/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

namespace Detective.Relevancy {
    public const int HIGHEST = 100;
    public const int HIGH = 75;
    public const int MEDIUM = 50;
    public const int LOW = 25;
    public const int LOWEST = 1;
}

public class Detective.Match : Object {
    // Will be automatically set by the MatchType this match is added to
    public string match_type_name { get; internal set; }

    public int relevancy { get; construct set; default = 0; }
    public string title { get; construct set; default = _("Unknown Match"); }

    public string? description { get; construct set; }
    public Icon? icon { get; construct set; }
    public Gdk.Paintable? paintable { get; construct set; }

    public Match (int relevancy, string title, string? description, Icon? icon, Gdk.Paintable? paintable) {
        Object (
            relevancy: relevancy,
            title: title,
            description: description,
            icon: icon,
            paintable: paintable
        );
    }

    public virtual Gtk.Widget? get_custom_preview () {
        return null;
    }

    public virtual async void activate () throws Error {
        debug ("Activated match without activate func");
    }
}
