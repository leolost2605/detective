/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Detective.ResultRow : Granite.Bin {
    private Gtk.Image icon;
    private Gtk.Label label;
    private Gtk.Label description_label;

    private Granite.Box label_box;

    construct {
        icon = new Gtk.Image () {
            pixel_size = 32,
        };

        label = new Gtk.Label ("") {
            hexpand = true,
            xalign = 0,
            ellipsize = END
        };

        description_label = new Gtk.Label ("") {
            hexpand = true,
            xalign = 0,
            ellipsize = END
        };
        description_label.add_css_class (Granite.CssClass.SMALL);
        description_label.add_css_class (Granite.CssClass.DIM);

        label_box = new Granite.Box (VERTICAL, NONE) {
            valign = CENTER,
        };
        label_box.append (label);
        label_box.append (description_label);

        var content_box = new Granite.Box (HORIZONTAL, SINGLE);
        content_box.append (icon);
        content_box.append (label_box);

        var list_item = new Granite.ListItem () {
            child = content_box
        };

        child = list_item;
    }

    public void bind (Result result) {
        icon.gicon = result.icon;
        label.label = result.title;

        description_label.label = result.description;

        var should_show_description = result.description != null && result.description != "";
        var shows_description = description_label.parent == label_box;

        if (should_show_description && !shows_description) {
            label_box.append (description_label);
        } else if (!should_show_description && shows_description) {
            label_box.remove (description_label);
        }
    }
}
