/**
 * Automatically loads plugins and queries them for searches.
 * Used for implementing frontends.
 */
public class Detective.Engine : Object {
    public Gtk.SortListModel matches { get; construct; }

    private ListStore search_providers;
    private PluginLoader plugin_loader;

    private Query? current_query;

    construct {
        search_providers = new ListStore (typeof (SearchProvider));

        var map_model = new Gtk.MapListModel (search_providers, (obj) => {
            return ((SearchProvider) obj).matches;
        });

        var flatten_model = new Gtk.FlattenListModel (map_model);

        var section_sorter = new Gtk.StringSorter (MatchType.expression);
        var relevancy_sorter = new Gtk.NumericSorter (Match.relevancy_expression) {
            sort_order = DESCENDING
        };

        matches = new Gtk.SortListModel (flatten_model, relevancy_sorter) {
            //  section_sorter = section_sorter
        };

        plugin_loader = new PluginLoader ();

        foreach (var provider in plugin_loader.providers) {
            search_providers.append (provider);
        }
    }

    private void cancel_current_query () {
        if (current_query != null) {
            current_query.cancel ();
        }
    }

    public void search (string search_term) {
        cancel_current_query ();

        current_query = new Query (search_term);

        for (int i = 0; i < search_providers.get_n_items (); i++) {
            ((SearchProvider) search_providers.get_item (i)).search (current_query);
        }
    }

    public void clear_search () {
        cancel_current_query ();

        current_query = null;

        for (int i = 0; i < search_providers.get_n_items (); i++) {
            ((SearchProvider) search_providers.get_item (i)).clear ();
        }
    }
}
