public enum ProjectViewStyle {
    LIST,
    BOARD;

    public string to_string () {
        switch (this) {
            case LIST:
                return "list";

            case BOARD:
                return "board";

            default:
                assert_not_reached();
        }
    }
}

public enum ProjectIconStyle {
    PROGRESS,
    EMOJI;

    public string to_string () {
        switch (this) {
            case PROGRESS:
                return "progress";

            case EMOJI:
                return "emoji";

            default:
                assert_not_reached();
        }
    }
}

public enum FilterType {
    TODAY,
    INBOX,
    SCHEDULED,
    PINBOARD;

    public string to_string () {
        switch (this) {
            case TODAY:
                return "today";

            case INBOX:
                return "inbox";

            case SCHEDULED:
                return "scheduled";

            case PINBOARD:
                return "pinboard";

            default:
                assert_not_reached();
        }
    }
}

public enum BackendType {
    NONE = 0,
    LOCAL = 1,
    TODOIST = 2,
    CALDAV = 3;
}

public enum PaneType {
    FILTER,
    FAVORITE,
    PROJECT,
    LABEL,
    TASKLIST
}

public enum ContainerType {
    LISTBOX,
    FLOWBOX
}

public enum LoadingButtonType {
    LABEL,
    ICON
}

public class Util : GLib.Object {
    public Gtk.TargetEntry[] MAGICBUTTON_TARGET_ENTRIES = {
        {"MAGICBUTTON", Gtk.TargetFlags.SAME_APP, 0}
    };

    public Gtk.TargetEntry[] ITEMROW_TARGET_ENTRIES = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

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
            colors.set ("red", new Objects.Color (31, _("Red"), "#db4035"));
            colors.set ("orange", new Objects.Color (32, _("Orange"), "#ff9933"));
            colors.set ("yellow", new Objects.Color (33, _("Olive Green"), "#fad000"));
            colors.set ("olive_green", new Objects.Color (34, _("Yellow"), "#afb83b"));
            colors.set ("lime_green", new Objects.Color (35, _("Lime Green"), "#7ecc49"));
            colors.set ("green", new Objects.Color (36, _("Green"), "#299438"));
            colors.set ("mint_green", new Objects.Color (37, _("Mint Green"), "#6accbc"));
            colors.set ("teal", new Objects.Color (38, _("Teal"), "#158fad"));
            colors.set ("sky_blue", new Objects.Color (39, _("Sky Blue"), "#14aaf5"));
            colors.set ("light_blue", new Objects.Color (40, _("Light Blue"), "#96c3eb"));
            colors.set ("blue", new Objects.Color (41, _("Blue"), "#4073ff"));
            colors.set ("grape", new Objects.Color (42, _("Grape"), "#884dff"));
            colors.set ("violet", new Objects.Color (43, _("Violet"), "#af38eb"));
            colors.set ("lavender", new Objects.Color (44, _("Lavander"), "#eb96eb"));
            colors.set ("magenta", new Objects.Color (45, _("Magenta"), "#e05194"));
            colors.set ("salmon", new Objects.Color (46, _("Salmon"), "#ff8d85"));
            colors.set ("charcoal", new Objects.Color (47, _("Charcoal"), "#808080"));
            colors.set ("grey", new Objects.Color (48, _("Grey"), "#b8b8b8"));
            colors.set ("taupe", new Objects.Color (49, _("Taupe"), "#ccac93"));
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

