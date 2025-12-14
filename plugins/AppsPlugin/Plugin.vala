public class Detective.AppMatch : Match {
    public string app_id { get; construct; }
    public string exec { get; construct; }
    public string[] keywords { get; construct; }

    private string[] title_tokens;
    private string[] description_tokens;

    public AppMatch (string app_id, string title, string? description, Icon? icon, string exec, string[] keywords) {
        Object (
            relevancy: 0,
            app_id: app_id,
            title: title,
            description: description,
            icon: icon,
            exec: exec,
            keywords: keywords
        );
    }

    construct {
        title_tokens = title.tokenize_and_fold (null, null);
        description_tokens = description?.tokenize_and_fold (null, null) ?? new string[0];
    }

    public int set_relevancy (Query query) {
        const int title_weight = Relevancy.HIGH;
        const int description_weight = Relevancy.MEDIUM;
        const int keyword_weight = Relevancy.LOW;

        int relevancy = 0;

        relevancy += Algorithms.fuzzy_relevancy (query.search_tokens, title_tokens, title_weight);
        relevancy += Algorithms.fuzzy_relevancy (query.search_tokens, description_tokens, description_weight);

        foreach (var keyword in keywords) {
            relevancy += Algorithms.fuzzy_relevancy (query.search_tokens, { keyword }, keyword_weight);
        }

        relevancy = int.min (relevancy, Relevancy.HIGHEST);
        relevancy = AppsProvider.calculate_relevancy_with_recency (relevancy, app_id);

        this.relevancy = relevancy;

        return relevancy;
    }

    public override async void activate () throws Error {
        RelevancyService.get_default ().app_launched (app_id);

#if DESKTOP_INTEGRATION
        var desktop_integration = yield DesktopIntegration.get_instance ();
        foreach (var window in yield desktop_integration.get_windows ()) {
            if (window.properties["app-id"].get_string () == app_id) {
                yield desktop_integration.focus_window (window.uid);
                return;
            }
        }
#endif

        var app_info = new DesktopAppInfo (app_id);
        if (app_info != null) {
            app_info.launch (null, null);
        } else {
            Process.spawn_command_line_async ("flatpak-spawn --host " + exec);
        }
    }
}

public class Detective.AppActionMatch : Match {
    public string app_id { get; construct; }
    public string action_name { get; construct; }
    public string exec { get; construct; }
    public string app_title { get; construct; }

    private string[] title_tokens;
    private string[] app_title_tokens;

    public AppActionMatch (string app_id, string action_name, string action_title, string app_title, Icon? icon, string exec) {
        Object (
            relevancy: 0,
            app_id: app_id,
            action_name: action_name,
            title: action_title,
            app_title: app_title,
            description: null,
            icon: icon,
            exec: exec
        );
    }

    construct {
        title_tokens = title.tokenize_and_fold (null, null);
        app_title_tokens = app_title.tokenize_and_fold (null, null);
    }

    public int set_relevancy (Query query) {
        const int title_weight = Relevancy.HIGHEST;
        const int app_title_weight = Relevancy.LOW;

        int relevancy = 0;

        // Match against action title
        relevancy += Algorithms.fuzzy_relevancy (query.search_tokens, title_tokens, title_weight);

        // Match against app title
        relevancy += Algorithms.fuzzy_relevancy (query.search_tokens, app_title_tokens, app_title_weight);

        relevancy = int.min (relevancy, Relevancy.HIGHEST);
        relevancy = AppsProvider.calculate_relevancy_with_recency (relevancy, app_id);

        this.relevancy = relevancy;

        return relevancy;
    }

    public override async void activate () throws Error {
        RelevancyService.get_default ().app_launched (app_id);

        var app_info = new DesktopAppInfo (app_id);
        if (app_info != null) {
            app_info.launch_action (action_name, null);
        } else {
            Process.spawn_command_line_async ("flatpak-spawn --host " + exec);
        }
    }
}

public class Detective.AppsProvider : SearchProvider {
    // Helper method to calculate relevancy with recency
    public static int calculate_relevancy_with_recency (int base_relevancy, string app_id) {
        if (base_relevancy <= 0) {
            return 0;
        }

        var recency_relevancy = (int) (RelevancyService.get_default ().get_app_relevancy (app_id) * Relevancy.HIGHEST);
        return (base_relevancy * 2 + recency_relevancy) / 3;
    }

    private string[] paths = {
        Environment.get_home_dir () + "/.local/share",
        Environment.get_home_dir () + "/.local/share/flatpak/exports/share",
        "/var/lib/flatpak/exports/share",
        "/var/lib/snapd/desktop"
    };

    private GenericSet<string> found_desktop_ids = new GenericSet<string> (str_hash, str_equal);

    private ListStore list_store;
    private ListStore actions_list_store;
    private Query? query;

