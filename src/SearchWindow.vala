
public class Detective.SearchWindow : Gtk.ApplicationWindow {
    private Engine engine;

    public SearchWindow (Application app) {
        Object (application: app);
    }

    construct {
        engine = new Engine ();

        var entry = new Gtk.SearchEntry ();

        var selection_model = new Gtk.SingleSelection (engine.matches);

        var factory = new Gtk.SignalListItemFactory ();
        factory.bind.connect ((obj) => {
            var list_item = (Gtk.ListItem) obj;
            var item = (Match) list_item.item;
            list_item.child = new Gtk.Label (item.text);
        });

        var list_view = new Gtk.ListView (selection_model, factory);

        var content = new Gtk.Box (VERTICAL, 6);
        content.append (entry);
        content.append (list_view);

        child = content;
        titlebar = new Gtk.Grid () { visible = false };

        entry.search_changed.connect (() => engine.search (entry.text));
    }
}
