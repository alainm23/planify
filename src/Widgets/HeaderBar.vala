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

public class Widgets.HeaderBar : Gtk.HeaderBar {
    private Gtk.SearchEntry search_entry;
    private Gtk.ToggleButton add_task_button;
    private Gtk.ToggleButton calendar_button;
    private Gtk.ToggleButton notification_button;
    private Gtk.Button sync_button;
    private Gtk.Button menu_button;

    public const string CSS = """
        @define-color color_header %s;
        @define-color color_selected %s;
        @define-color color_text %s;
    """;

    public bool visible_ui {
        set {
            search_entry.visible = value;
            add_task_button.visible = value;
            calendar_button.visible = value;
            menu_button.visible = value;

            if (value) {
                custom_title = search_entry;
            } else {
                custom_title = null;
            }
        }
    }

    public HeaderBar () {
        Object (
            show_close_button: true
        );
    }

    construct {
        get_style_context ().add_class ("default-decoration");
        decoration_layout = "close:menu";
        title = "Planner";

        var mode_switch = new Granite.ModeSwitch.from_icon_name ("display-brightness-symbolic", "weather-clear-night-symbolic");
        mode_switch.margin_start = 12;
        mode_switch.primary_icon_tooltip_text = (_("Light background"));
        mode_switch.secondary_icon_tooltip_text = (_("Dark background"));
        mode_switch.valign = Gtk.Align.CENTER;

        var label = new Gtk.Label (_("Night Mode"));
        label.margin_start = 6;

        var night_mode_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        night_mode_box.get_style_context ().add_class ("menuitem");
        night_mode_box.pack_start (label, false, false, 0);
        night_mode_box.pack_end (mode_switch, false, false, 0);

        var night_mode_eventbox = new Gtk.EventBox ();
        night_mode_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        night_mode_eventbox.get_style_context ().add_class ("menuitem");
        night_mode_eventbox.add (night_mode_box);

        var preferences_menuitem = new Gtk.ModelButton ();
        preferences_menuitem.text = _("Settings");

        // Menu
        var avatar = new Granite.Widgets.Avatar.from_file (Environment.get_home_dir () + "/.local/share/com.github.alainm23.planner/profile/avatar-%s.jpg".printf (Application.user.id.to_string ()), 24);

        menu_button = new Gtk.Button ();
        menu_button.get_style_context ().add_class ("headerbar-menu");
        menu_button.tooltip_text = _("Menu");
        menu_button.image = avatar;

        var menu_grid = new Gtk.Grid ();
        menu_grid.margin_bottom = 3;
        menu_grid.orientation = Gtk.Orientation.VERTICAL;
        menu_grid.width_request = 250;

        menu_grid.add (get_overview ());
        menu_grid.add (night_mode_eventbox);
        menu_grid.add (preferences_menuitem);
        menu_grid.show_all ();

        var menu_popover = new Gtk.Popover (menu_button);
        menu_popover.add (menu_grid);

        menu_button.clicked.connect (() => {
            menu_popover.show_all ();
        });

        // Search Entry
        search_entry = new Gtk.SearchEntry ();
        search_entry.margin_top = 1;
        search_entry.valign = Gtk.Align.CENTER;
        search_entry.halign = Gtk.Align.CENTER;
        search_entry.width_request = 300;
        search_entry.get_style_context ().add_class ("headerbar-search");
        search_entry.get_style_context ().add_class ("headerbar-widget");
        search_entry.placeholder_text = _("Quick find");
        
        // Add Task Button
        add_task_button = new Gtk.ToggleButton ();
        add_task_button.can_focus = false;
        add_task_button.tooltip_text = _("Add new Inbox task");
        add_task_button.width_request = 32;
        add_task_button.valign = Gtk.Align.CENTER;
        add_task_button.halign = Gtk.Align.CENTER;
        add_task_button.get_style_context ().add_class ("headerbar-widget");
        add_task_button.add (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON));

