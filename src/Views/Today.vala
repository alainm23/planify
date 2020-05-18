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
    private Gtk.ListBox listbox;
    private Gtk.ListBox event_listbox;
    // public Gtk.Revealer new_item_revealer;
    // private Widgets.NewItem new_item;
    private Gtk.Stack view_stack;

    private Gee.HashMap<string, Widgets.EventRow> event_hashmap;
    public Gee.HashMap <string, Widgets.ItemRow> items_loaded;
    public Gee.ArrayList<Widgets.ItemRow?> items_opened;

    private uint update_events_idle_source = 0;
    private GLib.DateTime date;

    construct {
        items_opened = new Gee.ArrayList<Widgets.ItemRow?> ();
        items_loaded = new Gee.HashMap <string, Widgets.ItemRow> ();

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
        listbox.expand = true;
        listbox.margin_start = 30;
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;
        listbox.margin_top = 6;

        var placeholder_view = new Widgets.Placeholder (
            _("What tasks are on your mind?"),
            _("Tap + to add a task for today."),
            icon_image.icon_name
        );
        placeholder_view.reveal_child = true;

        view_stack = new Gtk.Stack ();
        view_stack.expand = true;
        view_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        view_stack.add_named (listbox, "listbox");
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

        // Check Placeholder view
        Timeout.add (125, () => {
            check_placeholder_view ();

            return false;
        });

        listbox.row_activated.connect ((row) => {
            var item = ((Widgets.ItemRow) row);
            item.reveal_child = true;
        });

        listbox.remove.connect ((row) => {
            check_placeholder_view ();
        });

        Planner.database.add_due_item.connect ((item) => {
            var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
            if (Planner.utils.is_today (datetime) || Planner.utils.is_before_today (datetime)) {
                if (items_loaded.has_key (item.id.to_string ()) == false) {
                    var row = new Widgets.ItemRow (item, "today");

                    items_loaded.set (item.id.to_string (), row);

                    listbox.add (row);
                    listbox.show_all ();

                    check_placeholder_view ();
                }
            }
        });

        Planner.database.remove_due_item.connect ((item) => {
            if (items_loaded.has_key (item.id.to_string ())) {
                items_loaded.get (item.id.to_string ()).hide_destroy ();
                items_loaded.unset (item.id.to_string ());
                check_placeholder_view ();
            }
        });

        Planner.database.update_due_item.connect ((item) => {
            var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());

            if (Planner.utils.is_today (datetime) || Planner.utils.is_before_today (datetime)) {
                if (items_loaded.has_key (item.id.to_string ()) == false) {
                    add_item (item);
                    check_placeholder_view ();
                }
            } else {
                if (items_loaded.has_key (item.id.to_string ())) {
                    items_loaded.get (item.id.to_string ()).hide_destroy ();
                    items_loaded.unset (item.id.to_string ());
                    check_placeholder_view ();
                }
            }
        });

        Planner.database.item_added.connect ((item) => {
            if (item.due_date != "") {
                var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
                if (Planner.utils.is_today (datetime)) {
                    add_item (item);
                    check_placeholder_view ();
                }
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
                    if (Planner.utils.is_today (datetime) || Planner.utils.is_before_today (datetime)) {
                        if (items_loaded.has_key (item.id.to_string ()) == false) {
                            add_item (item);
                            check_placeholder_view ();
                        }
                    }
                }

                return false;
            });
        });

        //  new_item.new_item_hide.connect (() => {
        //      new_item_revealer.reveal_child = false;
        //      check_placeholder_view ();
        //  });

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
                items_opened.add (row);
            }
        });

        Planner.utils.remove_item_show_queue_view.connect ((row, view) => {
            if (view == "today") {
                remove_item_show_queue (row);
            }
        });
    }

    public void add_new_item () {
        var new_item = new Widgets.NewItem (
            Planner.settings.get_int64 ("inbox-project"),
            0,
            Planner.database.get_project_by_id (Planner.settings.get_int64 ("inbox-project")).is_todoist,
            new GLib.DateTime.now_local ().to_string ()
        );

        listbox.add (new_item);
        listbox.show_all ();
        view_stack.visible_child_name = "listbox";
    }

    private void remove_item_show_queue (Widgets.ItemRow row) {
        items_opened.remove (row);
    }

    public void hide_last_item () {
        if (items_opened.size > 0) {
            var last = items_opened [items_opened.size - 1];
            remove_item_show_queue (last);
            last.hide_item ();

            if (items_opened.size > 0) {
                var focus = items_opened [items_opened.size - 1];
                focus.grab_focus ();
                focus.content_entry_focus ();
            }
        }
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

    private void add_item (Objects.Item item) {
        var row = new Widgets.ItemRow (item, "today");

        items_loaded.set (item.id.to_string (), row);

        listbox.add (row);
        listbox.show_all ();
    }

    private void add_all_items () {
        foreach (var item in Planner.database.get_all_today_items ()) {
            var row = new Widgets.ItemRow (item, "today");

            items_loaded.set (item.id.to_string (), row);

            listbox.add (row);
            listbox.show_all ();
        }

        //listbox.set_sort_func (sort_function);
        //listbox.set_header_func (update_headers);
    }

    //  private int sort_function (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
    //      var i1 = ((Widgets.ItemRow) row1).item;
    //      var i2 = ((Widgets.ItemRow) row2).item;

    //      if (i1.project_id < i2.project_id) {
    //          return -1;
    //      } else {
    //          return 1;
    //      }
    //  }

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

    //  private void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
    //      var item = ((Widgets.ItemRow) row).item;
    //      if (before != null) {
    //          var item_before = ((Widgets.ItemRow) before).item;

    //          if (item.project_id == item_before.project_id) {
    //              row.set_header (null);
    //              return;
    //          }

    //          if (item.project_id != item_before.project_id) {
    //              row.set_header (get_header_project (item.project_id));
    //          }
    //      } else {
    //          row.set_header (get_header_project (item.project_id));
    //      }
    //  }
    
    //  public void toggle_new_item () {
    //      if (new_item_revealer.reveal_child) {
    //          new_item_revealer.reveal_child = false;
    //      } else {
    //          new_item_revealer.reveal_child = true;
    //          new_item.entry_grab_focus ();

    //          view_stack.visible_child_name = "listbox";
    //      }
    //  }

    private void check_placeholder_view () {
        if (Planner.database.get_all_today_items ().size > 0) {
            view_stack.visible_child_name = "listbox";
        } else {
            view_stack.visible_child_name = "placeholder";
        }
    }
}
