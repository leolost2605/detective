public class Match : Object {
    internal static Gtk.Expression relevancy_expression = new Gtk.PropertyExpression (typeof (Match), null, "relevancy");

    public MatchType match_type { get; construct set; default = new MatchType ("Unknown MatchType"); }
    public int relevancy { get; construct set; default = 0; }
    public string title { get; construct set; default = "Unknown Match"; }

    public string? description { get; construct set; }
    public Icon? icon { get; construct set; }
    public Gdk.Paintable? paintable { get; construct set; }

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
