public class MatchRow : Gtk.Box {
    private Gtk.Image icon;
    private Granite.HeaderLabel text;

    construct {
        icon = new Gtk.Image () {
            icon_size = LARGE
        };

        text = new Granite.HeaderLabel ("") {
            hexpand = true
        };

        orientation = HORIZONTAL;
        spacing = 6;
        append (icon);
        append (text);
    }

    public void bind (Match match) {
        icon.gicon = match.icon;
        text.label = match.title;
        text.secondary_text = match.description;
    }
}
