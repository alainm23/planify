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

public class Widgets.EventRow : Gtk.ListBoxRow {
    public unowned ICal.Component component { get; construct; }
    public unowned E.SourceCalendar cal { get; construct; }
    public E.Source source { get; construct; }

    public GLib.DateTime start_time { get; private set; }
    public GLib.DateTime ? end_time { get; private set; }
    public bool is_allday { get; private set; default = false; }

    private Gtk.Grid color_grid;
    private Gtk.Label time_label;
    private Gtk.Label name_label;
    private Gtk.Popover popover;

    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public EventRow (ICal.Component component, E.Source source) {
        Object (
            component : component,
            cal: (E.SourceCalendar ?) source.get_extension (E.SOURCE_EXTENSION_CALENDAR),
            source: source
        );
    }

    ~EventRow () {
        debug ("Destroying - Widgets.EventRow\n");
    }

    construct {
        add_css_class ("no-selectable");
        add_css_class ("transition");

        update_times (component);

        color_grid = new Gtk.Grid () {
            width_request = 3,
            height_request = 12,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            css_classes = { "event-bar" }
        };

        time_label = new Gtk.Label (null) {
            xalign = 0,
            valign = Gtk.Align.CENTER,
            css_classes = { "dimmed", "caption" }
        };

        name_label = new Gtk.Label (component.get_summary ()) {
            valign = Gtk.Align.CENTER,
            ellipsize = Pango.EllipsizeMode.END,
            wrap = true,
            use_markup = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
            margin_start = 3,
            css_classes = { "caption" }
        };

        var grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 3,
            margin_bottom = 3
        };

        if (!is_allday) {
            grid.append (time_label);
        }

        grid.append (color_grid);
        grid.append (name_label);

        var description = component.get_description ();
        if (description != null && ("meet.google.com" in description || "teams.microsoft.com" in description || "zoom.us" in description)) {
            var video_icon = new Gtk.Image.from_icon_name ("video-camera-symbolic") {
                pixel_size = 12,
                valign = Gtk.Align.CENTER,
                margin_top = 3
            };
            grid.append (video_icon);
        }

        child = grid;

        var click_gesture = new Gtk.GestureClick ();
        click_gesture.released.connect (() => {
            if (popover == null) {
                create_popover ();
            }

            popover.popup ();
        });
        add_controller (click_gesture);

        update_color ();
        signal_map[cal.notify["color"].connect (update_color)] = cal;
        update_timelabel ();

