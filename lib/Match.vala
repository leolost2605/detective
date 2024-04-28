public class Match : Object {
    internal static Gtk.Expression relevancy_expression = new Gtk.PropertyExpression (typeof (Match), null, "relevancy");

    public MatchType match_type { get; construct; }
    public int relevancy { get; construct; }
    public string title { get; construct; }

    public string? description { get; construct; }
    public Icon? icon { get; construct; }
    public Gdk.Paintable? paintable { get; construct; }

    public Match (MatchType match_type, int relevancy, string title, string? description, Icon? icon, Gdk.Paintable? paintable) {
        Object (
            match_type: match_type,
            relevancy: relevancy,
            title: title,
            description: description,
            icon: icon,
            paintable: paintable
        );
    }

    public virtual async void activate () throws Error {
        warning ("Activated match without implemented activate func");
    }
}
