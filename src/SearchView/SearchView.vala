/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Detective.SearchView : Granite.Bin {
    private const int MAX_HEIGHT = 300;

    public Engine engine { get; construct; }

    private Gtk.SingleSelection selection_model;
    private Gtk.ListView list_view;
    private Gtk.ScrolledWindow scrolled_window;

    public SearchView (Engine engine) {
        Object (engine: engine);
    }

    construct {
        selection_model = new Gtk.SingleSelection (engine.results) {
            autoselect = false,
            can_unselect = true
        };

        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (on_row_setup);
        factory.bind.connect (on_row_bind);

        var header_factory = new Gtk.SignalListItemFactory ();
        header_factory.setup.connect (on_header_setup);
        header_factory.bind.connect (on_header_bind);

        list_view = new Gtk.ListView (selection_model, factory) {
            single_click_activate = true,
            header_factory = header_factory
        };
        list_view.add_css_class ("results-list");
        list_view.add_css_class (Granite.STYLE_CLASS_BACKGROUND);

        scrolled_window = new Gtk.ScrolledWindow () {
            child = list_view,
            propagate_natural_height = true,
            hscrollbar_policy = NEVER,
        };

        var preview = new Preview (selection_model);

        var box = new Granite.Box (HORIZONTAL, DOUBLE) {
            homogeneous = true,
        };
        box.append (scrolled_window);
        box.append (preview);

        //  var clamp = new Adw.Clamp () {
        //      child = box,
        //      orientation = VERTICAL,
        //      maximum_size = MAX_HEIGHT,
        //  };
        //  selection_model.bind_property (
        //      "n-items", clamp, "visible", SYNC_CREATE,
        //      (binding, from_value, ref to_value) => {
        //          to_value.set_boolean (from_value.get_uint () > 0);
        //          return true;
        //      }
        //  );

        child = box;

        list_view.activate.connect (activate_result);

        selection_model.items_changed.connect_after (on_items_changed);
    }

    private void on_row_setup (Object obj) {
        var list_item = (Gtk.ListItem) obj;
        list_item.child = new ResultRow ();
    }

    private void on_row_bind (Object obj) {
        var list_item = (Gtk.ListItem) obj;
        var item = (Result) list_item.item;
        ((ResultRow) list_item.child).bind (item);
    }

    private void on_header_setup (Object obj) {
        var label = new Gtk.Label (null) {
            halign = START
        };
        label.add_css_class ("result-heading");

        var list_header = (Gtk.ListHeader) obj;
        list_header.child = label;
    }

    private void on_header_bind (Object obj) {
        var list_header = (Gtk.ListHeader) obj;
        var item = (Result) list_header.item;
        ((Gtk.Label) list_header.child).label = item.result_type_name;
    }

    public void activate_selected () {
        activate_result.begin (selection_model.selected);
    }

    private async void activate_result (uint position) {
        var result = (Result) engine.results.get_item (position);

        if (result == null) {
            return;
        }

        try {
            yield result.activate ();
        } catch (Error e) {
            warning (e.message);
        }

        close ();
    }

    private void on_items_changed () {
        if (selection_model.get_n_items () > 0) {
            list_view.scroll_to (0, SELECT, null);
        }
    }

    private void close () {
        activate_action_variant ("window.close", null);
    }
}
