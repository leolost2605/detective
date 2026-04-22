/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Detective.Window : Gtk.ApplicationWindow {
    public Engine engine { get; construct; }

    public Window (Application app, Engine engine) {
        Object (application: app, engine: engine);
    }

    construct {
        var search_view = new SearchView (engine);

        resizable = false;
        child = search_view;
        titlebar = new Gtk.Grid () { visible = false };
        default_width = 700;
        hide_on_close = true;

        notify["is-active"].connect (on_is_active_changed);
    }

    private void on_is_active_changed () {
        if (!is_active) {
            close ();
        }
    }
}
