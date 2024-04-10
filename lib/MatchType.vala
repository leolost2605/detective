
/**
 * Specifies the type of a match. Matches of the same type are grouped together.
 */
public class MatchType : Object {
    public static Gtk.Expression expression = new Gtk.PropertyExpression (typeof (MatchType), Match.match_type_expression, "id");

    /**
     * Used for comparing, i.e. whether two matches are the same
     */
    public string id { get; construct; }

    /**
     * The name of the MatchType. Shown to the user in a header.
     */
    public string name { get; construct; }

    public MatchType (string id, string name) {
        Object (id: id, name: name);
    }
}
