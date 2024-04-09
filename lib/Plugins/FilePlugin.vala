
public class FilePlugin : Object {
    private static MatchType match_type;

    public static TrackerProvider get_provider () {
        match_type = new MatchType ("file", "File");

        var query = """
            SELECT nfo:fileName(?r) nie:url(?r) {
                GRAPH tracker:FileSystem {
                    ?r a nfo:FileDataObject ;
                    fts:match "%s"
                }
            } ORDER BY fts:rank(?r)
        """;

        return new TrackerProvider (query, (cursor) => {
            var match = new Match (match_type, 0, cursor.get_string (0), null, null);
            var url = cursor.get_string (1);
            match.activated.connect (() => {
                try {
                    AppInfo.launch_default_for_uri (url, null);
                } catch (Error e) {
                    warning ("Failed to launch default app for uri: %s", e.message);
                }
            });
            return match;
        });
    }
}
