public class AppMatch : Match {
    public static MatchType match_type_apps = new MatchType ("Applications");

    public KeyFile key_file { get; construct; }

    public AppMatch (KeyFile key_file) {
        Object (
            match_type: match_type_apps,
            relevancy: 0,
            key_file: key_file
        );
    }

    construct {
        try {
            title = key_file.get_locale_string ("Desktop Entry", "Name", null);
        } catch (Error e) {
            warning ("Failed to get name: %s", e.message);
        }

        try {
            description = key_file.get_locale_string ("Desktop Entry", "Comment", null);
        } catch (Error e) {
            warning ("Failed to get name: %s", e.message);
        }

        try {
            var icon_name = key_file.get_string ("Desktop Entry", "Icon");

            var file = File.new_for_path (icon_name);
            if (file.query_exists ()) {
                icon = new FileIcon (file);
            } else {
                icon = new ThemedIcon (icon_name);
            }
        } catch (Error e) {
            warning ("Failed to get name: %s", e.message);
        }
    }

    public int set_relevancy (string search_term) {
        int relevancy = 0;

        if (title.contains (search_term)) {
            relevancy = 100;
        }

        this.relevancy = relevancy;

        match_type_apps.add_relevancy (relevancy);

        return relevancy;
    }

    public override async void activate () throws Error {
        Process.spawn_command_line_async ("flatpak-spawn --host " + key_file.get_string ("Desktop Entry", "Exec"));
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

    construct {
        list_store = new ListStore (typeof (AppMatch));

        var filter_list_model = new Gtk.FilterListModel (list_store, new Gtk.CustomFilter ((obj) => {
            var match = (AppMatch) obj;
            return query != null ? match.set_relevancy (query.search_term) > 0 : false;
        }));

        matches = filter_list_model;

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

        list_store.append (new AppMatch (key_file));
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
    //  match_type_apps = new MatchType ("Applications");
    //  var query = """SELECT nie:title(?r) nfo:softwareIcon(?r) nie:url(nie:isStoredAs(?r)) fts:rank(?r) { ?r a nfo:SoftwareApplication ; fts:match "%s" } ORDER BY fts:rank(?r)""";
    //  var provider = new TrackerProvider (query, (cursor) => {
    //      var str = cursor.get_string (1);
    //      Icon? icon = null;
    //      if (str != null) {
    //          var split = cursor.get_string (1).split (":");
    //          var icon_name = split[split.length - 1];
    //          icon = new ThemedIcon (icon_name);
    //      }

    //      var match = new SignalMatch (match_type_apps, (int) cursor.get_integer (3) * -100, cursor.get_string (0), null, icon, null);

    //      var url = cursor.get_string (2);
    //      match.activated.connect ((callback) => {
    //          var split_url = url.split ("/");
    //          var app_info = new GLib.DesktopAppInfo (split_url[split_url.length - 1]);
    //          try {
    //              app_info.launch (null, null);
    //              callback (null);
    //          } catch (Error e) {
    //              callback (e);
    //          }
    //      });

    //      match_type_apps.add_relevancy (match.relevancy);

    //      return match;
    //  });

    //  provider.cleared.connect (() => match_type_apps.clear_relevancy ());

    return new AppsProvider ();
}
