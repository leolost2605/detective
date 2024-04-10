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
        var match = new Match (match_type, 20, cursor.get_string (0), null, icon, null);
        var url = cursor.get_string (2);
        match.activated.connect (() => {
            var split_url = url.split ("/");
            var app_info = new GLib.DesktopAppInfo (split_url[split_url.length - 1]);
            try {
                app_info.launch (null, null);
            } catch (Error e) {
                warning ("FAILED TO LAUNCH APP");
            }
        });
        return match;
    });
}
