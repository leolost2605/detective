/**
 * Automatically loads plugins and queries them for searches.
 * Used for implementing frontends.
 */
public class Detective.Engine : Object {
    private const int DEFAULT_RESULT_NUMBER = 10;

    public ListModel matches { get; construct; }

    private ListStore search_providers;
    private PluginLoader plugin_loader;

    private Query? current_query;

    construct {
        search_providers = new ListStore (typeof (SearchProvider));
        search_providers.append (new InternalProvider ());

        var map_model = new Gtk.MapListModel (search_providers, (obj) => {
            return ((SearchProvider) obj).match_types;
        });

        var flatten_model = new Gtk.FlattenListModel (map_model);

        var match_type_sorter = new Gtk.NumericSorter (new Gtk.PropertyExpression (typeof (MatchType), null, "best-match-relevancy"));

        var match_type_sort_model = new Gtk.SortListModel (flatten_model, match_type_sorter);

        var match_model = new Gtk.MapListModel (match_type_sort_model, (obj) => {
            return ((MatchType) obj).results;
        });

        matches = new Gtk.FlattenListModel (match_model);

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

        current_query = new Query (search_term, DEFAULT_RESULT_NUMBER);

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
