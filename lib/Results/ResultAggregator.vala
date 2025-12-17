/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Detective.ResultAggregator : Object {
    /**
     * A model containing all results from all search providers for the current query.
     * The results are grouped in sections by their category where the first section
     * is the section with the result that has the highest relevancy. Within a section
     * the results are also sorted by relevancy descending.
     */
    public Gtk.SectionModel results { get; construct; }

    private ListStore result_types;
    private uint permanent_result_types_index = 0;

    private Gtk.NumericSorter result_type_sorter;

    private GenericArray<ResultListStore> result_stores;

    construct {
        result_types = new ListStore (typeof (ResultType));

        var best_relevancy_expression = new Gtk.PropertyExpression (typeof (ResultType), null, "best-result-relevancy");
        result_type_sorter = new Gtk.NumericSorter (best_relevancy_expression) {
            sort_order = DESCENDING
        };

        var result_type_sort_model = new Gtk.SortListModel (result_types, result_type_sorter);

        var results_model = new Gtk.MapListModel (result_type_sort_model, (obj) => {
            return ((ResultType) obj).results;
        });

        results = new Gtk.FlattenListModel (results_model);

        result_stores = new GenericArray<ResultListStore> ();
    }

    public void register_result_type (string name, ListModel results, bool permanent = true) {
        var result_type = new ResultType (name, results);
        result_type.notify["best-result-relevancy"].connect (() => result_type_sorter.changed (DIFFERENT));

        var pos = permanent ? permanent_result_types_index++ : result_types.n_items;
        result_types.insert (pos, result_type);
    }

    internal void clear_temporary_result_types () {
        result_types.splice (permanent_result_types_index, result_types.n_items - permanent_result_types_index, {});
    }

    /**
     * Registers a new result type with the given name.
     * The returned id can then be used to use the convenience API
     * {@link add_result} and {@link commit_results}.
     * The result type will also be automatically cleared when a search is ended.
     */
    public uint register_result_type_simple (string name) {
        var store = new ResultListStore ();
        result_stores.add (store);

        register_result_type (name, store);

        return result_stores.length - 1;
    }

    /**
     * Adds a result to the result type with the given id. The result will not be
     * immediately visible but only after {@link commit_results} has been called.
     *
     * @param result_type_id An id obtained from {@link register_result_type_simple}
     */
    public void add_result (uint result_type_id, Result result) {
        result_stores[result_type_id].append (result);
    }

    /**
     * Replaces the currently visible results of the result type with the given id
     * with the results added using {@link add_result} since the last commit.
     *
     * @param result_type_id An id obtained from {@link register_result_type_simple}
     */
    public void commit_results (uint result_type_id) {
        result_stores[result_type_id].commit ();
    }

    internal void clear () {
        foreach (var store in result_stores) {
            store.commit ();
        }
    }
}
