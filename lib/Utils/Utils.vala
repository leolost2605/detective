/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

namespace Detective.Utils {
    public static ListModel create_sort_and_slice_model (ListModel results) {
        var relevancy_sorter = new Gtk.NumericSorter (new Gtk.PropertyExpression (typeof (Result), null, "relevancy")) {
            sort_order = DESCENDING
        };

        var sort_model = new Gtk.SortListModel (results, relevancy_sorter);
        return new Gtk.SliceListModel (sort_model, 0, 5);
    }
}
