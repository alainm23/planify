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

public class Views.Today : Gtk.EventBox {
    private Gtk.ListBox event_listbox;
    private Gtk.ListBox listbox;
    private Gtk.ListBox overdue_listbox;
    private Gtk.Stack view_stack;
    private Gtk.Revealer overdue_revealer;
    private Gtk.ToggleButton reschedule_button;
    private Gtk.Popover reschedule_popover = null;

    private Gee.HashMap<string, Widgets.EventRow> event_hashmap;
    
    private Gee.HashMap <string, Widgets.ItemRow> items_loaded;
    private Gee.HashMap <string, Widgets.ItemRow> overdues_loaded;
    private Gee.ArrayList<Widgets.ItemRow?> items_list;
    private Gee.ArrayList<Widgets.ItemRow?> overdue_list;

    private uint update_events_idle_source = 0;
    private uint timeout = 0;
    private GLib.DateTime date;

    private const Gtk.TargetEntry[] TARGET_ENTRIES = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    construct {
        items_list = new Gee.ArrayList<Widgets.ItemRow?> ();
        overdue_list = new Gee.ArrayList<Widgets.ItemRow?> ();
        
        items_loaded = new Gee.HashMap <string, Widgets.ItemRow> ();
        overdues_loaded = new Gee.HashMap <string, Widgets.ItemRow> ();

        var icon_image = new Gtk.Image ();
        icon_image.valign = Gtk.Align.CENTER;
        icon_image.pixel_size = 16;
        icon_image.icon_name = "help-about-symbolic";
        icon_image.get_style_context ().add_class ("today-icon");

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Today")));
        title_label.get_style_context ().add_class ("title-label");
        title_label.use_markup = true;

        var date_label = new Gtk.Label (
            new GLib.DateTime.now_local ().format (
                Granite.DateTime.get_default_date_format (false, true, false)
            )
        );
        date_label.valign = Gtk.Align.CENTER;
        date_label.margin_top = 6;
        date_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_end = 36;
        top_box.margin_start = 42;
        top_box.margin_bottom = 6;
        top_box.margin_top = 6;

        top_box.pack_start (icon_image, false, false, 0);
        top_box.pack_start (title_label, false, false, 0);
        top_box.pack_start (date_label, false, false, 0);

        listbox = new Gtk.ListBox ();
        listbox.margin_start = 30;
        listbox.margin_end = 32;
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;
        listbox.margin_top = 6;

        var overdue_label = new Gtk.Label (_("Overdue"));
        overdue_label.get_style_context ().add_class ("font-bold");
        overdue_label.halign = Gtk.Align.START;

        overdue_listbox = new Gtk.ListBox ();
        overdue_listbox.margin_start = 30;
        overdue_listbox.get_style_context ().add_class ("listbox");
        overdue_listbox.activate_on_single_click = true;
        overdue_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        overdue_listbox.hexpand = true;

        var overdue_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        overdue_separator.hexpand = true;
        overdue_separator.margin_start = 42;
        overdue_separator.margin_end = 40;

        reschedule_button = new Gtk.ToggleButton.with_label (_("Reschedule"));
        reschedule_button.get_style_context ().add_class ("flat");
        reschedule_button.get_style_context ().add_class ("overdue-label");
        reschedule_button.valign = Gtk.Align.CENTER;
        reschedule_button.can_focus = false;

        var overdue_header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        overdue_header_box.margin_start = 42;
        overdue_header_box.margin_end = 40;
        overdue_header_box.pack_start (overdue_label, false, true, 0);
        overdue_header_box.pack_end (reschedule_button, false, false, 0);

        var overdue_container_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        overdue_container_box.margin_top = 24;
        overdue_container_box.add (overdue_header_box);
        overdue_container_box.add (overdue_separator);
        overdue_container_box.add (overdue_listbox);

        overdue_revealer = new Gtk.Revealer ();
        overdue_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        overdue_revealer.add (overdue_container_box);
        overdue_revealer.reveal_child = true;

        var listbox_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        listbox_box.expand = true;
        listbox_box.add (listbox);
        listbox_box.add (overdue_revealer);

        var placeholder_view = new Widgets.Placeholder (
            _("What tasks are on your mind?"),
            _("Tap + to add a task for today."),
            icon_image.icon_name
        );
        placeholder_view.reveal_child = true;

        view_stack = new Gtk.Stack ();
        view_stack.expand = true;
        view_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        view_stack.add_named (listbox_box, "listbox");
        view_stack.add_named (placeholder_view, "placeholder");

        event_listbox = new Gtk.ListBox ();
        event_listbox.margin_top = 6;
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

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.margin_bottom = 3;
        box.margin_end = 3;
        box.pack_start (event_revealer, false, false, 0);
        // box.pack_start (new_item_revealer, false, false, 0);
        box.pack_start (view_stack, true, true, 0);

        var box_scrolled = new Gtk.ScrolledWindow (null, null);
        box_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        box_scrolled.expand = true;
        box_scrolled.add (box);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (box_scrolled, false, true, 0);

        add (main_box);
        add_all_items ();
        show_all ();
        build_drag_and_drop ();

        // Check Placeholder view
        Timeout.add (125, () => {
            check_placeholder_view ();

            return false;
        });

        reschedule_button.toggled.connect (() => {
            if (reschedule_button.active) {
                if (reschedule_popover == null) {
                    create_reschedule_popover ();
                }
            }

            reschedule_popover.popup ();
        });

        listbox.row_activated.connect ((row) => {
            var item = ((Widgets.ItemRow) row);
            item.reveal_child = true;
        });

        overdue_listbox.row_activated.connect ((row) => {
            var item = ((Widgets.ItemRow) row);
            item.reveal_child = true;
        });

        listbox.remove.connect ((row) => {
            check_placeholder_view ();
        });

        Planner.database.add_due_item.connect ((item) => {
            var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
            if (Planner.utils.is_today (datetime)) {
                if (items_loaded.has_key (item.id.to_string ()) == false) {
                    add_item (item);
                    check_placeholder_view ();
                }
            } else if (Planner.utils.is_overdue (datetime)) {
                if (overdues_loaded.has_key (item.id.to_string ()) == false) {
                    add_overdue_item (item);
                    check_placeholder_view ();
                }
            }
        });

        Planner.database.remove_due_item.connect ((item) => {
            if (items_loaded.has_key (item.id.to_string ())) {
                items_loaded.get (item.id.to_string ()).hide_destroy ();
                items_loaded.unset (item.id.to_string ());

                check_placeholder_view ();
            } else if (overdues_loaded.has_key (item.id.to_string ())) {
                overdues_loaded.get (item.id.to_string ()).hide_destroy ();
                overdues_loaded.unset (item.id.to_string ());
                
                check_placeholder_view ();
            }
        });

        Planner.database.update_due_item.connect ((item, index) => {
            var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());

            if (Planner.utils.is_today (datetime)) {
                if (items_loaded.has_key (item.id.to_string ()) == false) {
                    add_item (item, index);
                    check_placeholder_view ();
                }
            } else {
                if (items_loaded.has_key (item.id.to_string ())) {
                    items_loaded.get (item.id.to_string ()).hide_destroy ();
                    items_loaded.unset (item.id.to_string ());
                    check_placeholder_view ();
                }
            }

            if (Planner.utils.is_overdue (datetime)) {
                if (overdues_loaded.has_key (item.id.to_string ()) == false) {
                    add_overdue_item (item);
                    check_placeholder_view ();
                }
            } else {
                if (overdues_loaded.has_key (item.id.to_string ())) {
                    overdues_loaded.get (item.id.to_string ()).hide_destroy ();
                    overdues_loaded.unset (item.id.to_string ());
                    check_placeholder_view ();
                }
            }
        });

