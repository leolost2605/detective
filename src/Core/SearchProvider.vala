public abstract class SearchProvider : Object {
    public ListModel matches { get; set; }

    /**
     * Called when the search term changes. The SearchProvider implementation
     * is responsible for caching previous search terms and updating the matches
     * accordingly. If a search was ended completly by the user clear is called
     * meaning the implementation should remove all matches from the model and treat
     * a new call to search as a completely separate search.
     */
    public abstract void search (string search_term);

    /**
     * Called when a current search is ended by the user. The implementation should cancel
     * any ongoing queries, remove all matches from the list and treat a new all to search
     * as a completely separate search.
     */
    public abstract void clear ();
}
