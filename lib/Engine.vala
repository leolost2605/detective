/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

/**
 * Automatically loads plugins and queries them for searches.
 * Used for implementing frontends.
 */
public class Detective.Engine : Object {
    private const int DEFAULT_RESULT_NUMBER = 10;

    /**
     * A model containing all matches from all search providers matching the current query.
     * The matches are grouped in sections by their category where the first section
     * is the section with the match that has the highest relevancy. Within a section
     * the matches are also sorted by relevancy descending.
     */
    public Gtk.SectionModel matches { get { return aggregator.results; } }

    private ResultAggregator aggregator;

    private ListStore search_providers;
    private PluginLoader plugin_loader;

    private Query? current_query;

    construct {
        aggregator = new ResultAggregator ();

        search_providers = new ListStore (typeof (SearchProvider));
        search_providers.append (new InternalProvider ());

        plugin_loader = new PluginLoader ();

        foreach (var provider in plugin_loader.providers) {
            search_providers.append (provider);
        }

        for (int i = 0; i < search_providers.get_n_items (); i++) {
            ((SearchProvider) search_providers.get_item (i)).register_with_aggregator (aggregator);
        }
    }

    private void cancel_current_query () {
        if (current_query != null) {
            current_query.cancel ();
        }

        aggregator.clear_temporary_result_types ();
    }

    public void search (string search_term) {
        cancel_current_query ();

        current_query = new Query (search_term, DEFAULT_RESULT_NUMBER);

        for (int i = 0; i < search_providers.get_n_items (); i++) {
            ((SearchProvider) search_providers.get_item (i)).search (current_query, aggregator);
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
