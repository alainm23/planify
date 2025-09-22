/*
 * Copyright © 2025 Alain M. (https://github.com/alainm23/planify)
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

public class Dialogs.Preferences.Pages.General : Dialogs.Preferences.Pages.BasePage {
    public General (Adw.PreferencesDialog preferences_dialog) {
        Object (
            preferences_dialog: preferences_dialog,
            title: _("General")
        );
    }

    ~General () {
        debug ("Destroying - Dialogs.Preferences.Pages.General\n");
    }

    construct {
        var sort_projects_model = new Gtk.StringList (null);
        sort_projects_model.append (_("Custom Sort Order"));
        sort_projects_model.append (_("Alphabetically"));

        var sort_projects_row = new Adw.ComboRow ();
        sort_projects_row.title = _("Sort by");
        sort_projects_row.model = sort_projects_model;
        sort_projects_row.selected = Services.Settings.get_default ().settings.get_enum ("projects-sort-by");

        var sort_order_projects_model = new Gtk.StringList (null);
        sort_order_projects_model.append (_("Ascending"));
        sort_order_projects_model.append (_("Descending"));

        var sort_order_projects_row = new Adw.ComboRow ();
        sort_order_projects_row.title = _("Ordered");
        sort_order_projects_row.model = sort_order_projects_model;
        sort_order_projects_row.selected = Services.Settings.get_default ().settings.get_enum ("projects-ordered");
        sort_order_projects_row.sensitive = Services.Settings.get_default ().settings.get_enum ("projects-sort-by") ==
                                            1;

        var sort_setting_group = new Adw.PreferencesGroup ();
        sort_setting_group.title = _("Projects");
        sort_setting_group.add (sort_projects_row);
        sort_setting_group.add (sort_order_projects_row);

        var de_group = new Adw.PreferencesGroup ();
        de_group.title = _("DE Integration");

        var run_background_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER,
            active = Services.Settings.get_default ().settings.get_boolean ("run-in-background")
        };

        var run_background_row = new Adw.ActionRow ();
        run_background_row.title = _("Run in Background");
        run_background_row.subtitle = _("Let Planify run in background and send notifications");
        run_background_row.set_activatable_widget (run_background_switch);
        run_background_row.add_suffix (run_background_switch);

        // de_group.add (run_background_row);

        #if WITH_LIBPORTAL
        var run_on_startup_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER,
            active = Services.Settings.get_default ().settings.get_boolean ("run-on-startup")
        };

        var run_on_startup_row = new Adw.ActionRow ();
        run_on_startup_row.title = _("Run on Startup");
        run_on_startup_row.subtitle = _("Whether Planify should run on startup");
        run_on_startup_row.set_activatable_widget (run_on_startup_switch);
        run_on_startup_row.add_suffix (run_on_startup_switch);

        de_group.add (run_on_startup_row);
        #endif

        var calendar_events_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER,
            active = Services.Settings.get_default ().settings.get_boolean ("calendar-enabled")
        };

        var calendar_events_row = new Adw.ActionRow ();
        calendar_events_row.title = _("Calendar Events");
        calendar_events_row.set_activatable_widget (calendar_events_switch);
        calendar_events_row.add_suffix (calendar_events_switch);

        de_group.add (calendar_events_row);

        var datetime_group = new Adw.PreferencesGroup ();
        datetime_group.title = _("Date and Time");

        var clock_format_model = new Gtk.StringList (null);
        clock_format_model.append (_("24h"));
        clock_format_model.append (_("12h"));

        var clock_format_row = new Adw.ComboRow ();
        clock_format_row.title = _("Clock Format");
        clock_format_row.model = clock_format_model;
        clock_format_row.selected = Services.Settings.get_default ().settings.get_enum ("clock-format");

        datetime_group.add (clock_format_row);

        var start_week_model = new Gtk.StringList (null);
        start_week_model.append (_("Sunday"));
        start_week_model.append (_("Monday"));
        start_week_model.append (_("Tuesday"));
        start_week_model.append (_("Wednesday"));
        start_week_model.append (_("Thursday"));
        start_week_model.append (_("Friday"));
        start_week_model.append (_("Saturday"));

        var start_week_row = new Adw.ComboRow ();
        start_week_row.title = _("Start of the Week");
        start_week_row.model = start_week_model;
        start_week_row.selected = Services.Settings.get_default ().settings.get_enum ("start-week");

        datetime_group.add (start_week_row);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
        content_box.append (sort_setting_group);
        content_box.append (de_group);
        content_box.append (datetime_group);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 600,
            margin_start = 24,
            margin_end = 24,
            margin_bottom = 24
        };

        content_clamp.child = content_box;

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };
        scrolled_window.child = content_clamp;

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (new Adw.HeaderBar ());
        toolbar_view.content = scrolled_window;

        child = toolbar_view;

        signal_map[sort_projects_row.notify["selected"].connect (() => {
            Services.Settings.get_default ().settings.set_enum ("projects-sort-by", (int) sort_projects_row.selected);
            sort_order_projects_row.sensitive =
                Services.Settings.get_default ().settings.get_enum ("projects-sort-by") == 1;
        })] = sort_projects_row;

        signal_map[sort_order_projects_row.notify["selected"].connect (() => {
            Services.Settings.get_default ().settings.set_enum ("projects-ordered",
                                                                (int) sort_order_projects_row.selected);
        })] = sort_order_projects_row;

        signal_map[run_background_switch.notify["active"].connect (() => {
            Services.Settings.get_default ().settings.set_boolean ("run-in-background", run_background_switch.active);
        })] = run_background_switch;

#if WITH_LIBPORTAL
        signal_map[run_on_startup_switch.notify["active"].connect (() => {
            Services.Settings.get_default ().settings.set_boolean ("run-on-startup", run_on_startup_switch.active);
        })] = run_on_startup_switch;
#endif

        signal_map[calendar_events_switch.notify["active"].connect (() => {
            Services.Settings.get_default ().settings.set_boolean ("calendar-enabled", calendar_events_switch.active);
        })] = calendar_events_switch;

        signal_map[clock_format_row.notify["selected"].connect (() => {
            Services.Settings.get_default ().settings.set_enum ("clock-format", (int) clock_format_row.selected);
        })] = clock_format_row;

        signal_map[start_week_row.notify["selected"].connect (() => {
            Services.Settings.get_default ().settings.set_enum ("start-week", (int) start_week_row.selected);
        })] = start_week_row;

        destroy.connect (() => {
            clean_up ();
        });
    }

    public override void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }
}
