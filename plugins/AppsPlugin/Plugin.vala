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

    private int min3 (int i1, int i2, int i3) {
        if (i1 <= i2 && i1 <= i3) {
            return i1;
        } else if (i2 <= i1 && i2 <= i3) {
            return i2;
        } else {
            return i3;
        }
    }

    // https://en.wikipedia.org/wiki/Levenshtein_distance#Iterative_with_two_matrix_rows
    public int levenshtein_distance (string search_term, string compare_term) {
        // Weights are in integers, where larger numbers imply a further distance
        var deletion_weight = 1;
        var insertion_weight = 1;
        var substitution_weight = 2;

        // Declare working arrays
        var previous_row = new int[compare_term.length + 1];
        var current_row = new int[compare_term.length + 1];

        // Initialize row
        for (var i = 0; i <= compare_term.length; i++) {
            previous_row[i] = i;
        }

        // Calculate cost matrix
        for (var i = 0; i < search_term.length; i++) {
            current_row[0] = i + deletion_weight;

            for (var j = 0; j < compare_term.length; j++) {
                var deletion_cost = previous_row[j + 1] + deletion_weight;
                var insertion_cost = current_row[j] + insertion_weight;
                var substitution_cost = 0;

                if (search_term.get_char (i) == compare_term.get_char (j)) {
                    substitution_cost = previous_row[j];
                } else {
                    substitution_cost = previous_row[j] + substitution_weight;
                }

                current_row[j + 1] = min3(deletion_cost, insertion_cost, substitution_cost);
            }

            previous_row = current_row;
        }

    return previous_row[compare_term.length];
}

    public int set_relevancy (string search_term) {
        // Also this just grew as I thought of new things so some more considerations should be put into
        // some things. E.g. how do we weight the relevancy from times launched? Should it be more than 1/10? Probably
        const int max_l_distance = 5;
        const int title_weight = 20;
        const int description_weight = 5;
        const int keyword_weight = 1;

        int relevancy = 0;
        var downed_search_term = search_term.down ();

        var title_l_distance = levenshtein_distance (downed_search_term, title.down ());
        if (title.down ().contains (downed_search_term)) {
            relevancy += title_weight * (max_l_distance + 1); // weight an exact match more heavily than a close match

            if (title.down ().has_prefix (downed_search_term)) {
                relevancy += 5;
            }
        } else if (levenshtein_distance (downed_search_term, title.down ()) <= max_l_distance) {
            relevancy += (max_l_distance - title_l_distance) * title_weight;
        }

        if (description != null && description.down ().contains (downed_search_term)) {
            relevancy += description_weight;
        } 

        if (keywords != null) {
            foreach (unowned var keyword in keywords) {
                var keyword_l_distance = levenshtein_distance (downed_search_term, keyword.down ());
                if (keyword_l_distance < 3) {
                    relevancy += (3 - keyword_l_distance) * keyword_weight;
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

#if DESKTOP_INTEGRATION
        var desktop_integration = yield DesktopIntegration.get_instance ();
        foreach (var window in yield desktop_integration.get_windows ()) {
            if (window.properties["app-id"].get_string () == app_id) {
                yield desktop_integration.focus_window (window.uid);
                return;
            }
        }
#endif

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

        match_type_apps = new MatchType (_("Applications"), filter_list_model);

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
