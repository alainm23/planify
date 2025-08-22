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
            colors.set ("lavender", new Objects.Color (44, _("Lavender"), "#eb96eb"));
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
        if (get_colors ().has_key (key)) {
            return get_colors ().get (key).hexadecimal;
        }

        return key;
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

        var collection = Services.Store.instance ().get_collection_by_type (base_object);
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
        return text.replace ("&", "%26").replace ("#", "%23");
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

        var color_scheme_settings = ColorSchemeSettings.Settings.get_default ();

        if (system_appearance) {
            dark_mode = color_scheme_settings.prefers_color_scheme == ColorSchemeSettings.Settings.ColorScheme.DARK;
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
            sidebar_bg_color = "#f2f2f2";
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

    public void update_font_scale () {
        string _css = """
            popover,
            window {
                font-size: %s%;
            }
        """;

        var provider = new Gtk.CssProvider ();

        try {
            string scale = (100 * Services.Settings.get_default ().get_double ("font-scale")).to_string ();
            var css = _css.printf (scale);

            provider.load_from_string (css);
            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (), provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } catch (GLib.Error e) {
            debug (e.message);
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


    public string escape_text (string text) {
        return GLib.Markup.escape_text (text, text.length);
    }

    private Gtk.MediaFile soud_medida = null;
    public void play_audio () {
        if (soud_medida == null) {
            soud_medida = Gtk.MediaFile.for_resource ("/io/github/alainm23/planify/success.ogg");
        }
        
        soud_medida.play ();
    }    

    public bool is_input_valid (Gtk.Entry entry) {
        return entry.get_text_length () > 0;
    }

    public bool is_text_valid (string text) {
        return text.length > 0;
    }

    public string get_short_name (string name, int size = Constants.SHORT_NAME_SIZE) {
        string returned = name;
        
        int char_count = name.char_count ();
        if (char_count > size) {
            returned = name.substring (0, name.index_of_nth_char (size)) + "…";
        }

        return returned;
    }

    public void clear_database (string title, string message, Gtk.Window window) {
        var dialog = new Adw.AlertDialog (title, message);

        dialog.body_use_markup = true;
        dialog.add_response ("cancel", _("Cancel"));
        dialog.add_response ("delete", _("Delete All"));
        dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
        dialog.present (window);

        dialog.response.connect ((response) => {
            if (response == "delete") {
                Services.Database.get_default ().clear_database ();
                Services.Settings.get_default ().reset_settings ();
                show_alert_destroy (window);
            }
        });
    }

    public void show_alert_destroy (Gtk.Window window) {
        var dialog = new Adw.AlertDialog (null, _("Process completed, you need to start Planify again."));

        dialog.add_response ("ok", _("Ok"));
        dialog.present (window);

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
            case 4:
                return FilterType.PINBOARD;
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

    public List<Gtk.FlowBoxChild> get_flowbox_children (Gtk.FlowBox list) {
        List<Gtk.FlowBoxChild> response = new List<Gtk.FlowBoxChild> ();

        Gtk.FlowBoxChild item_row = null;
        var row_index = 0;

        do {
            item_row = list.get_child_at_index (row_index);

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

    public string get_priority_keywords (int priority) {
        if (priority == Constants.PRIORITY_1) {
            return "%s;%s".printf ("p1", _("high"));
        } else if (priority == Constants.PRIORITY_2) {
            return "%s;%s".printf ("p2", _("medium"));
        } else if (priority == Constants.PRIORITY_3) {
            return "%s;%s".printf ("p3", _("low"));
        } else if (priority == Constants.PRIORITY_4) {
            return "%s;%s".printf ("p4", _("none"));
        } else {
            return "";
        }
    }

    public Gtk.Image get_priority_icon (int priority) {
        if (priority == Constants.PRIORITY_1) {
            return new Gtk.Image.from_icon_name ("flag-outline-thick-symbolic") {
                css_classes = { "priority-1-icon" },
                pixel_size = 16
            };
        } else if (priority == Constants.PRIORITY_2) {
            return new Gtk.Image.from_icon_name ("flag-outline-thick-symbolic") {
                css_classes = { "priority-2-icon" },
                pixel_size = 16
            };
        } else if (priority == Constants.PRIORITY_3) {
            return new Gtk.Image.from_icon_name ("flag-outline-thick-symbolic") {
                css_classes = { "priority-3-icon" },
                pixel_size = 16
            };
        } else if (priority == Constants.PRIORITY_4) {
            return new Gtk.Image.from_icon_name ("flag-outline-thick-symbolic") {
                pixel_size = 16
            };
        } else {
            return new Gtk.Image.from_icon_name ("flag-outline-thick-symbolic") {
                pixel_size = 16
            };
        }
    }

    public string get_priority_color (int priority) {
        if (priority == Constants.PRIORITY_1) {
            return "#ff7066";
        } else if (priority == Constants.PRIORITY_2) {
            return "#ff9914";
        } else if (priority == Constants.PRIORITY_3) {
            return "#5297ff";
        } else {
            return "@text_color";
        }
    }

    private Gee.HashMap<string, Objects.Filters.Priority> priority_views;
    public Objects.Filters.Priority get_priority_filter (string view_id) {
        if (priority_views == null) {
            priority_views = new Gee.HashMap<string, Objects.Filters.Priority> ();
        }

        if (priority_views.has_key (view_id)) {
            return priority_views[view_id];
        } else {
            int priority = int.parse (view_id.split ("-")[1]);
            priority_views[view_id] = new Objects.Filters.Priority (priority);
            return priority_views[view_id];
        }
    }

    public Objects.Source create_local_source () {
        Objects.Source local_source = new Objects.Source ();
        local_source.id = SourceType.LOCAL.to_string ();
        local_source.source_type = SourceType.LOCAL;
        local_source.display_name = _("On This Computer");
        Services.Store.instance ().insert_source (local_source);
        return local_source;
    }

    public Objects.Project create_inbox_project () {
        Objects.Project inbox_project = new Objects.Project ();
        inbox_project.source_id = SourceType.LOCAL.to_string ();
        inbox_project.id = Util.get_default ().generate_id (inbox_project);
        inbox_project.name = _("Inbox");
        inbox_project.inbox_project = true;
        inbox_project.color = "blue";

        Services.Store.instance ().insert_project (inbox_project);
        Services.Settings.get_default ().settings.set_string ("local-inbox-project-id", inbox_project.id);

        return inbox_project;
    }

    public void create_tutorial_project () {
        Objects.Project project = new Objects.Project ();
        project.id = Util.get_default ().generate_id (project);
        project.source_id = SourceType.LOCAL.to_string ();
        project.icon_style = ProjectIconStyle.EMOJI;
        project.emoji = "🚀️";
        project.name = _("Meet Planify");
        project.color = "blue";
        project.show_completed = true;
        project.description = _("This project shows you everything you need to know to hit the ground running. Don’t hesitate to play around in it – you can always create a new one from settings.");

        Services.Store.instance ().insert_project (project);

        var item_01 = new Objects.Item ();
        item_01.id = Util.get_default ().generate_id (item_01);
        item_01.project_id = project.id;
        item_01.content = _("Tap this to-do");
        item_01.description = _("You're looking at a to-do! Complete it by tapping the checkbox on the left. Completed to-dos are collected at the bottom of your project.");

        var item_02 = new Objects.Item ();
        item_02.id = Util.get_default ().generate_id (item_02);
        item_02.project_id = project.id;
        item_02.content = _("Create a new to-do");
        item_02.description = _("Now it's your turn, tap the '+' button at the bottom of your project, enter any pending and tap the blue 'Save' button.");

        var item_03 = new Objects.Item ();
        item_03.id = Util.get_default ().generate_id (item_03);
        item_03.project_id = project.id;
        item_03.content = _("Plan this to-do by today or later");
        item_03.description = _("Tap the calendar button at the bottom to decide when to do this to-do.");

        var item_04 = new Objects.Item ();
        item_04.id = Util.get_default ().generate_id (item_04);
        item_04.project_id = project.id;
        item_04.content = _("Reorder yours to-dos");
        item_04.description = _("To reorder your list, tap and hold a to-do, then drag it to where it should go.");

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
        item_02_01.description = _("You can display your system's calendar events in Planify. Go to 'Preferences' 🡒 General 🡒 Calendar Events to turn it on.");

        var item_02_02 = new Objects.Item ();
        item_02_02.id = Util.get_default ().generate_id (item_02_02);
        item_02_02.project_id = project.id;
        item_02_02.section_id = section_01.id;
        item_02_02.content = _("Enable synchronization with third-party service.");
        item_02_02.description = _("Planify not only creates tasks locally, it can also synchronize your Todoist account. Go to 'Preferences' 🡒 'Accounts'.");

        section_01.add_item_if_not_exists (item_02_01);
        section_01.add_item_if_not_exists (item_02_02);

        var section_02 = new Objects.Section ();
        section_02.id = Util.get_default ().generate_id (section_01);
        section_02.project_id = project.id;
        section_02.name = _("Boost your productivity");

        project.add_section_if_not_exists (section_02);

        var item_03_01 = new Objects.Item ();
        item_03_01.id = Util.get_default ().generate_id (item_03_01);
        item_03_01.project_id = project.id;
        item_03_01.section_id = section_02.id;
        item_03_01.content = _("Drag the plus button!");
        item_03_01.description = _("That blue button you see at the bottom of each screen is more powerful than it looks: it's made to move! Drag it up to create a task wherever you want.");

        var item_03_02 = new Objects.Item ();
        item_03_02.id = Util.get_default ().generate_id (item_03_02);
        item_03_02.project_id = project.id;
        item_03_02.section_id = section_02.id;
        item_03_02.content = _("Tag your to-dos!");
        item_03_02.description = _("Tags allow you to improve your workflow in Planify. To add a Tag click on the tag button at the bottom.");

        var item_03_03 = new Objects.Item ();
        item_03_03.id = Util.get_default ().generate_id (item_03_03);
        item_03_03.project_id = project.id;
        item_03_03.section_id = section_02.id;
        item_03_03.content = _("Set timely reminders!");
        item_03_03.description = _("You want Planify to send you a notification to remind you of an important event or something special. Tap the bell button below to add a reminder.");
        
        section_02.add_item_if_not_exists (item_03_01);
        section_02.add_item_if_not_exists (item_03_02);
        section_02.add_item_if_not_exists (item_03_03);
    }

    public void create_default_labels () {
        var label_01 = new Objects.Label ();
        label_01.id = Util.get_default ().generate_id (label_01);
        label_01.source_id = SourceType.LOCAL.to_string ();
        label_01.name = _("💼️Work");
        label_01.color = "taupe";

        var label_02 = new Objects.Label ();
        label_02.id = Util.get_default ().generate_id (label_02);
        label_02.source_id = SourceType.LOCAL.to_string ();
        label_02.name = _("🎒️School");
        label_02.color = "berry_red";

        var label_03 = new Objects.Label ();
        label_03.id = Util.get_default ().generate_id (label_03);
        label_03.source_id = SourceType.LOCAL.to_string ();
        label_03.name = _("👉️Delegated");
        label_03.color = "yellow";

        var label_04 = new Objects.Label ();
        label_04.id = Util.get_default ().generate_id (label_04);
        label_04.source_id = SourceType.LOCAL.to_string ();
        label_04.name = _("🏡️Home");
        label_04.color = "lime_green";

        var label_05 = new Objects.Label ();
        label_05.id = Util.get_default ().generate_id (label_05);
        label_05.source_id = SourceType.LOCAL.to_string ();
        label_05.name = _("🏃‍♀️️Follow Up");
        label_05.color = "grey";

        Services.Store.instance ().insert_label (label_01);
        Services.Store.instance ().insert_label (label_02);
        Services.Store.instance ().insert_label (label_03);
        Services.Store.instance ().insert_label (label_04);
        Services.Store.instance ().insert_label (label_05);
    }

    public string markup_accel_tooltip (string description, string accel) {
        return "%s\n%s".printf (description, """<span weight="600" size="smaller" alpha="75%">%s</span>""".printf (accel));
    }

    public string markup_accels_tooltip (string description, string[] accels) {
        string result = "%s\n".printf (description);

        for (int index = 0; index < accels.length; index++) {
            string accel = """<span weight="600" size="smaller" alpha="75%">%s</span>""".printf (accels[index]);

            if (index < accels.length - 1) {
                result += accel + ", ";
            } else {
                result += accel;
            }
        }

        return result;
    }

    /*
    *   XML adn CakDAV Util
    */

    public static string get_task_id_from_url (GXml.DomElement element) {
        GXml.DomElement href = element.get_elements_by_tag_name ("d:href").get_element (0);
        string[] parts = href.text_content.split ("/");
        return parts[parts.length - 1];
    }

    public static string get_task_uid (GXml.DomElement element) {
        GXml.DomElement propstat = element.get_elements_by_tag_name ("d:propstat").get_element (0);
        GXml.DomElement prop = propstat.get_elements_by_tag_name ("d:prop").get_element (0);
        string data = prop.get_elements_by_tag_name ("cal:calendar-data").get_element (0).text_content;

        ICal.Component ical = new ICal.Component.from_string (data);
        return ical.get_uid ();
    }

    public static string get_related_to_uid (GXml.DomElement element) {
        GXml.DomElement propstat = element.get_elements_by_tag_name ("d:propstat").get_element (0);
        GXml.DomElement prop = propstat.get_elements_by_tag_name ("d:prop").get_element (0);
        string data = prop.get_elements_by_tag_name ("cal:calendar-data").get_element (0).text_content;
        return Util.find_string_value ("RELATED-TO", data);
    }

    public static string find_string_value (string key, string data) {
        GLib.Regex? regex = null;
        GLib.MatchInfo match;

        try {
            regex = new GLib.Regex ("%s:(.*)".printf (key));
        } catch (GLib.RegexError e) {
            critical (e.message);
        }

        if (regex == null) {
            return "";
        }

        if (!regex.match (data.strip (), 0, out match)) {
            return "";
        }

        return match.fetch_all ()[1];
    }

    public static bool find_boolean_value (string key, string data) {
        GLib.Regex? regex = null;
        GLib.MatchInfo match;

        try {
            regex = new GLib.Regex ("%s:(.*)".printf (key));
        } catch (GLib.RegexError e) {
            critical (e.message);
        }

        if (regex == null) {
            return false;
        }

        if (!regex.match (data, 0, out match)) {
            return false;
        }

        return bool.parse (match.fetch_all () [1]);
    }

    public static string generate_extra_data (string ics, string etag, string data) {
        var builder = new Json.Builder ();
        builder.begin_object ();

        builder.set_member_name ("ics");
        builder.add_string_value (ics);

        builder.set_member_name ("etag");
        builder.add_string_value (etag);
        
        builder.set_member_name ("calendar-data");
        builder.add_string_value (data);

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);
        return generator.to_data (null);
    }

    public async void move_backend_type_item (Objects.Item item, Objects.Project target_project, string parent_id = "") {
        var new_item = item.duplicate ();
        new_item.project_id = target_project.id;
        new_item.parent_id = parent_id;

        item.loading = true;
        item.sensitive = false;

        if (target_project.source_type == SourceType.LOCAL) {
            new_item.id = Util.get_default ().generate_id (new_item);
            yield add_final_duplicate_item (new_item, item);
        } else if (target_project.source_type == SourceType.TODOIST) {
            HttpResponse response = yield Services.Todoist.get_default ().add (new_item);
            item.loading = false;

            if (response.status) {
                new_item.id = response.data;
                yield add_final_duplicate_item (new_item, item);
            }
        } else if (target_project.source_type == SourceType.CALDAV) {
            new_item.id = Util.get_default ().generate_id (new_item);
            HttpResponse response = yield Services.CalDAV.Core.get_default ().add_task (new_item);
            item.loading = false;

            if (response.status) {
                yield add_final_duplicate_item (new_item, item);
            }
        }
    }

    public async void add_final_duplicate_item (Objects.Item new_item, Objects.Item item) {
        new_item.project.add_item_if_not_exists (new_item);

        foreach (Objects.Reminder reminder in item.reminders) {
            var _reminder = reminder.duplicate ();
            _reminder.id = Util.get_default ().generate_id (_reminder);
            _reminder.item_id = new_item.id;
            new_item.add_reminder_if_not_exists (_reminder);
        }

        foreach (Objects.Attachment attachment in item.attachments) {
            var _attachment = attachment.duplicate ();
            _attachment.id = Util.get_default ().generate_id ();
            _attachment.item_id = new_item.id;
            new_item.add_attachment_if_not_exists (_attachment);
        }

        foreach (Objects.Item subitem in item.items) {
            yield move_backend_type_item (subitem, new_item.project, new_item.id);
        }

        Services.EventBus.get_default ().send_toast (
            create_toast (_("Task moved to %s".printf (new_item.project.name)))
        );

        item.delete_item ();
    }

    public async void duplicate_item (Objects.Item item, string project_id, string section_id = "", string parent_id = "", bool notify = true) {
        var new_item = item.duplicate ();
        new_item.project_id = project_id;
        new_item.section_id = section_id;
        new_item.parent_id = parent_id;

        item.loading = true;
        item.sensitive = false;

        if (item.project.source_type == SourceType.LOCAL) {
            new_item.id = Util.get_default ().generate_id (new_item);

            item.loading = false;
            item.sensitive = true;

            yield insert_duplicate_item (new_item, item, notify);
        } else if (item.project.source_type == SourceType.TODOIST) {
            HttpResponse response = yield Services.Todoist.get_default ().add (new_item);
            
            item.loading = false;
            item.sensitive = true;

            if (response.status) {
                new_item.id = response.data;
                yield insert_duplicate_item (new_item, item, notify);
            }
        } else if (item.project.source_type == SourceType.CALDAV) {
            new_item.id = Util.get_default ().generate_id (new_item);
            HttpResponse response = yield Services.CalDAV.Core.get_default ().add_task (new_item);
            
            item.loading = false;
            item.sensitive = true;

            if (response.status) {
                yield insert_duplicate_item (new_item, item, notify);
            }
        }
    }

    private async void insert_duplicate_item (Objects.Item new_item, Objects.Item item, bool notify = true) {
        if (new_item.has_parent) {
			new_item.parent.add_item_if_not_exists (new_item);
		} else {
            if (new_item.section_id != "") {
                new_item.section.add_item_if_not_exists (new_item);
            } else {
                new_item.project.add_item_if_not_exists (new_item);
            }
        }

        Services.EventBus.get_default ().update_section_sort_func (new_item.project_id, new_item.section_id, false);

        foreach (Objects.Reminder reminder in item.reminders) {
            var _reminder = reminder.duplicate ();
            _reminder.id = Util.get_default ().generate_id (_reminder);
            _reminder.item_id = new_item.id;
            new_item.add_reminder_if_not_exists (_reminder);
        }

        foreach (Objects.Attachment attachment in item.attachments) {
            var _attachment = attachment.duplicate ();
            _attachment.id = Util.get_default ().generate_id ();
            _attachment.item_id = new_item.id;
            new_item.add_attachment_if_not_exists (_attachment);
        }

        foreach (Objects.Item subitem in item.items) {
            yield duplicate_item (subitem, new_item.project_id, new_item.section_id, new_item.id, notify);
        }

        if (notify) {
            Services.EventBus.get_default ().send_toast (
                Util.get_default ().create_toast (_("Task duplicated"))
            );
        }
    }

    public async void duplicate_section (Objects.Section section, string project_id, bool notify = true) {
        var new_section = section.duplicate ();
        new_section.project_id = project_id;

        section.loading = true;
        section.sensitive = false;

        if (new_section.project.source_type == SourceType.LOCAL) {
            new_section.id = Util.get_default ().generate_id (new_section);
            yield insert_duplicate_section (new_section, section, notify);
        } else if (new_section.project.source_type == SourceType.TODOIST) {
            HttpResponse response = yield Services.Todoist.get_default ().add (new_section);
            if (response.status) {
                new_section.id = response.data;
                yield insert_duplicate_section (new_section, section, notify);
            }
        }
    }

    private async void insert_duplicate_section (Objects.Section new_section, Objects.Section section, bool notify = true) {
        new_section.project.add_section_if_not_exists (new_section);

        foreach (Objects.Item item in section.items) {
            yield duplicate_item (item, new_section.project_id, new_section.id, item.parent_id, false);
        }

        section.loading = false;
        section.sensitive = true;

        if (notify) {
            Services.EventBus.get_default ().send_toast (
                Util.get_default ().create_toast (_("Section duplicated"))
            );
        }
    }

    public async void duplicate_project (Objects.Project project, string parent_id = "") {
        var new_project = project.duplicate ();
        new_project.parent_id = parent_id;

        project.loading = true;

        if (project.source_type == SourceType.LOCAL) {
            new_project.id = Util.get_default ().generate_id (new_project);
            Services.Store.instance ().insert_project (new_project);

            foreach (Objects.Item item in project.items) {
                yield duplicate_item (item, new_project.id, item.section_id, item.parent_id, false);
            }

            foreach (Objects.Section section in project.sections) {
                yield duplicate_section (section, new_project.id, false);
            }

            project.loading = false;

            Services.EventBus.get_default ().send_toast (
                Util.get_default ().create_toast (_("Project duplicated"))
            );
        } else if (project.source_type == SourceType.TODOIST) {            
            Services.Todoist.get_default ().duplicate_project.begin (project, (obj, res) => {
                project.loading = false;
                
                if (Services.Todoist.get_default ().duplicate_project.end (res).status) {
                    Services.Todoist.get_default ().sync.begin (project.source);
                }
            });
        } else if (project.source_type == SourceType.CALDAV) {
            new_project.id = Util.get_default ().generate_id (new_project);
            
            HttpResponse response = yield Services.CalDAV.Core.get_default ().add_tasklist (new_project);

            if (response.status) {
                Services.Store.instance ().insert_project (new_project);
            
                foreach (Objects.Item item in project.items) {
                    yield duplicate_item (item, new_project.id, "", item.parent_id, false);
                }
    
                project.loading = false;
    
                Services.EventBus.get_default ().send_toast (
                    Util.get_default ().create_toast (_("Project duplicated"))
                );
            }
        }
    }

    public string markup_string (string _text) {
        var text = escape_text (_text);

        try {
            Regex mailto_regex = /(?P<mailto>[a-zA-Z0-9\._\%\+\-]+@[a-zA-Z0-9\-\.]+\.[a-zA-Z]+(\S*))/; // vala-lint=space-before-paren
            Regex url_regex = /(?P<url>(http|https)\:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]+(\/\S*))/; // vala-lint=space-before-paren
            Regex url_markdown = new Regex ("\\[([^\\]]+)\\]\\(([^\\)]+)\\)");

            Regex italic_bold_regex = /\*\*\*(.*?)\*\*\*/; // vala-lint=space-before-paren
            Regex bold_regex = /\*\*(.*?)\*\*/; // vala-lint=space-before-paren
            Regex italic_regex = /\*(.*?)\*/; // vala-lint=space-before-paren
            Regex underline_regex = /_(.*?)_/; // vala-lint=space-before-paren

            Regex italic_bold_underline_regex = /\*\*\*_([^*]+)_\*\*\*/; // vala-lint=space-before-paren
            Regex bold_underline_regex = /\*\*_([^*]+)_\*\*/; // vala-lint=space-before-paren
            Regex italic_underline_regex = /\*_(.*?)_\*/; // vala-lint=space-before-paren

            MatchInfo info;

            List<string> emails = new List<string> ();
            if (mailto_regex.match (text, 0, out info)) {
                do {
                    var email = info.fetch_named ("mailto");
                    emails.append (email);
                } while (info.next ());
            }

            Gee.ArrayList<RegexMarkdown> markdown_urls = new Gee.ArrayList<RegexMarkdown> ();
            if (url_markdown.match (text, 0, out info)) {
                do {
                    markdown_urls.add (new RegexMarkdown (info.fetch (0), info.fetch (1), info.fetch (2)));
                } while (info.next ());
            }

            List<string> urls = new List<string> ();
            if (url_regex.match (text, 0, out info)) {
                do {
                    var url = info.fetch_named ("url");

                    if (!url_exists (url, markdown_urls)) {
                        urls.append (url);
                    }
                } while (info.next ());
            }

            Gee.ArrayList<RegexMarkdown> bolds_01 = new Gee.ArrayList<RegexMarkdown> ();
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

            Gee.ArrayList<RegexMarkdown> italic_bold = new Gee.ArrayList<RegexMarkdown> ();
            if (italic_bold_regex.match (text, 0, out info)) {
                do {
                    italic_bold.add (new RegexMarkdown (info.fetch (0), info.fetch (1)));
                } while (info.next ());
            }

            Gee.ArrayList<RegexMarkdown> italic_bold_underline = new Gee.ArrayList<RegexMarkdown> ();
            if (italic_bold_underline_regex.match (text, 0, out info)) {
                do {
                    italic_bold_underline.add (new RegexMarkdown (info.fetch (0), info.fetch (1)));
                } while (info.next ());
            }

            Gee.ArrayList<RegexMarkdown> bold_underline = new Gee.ArrayList<RegexMarkdown> ();
            if (bold_underline_regex.match (text, 0, out info)) {
                do {
                    bold_underline.add (new RegexMarkdown (info.fetch (0), info.fetch (1)));
                } while (info.next ());
            }

            Gee.ArrayList<RegexMarkdown> italic_underline = new Gee.ArrayList<RegexMarkdown> ();
            if (italic_underline_regex.match (text, 0, out info)) {
                do {
                    italic_underline.add (new RegexMarkdown (info.fetch (0), info.fetch (1)));
                } while (info.next ());
            }

            Gee.ArrayList<RegexMarkdown> underlines = new Gee.ArrayList<RegexMarkdown> ();
            if (underline_regex.match (text, 0, out info)) {
                do {
                    underlines.add (new RegexMarkdown (info.fetch (0), info.fetch (1)));
                } while (info.next ());
            }

            string converted = text;

            foreach (RegexMarkdown m in markdown_urls) {
                string markdown_text = m.text;
                string markdown_link = m.extra;

                string urlAsLink = @"<a href=\"$markdown_link\">$markdown_text</a>";
                converted = converted.replace (m.match, urlAsLink);
            }

            urls.foreach ((url) => {
                converted = converted.replace (url, @"<a href=\"$url\">$url</a>");
            });

            emails.foreach ((email) => {
                converted = converted.replace (email, @"<a href=\"mailto:$email\">$email</a>");
            });

            foreach (RegexMarkdown m in italic_bold_underline) {
                converted = converted.replace (m.match, "<i><b><u>" + m.text + "</u></b></i>");
            }

            foreach (RegexMarkdown m in bold_underline) {
                converted = converted.replace (m.match, "<b><u>" + m.text + "</u></b>");
            }

            foreach (RegexMarkdown m in italic_underline) {
                converted = converted.replace (m.match, "<i><u>" + m.text + "</u></i>");
            }

            foreach (RegexMarkdown m in underlines) {
                converted = converted.replace (m.match, "<u>" + m.text + "</u>");
            }

            foreach (RegexMarkdown m in italic_bold) {
                converted = converted.replace (m.match, "<i><b>" + m.text + "</b></i>");
            }

            foreach (RegexMarkdown m in bolds_01) {
                converted = converted.replace (m.match, "<b>" + m.text + "</b>");
            }

            foreach (RegexMarkdown m in italics_01) {
                converted = converted.replace (m.match, "<i>" + m.text + "</i>");
            }

            return converted;
        } catch (GLib.RegexError ex) {
            return text;
        }
    }

    private bool url_exists (string url, Gee.ArrayList<RegexMarkdown> urls) {
        foreach (RegexMarkdown m in urls) {
            if (url == m.extra) {
                return true;
            }
        }

        return false;
    }

    public static int get_reminders_mm_offset () {
        int value = Services.Settings.get_default ().settings.get_enum ("automatic-reminders");
        int return_value = 0;

        switch (value) {
            case 0:
                return_value = 0;
                break;
            case 1:
                return_value = 10;
                break;
            case 2:
                return_value = 30;
                break;
            case 3:
                return_value = 45;
                break;
            case 4:
                return_value = 60;
                break;
            case 5:
                return_value = 120;
                break;
            case 6:
                return_value = 180;
                break;
        }

        return return_value;
    }

    public static string get_reminders_mm_offset_text (int value) {
        string return_value = "";

        switch (value) {
            case 0:
                return_value = _("At due time");
                break;
            case 10:
                return_value = _("10 minutes before");
                break;
            case 30:
                return_value = _("30 minutes before");
                break;
            case 45:
                return_value = _("45 minutes before");
                break;
            case 60:
                return_value = _("1 hour before");
                break;
            case 120:
                return_value = _("2 hours before");
                break;
            case 180:
                return_value = _("3 hours before");
                break;
        }

        return return_value;
    }

    // https://wiki.gnome.org/Projects/Vala/AsyncSamples#Async_sleep_example
    public static async void nap (uint interval, int priority = GLib.Priority.DEFAULT) {
    GLib.Timeout.add (interval, () => {
        nap.callback ();
        return false;
        }, priority);
    yield;
    }
}

public class RegexMarkdown {
    public string match { get; set; }
    public string text { get; set; }
    public string extra { get; set; }
    public RegexMarkdown (string match, string text, string extra = "") {
        this.match = match;
        this.text = text;
        this.extra = extra;
    }
}
