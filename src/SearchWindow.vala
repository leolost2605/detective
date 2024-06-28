public class Detective.SearchWindow : Gtk.ApplicationWindow {
    public Engine engine { get; construct; }

    //Used in signal handlers so make them fields to avoid memory leaks
    private Gtk.SearchEntry entry;
    private Gtk.SingleSelection selection_model;
    private Gtk.ListView list_view;
    private Gtk.ScrolledWindow scrolled_window;
    private Gtk.Stack stack;

    public SearchWindow (Application app, Engine engine) {
        Object (application: app, engine: engine);
    }

    construct {
        entry = new Gtk.SearchEntry () {
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6
        };

        selection_model = new Gtk.SingleSelection (engine.matches) {
            autoselect = false,
            can_unselect = true
        };

        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect ((obj) => {
            var list_item = (Gtk.ListItem) obj;
            list_item.child = new MatchRow ();
        });

        factory.bind.connect ((obj) => {
            var list_item = (Gtk.ListItem) obj;
            var item = (Match) list_item.item;
            ((MatchRow) list_item.child).bind (item);
        });

        var header_factory = new Gtk.SignalListItemFactory ();
        header_factory.setup.connect ((obj) => {
            var list_header = (Gtk.ListHeader) obj;
            list_header.child = new Granite.HeaderLabel ("");
        });

        header_factory.bind.connect ((obj) => {
            var list_header = (Gtk.ListHeader) obj;
            var item = (Match) list_header.item;
            ((Granite.HeaderLabel) list_header.child).label = item.match_type_name;
        });

        list_view = new Gtk.ListView (selection_model, factory) {
            vexpand = true,
            single_click_activate = true,
            header_factory = header_factory
        };
        list_view.add_css_class (Granite.STYLE_CLASS_RICH_LIST);
        list_view.add_css_class (Granite.STYLE_CLASS_BACKGROUND);

        var view_port = new Gtk.Viewport (null, null) {
            child = list_view,
            scroll_to_focus = false
        };

        scrolled_window = new Gtk.ScrolledWindow () {
            child = view_port
        };

        var placeholder = new Granite.Placeholder (_("Start typing to search")) {
            icon = new ThemedIcon ("system-search")
        };

        stack = new Gtk.Stack ();
        stack.add_named (placeholder, "placeholder");
        stack.add_named (scrolled_window, "list");

        var content = new Gtk.Box (VERTICAL, 6);
        content.append (entry);
        content.append (stack);

        resizable = false;
        child = content;
        titlebar = new Gtk.Grid () { visible = false };

        entry.search_changed.connect (() => {
            if (entry.text.strip () != "") {
                engine.search (entry.text);
            } else {
                engine.clear_search ();
            }
        });

        list_view.activate.connect ((position) => {
            var match = (Match) engine.matches.get_item (position);
            match.activate.begin ((obj, res) => {
                try {
                    match.activate.end (res);
                } catch (Error e) {
                    warning (e.message);
                }

                destroy ();
            });
        });

        entry.activate.connect (() => {
            if (selection_model.selected != Gtk.INVALID_LIST_POSITION) {
                list_view.activate (selection_model.selected);
            }
        });

        entry.stop_search.connect (destroy);

        selection_model.items_changed.connect (() => Idle.add (update_vadjustment));

        weak_ref (engine.clear_search);
    }

    private bool update_vadjustment () {
        scrolled_window.vadjustment.value = 0;
        selection_model.selected = 0;

        if (selection_model.n_items > 0) {
            stack.visible_child_name = "list";
        } else {
            stack.visible_child_name = "placeholder";
        }

        return Source.REMOVE;
    }
}
