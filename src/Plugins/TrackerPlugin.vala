
// This whole thing is just for testing
public class AppsProvider : Object {
    private static MatchType match_type;
    public static TrackerProvider get_provider () {
        match_type = new MatchType ("tracker", "Tracker");
        var query = """SELECT nie:title(?r) nfo:softwareIcon(?r) nie:url(nie:isStoredAs(?r)) { ?r a nfo:SoftwareApplication ; fts:match "%s" } ORDER BY fts:rank(?r)""";
        return new TrackerProvider (query, (cursor) => {
            var str = cursor.get_string (1);
            Icon? icon = null;
            if (str != null) {
                var split = cursor.get_string (1).split (":");
                var icon_name = split[split.length - 1];
                icon = new ThemedIcon (icon_name);
            }
            var match = new Match (match_type, 0, cursor.get_string (0), icon, null);
            var url = cursor.get_string (2);
            match.activated.connect (() => {
                var split_url = url.split ("/");
                var app_info = new DesktopAppInfo (split_url[split_url.length - 1]);
                app_info.launch (null, null);
            });
            return match;
        });
    }
}
