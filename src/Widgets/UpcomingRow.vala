/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Widgets.UpcomingRow : Gtk.ListBoxRow {
    public GLib.DateTime date { get; construct; }

    private Gtk.ListBox listbox;
    private Gtk.ListBox event_listbox;
    private Gtk.Revealer motion_revealer;
    private Gee.HashMap<string, bool> items_loaded;
    private Gee.HashMap<string, Gtk.Widget> event_hashmap;

    private uint update_events_idle_source = 0;

    public UpcomingRow (GLib.DateTime date) {
        Object (
            date: date
        );
    }

    construct {
        can_focus = false;
        get_style_context ().add_class ("area-row");

        items_loaded = new Gee.HashMap<string, bool> ();

        var day_label = new Gtk.Label (date.format ("%d"));
        day_label.halign = Gtk.Align.START;
        day_label.get_style_context ().add_class ("title-label");
        day_label.get_style_context ().add_class ("font-bold");
        day_label.valign = Gtk.Align.CENTER;
        day_label.use_markup = true;

        string day = date.format ("%A");
        if (Planner.utils.is_tomorrow (date)) {
            day = _("Tomorrow");
        }

        var date_label = new Gtk.Label ("<small>%s, %s</small>".printf (day, date.format ("%b")));
        date_label.halign = Gtk.Align.START;
        date_label.valign = Gtk.Align.END;
        date_label.get_style_context ().add_class ("h3");
        date_label.margin_bottom = 4;
        date_label.use_markup = true;

        var add_button = new Gtk.Button ();
        add_button.can_focus = false;
        add_button.valign = Gtk.Align.CENTER;
        add_button.tooltip_text = _("Add task");
        add_button.image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        add_button.get_style_context ().remove_class ("button");
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        add_button.get_style_context ().add_class ("hidden-button");

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin_start = 24;
        top_box.margin_end = 16;
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.pack_start (day_label, false, false, 0);
        top_box.pack_start (date_label, false, false, 6);
        //top_box.pack_end (add_button, false, false, 0);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_top = 3;
        separator.margin_start = 24;
        separator.margin_end = 16;
        separator.margin_bottom = 6;

        var motion_grid = new Gtk.Grid ();
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;

        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        listbox = new Gtk.ListBox ();
        listbox.valign = Gtk.Align.START;
        listbox.margin_start = 12;
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        event_listbox = new Gtk.ListBox ();
        event_listbox.margin_bottom = 3;
        event_listbox.margin_start = 26;
        event_listbox.valign = Gtk.Align.START;
        event_listbox.get_style_context ().add_class ("listbox");
        event_listbox.activate_on_single_click = true;
        event_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        event_listbox.hexpand = true;
        event_listbox.set_sort_func (sort_event_function);

        var event_revealer = new Gtk.Revealer ();
        event_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        event_revealer.add (event_listbox);
        event_revealer.reveal_child = Planner.settings.get_boolean ("calendar-enabled");

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.margin_bottom = 12;
        main_box.hexpand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (motion_revealer, false, false, 0);
        main_box.pack_start (separator, false, false, 0);
        main_box.pack_start (event_revealer, false, false, 0);
        main_box.pack_start (listbox, false, false, 0);

        add (main_box);
        add_all_items ();

        listbox.row_activated.connect ((row) => {
            var item = ((Widgets.ItemRow) row);
            item.reveal_child = true;
        });

        Planner.database.add_due_item.connect ((item) => {
            var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
            if (Granite.DateTime.is_same_day (datetime, date)) {
                if (items_loaded.has_key (item.id.to_string ()) == false) {
                    add_item (item);
                }
            }
        });

        Planner.database.remove_due_item.connect ((item) => {
            if (items_loaded.has_key (item.id.to_string ())) {
                items_loaded.unset (item.id.to_string ());
            }
        });

        Planner.database.update_due_item.connect ((item) => {
            var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());

            if (Granite.DateTime.is_same_day (datetime, date)) {
                if (items_loaded.has_key (item.id.to_string ()) == false) {
                    var row = new Widgets.ItemRow (item);

                    row.upcoming = date;
                    items_loaded.set (item.id.to_string (), true);

                    Timeout.add (1000, () => {
                        listbox.add (row);
                        listbox.show_all ();

                        return false;
                    });
                }
            } else {
                if (items_loaded.has_key (item.id.to_string ())) {
                    items_loaded.unset (item.id.to_string ());
                }
            }
        });

        Planner.database.item_completed.connect ((item) => {
            Idle.add (() => {
                if (item.checked == 0 && item.due_date != "") {
                    var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
                    if (Granite.DateTime.is_same_day (datetime, date)) {
                        if (items_loaded.has_key (item.id.to_string ()) == false) {
                            add_item (item);
                        }
                    }
                } else {
                    if (items_loaded.has_key (item.id.to_string ())) {
                        items_loaded.unset (item.id.to_string ());
                    }
                }

                return false;
            });
        });

        event_hashmap = new Gee.HashMap<string, Gtk.Widget> ();

        Planner.calendar_model.events_added.connect (add_event_model);
        Planner.calendar_model.events_removed.connect (remove_event_model);

        idle_update_events ();

        Planner.settings.changed.connect ((key) => {
            if (key == "calendar-enabled") {
                event_revealer.reveal_child = Planner.settings.get_boolean ("calendar-enabled");
            }
        });
    }

    private void add_event_model (E.Source source, Gee.Collection<ECal.Component> events) {
        foreach (var component in events) {
            if (Util.calcomp_is_on_day (component, date)) {
                unowned ICal.Component ical = component.get_icalcomponent ();

                var event_uid = ical.get_uid ();
                if (!event_hashmap.has_key (event_uid)) {
                    event_hashmap [event_uid] = new Widgets.EventRow (date, ical, source);
                    event_listbox.add (event_hashmap [event_uid]);
                }
            }
        }

        event_listbox.show_all ();
    }

    private void idle_update_events () {
        if (update_events_idle_source > 0) {
            GLib.Source.remove (update_events_idle_source);
        }

        update_events_idle_source = GLib.Idle.add (update_events);
    }

    private bool update_events () {
        Planner.calendar_model.source_events.@foreach ((source, component_map) => {
            foreach (var comp in component_map.get_values ()) {
                if (Util.calcomp_is_on_day (comp, date)) {
                    unowned ICal.Component ical = comp.get_icalcomponent ();
                    var event_uid = ical.get_uid ();
                    if (!event_hashmap.has_key (event_uid)) {
                        event_hashmap [event_uid] = new Widgets.EventRow (date, ical, source);
                        event_listbox.add (event_hashmap[event_uid]);
                    }
                }
            }
        });

        event_listbox.show_all ();
        update_events_idle_source = 0;
        return GLib.Source.REMOVE;
    }

    private void remove_event_model (E.Source source, Gee.Collection<ECal.Component> events) {
        foreach (var component in events) {
            unowned ICal.Component ical = component.get_icalcomponent ();
            var event_uid = ical.get_uid ();
            var dot = event_hashmap[event_uid];
            if (dot != null) {
                dot.destroy ();
                event_hashmap.unset (event_uid);
            }
        }
    }

    private int sort_event_function (Gtk.ListBoxRow child1, Gtk.ListBoxRow child2) {
        var e1 = (Widgets.EventRow) child1;
        var e2 = (Widgets.EventRow) child2;

        if (e1.start_time.compare (e2.start_time) != 0) {
            return e1.start_time.compare (e2.start_time);
        }

        // If they have the same date, sort them wholeday first
        if (e1.is_allday) {
            return -1;
        } else if (e2.is_allday) {
            return 1;
        }

        return 0;
    }

    private void add_item (Objects.Item item) {
        var row = new Widgets.ItemRow (item);

        row.upcoming = date;
        items_loaded.set (item.id.to_string (), true);

        listbox.add (row);
        listbox.show_all ();
    }

    private void add_all_items () {
        foreach (var item in Planner.database.get_items_by_date (date)) {
            var row = new Widgets.ItemRow (item);

            row.upcoming = date;
            items_loaded.set (item.id.to_string (), true);

            listbox.add (row);
            listbox.show_all ();
        }
    }
}
