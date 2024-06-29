
// This whole thing is just for testing
public class TrackerProvider : SearchProvider {
    public signal void cleared ();

    // Needs to have exactly one printf style %s for the search term
    public string query { get; construct; }
    public string match_type_name { get; construct; }

    public delegate Match CreateMatchFunc (Tracker.Sparql.Cursor cursor);

    private Query search_query;

    private ListStore matches;
    private Tracker.Sparql.Connection tracker_connection;

    private unowned CreateMatchFunc create_match_func;

    public TrackerProvider (string query, string match_type_name, CreateMatchFunc create_match_func) {
        Object (query: query, match_type_name: match_type_name);

        this.create_match_func = create_match_func;
    }

    construct {
        matches = new ListStore (typeof (Match));

        var match_types = new ListStore (typeof (MatchType));
        match_types.append (new MatchType (match_type_name, matches));

        this.match_types = match_types;

        try {
            tracker_connection = Tracker.Sparql.Connection.bus_new ("org.freedesktop.Tracker3.Miner.Files", null, null);
        } catch (Error e) {
            // TODO: Maybe send notification?
            warning (e.message);
        }
    }

    internal override void search (Query search_query) {
        this.search_query = search_query;
        search_tracker.begin ();
    }

    internal override void clear () {
        matches.remove_all ();
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
            this.matches.splice (0, 0, matches);

            cursor.close ();
        } catch (Error e) {
            if (e is IOError.CANCELLED) {
                matches.remove_all ();
            } else {
                warning (e.message);
            }
        }
    }
}
