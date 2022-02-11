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

public enum ObjectType {
    PROJECT,
    SECTION,
    ITEM,
    LABEL;

    public string get_header () {
        switch (this) {
            case PROJECT:
                return _("Projects");

            case SECTION:
                return _("Setions");

            case ITEM:
                return _("Items");

            case LABEL:
                return _("Labels");

            default:
                assert_not_reached();
        }
    }
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
    
    public void open_quick_find () {
        var dialog = new Dialogs.QuickFind.QuickFind ();

        int window_x, window_y;
        int window_width, width_height;

        Planner.settings.get ("window-position", "(ii)", out window_x, out window_y);
        Planner.settings.get ("window-size", "(ii)", out window_width, out width_height);

        dialog.move (window_x + ((window_width - dialog.width_request) / 2), window_y + 48);
        dialog.show_all ();
    }

    public void clear_database (string title, string message) {
        var message_dialog = new Dialogs.MessageDialog (
            title,
            message,
            "dialog-warning"
        ) {
            modal = true
        };
        
        message_dialog.add_default_action (_("Cancel"), Gtk.ResponseType.CANCEL);
        message_dialog.add_default_action (_("Reset all"), Gtk.ResponseType.ACCEPT, Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        message_dialog.show_all ();

        message_dialog.default_action.connect ((response) => {
            if (response == Gtk.ResponseType.ACCEPT) {
                clear_database_query ();
                Planner.instance.main_window.destroy ();
            } else {
                message_dialog.hide_destroy ();
            }
        });
    }

    public void clear_database_query () {
        string db_path = Environment.get_user_data_dir () + "/com.github.alainm23.planner/database.db";
        File db_file = File.new_for_path (db_path);

        if (db_file.query_exists ()) {
            try {
                db_file.delete ();
            } catch (Error err) {
                warning (err.message);
            }
        }
    }

    public void reset_settings () {
        var schema_source = GLib.SettingsSchemaSource.get_default ();
        SettingsSchema schema = schema_source.lookup ("com.github.alainm23.planner", true);

        foreach (string key in schema.list_keys ()) {
            Planner.settings.reset (key);
        }
    }

    public void open_migrate_message () {
        var message_dialog = new Dialogs.MessageDialog (
            _("Welcome to Planner 3"),
            _("We have detected that you have a Planner 2 configuration started, currently the v3 database is not compatible with v2, if you wish you can download a backup in JSON format and migrate your data manually, or you can start with v3 with a new configuration."),
            "dialog-warning"
        ) {
            modal = true
        };
        
        message_dialog.add_default_action (_("Create backup"), Gtk.ResponseType.ACCEPT, Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        message_dialog.add_default_action (_("Starting over"), Gtk.ResponseType.CANCEL);

        message_dialog.show_all ();

        message_dialog.default_action.connect ((response) => {
            if (response == Gtk.ResponseType.CANCEL) {
                clear_database_query ();
                Planner.settings.set_string ("version", Constants.VERSION);
            } else {
                export_v2_database ();
            }
        });
    }

    private void export_v2_database () {
        Sqlite.Database db;
        string db_path = Environment.get_user_data_dir () + "/com.github.alainm23.planner/database.db";

        Sqlite.Database.open (db_path, out db);
        save_file_as (db);
    }

    private Gee.ArrayList<Objects.ProjectV2> get_all_projects (Sqlite.Database db) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, area_id, name, note, due_date, color, is_todoist, inbox_project, team_inbox,
                item_order, is_deleted, is_archived, is_favorite, is_sync, shared, is_kanban, show_completed,
                sort_order, parent_id, collapsed
            FROM Projects ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.ProjectV2?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var p = new Objects.ProjectV2 ();

            p.id = stmt.column_int64 (0);
            p.area_id = stmt.column_int64 (1);
            p.name = stmt.column_text (2);
            p.note = stmt.column_text (3);
            p.due_date = stmt.column_text (4);
            p.color = stmt.column_int (5);
            p.is_todoist = stmt.column_int (6);
            p.inbox_project = stmt.column_int (7);
            p.team_inbox = stmt.column_int (8);
            p.item_order = stmt.column_int (9);
            p.is_deleted = stmt.column_int (10);
            p.is_archived = stmt.column_int (11);
            p.is_favorite = stmt.column_int (12);
            p.is_sync = stmt.column_int (13);
            p.shared = stmt.column_int (14);
            p.is_kanban = stmt.column_int (15);
            p.show_completed = stmt.column_int (16);
            p.sort_order = stmt.column_int (17);
            p.parent_id = stmt.column_int64 (18);
            p.collapsed = stmt.column_int (19);

            all.add (p);
        }

        stmt.reset ();
        return all;
    }

    private Gee.ArrayList<Objects.SectionV2> get_all_sections (Sqlite.Database db) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, name, project_id, item_order, collapsed, sync_id, is_deleted, is_archived,
                date_archived, date_added, is_todoist, note
            FROM Sections ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.SectionV2> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var s = new Objects.SectionV2 ();

