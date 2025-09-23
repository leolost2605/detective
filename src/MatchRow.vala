public class MatchRow : Granite.Bin {
    private Gtk.Image icon;
    private Gtk.Label label;

    construct {
        icon = new Gtk.Image ();

        label = new Gtk.Label ("") {
            hexpand = true,
            xalign = 0
        };

        var content = new Gtk.Box (HORIZONTAL, 6) {
            margin_start = 12,
            margin_end = 12,
            margin_top = 6,
            margin_bottom = 6
        };
        content.append (icon);
        content.append (label);

        child = content;
    }

    public void bind (Match match) {
        icon.gicon = match.icon;
        label.label = match.title;
    }
}
