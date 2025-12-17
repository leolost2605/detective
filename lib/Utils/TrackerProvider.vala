/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Detective.TrackerProvider : SearchProvider {
    // Needs to have exactly one printf style %s for the search term and
    // one prinf style %d for the maximum number of results
    public string query { get; construct; }
    public string result_type_name { get; construct; }

    public delegate Result CreateResultFunc (Tracker.Sparql.Cursor cursor);

    private Tracker.Sparql.Connection tracker_connection;

    private unowned CreateResultFunc create_result_func;

    private uint result_type_id;

    public TrackerProvider (string query, string result_type_name, CreateResultFunc create_result_func) {
        Object (query: query, result_type_name: result_type_name);

        this.create_result_func = create_result_func;
    }

    construct {
        try {
            tracker_connection = Tracker.Sparql.Connection.bus_new ("org.freedesktop.Tracker3.Miner.Files", null, null);
        } catch (Error e) {
            // TODO: Maybe send notification?
            warning (e.message);
        }
    }

    public override void register_with_aggregator (ResultAggregator aggregator) {
        result_type_id = aggregator.register_result_type_simple (result_type_name);
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

            while (yield cursor.next_async ()) {
                if (search_query.cancelled) {
                    throw new IOError.CANCELLED ("Search was cancelled");
                }

                var result = create_result_func (cursor);
                aggregator.add_result (result_type_id, result);
            }

            cursor.close ();
        } catch (Error e) {
            if (e is IOError.CANCELLED) {
                // Ignore
            } else {
                warning (e.message);
            }
        }

        aggregator.commit_results (result_type_id);
    }
}
