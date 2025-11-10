/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Detective.Query : Object {
    public string search_term { get; construct; }
    public string[] search_tokens { get; construct; }

    public int n_results { get; construct; }

    public bool cancelled {
        get {
            return cancellable.is_cancelled ();
        }
    }

    public Cancellable cancellable { get; construct; }

    internal Query (string search_term, int n_results) {
        var tokens = search_term.tokenize_and_fold (null, null);
        Object (search_term: search_term, search_tokens: tokens, n_results: n_results);
    }

    construct {
        cancellable = new Cancellable ();
    }

    internal void cancel () {
        cancellable.cancel ();
    }
}
