/**
 * Automatically loads plugins and queries them for searches.
 * Used for implementing frontends.
 */
public class Detective.Engine : Object {
    public Gtk.SortListModel matches { get; construct; }

    private ListStore search_providers;
    private PluginLoader plugin_loader;

    construct {
        search_providers = new ListStore (typeof (SearchProvider));

        var map_model = new Gtk.MapListModel (search_providers, (obj) => {
            return ((SearchProvider) obj).matches;
        });

        var flatten_model = new Gtk.FlattenListModel (map_model);

        var section_sorter = new Gtk.StringSorter (MatchType.expression);
        var relevancy_sorter = new Gtk.NumericSorter (Match.relevancy_expression);

        matches = new Gtk.SortListModel (flatten_model, relevancy_sorter) {
            //  section_sorter = section_sorter
        };

        plugin_loader = new PluginLoader ();

        foreach (var provider in plugin_loader.providers) {
            search_providers.append (provider);
        }
    }

    public void search (string search_term) {
        for (int i = 0; i < search_providers.get_n_items (); i++) {
            ((SearchProvider) search_providers.get_item (i)).search (search_term);
        }
    }

    public void clear_search () {
        for (int i = 0; i < search_providers.get_n_items (); i++) {
            ((SearchProvider) search_providers.get_item (i)).clear ();
        }
    }
}