        signal_map[Services.Settings.get_default ().settings.changed["clock-format"].connect (update_timelabel)] = Services.Settings.get_default ();
    }

    private void update_timelabel () {
        string format = Utils.Datetime.is_clock_format_12h () ? "%I:%M %p" : "%H:%M";
        time_label.label = start_time.format (format);
    }

    private void update_color () {
        Util.get_default ().set_widget_color (cal.dup_color (), color_grid);
    }

    private void update_times (ICal.Component comp) {
        var dt_start = comp.get_dtstart ();
        var dt_end = comp.get_dtend ();

        if (dt_start.is_date ()) {
            start_time = CalendarEventsUtil.ical_to_date_time (dt_start);
        } else {
            start_time = CalendarEventsUtil.ical_to_date_time (dt_start).to_local ();
        }

        if (dt_end.is_date ()) {
            end_time = CalendarEventsUtil.ical_to_date_time (dt_end);
        } else {
            end_time = CalendarEventsUtil.ical_to_date_time (dt_end).to_local ();
        }

        is_allday = end_time != null && CalendarEventsUtil.is_the_all_day (start_time, end_time);
    }

    public void update (ICal.Component new_component) {
        update_times (new_component);
        name_label.label = new_component.get_summary ();
        update_timelabel ();
    }

    private void create_popover () {
        var title_label = new Gtk.Label (component.get_summary ()) {
            xalign = 0,
            wrap = true,
            selectable = true,
            can_focus = false,
            css_classes = { "title-4" }
        };

        string date_text;
        if (is_allday) {
            date_text = start_time.format ("%A, %e de %B");
        } else {
            string time_format = Utils.Datetime.is_clock_format_12h () ? "%I:%M %p" : "%H:%M";
            
            if (start_time.get_day_of_year () == end_time.get_day_of_year () && start_time.get_year () == end_time.get_year ()) {
                date_text = start_time.format ("%A, %e de %B · ") + start_time.format (time_format) + " - " + end_time.format (time_format);
            } else {
                date_text = start_time.format ("%e %b ") + start_time.format (time_format) + " - " + end_time.format ("%e %b ") + end_time.format (time_format);
            }
        }

        var date_label = new Gtk.Label (date_text) {
            xalign = 0,
            wrap = true,
            selectable = true,
            can_focus = false,
            css_classes = { "dimmed", "caption" }
        };

        var header_box = new Gtk.Box (VERTICAL, 3);
        header_box.append (title_label);
        header_box.append (date_label);

        var now = new DateTime.now_local ();
        if (!is_allday && start_time.get_day_of_year () == now.get_day_of_year () && start_time.get_year () == now.get_year ()) {
            var time_diff = start_time.difference (now) / TimeSpan.MINUTE;
            string time_status = "";
            
            if (time_diff > 0) {
                if (time_diff < 60) {
                    time_status = _("In %d minutes").printf ((int)time_diff);
                } else {
                    time_status = _("In %d hours").printf ((int)(time_diff / 60));
                }
            } else if (time_diff > -60 && end_time != null) {
                var end_diff = end_time.difference (now) / TimeSpan.MINUTE;
                if (end_diff > 0) {
                    time_status = _("Happening now");
                }
            }
            
            if (time_status != "") {
                var time_status_label = new Gtk.Label (time_status) {
                    xalign = 0,
                    css_classes = { "caption", "accent" }
                };
                header_box.append (time_status_label);
            }
        }


        var popover_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12
        };
        popover_box.append (header_box);
        popover_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3
        });

        var location = component.get_location ();
        if (location != null && location != "") {
            var location_label = new Gtk.Label (location) {
                xalign = 0,
                wrap = true,
                selectable = true,
                can_focus = false
            };
            
            popover_box.append (create_info_widget ("map-marker-symbolic", _("Location"), location_label));
        }

        var organizer_prop = component.get_first_property (ICal.PropertyKind.ORGANIZER_PROPERTY);
        if (organizer_prop != null) {
            var organizer = organizer_prop.get_organizer ();
            if (organizer != null && organizer != "") {
                var organizer_label = new Gtk.Label (organizer.replace ("mailto:", "")) {
                    xalign = 0,
                    wrap = true,
                    selectable = true,
                    can_focus = false
                };
                popover_box.append (create_info_widget ("people-symbolic", _("Organizer"), organizer_label));
            }
        }

        var url_prop = component.get_first_property (ICal.PropertyKind.URL_PROPERTY);
        if (url_prop != null) {
            var url = url_prop.get_url ();
            if (url != null && url != "") {
                var url_label = new Gtk.Label (url) {
                    xalign = 0,
                    wrap = true,
                    selectable = true,
                    can_focus = false
                };
                popover_box.append (create_info_widget ("external-link-symbolic", _("URL"), url_label));
            }
        }

        var calendar_label = new Gtk.Label (source.dup_display_name ()) {
            xalign = 0,
            wrap = true,
            selectable = true,
            can_focus = false
        };
        popover_box.append (create_info_widget ("work-week-symbolic", _("Calendar"), calendar_label));

        var description = component.get_description ();
        if (description != null && description != "") {
            bool content_added = false;
            
            if ("meet.google.com" in description || "Google Meet" in description) {
                var meet_url = extract_meet_url (description);
                if (meet_url != null) {
                    popover_box.append (create_meeting_widget ("Google Meet", meet_url));
                    content_added = true;
                }
            } else if ("teams.microsoft.com" in description || "Microsoft Teams" in description) {
                var teams_url = extract_teams_url (description);
                if (teams_url != null) {
                    popover_box.append (create_meeting_widget ("Microsoft Teams", teams_url));
                    content_added = true;
                }
            } else if ("zoom.us" in description || "Zoom" in description) {
                var zoom_url = extract_zoom_url (description);
                if (zoom_url != null) {
                    popover_box.append (create_meeting_widget ("Zoom", zoom_url));
                    content_added = true;
                }
            }
            
            if (!content_added) {
                var description_label = new Gtk.Label (description) {
                    xalign = 0,
                    wrap = true,
                    selectable = true,
                    can_focus = false,
                    use_markup = false
                };
                
                popover_box.append (create_info_widget ("text-justify-left-symbolic", _("Description"), description_label));
            }
        }

        var popover_scrolled_window = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vscrollbar_policy = Gtk.PolicyType.NEVER,
            child = popover_box
        };

        popover = new Gtk.Popover () {
            child = popover_scrolled_window,
            width_request = 275
        };

        popover.set_parent (this);
    }

    private Gtk.Widget create_info_widget (string icon_name, string header_text, Gtk.Widget content_widget) {
        var grid = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 6
        };
        
        var icon = new Gtk.Image.from_icon_name (icon_name) {
            pixel_size = 12,
            valign = Gtk.Align.CENTER
        };
        icon.add_css_class ("dimmed");
        
        var header = new Gtk.Label (header_text) {
            xalign = 0,
            css_classes = { "caption", "dimmed" }
        };
        
        grid.attach (icon, 0, 0, 1, 1);
        grid.attach (header, 1, 0, 1, 1);
        grid.attach (content_widget, 1, 1, 1, 1);
        
        return grid;
    }

    private Gtk.Widget create_meeting_widget (string title, string url) {        
        var header = new Gtk.Label (title) {
            xalign = 0,
            hexpand = true,
            css_classes = { "caption", "dim-label" }
        };

        var url_entry = new Gtk.Text () {
            text = url,
            editable = false,
            can_focus = false,
            hexpand = true
        };
        url_entry.add_css_class ("caption");
        url_entry.add_css_class ("accent");
        
        var join_button = new Gtk.Button.with_label (_("Join")) {
            valign = Gtk.Align.CENTER
        };
        
        join_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri (url, null);
            } catch (Error e) {
                warning ("Error opening URL: %s", e.message);
            }
        });

        var grid = new Gtk.Grid () {
            column_spacing = 24,
            row_spacing = 6,
            margin_top = 12
        };
        grid.attach (header, 0, 0, 1, 1);
        grid.attach (url_entry, 0, 1, 1, 1);
        grid.attach (join_button, 1, 0, 1, 2);
        
        return grid;
    }

    private string? extract_meet_url (string description) {
        var regex = /https:\/\/meet\.google\.com\/[a-z\-]+/;
        MatchInfo match_info;
        if (regex.match (description, 0, out match_info)) {
            return match_info.fetch (0);
        }
        return null;
    }

    private string? extract_teams_url (string description) {
        var regex = /https:\/\/teams\.microsoft\.com\/l\/meetup-join\/[^>\s]+/;
        MatchInfo match_info;
        if (regex.match (description, 0, out match_info)) {
            var url = match_info.fetch (0);
            return url.replace ("&amp;", "&");
        }
        return null;
    }

    private string? extract_zoom_url (string description) {
        var regex = /https:\/\/[a-z0-9]+\.zoom\.us\/[^\s]+/;
        MatchInfo match_info;
        if (regex.match (description, 0, out match_info)) {
            return match_info.fetch (0);
        }
        return null;
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
        
        if (popover != null) {
            popover.unparent ();
        }
    }
}
