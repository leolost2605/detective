public class Detective.FileActionMatch : Result {
    public delegate void ActionCallback ();
    private ActionCallback callback;

    public FileActionMatch (string title, string? description, Icon? icon, owned ActionCallback callback) {
        Object (
            relevancy: 0,
            title: title,
            description: description,
            icon: icon
        );
        this.callback = (owned) callback;
    }

    public override async void activate () throws Error {
        this.callback ();
    }
}

public class Detective.FileMatch : Result {
    public string uri { get; construct; }

    public FileMatch (int relevancy, string title, string? description, Icon? icon, string uri) {
        Object (
            relevancy: relevancy,
            title: title,
            description: description,
            icon: icon,
            uri: uri
        );
    }

    public override async void activate () throws Error {
        yield new Gtk.FileLauncher (File.new_for_uri (uri)).launch (null, null);
    }

    public override GLib.ListModel? get_actions () {
        var actions = new GLib.ListStore (typeof (Result));
        
        // Open Location
        actions.append (new Detective.FileActionMatch (
            _("Open Location"),
            _("Open the folder containing this file"),
            new ThemedIcon ("folder-symbolic"),
            () => {
                var file = File.new_for_uri (uri);
                var parent = file.get_parent ();
                if (parent != null) {
                    new Gtk.FileLauncher (parent).launch.begin (null, null);
                }
            }
        ));

        // Copy Path
        actions.append (new Detective.FileActionMatch (
            _("Copy Path"),
            _("Copy the absolute file path to clipboard"),
            new ThemedIcon ("edit-copy-symbolic"),
            () => {
                var display = Gdk.Display.get_default ();
                if (display != null) {
                    string path = uri;
                    try {
                        path = Filename.from_uri (uri, null);
                    } catch (Error e) {}
                    display.get_clipboard ().set_text (path);
                }
            }
        ));

        // Move to Trash
        actions.append (new Detective.FileActionMatch (
            _("Move to Trash"),
            _("Move this file to the trash bin"),
            new ThemedIcon ("user-trash-symbolic"),
            () => {
                try {
                    var file = File.new_for_uri (uri);
                    file.trash (null);
                } catch (Error e) {
                    warning ("Failed to trash file: %s", e.message);
                }
            }
        ));

        return actions;
    }
}

public static Detective.TrackerProvider get_provider () {
    var query = """
        SELECT nfo:fileName(?r) nie:url(?r) nie:mimeType(nie:interpretedAs(?r)) fts:rank(?r) {
            GRAPH tracker:FileSystem {
                ?r a nfo:FileDataObject ;
                fts:match "%s"
            }
        } ORDER BY fts:rank(?r)
          LIMIT %d
    """;

    var provider = new Detective.TrackerProvider (query, _("Files"), (cursor) => {
        var url = cursor.get_string (1);

        string path = url;
        try {
            path = Filename.from_uri (url, null);
        } catch (Error e) {
            warning ("Failed to parse file uri: %s", e.message);
        }

        Icon? icon = null;
        if (cursor.is_bound (2)) {
            icon = ContentType.get_icon (cursor.get_string (2));
        } else {
            icon = new ThemedIcon ("unknown");
        }

        return new Detective.FileMatch ((int) cursor.get_integer (3) * 10, cursor.get_string (0), path, icon, url);
    });

    return provider;
}