            s.id = stmt.column_int64 (0);
            s.name = stmt.column_text (1);
            s.project_id = stmt.column_int64 (2);
            s.item_order = stmt.column_int (3);
            s.collapsed = stmt.column_int (4);
            s.sync_id = stmt.column_int64 (5);
            s.is_deleted = stmt.column_int (6);
            s.is_archived = stmt.column_int (7);
            s.date_archived = stmt.column_text (8);
            s.date_added = stmt.column_text (9);
            s.is_todoist = stmt.column_int (10);
            s.note = stmt.column_text (11);

            all.add (s);
        }

        stmt.reset ();
        return all;
    }

    private Gee.ArrayList<Objects.ItemV2> get_all_items (Sqlite.Database db) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, project_id, section_id, user_id, assigned_by_uid, responsible_uid,
                sync_id, parent_id, priority, item_order, checked, is_deleted, content, note,
                due_date, due_timezone, due_string, due_lang, due_is_recurring, date_added,
                date_completed, date_updated, is_todoist, day_order, collapsed
            FROM Items ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.ItemV2> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var i = new Objects.ItemV2 ();

            i.id = stmt.column_int64 (0);
            i.project_id = stmt.column_int64 (1);
            i.section_id = stmt.column_int64 (2);
            i.user_id = stmt.column_int64 (3);
            i.assigned_by_uid = stmt.column_int64 (4);
            i.responsible_uid = stmt.column_int64 (5);
            i.sync_id = stmt.column_int64 (6);
            i.parent_id = stmt.column_int64 (7);
            i.priority = stmt.column_int (8);
            i.item_order = stmt.column_int (9);
            i.checked = stmt.column_int (10);
            i.is_deleted = stmt.column_int (11);
            i.content = stmt.column_text (12);
            i.note = stmt.column_text (13);
            i.due_date = stmt.column_text (14);
            i.due_timezone = stmt.column_text (15);
            i.due_string = stmt.column_text (16);
            i.due_lang = stmt.column_text (17);
            i.due_is_recurring = stmt.column_int (18);
            i.date_added = stmt.column_text (19);
            i.date_completed = stmt.column_text (20);
            i.date_updated = stmt.column_text (21);
            i.is_todoist = stmt.column_int (22);
            i.day_order = stmt.column_int (23);
            i.collapsed = stmt.column_int (24);

            all.add (i);
        }

        stmt.reset ();
        return all;
    }

    public bool export_to_json (string path, Sqlite.Database db) {        
        Json.Builder builder = new Json.Builder ();
        bool returned = false;

        builder.begin_object ();
            // Projects
            builder.set_member_name ("projects");
            builder.begin_array ();
                foreach (var project in get_all_projects (db)) {
                    builder.begin_object ();
                    builder.set_member_name ("parent_id");
                    builder.add_int_value (project.parent_id);

                    builder.set_member_name ("id");
                    builder.add_int_value (project.id);

                    builder.set_member_name ("name");
                    builder.add_string_value (project.name);

                    builder.set_member_name ("note");
                    builder.add_string_value (project.note);

                    builder.set_member_name ("due_date");
                    builder.add_string_value (project.due_date);

                    builder.set_member_name ("color");
                    builder.add_int_value (project.color);

                    builder.set_member_name ("is_todoist");
                    builder.add_int_value (project.is_todoist);

                    builder.set_member_name ("inbox_project");
                    builder.add_int_value (project.inbox_project);

                    builder.set_member_name ("team_inbox");
                    builder.add_int_value (project.team_inbox);

                    builder.set_member_name ("item_order");
                    builder.add_int_value (project.item_order);

                    builder.set_member_name ("is_deleted");
                    builder.add_int_value (project.is_deleted);

                    builder.set_member_name ("is_archived");
                    builder.add_int_value (project.is_archived);

                    builder.set_member_name ("is_favorite");
                    builder.add_int_value (project.is_favorite);

                    builder.set_member_name ("is_sync");
                    builder.add_int_value (project.is_sync);

                    builder.set_member_name ("shared");
                    builder.add_int_value (project.shared);

                    builder.set_member_name ("is_kanban");
                    builder.add_int_value (project.is_kanban);

                    builder.set_member_name ("show_completed");
                    builder.add_int_value (project.show_completed);

                    builder.set_member_name ("sort_order");
                    builder.add_int_value (project.sort_order);
                    builder.end_object ();
                }
            builder.end_array ();

            // Sections
            builder.set_member_name ("sections");
            builder.begin_array ();
                foreach (var section in get_all_sections (db)) {
                    builder.begin_object ();
                    builder.set_member_name ("id");
                    builder.add_int_value (section.id);

                    builder.set_member_name ("project_id");
                    builder.add_int_value (section.project_id);

                    builder.set_member_name ("sync_id");
                    builder.add_int_value (section.sync_id);

                    builder.set_member_name ("name");
                    builder.add_string_value (section.name);

                    builder.set_member_name ("note");
                    builder.add_string_value (section.note);

                    builder.set_member_name ("item_order");
                    builder.add_int_value (section.item_order);

                    builder.set_member_name ("collapsed");
                    builder.add_int_value (section.collapsed);

                    builder.set_member_name ("is_todoist");
                    builder.add_int_value (section.is_todoist);

                    builder.set_member_name ("is_deleted");
                    builder.add_int_value (section.is_deleted);

                    builder.set_member_name ("is_archived");
                    builder.add_int_value (section.is_archived);

                    builder.set_member_name ("date_archived");
                    builder.add_string_value (section.date_archived);

                    builder.set_member_name ("date_added");
                    builder.add_string_value (section.date_added);
                    builder.end_object ();
                }
            builder.end_array ();

            // Items
            builder.set_member_name ("items");
            builder.begin_array ();
                foreach (var item in get_all_items (db)) {
                    builder.begin_object ();
                    builder.set_member_name ("id");
                    builder.add_int_value (item.id);

                    builder.set_member_name ("project_id");
                    builder.add_int_value (item.project_id);

                    builder.set_member_name ("section_id");
                    builder.add_int_value (item.section_id);

                    builder.set_member_name ("user_id");
                    builder.add_int_value (item.user_id);

                    builder.set_member_name ("assigned_by_uid");
                    builder.add_int_value (item.assigned_by_uid);

                    builder.set_member_name ("responsible_uid");
                    builder.add_int_value (item.responsible_uid);

                    builder.set_member_name ("sync_id");
                    builder.add_int_value (item.sync_id);

                    builder.set_member_name ("parent_id");
                    builder.add_int_value (item.parent_id);

                    builder.set_member_name ("priority");
                    builder.add_int_value (item.priority);

                    builder.set_member_name ("item_order");
                    builder.add_int_value (item.item_order);

                    builder.set_member_name ("day_order");
                    builder.add_int_value (item.day_order);

                    builder.set_member_name ("checked");
                    builder.add_int_value (item.checked);

                    builder.set_member_name ("is_deleted");
                    builder.add_int_value (item.is_deleted);

                    builder.set_member_name ("is_todoist");
                    builder.add_int_value (item.is_todoist);

                    builder.set_member_name ("content");
                    builder.add_string_value (item.content);
                    
                    builder.set_member_name ("note");
                    builder.add_string_value (item.note);

                    builder.set_member_name ("due_date");
                    builder.add_string_value (item.due_date);

                    builder.set_member_name ("due_timezone");
                    builder.add_string_value (item.due_timezone);

                    builder.set_member_name ("due_string");
                    builder.add_string_value (item.due_string);

                    builder.set_member_name ("due_lang");
                    builder.add_string_value (item.due_lang);

                    builder.set_member_name ("due_is_recurring");
                    builder.add_int_value (item.due_is_recurring);

                    builder.set_member_name ("date_added");
                    builder.add_string_value (item.date_added);

                    builder.set_member_name ("date_completed");
                    builder.add_string_value (item.date_completed);

                    builder.set_member_name ("date_updated");
                    builder.add_string_value (item.date_updated);
                    
                    builder.end_object ();
                }
            builder.end_array ();
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        generator.pretty = true;

        Json.Node root = builder.get_root ();
        generator.set_root (root);

        try {
            returned = generator.to_file (path);
        } catch (Error e) {
            print ("Error: %s\n", e.message);
        }

        return returned;
    }

    public void save_file_as (Sqlite.Database db) {
        var dialog = new Gtk.FileChooserNative (
            _("Save backup file"), Planner.instance.main_window,
            Gtk.FileChooserAction.SAVE,
            _("Save"),
            _("Cancel"));

        dialog.set_do_overwrite_confirmation (true);
        add_filters (dialog);
        dialog.set_modal (true);
        
        if (dialog.run () == Gtk.ResponseType.ACCEPT) {
            var file = dialog.get_file ();

            if (!file.get_basename ().down ().has_suffix (".json")) {
                if (export_to_json (file.get_path () + ".json", db)) {
                    clear_database_query ();
                    Planner.settings.set_string ("version", Constants.VERSION);
                }
            }
        }

        dialog.destroy ();
    }

    private void add_filters (Gtk.FileChooserNative chooser) {
        Gtk.FileFilter filter = new Gtk.FileFilter ();
        filter.add_pattern ("*.json");
        filter.set_filter_name (_("JSON files"));
        chooser.add_filter (filter);

        filter = new Gtk.FileFilter ();
        filter.add_pattern ("*");
        filter.set_filter_name (_("All files"));
        chooser.add_filter (filter);
    }
}
