public class Views.Date : Gtk.EventBox {
    public GLib.DateTime date { get; set; }
    public bool is_today_view { get; construct; }

    private Gtk.ListBox overdue_listbox;
    private Gtk.ListBox listbox;
    private Gtk.ListBox checked_listbox;
    private Gtk.Revealer checked_revealer;
    private Gtk.Stack listbox_stack;
    private Gtk.Revealer main_revealer;
    private Gtk.Revealer overdue_revealer;
    private Gtk.Revealer today_label_revealer;
    private Widgets.Placeholder listbox_placeholder;
    private Widgets.EventsList event_list;

    public Gee.HashMap <string, Layouts.ItemRow> overdue_items;
    public Gee.HashMap <string, Layouts.ItemRow> items;
    public Gee.HashMap <string, Layouts.ItemRow> items_checked;
    private Gee.Map<E.Source, ECal.ClientView> views;

    private Gee.HashMap <string, Objects.Task> tasks_store;    
    public Gee.HashMap <string, Layouts.TaskRow> tasks_map;
    public Gee.HashMap <string, Layouts.TaskRow> overdue_tasks_map;

    private E.SourceRegistry registry;
    private const string QUERY = "AND (NOT is-completed?) (has-start?)";

    private bool overdue_has_children {
        get {
            return overdue_listbox.get_children ().length () > 0;
        }
    }

    private bool has_children {
        get {
            return listbox.get_children ().length () > 0;
        }
    }

    public Date (bool is_today_view = false) {
        Object (
            is_today_view: is_today_view
        );
    }

    construct {
        overdue_items = new Gee.HashMap <string, Layouts.ItemRow> ();
        items = new Gee.HashMap <string, Layouts.ItemRow> ();
        items_checked = new Gee.HashMap <string, Layouts.ItemRow> ();
        views = new Gee.HashMap<E.Source, ECal.ClientView> ();

        tasks_map = new Gee.HashMap <string, Layouts.TaskRow> ();
        overdue_tasks_map = new Gee.HashMap <string, Layouts.TaskRow> ();

        BackendType backend_type = (BackendType) Planner.settings.get_enum ("backend-type");
        if (backend_type == BackendType.CALDAV) {
            try {
                registry = Services.CalDAV.get_default ().get_registry_sync ();
                var sources = registry.list_sources (E.SOURCE_EXTENSION_TASK_LIST);
                sources.foreach ((source) => {
                    add_task_list (source);
                });
            } catch (Error e) {
                warning (e.message);
            }
        }

        event_list = new Widgets.EventsList (is_today_view) {
            margin_start = 20
        };

        var overdue_label = new Gtk.Label (_("Overdue")) {
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_start = 26,
            margin_bottom = 6
        };
        overdue_label.get_style_context ().add_class ("font-bold");
        
        var reschedule_button = new Gtk.Button.with_label (_("Reschedule")) {
            can_focus = false
        };
        reschedule_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        reschedule_button.get_style_context ().add_class ("primary-color");
        reschedule_button.clicked.connect (open_datetime_picker);

        var overdue_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        overdue_box.pack_start (overdue_label, false, true, 0);
        overdue_box.pack_end (reschedule_button, false, true, 0);

        overdue_listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };

        unowned Gtk.StyleContext overdue_listbox_context = overdue_listbox.get_style_context ();
        overdue_listbox_context.add_class ("listbox-background");

