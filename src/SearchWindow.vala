public class Detective.SearchWindow : Gtk.ApplicationWindow {
    private Engine engine;

    public SearchWindow (Application app) {
        Object (application: app);
    }

    construct {
        engine = new Engine ();

        var entry = new Gtk.SearchEntry () {
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6
        };

        var selection_model = new Gtk.SingleSelection (engine.matches) {
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

        var list_view = new Gtk.ListView (selection_model, factory) {
            vexpand = true,
            single_click_activate = true
        };
        list_view.add_css_class (Granite.STYLE_CLASS_RICH_LIST);

        var scrolled_window = new Gtk.ScrolledWindow () {
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
            ((Match) engine.matches.get_item (position)).activated ();
            destroy ();
        });

        entry.activate.connect (() => {
            list_view.activate (selection_model.selected);
        });
    }
}
