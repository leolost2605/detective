/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Detective.TrackerProvider : SearchProvider {
    // Needs to have exactly one printf style %s for the search term and
    // one prinf style %d for the maximum number of results
    public string query { get; construct; }
    public string match_type_name { get; construct; }

    public delegate Result CreateMatchFunc (Tracker.Sparql.Cursor cursor);

    private Tracker.Sparql.Connection tracker_connection;

    private unowned CreateMatchFunc create_match_func;

    public TrackerProvider (string query, string match_type_name, CreateMatchFunc create_match_func) {
        Object (query: query, match_type_name: match_type_name);

        this.create_match_func = create_match_func;
    }

    construct {
        try {
            tracker_connection = Tracker.Sparql.Connection.bus_new ("org.freedesktop.Tracker3.Miner.Files", null, null);
        } catch (Error e) {
            // TODO: Maybe send notification?
            warning (e.message);
        }
    }

    internal override void search (Query search_query, ResultAggregator aggregator) {
        search_tracker.begin (search_query, aggregator);
    }

    private async void search_tracker (Query search_query, ResultAggregator aggregator) {
        try {
            var tracker_statement_id = tracker_connection.query_statement (
                query.printf (search_query.search_term, search_query.n_results)
            );

            var cursor = yield tracker_statement_id.execute_async (search_query.cancellable);

            ListStore? results = null;
            while (yield cursor.next_async ()) {
                if (search_query.cancelled) {
                    throw new IOError.CANCELLED ("Search was cancelled");
                }

                if (results == null) {
                    results = new ListStore (typeof (Result));
                    aggregator.register_result_type (match_type_name, results, false);
                }

                var result = create_match_func (cursor);
                results.append (result);
            }

            cursor.close ();
        } catch (Error e) {
            if (e is IOError.CANCELLED) {
                // Ignore
            } else {
                warning (e.message);
            }
        }
    }
}
