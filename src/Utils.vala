/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Utils : GLib.Object {
    public void create_dir_with_parents (string dir) {
        string path = Environment.get_home_dir () + dir;
        File tmp = File.new_for_path (path);
        if (tmp.query_file_type (0) != FileType.DIRECTORY) {
            GLib.DirUtils.create_with_parents (path, 0775);
        }
    }

    public string convert_invert (string hex) {
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

    public string rgb_to_hex_string (Gdk.RGBA rgba) {
        string s = "#%02x%02x%02x".printf(
            (uint) (rgba.red * 255),
            (uint) (rgba.green * 255),
            (uint) (rgba.blue * 255));
        return s;
    }

    public bool is_label_repeted (Gtk.FlowBox flowbox, int id) {
        foreach (Gtk.Widget element in flowbox.get_children ()) {
            var child = element as Widgets.LabelChild;
            if (child.label.id == id) {
                return true;
            }
        }

        return false;
    }

    public bool is_empty (Gtk.FlowBox flowbox) {
        int l = 0;
        foreach (Gtk.Widget element in flowbox.get_children ()) {
            l = l + 1;
        }

        if (l <= 0) {
            return true;
        } else {
            return false;
        }
    }

    public bool is_listbox_empty (Gtk.ListBox listbox) {
        int l = 0;
        foreach (Gtk.Widget element in listbox.get_children ()) {
            var item = element as Widgets.TaskRow;

            if (item.task.checked == 0) {
                l = l + 1;
            }
        }

        if (l <= 0) {
            return true;
        } else {
            return false;
        }
    }

    public bool is_task_repeted (Gtk.ListBox listbox, int id) {
        foreach (Gtk.Widget element in listbox.get_children ()) {
            var item = element as Widgets.TaskRow;

            if (id == item.task.id) {
                return true;
            }
        }

        return false;
    }

    public bool is_tomorrow (GLib.DateTime date_1) {
        var date_2 = new GLib.DateTime.now_local ().add_days (1);
        return date_1.get_day_of_year () == date_2.get_day_of_year () && date_1.get_year () == date_2.get_year ();
    }

    public bool is_today (GLib.DateTime date_1) {
        var date_2 = new GLib.DateTime.now_local ();
        return date_1.get_day_of_year () == date_2.get_day_of_year () && date_1.get_year () == date_2.get_year ();
    }

    public bool is_before_today (GLib.DateTime date_1) {
        var date_2 = new GLib.DateTime.now_local ();

        if (date_1.compare(date_2) == -1) {
            return true;
        }

        return false;
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

    public bool is_upcoming (GLib.DateTime date) {
        if (is_today (date) && is_before_today (date) == false) {
            return false;
        } else {
            return true;
        }
    }

    public string first_letter_to_up (string text) {
        string l = text.substring (0, 1);
        return l.up () + text.substring (1);
    }

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

    public string get_weather_icon_name (string key) {
        var weather_icon_name = new Gee.HashMap<string, string> ();

        weather_icon_name.set ("01d", "weather-clear-symbolic");
        weather_icon_name.set ("01n", "weather-clear-night-symbolic");
        weather_icon_name.set ("02d", "weather-few-clouds-symbolic");
        weather_icon_name.set ("02n", "weather-few-clouds-night-symbolic");
        weather_icon_name.set ("03d", "weather-overcast-symbolic");
        weather_icon_name.set ("03n", "weather-overcast-symbolic");
        weather_icon_name.set ("04d", "weather-overcast-symbolic");
        weather_icon_name.set ("04n", "weather-overcast-symbolic");
        weather_icon_name.set ("09d", "weather-showers-symbolic");
        weather_icon_name.set ("09n", "weather-showers-symbolic");
        weather_icon_name.set ("10d", "weather-showers-scattered-symbolic");
        weather_icon_name.set ("10n", "weather-showers-scattered-symbolic");
        weather_icon_name.set ("11d", "weather-storm-symbolic");
        weather_icon_name.set ("11n", "weather-storm-symbolic");
        weather_icon_name.set ("13d", "weather-snow-symbolic");
        weather_icon_name.set ("13n", "weather-snow-symbolic");
        weather_icon_name.set ("50d", "weather-fog-symbolic");
        weather_icon_name.set ("50n", "weather-fog-symbolic");

        return weather_icon_name.get (key);
    }

    public string get_default_date_format (string date_string) {
        var now = new GLib.DateTime.now_local ();
        var date = new GLib.DateTime.from_iso8601 (date_string, new GLib.TimeZone.local ());

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

    public string get_relative_default_date_format_from_date (GLib.DateTime date) {
        if (Application.utils.is_today (date)) {
            return _("Today");
        } else if (Application.utils.is_tomorrow (date)) {
            return _("Tomorrow");
        } else {
            return Application.utils.get_default_date_format_from_date (date);
        }
    }


    public string get_theme (int key) {
        var themes = new Gee.HashMap<int, string> ();

        themes.set (1, "#ffe16b");
        themes.set (2, "#3d4248");
        themes.set (3, "#64baff");
        themes.set (4, "#ed5353");
        themes.set (5, "#9bdb4d");
        themes.set (6, "#667885");
        themes.set (7, "#FA0080");

        return themes.get (key);
    }

    public void apply_theme (string hex) {
        string THEME_CLASS = """
            @define-color color_header %s;
            @define-color color_selected %s;
            @define-color color_text %s;
        """;

        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = THEME_CLASS.printf (
                hex,
                hex,
                convert_invert (hex)
            );

            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }

    public GLib.DateTime strip_time (GLib.DateTime datetime) {
        return datetime.add_full (0, 0, 0, -datetime.get_hour (), -datetime.get_minute (), -datetime.get_second ());
    }

    /*
    public void create_tutorial_project () {
        var tutorial = new Objects.Project ();
        tutorial.name = _("Meet Planner !!!");
        tutorial.note = _("This project shows you everything you need to know use Planner.\nDon't hesitateto play arount in it - you can always create a new one in 'Preferences > Help'");
        tutorial.color = "#f9c440";

        if (Application.database.add_project (tutorial) == Sqlite.DONE) {
            var last_project = Application.database.get_last_project ();

            var task_1 = new Objects.Task ();
            task_1.project_id = last_project.id;
            task_1.content = _("Complete this task");
            task_1.note = _("Complete it by taping the checkbox on the left.");
            Application.database.add_task (task_1);

            var task_2 = new Objects.Task ();
            task_2.project_id = last_project.id;
            task_2.content = _("Create a new task");
            task_2.note = _("Tap the '+' button down on the right to create a new task.");
            Application.database.add_task (task_2);

            var task_3 = new Objects.Task ();
            task_3.project_id = last_project.id;
            task_3.content = _("Put this task in Today");
            task_3.note = _("Tap the calendar button below to decide when you'll do this task. Choose Today with a double click.");
            Application.database.add_task (task_3);

            var task_4 = new Objects.Task ();
            task_4.project_id = last_project.id;
            task_4.content = _("Plan this task for later");
            task_4.note = _("Tap the calendar button again, but now, choose a date in the calendar. It will appear on your Today list when the day comes. While the day comes, this task appear in the Upcoming list.");
            Application.database.add_task (task_4);

            var task_5 = new Objects.Task ();
            task_5.project_id = last_project.id;
            task_5.content = _("Create a project");
            task_5.note = _("Do you want to group your tasks? On the left side, tap the '+' button to create a project.");
            Application.database.add_task (task_5);
        }
    }
    */
}
