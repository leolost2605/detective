/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Detective.SearchWindow : Gtk.ApplicationWindow {
    public Engine engine { get; construct; }

    //Used in signal handlers so make them fields to avoid memory leaks
    private Gtk.SearchEntry entry;
    private Gtk.SingleSelection selection_model;
    private Gtk.ScrolledWindow scrolled_window;

    public SearchWindow (Application app, Engine engine) {
        Object (application: app, engine: engine);
    }

    construct {
        entry = new Gtk.SearchEntry () {
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6,
            placeholder_text = _("Search apps, files and more..."),
        };

        selection_model = new Gtk.SingleSelection (engine.matches) {
            autoselect = false,
            can_unselect = true
        };

        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (on_row_setup);
        factory.bind.connect (on_row_bind);

        var header_factory = new Gtk.SignalListItemFactory ();
        header_factory.setup.connect (on_header_setup);
        header_factory.bind.connect (on_header_bind);

        var list_view = new Gtk.ListView (selection_model, factory) {
            single_click_activate = true,
            header_factory = header_factory
        };

        scrolled_window = new Gtk.ScrolledWindow () {
            child = list_view,
            propagate_natural_height = true,
            max_content_height = 400,
        };
        selection_model.bind_property (
            "n-items", scrolled_window, "visible", SYNC_CREATE,
            (binding, from_value, ref to_value) => {
                to_value.set_boolean (from_value.get_uint () > 0);
                return true;
            }
        );

        var toolbar_view = new Adw.ToolbarView () {
            content = scrolled_window
        };
        toolbar_view.add_top_bar (entry);

        resizable = false;
        child = toolbar_view;
        titlebar = new Gtk.Grid () { visible = false };
        default_width = 500;

        entry.search_changed.connect (() => {
            if (entry.text.strip () != "") {
                engine.search (entry.text);
            } else {
                engine.clear_search ();
            }
        });

        entry.activate.connect (on_entry_activated);
        entry.stop_search.connect (hide);

        list_view.activate.connect (activate_match);

        var key_controller = new Gtk.EventControllerKey ();
        key_controller.key_pressed.connect (on_key_pressed);
        child.add_controller (key_controller);

        selection_model.items_changed.connect (() => Idle.add (update_vadjustment));

        hide.connect (() => {
            engine.clear_search ();
            entry.text = "";
            entry.grab_focus ();
        });
    }

    private void on_row_setup (Object obj) {
        var list_item = (Gtk.ListItem) obj;
        list_item.child = new MatchRow ();
    }

    private void on_row_bind (Object obj) {
        var list_item = (Gtk.ListItem) obj;
        var item = (Match) list_item.item;
        ((MatchRow) list_item.child).bind (item);
    }

    private void on_header_setup (Object obj) {
        var list_header = (Gtk.ListHeader) obj;
        list_header.child = new Granite.HeaderLabel ("");
    }

    private void on_header_bind (Object obj) {
        var list_header = (Gtk.ListHeader) obj;
        var item = (Match) list_header.item;
        ((Granite.HeaderLabel) list_header.child).label = item.match_type_name;
    }

    private void on_entry_activated () {
        activate_match.begin (selection_model.selected);
    }

    private async void activate_match (uint position) {
        var match = (Match) engine.matches.get_item (position);

        if (match == null) {
            return;
        }

        try {
            yield match.activate ();
        } catch (Error e) {
            warning (e.message);
        }
        hide ();
    }

    private bool on_key_pressed (uint keyval, uint keycode) {
        if (keyval == Gdk.Key.Escape) {
            hide ();
            return Gdk.EVENT_STOP;
        }

        return Gdk.EVENT_PROPAGATE;
    }

    private bool update_vadjustment () {
        scrolled_window.vadjustment.value = 0;
        selection_model.selected = 0;
        return Source.REMOVE;
    }
}
