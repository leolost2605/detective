/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Detective.GenericPreview : Granite.Bin {
    private Gtk.Image icon;

    private Granite.HeaderLabel label;

    construct {
        icon = new Gtk.Image () {
            pixel_size = 64
        };

        label = new Granite.HeaderLabel ("");

        var content = new Gtk.Box (VERTICAL, 6) {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };
        content.append (icon);
        content.append (label);

        child = content;
    }

    public void bind (Match match) {
        icon.gicon = match.icon;
        label.label = match.title;
        label.secondary_text = match.description;
    }
}
