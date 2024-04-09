
// This whole thing is just for testing
public class TrackerProvider : SearchProvider {
    // Needs to have exactly one printf style %s for the search term
    public string query { get; construct; }

    public delegate Match CreateMatchFunc (Tracker.Sparql.Cursor cursor);

    private string search_term = "";

    private ListStore matches_internal;
    private Tracker.Sparql.Connection tracker_connection;

    private unowned CreateMatchFunc create_match_func;

    public TrackerProvider (string query, CreateMatchFunc create_match_func) {
        Object (query: query);

        this.create_match_func = create_match_func;
    }

    construct {
        matches_internal = new ListStore (typeof (Match));
        matches = matches_internal;

        try {
            tracker_connection = Tracker.Sparql.Connection.bus_new ("org.freedesktop.Tracker3.Miner.Files", null, null);
        } catch (Error e) {
            warning (e.message);
        }
    }

    public override void search (string search_term) {
        this.search_term = search_term;
        search_tracker.begin ();
    }

    public override void clear () {
        matches_internal.remove_all ();
    }

    public async void search_tracker () {
        try {
            var tracker_statement_id = tracker_connection.query_statement (
                query.printf (search_term)
            );

            var cursor = yield tracker_statement_id.execute_async (null);

            matches_internal.remove_all ();

            while (yield cursor.next_async ()) {
                var match = create_match_func (cursor);
                matches_internal.append (match);
            }

            cursor.close ();
        } catch (Error e) {
            warning (e.message);
        }
    }
}
