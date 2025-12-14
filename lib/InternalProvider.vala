/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Detective.InternalProvider : SearchProvider {
    private ListStore results;
    private Gtk.FilterListModel filter_model;
    private Gtk.StringFilter filter;

    public override void register_with_aggregator (ResultAggregator aggregator) {
        results = new ListStore (typeof (Result));

        filter = new Gtk.StringFilter (new Gtk.PropertyExpression (typeof (Result), null, "title")) {
            match_mode = SUBSTRING,
            ignore_case = true
        };

        filter_model = new Gtk.FilterListModel (null, filter) {
            incremental = true
        };

        aggregator.register_result_type (_("Detective"), filter_model);
    }

    public override void search (Query query, ResultAggregator aggregator) {
        filter_model.model = results;
        filter.search = query.search_term;
    }

    public override void clear () {
        filter_model.model = null;
    }
}
