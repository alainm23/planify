public enum FilterType {
    QUICK_SEARCH,
    TODAY,
    INBOX,
    UPCOMING,
    TRASH;

    public string to_string () {
        switch (this) {
            case QUICK_SEARCH:
                return "QUICK_SEARCH";

            case TODAY:
                return "TODAY";

            case INBOX:
                return "INBOX";

            case UPCOMING:
                return "UPCOMING";

            case TRASH:
                return "TRASH";

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
    PROJECT,
    LABEL,
    TASKLIST
}

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

    public Gee.HashMap<int, string> color () {
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

    public string get_todoist_avatar_path () {
        return GLib.Path.build_filename (
            Environment.get_user_data_dir () + "/com.github.alainm23.planner",
            Planner.settings.get_string ("todoist-user-image-id") + ".jpg"
        );
    }

    public void download_profile_image (string id, string avatar_url) {
        if (id != null) {
            var file_path = File.new_for_path (get_todoist_avatar_path ());
            var file_from_uri = File.new_for_uri (avatar_url);
            if (file_path.query_exists () == false) {
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
}
