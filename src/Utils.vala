// vala-lint=skip-file

/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alainmh23@gmail.com>
*/

public class Utils : GLib.Object {
    private const string ALPHA_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    private const string NUMERIC_CHARS = "0123456789";

    private const string TODAY = _("today");
    private const string TOMORROW = _("tomorrow");

    public string APP_FOLDER; // vala-lint=naming-convention
    public string AVATARS_FOLDER; // vala-lint=naming-convention
    public Settings h24_settings;

    public signal void pane_project_selected (int64 project_id, int64 area_id);
    public signal void select_pane_project (int64 project_id);
    public signal void pane_action_selected ();

    public signal void insert_project_to_area (int64 area_id);

    public signal void clock_format_changed ();

    public signal void drag_item_activated (bool active);
    public signal void magic_button_clicked (string view);

    public signal void add_item_show_queue (Widgets.ItemRow row);
    public signal void remove_item_show_queue (Widgets.ItemRow row);
    public signal void add_item_show_queue_view (Widgets.ItemRow row, string view);
    public signal void remove_item_show_queue_view (Widgets.ItemRow row, string view);

    public signal void highlight_item (int64 item_id);

    private GLib.Regex line_break_to_space_regex = null;

    public Utils () {
        APP_FOLDER = GLib.Path.build_filename (Environment.get_user_data_dir (), "com.github.alainm23.planner");
        AVATARS_FOLDER = GLib.Path.build_filename (APP_FOLDER, "avatars");

        h24_settings = new Settings ("org.gnome.desktop.interface");
        h24_settings.changed.connect ((key) => {
            if (key == "clock-format") {
                clock_format_changed ();
            }
        });
    }

    public void create_dir_with_parents (string dir) {
        string path = Environment.get_user_data_dir () + dir;
        File tmp = File.new_for_path (path);
        if (tmp.query_file_type (0) != FileType.DIRECTORY) {
            GLib.DirUtils.create_with_parents (path, 0775);
        }
    }

    public string line_break_to_space (string str) {
        if (line_break_to_space_regex == null) {
            try {
                line_break_to_space_regex = new GLib.Regex ("(^\\s+|\\s+$|\n|\\s\\s+)");
            } catch (GLib.RegexError e) {
                critical (e.message);
            }
        }

        try {
            return line_break_to_space_regex.replace (str, str.length, 0, " ");
        } catch (GLib.RegexError e) {
            warning (e.message);
        }

        return str;
    }