        Planner.database.item_added.connect ((item, index) => {
            if (item.due_date != "") {
                var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
                if (Planner.utils.is_today (datetime)) {
                    add_item (item, index);
                    check_placeholder_view ();
                } else if (Planner.utils.is_overdue (datetime)) {
                    var row = new Widgets.ItemRow (item, "today");

                    overdues_loaded.set (item.id.to_string (), row);
                    overdue_list.add (row);

                    overdue_listbox.add (row);
                    overdue_listbox.show_all ();

                    check_placeholder_view ();
                    update_item_order ();
                }
            }
        });

        Planner.event_bus.magic_button_activated.connect ((project_id, section_id, is_todoist, index, view, due_date) => {
            if (view == "today") {
                add_new_item (index);
            }
        });

        Planner.database.item_completed.connect ((item) => {
            Idle.add (() => {
                if (items_loaded.has_key (item.id.to_string ())) {
                    items_loaded.get (item.id.to_string ()).hide_destroy ();
                    items_loaded.unset (item.id.to_string ());
                    check_placeholder_view ();
                }

                return false;
            });
        });

        Planner.database.item_uncompleted.connect ((item) => {
            Idle.add (() => {
                if (items_loaded.has_key (item.id.to_string ()) == false) {
                    var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
                    if (Planner.utils.is_today (datetime) || Planner.utils.is_overdue (datetime)) {
                        if (items_loaded.has_key (item.id.to_string ()) == false) {
                            add_item (item);
                            check_placeholder_view ();
                        }
                    }
                }

                return false;
            });
        });
        