    private Regex exec_field_codes_regex;

    private FileMonitor[] file_monitors = {};

    construct {
        RelevancyService.get_default (); // Init file loading

        list_store = new ListStore (typeof (AppMatch));
        actions_list_store = new ListStore (typeof (AppActionMatch));

        try {
            exec_field_codes_regex = new Regex ("(?<!%)%.");
        } catch (Error e) {
            warning ("Failed to compile regex. This shouldn't be reached: %s", e.message);
        }

        // Not entirely sure how this works but the Gtk.IconTheme here doesn't search in the directories containing
        // flatpak app icons and some others. Therefore add them manually. Might be too many but better safe than sorry.
        var icon_theme = Gtk.IconTheme.get_for_display (Gdk.Display.get_default ());
        icon_theme.add_search_path (Environment.get_home_dir () + "/.local/share/flatpak/exports/share/icons");
        icon_theme.add_search_path ("/var/lib/flatpak/exports/share/icons");
        icon_theme.add_search_path (Environment.get_home_dir () + "/.local/share/icons");
        icon_theme.add_search_path ("/run/host/usr/share/icons");
        icon_theme.add_search_path ("/run/host/usr/share/pixmaps");
        icon_theme.add_search_path ("/run/host/usr/local/share/icons");
        icon_theme.add_search_path ("/run/host/usr/local/share/pixmaps");

        // Make sure preferred entries come first here
        paths += Environment.get_user_data_dir ();
        foreach (var dir in Environment.get_system_data_dirs ()) {
            if (dir.has_prefix ("/usr")) {
                paths += "/run/host" + dir; // /usr dirs aren't available from the sandbox
            } else {
                paths += dir;
            }
        }

        build_cache.begin ();
    }

    private async void build_cache () {
        found_desktop_ids.remove_all ();
        list_store.remove_all ();

        //TODO: support subpaths
        foreach (var path in paths) {
            yield check_directory (File.new_build_filename (path, "applications"));
        }
    }

    private async void check_directory (File dir) {
        if (!dir.query_exists ()) {
            return;
        }

        try {
            var enumerator = yield dir.enumerate_children_async ("standard::*", NOFOLLOW_SYMLINKS, Priority.DEFAULT, null);

            FileInfo? info = null;
            while ((info = enumerator.next_file (null)) != null) {
                var child = File.new_build_filename (dir.get_path (), info.get_name ());

                if (info.get_file_type () == DIRECTORY) {
                    yield check_directory (child);
                } else {
                    yield validate_appinfo (child);
                }
            }
        } catch (Error e) {
            warning ("Failed to enumerate children of path %s: %s", dir.get_path (), e.message);
        }

        try {
            var monitor = dir.monitor (NONE);

            monitor.changed.connect ((file, other_file, event) => {
                if (event == CREATED) {
                    if (file.query_file_type (NONE, null) == DIRECTORY) {
                        check_directory.begin (file);
                    } else {
                        validate_appinfo.begin (file);
                    }
                }

                if (event == DELETED) {
                    //TODO
                }
            });

            file_monitors += monitor;
        } catch (Error e) {
            warning ("Failed to monitor directory at path %s: %s", dir.get_path (), e.message);
        }
    }

