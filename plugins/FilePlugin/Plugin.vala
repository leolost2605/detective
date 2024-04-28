private static MatchType match_type_files;

public static TrackerProvider get_provider () {
    match_type_files = new MatchType ("Files");

    var query = """
        SELECT nfo:fileName(?r) nie:url(?r) nie:mimeType(nie:interpretedAs(?r)) fts:rank(?r) {
            GRAPH tracker:FileSystem {
                ?r a nfo:FileDataObject ;
                fts:match "%s"
            }
        } ORDER BY fts:rank(?r)
    """;

    var provider = new TrackerProvider (query, (cursor) => {
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
        }

        var match = new SignalMatch (match_type_files, (int) cursor.get_integer (3) * -100, cursor.get_string (0), path, icon, null);
        match.activated.connect ((callback) => {
            try {
                AppInfo.launch_default_for_uri (url, null);
                callback (null);
            } catch (Error e) {
                callback (e);
                warning ("Failed to launch default app for uri: %s", e.message);
            }
        });

        match_type_files.add_relevancy (match.relevancy);

        return match;
    });

    provider.cleared.connect (() => match_type_files.clear_relevancy ());

    return provider;
}
