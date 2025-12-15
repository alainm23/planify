/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
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

public class Dialogs.CalendarSync : Adw.Dialog {
    public Objects.Project project { get; construct; }
    
    private Widgets.LoadingButton enable_button;
    private Widgets.LoadingButton disable_button;
    private E.Source? selected_source = null;
    private Gtk.Stack stack;

    public CalendarSync (Objects.Project project) {
        Object (
            project: project,
            title: _("Calendar Sync"),
            content_width: 450
        );
    }

    construct {
        var title_label = new Gtk.Label (_("Calendar Sync")) {
            css_classes = { "title-1" },
            margin_top = 24,
            margin_bottom = 12
        };

        var description_label = new Gtk.Label (_("Turn your tasks into calendar events automatically. Any task with a date will appear in your calendar, making it easier to plan your day.")) {
            wrap = true,
            justify = Gtk.Justification.CENTER,
            margin_start = 24,
            margin_end = 24,
            margin_bottom = 12
        };

        var note_label = new Gtk.Label (_("Requirement: You need a calendar account configured in GNOME Calendar (Google, Nextcloud, etc.)")) {
            wrap = true,
            justify = Gtk.Justification.CENTER,
            margin_start = 24,
            margin_end = 24,
            margin_bottom = 24,
            css_classes = { "dim-label", "caption" }
        };

        var benefit1_card = create_benefit_card (_("Get mobile notifications for your tasks through Google Calendar, Outlook, or any calendar app"));
        var benefit2_card = create_benefit_card (_("Your tasks sync everywhere: phone, tablet, web browser, and any device with your calendar"));

        var benefits_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            homogeneous = true,
            margin_start = 24,
            margin_end = 24,
            margin_bottom = 24
        };
        benefits_box.append (benefit1_card);
        benefits_box.append (benefit2_card);

        var calendar_color = new Gtk.Grid () {
            width_request = 16,
            height_request = 16,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            css_classes = { "source-calendar-color" }
        };
        Util.get_default ().set_widget_color ("#808080", calendar_color);

        var calendar_name_label = new Gtk.Label (_("Choose Calendar")) {
            halign = Gtk.Align.START,
            hexpand = true
        };

        var calendar_location_label = new Gtk.Label (_("Select a calendar from the list")) {
            halign = Gtk.Align.START,
            hexpand = true,
            css_classes = { "dim-label", "caption" }
        };

        var calendar_button_grid = new Gtk.Grid () {
            column_spacing = 9
        };
        calendar_button_grid.attach (calendar_color, 0, 0, 1, 2);
        calendar_button_grid.attach (calendar_name_label, 1, 0);
        calendar_button_grid.attach (calendar_location_label, 1, 1);

        var calendar_button = new Gtk.MenuButton () {
            child = calendar_button_grid,
            margin_start = 24,
            margin_end = 24,
            margin_top = 12,
            margin_bottom = 12
        };
        calendar_button.add_css_class ("pill");

        var calendar_popover = create_calendar_popover (calendar_button, calendar_name_label, calendar_location_label, calendar_color);
        calendar_button.popover = calendar_popover;

        enable_button = new Widgets.LoadingButton.with_label (_("Enable Sync")) {
            sensitive = false,
            margin_start = 24,
            margin_end = 24,
            margin_bottom = 24,
            margin_top = 24
        };
        enable_button.add_css_class ("suggested-action");

        enable_button.clicked.connect (() => {
            if (selected_source != null) {
                sync_tasks.begin ();
            }
        });

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.append (title_label);
        content_box.append (description_label);
        content_box.append (note_label);
        content_box.append (benefits_box);
        content_box.append (calendar_button);
        content_box.append (enable_button);

        var success_page = create_success_page ();
        var active_page = create_active_page ();

        stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };
        stack.add_named (content_box, "setup");
        stack.add_named (success_page, "success");
        stack.add_named (active_page, "active");

        var toolbar_view = new Adw.ToolbarView () {
            content = stack
        };
        toolbar_view.add_top_bar (new Adw.HeaderBar ());

        child = toolbar_view;

        if (project.calendar_source_uid != "") {
            stack.set_visible_child_name ("active");
        }
    }

    private async void unsync_tasks () {
        disable_button.is_loading = true;
        disable_button.sensitive = false;

        int deleted_count = 0;
        foreach (var item in project.all_items) {
            if (item.calendar_event_uid != "") {
                bool success = yield Services.CalendarEvents.get_default ().delete_event (
                    project.calendar_source_uid,
                    item.calendar_event_uid
                );
                
                if (success) {
                    item.calendar_event_uid = "";
                    item.update_local ();
                    deleted_count++;
                }
            }
        }

        project.calendar_source_uid = "";
        project.update_local ();

        disable_button.is_loading = false;
        
        Services.EventBus.get_default ().send_toast (
            Util.get_default ().create_toast (_("Calendar sync disabled successfully"))
        );
        
        close ();
    }

    private async void sync_tasks () {
        enable_button.is_loading = true;
        enable_button.sensitive = false;

        project.calendar_source_uid = selected_source.get_uid ();
        project.update_local ();

        int synced_count = 0;
        foreach (var item in project.all_items) {
            if (item.has_due) {
                string? event_uid = yield Services.CalendarEvents.get_default ().create_event (
                    selected_source.get_uid (),
                    item
                );
                
                if (event_uid != null) {
                    item.calendar_event_uid = event_uid;
                    item.update_local ();
                    synced_count++;
                }
            }
        }

        enable_button.is_loading = false;
        stack.set_visible_child_name ("success");
    }

    private Gtk.Widget create_active_page () {
        var icon = new Gtk.Image.from_icon_name ("check-round-outline-symbolic") {
            pixel_size = 64,
            css_classes = { "success" }
        };

        var title = new Gtk.Label (_("Calendar Sync Active")) {
            css_classes = { "title-1" },
            margin_top = 24
        };

        var description = new Gtk.Label (_("Your tasks are currently synced with your calendar. Any task with a date automatically appears as a calendar event.")) {
            wrap = true,
            justify = Gtk.Justification.CENTER,
            margin_start = 24,
            margin_end = 24,
            margin_top = 12
        };

        var calendar_info = new Gtk.Label ("") {
            wrap = true,
            justify = Gtk.Justification.CENTER,
            margin_start = 24,
            margin_end = 24,
            margin_top = 24,
            css_classes = { "dim-label" }
        };

        load_active_calendar_info.begin (calendar_info);

        disable_button = new Widgets.LoadingButton.with_label (_("Disable Sync")) {
            margin_start = 24,
            margin_end = 24,
            margin_top = 24,
            margin_bottom = 24,
            halign = CENTER
        };
        disable_button.add_css_class ("destructive-action");
        disable_button.add_css_class ("pill");
        disable_button.clicked.connect (() => {
            unsync_tasks.begin ();
        });

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.CENTER,
            vexpand = true
        };
        box.append (icon);
        box.append (title);
        box.append (description);
        box.append (calendar_info);
        box.append (disable_button);

        return box;
    }

    private async void load_active_calendar_info (Gtk.Label label) {
        try {
            var registry = yield new E.SourceRegistry (null);
            var source = registry.ref_source (project.calendar_source_uid);
            
            if (source != null) {
                label.label = _("Synced with: %s").printf (source.dup_display_name ());
            }
        } catch (Error e) {
            critical ("Error loading calendar info: %s", e.message);
        }
    }

    private Gtk.Widget create_success_page () {
        var icon = new Gtk.Image.from_icon_name ("check-round-outline-symbolic") {
            pixel_size = 64,
            css_classes = { "success" }
        };

        var title = new Gtk.Label (_("Sync Enabled!")) {
            css_classes = { "title-1" },
            margin_top = 24
        };

        var description = new Gtk.Label (_("Your tasks are now synced with your calendar. Any task with a date will automatically appear as a calendar event.")) {
            wrap = true,
            justify = Gtk.Justification.CENTER,
            margin_start = 24,
            margin_end = 24,
            margin_top = 12
        };

        var ok_button = new Gtk.Button.with_label (_("OK")) {
            margin_start = 24,
            margin_end = 24,
            margin_top = 32,
            margin_bottom = 24,
            halign = CENTER
        };
        ok_button.add_css_class ("suggested-action");
        ok_button.add_css_class ("pill");
        ok_button.clicked.connect (() => close ());

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.CENTER,
            vexpand = true
        };
        box.append (icon);
        box.append (title);
        box.append (description);
        box.append (ok_button);

        return box;
    }

    private Gtk.Widget create_benefit_card (string description) {
        var label = new Gtk.Label (description) {
            wrap = true,
            justify = CENTER,
            valign = CENTER,
            vexpand = true,
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12
        };
        label.add_css_class ("caption");

        var card = new Adw.Bin () {
            css_classes = { "card" },
            child = label
        };

        return card;
    }

    private Gtk.Popover create_calendar_popover (Gtk.MenuButton button, Gtk.Label name_label, Gtk.Label location_label, Gtk.Grid color_widget) {
        var list_box = new Gtk.ListBox () {
            css_classes = { "listbox-background" },
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6
        };

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
            child = list_box
        };

        var popover = new Gtk.Popover () {
            child = scrolled_window,
            width_request = 300,
            height_request = 300
        };
        popover.add_css_class ("popover-contents");

        list_box.row_activated.connect ((row) => {
            var calendar_row = (CalendarSourceRow) row;

            // Update button content
            name_label.label = calendar_row.calendar_name;
            location_label.label = CalendarEventsUtil.get_source_location (calendar_row.source);
            location_label.visible = true;
            
            E.SourceCalendar cal = (E.SourceCalendar) calendar_row.source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
            Util.get_default ().set_widget_color (cal.dup_color (), color_widget);
            color_widget.visible = true;

            selected_source = calendar_row.source;
            enable_button.sensitive = true;

            // Hide all check icons
            var child = list_box.get_first_child ();
            while (child != null) {
                if (child is CalendarSourceRow) {
                    ((CalendarSourceRow) child).check_icon.visible = false;
                }
                child = child.get_next_sibling ();
            }

            calendar_row.check_icon.visible = true;
            popover.popdown ();
        });

        load_calendar_sources.begin (list_box);

        return popover;
    }

    private async void load_calendar_sources (Gtk.ListBox list_box) {
        try {
            var registry = yield new E.SourceRegistry (null);
            var sources = registry.list_sources (E.SOURCE_EXTENSION_CALENDAR);
            var used_calendars = Services.Store.instance ().get_used_calendar_sources ();

            sources.foreach ((source) => {
                if (!source.enabled) {
                    return;
                }

                if (used_calendars.contains (source.get_uid ())) {
                    return;
                }

                list_box.append (new CalendarSourceRow (source));
            });
        } catch (GLib.Error error) {
            critical ("Error loading calendar sources: %s", error.message);
        }
    }

    public class CalendarSourceRow : Gtk.ListBoxRow {
        public E.Source source { get; construct; }
        public Gtk.Image check_icon { get; private set; }
        public string calendar_name { get; private set; }

        public CalendarSourceRow (E.Source source) {
            Object (
                source: source
            );
        }

        construct {
            calendar_name = source.dup_display_name ();

            var color_grid = new Gtk.Grid () {
                width_request = 16,
                height_request = 16,
                valign = Gtk.Align.CENTER,
                halign = Gtk.Align.CENTER,
                css_classes = { "source-calendar-color" }
            };

            var title_label = new Gtk.Label (calendar_name) {
                halign = Gtk.Align.START,
                hexpand = true
            };

            var subtitle_label = new Gtk.Label (CalendarEventsUtil.get_source_location (source)) {
                halign = Gtk.Align.START,
                hexpand = true,
                css_classes = { "dim-label", "caption" }
            };

            check_icon = new Gtk.Image.from_icon_name ("object-select-symbolic") {
                visible = false,
                margin_end = 6
            };

            var grid = new Gtk.Grid () {
                column_spacing = 9,
                margin_top = 6,
                margin_bottom = 6,
                margin_start = 6,
                margin_end = 6
            };
            grid.attach (color_grid, 0, 0, 1, 2);
            grid.attach (title_label, 1, 0);
            grid.attach (subtitle_label, 1, 1);
            grid.attach (check_icon, 2, 0, 1, 2);

            child = grid;
            add_css_class ("border-radius-6");
            
            E.SourceCalendar cal = (E.SourceCalendar) source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
            Util.get_default ().set_widget_color (cal.dup_color (), color_grid);
        }
    }
}