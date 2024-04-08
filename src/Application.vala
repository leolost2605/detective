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
        var main_window = new SearchWindow (this) {
            default_height = 400,
            default_width = 600,
            title = "Detective"
        };
        main_window.present ();
    }

    public static int main (string[] args) {
        return new Application ().run (args);
    }
}
