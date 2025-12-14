/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public abstract class Detective.SearchProvider : Object {
    /**
     * This will be called before any call to {@link search}. The implementation
     * should register its result types with the given aggregator. The result listmodel
     * given when registering a result type should then be updated on every call to {@link search}.
     * See {@link ResultAggregator.register_result_type}.
     */
    public virtual void register_with_aggregator (ResultAggregator aggregator) {}

    /**
     * Called when the search term changes. The SearchProvider implementation
     * is responsible for caching previous search terms and updating the results
     * accordingly. If a search was ended completly by the user clear is called
     * meaning the implementation should remove all results from the model and treat
     * a new call to search as a completely separate search.
     */
    public abstract void search (Query query, ResultAggregator aggregator);

    /**
     * Called when a current search is ended by the user. The implementation should cancel
     * any ongoing queries, remove all results from the list and treat a new call to search
     * as a completely separate search.
     */
    public virtual void clear () {}
}
