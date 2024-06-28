/*
 * Copyright 2024 Leonhard Kargl <leo.kargl@proton.me>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class RelevancyService : Object {
    private static RelevancyService instance;
    public static RelevancyService get_default () {
        if (instance == null) {
            instance = new RelevancyService ();
        }
        return instance;
    }

    private KeyFile key_file;
    private bool writing = false;

    construct {
        load_keyfile.begin ();
    }

    private async void load_keyfile () {
        var dir = Environment.get_user_data_dir ();
        File file = File.new_build_filename (dir, "io.github.leolost2605.detective.data");

        Bytes bytes;
        try {
            if (!file.query_exists ()) {
                key_file = new KeyFile ();
                return;
            }

            bytes = yield file.load_bytes_async (null, null);
        } catch (Error e) {
            warning ("Failed to load file %s: %s", dir, e.message);
            return;
        }

        key_file = new KeyFile ();
        try {
            key_file.load_from_bytes (bytes, NONE);
        } catch (Error e) {
            warning ("Failed to parse relevancy key file %s, deleting it to start afresh: %s", dir, e.message);

            try {
                yield file.delete_async ();
            } catch (Error e) {
                warning ("Failed to delete file: %s", e.message);
            }

            return;
        }
    }

    private async void save_keyfile () {
        if (writing) {
            return;
        }

        writing = true;

        var dir = Environment.get_user_data_dir ();

        try {
            File file = File.new_build_filename (dir, "io.github.leolost2605.detective.data");

            yield file.replace_contents_async (key_file.to_data ().data, null, false, NONE, null, null);
        } catch (Error e) {
            warning ("Failed to save file %s: %s", dir, e.message);
            return;
        } finally {
            writing = false;
        }
    }

    public double get_app_relevancy (string app_id) {
        double app_sum = get_time_sum_and_cleanup (app_id);
        double altogether = get_time_sum_and_cleanup ("altogether");

        return altogether != 0 ? (app_sum / altogether) : 0;
    }

    public void app_launched (string app_id) {
        var now = new DateTime.now_local ().get_day_of_year ().to_string ();

        create_or_inc_key (app_id, now);
        create_or_inc_key ("altogether", now);

        save_keyfile.begin ();
    }

    private int get_time_sum_and_cleanup (string group) {
        if (!key_file.has_group (group)) {
            return 0;
        }

        var now = new DateTime.now_local ().get_day_of_year ();

        try {
            int sum = 0;
            foreach (var key in key_file.get_keys (group)) {
                if ((Math.fabs (int.parse (key) - now) % (365 - 4 * 7)) > 4 * 7) {
                    key_file.remove_key (group, key);
                } else {
                    sum += key_file.get_integer (group, key);
                }
            }
            return sum;
        } catch (Error e) {
            warning ("Failed to get time sum and cleanup group %s: %s", group, e.message);
        }

        return 0;
    }

    private void create_or_inc_key (string group, string key) {
        try {
            if (!key_file.has_group (group) || !key_file.has_key (group, key)) {
                key_file.set_integer (group, key, 1);
            } else {
                var old = key_file.get_integer (group, key);
                old++;
                key_file.set_integer (group, key, old);
            }
        } catch (Error e) {
            warning ("Failed to set or inc key %s in group %s: %s", key, group, e.message);
        }
    }
}
