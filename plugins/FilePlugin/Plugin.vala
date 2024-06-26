public class FileMatch : Match {
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
}

public static TrackerProvider get_provider () {
    var query = """
        SELECT nfo:fileName(?r) nie:url(?r) nie:mimeType(nie:interpretedAs(?r)) fts:rank(?r) {
            GRAPH tracker:FileSystem {
                ?r a nfo:FileDataObject ;
                fts:match "%s"
            }
        } ORDER BY fts:rank(?r)
          LIMIT 50
    """;

    var provider = new TrackerProvider (query, _("Files"), (cursor) => {
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

        return new FileMatch ((int) cursor.get_integer (3) * 10, cursor.get_string (0), path, icon, url);
    });

    return provider;
}
