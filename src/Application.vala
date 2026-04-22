/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

public class Detective.Application : Gtk.Application {
    private const string BACKGROUND = "background";

    private static bool background;

    private const OptionEntry[] OPTIONS = {
        { BACKGROUND, 'b', OptionFlags.NONE, OptionArg.NONE, out background, "Launch without showing a window and keep running in background.", },
    };

    private Engine engine;
    private Window? window;

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
        if (window == null) {
            window = new Window (this, engine);
        }

        window.present ();

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
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Config.GETTEXT_PACKAGE);

        return new Application ().run (args);
    }
}
