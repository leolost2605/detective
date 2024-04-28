
// This whole thing is just for testing
public class TrackerProvider : SearchProvider {
    public signal void cleared ();

    // Needs to have exactly one printf style %s for the search term
    public string query { get; construct; }

    public delegate Match CreateMatchFunc (Tracker.Sparql.Cursor cursor);

    private Query search_query;

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

    internal override void search (Query search_query) {
        this.search_query = search_query;
        search_tracker.begin ();
    }

    internal override void clear () {
        matches_internal.remove_all ();
        cleared ();
    }

    private async void search_tracker () {
        try {
            var tracker_statement_id = tracker_connection.query_statement (
                query.printf (search_query.search_term)
            );

            var cursor = yield tracker_statement_id.execute_async (search_query.cancellable);

            clear ();

            Match[] matches = {};
            while (yield cursor.next_async ()) {
                if (search_query.cancelled) {
                    throw new IOError.CANCELLED ("Search was cancelled");
                }

                var match = create_match_func (cursor);
                matches += match;
            }
            matches_internal.splice (0, 0, matches);

            cursor.close ();
        } catch (Error e) {
            if (e is IOError.CANCELLED) {
                matches_internal.remove_all ();
            } else {
                warning (e.message);
            }
        }
    }
}
