
// This whole thing is just for testing
public class TrackerProvider : SearchProvider {
    private string search_term = "";
    private bool searching = false;

    private MatchType match_type;
    private ListStore matches_internal;
    private Tracker.Sparql.Connection tracker_connection;

    construct {
        match_type = new MatchType ("tracker", "Tracker");

        matches_internal = new ListStore (typeof (Match));
        matches = matches_internal;

        try {
            tracker_connection = Tracker.Sparql.Connection.bus_new ("org.freedesktop.Tracker3.Miner.Files", null, null);
        } catch (Error e) {
            warning (e.message);
        }
    }

    public override void search (string search_term) {
        matches_internal.remove_all ();
        searching = true;
        this.search_term = search_term;
        search_tracker.begin ();
    }

    public override void clear () {
        searching = false;
        matches_internal.remove_all ();
    }

    public async void search_tracker () {
        try {
            var tracker_statement_id = tracker_connection.query_statement (
                """
                    SELECT nie:title(?r) nfo:softwareIcon(?r) { ?r a nfo:SoftwareApplication ; fts:match "%s" } ORDER BY fts:rank(?r)
                """.printf (search_term)
            );

            var cursor = yield tracker_statement_id.execute_async (null);

            while (yield cursor.next_async ()) {
                var str = cursor.get_string (1);
                Icon? icon = null;
                if (str != null) {
                    var split = cursor.get_string (1).split (":");
                    var icon_name = split[split.length - 1];
                    icon = new ThemedIcon (icon_name);
                }
                var match = new Match (match_type, 0, cursor.get_string (0), icon, null);
                matches_internal.append (match);
            }

            cursor.close ();
        } catch (Error e) {
            warning (e.message);
        }
    }
}
