/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2023 Your Organization (https://yourwebsite.com)
 */

public class Detective.Application : Gtk.Application {
    private Engine engine;

    public Application () {
        Object (
            application_id: "io.github.leolost2605.detective",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void startup () {
        base.startup ();

        ShellKeyGrabber.init ();

        engine = new Engine ();

        hold ();
    }

    protected override void activate () {
        present_window ();
    }

    public void present_window () {
        if (active_window == null) {
            var window = new SearchWindow (this, engine) {
                default_height = 600,
                default_width = 800,
                title = "Detective"
            };
        }
        active_window.present ();

        request_background.begin ();
    }

    private async void request_background () {
        var portal = new Xdp.Portal ();

        Xdp.Parent? parent = active_window != null ? Xdp.parent_new_gtk (active_window) : null;

        var command = new GenericArray<weak string> ();
        command.add ("io.github.leolost2605.detective");

        try {
            if (!yield portal.request_background (
                parent,
                _("Detective needs to run in the background to be easily invokable via keyboard shortcuts."),
                (owned) command,
                Xdp.BackgroundFlags.AUTOSTART,
                null
            )) {
                release ();
            }
        } catch (Error e) {
            if (e is IOError.CANCELLED) {
                debug ("Request for autostart and background permissions denied: %s", e.message);
                release ();
            } else {
                warning ("Failed to request autostart and background permissions: %s", e.message);
            }
        }
    }

    public static int main (string[] args) {
        return new Application ().run (args);
    }
}