            try {
                var style_provider = new Gtk.CssProvider ();
                style_provider.load_from_data (style, style.length);

                providers[color] = style_provider;
            } catch (Error e) {
                critical ("Unable to set color: %s", e.message);
            }
        }

        unowned Gtk.StyleContext style_context = widget.get_style_context ();
        style_context.add_provider (providers[color], Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    public void set_widget_priority (int priority, Gtk.Widget widget) {
        if (providers == null) {
            providers = new Gee.HashMap<string, Gtk.CssProvider> ();
        }

        if (!providers.has_key (priority.to_string ())) {
            string style = """
                @define-color colorPriority %s;
                @define-color colorPriorityBackground %s;
            """.printf (get_priority_color (priority), get_priority_background (priority));

            try {
                var style_provider = new Gtk.CssProvider ();
                style_provider.load_from_data (style, style.length);

                providers[priority.to_string ()] = style_provider;
            } catch (Error e) {
                critical ("Unable to set color: %s", e.message);
            }
        }

        unowned Gtk.StyleContext style_context = widget.get_style_context ();
        style_context.add_provider (providers[priority.to_string ()], Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    public string get_priority_color (int priority) {
        if (priority == Constants.PRIORITY_1) {
            return "#ff7066";
        } else if (priority == Constants.PRIORITY_2) {
            return "#ff9a14";
        } else if (priority == Constants.PRIORITY_3) {
            return "#5297ff";
        } else {
            return "@item_border_color";
        }
    }

    public string get_priority_background (int priority) {
        if (priority == Constants.PRIORITY_1) {
            return "rgba (255, 112, 102, 0.1)";
        } else if (priority == Constants.PRIORITY_2) {
            return "rgba (255, 154, 20, 0.1)";
        } else if (priority == Constants.PRIORITY_3) {
            return "rgba (82, 151, 255, 0.1)";
        } else {
            return "transparent";
        }
    }

    public void download_profile_image (string id, string avatar_url) {
        if (id == null) {
            return;
        }
        
        var file_path = File.new_for_path (get_todoist_avatar_path ());
        var file_from_uri = File.new_for_uri (avatar_url);
        if (!file_path.query_exists ()) {
            MainLoop loop = new MainLoop ();

            file_from_uri.copy_async.begin (file_path, 0, Priority.DEFAULT, null, (current_num_bytes, total_num_bytes) => { // vala-lint=line-length
            }, (obj, res) => {
                try {
                    if (file_from_uri.copy_async.end (res)) {
                        Planner.event_bus.avatar_downloaded ();
                    }
                } catch (Error e) {
                    debug ("Error: %s\n", e.message);
                }

                loop.quit ();
            });

            loop.run ();
        }
    }

    public string get_todoist_avatar_path () {
        return GLib.Path.build_filename (
            Environment.get_user_data_dir () + "/com.github.alainm23.planner",
            Planner.settings.get_string ("todoist-user-image-id") + ".jpg"
        );
    }

    public int64 generate_id (int len=10) {
        string allowed_characters = "0123456789";

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

    public string get_theme_name () {
        string returned = "";
        int appearance_mode = Planner.settings.get_enum ("appearance");
        
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

    public void update_theme () {
        string _css = """
            @define-color base_color %s;
            @define-color bg_color %s;
            @define-color item_bg_color %s;
            @define-color item_border_color %s;
            @define-color picker_bg %s;
            @define-color picker_content_bg %s;
        """;

        int appearance_mode = Planner.settings.get_enum ("appearance");
        var provider = new Gtk.CssProvider ();

        try {
            string base_color = "";
            string bg_color = "";
            string item_bg_color = "";
            string item_border_color = "";
            string picker_bg = "";
            string picker_content_bg = ""; 

            if (appearance_mode == 0) {
                base_color = "#ffffff";
                bg_color = "@SILVER_100";
                item_bg_color = "@base_color";
                item_border_color = "@menu_separator";
                picker_bg = "@bg_color";
                picker_content_bg = "@base_color";
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;
            } else if (appearance_mode == 1) {
                base_color = "#151515";
                bg_color = "#222222";
                item_bg_color = "@bg_color";
                item_border_color = "#333333";
                picker_bg = "@base_color";
                picker_content_bg = "@bg_color";
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
            } else if (appearance_mode == 2) {
                base_color = "#0B0B11";
                bg_color = "#15151B";
                item_bg_color = "@bg_color";
                item_border_color = "#333333";
                picker_bg = "@base_color";
                picker_content_bg = "@bg_color";
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
            }

            var CSS = _css.printf (
                base_color,
                bg_color,
                item_bg_color,
                item_border_color,
                picker_bg,
                picker_content_bg
            );

            provider.load_from_data (CSS, CSS.length);

            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (), provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );

            Planner.event_bus.theme_changed ();
        } catch (GLib.Error e) {
            return;
        }
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
        if (date.length == 10) { // YYYY-MM-DD 
            var _date = date.split ("-");

            datetime = new GLib.DateTime.local (
                int.parse (_date [0]),
                int.parse (_date [1]),
                int.parse (_date [2]),
                0,
                0,
                0
            );
        } else if (date.length == 19) { // YYYY-MM-DDTHH:MM:SS
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
        } else { // YYYY-MM-DDTHH:MM:SSZ
            var _date = date.split ("T") [0].split ("-");
            // var _time = date.split ("T") [1].split (":");

            datetime = new GLib.DateTime.local (
                int.parse (_date [0]),
                int.parse (_date [1]),
                int.parse (_date [2]),
                0,
                0,
                0
                // int.parse (_time [0]),
                // int.parse (_time [1]),
                // int.parse (_time [2].substring (0, 2))
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
            return _("Yesterday");
        } else {
            returned = get_default_date_format_from_date (datetime);
        }

        if (has_time (datetime)) {
            returned += " " + datetime.format (get_default_time_format ());
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

    public void item_added (Layouts.ItemRow row) {
        bool insert = row.project_id != row.item.project.id || row.section_id != row.item.section_id;

        if (row.item.section_id != Constants.INACTIVE) {
            Planner.database.get_section (row.item.section_id)
                .add_item_if_not_exists (row.item, insert);
        } else {
            Planner.database.get_project (row.item.project_id)
                .add_item_if_not_exists (row.item, insert);
        }
        
        if (!insert) {
            Planner.event_bus.update_inserted_item_map (row);
            /// items [row.item.id_string] = row;
            row.update_inserted_item ();
        } else {
            row.hide_destroy ();
        }
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
        return date.format (Granite.DateTime.get_default_date_format (
            false,
            true,
            date.get_year () != new GLib.DateTime.now_local ().get_year ()
        ));
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

    public string get_short_name (string name, int size = Constants.SHORT_NAME_SIZE) {
        string returned = name;
        
        if (name.length > size) {
            returned = name.substring (0, size) + "…";
        }

        return returned;
    }

    public bool is_clock_format_12h () {
        return Planner.settings.get_string ("clock-format").contains ("12h");
    }
}
