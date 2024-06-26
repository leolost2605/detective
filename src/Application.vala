/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: 2023 Your Organization (https://yourwebsite.com)
 */

public class Detective.Application : Gtk.Application {
    private const string BACKGROUND = "background";

    private static bool background;

    private const OptionEntry[] OPTIONS = {
        { BACKGROUND, 'b', OptionFlags.NONE, OptionArg.NONE, out background, "Launch without showing a window and keep running in background.", },
    };

    private Engine engine;

    public Application () {
        Object (
            application_id: "io.github.leolost2605.detective",
            flags: ApplicationFlags.HANDLES_COMMAND_LINE
        );
    }

    construct {
        add_main_option_entries (OPTIONS);
    }

    protected override void startup () {
        base.startup ();

        Granite.init ();
        ShellKeyGrabber.init ();

        unowned var granite_settings = Granite.Settings.get_default ();
        unowned var gtk_settings = Gtk.Settings.get_default ();

        granite_settings.notify["prefers-color-scheme"].connect (() =>
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == DARK
        );

        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == DARK;

        engine = new Engine ();

        hold ();
    }

    protected override int command_line (ApplicationCommandLine command_line) {
        activate ();
        return 0;
    }

    protected override void activate () {
        if (background) {
            request_background.begin ();
            background = false;
            return;
        }

        present_window ();
    }

    public void present_window () {
        if (active_window == null) {
            new SearchWindow (this, engine) {
                default_height = 600,
                default_width = 900,
                title = "Detective"
            };
        }
        active_window.present ();

        request_background.begin ();
    }

    private async void request_background () {
        var portal = new Xdp.Portal ();

        var command = new GenericArray<weak string> ();
        command.add ("io.github.leolost2605.detective");
        command.add ("--background");

        try {
            if (!yield portal.request_background (
                null,
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