        // Calendar Button
        calendar_button = new Gtk.ToggleButton ();
        calendar_button.can_focus = false;
        calendar_button.tooltip_text = _("See calendar of events");
        calendar_button.width_request = 32;
        calendar_button.valign = Gtk.Align.CENTER;
        calendar_button.halign = Gtk.Align.CENTER;
        calendar_button.get_style_context ().add_class ("headerbar-widget");
        calendar_button.add (new Gtk.Image.from_icon_name ("office-calendar-symbolic", Gtk.IconSize.BUTTON));

        // Synchronizing Button
        sync_button = new Gtk.Button ();
        sync_button.can_focus = false;
        sync_button.tooltip_text = _("Synchronizing");
        sync_button.margin_start = 9;
        sync_button.margin_end = 3;
        sync_button.width_request = 32;
        sync_button.valign = Gtk.Align.CENTER;
        sync_button.halign = Gtk.Align.CENTER;
        sync_button.get_style_context ().add_class ("sync");
        sync_button.get_style_context ().add_class ("is_loading");
        sync_button.get_style_context ().add_class ("headerbar-widget");
        sync_button.add (new Gtk.Image.from_icon_name ("emblem-synchronizing-symbolic", Gtk.IconSize.BUTTON));

        if (Application.user.is_todoist == false) {
            sync_button.no_show_all = true;
            sync_button.visible = false;
        }

        // Notification Button
        notification_button = new Gtk.ToggleButton ();
        notification_button.can_focus = false;
        notification_button.tooltip_text = _("See calendar of events");
        notification_button.width_request = 32;
        notification_button.margin_start = 9;
        notification_button.valign = Gtk.Align.CENTER;
        notification_button.halign = Gtk.Align.CENTER;
        notification_button.get_style_context ().add_class ("headerbar-widget");
        notification_button.add (new Gtk.Image.from_icon_name ("notification-symbolic", Gtk.IconSize.BUTTON));

        pack_end (menu_button);
        pack_end (sync_button);
        pack_end (notification_button);
        pack_end (calendar_button);
        pack_end (add_task_button);
        custom_title = search_entry;
    
