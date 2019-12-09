public class Utils : GLib.Object {
    private const string ALPHA_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    private const string NUMERIC_CHARS = "0123456789";
    
    public string APP_FOLDER;
    public string AVATARS_FOLDER;

    public signal void pane_project_selected (int64 project_id, int64 area_id);
    public signal void pane_action_selected ();
    
    public signal void drag_item_activated (bool active);
    public signal void drag_magic_button_activated (bool active);
    public signal void magic_button_activated (int64 project_id, int64 section_id, int is_todoist, bool last, int index = 0);
    
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

        if (int64.parse (password_builder.str) <= 0) {
            return generate_id ();
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

    public void create_default_labels () {
        var labels = new Gee.HashMap<int, string> ();
        labels.set (41, _("Home"));
        labels.set (42, _("Office"));
        labels.set (32, _("Errand"));
        labels.set (31, _("Important"));
        labels.set (33, _("Pending"));

        var home = new Objects.Label ();
        home.name = _("Home");
        home.color = 41;

        var office = new Objects.Label ();
        office.name = _("Office");
        office.color = 42;

        var errand = new Objects.Label ();
        errand.name = _("Errand");
        errand.color = 32;

        var important = new Objects.Label ();
        important.name = _("Important");
        important.color = 31;

        var pending = new Objects.Label ();
        pending.name = _("Pending");
        pending.color = 33;

        Planner.database.insert_label (home);
        Planner.database.insert_label (office);
        Planner.database.insert_label (errand);
        Planner.database.insert_label (important);
        Planner.database.insert_label (pending);
    }

    /*
        Colors Utils
    */
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

    public string calculate_tint (string hex) {
        Gdk.RGBA rgba = Gdk.RGBA ();
        rgba.parse (hex);

        //102 + ((255 - 102) x .1)
        double r = (rgba.red * 255) + ((255 - rgba.red * 255) * 0.7); 
        double g = (rgba.green * 255) + ((255 - rgba.green * 255) * 0.7); 
        double b = (rgba.blue * 255) + ((255 - rgba.blue * 255) * 0.7); 

        Gdk.RGBA new_rgba = Gdk.RGBA ();
        new_rgba.parse ("rgb (%s, %s, %s)".printf (r.to_string (), g.to_string (), b.to_string ()));

        return rgb_to_hex_string (new_rgba);
    }
    
    private string rgb_to_hex_string (Gdk.RGBA rgba) {
        string s = "#%02x%02x%02x".printf(
            (uint) (rgba.red * 255),
            (uint) (rgba.green * 255),
            (uint) (rgba.blue * 255));
        return s;
    }

    public string get_contrast (string hex) {
        var gdk_white = Gdk.RGBA ();
        gdk_white.parse ("#fff");

        var gdk_black = Gdk.RGBA ();
        gdk_black.parse ("#000");

        var gdk_bg = Gdk.RGBA ();
        gdk_bg.parse (hex);

        var contrast_white = contrast_ratio (
            gdk_bg,
            gdk_white
        );

        var contrast_black = contrast_ratio (
            gdk_bg,
            gdk_black
        );

        var fg_color = "#fff";

        // NOTE: We cheat and add 3 to contrast when checking against black,
        // because white generally looks better on a colored background
        if (contrast_black > (contrast_white + 3)) {
            fg_color = "#000";
        }

        return fg_color;
    }

    private double contrast_ratio (Gdk.RGBA bg_color, Gdk.RGBA fg_color) {
        var bg_luminance = get_luminance (bg_color);
        var fg_luminance = get_luminance (fg_color);

        if (bg_luminance > fg_luminance) {
            return (bg_luminance + 0.05) / (fg_luminance + 0.05);
        }

        return (fg_luminance + 0.05) / (bg_luminance + 0.05);
    }

    private double get_luminance (Gdk.RGBA color) {
        var red = sanitize_color (color.red) * 0.2126;
        var green = sanitize_color (color.green) * 0.7152;
        var blue = sanitize_color (color.blue) * 0.0722;

        return (red + green + blue);
    }

    private double sanitize_color (double color) {
        if (color <= 0.03928) {
            return color / 12.92;
        }

        return Math.pow ((color + 0.055) / 1.055, 2.4);
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
                        Planner.todoist.avatar_downloaded ();
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

    public void set_autostart (bool active) {
        var desktop_file_name = "com.github.alainm23.planner.desktop";
        var desktop_file_path = new DesktopAppInfo (desktop_file_name).filename;
        var desktop_file = File.new_for_path (desktop_file_path);
        var dest_path = Path.build_path (Path.DIR_SEPARATOR_S,
                                         Environment.get_user_config_dir (),
                                         "autostart",
                                         desktop_file_name);
        var dest_file = File.new_for_path (dest_path);
        try {
            desktop_file.copy (dest_file, FileCopyFlags.OVERWRITE);
        } catch (Error e) {
            warning ("Error making copy of desktop file for autostart: %s", e.message);
        }

        var keyfile = new KeyFile ();
        try {
            keyfile.load_from_file (dest_path, KeyFileFlags.NONE);
            keyfile.set_boolean ("Desktop Entry", "X-GNOME-Autostart-enabled", active);
            keyfile.set_string("Desktop Entry", "Exec", "com.github.alainm23.planner.desktop --s");
            keyfile.save_to_file (dest_path);
        } catch (Error e) {
            warning ("Error enabling autostart: %s", e.message);
        }
    }

    /*
        Calendar Utils
    */
    
    public int get_days_of_month (int index, int year_nav) {
        if ((index == 1) || (index == 3) || (index == 5) || (index == 7) || (index == 8) || (index == 10) || (index == 12)) {
            return 31;
        } else {
            if (index == 2) {
                if (year_nav % 4 == 0) {
                    return 29;
                } else {
                    return 28;
                }
            } else {
                return 30;
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

    public bool is_before_today (GLib.DateTime date) {
        var date_1 = date.add_days (1);
        var date_2 = new GLib.DateTime.now_local ();

        if (date_1.compare (date_2) == -1) {
            return true;
        }

        return false;
    }

    public bool is_today (GLib.DateTime date_1) {
        var date_2 = new GLib.DateTime.now_local ();
        return date_1.get_day_of_year () == date_2.get_day_of_year () && date_1.get_year () == date_2.get_year ();
    }
    
    public bool is_tomorrow (GLib.DateTime date_1) {
        var date_2 = new GLib.DateTime.now_local ().add_days (1);
        return date_1.get_day_of_year () == date_2.get_day_of_year () && date_1.get_year () == date_2.get_year ();
    }
    
    public bool is_upcoming (GLib.DateTime date) {
        if (is_today (date) == false && is_before_today (date) == false) {
            return true;
        } else {
            return false;
        }
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

    public string get_relative_time_from_string (string due) {
        bool is_12h = true;
        if (Planner.settings.get_enum ("time-format") == 1) {
            is_12h = false;
        }

        var date = new GLib.DateTime.from_iso8601 (due, new GLib.TimeZone.local ());
        return date.format (Granite.DateTime.get_default_time_format (is_12h, false));
    }

    public string get_relative_date_from_date (GLib.DateTime date) {
        if (Planner.utils.is_today (date)) {
            return _("Today");
        } else if (Planner.utils.is_tomorrow (date)) {
            return _("Tomorrow");
        } else {
            return get_default_date_format_from_date (date);
        }
    }

    public GLib.DateTime get_todoist_datetime (string date) {
        if (is_full_day_date (date)) {
            var _date = date.split ("-");

            return new GLib.DateTime.local (
                int.parse (_date [0]),
                int.parse (_date [1]),
                int.parse (_date [2]),
                0,
                0,
                0
            );
        } else {
            var _date = date.split ("T") [0].split ("-");
            var _time = date.split ("T") [1].split (":");

            return new GLib.DateTime.local (
                int.parse (_date [0]),
                int.parse (_date [1]),
                int.parse (_date [2]),
                int.parse (_time [0]),
                int.parse (_time [1]),
                int.parse (_time [2])
            );
        }
    }

    public bool is_full_day_date (string datetime) {
        return datetime.length <= 10;
    }

    /*  
        Settigns Theme 
    */

    public void apply_theme_changed () {
        string CSS = """
            @define-color projectview_color %s;
            @define-color border_color alpha (@BLACK_900, %s);
            @define-color pane_color %s;
        """;

        bool dark_mode = Planner.settings.get_boolean ("prefer-dark-style");
        Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = dark_mode;

        var provider = new Gtk.CssProvider ();

        try {
            string projectview_color = "#fafafa";
            string border_color = "0.25";
            string pane_color = "@bg_color";
            if (dark_mode) {
                projectview_color = "#333333";
                border_color = "0.55";
                pane_color = "shade (@bg_color, 0.7)";
            }
            
            var css = CSS.printf (
                projectview_color,
                border_color,
                pane_color
            );

            provider.load_from_data (css, css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }
}