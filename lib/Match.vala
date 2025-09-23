public class Match : Object {
    public string match_type_name { get; internal set; }

    public int relevancy { get; construct set; default = 0; }
    public string title { get; construct set; default = _("Unknown Match"); }

    public string? description { get; construct set; }
    public Icon? icon { get; construct set; }
    public Gdk.Paintable? paintable { get; construct set; }

    public Gtk.Widget? custom_preview { get; construct; }

    public Match (int relevancy, string title, string? description, Icon? icon, Gdk.Paintable? paintable) {
        Object (
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