        mode_switch.notify["active"].connect (() => {
            var provider = new Gtk.CssProvider ();
            var colored_css = "";

            if (mode_switch.active) {
                colored_css = CSS.printf (
                    "@base_color",
                    "@selected_bg_color",
                    "@text_color"
                );
            } else {
                colored_css = CSS.printf (
                    Application.utils.get_theme (Application.settings.get_enum ("theme")),
                    Application.utils.get_selected_theme (Application.settings.get_enum ("theme")),
                    Application.utils.convert_invert ( Application.utils.get_selected_theme (Application.settings.get_enum ("theme")))
                );
            }

            try {
                provider.load_from_data (colored_css, colored_css.length);

                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (GLib.Error e) {
                return;
            }
        });

        preferences_menuitem.clicked.connect (() => {
            var settings_dialog = new Dialogs.Settings ();
            settings_dialog.destroy.connect (Gtk.main_quit);
            settings_dialog.show_all ();
        });

        var gtk_settings = Gtk.Settings.get_default ();
        mode_switch.bind_property ("active", gtk_settings, "gtk_application_prefer_dark_theme");
        Application.settings.bind ("prefer-dark-style", mode_switch, "active", GLib.SettingsBindFlags.DEFAULT);

        night_mode_eventbox.enter_notify_event.connect ((event) => {
            night_mode_eventbox.get_style_context ().add_class ("when-item");
            return false;
        });

        night_mode_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            night_mode_eventbox.get_style_context ().remove_class ("when-item");
            return false;
        });

        night_mode_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                if (mode_switch.active) {
                    mode_switch.active = false;
                } else {
                    mode_switch.active = true;
                }
            }

            return false;
        });

        Application.database.user_added.connect ((user) => {
            try {
                string file = Environment.get_home_dir () + "/.local/share/com.github.alainm23.planner/profile/avatar-%s.jpg".printf (user.id.to_string ());
                var pixbuf = new Gdk.Pixbuf.from_file_at_scale (file, 24, 24, true);
                avatar.pixbuf = pixbuf;
            } catch (Error e) {
                print ("Error: %s\n", e.message);
            } 
        });
    }

    private Gtk.Grid get_overview () {
        var username = GLib.Environment.get_user_name ();
        var iconfile = @"/var/lib/AccountsService/icons/$username";

        var avatar = new Granite.Widgets.Avatar.from_file (iconfile, 44);

        var username_label = new Gtk.Label ("<b>%s</b>".printf (GLib.Environment.get_real_name ()));
        username_label.margin_top = 6;
        username_label.halign = Gtk.Align.CENTER;
        username_label.use_markup = true;

        var overview_levelbar = new Gtk.LevelBar.for_interval (0, 1);
        overview_levelbar.margin_top = 12;
        overview_levelbar.valign = Gtk.Align.CENTER;
        overview_levelbar.hexpand = true;
        overview_levelbar.width_request = 200;

        var completed_task_label = new Gtk.Label (_("Completed tasks"));
        completed_task_label.max_width_chars = 1;
        completed_task_label.valign = Gtk.Align.CENTER;
        completed_task_label.wrap = true;
        completed_task_label.use_markup = true;
        completed_task_label.justify = Gtk.Justification.CENTER;

        var completed_task_number = new Gtk.Label (null);
        completed_task_number.get_style_context ().add_class ("h3");
        completed_task_number.get_style_context ().add_class ("h4");

        var completed_task_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        completed_task_box.pack_start (completed_task_number, false, false, 0);
        completed_task_box.pack_start (completed_task_label, false, false, 0);

        var todo_task_label = new Gtk.Label (_("To do tasks"));
        todo_task_label.max_width_chars = 1;
        todo_task_label.valign = Gtk.Align.CENTER;
        todo_task_label.wrap = true;
        todo_task_label.use_markup = true;
        todo_task_label.justify = Gtk.Justification.CENTER;

        var todo_task_number = new Gtk.Label (null);
        todo_task_number.get_style_context ().add_class ("h3");
        todo_task_number.get_style_context ().add_class ("h4");

        var todo_task_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        todo_task_box.pack_start (todo_task_number, false, false, 0);
        todo_task_box.pack_start (todo_task_label, false, false, 0);

        var all_task_label = new Gtk.Label (_("All tasks"));
        all_task_label.max_width_chars = 1;
        all_task_label.valign = Gtk.Align.CENTER;
        all_task_label.wrap = true;
        all_task_label.use_markup = true;
        all_task_label.justify = Gtk.Justification.CENTER;

        var all_task_number = new Gtk.Label (null);
        all_task_number.get_style_context ().add_class ("h3");
        all_task_number.get_style_context ().add_class ("h4");

        var all_task_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        all_task_box.pack_start (all_task_number, false, false, 0);
        all_task_box.pack_start (all_task_label, false, false, 0);

        var grid = new Gtk.Grid ();
        grid.margin_top = 12;
        grid.column_homogeneous = true;
        grid.add (completed_task_box);
        grid.add (todo_task_box);
        grid.add (all_task_box);

        var overview_grid = new Gtk.Grid ();
        overview_grid.orientation = Gtk.Orientation.VERTICAL;
        overview_grid.margin = 12;
        overview_grid.add (avatar);
        overview_grid.add (username_label);
        overview_grid.add (overview_levelbar);
        overview_grid.add (grid);
        
        /*
        Application.database.update_indicators.connect (() => {
            int completed_tasks = Application.database.get_all_completed_tasks ();
            int todo_tasks = Application.database.get_all_todo_tasks ();
            int all_tasks = Application.database.get_all_tasks ();

            completed_task_number.label = completed_tasks.to_string ();
            todo_task_number.label = todo_tasks.to_string ();
            all_task_number.label = all_tasks.to_string ();

            overview_levelbar.value = (double) completed_tasks / (double) all_tasks;
        });
        */

        return overview_grid;
    }
}
