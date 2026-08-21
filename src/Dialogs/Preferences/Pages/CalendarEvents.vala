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

public class Dialogs.Preferences.Pages.CalendarEvents : Dialogs.Preferences.Pages.BasePage {
    public CalendarEvents (Adw.PreferencesDialog preferences_dialog) {
        Object (
            preferences_dialog: preferences_dialog,
            title: _("Calendar Events")
        );
    }

    ~CalendarEvents () {
        debug ("Destroying - Dialogs.Preferences.Pages.CalendarEvents\n");
    }

    construct {
        var calendar_enabled_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER,
            active = Services.Settings.get_default ().settings.get_boolean ("calendar-enabled")
        };

        var calendar_enabled_row = new Adw.ActionRow ();
        calendar_enabled_row.title = _("Show Calendar Events");
        calendar_enabled_row.subtitle = _("Display events from your calendars in Planify");
        calendar_enabled_row.set_activatable_widget (calendar_enabled_switch);
        calendar_enabled_row.add_suffix (calendar_enabled_switch);

        var enabled_group = new Adw.PreferencesGroup ();
        enabled_group.add (calendar_enabled_row);

        var sources_group = new Adw.PreferencesGroup ();
        sources_group.title = _("Calendars");
        sources_group.description = _("Choose which calendars to show in Planify");

        var sources_map = new Gee.HashMap<string, Gtk.Switch> ();

        var calendar_service = Services.CalendarEvents.get_default ();
        var all_sources = calendar_service.get_all_sources ();
        foreach (E.Source source in all_sources) {
            if (!source.has_extension (E.SOURCE_EXTENSION_CALENDAR)) {
                continue;
            }

            E.SourceCalendar cal = (E.SourceCalendar) source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
            if (!cal.selected || !source.enabled) {
                continue;
            }

            var source_switch = new Gtk.Switch () {
                valign = Gtk.Align.CENTER,
                active = !(source.dup_uid () in Services.Settings.get_default ().settings.get_strv ("calendar-sources-disabled")),
                sensitive = calendar_enabled_switch.active
            };

            sources_map[source.dup_uid ()] = source_switch;

            var color_grid = new Gtk.Grid () {
                width_request = 3,
                height_request = 24,
                valign = Gtk.Align.CENTER,
                css_classes = { "event-bar" }
            };
            Util.get_default ().set_widget_color (cal.dup_color (), color_grid);

            var source_row = new Adw.ActionRow ();
            source_row.title = source.dup_display_name ();
            source_row.use_markup = false;

            var parent_uid = source.dup_parent ();
            if (parent_uid != null) {
                var parent = calendar_service.registry.ref_source (parent_uid);
                if (parent != null) {
                    source_row.subtitle = parent.dup_display_name ();
                }
            }
            source_row.set_activatable_widget (source_switch);
            source_row.add_prefix (color_grid);
            source_row.add_suffix (source_switch);

            sources_group.add (source_row);

            signal_map[source_switch.notify["active"].connect (() => {
                string[] sources_disabled = {};
                foreach (var entry in sources_map.entries) {
                    if (!entry.value.active) {
                        sources_disabled += entry.key;
                    }
                }
                Services.Settings.get_default ().settings.set_strv ("calendar-sources-disabled", sources_disabled);
            })] = source_switch;
        }

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_top = 6
        };
        content_box.append (enabled_group);
        content_box.append (sources_group);

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = content_box
        };

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (new Adw.HeaderBar ());
        toolbar_view.content = scrolled_window;

        child = toolbar_view;

        signal_map[calendar_enabled_switch.notify["active"].connect (() => {
            Services.Settings.get_default ().settings.set_boolean ("calendar-enabled", calendar_enabled_switch.active);
            sources_group.sensitive = calendar_enabled_switch.active;
        })] = calendar_enabled_switch;

        destroy.connect (() => {
            clean_up ();
        });
    }
}
