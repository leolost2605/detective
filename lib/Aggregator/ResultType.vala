/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

/**
 * Specifies the type of a result. Results of the same type are grouped together.
 */
internal class Detective.ResultType : Object {
    /**
     * The name of the ResultType. Shown to the user in a header.
     */
    public string name { get; construct; }

    /**
     * The relevancy of the best result this type currently has.
     */
    public int best_result_relevancy { get; private set; }

    /**
     * The results that belong to this result type.
     */
    public ListModel results { get; construct; }

    public ResultType (string name, ListModel results) {
        var relevancy_sorter = new Gtk.NumericSorter (new Gtk.PropertyExpression (typeof (Match), null, "relevancy")) {
            sort_order = DESCENDING
        };

        var sort_model = new Gtk.SortListModel (results, relevancy_sorter);
        var slice_model = new Gtk.SliceListModel (sort_model, 0, 5);

        Object (name: name, results: slice_model);
    }

    construct {
        results.items_changed.connect (on_items_changed);
    }

    private void on_items_changed (uint position, uint removed, uint added) {
        for (uint i = position; i < position + added; i++) {
            var match = (Match) results.get_item (i);
            match.match_type_name = name;
        }

        if (position == 0) {
            best_result_relevancy = results.get_n_items () > 0 ? ((Match) results.get_item (0)).relevancy : 0;
        }
    }
}
