public class Views.Today : Gtk.EventBox {
    private Gtk.ListBox listbox;
    private Gtk.ListBox event_listbox;
    private Gee.HashMap<string, bool> items_loaded;
    private Gtk.Revealer new_item_revealer;
    private Widgets.NewItem new_item;

    private Gtk.Box main_box;

    private Gee.HashMap<string, Widgets.EventRow> event_hashmap;
    private uint update_events_idle_source = 0;
    private GLib.DateTime date;

    construct {
        items_loaded = new Gee.HashMap<string, bool> ();

        var icon_image = new Gtk.Image ();
        icon_image.valign = Gtk.Align.CENTER;
        icon_image.pixel_size = 21; 

        var hour = new GLib.DateTime.now_local ().get_hour ();
        if (hour >= 18 || hour <= 6) {
            icon_image.gicon = new ThemedIcon ("planner-today-night-symbolic");
            icon_image.get_style_context ().add_class ("today-night-icon");
        } else {
            icon_image.gicon = new ThemedIcon ("planner-today-day-symbolic");
            icon_image.get_style_context ().add_class ("today-day-icon");
        }

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Today")));
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        //title_label.get_style_context ().add_class ("today");
        title_label.use_markup = true;

        var date_label = new Gtk.Label (new GLib.DateTime.now_local ().format (Granite.DateTime.get_default_date_format (false, true, false)));
        date_label.valign = Gtk.Align.CENTER;
        date_label.margin_top = 6;
        date_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_start = 41;
        top_box.margin_end = 24;

        top_box.pack_start (icon_image, false, false, 0);
        top_box.pack_start (title_label, false, false, 6);
        top_box.pack_start (date_label, false, false, 0);

        listbox = new Gtk.ListBox  ();
        listbox.valign = Gtk.Align.START;
        listbox.get_style_context ().add_class ("welcome");
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;
        
        int is_todoist = 0;
        if (Application.settings.get_boolean ("inbox-project-sync")) {
            is_todoist = 1;
        }

        new_item = new Widgets.NewItem (
            Application.settings.get_int64 ("inbox-project"),
            0, 
            is_todoist
        );
        new_item.margin_top = 12;

        new_item_revealer = new Gtk.Revealer ();
        new_item_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        new_item_revealer.add (new_item);

        event_listbox = new Gtk.ListBox ();
        event_listbox.margin_top = 6;
        event_listbox.valign = Gtk.Align.START;
        event_listbox.get_style_context ().add_class ("welcome");
        event_listbox.get_style_context ().add_class ("listbox");
        event_listbox.activate_on_single_click = true;
        event_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        event_listbox.hexpand = true;
        event_listbox.set_sort_func (sort_event_function);

        var event_revealer = new Gtk.Revealer ();
        event_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        event_revealer.add (event_listbox);
        event_revealer.reveal_child = Application.settings.get_boolean ("calendar-enabled");

        main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (event_revealer, false, false, 0);
        main_box.pack_start (new_item_revealer, false, false, 0);
        main_box.pack_start (listbox, false, false, 0);

        var main_scrolled = new Gtk.ScrolledWindow (null, null);
        main_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        main_scrolled.expand = true;
        main_scrolled.add (main_box);

        add (main_scrolled);
        add_all_items ();
        
        show_all ();
        
        listbox.row_activated.connect ((row) => {
            var item = ((Widgets.ItemRow) row);
            item.reveal_child = true;
        });

        Application.database.add_due_item.connect ((item) => {
            var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
            if (Application.utils.is_today (datetime) || Application.utils.is_before_today (datetime)) {
                if (items_loaded.has_key (item.id.to_string ()) == false) {
                    var row = new Widgets.ItemRow (item);
            
                    row.is_today = true;
                    items_loaded.set (item.id.to_string (), true);
        
                    listbox.add (row);
                    listbox.show_all ();
                }
            }
        });

        Application.database.remove_due_item.connect ((item) => {
            if (items_loaded.has_key (item.id.to_string ())) {
                items_loaded.unset (item.id.to_string ());
            }
        });

        Application.database.update_due_item.connect ((item) => {
            var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());

            if (Application.utils.is_today (datetime) || Application.utils.is_before_today (datetime)) {
                if (items_loaded.has_key (item.id.to_string ()) == false) {
                    add_item (item);
                }
            } else {
                if (items_loaded.has_key (item.id.to_string ())) {
                    items_loaded.unset (item.id.to_string ());
                }
            }
        });

