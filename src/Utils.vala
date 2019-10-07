public class Utils : GLib.Object {
    private const string ALPHA_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    private const string NUMERIC_CHARS = "0123456789";
    
    public string APP_FOLDER;
    public string AVATARS_FOLDER;

    public signal void pane_project_selected (int64 project_id, int64 area_id);
    public signal void pane_action_selected ();
    
    public signal void drag_item_activated (bool active);
    public signal void drag_magic_button_activated (bool active);
    public signal void magic_button_activated (int64 project_id, int64 header_id, int is_todoist, bool last, int index = 0);
    
    public Utils () {
        APP_FOLDER = GLib.Path.build_filename (Environment.get_home_dir () + "/.local/share/", "com.github.alainm23.planner");
        AVATARS_FOLDER = GLib.Path.build_filename (APP_FOLDER, "avatars");
    }

    public void create_dir_with_parents (string dir) {
        string path = Environment.get_home_dir () + dir;
        File tmp = File.new_for_path (path);
        if (tmp.query_file_type (0) != FileType.DIRECTORY) {
            GLib.DirUtils.create_with_parents (path, 0775);
        }
    }

    public int64 generate_id () {
        string allowed_characters = NUMERIC_CHARS;

        var password_builder = new StringBuilder ();
        for (var i = 0; i < 10; i++) {
            var random_index = Random.int_range (0, allowed_characters.length);
            password_builder.append_c (allowed_characters[random_index]);
        }
        
        return int64.parse (password_builder.str);
    }

    public string generate_string () {
        string allowed_characters = ALPHA_CHARS + NUMERIC_CHARS;

        var password_builder = new StringBuilder ();
        for (var i = 0; i < 36; i++) {
            var random_index = Random.int_range (0, allowed_characters.length);
            password_builder.append_c (allowed_characters[random_index]);
        }

        return password_builder.str;
    }

    public string get_color (int key) {
        var colors = new Gee.HashMap<int, string> ();
        
        colors.set (30, "#b8256f");
        colors.set (31, "#db4035");
        colors.set (32, "#ff9933");
        colors.set (33, "#fad000");
        colors.set (34, "#afb83b");
        colors.set (35, "#7ecc49");
        colors.set (36, "#299438");
        colors.set (37, "#6accbc");
        colors.set (38, "#158fad");
        colors.set (39, "#14aaf5");
        colors.set (40, "#96c3eb");
        colors.set (41, "#4073ff");
        colors.set (42, "#884dff");
        colors.set (43, "#af38eb");
        colors.set (44, "#eb96eb");
        colors.set (45, "#e05194");
        colors.set (46, "#ff8d85");
        colors.set (47, "#808080");
        colors.set (48, "#b8b8b8");
        colors.set (49, "#ccac93");

        return colors.get (key);
    }

    public void apply_styles (string id, string color, Gtk.RadioButton radio) {
        string COLOR_CSS = """
            .color-%s radio {
                background: %s;
                border: 1px solid shade (%s, 0.9);
                box-shadow: inset 0px 0px 0px 1px rgba(0, 0, 0, 0.2);
            }
        """;

        var provider = new Gtk.CssProvider ();
        radio.get_style_context ().add_class ("color-%s".printf (id));
        radio.get_style_context ().add_class ("color-radio");

        try {
            var colored_css = COLOR_CSS.printf (
                id,
                color,
                color
            );

            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }

    public void download_profile_image (string avatar) {
        // Create file
        var image_path = GLib.Path.build_filename (AVATARS_FOLDER, "avatar.jpg");

        var file_path = File.new_for_path (image_path);
        var file_from_uri = File.new_for_uri (avatar);
        if (file_path.query_exists () == false) {
            MainLoop loop = new MainLoop ();

            file_from_uri.copy_async.begin (file_path, 0, Priority.DEFAULT, null, (current_num_bytes, total_num_bytes) => {
                // Report copy-status:
                print ("%" + int64.FORMAT + " bytes of %" + int64.FORMAT + " bytes copied.\n", current_num_bytes, total_num_bytes);
            }, (obj, res) => {
                try {
                    if (file_from_uri.copy_async.end (res)) {
                        print ("Avatar Profile Downloaded\n");
                        Application.todoist.avatar_downloaded ();
                    }
                } catch (Error e) {
                    print ("Error: %s\n", e.message);
                }

                loop.quit ();
            });

            loop.run ();
        }
    }

    public bool check_connection () {
        var host = "www.google.com";

        try {
            var resolver = Resolver.get_default ();
            var addresses = resolver.lookup_by_name (host, null);
            var address = addresses.nth_data (0);
            if (address == null) {
                return false;
            }
        } catch (Error e) {
            debug ("%s\n", e.message);
            return false;
        }
        
        return true;
    }

    /*
        Calendar Utils
    */
    
    public int get_days_of_month (int index) {
        if ((index == 1) || (index == 3) || (index == 5) || (index == 7) || (index == 8) || (index == 10) || (index == 12)) {
            return 31;
        } else if ((index == 2) || (index == 4) || (index == 6) || (index == 9) || (index == 11)) {
            return 30;
        } else {
            var date = new GLib.DateTime.now_local ();
            int year = date.get_year ();

            if (year % 4 == 0) {
                if (year % 100 == 0) {
                    if (year % 400 == 0) {
                        return 29;
                    } else {
                        return 28;
                    }
                } else {
                    return 28;
                }
            } else {
                return 28;
            }
        }
    }

    public bool is_current_month (GLib.DateTime date) {
        var now = new GLib.DateTime.now_local ();

        if (date.get_year () == now.get_year ()) {
            if (date.get_month () == now.get_month ()) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    public bool is_today (GLib.DateTime date_1) {
        var date_2 = new GLib.DateTime.now_local ();
        return date_1.get_day_of_year () == date_2.get_day_of_year () && date_1.get_year () == date_2.get_year ();
    }
    
    public bool is_tomorrow (GLib.DateTime date_1) {
        var date_2 = new GLib.DateTime.now_local ().add_days (1);
        return date_1.get_day_of_year () == date_2.get_day_of_year () && date_1.get_year () == date_2.get_year ();
    }
    
    public string get_default_date_format_from_date (GLib.DateTime date) {
        var now = new GLib.DateTime.now_local ();

        if (date.get_year () == now.get_year ()) {
            return date.format (Granite.DateTime.get_default_date_format (false, true, false));
        } else {
            return date.format (Granite.DateTime.get_default_date_format (false, true, true));
        }
    }

    public string get_relative_date_from_string (string due) {
        var date = new GLib.DateTime.from_iso8601 (due, new GLib.TimeZone.local ());
        return get_relative_date_from_date (date);
    }

    public string get_relative_date_from_date (GLib.DateTime date) {
        if (Application.utils.is_today (date)) {
            return _("Today");
        } else if (Application.utils.is_tomorrow (date)) {
            return _("Tomorrow");
        } else {
            return get_default_date_format_from_date (date);
        }
    }
}