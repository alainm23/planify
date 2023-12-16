/*
* Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
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

public class Util : GLib.Object {
    private static Util? _instance;
    public static Util get_default () {
        if (_instance == null) {
            _instance = new Util ();
        }

        return _instance;
    }

    /*
    *  Colors Utils
    */

    private Gee.HashMap<string, Objects.Color>? colors;
    public Gee.HashMap<string, Objects.Color> get_colors () {
        if (colors == null) {
            colors = new Gee.HashMap<string, Objects.Color> ();

            colors.set ("berry_red", new Objects.Color (30, _("Berry Red"), "#b8256f"));
            colors.set ("#b8256f", new Objects.Color (30, _("Berry Red"), "berry_red"));

            colors.set ("red", new Objects.Color (31, _("Red"), "#db4035"));
            colors.set ("#db4035", new Objects.Color (31, _("Red"), "red"));

            colors.set ("orange", new Objects.Color (32, _("Orange"), "#ff9933"));
            colors.set ("#ff9933", new Objects.Color (32, _("Orange"), "orange"));

            colors.set ("yellow", new Objects.Color (33, _("Olive Green"), "#fad000"));
            colors.set ("#fad000", new Objects.Color (33, _("Olive Green"), "yellow"));

            colors.set ("olive_green", new Objects.Color (34, _("Yellow"), "#afb83b"));
            colors.set ("#afb83b", new Objects.Color (34, _("Yellow"), "olive_green"));

            colors.set ("lime_green", new Objects.Color (35, _("Lime Green"), "#7ecc49"));
            colors.set ("#7ecc49", new Objects.Color (35, _("Lime Green"), "lime_green"));

            colors.set ("green", new Objects.Color (36, _("Green"), "#299438"));
            colors.set ("#299438", new Objects.Color (36, _("Green"), "green"));

            colors.set ("mint_green", new Objects.Color (37, _("Mint Green"), "#6accbc"));
            colors.set ("#6accbc", new Objects.Color (37, _("Mint Green"), "mint_green"));

            colors.set ("teal", new Objects.Color (38, _("Teal"), "#158fad"));
            colors.set ("#158fad", new Objects.Color (38, _("Teal"), "teal"));

            colors.set ("sky_blue", new Objects.Color (39, _("Sky Blue"), "#14aaf5"));
            colors.set ("#14aaf5", new Objects.Color (39, _("Sky Blue"), "sky_blue"));

            colors.set ("light_blue", new Objects.Color (40, _("Light Blue"), "#96c3eb"));
            colors.set ("#96c3eb", new Objects.Color (40, _("Light Blue"), "light_blue"));

            colors.set ("blue", new Objects.Color (41, _("Blue"), "#4073ff"));
            colors.set ("#4073ff", new Objects.Color (41, _("Blue"), "blue"));

            colors.set ("grape", new Objects.Color (42, _("Grape"), "#884dff"));
            colors.set ("#884dff", new Objects.Color (42, _("Grape"), "grape"));

            colors.set ("violet", new Objects.Color (43, _("Violet"), "#af38eb"));
            colors.set ("#af38eb", new Objects.Color (43, _("Violet"), "violet"));

            colors.set ("lavender", new Objects.Color (44, _("Lavander"), "#eb96eb"));
            colors.set ("#eb96eb", new Objects.Color (44, _("Lavander"), "lavender"));

            colors.set ("magenta", new Objects.Color (45, _("Magenta"), "#e05194"));
            colors.set ("#e05194", new Objects.Color (45, _("Magenta"), "magenta"));

            colors.set ("salmon", new Objects.Color (46, _("Salmon"), "#ff8d85"));
            colors.set ("#ff8d85", new Objects.Color (46, _("Salmon"), "salmon"));

            colors.set ("charcoal", new Objects.Color (47, _("Charcoal"), "#808080"));
            colors.set ("#808080", new Objects.Color (47, _("Charcoal"), "charcoal"));

            colors.set ("grey", new Objects.Color (48, _("Grey"), "#b8b8b8"));
            colors.set ("#b8b8b8", new Objects.Color (48, _("Grey"), "grey"));

            colors.set ("taupe", new Objects.Color (49, _("Taupe"), "#ccac93"));
            colors.set ("#ccac93", new Objects.Color (49, _("Taupe"), "taupe"));
        }

        return colors;
    }

    public string get_color_name (string key) {
        return get_colors ().get (key).name;
    }

    public string get_color (string key) {
        return get_colors ().get (key).hexadecimal;
    }

    public string get_random_color () {
        string returned = "berry_red";
        int random = GLib.Random.int_range (30, 50);
        foreach (var entry in get_colors ().entries) {
            if (entry.value.id == random) {
                returned = entry.key;
            }
        }

        return returned;
    }

    // Providers
    
    private Gee.HashMap<string, Gtk.CssProvider>? providers;
    public void set_widget_color (string color, Gtk.Widget widget) {
        if (providers == null) {
            providers = new Gee.HashMap<string, Gtk.CssProvider> ();
        }
 
        if (!providers.has_key (color)) {
            string style = """
                @define-color colorAccent %s;
                @define-color accent_color %s;
            """.printf (color, color);

            var style_provider = new Gtk.CssProvider ();
            style_provider.load_from_string (style);

            providers[color] = style_provider;
        }

        unowned Gtk.StyleContext style_context = widget.get_style_context ();
        style_context.add_provider (providers[color], Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    public void set_widget_priority (int priority, Gtk.Widget widget) {
        widget.remove_css_class ("priority-1-color");
        widget.remove_css_class ("priority-2-color");
        widget.remove_css_class ("priority-3-color");
        widget.remove_css_class ("priority-4-color");

        if (priority == Constants.PRIORITY_1) {
            widget.add_css_class ("priority-1-color");
        } else if (priority == Constants.PRIORITY_2) {
            widget.add_css_class ("priority-2-color");
        } else if (priority == Constants.PRIORITY_3) {
            widget.add_css_class ("priority-3-color");
        } else if (priority == Constants.PRIORITY_4) {
            widget.add_css_class ("priority-4-color");
        }
    }

    public void download_profile_image (string id, string avatar_url) {
        if (id == null) {
            return;
        }
        
        var file_path = File.new_for_path (get_avatar_path (id));
        var file_from_uri = File.new_for_uri (avatar_url);

        if (!file_path.query_exists ()) {
            MainLoop loop = new MainLoop ();

            file_from_uri.copy_async.begin (file_path, 0, Priority.DEFAULT, null, (current_num_bytes, total_num_bytes) => {}, (obj, res) => {
                try {
                    if (file_from_uri.copy_async.end (res)) {
                        // Services.EventBus.get_default ().avatar_downloaded ();
                    }
                } catch (Error e) {
                    debug ("Error: %s\n", e.message);
                }

                loop.quit ();
            });

            loop.run ();
        }
    }

    public string get_avatar_path (string id) {
        return GLib.Path.build_filename (
            Environment.get_user_data_dir () + "/io.github.alainm23.planify", id + ".jpg"
        );
    }

    public string generate_id (Objects.BaseObject? base_object = null) {
        if (base_object == null) {
            return Uuid.string_random ();
        }

        var collection = Services.Database.get_default ().get_collection_by_type (base_object);
        var id = Uuid.string_random ();

        if (check_id_exists (collection, id)) {
            return generate_id (base_object);
        }

        return id;
    }

    private bool check_id_exists (Gee.ArrayList<Objects.BaseObject> items, string id) {
        bool returned = false;
        foreach (Objects.BaseObject base_object in items) {
            if (base_object.id == id) {
                returned = true;
                break;
            }
        }

        return returned;
    }

    public string generate_string () {
        return generate_id ();
    }

    public string get_encode_text (string text) {
        return Uri.escape_string (text, null, false);
    }

    public string get_theme_name () {
        string returned = "";
        int appearance_mode = Services.Settings.get_default ().settings.get_enum ("appearance");
        
        switch (appearance_mode) {
            case 0:
                returned = _("Light");
                break;
            case 1:
                returned = _("Dark");
                break;
            case 2:
                returned = _("Dark Blue");
                break;
        }

        return returned;
    }

    public string get_badge_name () {
        string returned = "";
        int badge_count = Services.Settings.get_default ().settings.get_enum ("badge-count");
        
        switch (badge_count) {
            case 0:
                returned = _("None");
                break;
            case 1:
                returned = _("Inbox");
                break;
            case 2:
                returned = _("Today");
                break;
            case 3:
                returned = _("Today + Inbox");
                break;
        }

        return returned;
    }

    public void update_theme () {
        string _css = """
            @define-color window_bg_color %s;
            @define-color popover_bg_color %s;
            @define-color sidebar_bg_color %s;
            @define-color item_border_color %s;
            @define-color upcoming_bg_color %s;
            @define-color upcoming_fg_color %s;
            @define-color selected_color %s;
        """;

        int appearance_mode = Services.Settings.get_default ().settings.get_enum ("appearance");
        bool dark_mode = Services.Settings.get_default ().settings.get_boolean ("dark-mode");
        bool system_appearance = Services.Settings.get_default ().settings.get_boolean ("system-appearance");

        var granite_settings = Granite.Settings.get_default ();

        if (system_appearance) {
            dark_mode = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        }

        var provider = new Gtk.CssProvider ();

        string window_bg_color = "";
        string popover_bg_color = "";
        string sidebar_bg_color = "";
        string item_border_color = "";
        string upcoming_bg_color = "";
        string upcoming_fg_color = ""; 
        string selected_color = "";

        if (dark_mode) {
            if (appearance_mode == 1) {
                window_bg_color = "#151515";
                popover_bg_color = "shade(#151515, 1.4)";
                sidebar_bg_color = "#1e1e1e";
                item_border_color = "#333333";
                upcoming_bg_color = "#313234";
                upcoming_fg_color = "#ededef";
                selected_color = "@popover_bg_color";
                Adw.StyleManager.get_default ().color_scheme = Adw.ColorScheme.FORCE_DARK;
            } else if (appearance_mode == 2) {
                window_bg_color = "#0B0B11";
                popover_bg_color = "#15151B";
                sidebar_bg_color = "#15161b";
                item_border_color = "shade(#333333, 1.35)";
                upcoming_bg_color = "#313234";
                upcoming_fg_color = "#ededef";
                selected_color = "@popover_bg_color";
                Adw.StyleManager.get_default ().color_scheme = Adw.ColorScheme.FORCE_DARK;
            }
        } else {
            window_bg_color = "#fafafa";
            popover_bg_color = "#ffffff";
            sidebar_bg_color = "#f6f5f4";
            item_border_color = "@borders";
            upcoming_bg_color = "#ededef";
            upcoming_fg_color = "shade(#ededef, 0)";
            selected_color = "alpha(@shade_color, 0.65)";
            Adw.StyleManager.get_default ().color_scheme = Adw.ColorScheme.FORCE_LIGHT;
        }

        var css = _css.printf (
            window_bg_color,
            popover_bg_color,
            sidebar_bg_color,
            item_border_color,
            upcoming_bg_color,
            upcoming_fg_color,
            selected_color
        );

        provider.load_from_string (css);
        
        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (), provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        Services.EventBus.get_default ().theme_changed ();
    }

    /**
    * Replaces all line breaks with a space and
    * replaces multiple spaces with a single one.
    */
    private GLib.Regex line_break_to_space_regex = null;
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

    public string get_dialog_text (string text) {
        return text.replace ("&", "&amp;").replace ("<", "&lt;").replace (">", "&gt;");
    }

    /*
        DateTime
    */

    public GLib.DateTime? get_todoist_datetime (string date) {
        if (date == "") {
            return null;
        }

        GLib.DateTime datetime = null;
        
        // YYYY-MM-DD 
        if (date.length == 10) {
            var _date = date.split ("-");

            datetime = new GLib.DateTime.local (
                int.parse (_date [0]),
                int.parse (_date [1]),
                int.parse (_date [2]),
                0,
                0,
                0
            );
        // YYYY-MM-DDTHH:MM:SS
        } else if (date.length == 19) {
            var _date = date.split ("T") [0].split ("-");
            var _time = date.split ("T") [1].split (":");

            datetime = new GLib.DateTime.local (
                int.parse (_date [0]),
                int.parse (_date [1]),
                int.parse (_date [2]),
                int.parse (_time [0]),
                int.parse (_time [1]),
                int.parse (_time [2])
            );
        // YYYY-MM-DDTHH:MM:SSZ
        } else {
            var _date = date.split ("T") [0].split ("-");
            datetime = new GLib.DateTime.local (
                int.parse (_date [0]),
                int.parse (_date [1]),
                int.parse (_date [2]),
                0,
                0,
                0
            );
        }

        return datetime;
    }

    public string get_relative_date_from_date (GLib.DateTime datetime) {
        string returned = "";

        if (is_today (datetime)) {
            returned = _("Today");
        } else if (is_tomorrow (datetime)) {
            returned = _("Tomorrow");
        } else if (is_yesterday (datetime)) {
            returned = _("Yesterday");
        } else {
            returned = get_default_date_format_from_date (datetime);
        }

        if (has_time (datetime)) {
            returned = "%s %s".printf (returned, datetime.format (get_default_time_format ()));
        }

        return returned;
    }

    public string get_default_time_format () {
        return Granite.DateTime.get_default_time_format (
            is_clock_format_12h (), false
        );
    }

    public string get_calendar_icon (GLib.DateTime date) {
        if (is_today (date)) {
            return "planner-today";
        } else {
            return "planner-scheduled";
        }
    }

    public bool is_today (GLib.DateTime date) {
        return Granite.DateTime.is_same_day (date, new GLib.DateTime.now_local ());
    }

    public bool is_tomorrow (GLib.DateTime date) {
        return Granite.DateTime.is_same_day (date, new GLib.DateTime.now_local ().add_days (1));
    }

    public bool is_yesterday (GLib.DateTime date) {
        return Granite.DateTime.is_same_day (date, new GLib.DateTime.now_local ().add_days (-1));
    }

    public bool is_same_day (GLib.DateTime day1, GLib.DateTime day2) {
        return Granite.DateTime.is_same_day (day1, day2);
    }

    public bool is_overdue (GLib.DateTime date) {
        if (get_format_date (date).compare (get_format_date (new DateTime.now_local ())) == -1) {
            return true;
        }

        return false;
    }

    public GLib.DateTime next_recurrency (GLib.DateTime datetime, Objects.DueDate duedate) {
        GLib.DateTime returned = datetime;

        if (duedate.recurrency_type == RecurrencyType.EVERY_DAY) {
            returned = returned.add_days (duedate.recurrency_interval);
        } else if (duedate.recurrency_type == RecurrencyType.EVERY_WEEK) {
            if (duedate.recurrency_weeks == "") {
                returned = returned.add_days (duedate.recurrency_interval * 7);
            } else {
                returned = next_recurrency_week (datetime, duedate, true);
            }
        } else if (duedate.recurrency_type == RecurrencyType.EVERY_MONTH) {
            returned = returned.add_months (duedate.recurrency_interval);
        } else if (duedate.recurrency_type == RecurrencyType.EVERY_YEAR) {
            returned = returned.add_years (duedate.recurrency_interval);
        }

        return returned;
    }

    public int get_next_day_of_week_from_recurrency_week (GLib.DateTime datetime, Objects.DueDate duedate) {
        string[] weeks = duedate.recurrency_weeks.split (",");
        int day_of_week = datetime.get_day_of_week ();
        int index = 0;

        for (int i = 0; i < weeks.length ; i++) {
            if (day_of_week <= int.parse (weeks[i])) {
                index = i;
                break;
            }
        }
        
        if (index > weeks.length - 1) {
            index = 0;
        }

        return int.parse (weeks[index]);
    }

    public GLib.DateTime next_recurrency_week (GLib.DateTime datetime, Objects.DueDate duedate, bool user = false) {
        string[] weeks = duedate.recurrency_weeks.split (","); // [1, 2, 3]
        int day_of_week = datetime.get_day_of_week (); // 2
        int days = 0;
        int next_day = 0;
        int index = 0;
        int recurrency_interval = 0;

        for (int i = 0; i < weeks.length ; i++) {
            if (day_of_week < int.parse (weeks[i])) {
                index = i;
                break;
            }
        }

        next_day = int.parse (weeks[index]);

        if (day_of_week < next_day) {
            days = next_day - day_of_week;
        } else {
            days = 7 - (day_of_week - next_day);
        }

        if (user && index == 0) {
            recurrency_interval = (duedate.recurrency_interval - 1) * 7;
        }

        return datetime.add_days (days).add_days (recurrency_interval);
    }

    public string get_recurrency_weeks (RecurrencyType recurrency_type, int recurrency_interval,
        string recurrency_weeks) {
        string returned = recurrency_type.to_friendly_string (recurrency_interval);

        if (recurrency_type == RecurrencyType.EVERY_WEEK &&
            recurrency_weeks.split (",").length > 0) {
            string weeks = "";
            if (recurrency_weeks.contains ("1")) {
                weeks += _("Mo,");
            }
    
            if (recurrency_weeks.contains ("2")) {
                weeks += _("Tu,");
            }
    
            if (recurrency_weeks.contains ("3")) {
                weeks += _("We,");
            }
    
            if (recurrency_weeks.contains ("4")) {
                weeks += _("Th,");
            }
    
            if (recurrency_weeks.contains ("5")) {
                weeks += _("Fr,");
            }
    
            if (recurrency_weeks.contains ("6")) {
                weeks += _("Sa,");
            }
    
            if (recurrency_weeks.contains ("7")) {
                weeks += _("Su,");
            }
    
            weeks = weeks.slice (0, -1);
            returned = "%s (%s)".printf (returned, weeks);
        }

        return returned;
    }

    public GLib.DateTime get_today_format_date () {
        return get_format_date (new DateTime.now_local ());
    }

    public GLib.DateTime get_format_date (GLib.DateTime date) {
        return new DateTime.local (
            date.get_year (),
            date.get_month (),
            date.get_day_of_month (),
            0,
            0,
            0
        );
    }

    public string get_default_date_format_from_date (GLib.DateTime date) {
        var format = date.format (Granite.DateTime.get_default_date_format (
            false,
            true,
            date.get_year () != new GLib.DateTime.now_local ().get_year ()
        ));
        return format;
    }

    public string get_todoist_datetime_format (GLib.DateTime date) {
        string returned = "";

        if (has_time (date)) {
            returned = date.format ("%F") + "T" + date.format ("%T");
        } else {
            returned = date.format ("%F");
        }

        return returned;
    }

    public bool has_time (GLib.DateTime datetime) {
        if (datetime == null) {
            return false;
        }

        bool returned = true;
        
        if (datetime.get_hour () == 0 && datetime.get_minute () == 0 && datetime.get_second () == 0) {
            returned = false;
        }

        return returned;
    }

    public bool has_time_from_string (string date) {
        return has_time (new GLib.DateTime.from_iso8601 (date, new GLib.TimeZone.local ()));
    }

    public GLib.DateTime get_date_from_string (string date) {
        return new GLib.DateTime.from_iso8601 (date, new GLib.TimeZone.local ());
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

    public GLib.DateTime get_start_of_month (owned GLib.DateTime? date = null) {
        if (date == null) {
            date = new GLib.DateTime.now_local ();
        }

        return new GLib.DateTime.local (date.get_year (), date.get_month (), 1, 0, 0, 0);
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

    /*
        Icons
    */

    private Gee.HashMap<string, bool>? _dynamic_icons;
    public Gee.HashMap<string, bool> dynamic_icons {
        get {
            if (_dynamic_icons == null) {
                _dynamic_icons = new Gee.HashMap<string, bool> ();
                _dynamic_icons.set ("planner-calendar", true);
                _dynamic_icons.set ("planner-search", true);
                _dynamic_icons.set ("chevron-right", true);
                _dynamic_icons.set ("chevron-down", true);
                _dynamic_icons.set ("planner-refresh", true);
                _dynamic_icons.set ("planner-edit", true);
                _dynamic_icons.set ("planner-trash", true);
                _dynamic_icons.set ("planner-star", true);
                _dynamic_icons.set ("planner-note", true);
                _dynamic_icons.set ("planner-close-circle", true);
                _dynamic_icons.set ("planner-check-circle", true);
                _dynamic_icons.set ("planner-flag", true);
                _dynamic_icons.set ("planner-tag", true);
                _dynamic_icons.set ("planner-pinned", true);
                _dynamic_icons.set ("planner-settings", true);
                _dynamic_icons.set ("planner-bell", true);
                _dynamic_icons.set ("sidebar-left", true);
                _dynamic_icons.set ("sidebar-right", true);
                _dynamic_icons.set ("planner-mail", true);
                _dynamic_icons.set ("planner-note", true);
                _dynamic_icons.set ("planner-settings-sliders", true);
                _dynamic_icons.set ("planner-list", true);
                _dynamic_icons.set ("planner-board", true);
                _dynamic_icons.set ("color-swatch", true);
                _dynamic_icons.set ("emoji-happy", true);
                _dynamic_icons.set ("planner-clipboard", true);
                _dynamic_icons.set ("planner-copy", true);
                _dynamic_icons.set ("planner-rotate", true);
                _dynamic_icons.set ("planner-section", true);
                _dynamic_icons.set ("unordered-list", true);
                _dynamic_icons.set ("ordered-list", true);
                _dynamic_icons.set ("menu", true);
                _dynamic_icons.set ("share", true);
                _dynamic_icons.set ("dropdown", true);
                _dynamic_icons.set ("information", true);
                _dynamic_icons.set ("dots-vertical", true);
                _dynamic_icons.set ("plus", true);
                _dynamic_icons.set ("file-download", true);
                _dynamic_icons.set ("download", true);
                _dynamic_icons.set ("file", true);
                _dynamic_icons.set ("gift", true);
            }

            return _dynamic_icons;
        }
    }

    public bool is_dynamic_icon (string icon_name) {
        return dynamic_icons.has_key (icon_name);
    }

    public bool is_input_valid (Gtk.Entry entry) {
        return entry.get_text_length () > 0;
    }

    public bool is_text_valid (string text) {
        return text.length > 0;
    }

    public string get_short_name (string name, int size = Constants.SHORT_NAME_SIZE) {
        string returned = name;
        
        if (name.length > size) {
            returned = name.substring (0, size) + "…";
        }

        return returned;
    }

    public bool is_clock_format_12h () {
        return Services.Settings.get_default ().settings.get_string ("clock-format").contains ("12h");
    }

    public void clear_database (string title, string message, Gtk.Window window) {
        var dialog = new Adw.MessageDialog (window, title, message);

        dialog.body_use_markup = true;
        dialog.add_response ("cancel", _("Cancel"));
        dialog.add_response ("delete", _("Reset all"));
        dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
        dialog.show ();

        dialog.response.connect ((response) => {
            if (response == "delete") {
                Services.Database.get_default ().clear_database ();
                Services.Settings.get_default ().reset_settings ();
                show_alert_destroy (window);
            }
        });
    }

    public void show_alert_destroy (Gtk.Window window) {
        var dialog = new Adw.MessageDialog (window, null, _("Process completed, you need to start Planify again."));

        dialog.modal = true;
        dialog.add_response ("ok", _("Ok"));
        dialog.show ();

        dialog.response.connect ((response) => {
            window.destroy ();
        });
    }

    public FilterType get_filter () {
        switch (Services.Settings.get_default ().settings.get_enum ("homepage-item")) {
            case 0:
                return FilterType.INBOX;
            case 1:
                return FilterType.TODAY;
            case 2:
                return FilterType.SCHEDULED;
            case 3:
                return FilterType.LABELS;
            default:
                assert_not_reached ();
        }
    }

    public int get_default_priority () {
        int default_priority = Services.Settings.get_default ().settings.get_enum ("default-priority");
        int returned = 1;

        if (default_priority == 0) {
            returned = 4;
        } else if (default_priority == 1) {
            returned = 3;
        } else if (default_priority == 2) {
            returned = 2;
        } else if (default_priority == 3) {
            returned = 1;
        }

        return returned;
    }

    public int to_caldav_priority (int priority) {
        int returned = 1;

        if (priority == 4) {
            returned = 1;
        } else if (priority == 3) {
            returned = 5;
        } else if (priority == 2) {
            returned = 9;
        } else {
            returned = 0;
        }

        return returned;
    }

    /*
    *   Theme Utils
    */

    public bool is_dark_theme () {
        return Services.Settings.get_default ().settings.get_boolean ("dark-mode");
    }

    public bool is_flatpak () {
        var is_flatpak = Environment.get_variable ("FLATPAK_ID");
        if (is_flatpak != null) {
            return true;
        }
    
        return false;
    }
    
    public List<Gtk.ListBoxRow> get_children (Gtk.ListBox list) {
        List<Gtk.ListBoxRow> response = new List<Gtk.ListBoxRow> ();

        Gtk.ListBoxRow item_row = null;
        var row_index = 0;

        do {
            item_row = list.get_row_at_index (row_index);

            if (item_row != null) {
                response.append (item_row);
            }

            row_index++;
        } while (item_row != null);

        return response;
    }

    public Adw.Toast create_toast (string title, uint timeout = 2, Adw.ToastPriority priority = Adw.ToastPriority.NORMAL) {
        var toast = new Adw.Toast (title);
        toast.timeout = timeout;
        toast.priority = priority;

        return toast;
    }

    public string get_priority_title (int priority) {
        if (priority == Constants.PRIORITY_1) {
            return _("Priority 1: high");
        } else if (priority == Constants.PRIORITY_2) {
            return _("Priority 2: medium");
        } else if (priority == Constants.PRIORITY_3) {
            return _("Priority 3: low");
        } else if (priority == Constants.PRIORITY_4) {
            return _("Priority 4: none");
        } else {
            return _("Priority 4: none");
        }
    }

    public string get_priority_icon (int priority) {
        if (priority == Constants.PRIORITY_1) {
            return "planner-priority-1";
        } else if (priority == Constants.PRIORITY_2) {
            return "planner-priority-2";
        } else if (priority == Constants.PRIORITY_3) {
            return "planner-priority-3";
        } else if (priority == Constants.PRIORITY_4) {
            return "planner-flag";
        } else {
            return "planner-flag";
        }
    }

    private Gee.HashMap<string, Objects.Priority> priority_views;
    public Objects.Priority get_priority_filter (string view_id) {
        if (priority_views == null) {
            priority_views = new Gee.HashMap<string, Objects.Priority> ();
        }

        if (priority_views.has_key (view_id)) {
            return priority_views[view_id];
        } else {
            int priority = int.parse (view_id.split ("-")[1]);
            priority_views[view_id] = new Objects.Priority (priority);
            return priority_views[view_id];
        }
    }

    public void change_default_inbox () {
        var default_inbox = (DefaultInboxProject) Services.Settings.get_default ().settings.get_enum ("default-inbox");
        Objects.Project inbox_project = null;

        if (default_inbox == DefaultInboxProject.LOCAL) {
            inbox_project = Services.Database.get_default ().get_project (
                Services.Settings.get_default ().settings.get_string ("local-inbox-project-id")
            );

            if (inbox_project == null) {
                inbox_project = create_inbox_project ();
            }
        } else if (default_inbox == DefaultInboxProject.TODOIST) {
            inbox_project = Services.Database.get_default ().get_project (
                Services.Settings.get_default ().settings.get_string ("todoist-inbox-project-id")
            );
        }

        Services.Settings.get_default ().settings.set_string ("inbox-project-id", inbox_project.id);
        Services.EventBus.get_default ().inbox_project_changed ();
    }

    public Objects.Project create_inbox_project () {
        Objects.Project inbox_project = new Objects.Project ();
        inbox_project.id = Util.get_default ().generate_id (inbox_project);
        inbox_project.backend_type = BackendType.LOCAL;
        inbox_project.name = _("Inbox");
        inbox_project.inbox_project = true;
        inbox_project.color = "blue";
        
        if (Services.Database.get_default ().insert_project (inbox_project)) {
            Services.Settings.get_default ().settings.set_string ("inbox-project-id", inbox_project.id);
            Services.Settings.get_default ().settings.set_string ("local-inbox-project-id", inbox_project.id);
        }

        return inbox_project;
    }

    public void create_tutorial_project () {
        Objects.Project project = new Objects.Project ();
        project.id = Util.get_default ().generate_id (project);
        project.backend_type = BackendType.LOCAL;
        project.icon_style = ProjectIconStyle.EMOJI;
        project.emoji = "🚀️";
        project.name = _("Meet Planify");
        project.color = "blue";
        project.show_completed = true;
        project.description = _("This project shows you everything you need to know to hit the ground running. Don’t hesitate to play around in it – you can always create a new one from settings.");

        if (Services.Database.get_default ().insert_project (project)) {
            var item_01 = new Objects.Item ();
            item_01.id = Util.get_default ().generate_id (item_01);
            item_01.project_id = project.id;
            item_01.content = _("Tap this to-do");
            item_01.description = _("You're looking at a to-do! Complete it by tapping the checkbox on the left. Completed to-dos are collected al the bottom of your project.");

            var item_02 = new Objects.Item ();
            item_02.id = Util.get_default ().generate_id (item_02);
            item_02.project_id = project.id;
            item_02.content = _("Create a new to-do");
            item_02.description = _("Now it's your turn, tap the '+' button at the top of your project, enter any pending and tap the blue 'Save' button.");

            var item_03 = new Objects.Item ();
            item_03.id = Util.get_default ().generate_id (item_03);
            item_03.project_id = project.id;
            item_03.content = _("Plan this to-do by today or later");
            item_03.description = _("Tap the calendar button at the bottom to decide when to do this to-do.");

            var item_04 = new Objects.Item ();
            item_04.id = Util.get_default ().generate_id (item_04);
            item_04.project_id = project.id;
            item_04.content = _("Reorder yours to-dos");
            item_04.description = _("To reorder your list, tap amd hold a to-do, then drag it to where it shpuld go.");

            var item_05 = new Objects.Item ();
            item_05.id = Util.get_default ().generate_id (item_05);
            item_05.project_id = project.id;
            item_05.content = _("Create a project");
            item_05.description = _("Organize your to-dos better! Go to the left panel and click the '+' button in the 'On This Computer' section and add a project of your own.");

            var item_06 = new Objects.Item ();
            item_06.id = Util.get_default ().generate_id (item_06);
            item_06.project_id = project.id;
            item_06.content = _("You’re done!");
            item_06.description = _("""That’s all you really need to know. Feel free to start adding your own projects and to-dos.

You can come back to this project later to learn the advanced features below..

We hope you’ll enjoy using Planify!""");

            project.add_item_if_not_exists (item_01);
            project.add_item_if_not_exists (item_02);
            project.add_item_if_not_exists (item_03);
            project.add_item_if_not_exists (item_04);
            project.add_item_if_not_exists (item_05);
            project.add_item_if_not_exists (item_06);

            var section_01 = new Objects.Section ();
            section_01.id = Util.get_default ().generate_id (section_01);
            section_01.project_id = project.id;
            section_01.name = _("Tune your setup");

            project.add_section_if_not_exists (section_01);

            var item_02_01 = new Objects.Item ();
            item_02_01.id = Util.get_default ().generate_id (item_02_01);
            item_02_01.project_id = project.id;
            item_02_01.section_id = section_01.id;
            item_02_01.content = _("Show your calendar events");
            item_02_01.description = _("You can display your system's calendar events in Planify. Go to 'Preferences' 🡒 Calendar Events to turn ir on.");

            var item_02_02 = new Objects.Item ();
            item_02_02.id = Util.get_default ().generate_id (item_02_02);
            item_02_02.project_id = project.id;
            item_02_02.section_id = section_01.id;
            item_02_02.content = _("Enable synchronization with third-party service.");
            item_02_02.description = _("Planify not only creates tasks locally, it can also synchronize your Todoist account. Go to 'Preferences' 🡒 'Accounts'.");

            section_01.add_item_if_not_exists (item_02_01);
            section_01.add_item_if_not_exists (item_02_02);
        }
    }

    public void create_default_labels () {
        var label_01 = new Objects.Label ();
        label_01.id = Util.get_default ().generate_id (label_01);
        label_01.backend_type = BackendType.LOCAL;
        label_01.name = _("💼️Work");
        label_01.color = "taupe";

        var label_02 = new Objects.Label ();
        label_02.id = Util.get_default ().generate_id (label_02);
        label_02.backend_type = BackendType.LOCAL;
        label_02.name = _("🎒️School");
        label_02.color = "berry_red";

        var label_03 = new Objects.Label ();
        label_03.id = Util.get_default ().generate_id (label_03);
        label_03.backend_type = BackendType.LOCAL;
        label_03.name = _("👉️Delegated");
        label_03.color = "yellow";

        var label_04 = new Objects.Label ();
        label_04.id = Util.get_default ().generate_id (label_04);
        label_04.backend_type = BackendType.LOCAL;
        label_04.name = _("🏡️Home");
        label_04.color = "lime_green";

        var label_05 = new Objects.Label ();
        label_05.id = Util.get_default ().generate_id (label_05);
        label_05.backend_type = BackendType.LOCAL;
        label_05.name = _("🏃‍♀️️Follow Up");
        label_05.color = "grey";

        Services.Database.get_default ().insert_label (label_01);
        Services.Database.get_default ().insert_label (label_02);
        Services.Database.get_default ().insert_label (label_03);
        Services.Database.get_default ().insert_label (label_04);
        Services.Database.get_default ().insert_label (label_05);
    }

    public string get_markup_format (string _text) {
        var text = get_dialog_text (_text);

        Regex mailto_regex = /(?P<mailto>[a-zA-Z0-9\._\%\+\-]+@[a-zA-Z0-9\-\.]+\.[a-zA-Z]+(\S*))/;
        Regex url_regex = /(?P<url>(http|https)\:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]+(\/\S*))/;
                
        Regex italic_bold_regex = /\*\*\*(.*?)\*\*\*/;
        Regex bold_regex = /\*\*(.*?)\*\*/;
        Regex italic_regex = /\*(.*?)\*/;

        MatchInfo info;
        try {
            List<string> urls = new List<string> ();
            if (url_regex.match (text, 0, out info)) {
                do {
                    var url = info.fetch_named ("url");
                    urls.append (url);
                } while (info.next ());
            }
            List<string> emails = new List<string> ();
            if (mailto_regex.match (text, 0, out info)) {
                do {
                    var email = info.fetch_named ("mailto");
                    emails.append (email);
                } while (info.next ());
            }
            Gee.ArrayList<RegexMarkdown> bolds_01 = new Gee.ArrayList<RegexMarkdown>();
            if (bold_regex.match (text, 0, out info)) {
                do {
                    bolds_01.add (new RegexMarkdown (info.fetch (0), info.fetch (1)));
                } while (info.next ());
            }
            Gee.ArrayList<RegexMarkdown> italics_01 = new Gee.ArrayList<RegexMarkdown> ();
            if (italic_regex.match (text, 0, out info)) {
                do {
                    italics_01.add (new RegexMarkdown (info.fetch (0), info.fetch (1)));
                } while (info.next ());
            }
            Gee.ArrayList<RegexMarkdown> italic_bold = new Gee.ArrayList<RegexMarkdown>();
            if (italic_bold_regex.match (text, 0, out info)) {
                do {
                    italic_bold.add (new RegexMarkdown (info.fetch (0), info.fetch (1)));
                } while (info.next ());
            }

            var converted = text;
            urls.foreach ((url) => {
                var url_encoded = url.replace ("&", "&amp;");
                var url_as_link = @"<a href=\"$url_encoded\">$url_encoded</a>";
                converted = converted.replace (url, url_as_link);
            });
            emails.foreach ((email) => {
                var email_as_link = @"<a href=\"mailto:$email\">$email</a>";
                converted = converted.replace (email, email_as_link);
            });
            foreach (RegexMarkdown m in italic_bold) {
                string format = "<i><b>" + m.text + "</b></i>";
                converted = converted.replace (m.match, format);
            }
            foreach (RegexMarkdown m in bolds_01) {
                string format = "<b>" + m.text + "</b>";
                converted = converted.replace (m.match, format);
            }
            foreach (RegexMarkdown m in italics_01) {
                string format = "<i>" + m.text + "</i>";
                converted = converted.replace (m.match, format);
            }

            return converted;
        } catch (GLib.RegexError ex) {
            return text;
        }
    }

    public BackendType get_backend_type_by_text (string backend_type) {
        if (backend_type == "local") {
            return BackendType.LOCAL;
        } else if (backend_type == "todoist") {
            return BackendType.TODOIST;
        } else if (backend_type == "google-tasks") {
            return BackendType.GOOGLE_TASKS;
        } else if (backend_type == "caldav") {
            return BackendType.CALDAV;
        } else {
            return BackendType.NONE;
        }
    }
}

public class RegexMarkdown {
    public string match { get; set; }
    public string text { get; set; }
    public string extra { get; set; }
    public RegexMarkdown (string match, string text, string extra="") {
        this.match = match;
        this.text = text;
        this.extra = extra;
    }
}
