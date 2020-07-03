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
    private Gtk.Grid top_box;
    public Gee.HashMap <string, Widgets.ItemRow> items_loaded;
    public Gee.ArrayList<Widgets.ItemRow?> items_list;
    private Gee.HashMap<string, Gtk.Widget> event_hashmap;

    private uint update_events_idle_source = 0;
    private uint timeout = 0;
    
    private const Gtk.TargetEntry[] TARGET_ENTRIES = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] TARGET_ENTRIES_MAGIC_BUTTON = {
        {"MAGICBUTTON", Gtk.TargetFlags.SAME_APP, 0}
    };

    public UpcomingRow (GLib.DateTime date) {
        Object (
            date: date
        );
    }

    construct {
        can_focus = false;
        get_style_context ().add_class ("area-row");
        items_list = new Gee.ArrayList<Widgets.ItemRow?> ();
        items_loaded = new Gee.HashMap<string, Widgets.ItemRow> ();

        var day_label = new Gtk.Label ("%s ‧ %s".printf (date.format ("%a"), Planner.utils.get_relative_date_from_date (date)));
        day_label.halign = Gtk.Align.START;
        day_label.get_style_context ().add_class ("font-bold");
        day_label.valign = Gtk.Align.CENTER;
        day_label.use_markup = true;

        string day = date.format ("%A");
        if (Planner.utils.is_tomorrow (date)) {
            day = _("Tomorrow");
        }

        //  var date_label = new Gtk.Label ("<small>%s, %s</small>".printf (day, ));
        //  date_label.halign = Gtk.Align.START;
        //  date_label.valign = Gtk.Align.START;
        //  date_label.get_style_context ().add_class ("dim-label");
        //  date_label.use_markup = true;

        var add_button = new Gtk.Button ();
        add_button.can_focus = false;
        add_button.valign = Gtk.Align.CENTER;
        add_button.tooltip_text = _("Add task");
        add_button.image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        add_button.get_style_context ().remove_class ("button");
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        add_button.get_style_context ().add_class ("hidden-button");

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.hexpand = true;
        separator.margin_top = 3;
        separator.margin_start = 42;
        separator.margin_end = 40;

        top_box = new Gtk.Grid ();
        top_box.margin_start = 42;
        top_box.margin_end = 40;
        top_box.column_spacing = 6;
        top_box.row_spacing = 3;
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.add (day_label);
        
        var motion_grid = new Gtk.Grid ();
        motion_grid.margin_start = 42;
        motion_grid.margin_bottom = 0;
        motion_grid.margin_end = 40;
        motion_grid.margin_top = 6;
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;

        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        listbox = new Gtk.ListBox ();
        listbox.valign = Gtk.Align.START;
        listbox.margin_start = 32;
        listbox.margin_end = 32;
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        event_listbox = new Gtk.ListBox ();
        event_listbox.margin_bottom = 3;
        event_listbox.margin_start = 44;
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
        main_box.margin_bottom = 48;
        main_box.hexpand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (separator, false, false, 0);
        main_box.pack_start (event_revealer, false, false, 0);
        main_box.pack_start (motion_revealer, false, false, 0);
        main_box.pack_start (listbox, false, false, 0);

        add (main_box);
        add_all_items ();
        build_drag_and_drop (false);

        listbox.row_activated.connect ((row) => {
            var item = ((Widgets.ItemRow) row);
            item.reveal_child = true;
        });

        Planner.database.item_added.connect ((item, index) => {
            if (item.due_date != "") {
                var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
                if (Granite.DateTime.is_same_day (datetime, date)) {
                    if (items_loaded.has_key (item.id.to_string ()) == false) {
                        add_item (item, index);
                    }
                }
            }
        });

        Planner.event_bus.magic_button_activated.connect ((project_id, section_id, is_todoist, index, view, due_date) => {
            var datetime = new GLib.DateTime.from_iso8601 (due_date, new GLib.TimeZone.local ());
            if (view == "upcoming" && Granite.DateTime.is_same_day (datetime, date)) {
                add_new_item (index);
            }
        });

        Planner.database.add_due_item.connect ((item, index) => {
            var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
            if (Granite.DateTime.is_same_day (datetime, date)) {
                if (items_loaded.has_key (item.id.to_string ()) == false) {
                    add_item (item, index);
                }
            }
        });

        Planner.database.remove_due_item.connect ((item) => {
            if (items_loaded.has_key (item.id.to_string ())) {
                items_loaded.get (item.id.to_string ()).hide_destroy ();
                items_loaded.unset (item.id.to_string ());
            }
        });

        Planner.database.update_due_item.connect ((item, index) => {
            var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());

            if (Granite.DateTime.is_same_day (datetime, date)) {
                if (items_loaded.has_key (item.id.to_string ()) == false) {
                    var row = new Widgets.ItemRow (item, "upcoming");
                    add_item (item, index);
                }
            } else {
                if (items_loaded.has_key (item.id.to_string ())) {
                    items_loaded.get (item.id.to_string ()).hide_destroy ();
                    items_loaded.unset (item.id.to_string ());
                }
            }
        });

        Planner.database.item_completed.connect ((item) => {
            Idle.add (() => {
                if (items_loaded.has_key (item.id.to_string ())) {
                    items_loaded.get (item.id.to_string ()).hide_destroy ();
                    items_loaded.unset (item.id.to_string ());
                }

                return false;
            });
        });

        Planner.database.item_uncompleted.connect ((item) => {
            Idle.add (() => {
                if (items_loaded.has_key (item.id.to_string ()) == false) {
                    var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
                    if (Granite.DateTime.is_same_day (datetime, date)) {
                        if (items_loaded.has_key (item.id.to_string ()) == false) {
                            add_item (item);
                        }
                    }
                }

                return false;
            });
        });

        Planner.utils.magic_button_clicked.connect ((view) => {
            if (view == "upcoming" && Granite.DateTime.is_same_day (new DateTime.now_local ().add_days (1), date)) {
                add_new_item (0);
            }
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

        Planner.event_bus.drag_magic_button_activated.connect ((value) => {
            build_drag_and_drop (value);
        });
    }
    
    private void build_drag_and_drop (bool value) {
        Gtk.drag_dest_set (listbox, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        listbox.drag_data_received.connect (on_drag_data_received);
        top_box.drag_data_received.disconnect (on_drag_item_received);
        top_box.drag_data_received.disconnect (on_drag_magic_button_received);

        if (value) {
            Gtk.drag_dest_set (top_box, Gtk.DestDefaults.ALL, TARGET_ENTRIES_MAGIC_BUTTON, Gdk.DragAction.MOVE);
            top_box.drag_data_received.connect (on_drag_magic_button_received);
            top_box.drag_motion.connect (on_drag_magicbutton_motion);
            top_box.drag_leave.connect (on_drag_magicbutton_leave);
        } else {
            Gtk.drag_dest_set (top_box, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);
            top_box.drag_data_received.connect (on_drag_item_received);
            top_box.drag_motion.connect (on_drag_magicbutton_motion);
            top_box.drag_leave.connect (on_drag_magicbutton_leave);
        }
    }

    private void on_drag_magic_button_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        add_new_item (0);
    }

    private void add_new_item (int index=-1) {
        var new_item = new Widgets.NewItem (
            Planner.settings.get_int64 ("inbox-project"),
            0,
            Planner.database.get_project_by_id (Planner.settings.get_int64 ("inbox-project")).is_todoist,
            date.to_string (),
            index,
            listbox
        );
        
        if (index == -1) {
            listbox.add (new_item);
        } else {
            listbox.insert (new_item, index);
        }

        listbox.show_all ();
    }

    private void on_drag_data_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.ItemRow target;
        Widgets.ItemRow source;
        Gtk.Allocation alloc;

        target = (Widgets.ItemRow) listbox.get_row_at_y (y);
        target.get_allocation (out alloc);

        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        if (target != null) {
            source.get_parent ().remove (source);
            items_list.remove (source);
            
            var due = new GLib.DateTime.from_iso8601 (source.item.due_date, new GLib.TimeZone.local ());
            if (!Granite.DateTime.is_same_day (due, date)) {
                source.item.due_date = date.to_string ();

                Planner.database.set_due_item (source.item, false, target.get_index () + 1);
                if (source.item.is_todoist == 1) {
                    Planner.todoist.update_item (source.item);
                }
            } else {
                listbox.insert (source, target.get_index () + 1);
                items_list.insert (target.get_index () + 1, source);

                listbox.show_all ();
            }

            update_item_order ();
        }
    }

    private void on_drag_item_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type) {
        Widgets.ItemRow source;
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        source.get_parent ().remove (source);
        items_list.remove (source);

        var due = new GLib.DateTime.from_iso8601 (source.item.due_date, new GLib.TimeZone.local ());
        if (!Granite.DateTime.is_same_day (due, date)) {
            source.item.due_date = date.to_string ();

            Planner.database.set_due_item (source.item, false, 0);
            if (source.item.is_todoist == 1) {
                Planner.todoist.update_item (source.item);
            }
        } else {
            listbox.insert (source, 0);
            items_list.insert (0, source);

            listbox.show_all ();
        }

        update_item_order ();
    }

    private void update_item_order () {
        if (timeout != 0) {
            Source.remove (timeout);
        }

        timeout = Timeout.add (1000, () => {
            new Thread<void*> ("update_item_order", () => {
                for (int index = 0; index < items_list.size; index++) {
                    Planner.database.update_today_day_order (items_list [index].item, index);
                }

                return null;
            });

            return false;
        });
    }

    public bool on_drag_magicbutton_motion (Gdk.DragContext context, int x, int y, uint time) {
        motion_revealer.reveal_child = true;
        return true;
    }

    public void on_drag_magicbutton_leave (Gdk.DragContext context, uint time) {
        motion_revealer.reveal_child = false;
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

    private void add_item (Objects.Item item, int index=-1) {
        var row = new Widgets.ItemRow (item, "upcoming");

        items_loaded.set (item.id.to_string (), row);
        
        if (index == -1) {
            items_list.add (row);
            listbox.add (row);
        } else {
            items_list.insert (index, row);
            listbox.insert (row, index);
        }

        listbox.show_all ();
        update_item_order ();
    }

    private void add_all_items () {
        foreach (var item in Planner.database.get_items_by_date (date)) {
            var row = new Widgets.ItemRow (item, "upcoming");

            items_loaded.set (item.id.to_string (), row);
            items_list.add (row);

            listbox.add (row);
            listbox.show_all ();
        }
    }
}
