/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Detective.SearchWindow : Gtk.ApplicationWindow {
    public const int MAX_HEIGHT = 300;

    public Engine engine { get; construct; }

    //Used in signal handlers so make them fields to avoid memory leaks
    private Gtk.SearchEntry entry;
    private Gtk.SingleSelection selection_model;
    private Gtk.ListView list_view;
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
            search_delay = 100
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

        list_view = new Gtk.ListView (selection_model, factory) {
            single_click_activate = true,
            header_factory = header_factory
        };
        list_view.add_css_class (Granite.STYLE_CLASS_BACKGROUND);

        scrolled_window = new Gtk.ScrolledWindow () {
            child = list_view,
            propagate_natural_height = true,
            max_content_height = MAX_HEIGHT,
        };

        var preview = new Preview (selection_model);

        var paned = new Gtk.Paned (HORIZONTAL) {
            start_child = scrolled_window,
            end_child = preview,
        };
        selection_model.bind_property (
            "n-items", paned, "visible", SYNC_CREATE,
            (binding, from_value, ref to_value) => {
                to_value.set_boolean (from_value.get_uint () > 0);
                return true;
            }
        );

        var toolbar_view = new Adw.ToolbarView () {
            content = paned
        };
        toolbar_view.add_top_bar (entry);

        resizable = false;
        child = toolbar_view;
        titlebar = new Gtk.Grid () { visible = false };
        default_width = 700;
        hide_on_close = true;

        notify["is-active"].connect (on_is_active_changed);
        close_request.connect (on_close_request);
        map.connect (() => entry.grab_focus ());

        entry.search_changed.connect (() => {
            if (entry.text.strip () != "") {
                engine.search (entry.text);
            } else {
                engine.clear_search ();
            }
        });

        entry.activate.connect (on_entry_activated);
        entry.stop_search.connect (close);

        list_view.activate.connect (activate_match);

        var key_controller = new Gtk.EventControllerKey ();
        key_controller.key_pressed.connect (on_key_pressed);
        child.add_controller (key_controller);

        selection_model.items_changed.connect_after (on_items_changed);
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

    private void on_is_active_changed () {
        if (!is_active) {
            close ();
        }
    }

    private bool on_close_request () {
        engine.clear_search ();
        entry.text = "";
        return false;
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
        close ();
    }

    private bool on_key_pressed (uint keyval, uint keycode) {
        if (keyval == Gdk.Key.Escape) {
            close ();
            return Gdk.EVENT_STOP;
        }

        return Gdk.EVENT_PROPAGATE;
    }

    private void on_items_changed () {
        if (selection_model.get_n_items () > 0) {
            list_view.scroll_to (0, SELECT, null);
        }
    }
}