        var overdue_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            margin_bottom = 12
        };
        overdue_grid.add (overdue_box);
        overdue_grid.add (overdue_listbox);
        
        overdue_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        overdue_revealer.add (overdue_grid);

        var today_label = new Gtk.Label (_("Today")) {
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_start = 26,
            margin_bottom = 6
        };
        today_label.get_style_context ().add_class ("font-bold");

        today_label_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        today_label_revealer.add (today_label);

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE
        };

        if (!is_today_view) {
            listbox.set_placeholder (get_placeholder ());
        }

        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("listbox-background");

        checked_listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            expand = true
        };

        unowned Gtk.StyleContext checked_listbox_context = checked_listbox.get_style_context ();
        checked_listbox_context.add_class ("listbox-background");

        var checked_listbox_grid = new Gtk.Grid ();
        checked_listbox_grid.add (checked_listbox);

        checked_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };

        checked_revealer.add (checked_listbox_grid);

        var listbox_grid = new Gtk.Grid () {
            valign = Gtk.Align.START,
            orientation = Gtk.Orientation.VERTICAL
        };
        
        listbox_grid.add (listbox);
        listbox_grid.add (checked_revealer);

        listbox_placeholder = new Widgets.Placeholder (
            is_today_view ? _("Today") : _("Scheduled"),
            _("No tasks with this filter at the moment"),
            is_today_view ? "planner-today" : "planner-scheduled");

        listbox_stack = new Gtk.Stack () {
            expand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        listbox_stack.add_named (listbox_grid, "listbox");
        listbox_stack.add_named (listbox_placeholder, "placeholder");
        
        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            expand = true
        };

        main_grid.add (event_list);
        main_grid.add (overdue_revealer);
        main_grid.add (today_label_revealer);
        main_grid.add (listbox_stack);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.add (main_grid);
        
        add (main_revealer);
        
        if (is_today_view) {
            update_date (new GLib.DateTime.now_local ());
        }

        Timeout.add (main_revealer.transition_duration, () => {
            validate_placeholder ();
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        overdue_listbox.add.connect (update_headers);
        overdue_listbox.remove.connect (update_headers);
        listbox.add.connect (update_headers);
        listbox.remove.connect (update_headers);

        Planner.database.item_added.connect (valid_add_item);
        Planner.database.item_deleted.connect (valid_delete_item);
        Planner.database.item_updated.connect (valid_update_item);
        Planner.event_bus.item_moved.connect ((item) => {
            if (items.has_key (item.id_string)) {
                items[item.id_string].update_request ();
            }

            if (overdue_items.has_key (item.id_string)) {
                items[item.id_string].update_request ();
            }
        });

        listbox.add.connect (validate_placeholder);
        listbox.remove.connect (validate_placeholder);
        overdue_listbox.add.connect (validate_placeholder);
        overdue_listbox.remove.connect (validate_placeholder);

        //  Planner.settings.changed.connect ((key) => {
        //      if (key == "show-today-completed") {
        //          show_completed_changed ();
        //      }
        //  });
    }

    private void show_completed_changed () {
        if (Planner.settings.get_boolean ("show-today-completed")) {
            add_completed_items ();
        } else {
            items_checked.clear ();

            foreach (unowned Gtk.Widget child in checked_listbox.get_children ()) {
                child.destroy ();
            }
        }

        // checked_revealer.reveal_child = section.project.show_completed;
    }

    private void add_completed_items () {
        items_checked.clear ();

        foreach (unowned Gtk.Widget child in checked_listbox.get_children ()) {
            child.destroy ();
        }

        foreach (Objects.Item item in Planner.database.get_items_by_date (new GLib.DateTime.now_local (), true)) {
            if (item.completed) {
                add_complete_item (item);
            }
        }

        checked_revealer.reveal_child = Planner.settings.get_boolean ("show-today-completed");
    }

    public void add_complete_item (Objects.Item item) {
        if (Planner.settings.get_boolean ("show-today-completed") && item.checked) {
            if (!items_checked.has_key (item.id_string)) {
                items_checked [item.id_string] = new Layouts.ItemRow (item);
                checked_listbox.add (items_checked [item.id_string]);
                checked_listbox.show_all ();
            }
        }
    }

    private void open_datetime_picker () {
        var datetime_picker = new Dialogs.DateTimePicker.DateTimePicker ();
        datetime_picker.popup ();

        datetime_picker.date_changed.connect (() => {
            set_datetime (datetime_picker.datetime);
        });
    }
    
    public void set_datetime (GLib.DateTime? date) {
        //  foreach (string key in overdue_items.keys) {
        //      print ("Item: %s\n".printf (key));
        //      //  if (overdue_items.has_key (key)) {
        //      //      overdue_items[key].update_due (date);
        //      //  }            
        //  }

        foreach (unowned Gtk.Widget child in overdue_listbox.get_children ()) {
            ((Layouts.ItemRow) child).update_due (date);
        }
    }

    public void update_date (GLib.DateTime newDate) {
        date = newDate;
        event_list.date = date;

        if (is_today_view) {
            add_today_items ();
            // show_completed_changed ();
        } else {
            listbox_placeholder.title = Util.get_default ().get_relative_date_from_date (
                Util.get_default ().get_format_date (date));
            add_items (date);
        }
    }

    private void validate_placeholder () {
        if (is_today_view) {
            listbox_stack.visible_child_name = overdue_has_children || has_children ? "listbox" : "placeholder";
        } else {
            listbox_stack.visible_child_name = has_children ? "listbox" : "placeholder";
        }
    }

    private void valid_add_item (Objects.Item item, bool insert = true) {
        if (!items.has_key (item.id_string) &&
            Planner.database.valid_item_by_date (item, date, false)) {
            add_item (item);   
        }

        if (is_today_view && !overdue_items.has_key (item.id_string) &&
            Planner.database.valid_item_by_overdue (item, date, false)) {
            add_overdue_item (item);
        }
    }

    private void valid_add_task (ECal.Component task) {
        GLib.DateTime date_now = new GLib.DateTime.now_local ();
        GLib.DateTime datetime = CalDAVUtil.ical_to_date_time_local (
            task.get_icalcomponent ().get_due ()
        );

        if (!tasks_map.has_key (task.get_icalcomponent ().get_uid ()) &&
            Granite.DateTime.is_same_day (datetime, date)) {
            add_task (tasks_store[task.get_icalcomponent ().get_uid ()]);
        }

        if (!overdue_tasks_map.has_key (task.get_icalcomponent ().get_uid ()) &&
            datetime.compare (date_now) < 0 &&
            !Granite.DateTime.is_same_day (datetime, date_now)) {
            add_overdue_task (tasks_store[task.get_icalcomponent ().get_uid ()]);
        }
    }
    
    private void valid_delete_item (Objects.Item item) {
        if (items.has_key (item.id_string)) {
            items[item.id_string].hide_destroy ();
            items.unset (item.id_string);
        }

        if (overdue_items.has_key (item.id_string)) {
            overdue_items[item.id_string].hide_destroy ();
            overdue_items.unset (item.id_string);
        }
    }

    private void valid_update_item (Objects.Item item) {
        if (items.has_key (item.id_string)) {
            items[item.id_string].update_request ();
        }

        if (overdue_items.has_key (item.id_string)) {
            overdue_items[item.id_string].update_request ();
        }

        if (items.has_key (item.id_string) && !item.has_due) {
            items[item.id_string].hide_destroy ();
            items.unset (item.id_string);
        }

        if (overdue_items.has_key (item.id_string) && !item.has_due) {
            overdue_items[item.id_string].hide_destroy ();
            overdue_items.unset (item.id_string);
        }

        if (items.has_key (item.id_string) && item.has_due) {
            if (!Planner.database.valid_item_by_date (item, date, false)) {
                items[item.id_string].hide_destroy ();
                items.unset (item.id_string);
            }
        }

        if (overdue_items.has_key (item.id_string) && item.has_due) {
            if (!Planner.database.valid_item_by_overdue (item, date, false)) {
                overdue_items[item.id_string].hide_destroy ();
                overdue_items.unset (item.id_string);
            }
        }

        if (item.has_due) {
            valid_add_item (item);
        }
    }

    private void add_items (GLib.DateTime date) {
        items.clear ();
        tasks_map.clear ();

        foreach (unowned Gtk.Widget child in listbox.get_children ()) {
            child.destroy ();
        }

        BackendType backend_type = (BackendType) Planner.settings.get_enum ("backend-type");
        if (backend_type == BackendType.LOCAL || backend_type == BackendType.TODOIST) {
            foreach (Objects.Item item in Planner.database.get_items_by_date (date, false)) {
                add_item (item);
            }
        } else if (backend_type == BackendType.CALDAV) {
            foreach (Objects.Task task in tasks_store.values) {
                add_task (task);
            }
        }
    }

    private void add_today_items () {
        items.clear ();
        tasks_map.clear ();

        foreach (unowned Gtk.Widget child in listbox.get_children ()) {
            child.destroy ();
        }

        BackendType backend_type = (BackendType) Planner.settings.get_enum ("backend-type");
        if (backend_type == BackendType.LOCAL || backend_type == BackendType.TODOIST) {
            foreach (Objects.Item item in Planner.database.get_items_by_date (date, false)) {
                add_item (item);
            }
    
            overdue_items.clear ();
    
            foreach (unowned Gtk.Widget child in overdue_listbox.get_children ()) {
                child.destroy ();
            }
    
            foreach (Objects.Item item in Planner.database.get_items_by_overdeue_view (false)) {
                add_overdue_item (item);
            }
    
            update_headers ();
        } else if (backend_type == BackendType.CALDAV) {
            foreach (Objects.Task task in tasks_store.values) {
                add_task (task);
            }

            overdue_tasks_map.clear ();

            foreach (unowned Gtk.Widget child in overdue_listbox.get_children ()) {
                child.destroy ();
            }

            foreach (Objects.Task task in tasks_store.values) {
                add_overdue_task (task);
            }
            
            update_headers ();
        }
    }

    private void update_headers () {
        overdue_revealer.reveal_child = is_today_view && overdue_has_children;
        today_label_revealer.reveal_child = overdue_revealer.reveal_child && has_children;
    }

    private void add_item (Objects.Item item) {
        items [item.id_string] = new Layouts.ItemRow (item);
        listbox.add (items [item.id_string]);
        listbox.show_all ();
    }

    private void add_task (Objects.Task task) {
        if (tasks_map.has_key (task.task.get_icalcomponent ().get_uid ())) {
            return;
        }

        GLib.DateTime datetime = CalDAVUtil.ical_to_date_time_local (
            task.task.get_icalcomponent ().get_due ()
        );

        if (Granite.DateTime.is_same_day (datetime, date)) {
            tasks_map [task.task.get_icalcomponent ().get_uid ()] = new Layouts.TaskRow.for_component (task.task, task.source);
            listbox.add (tasks_map [task.task.get_icalcomponent ().get_uid ()]);
            listbox.show_all ();
        }
    }

    private void add_overdue_task (Objects.Task task) {
        GLib.DateTime date_now = new GLib.DateTime.now_local ();
        GLib.DateTime datetime = CalDAVUtil.ical_to_date_time_local (
            task.task.get_icalcomponent ().get_due ()
        );

        if (datetime.compare (date_now) < 0 &&
            !Granite.DateTime.is_same_day (datetime, date_now)) {
            overdue_tasks_map [task.task.get_icalcomponent ().get_uid ()] = new Layouts.TaskRow.for_component (task.task, task.source);
            overdue_listbox.add (overdue_tasks_map [task.task.get_icalcomponent ().get_uid ()]);
            overdue_listbox.show_all ();
        }
    }

    private void add_overdue_item (Objects.Item item) {
        overdue_items [item.id_string] = new Layouts.ItemRow (item);
        overdue_listbox.add (overdue_items [item.id_string]);
        overdue_listbox.show_all ();
    }

    private Gtk.Widget get_placeholder () {
        var calendar_image = new Widgets.DynamicIcon () {
            opacity = 0.1
        };
        calendar_image.size = 96;

        calendar_image.update_icon_name ("planner-calendar");
        if (is_today_view) {
            calendar_image.update_icon_name ("planner-star");
        }

        var grid = new Gtk.Grid () {
            margin_top = 128,
            halign = Gtk.Align.CENTER
        };
        grid.add (calendar_image);
        grid.show_all ();

        return grid;
    }

    public void prepare_new_item (string content = "") {
        BackendType backend_type = (BackendType) Planner.settings.get_enum ("backend-type");
        if (backend_type == BackendType.LOCAL || backend_type == BackendType.TODOIST) {
            Planner.event_bus.item_selected (null);

            var row = new Layouts.ItemRow.for_project (
                Planner.database.get_project (Planner.settings.get_int64 ("inbox-project-id"))
            );
            
            row.update_due (Util.get_default ().get_format_date (date));
            row.update_content (content);
            row.update_priority (Util.get_default ().get_default_priority ());

            row.item_added.connect (() => {
                item_added (row);
            });
    
            listbox.add (row);
            listbox.show_all ();
        } else if (backend_type == BackendType.CALDAV) {
            try {
                var registry = Services.CalDAV.get_default ().get_registry_sync ();

                var row = new Layouts.TaskRow.for_source (registry.default_task_list);

                row.update_due (Util.get_default ().get_format_date (date));
                row.update_content (content);
                row.update_priority (Util.get_default ().get_default_priority ());

                listbox.add (row);
                listbox.show_all ();
            } catch (Error e) {
                warning (e.message);
            }
        }
    }

    private void item_added (Layouts.ItemRow row) {
        bool insert = true;
        if (row.item.has_due) {
            insert = !Util.get_default ().is_same_day (date, row.item.due.datetime);
        }

        if (!insert) {
            valid_add_itemrow (row);
            row.update_inserted_item ();
        }

        if (row.item.section_id != Constants.INACTIVE) {
            Planner.database.get_section (row.item.section_id)
                .add_item_if_not_exists (row.item);
        } else {
            Planner.database.get_project (row.item.project_id)
                .add_item_if_not_exists (row.item);
        }

        if (insert) {
            row.hide_destroy ();
        }
    }

    private void valid_add_itemrow (Layouts.ItemRow row) {
        if (is_today_view) {
            if (!items.has_key (row.item.id_string) &&
                Planner.database.valid_item_by_date (row.item, date, false)) {
                items [row.item.id_string] = row;
                listbox.add (items [row.item.id_string]);
                listbox.show_all (); 
            }

            if (is_today_view && !overdue_items.has_key (row.item.id_string) &&
                Planner.database.valid_item_by_overdue (row.item, date, false)) {
                overdue_items [row.item.id_string] = row;
                overdue_listbox.add (overdue_items [row.item.id_string]);
                overdue_listbox.show_all ();
            }
        } else {
            if (!items.has_key (row.item.id_string)) {
                items [row.item.id_string] = row;
                listbox.add (items [row.item.id_string]);
                listbox.show_all ();
            }
        } 
    }

    private void add_task_list (E.Source task_list) {
        if (!task_list.has_extension (E.SOURCE_EXTENSION_TASK_LIST)) {
            return;
        }

        E.SourceTaskList list = (E.SourceTaskList) task_list.get_extension (E.SOURCE_EXTENSION_TASK_LIST);

        if (list.selected == true && task_list.enabled == true && !task_list.has_extension (E.SOURCE_EXTENSION_COLLECTION)) {
            add_view (task_list, QUERY);
        }
    }

    private void add_view (E.Source source, string query) {
        try {
            var view = Services.CalDAV.get_default ().create_task_list_view (
                source,
                query,
                on_tasks_added,
                on_tasks_modified,
                on_tasks_removed
            );

            lock (views) {
                views.set (source, view);
            }

        } catch (Error e) {
            critical (e.message);
        }
    }

    private void on_tasks_added (Gee.Collection<ECal.Component> tasks, E.Source source) {
        if (tasks_store == null) {
            tasks_store = new Gee.HashMap <string, Objects.Task> ();
        }

        foreach (ECal.Component task in tasks) {
            if (task != null && !tasks_store.has_key (task.get_icalcomponent ().get_uid ())) {
                tasks_store[task.get_icalcomponent ().get_uid ()] = new Objects.Task (task, source);
            }
        }

        Layouts.TaskRow task_row = null;
        var row_index = 0;

        if (tasks_map == null) {
            tasks_map = new Gee.HashMap <string, Layouts.TaskRow> ();
        }
        
        do {
            task_row = (Layouts.TaskRow) listbox.get_row_at_index (row_index);

            if (task_row != null) {
                foreach (ECal.Component task in tasks) {
                    string uid = task.get_icalcomponent ().get_uid ();
                    if (CalDAVUtil.calcomponent_equal_func (task_row.task, task) && !task_row.created) {
                        task_row.task = task;
                        tasks_map[uid] = task_row;
                        task_row.edit = false;

                        break;
                    }
                }
            }

            row_index++;
        } while (task_row != null);

        foreach (ECal.Component task in tasks) {
            add_task (new Objects.Task (task, source));

            if (is_today_view) {
                add_overdue_task (new Objects.Task (task, source));
            }
        }
    }

    private void on_tasks_modified (Gee.Collection<ECal.Component> tasks) {
        foreach (ECal.Component task in tasks) {
            if (task != null && tasks_store.has_key (task.get_icalcomponent ().get_uid ())) {
                tasks_store[task.get_icalcomponent ().get_uid ()].task = task;
            }

            if (tasks_map.has_key (task.get_icalcomponent ().get_uid ())) {
                tasks_map[task.get_icalcomponent ().get_uid ()].task = task;
            }

            if (overdue_tasks_map.has_key (task.get_icalcomponent ().get_uid ())) {
                overdue_tasks_map[task.get_icalcomponent ().get_uid ()].task = task;
            }

            //  if (tasks_map.has_key (task.get_icalcomponent ().get_uid ()) &&
            //      task.get_icalcomponent ().get_due ().is_null_time ()) {
            //      tasks_map[task.get_icalcomponent ().get_uid ()].hide_destroy ();
            //      tasks_map.unset (task.get_icalcomponent ().get_uid ());
            //  }
    
            //  if (overdue_tasks_map.has_key (task.get_icalcomponent ().get_uid ()) &&
            //      task.get_icalcomponent ().get_due ().is_null_time ()) {
            //      overdue_tasks_map[task.get_icalcomponent ().get_uid ()].hide_destroy ();
            //      overdue_tasks_map.unset (task.get_icalcomponent ().get_uid ());
            //  }

            if (tasks_map.has_key (task.get_icalcomponent ().get_uid ()) &&
                !task.get_icalcomponent ().get_due ().is_null_time ()) {
                GLib.DateTime datetime = CalDAVUtil.ical_to_date_time_local (
                    task.get_icalcomponent ().get_due ()
                );
        
                if (!Granite.DateTime.is_same_day (datetime, date)) {
                    tasks_map [task.get_icalcomponent ().get_uid ()].hide_destroy ();
                    tasks_map.unset (task.get_icalcomponent ().get_uid ());
                }
            }
    
            if (overdue_tasks_map.has_key (task.get_icalcomponent ().get_uid ()) &&
                !task.get_icalcomponent ().get_due ().is_null_time ()) {
                GLib.DateTime date_now = new GLib.DateTime.now_local ();
                GLib.DateTime datetime = CalDAVUtil.ical_to_date_time_local (
                    task.get_icalcomponent ().get_due ()
                );

                if (!(datetime.compare (date_now) < 0 &&
                    !Granite.DateTime.is_same_day (datetime, date_now))) {
                    overdue_tasks_map[task.get_icalcomponent ().get_uid ()].hide_destroy ();
                    overdue_tasks_map.unset (task.get_icalcomponent ().get_uid ());
                }
            }

            if (!task.get_icalcomponent ().get_due ().is_null_time ()) {
                valid_add_task (task);
            }
        }
    }

    private void on_tasks_removed (SList<ECal.ComponentId?> cids) {
        foreach (unowned ECal.ComponentId cid in cids) {
            if (cid == null) {
                continue;
            } else if (tasks_store.has_key (cid.get_uid ())) {
                tasks_store.unset (cid.get_uid ());
                break;
            }
        }

        foreach (unowned ECal.ComponentId cid in cids) {
            if (tasks_map.has_key (cid.get_uid ())) {
                tasks_map[cid.get_uid ()].hide_destroy ();
                tasks_map.unset (cid.get_uid ());
            }

            if (overdue_tasks_map.has_key (cid.get_uid ())) {
                overdue_tasks_map[cid.get_uid ()].hide_destroy ();
                overdue_tasks_map.unset (cid.get_uid ());
            }
        }
    }
}
