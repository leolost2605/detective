public class Match : Object {
    public static Gtk.Expression match_type_expression = new Gtk.PropertyExpression (typeof (Match), null, "match-type");
    public static Gtk.Expression relevancy_expression = new Gtk.PropertyExpression (typeof (Match), null, "relevancy");
    public static Gtk.Expression text_expression = new Gtk.PropertyExpression (typeof (Match), null, "text");

    public signal void activated ();

    public MatchType match_type { get; construct; }
    public int relevancy { get; construct; }

    public string? text { get; construct; }
    public Icon? icon { get; construct; }
    public Gdk.Paintable? paintable { get; construct; }

    public Match (MatchType match_type, int relevancy, string? text, Icon? icon, Gdk.Paintable? paintable) {
        Object (
            match_type: match_type,
            relevancy: relevancy,
            text: text,
            icon: icon,
            paintable: paintable
        );
    }
}
