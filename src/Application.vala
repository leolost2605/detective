/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2023 Your Organization (https://yourwebsite.com)
 */

public class Detective.Application : Gtk.Application {
    public Application () {
        Object (
            application_id: "io.github.leolost2605.detective",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var headerbar = new Gtk.HeaderBar () {
            show_title_buttons = true
        };

        var main_window = new Gtk.ApplicationWindow (this) {
            default_height = 300,
            default_width = 300,
            title = "Detective",
            titlebar = headerbar
        };
        main_window.present ();
    }

    public static int main (string[] args) {
        return new Application ().run (args);
    }
}
