public class Match : Object {
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
        debug ("Activated match without activate func");
    }
}
