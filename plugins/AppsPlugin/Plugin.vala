private static MatchType match_type_apps;

public static TrackerProvider get_provider () {
    match_type_apps = new MatchType ("tracker-apps", "Applications");
    var query = """SELECT nie:title(?r) nfo:softwareIcon(?r) nie:url(nie:isStoredAs(?r)) { ?r a nfo:SoftwareApplication ; fts:match "%s" } ORDER BY fts:rank(?r)""";
    return new TrackerProvider (query, (cursor) => {
        var str = cursor.get_string (1);
        Icon? icon = null;
        if (str != null) {
            var split = cursor.get_string (1).split (":");
            var icon_name = split[split.length - 1];
            icon = new ThemedIcon (icon_name);
        }
        var match = new SignalMatch (match_type_apps, 20, cursor.get_string (0), null, icon, null);
        var url = cursor.get_string (2);
        match.activated.connect ((callback) => {
            var split_url = url.split ("/");
            var app_info = new GLib.DesktopAppInfo (split_url[split_url.length - 1]);
            try {
                app_info.launch (null, null);
                callback (null);
            } catch (Error e) {
                callback (e);
            }
        });
        return match;
    });
}
