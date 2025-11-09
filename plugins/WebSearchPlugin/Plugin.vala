/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Fernando Júnior Gomes da Silva <fernandojunior20110@gmail.com>
 */

public class Detective.WebSearchMatch : Match {
    public string search_engine { get; construct; }
    public string search_query { get; construct; }
    public string url { get; construct; }

    public WebSearchMatch (string search_engine, string search_query, string url) {
        var icon = new ThemedIcon ("system-search");

        // Translators: %s is the search query, %s is the search engine name
        string match_title = _("Search \"%s\" on %s").printf (search_query, search_engine);

        Object (
            relevancy: Relevancy.LOWEST,
            search_engine: search_engine,
            search_query: search_query,
            url: url,
            title: match_title,
            description: url,
            icon: icon
        );
    }

    public override async void activate () throws Error {
        Process.spawn_command_line_async (@"flatpak-spawn --host xdg-open \"$url\"");
    }
}

public class Detective.WebSearchProvider : SearchProvider {
    private const SearchEngine[] SEARCH_ENGINES = {
        { "Google", "https://www.google.com/search?q=%s" },
        { "DuckDuckGo", "https://duckduckgo.com/?q=%s" },
        { "Bing", "https://www.bing.com/search?q=%s" },
    };

    private struct SearchEngine {
        string name;
        string url_template;
    }

    private ListStore matches_internal;

    construct {
        matches_internal = new ListStore (typeof (Match));

        var match_types = new ListStore (typeof (MatchType));
        match_types.append (new MatchType (_("Web Search"), matches_internal));
        this.match_types = match_types;
    }

    public override void search (Query query) {
        matches_internal.remove_all ();

        // Só mostra resultados se houver pelo menos 2 caracteres
        if (query.search_term.length < 2) {
            return;
        }

        // Codifica a query para URL
        string encoded_query = Uri.escape_string (query.search_term, null, true);

        // Cria um match para cada search engine
        foreach (var engine in SEARCH_ENGINES) {
            string url = engine.url_template.printf (encoded_query);
            var match = new WebSearchMatch (engine.name, query.search_term, url);
            matches_internal.append (match);
        }
    }

    public override void clear () {
        matches_internal.remove_all ();
    }
}

public Detective.WebSearchProvider get_provider () {
    return new Detective.WebSearchProvider ();
}
