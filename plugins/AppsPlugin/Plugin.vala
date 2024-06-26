public class AppMatch : Match {
    public static MatchType match_type_apps;

    public string exec { get; construct; }
    public string[]? keywords { get; construct; }

    public AppMatch (string title, string? description, Icon? icon, string exec, string[]? keywords) {
        Object (
            match_type: match_type_apps,
            relevancy: 0,
            title: title,
            description: description,
            icon: icon,
            exec: exec,
            keywords: keywords
        );
    }

    public int set_relevancy (string search_term) {
        //TODO: Better search algorithm (fuzzy)
        int relevancy = 0;

        if (title.down ().contains (search_term.down ())) {
            relevancy = 100;
        }

        this.relevancy = relevancy;

        match_type_apps.add_relevancy (relevancy);

        return relevancy;
    }

    public override async void activate () throws Error {
        Process.spawn_command_line_async ("flatpak-spawn --host " + exec);
    }
}

public class AppsProvider : SearchProvider {
    private const string[] paths = {
        "/run/host/usr/share/applications/",
        "/usr/share/applications/",
        "/var/lib/flatpak/exports/share/applications/",
        ".local/share/flatpak/exports/share/applications/",
        "/var/lib/snapd/desktop/applications/"
    };

    private ListStore list_store;
    private Query? query;

    private Regex exec_field_codes_regex;

    construct {
        AppMatch.match_type_apps = new MatchType ("Applications");

        list_store = new ListStore (typeof (AppMatch));

        var filter_list_model = new Gtk.FilterListModel (list_store, new Gtk.CustomFilter ((obj) => {
            var match = (AppMatch) obj;
            return query != null ? match.set_relevancy (query.search_term) > 0 : false;
        }));

        matches = filter_list_model;

        try {
            exec_field_codes_regex = new Regex ("(?<!%)%.");
        } catch (Error e) {
            warning ("Failed to compile regex. This shouldn't be reached: %s", e.message);
        }

        build_cache.begin ();
    }

    private async void build_cache () {
        foreach (var path in paths) {
            var file = File.new_for_path (path);

            try {
                var enumerator = yield file.enumerate_children_async ("standard::*", NOFOLLOW_SYMLINKS, Priority.DEFAULT, null);

                FileInfo? info = null;
                while ((info = enumerator.next_file (null)) != null) {
                    yield validate_appinfo (Path.build_filename (path, info.get_name ()));
                }
            } catch (Error e) {
                warning ("Failed to enumerate children of path %s: %s", path, e.message);
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

            var file = File.new_for_path (icon_name);
            if (file.query_exists ()) {
                icon = new FileIcon (file);
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

        list_store.append (new AppMatch (title, description, icon, exec, keywords));
    }

    public override void search (Query query) {
        this.query = query;
        list_store.items_changed (0, list_store.n_items, list_store.n_items);
    }

    public override void clear () {
        this.query = null;
        list_store.items_changed (0, list_store.n_items, list_store.n_items);
        AppMatch.match_type_apps.clear_relevancy ();
    }
}

public static AppsProvider get_provider () {
    return new AppsProvider ();
}
