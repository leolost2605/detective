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
            search_delay = 0
        };

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
        list_view.add_css_class (Granite.STYLE_CLASS_BACKGROUND);

        scrolled_window = new Gtk.ScrolledWindow () {
            child = list_view,
            propagate_natural_height = true,
            max_content_height = MAX_HEIGHT,
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

        var hint_box = new Gtk.Box (HORIZONTAL, 12) {
            margin_start = 12,
            margin_end = 12,
            margin_top = 6,
            margin_bottom = 6,
            halign = Gtk.Align.END
        };

        var nav_box = new Gtk.Box (HORIZONTAL, 6);
        var nav_key = new Gtk.Label ("Tab");
        nav_key.add_css_class ("keycap");
        var nav_desc = new Gtk.Label ("Navegar");
        nav_desc.add_css_class ("dim-label");
        nav_box.append (nav_key);
        nav_box.append (nav_desc);

        var enter_box = new Gtk.Box (HORIZONTAL, 6);
        var enter_key = new Gtk.Label ("Enter");
        enter_key.add_css_class ("keycap");
        var enter_desc = new Gtk.Label ("Abrir");
        enter_desc.add_css_class ("dim-label");
        enter_box.append (enter_key);
        enter_box.append (enter_desc);

        var action_box = new Gtk.Box (HORIZONTAL, 6);
        var action_key = new Gtk.Label ("→");
        action_key.add_css_class ("keycap");
        var action_desc = new Gtk.Label ("Acciones");
        action_desc.add_css_class ("dim-label");
        action_box.append (action_key);
        action_box.append (action_desc);

        hint_box.append (nav_box);
        hint_box.append (enter_box);
        hint_box.append (action_box);

        selection_model.bind_property (
            "n-items", hint_box, "visible", SYNC_CREATE,
            (binding, from_value, ref to_value) => {
                to_value.set_boolean (from_value.get_uint () > 0);
                return true;
            }
        );

        toolbar_view.add_bottom_bar (hint_box);

        resizable = false;
        child = toolbar_view;
        titlebar = new Gtk.Grid () { visible = false };
        default_width = 650; // Un poco más estrecho al no tener panel de vista previa
        hide_on_close = true;

        // ESTO SOLUCIONA EL BUG DE ENFOQUE AL BAJAR CON FLECHAS
        entry.set_key_capture_widget (this);

        notify["is-active"].connect (on_is_active_changed);
        close_request.connect (on_close_request);
        map.connect (() => entry.grab_focus ());

        entry.search_changed.connect (() => {
            if (in_actions_view) {
                if (actions_filter != null) {
                    actions_filter.changed (Gtk.FilterChange.DIFFERENT);
                }
                return;
            }

            if (entry.text.strip () != "") {
                engine.search (entry.text);
            } else {
                engine.clear_search ();
            }
        });

        entry.activate.connect (on_entry_activated);
        entry.stop_search.connect (close);

        list_view.activate.connect (activate_result);

        var key_controller = new Gtk.EventControllerKey ();
        key_controller.set_propagation_phase (Gtk.PropagationPhase.CAPTURE);
        key_controller.key_pressed.connect (on_key_pressed);
        child.add_controller (key_controller);

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
        var list_header = (Gtk.ListHeader) obj;
        list_header.child = new Granite.HeaderLabel ("");
    }

    private void on_header_bind (Object obj) {
        var list_header = (Gtk.ListHeader) obj;
        var item = (Result) list_header.item;
        ((Granite.HeaderLabel) list_header.child).label = item.result_type_name;
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
        var sel_model = (Gtk.SingleSelection) list_view.model;
        if (sel_model.selected != Gtk.INVALID_LIST_POSITION) {
            activate_result.begin (sel_model.selected);
        }
    }

    private bool in_actions_view = false;
    private string previous_search = "";
    private Gtk.CustomFilter actions_filter = null;
    private GLib.ListModel current_actions = null;

    private void show_actions (Result result, GLib.ListModel actions) {
        in_actions_view = true;
        previous_search = entry.text;
        current_actions = actions;
        
        for (uint i = 0; i < actions.get_n_items (); i++) {
            var a = (Result) actions.get_item (i);
            if (a != null) {
                a.result_type_name = result.title;
            }
        }

        actions_filter = new Gtk.CustomFilter ((obj) => {
            if (entry.text.strip () == "") return true;
            var r = (Result) obj;
            return r.title.down ().contains (entry.text.down ().strip ()) ||
                   (r.description != null && r.description.down ().contains (entry.text.down ().strip ()));
        });

        var filter_model = new Gtk.FilterListModel (actions, actions_filter);
        var actions_selection = new Gtk.SingleSelection (filter_model) {
            autoselect = true
        };
        list_view.model = actions_selection;

        // Limpiar el texto para dejar buscar en el drill-down
        entry.text = "";
        entry.placeholder_text = result.title + " \u203A " + _("Buscar acciones...");
    }

    private void hide_actions () {
        if (in_actions_view) {
            in_actions_view = false;
            list_view.model = selection_model;
            entry.text = previous_search;
            entry.placeholder_text = _("Search apps, files and more...");
            current_actions = null;
            var editable = (Gtk.Editable) entry;
            editable.set_position (-1);
        }
    }

    private async void activate_result (uint position) {
        var sel_model = (Gtk.SingleSelection) list_view.model;
        var result = (Result) sel_model.get_item (position);

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

    private bool on_key_pressed (uint keyval, uint keycode) {
        if (keyval == Gdk.Key.Escape) {
            if (in_actions_view) {
                hide_actions ();
                return Gdk.EVENT_STOP;
            }
            close ();
            return Gdk.EVENT_STOP;
        } else if (keyval == Gdk.Key.Right) {
            var editable = (Gtk.Editable) entry;
            if (!in_actions_view && editable.get_position () < editable.get_text ().char_count ()) {
                return Gdk.EVENT_PROPAGATE;
            }

            if (!in_actions_view && selection_model.selected != Gtk.INVALID_LIST_POSITION) {
                var selected_item = engine.results.get_item (selection_model.selected);
                if (selected_item != null && selected_item is Result) {
                    var result = (Result) selected_item;
                    var actions = result.get_actions ();
                    if (actions != null && actions.get_n_items () > 0) {
                        show_actions (result, actions);
                        return Gdk.EVENT_STOP;
                    }
                }
            }
        } else if (keyval == Gdk.Key.Left) {
            if (in_actions_view) {
                hide_actions ();
                return Gdk.EVENT_STOP;
            }
        } else if (keyval == Gdk.Key.Tab || keyval == Gdk.Key.Down) {
            var sel_model = (Gtk.SingleSelection) list_view.model;
            var n_items = sel_model.get_n_items ();
            if (n_items > 0) {
                var next = sel_model.selected + 1;
                if (next >= n_items) next = 0;
                sel_model.select_item (next, true);
                list_view.scroll_to (next, Gtk.ListScrollFlags.SELECT, null);
                return Gdk.EVENT_STOP;
            }
        } else if (keyval == Gdk.Key.Up) {
            var sel_model = (Gtk.SingleSelection) list_view.model;
            var n_items = sel_model.get_n_items ();
            if (n_items > 0) {
                var prev = sel_model.selected;
                if (prev == 0) prev = n_items - 1;
                else prev--;
                sel_model.select_item (prev, true);
                list_view.scroll_to (prev, Gtk.ListScrollFlags.SELECT, null);
                return Gdk.EVENT_STOP;
            }
        } else if (keyval == Gdk.Key.BackSpace) {
            if (in_actions_view && entry.text.length == 0) {
                hide_actions ();
                return Gdk.EVENT_STOP;
            }
        }

        return Gdk.EVENT_PROPAGATE;
    }

    private void on_items_changed () {
        if (selection_model.get_n_items () > 0) {
            list_view.scroll_to (0, SELECT, null);
        }
    }
}
