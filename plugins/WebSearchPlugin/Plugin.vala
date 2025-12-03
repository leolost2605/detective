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
        var launcher = new Gtk.UriLauncher (url);
        yield launcher.launch (null, null);
    }
}

public class Detective.OpenUrlMatch : Match {
    public string url { get; construct; }

    public OpenUrlMatch (string url) {
        var icon = new ThemedIcon ("applications-internet");

        // Translators: %s is the URL to open
        string match_title = _("Open %s").printf (url);

        Object (
            relevancy: Relevancy.HIGHEST,
            url: url,
            title: match_title,
            description: _("Open URL in browser"),
            icon: icon
        );
    }

    public override async void activate () throws Error {
        var launcher = new Gtk.UriLauncher (url);
        yield launcher.launch (null, null);
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

    private bool is_ipv4 (string text) {
        var parts = text.split (".");
        if (parts.length != 4) {
            return false;
        }

        foreach (var part in parts) {
            if (part.length == 0 || part.length > 3) {
                return false;
            }

            for (int i = 0; i < part.length; i++) {
                unichar c = part.get_char (i);
                if (c < '0' || c > '9') {
                    return false;
                }
            }

            int val = int.parse (part);
            if (val < 0 || val > 255) {
                return false;
            }
        }

        return true;
    }

    private bool is_ipv6 (string text) {
        if (!text.contains (":")) {
            return false;
        }

        var parts = text.split (":");
        if (parts.length < 2 || parts.length > 8) {
            return false;
        }

        foreach (var part in parts) {
            if (part.length == 0) {
                continue;
            }

            if (part.length > 4) {
                return false;
            }

            for (int i = 0; i < part.length; i++) {
                unichar c = part.get_char (i);
                bool is_hex = (c >= '0' && c <= '9') ||
                             (c >= 'a' && c <= 'f') ||
                             (c >= 'A' && c <= 'F');
                if (!is_hex) {
                    return false;
                }
            }
        }

        return true;
    }

    private bool is_url (string text) {
        if (text.has_prefix ("http://") || text.has_prefix ("https://")) {
            return true;
        }

        if (text.contains (" ")) {
            return false;
        }

        if (text.has_prefix ("www.")) {
            return true;
        }

        string base_part = text;

        if (base_part.contains ("?")) {
            base_part = base_part.split ("?")[0];
        }

        if (base_part.contains ("/")) {
            base_part = base_part.split ("/")[0];
        }

        if (base_part.contains (":")) {
            if (is_ipv6 (base_part)) {
                return true;
            }
            base_part = base_part.split (":")[0];
        }

        if (is_ipv4 (base_part)) {
            return true;
        }

        if (is_ipv6 (base_part)) {
            return true;
        }

        if (base_part.contains (".")) {
            var parts = base_part.split (".");
            if (parts.length >= 2) {
                // Get the last part (TLD)
                string tld = parts[parts.length - 1].down ();

                // TLDs usually have 2-6 characters and are alphabetic
                if (tld.length >= 2 && tld.length <= 6) {
                    // Check if it's alphabetic (a-z)
                    for (int i = 0; i < tld.length; i++) {
                        unichar c = tld.get_char (i);
                        if (c < 'a' || c > 'z') {
                            return false;
                        }
                    }
                    return true;
                }
            }
        }

        return false;
    }

    private string normalize_url (string text) {
        if (text.has_prefix ("http://") || text.has_prefix ("https://")) {
            return text;
        }

        return "https://" + text;
    }

    public override void search (Query query) {
        matches_internal.remove_all ();

        if (query.search_term.length < 2) {
            return;
        }

        if (is_url (query.search_term)) {
            string normalized_url = normalize_url (query.search_term);
            var open_url_match = new OpenUrlMatch (normalized_url);
            matches_internal.append (open_url_match);
            return; 
        }

        string encoded_query = Uri.escape_string (query.search_term, null, true);

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