        date = new GLib.DateTime.now_local ();
        event_hashmap = new Gee.HashMap<string, Widgets.EventRow> ();
        Planner.calendar_model.month_start = Util.get_start_of_month ();

        Planner.calendar_model.events_added.connect (add_event_model);
        Planner.calendar_model.events_removed.connect (remove_event_model);

        idle_update_events ();

        Planner.settings.changed.connect ((key) => {
            if (key == "calendar-enabled") {
                event_revealer.reveal_child = Planner.settings.get_boolean ("calendar-enabled");
            }
        });

        Planner.utils.add_item_show_queue_view.connect ((row, view) => {
            if (view == "today") {
                // items_opened.add (row);
            }
        });

        Planner.utils.remove_item_show_queue_view.connect ((row, view) => {
            if (view == "today") {
                remove_item_show_queue (row);
            }
        });
    }

    private void build_drag_and_drop () {
        Gtk.drag_dest_set (listbox, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        listbox.drag_data_received.connect (on_drag_data_received);
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
            if (Planner.utils.is_today (due) == false) {
                source.item.due_date = new GLib.DateTime.now_local ().to_string ();

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

    public void add_new_item (int index=-1) {
        var new_item = new Widgets.NewItem (
            Planner.settings.get_int64 ("inbox-project"),
            0,
            Planner.database.get_project_by_id (Planner.settings.get_int64 ("inbox-project")).is_todoist,
            new GLib.DateTime.now_local ().to_string (),
            index,
            listbox
        );

        if (index == -1) {
            listbox.add (new_item);
        } else {
            listbox.insert (new_item, index);
        }

        listbox.show_all ();
        view_stack.visible_child_name = "listbox";
    }

    private void remove_item_show_queue (Widgets.ItemRow row) {
        // items_opened.remove (row);
    }

    public void hide_last_item () {
        //  if (items_opened.size > 0) {
        //      var last = items_opened [items_opened.size - 1];
        //      remove_item_show_queue (last);
        //      last.hide_item ();

        //      if (items_opened.size > 0) {
        //          var focus = items_opened [items_opened.size - 1];
        //          focus.grab_focus ();
        //          focus.content_entry_focus ();
        //      }
        //  }
    }

    private void add_event_model (E.Source source, Gee.Collection<ECal.Component> events) {
        foreach (var component in events) {
            if (Util.calcomp_is_on_day (component, date)) {
                unowned ICal.Component ical = component.get_icalcomponent ();

                var event_uid = ical.get_uid ();
                if (!event_hashmap.has_key (event_uid)) {
                    event_hashmap[event_uid] = new Widgets.EventRow (date, ical, source);
                    event_listbox.add (event_hashmap[event_uid]);
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
                        event_hashmap[event_uid] = new Widgets.EventRow (date, ical, source);
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
            var event_row = event_hashmap[event_uid];
            if (event_row != null) {
                event_row.destroy ();
                event_hashmap.unset (event_uid);
            }
        }
    }

    private void add_item (Objects.Item item, int index=-1) {
        var row = new Widgets.ItemRow (item, "today");

        items_loaded.set (item.id.to_string (), row);
        if (index == -1) {
            items_list.add (row);
            listbox.add (row);
        } else {
            items_list.insert (index, row);
            listbox.insert (row, index);
        }

        listbox.show_all ();
    }

    private void add_overdue_item (Objects.Item item) {
        var row = new Widgets.ItemRow (item, "today");

        overdues_loaded.set (item.id.to_string (), row);
        overdue_list.add (row);

        overdue_listbox.add (row);
        overdue_listbox.show_all ();   
    }

    private void add_all_items () {
        foreach (var item in Planner.database.get_all_today_items ()) {
            var row = new Widgets.ItemRow (item, "today");

            items_loaded.set (item.id.to_string (), row);
            items_list.add (row);

            listbox.add (row);
            listbox.show_all ();
        }

        foreach (var item in Planner.database.get_all_overdue_items ()) {
            var row = new Widgets.ItemRow (item, "today");

            overdues_loaded.set (item.id.to_string (), row);
            overdue_list.add (row);

            overdue_listbox.add (row);
            overdue_listbox.show_all ();
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

    private void check_placeholder_view () {
        var overdue_size = Planner.database.get_all_overdue_items ().size;

        if (Planner.database.get_all_today_items ().size > 0 ||
            overdue_size > 0) {
            view_stack.visible_child_name = "listbox";
        } else {
            view_stack.visible_child_name = "placeholder";
        }

        if (overdue_size > 0) {
            overdue_revealer.reveal_child = true;
        } else {
            overdue_revealer.reveal_child = false;
        }
    }

    private void create_reschedule_popover () {
        reschedule_popover = new Gtk.Popover (reschedule_button);
        reschedule_popover.position = Gtk.PositionType.BOTTOM;
        reschedule_popover.get_style_context ().add_class ("popover-background");

        var popover_grid = new Gtk.Grid ();
        popover_grid.margin_top = 6;
        popover_grid.width_request = 235;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (get_calendar_widget ());
        popover_grid.show_all ();

        reschedule_popover.add (popover_grid);

        reschedule_popover.closed.connect (() => {
            reschedule_button.active = false;
        });
    }

    private Gtk.Widget get_calendar_widget () {
        var today_button = new Widgets.ModelButton (_("Today"), "help-about-symbolic", "");
        today_button.get_style_context ().add_class ("due-menuitem");
        today_button.item_image.pixel_size = 14;
        today_button.color = 0;
        today_button.due_label = true;

        var tomorrow_button = new Widgets.ModelButton (_("Tomorrow"), "x-office-calendar-symbolic", "");
        tomorrow_button.get_style_context ().add_class ("due-menuitem");
        tomorrow_button.item_image.pixel_size = 14;
        tomorrow_button.color = 1;
        tomorrow_button.due_label = true;

        var calendar = new Widgets.Calendar.Calendar ();
        calendar.hexpand = true;

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (today_button);
        grid.add (tomorrow_button);
        grid.add (calendar);
        grid.show_all ();

        today_button.clicked.connect (() => {
            set_due (new GLib.DateTime.now_local ().to_string ());
        });

        tomorrow_button.clicked.connect (() => {
            set_due (new GLib.DateTime.now_local ().add_days (1).to_string ());
        });

        calendar.selection_changed.connect ((date) => {
            set_due (date.to_string ());
        });

        return grid;
    }

    private void set_due (string date) {
        foreach (var item in Planner.database.get_all_overdue_items ()) {
            item.due_date = date;
            Planner.database.set_due_item (item, false);
            if (item.is_todoist == 1) {
                Planner.todoist.update_item (item);
            }
        }
    }
}