    // TODO: Properly handle subpaths
    private async void validate_appinfo (File file) {
        Bytes bytes;
        try {
            bytes = yield file.load_bytes_async (null, null);
        } catch (Error e) {
            warning ("Failed to load file %s: %s", file.get_path (), e.message);
            return;
        }

        var key_file = new KeyFile ();
        try {
            key_file.load_from_bytes (bytes, NONE);
        } catch (Error e) {
            warning ("Failed to parse desktop file %s: %s", file.get_path (), e.message);
            return;
        }

        if (!key_file.has_group ("Desktop Entry")) {
            return;
        }

        var app_id = file.get_basename ();

        if (app_id in found_desktop_ids) {
            return;
        }

        try {
            if (key_file.has_key ("Desktop Entry", "Hidden") && key_file.get_boolean ("Desktop Entry", "Hidden")) {
                return;
            }
        } catch (Error e) {
            debug ("Failed to check hidden: %s", e.message);
        }

        try {
            if (key_file.has_key ("Desktop Entry", "NoDisplay") && key_file.get_boolean ("Desktop Entry", "NoDisplay")) {
                return;
            }
        } catch (Error e) {
            debug ("Failed to check NoDisplay: %s", e.message);
        }

        try {
            if (key_file.has_key ("Desktop Entry", "OnlyShowIn")) {
                var desktop = Environment.get_variable ("XDG_CURRENT_DESKTOP");
                var only_show_in = key_file.get_string ("Desktop Entry", "OnlyShowIn");

                if (only_show_in != desktop) {
                    return;
                }
            }
        } catch (Error e) {
            debug ("Failed to check OnlyShowIn: %s", e.message);
        }

        try {
            if (key_file.has_key ("Desktop Entry", "NotShowIn")) {
                var desktop = Environment.get_variable ("XDG_CURRENT_DESKTOP");
                var only_show_in = key_file.get_string ("Desktop Entry", "NotShowIn");

                if (only_show_in == desktop) {
                    return;
                }
            }
        } catch (Error e) {
            debug ("Failed to check NotShowIn: %s", e.message);
        }

        string? exec = null;
        try {
            exec = exec_field_codes_regex.replace (key_file.get_value ("Desktop Entry", "Exec"), -1, 0, "");
        } catch (Error e) {
            warning ("Failed to get exec: %s", e.message);
            return;
        }

        string? title = null;
        try {
            title = key_file.get_locale_string ("Desktop Entry", "Name", null);
        } catch (Error e) {
            warning ("Failed to get name: %s", e.message);
            return;
        }

        string? description = null;
        try {
            description = key_file.get_locale_string ("Desktop Entry", "Comment", null);
        } catch (Error e) {
            debug ("Failed to get description: %s", e.message);
        }

        Icon? icon = null;
        try {
            var icon_name = key_file.get_string ("Desktop Entry", "Icon");

            if (icon_name.strip ().has_prefix ("/")) {
                if (icon_name.has_prefix ("/usr")) {
                    icon_name = Path.build_filename ("/run/host", icon_name);
                }

                var icon_file = File.new_for_path (icon_name);

                if (icon_file.query_exists ()) {
                    icon = new FileIcon (icon_file);
                } else {
                    icon = new ThemedIcon ("application-default-icon");
                }
            } else if (Gtk.IconTheme.get_for_display (Gdk.Display.get_default ()).has_icon (icon_name)) {
                icon = new ThemedIcon (icon_name);
            } else {
                icon = new ThemedIcon ("application-default-icon");
            }
        } catch (Error e) {
            debug ("Failed to get icon: %s", e.message);
        }

        string[] keywords = {};
        try {
            keywords = key_file.get_locale_string_list ("Desktop Entry", "Keywords", null);
        } catch (Error e) {
            debug ("Failed to get keywords: %s", e.message);
        }

        list_store.append (new AppMatch (app_id, title, description, icon, exec, keywords));
        found_desktop_ids.add (app_id);

        try {
            if (key_file.has_key ("Desktop Entry", "Actions")) {
                var actions_string = key_file.get_string ("Desktop Entry", "Actions");
                var action_ids = actions_string.split (";");

                foreach (var action_id in action_ids) {
                    if (action_id.strip () == "") {
                        continue;
                    }

                    var group_name = "Desktop Action " + action_id;
                    if (!key_file.has_group (group_name)) {
                        continue;
                    }

                    string? action_name = null;
                    try {
                        action_name = key_file.get_locale_string (group_name, "Name", null);
                    } catch (Error e) {
                        debug ("Failed to get action name for %s: %s", action_id, e.message);
                        continue;
                    }

                    string? action_exec = null;
                    try {
                        action_exec = exec_field_codes_regex.replace (
                            key_file.get_value (group_name, "Exec"),
                            -1,
                            0,
                            ""
                        );
                    } catch (Error e) {
                        debug ("Failed to get action exec for %s: %s", action_id, e.message);
                        continue;
                    }

                    actions_list_store.append (
                        new AppActionMatch (app_id, action_id, action_name, title, icon, action_exec)
                    );
                }
            }
        } catch (Error e) {
            debug ("Failed to parse actions for %s: %s", app_id, e.message);
        }
    }

    public override void register_with_aggregator (ResultAggregator aggregator) {
        var filter_list_model = new Gtk.FilterListModel (list_store, new Gtk.CustomFilter ((obj) => {
            var match = (AppMatch) obj;
            return query != null ? match.set_relevancy (query) > 0 : false;
        }));

        var actions_filter_list_model = new Gtk.FilterListModel (actions_list_store, new Gtk.CustomFilter ((obj) => {
            var match = (AppActionMatch) obj;
            return query != null ? match.set_relevancy (query) > 0 : false;
        }));

        aggregator.register_result_type (_("Applications"), filter_list_model);
        aggregator.register_result_type (_("Application Actions"), actions_filter_list_model);
    }

    public override void search (Query query) {
        this.query = query;
        list_store.items_changed (0, list_store.n_items, list_store.n_items);
        actions_list_store.items_changed (0, actions_list_store.n_items, actions_list_store.n_items);
    }

    public override void clear () {
        this.query = null;
        list_store.items_changed (0, list_store.n_items, list_store.n_items);
        actions_list_store.items_changed (0, actions_list_store.n_items, actions_list_store.n_items);
    }
}

public static Detective.AppsProvider get_provider () {
    return new Detective.AppsProvider ();
}