    public int64 generate_id (int len=10) {
        string allowed_characters = NUMERIC_CHARS;

        var password_builder = new StringBuilder ();
        for (var i = 0; i < len; i++) {
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

    public string generate_temp_id () {
        return "_" + generate_id (13).to_string ();
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
    *  Colors Utils
    */

    public Gee.HashMap<int, string> color () {
        var colors = new Gee.HashMap<int, string> ();

        colors.set (30, "#b8256f"); // ed5353
        colors.set (31, "#db4035"); // db4035
        colors.set (32, "#ff9933"); // ff9933
        colors.set (33, "#fad000"); // fad000
        colors.set (34, "#afb83b"); // afb83b
        colors.set (35, "#7ecc49"); // 7ecc49
        colors.set (36, "#299438"); // 299438
        colors.set (37, "#6accbc"); // 6accbc
        colors.set (38, "#158fad"); // 158fad
        colors.set (39, "#14aaf5"); // 14aaf5
        colors.set (40, "#96c3eb"); // 96c3eb
        colors.set (41, "#4073ff"); // 4073ff
        colors.set (42, "#884dff"); // 884dff
        colors.set (43, "#af38eb"); // af38eb
        colors.set (44, "#eb96eb"); // eb96eb
        colors.set (45, "#e05194"); // e05194
        colors.set (46, "#ff8d85"); // ff8d85
        colors.set (47, "#808080"); // 808080
        colors.set (48, "#b8b8b8"); // b8b8b8
        colors.set (49, "#ccac93"); // ccac93

        return colors;
    }

    public Gee.HashMap<int, string> color_name () {
        var colors = new Gee.HashMap<int, string> ();

        colors.set (30, _("Berry Red"));
        colors.set (31, _("Red"));
        colors.set (32, _("Orange"));
        colors.set (33, _("Yellow"));
        colors.set (34, _("Olive Green"));
        colors.set (35, _("Lime Green"));
        colors.set (36, _("Green"));
        colors.set (37, _("Mint Green"));
        colors.set (38, _("Teal"));
        colors.set (39, _("Sky Blue"));
        colors.set (40, _("Light Blue"));
        colors.set (41, _("Blue"));
        colors.set (42, _("Grape"));
        colors.set (43, _("Violet"));
        colors.set (44, _("Lavander"));
        colors.set (45, _("Magenta"));
        colors.set (46, _("Salmon"));
        colors.set (47, _("Charcoal"));
        colors.set (48, _("Grey"));
        colors.set (49, _("Taupe"));

        return colors;
    }

    public Gee.ArrayList<int> get_color_list () {
        var colors = new Gee.ArrayList<int> ();

        colors.add (30);
        colors.add (31);
        colors.add (32);
        colors.add (33);
        colors.add (34);
        colors.add (35);
        colors.add (36);
        colors.add (37);
        colors.add (38);
        colors.add (39);
        colors.add (40);
        colors.add (41);
        colors.add (42);
        colors.add (43);
        colors.add (44);
        colors.add (45);
        colors.add (46);
        colors.add (47);
        colors.add (48);
        colors.add (49);

        return colors;
    }

    public string get_color_name (int key) {
        return color_name ().get (key);
    }

    public string get_color (int key) {
        return color ().get (key);
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
        string s = "#%02x%02x%02x".printf (
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

    public void apply_styles (string id, string color) {
        string color_css = """
            .color-%s radio {
                background: %s;
                border: 1px solid shade (%s, 0.67);
            }
        """;

        var provider = new Gtk.CssProvider ();
        try {
            var colored_css = color_css.printf (
                id,
                color,
                color
            );

            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (), provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } catch (GLib.Error e) {
            return;
        }
    }

    public void init_labels_color () {
        foreach (int color_id in get_color_list ()) {
            apply_styles (color_id.to_string (), get_color (color_id));
        }
    }

    public void download_profile_image (string? id, string avatar) {
        if (id != null) {
            // Create file
            var image_path = GLib.Path.build_filename (AVATARS_FOLDER, id + ".jpg");

            var file_path = File.new_for_path (image_path);
            var file_from_uri = File.new_for_uri (avatar);
            if (file_path.query_exists () == false) {
                MainLoop loop = new MainLoop ();

                file_from_uri.copy_async.begin (file_path, 0, Priority.DEFAULT, null, (current_num_bytes, total_num_bytes) => { // vala-lint=line-length
                    // Report copy-status:
                    print ("%" + int64.FORMAT + " bytes of %" + int64.FORMAT + " bytes copied.\n", current_num_bytes, total_num_bytes); // vala-lint=line-length
                }, (obj, res) => {
                    try {
                        if (file_from_uri.copy_async.end (res)) {
                            print ("Avatar Profile Downloaded\n");
                            Planner.todoist.avatar_downloaded (id);
                        }
                    } catch (Error e) {
                        print ("Error: %s\n", e.message);
                    }

                    loop.quit ();
                });

                loop.run ();
            }
        }
    }

    public bool is_disconnected () {
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
            return true;
        }

        return false;
    }

    public void set_autostart (bool active) {
        var desktop_file_name = "com.github.alainm23.planner.desktop";
        var desktop_file_path = new DesktopAppInfo (desktop_file_name).filename;
        var desktop_file = File.new_for_path (desktop_file_path);
        var dest_path = Path.build_path (
            Path.DIR_SEPARATOR_S,
            Environment.get_user_config_dir (),
            "autostart",
            desktop_file_name
        );
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
            keyfile.set_string ("Desktop Entry", "Exec", "com.github.alainm23.planner --s");
            keyfile.save_to_file (dest_path);
        } catch (Error e) {
            warning ("Error enabling autostart: %s", e.message);
        }
    }

    /*
        Calendar Utils
    */

    public int get_days_of_month (int index, int year_nav) {
        if ((index == 1) || (index == 3) || (index == 5) || (index == 7) || (index == 8) || (index == 10) || (index == 12)) { // vala-lint=line-length
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

    public bool is_overdue (GLib.DateTime date) {
        var now = get_format_date (new DateTime.now_local ());

        if (get_format_date (date).compare (now) == -1) {
            return true;
        }

        return false;
    }

    public bool is_today (GLib.DateTime date) {
        return Granite.DateTime.is_same_day (date, new GLib.DateTime.now_local ());
    }

    public bool is_tomorrow (GLib.DateTime date) {
        return Granite.DateTime.is_same_day (date, new GLib.DateTime.now_local ().add_days (1));
    }

    public bool is_upcoming (GLib.DateTime date) {
        var now = get_format_date (new DateTime.now_local ());

        if (get_format_date (date).compare (now) == 1) {
            return true;
        }

        return false;
    }

    private GLib.DateTime get_format_date (GLib.DateTime date) {
        return new DateTime.local (
            date.get_year (),
            date.get_month (),
            date.get_day_of_month (),
            0,
            0,
            0
        );
    }

    public GLib.DateTime get_format_date_from_string (string due_date) {
        var date = new GLib.DateTime.from_iso8601 (due_date, new GLib.TimeZone.local ());

        return new DateTime.local (
            date.get_year (),
            date.get_month (),
            date.get_day_of_month (),
            0,
            0,
            0
        );
    }

    public string get_default_date_format_from_string (string due_date) {
        var now = new GLib.DateTime.now_local ();
        var date = new GLib.DateTime.from_iso8601 (due_date, new GLib.TimeZone.local ());

        if (date.get_year () == now.get_year ()) {
            return date.format (Granite.DateTime.get_default_date_format (false, true, false));
        } else {
            return date.format (Granite.DateTime.get_default_date_format (false, true, true));
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

    public string get_relative_datetime_from_string (string date) {
        return Granite.DateTime.get_relative_datetime (
            new GLib.DateTime.from_iso8601 (date, new GLib.TimeZone.local ())
        );
    }

    public string get_relative_date_from_string (string due) {
        var date = new GLib.DateTime.from_iso8601 (due, new GLib.TimeZone.local ());
        return get_relative_date_from_date (date);
    }

    public bool is_clock_format_12h () {
        var format = h24_settings.get_string ("clock-format");
        return (format.contains ("12h"));
    }

    public string get_relative_time_from_string (string due) {
        var date = new GLib.DateTime.from_iso8601 (due, new GLib.TimeZone.local ());
        return date.format (Granite.DateTime.get_default_time_format (is_clock_format_12h (), false));
    }

    public string get_relative_date_from_date (GLib.DateTime date) {
        if (Planner.utils.is_today (date)) {
            return _("Today");
        } else if (Planner.utils.is_tomorrow (date)) {
            return _("Tomorrow");
        } else if (Planner.utils.is_overdue (date)) {
            return Granite.DateTime.get_relative_datetime (date);
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

    public GLib.DateTime? get_next_recurring_due_date (Objects.Item item, int value=1) {
        GLib.DateTime returned = null;

        if (item.due_lang == "en") {
            if (item.due_string == "every day" || item.due_string == "daily") {
                returned = get_format_date_from_string (item.due_date).add_days (value * 1);
            } else if (item.due_string == "every week" || item.due_string == "weekly") {
                returned = get_format_date_from_string (item.due_date).add_days (value * 7);
            } else if (item.due_string == "every month" || item.due_string == "monthly") {
                returned = get_format_date_from_string (item.due_date).add_months (value * 1);
            } else if (item.due_string == "every year" || item.due_string == "yearly") {
                returned = get_format_date_from_string (item.due_date).add_years (value * 1);
            }
        } else if (item.due_lang == "es") {
            if (item.due_string == "cada dia" || item.due_string == "todos dias" || item.due_string == "diario") {
                returned = get_format_date_from_string (item.due_date).add_days (value * 1);
            } else if (item.due_string == "cada semana" || item.due_string == "semanal") {
                returned = get_format_date_from_string (item.due_date).add_days (value * 7);
            } else if (item.due_string == "cada mes" || item.due_string == "mensual") {
                returned = get_format_date_from_string (item.due_date).add_months (value * 1);
            } else if (item.due_string == "cada año" || item.due_string == "anualmente") {
                returned = get_format_date_from_string (item.due_date).add_years (value * 1);
            }
        }

        return returned;
    }

    public int get_recurring_iter (Objects.Item item) {
        int returned = 4;

        if (item.due_lang == "en") {
            if (item.due_string == "every day" || item.due_string == "daily") {
                returned = 0;
            } else if (item.due_string == "every week" || item.due_string == "weekly") {
                returned = 1;
            } else if (item.due_string == "every month" || item.due_string == "monthly") {
                returned = 2;
            } else if (item.due_string == "every year" || item.due_string == "yearly") {
                returned = 3;
            }
        } else if (item.due_lang == "es") {
            if (item.due_string == "cada dia" || item.due_string == "todos dias" || item.due_string == "diario") {
                returned = 0;
            } else if (item.due_string == "cada semana" || item.due_string == "semanal") {
                returned = 1;
            } else if (item.due_string == "cada mes" || item.due_string == "mensual") {
                returned = 2;
            } else if (item.due_string == "cada año" || item.due_string == "anualmente") {
                returned = 3;
            }
        }

        return returned;
    }

    //  public string get_recurrent_task_string (int id) {
    //      if (is_supported_language ()) {

    //      }

    //      return "";
    //  }

    //  private bool is_supported_language () {
    //      return "es" in Intl.get_language_names () ||
    //              "en" in Intl.get_language_names ();
    //  }

    /*
        Settigns Theme
    */

    public void apply_theme_changed () {
        string _css = """
            @define-color base_color %s;
            @define-color check_border_color %s;
            @define-color projectview_color %s;
            @define-color pane_color %s;
            @define-color pane_selected_color %s;
            @define-color pane_text_color %s;
            @define-color popover_background %s;
            @define-color row_selected_color %s;
            @define-color upcoming_color %s;
        """;

        int appearance_mode = Planner.settings.get_enum ("appearance");
        var provider = new Gtk.CssProvider ();

        try {
            string base_color = "";
            string check_border_color = "";
            string projectview_color = "";
            string pane_color = "";
            string pane_selected_color = "";
            string pane_text_color = "";
            string popover_background = "";
            string row_selected_color = "";
            string upcoming_color = "";

            if (appearance_mode == 0) {
                base_color = "white";
                check_border_color = "@border_color";
                projectview_color = "shade (#FFFFFF, 0.985)";
                pane_color = "#F5F6F7";
                pane_selected_color = "shade (@bg_color, 0.93)";
                pane_text_color = "#333333";
                popover_background = "@projectview_color";
                row_selected_color = "shade (@check_border_color, 0.75)";
                upcoming_color = "#692fc2";

                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
            } else if (appearance_mode == 1) {
                base_color = "#282828";
                check_border_color = "grey";
                projectview_color = "#1f1f1f";
                pane_color = "shade (@bg_color, 0.7)";
                pane_selected_color = "#282828";
                pane_text_color = "#ffffff";
                popover_background = "#333333";
                row_selected_color = "shade (#333333, 0.4)";
                upcoming_color = "#a970ff";

                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
            } else if (appearance_mode == 2) {
                base_color = "#15151B";
                check_border_color = "grey";
                projectview_color = "#0B0B11";
                pane_color = "#15151B";
                pane_selected_color = "#1D2836";
                pane_text_color = "#ffffff";
                popover_background = "#15151B";
                row_selected_color = "shade (#ffffff, 0.125)";
                upcoming_color = "#a970ff";

                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
            } else if (appearance_mode == 3) {
                base_color = "#353945";
                check_border_color = "grey";
                projectview_color = "#404552";
                pane_color = "#353945";
                pane_selected_color = "#2B303B";
                pane_text_color = "#fefeff";
                popover_background = "#353945";
                row_selected_color = "shade (@projectview_color, 0.3)";
                upcoming_color = "#a970ff";

                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
            }

            var css = _css.printf (
                base_color,
                check_border_color,
                projectview_color,
                pane_color,
                pane_selected_color,
                pane_text_color,
                popover_background,
                row_selected_color,
                upcoming_color
            );

            provider.load_from_data (css, css.length);

            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (), provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } catch (GLib.Error e) {
            return;
        }
    }

    public void set_quick_add_shortcut (string QUICK_ADD_SHORTCUT) { // vala-lint=naming-convention
        var QUICKADD_COMMAND = "com.github.alainm23.planner.quick-add";
        if (get_os_info ("PRETTY_NAME") == null || get_os_info ("PRETTY_NAME").index_of ("elementary") == -1) {
            QUICKADD_COMMAND = "flatpak run --command=com.github.alainm23.planner.quick-add com.github.alainm23.planner";
        }

        Services.CustomShortcutSettings.init ();
        bool has_shortcut = false;
        foreach (var shortcut in Services.CustomShortcutSettings.list_custom_shortcuts ()) {
            if (shortcut.command == QUICKADD_COMMAND) {
                Services.CustomShortcutSettings.edit_shortcut (shortcut.relocatable_schema, QUICK_ADD_SHORTCUT);
                has_shortcut = true;
                return;
            }
        }
        if (!has_shortcut) {
            var shortcut = Services.CustomShortcutSettings.create_shortcut ();
            if (shortcut != null) {
                Services.CustomShortcutSettings.edit_shortcut (shortcut, QUICK_ADD_SHORTCUT);
                Services.CustomShortcutSettings.edit_command (shortcut, QUICKADD_COMMAND);

                uint accelerator_key;
                Gdk.ModifierType accelerator_mods;
                Gtk.accelerator_parse (QUICK_ADD_SHORTCUT, out accelerator_key, out accelerator_mods);
                var shortcut_hint = Gtk.accelerator_get_label (accelerator_key, accelerator_mods);

                Planner.notifications.send_system_notification (
                    _("Quick Add Activated!"),
                    _("Try %s to activate it. You can change it from the preferences".printf (shortcut_hint)),
                    "com.github.alainm23.planner",
                    GLib.NotificationPriority.HIGH
                );
            }
        }
    }

    public string get_os_info (string field) {
        string return_value = "";
        var file = File.new_for_path ("/etc/os-release");
        try {
            var osrel = new Gee.HashMap<string, string> ();
            var dis = new DataInputStream (file.read ());
            string line;
            // Read lines until end of file (null) is reached
            while ((line = dis.read_line (null)) != null) {
                var osrel_component = line.split ("=", 2);
                if (osrel_component.length == 2) {
                    osrel[osrel_component[0]] = osrel_component[1].replace ("\"", "");
                }
            }

            return_value = osrel[field];
        } catch (Error e) {
            warning ("Couldn't read os-release file, assuming elementary OS");
        }

        return return_value;
    }

    /*
        Tutorial project
    */

    public Objects.Project create_tutorial_project () {
        var project = new Objects.Project ();
        project.id = generate_id ();
        project.color = 41;
        project.name = _("🚀️ Getting Started");
        project.note = _("This project will help you learn the basics of Planner and get started with a simple task management system to stay organized and on top of everything you need to do."); // vala-lint=line-length

        var item_01 = new Objects.Item ();
        item_01.id = generate_id ();
        item_01.project_id = project.id;
        item_01.content = _("Keeping track of your tasks");
        item_01.note = _("It turns out, our brains are actually wired to keep us thinking about our unfinished tasks. Handy when you have one thing you need to work on. Not so good when you have 30+ tasks vying for your attention at once. That’s why the first step to organizing your work and life is getting everything out of your head and onto your to-do list. From there you can begin to organize and prioritize so you know exactly what to focus on and when."); // vala-lint=line-length

        var item_02 = new Objects.Item ();
        item_02.id = generate_id ();
        item_02.project_id = project.id;
        item_02.content = _("Adding new tasks");
        item_02.note = _("""- To add a new task to Planner, just click + and press Enter.
- When your task is created, click on the task to be able to edit it, add a note or some other options.""");

        var item_03 = new Objects.Item ();
        item_03.id = generate_id ();
        item_03.project_id = project.id;
        item_03.content = _("Due dates");
        item_03.note = _("""- If you know you need to have the task done on a certain day, click on the calendar icon and select a date.
- If you want to delete the due date, repeat the process and select the "undate" option.""");

        var item_04 = new Objects.Item ();
        item_04.id = generate_id ();
        item_04.project_id = project.id;
        item_04.content = _("How to use projects");
        item_04.note = _("""- Whether you’re planning a presentation, preparing for an event or creating a website, create a project so all the important details are saved in one central place.
- In the navigation menu on the left, at the bottom, click on the + symbol.
- In the options menu select 'Project' and type out the name of your new project.
- Select a source from the drop-down menu.
- (Optional) Select a different project color from the color list.
- Click Add to create the project.""");

        var section = new Objects.Section ();
        section.id = generate_id ();
        section.project_id = project.id;
        section.name = _("Sections");

        var item_05 = new Objects.Item ();
        item_05.id = generate_id ();
        item_05.project_id = project.id;
        item_05.section_id = section.id;
        item_05.content = _("Add sections");
        item_05.note = _("""- It’s always easier to take on a big project when you split it into easily manageable parts using Planner’s sections.
- Organize your projects with sections to group your tasks together and get a better overview of what needs to be done. Add sections to your project, drag the relevant tasks to the section they belong in, and you’ll find it a lot easier to make progress (instead of getting overwhelmed by a single long list).
- At the top right of a project, click the + icon.
- Type the name of your section and click Add.""");

        Planner.database.insert_project (project);
        Planner.database.insert_item (item_01);
        Planner.database.insert_item (item_02);
        Planner.database.insert_item (item_03);
        Planner.database.insert_item (item_04);
        Planner.database.insert_section (section);
        Planner.database.insert_item (item_05);

        return project;
    }

    public Gee.ArrayList<Objects.Shortcuts?> get_shortcuts () {
        var shortcuts = new Gee.ArrayList<Objects.Shortcuts?> ();

        shortcuts.add (new Objects.Shortcuts (_("Create a new task"), { "Ctrl", "N" }));
        shortcuts.add (new Objects.Shortcuts (_("Create a new task at the top of the list (only works inside projects)"), { "Ctrl", "Shift", "N" }));
        shortcuts.add (new Objects.Shortcuts (_("Create a new area"), { "Ctrl", "Shift", "A" }));
        shortcuts.add (new Objects.Shortcuts (_("Create a new project"), { "Ctrl", "Shift", "P" }));
        shortcuts.add (new Objects.Shortcuts (_("Create a new section"), { "Ctrl", "Shift", "S" }));
        shortcuts.add (new Objects.Shortcuts (_("Open the Inbox"), { "Ctrl", "1" }));
        shortcuts.add (new Objects.Shortcuts (_("Open Today"), { "Ctrl", "2" }));
        shortcuts.add (new Objects.Shortcuts (_("Open Upcoming"), { "Ctrl", "3" }));
        shortcuts.add (new Objects.Shortcuts (_("Open Search"), { "Ctrl", "F" }));
        shortcuts.add (new Objects.Shortcuts (_("Manually sync"), { "Ctrl", "S" }));
        shortcuts.add (new Objects.Shortcuts (_("Quit"), { "Ctrl", "Q" }));

        return shortcuts;
    }

    public string get_todoist_error (int code) {
        var messages = new Gee.HashMap<int, string> ();

        messages.set (400, _("The request was incorrect."));
        messages.set (401, _("Authentication is required, and has failed, or has not yet been provided."));
        messages.set (403, _("The request was valid, but for something that is forbidden."));
        messages.set (404, _("The requested resource could not be found."));
        messages.set (429, _("The user has sent too many requests in a given amount of time."));
        messages.set (500, _("The request failed due to a server error."));
        messages.set (503, _("The server is currently unable to handle the request."));

        return messages.get (code);
    }

    public Gee.ArrayList<string> get_patrons () {
        var patrons = new Gee.ArrayList<string> ();

        patrons.add ("Cassidy James");
        patrons.add ("Wout");
        patrons.add ("The Linux Experiment");
        patrons.add ("William Tumeo");
        patrons.add ("Cal");
        patrons.add ("Coryn");
        patrons.add ("Marco Bluethgen");
        patrons.add ("Luke Gaudreau");
        patrons.add ("I Sutter");
        patrons.add ("M");
        patrons.add ("James");
        patrons.add ("Sampath Rajapakse");
        patrons.add ("Kyle Riedemann");
        patrons.add ("Richard Prammer");

        return patrons;
    }

    public string get_random_avatar () {
        var avatars = new Gee.ArrayList<string> ();

        avatars.add ("/com/github/alainm23/planner/cat.svg");
        avatars.add ("/com/github/alainm23/planner/dog.svg");
        avatars.add ("/com/github/alainm23/planner/koala.svg");
        avatars.add ("/com/github/alainm23/planner/lion.svg");
        avatars.add ("/com/github/alainm23/planner/monkey.svg");
        avatars.add ("/com/github/alainm23/planner/owl.svg");
        avatars.add ("/com/github/alainm23/planner/penguin.svg");
        avatars.add ("/com/github/alainm23/planner/rabbit.svg");
        avatars.add ("/com/github/alainm23/planner/tiger.svg");
        avatars.add ("/com/github/alainm23/planner/zoo.svg");

        return avatars [GLib.Random.int_range (0, avatars.size)];
    }

    public string get_markup_format (string text) {
        Regex urlRegex = /(?P<url>(http|https)\:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]+(\/\S*))/;
        Regex mailtoRegex = /(?P<mailto>[a-zA-Z0-9\._\%\+\-]+@[a-zA-Z0-9\-\.]+\.[a-zA-Z]+(\S*))/;
        MatchInfo info;
        try {
            List<string> urls = new List<string>();
            if (urlRegex.match (text, 0, out info)) {
                do {
                    var url = info.fetch_named ("url");
                    urls.append (url);
                } while (info.next ());
            }
            List<string> emails = new List<string>();
            if (mailtoRegex.match (text, 0, out info)) {
                do {
                    var email = info.fetch_named ("mailto");
                    emails.append (email);
                } while (info.next ());
            }
            var converted = text;
            urls.foreach ((url) => {
                var urlEncoded = url.replace ("&", "&amp;");
                var urlAsLink = @"<a href=\"$urlEncoded\">$urlEncoded</a>";
                converted = converted.replace (url, urlAsLink);
            });
            emails.foreach ((email) => {
                var emailAsLink = @"<a href=\"mailto:$email\">$email</a>";
                converted = converted.replace (email, emailAsLink);
            });
            return converted;
        } catch (GLib.RegexError ex) {
            return text;
        }
    }

    public void parse_item_tags (Objects.Item item, string text) {
        var clean_text = "";
        Regex word_regex = /\S+\s*/;
        MatchInfo match_info;
        
        var match_text = text. strip ();
        for (word_regex.match (match_text, 0, out match_info) ; match_info.matches () ; match_info.next ()) {
            var word = match_info.fetch (0);
            var stripped =    word.strip ().down ();

            switch (stripped) {
                case TODAY:
                    item.due_date = new GLib.DateTime.now_local ().to_string ();
                    break;
                case TOMORROW:
                    item.due_date = new GLib.DateTime.now_local ().add_days (1).to_string ();
                    break;
                case "p1":
                    item.priority = 4;
                    break;
                case "p2":
                    item.priority = 3;
                    break;
                case "p3":
                    item.priority = 2;
                    break;
                case "p4":
                    item.priority = 1;
                    break;
                default:
                    clean_text+= word;
                    break;
            }
        }

        item.content = clean_text;
    }

    public string build_undo_object (string type, string object_type, int64 object_id, string undo_type, string undo_value) {
        var builder = new Json.Builder ();
        builder.begin_object ();

        builder.set_member_name ("type");
        builder.add_string_value (type);

        builder.set_member_name ("object_type");
        builder.add_string_value (object_type);

        builder.set_member_name ("object_id");
        builder.add_int_value (object_id);

        if (undo_type != "") {
            builder.set_member_name ("undo_type");
            builder.add_string_value (undo_type);

            if (undo_type == "string") {
                builder.set_member_name ("undo_value");
                builder.add_string_value (undo_value);
            } else if (undo_type == "int") {
                builder.set_member_name ("undo_value");
                builder.add_int_value (int64.parse (undo_type));
            }
        }

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);
        
        return generator.to_data (null);
    }
}