        Application.database.item_added.connect ((item) => {
            if (item.due_date != "") {
                var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
                if (Application.utils.is_today (datetime)) {
                    add_item (item);
                }
            }
        });

        Application.database.item_completed.connect ((item) => {
            if (item.checked == 0 && item.due_date != "") {
                var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
                if (Application.utils.is_today (datetime) || Application.utils.is_before_today (datetime)) {
                    if (items_loaded.has_key (item.id.to_string ()) == false) {
                        add_item (item);
                    }
                }
            } else {
                if (items_loaded.has_key (item.id.to_string ())) {
                    items_loaded.unset (item.id.to_string ());
                }
            }
        });

        new_item.new_item_hide.connect (() => {
            new_item_revealer.reveal_child = false;
        });

        date = new GLib.DateTime.now_local ();
        event_hashmap = new Gee.HashMap<string, Widgets.EventRow> ();
        Application.calendar_model.month_start = Util.get_start_of_month ();

        Application.calendar_model.events_added.connect (add_event_model);
        Application.calendar_model.events_removed.connect (remove_event_model);

        idle_update_events ();

        Application.settings.changed.connect ((key) => {
            if (key == "calendar-enabled") {
                event_revealer.reveal_child = Application.settings.get_boolean ("calendar-enabled");
            }
        });
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
        Application.calendar_model.source_events.@foreach ((source, component_map) => {
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
                event_hashmap.remove (event_uid);
            }
        }
    }

    private void add_item (Objects.Item item) {
        var row = new Widgets.ItemRow (item);
            
        row.is_today = true;
        items_loaded.set (item.id.to_string (), true);

        listbox.add (row);
        listbox.show_all ();
    }

    private void add_all_items () {
        foreach (var item in Application.database.get_all_today_items ()) {
            var row = new Widgets.ItemRow (item);
            
            row.is_today = true;
            items_loaded.set (item.id.to_string (), true);

            listbox.add (row);
            listbox.show_all ();
        }

        listbox.set_sort_func (sort_function);
        listbox.set_header_func (update_headers);
    }

    private int sort_function (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
        var i1 = ((Widgets.ItemRow) row1).item;
        var i2 = ((Widgets.ItemRow) row2).item;
        
        if (i1.project_id < i2.project_id) {
            return -1;
        } else {
            return 1;
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
    
    private void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
        var item = ((Widgets.ItemRow) row).item;
        if (before != null) {
            var item_before = ((Widgets.ItemRow) before).item;

            if (item.project_id == item_before.project_id) {
                row.set_header (null);
                return;
            }

            if (item.project_id != item_before.project_id) {
                row.set_header (get_header_project (item.project_id));
            }
        } else {
            row.set_header (get_header_project (item.project_id));
        }
    }

    private Gtk.Widget get_header_project (int64 id) {
        var project = Application.database.get_project_by_id (id);

        var name_label =  new Gtk.Label (project.name);
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("header-title");
        name_label.valign = Gtk.Align.CENTER;
        name_label.set_ellipsize (Pango.EllipsizeMode.END);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_top = 3;

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.margin_top = 12;
        main_box.margin_start = 41;
        main_box.margin_bottom = 6;
        main_box.margin_end = 32;
        main_box.hexpand = true;
        main_box.pack_start (name_label, false, false, 0);
        main_box.pack_start (separator, false, false, 0);
        main_box.show_all ();

        return main_box;
    }

    public void toggle_new_item () {
        if (new_item_revealer.reveal_child) {
            new_item_revealer.reveal_child = false;
        } else {
            new_item.due = new GLib.DateTime.now_local ().to_string ();
            new_item_revealer.reveal_child = true;
            new_item.entry_grab_focus ();
        }
    }
} 