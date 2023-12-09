public class Util : GLib.Object {
    private static Util? _instance;
    public static Util get_default () {
        if (_instance == null) {
            _instance = new Util ();
        }

        return _instance;
    }

    public string generate_id (int len=10) {
        string allowed_characters = "0123456789";

        var password_builder = new StringBuilder ();
        for (var i = 0; i < len; i++) {
            var random_index = Random.int_range (0, allowed_characters.length);
            password_builder.append_c (allowed_characters[random_index]);
        }

        if (int64.parse (password_builder.str) <= 0) {
            return generate_id ();
        }

        return password_builder.str;
    }

    public string generate_string () {
        string allowed_characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" + "0123456789";

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

    public string get_encode_text (string text) {
        return text.replace ("&", "%26").replace ("#", "%23");
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
                Adw.StyleManager.get_default ().set_color_scheme (Adw.ColorScheme.FORCE_DARK);
            } else if (appearance_mode == 2) {
                window_bg_color = "#0B0B11";
                popover_bg_color = "#15151B";
                sidebar_bg_color = "#15161b";
                item_border_color = "shade(#333333, 1.35)";
                upcoming_bg_color = "#313234";
                upcoming_fg_color = "#ededef";
                selected_color = "@popover_bg_color";
                Adw.StyleManager.get_default ().set_color_scheme (Adw.ColorScheme.FORCE_DARK);
            }
        } else {
            window_bg_color = "#ffffff";
            popover_bg_color = "#ffffff";
            sidebar_bg_color = "#fafafa";
            item_border_color = "@borders";
            upcoming_bg_color = "#ededef";
            upcoming_fg_color = "shade(#ededef, 0)";
            selected_color = "alpha(@shade_color, 0.65)";
            Adw.StyleManager.get_default ().set_color_scheme (Adw.ColorScheme.FORCE_LIGHT);
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
                _dynamic_icons.set ("planner-plus", true);
                _dynamic_icons.set ("chevron-right", true);
                _dynamic_icons.set ("chevron-down", true);
                _dynamic_icons.set ("chevron-left", true);
                _dynamic_icons.set ("planner-plus-circle", true);
                _dynamic_icons.set ("planner-refresh", true);
                _dynamic_icons.set ("planner-edit", true);
                _dynamic_icons.set ("planner-trash", true);
                _dynamic_icons.set ("planner-star", true);
                _dynamic_icons.set ("planner-note", true);
                _dynamic_icons.set ("planner-close-circle", true);
                _dynamic_icons.set ("planner-check-circle", true);
                _dynamic_icons.set ("planner-flag", true);
                _dynamic_icons.set ("dots-horizontal", true);
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
                _dynamic_icons.set ("menu", true);
            }

            return _dynamic_icons;
        }
    }

    public bool is_dynamic_icon (string icon_name) {
        return dynamic_icons.has_key (icon_name);
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

    public string get_default_time_format () {
        return Granite.DateTime.get_default_time_format (
            is_clock_format_12h (), false
        );
    }

    public bool is_clock_format_12h () {
        return Services.Settings.get_default ().settings.get_string ("clock-format").contains ("12h");
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
    
    public GLib.DateTime next_recurrency (GLib.DateTime datetime, Objects.DueDate duedate) {
        GLib.DateTime returned = datetime;

        if (duedate.recurrency_type == RecurrencyType.EVERY_DAY) {
            returned = returned.add_days (duedate.recurrency_interval);
        } else if (duedate.recurrency_type == RecurrencyType.EVERY_WEEK) {
            returned = returned.add_days (duedate.recurrency_interval * 7);
        } else if (duedate.recurrency_type == RecurrencyType.EVERY_MONTH) {
            returned = returned.add_months (duedate.recurrency_interval);
        } else if (duedate.recurrency_type == RecurrencyType.EVERY_YEAR) {
            returned = returned.add_years (duedate.recurrency_interval);
        }

        return returned;
    }

    public string next_x_recurrency (GLib.DateTime datetime, Objects.DueDate duedate) {
        string[] list = {"", ""};
        GLib.DateTime _datetime = datetime;

        for (int i = 0; i < 1; i++) {
            _datetime = next_recurrency (_datetime, duedate);
            string text = Util.get_default ().get_default_date_format_from_date (_datetime);
            list[i] = text;
        }

        list[1] = "…";

        return string.joinv (", ", list);
    }

    public string get_default_date_format_from_date (GLib.DateTime date) {
        var format = date.format (Granite.DateTime.get_default_date_format (
            false,
            true,
            date.get_year () != new GLib.DateTime.now_local ().get_year ()
        ));
        return format;
    }

    public bool is_todoist_error (int status_code) {
        return (status_code == 400 || status_code == 401 ||
            status_code == 403 || status_code == 404 ||
            status_code == 429 || status_code == 500 ||
            status_code == 503);
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

    public string get_todoist_datetime_format (GLib.DateTime date) {
        string returned = "";

        if (has_time (date)) {
            returned = date.format ("%F") + "T" + date.format ("%T");
        } else {
            returned = date.format ("%F");
        }

        return returned;
    }

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
    
    public string get_color (string key) {
        return get_colors().get (key).hexadecimal;
    }
}