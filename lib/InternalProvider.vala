/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Detective.InternalProvider : SearchProvider {
    private ListStore results;
    private Gtk.FilterListModel filter_model;
    private Gtk.StringFilter filter;

    construct {
        results = new ListStore (typeof (Match));

        filter = new Gtk.StringFilter (new Gtk.PropertyExpression (typeof (Match), null, "title")) {
            match_mode = SUBSTRING,
            ignore_case = true
        };

        filter_model = new Gtk.FilterListModel (null, filter) {
            incremental = true
        };

        var match_types = new ListStore (typeof (MatchType));
        match_types.append (new MatchType (_("Detective"), filter_model));

        this.match_types = match_types;
    }

    public override void search (Query query) {
        filter_model.model = results;
        filter.search = query.search_term;
    }

    public override void clear () {
        filter_model.model = null;
    }
}
