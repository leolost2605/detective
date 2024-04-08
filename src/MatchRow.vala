public class MatchRow : Gtk.Box {
    private Gtk.Image icon;
    private Gtk.Label text;

    construct {
        icon = new Gtk.Image () {
            icon_size = LARGE
        };

        text = new Gtk.Label (null) {
            ellipsize = MIDDLE,
            hexpand = true,
            xalign = 0
        };

        orientation = HORIZONTAL;
        spacing = 6;
        append (icon);
        append (text);
    }

    public void bind (Match match) {
        icon.gicon = match.icon;
        text.label = match.text;
    }
}
