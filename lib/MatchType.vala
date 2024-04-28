
/**
 * Specifies the type of a match. Matches of the same type are grouped together.
 */
public class MatchType : Object {
    /**
     * The name of the MatchType. Shown to the user in a header.
     */
    public string name { get; construct; }

    /**
     * The relevancy of the best match this type currently has.
     */
    public int best_match_relevancy { get; private set; }

    public MatchType (string name) {
        Object (name: name);
    }

    public void add_relevancy (int relevancy) {
        if (relevancy > best_match_relevancy) {
            best_match_relevancy = relevancy;
        }
    }

    public void clear_relevancy () {
        best_match_relevancy = 0;
    }
}
