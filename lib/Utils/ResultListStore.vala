/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Detective.ResultListStore : Object, ListModel {
    private GenericArray<Result> results;
    private GenericArray<Result> new_results;

    construct {
        results = new GenericArray<Result> ();
        new_results = new GenericArray<Result> (10);
    }

    public void append (Result result) {
        new_results.add (result);
    }

    public void commit () {
        var old_n_results = results.length;

        results = new_results;
        new_results = new GenericArray<Result> (10);

        items_changed (0, old_n_results, results.length);
    }

    public Type get_item_type () {
        return typeof (Result);
    }

    public uint get_n_items () {
        return results.length;
    }

    public Object? get_item (uint position) {
        if (position >= results.length) {
            return null;
        }

        return results[position];
    }
}
