/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Detective.Preview : Granite.Bin {
    public Gtk.SingleSelection selection { get; construct; }

    private Gtk.ScrolledWindow scrolled_window;
    private GenericPreview generic_preview;

    public Preview (Gtk.SingleSelection selection) {
        Object (selection: selection);
    }

    construct {
        scrolled_window = new Gtk.ScrolledWindow () {
            propagate_natural_height = true,
            max_content_height = SearchWindow.MAX_HEIGHT,
        };

        child = scrolled_window;

        generic_preview = new GenericPreview ();

        selection.notify["selected-item"].connect (on_selected_item_changed);
    }

    private void on_selected_item_changed () {
        var match = (Match) selection.selected_item;

        if (match == null) {
            scrolled_window.child = null;
            return;
        }

        var custom_preview = match.get_custom_preview ();
        if (custom_preview != null) {
            scrolled_window.child = custom_preview;
            return;
        }

        generic_preview.bind (match);
        scrolled_window.child = generic_preview;
    }
}
