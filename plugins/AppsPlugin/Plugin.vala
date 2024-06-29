public class AppMatch : Match {
    public string app_id { get; construct; }
    public string exec { get; construct; }
    public string[]? keywords { get; construct; }

    public AppMatch (string app_id, string title, string? description, Icon? icon, string exec, string[]? keywords) {
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

    public int set_relevancy (string search_term) {
        //TODO: Better search algorithm (fuzzy)
        // Also this just grew as I thought of new things so some more considerations should be put into
        // some things. E.g. how do we weight the relevancy from times launched? Should it be more than 1/10? Probably

        int relevancy = 0;

        var downed_search_term = search_term.down ();

        if (title.down ().contains (downed_search_term)) {
            if (title.down ().has_prefix (downed_search_term)) {
                relevancy = 50;
            } else {
                relevancy = 45;
            }
        } else if (description != null && description.down ().contains (downed_search_term)) {
            relevancy = 5;
        } else if (keywords != null) {
            foreach (unowned var keyword in keywords) {
                if (keyword.down ().contains (downed_search_term)) {
                    relevancy = 1;
                    break;
                }
            }
        }

        if (relevancy > 0) {
            relevancy += + (int) (RelevancyService.get_default ().get_app_relevancy (app_id) * 50);
        }

        this.relevancy = relevancy;

        return relevancy;
    }

    public override async void activate () throws Error {
        RelevancyService.get_default ().app_launched (app_id);

        var desktop_integration = yield DesktopIntegration.get_instance ();
        foreach (var window in yield desktop_integration.get_windows ()) {
            if (window.properties["app-id"].get_string () == app_id) {
                yield desktop_integration.focus_window (window.uid);
                return;
            }
        }

        Process.spawn_command_line_async ("flatpak-spawn --host " + exec);
    }
}

public class AppsProvider : SearchProvider {
    public static MatchType match_type_apps;

    private string[] paths = {
        Environment.get_home_dir () + "/.local/share/flatpak/exports/share",
        "/var/lib/flatpak/exports/share",
        "/var/lib/snapd/desktop"
    };

    private GenericSet<string> found_desktop_ids = new GenericSet<string> (str_hash, str_equal);

    private ListStore list_store;
    private Query? query;

    private Regex exec_field_codes_regex;

    private FileMonitor[] file_monitors = {};

    construct {
        RelevancyService.get_default (); // Init file loading

        list_store = new ListStore (typeof (AppMatch));

        var filter_list_model = new Gtk.FilterListModel (list_store, new Gtk.CustomFilter ((obj) => {
            var match = (AppMatch) obj;
            return query != null ? match.set_relevancy (query.search_term) > 0 : false;
        }));

        match_type_apps = new MatchType ("Applications", filter_list_model);

        var match_types_list_store = new ListStore (typeof (MatchType));
        match_types_list_store.append (match_type_apps);

        match_types = match_types_list_store;

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
            var file = File.new_build_filename (path, "applications");

            if (!file.query_exists ()) {
                continue;
            }

            try {
                var enumerator = yield file.enumerate_children_async ("standard::*", NOFOLLOW_SYMLINKS, Priority.DEFAULT, null);

                FileInfo? info = null;
                while ((info = enumerator.next_file (null)) != null) {
                    yield validate_appinfo (Path.build_filename (file.get_path (), info.get_name ()));
                }
            } catch (Error e) {
                warning ("Failed to enumerate children of path %s: %s", file.get_path (), e.message);
            }

            try {
                var monitor = file.monitor (NONE);

                monitor.changed.connect ((file, other_file, event) => {
                    if (event == CREATED) {
                        validate_appinfo.begin (file.get_path ());
                    }

                    if (event == DELETED) {
                        //TODO
                    }
                });

                file_monitors += monitor;
            } catch (Error e) {
                warning ("Failed to monitor directory at path %s: %s", file.get_path (), e.message);
            }
        }
    }

    private async void validate_appinfo (string path) {
        Bytes bytes;
        try {
            File file = File.new_for_path (path);
            bytes = yield file.load_bytes_async (null, null);
        } catch (Error e) {
            warning ("Failed to load file %s: %s", path, e.message);
            return;
        }

        var key_file = new KeyFile ();
        try {
            key_file.load_from_bytes (bytes, NONE);
        } catch (Error e) {
            warning ("Failed to parse desktop file %s: %s", path, e.message);
            return;
        }

        if (!key_file.has_group ("Desktop Entry")) {
            return;
        }

        var app_id = Path.get_basename (path);

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

                var file = File.new_for_path (icon_name);

                if (file.query_exists ()) {
                    icon = new FileIcon (file);
                }
            } else {
                icon = new ThemedIcon (icon_name);
            }
        } catch (Error e) {
            debug ("Failed to get icon: %s", e.message);
        }

        string[]? keywords = null;
        try {
            keywords = key_file.get_locale_string_list ("Desktop Entry", "Keywords", null);
        } catch (Error e) {
            debug ("Failed to get keywords: %s", e.message);
        }

        list_store.append (new AppMatch (app_id, title, description, icon, exec, keywords));
        found_desktop_ids.add (app_id);
    }

    public override void search (Query query) {
        this.query = query;
        list_store.items_changed (0, list_store.n_items, list_store.n_items);
    }

    public override void clear () {
        this.query = null;
        list_store.items_changed (0, list_store.n_items, list_store.n_items);
    }
}

public static AppsProvider get_provider () {
    return new AppsProvider ();
}
