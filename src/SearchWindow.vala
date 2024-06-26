public class Detective.SearchWindow : Gtk.ApplicationWindow {
    private Engine engine;

    //Used in signal handlers so make them fields to avoid memory leaks
    private Gtk.SearchEntry entry;
    private Gtk.SingleSelection selection_model;
    private Gtk.ListView list_view;
    private Gtk.ScrolledWindow scrolled_window;

    public SearchWindow (Application app) {
        Object (application: app);
    }

    construct {
        engine = new Engine ();

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
            ((Granite.HeaderLabel) list_header.child).label = item.match_type.name;
        });

        list_view = new Gtk.ListView (selection_model, factory) {
            vexpand = true,
            single_click_activate = true,
            header_factory = header_factory
        };
        list_view.add_css_class (Granite.STYLE_CLASS_RICH_LIST);

        scrolled_window = new Gtk.ScrolledWindow () {
            child = list_view
        };

        var content = new Gtk.Box (VERTICAL, 6);
        content.append (entry);
        content.append (scrolled_window);

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
            list_view.activate (selection_model.selected);
        });

        selection_model.items_changed.connect (() => Idle.add_once (() => {
            scrolled_window.vadjustment.value = 0;
            selection_model.selected = 0;
        }));
    }
}
