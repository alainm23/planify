public class MainWindow : Gtk.Window {
    private Gtk.Entry content_entry;
    private Gtk.TextView note_textview;

    private DBusClient dbus_client;
    private Gtk.ComboBox project_combobox;   
    private Gtk.ListStore list_store;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            resizable: false,
            width_request: 700,
            height_request: 335,
            window_position: Gtk.WindowPosition.CENTER,
            margin_bottom: 192
        );
    }

    construct {
        dbus_client = DBusClient.get_default ();

        var headerbar = new Gtk.HeaderBar ();
        headerbar.has_subtitle = false;
        headerbar.set_show_close_button (true);
        headerbar.decoration_layout = ":";

        unowned Gtk.StyleContext headerbar_style_context = headerbar.get_style_context ();
        headerbar_style_context.add_class (Gtk.STYLE_CLASS_FLAT);

        var checked_button = new Gtk.CheckButton ();
        checked_button.can_focus = false;
        checked_button.valign = Gtk.Align.CENTER;
        checked_button.halign = Gtk.Align.BASELINE;
        checked_button.get_style_context ().add_class ("checklist-button");

        content_entry = new Gtk.Entry ();
        content_entry.margin_bottom = 1;
        content_entry.placeholder_text = _("Task name");
        content_entry.get_style_context ().add_class ("flat");
        content_entry.get_style_context ().add_class ("label");
        content_entry.get_style_context ().add_class ("content-entry");
        content_entry.hexpand = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        top_box.margin_start = 18;
        top_box.margin_end = 6;
        top_box.hexpand = true;
        top_box.pack_start (checked_button, false, false, 0);
        top_box.pack_start (content_entry, false, true, 0);

        note_textview = new Gtk.TextView ();
        note_textview.expand = true;
        note_textview.margin_start = 42;
        note_textview.margin_bottom = 12;
        note_textview.margin_end = 6;
        note_textview.wrap_mode = Gtk.WrapMode.WORD;
        note_textview.get_style_context ().add_class ("textview");
        //note_textview.height_request = 42;

        var textview_scrolled = new Gtk.ScrolledWindow (null, null);
        textview_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        textview_scrolled.expand = true;
        textview_scrolled.add (note_textview);

        var note_placeholder = new Gtk.Label (_("Add note"));
        note_placeholder.opacity = 0.7;
        note_textview.add (note_placeholder);

        note_textview.focus_in_event.connect (() => {
            note_placeholder.visible = false;
            note_placeholder.no_show_all = true;

            return false;
        });

        note_textview.focus_out_event.connect (() => {
            if (note_textview.buffer.text == "") {
                note_placeholder.visible = true;
                note_placeholder.no_show_all = false;
            }

            return false;
        });

        var submit_button = new Gtk.Button ();
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var submit_spinner = new Gtk.Spinner ();
        submit_spinner.start ();

        var submit_stack = new Gtk.Stack ();
        submit_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        
        submit_stack.add_named (new Gtk.Label (_("Save")), "label");
        submit_stack.add_named (submit_spinner, "spinner");

        submit_button.add (submit_stack);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));

        var action_grid = new Gtk.Grid ();
        action_grid.margin = 6;
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 6;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);
        
        list_store = new Gtk.ListStore (3, typeof (Project), typeof (string), typeof (string));
        project_combobox = new Gtk.ComboBox.with_model (list_store);
        project_combobox.can_focus = false;
        project_combobox.get_style_context ().add_class ("quick-add-combobox");
        project_combobox.margin = 6;
        project_combobox.valign = Gtk.Align.CENTER;

        Gtk.TreeIter iter;
        string icon_name;
        foreach (var project in PlannerQuickAdd.database.get_all_projects ()) {
            list_store.append (out iter);

            if (project.inbox_project == 1) {
                icon_name = "mail-mailbox-symbolic";
            } else {
                icon_name = "planner-project-symbolic";
            }

            list_store.@set (iter, 
                0, project, 
                1, " " + project.name, 
                2, icon_name
            );

            if (PlannerQuickAdd.settings.get_boolean ("quick-add-save-last-project") == true && PlannerQuickAdd.settings.get_int64 ("quick-add-project-selected") == 0) {
                if (project.inbox_project == 1) {
                    project_combobox.set_active_iter (iter);
                }
            }

            if (PlannerQuickAdd.settings.get_boolean ("quick-add-save-last-project") == false && project.inbox_project == 1) {
                project_combobox.set_active_iter (iter);
            }

            if (PlannerQuickAdd.settings.get_boolean ("quick-add-save-last-project") == true && PlannerQuickAdd.settings.get_int64 ("quick-add-project-selected") == project.id) {
                project_combobox.set_active_iter (iter);
            }
        }

        var pixbuf_cell = new Gtk.CellRendererPixbuf ();
        project_combobox.pack_start (pixbuf_cell, false);
        project_combobox.add_attribute (pixbuf_cell, "icon-name", 2);

        var text_cell = new Gtk.CellRendererText ();
        project_combobox.pack_start (text_cell, true);
        project_combobox.add_attribute (text_cell, "text", 1);

        project_combobox.changed.connect (() => {
            var project = get_selected_project ();
            if (project != null) {
                PlannerQuickAdd.settings.set_int64 ("quick-add-project-selected", project.id);
            }
        });

        var action_bar = new Gtk.ActionBar ();
        action_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        action_bar.pack_start (project_combobox);
        action_bar.pack_end (action_grid);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (textview_scrolled, false, true, 0);
        main_box.pack_end (action_bar, false, false, 0);
        
        add (main_box);
        
        get_style_context ().add_class ("rounded");
        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        set_titlebar (headerbar);
        skip_taskbar_hint = true;

        cancel_button.clicked.connect (() => {
            hide ();
            /* Retain the window for a short time so that the keybinding
             * listener does not instantiate a new one right after closing
            */
            Timeout.add (500, () => {
                destroy ();
                return false;
            });
        });

        content_entry.changed.connect (() => {
            submit_button.sensitive = content_entry.text != "";
        });

        submit_button.clicked.connect (add_item);
        content_entry.activate.connect (add_item);

        PlannerQuickAdd.database.item_added_started.connect (() => {
            sensitive = false;
            submit_stack.visible_child_name = "spinner";
        });

        PlannerQuickAdd.database.item_added_completed.connect (() => {
            sensitive = true;
            submit_stack.visible_child_name = "label";
        });

        PlannerQuickAdd.database.item_added_error.connect ((http_code, error_message) => {

        });

        PlannerQuickAdd.database.item_added.connect ((item) => {
            hide ();

            send_notification (item.content, _("The task was correctly added."));

            content_entry.text = "";
            note_textview.buffer.text = "";

            content_entry.grab_focus ();

            try {
                dbus_client.interface.add_item (item.id);
            } catch (Error e) {
                debug (e.message);
            }

            Timeout.add (500, () => {
                destroy ();
                return false;
            });
        });

        focus_out_event.connect ((event) => {
            if (Posix.isatty (Posix.STDIN_FILENO) == false && project_combobox.popup_shown == false && PlannerQuickAdd.database.is_adding == false) {
                hide ();
            
                Timeout.add (500, () => {
                    destroy ();
                    return false;
                });
            }

            return Gdk.EVENT_STOP;
        });
    }

    private void add_item () {
        if (content_entry.text != "" && get_selected_project () != null) {
            var project = get_selected_project ();

            var item = new Item ();
            item.id = generate_id ();
            item.project_id = project.id;
            item.content = content_entry.text;
            item.note = note_textview.buffer.text;
            item.is_todoist = project.is_todoist;

            if (project.inbox_project == 1) {
                if (PlannerQuickAdd.settings.get_boolean ("inbox-project-sync")) {
                    PlannerQuickAdd.database.add_todoist_item (item);       
                } else {
                    PlannerQuickAdd.database.insert_item (item);
                }
            } else {
                if (project.is_todoist == 0) {
                    PlannerQuickAdd.database.insert_item (item);
                } else {
                    PlannerQuickAdd.database.add_todoist_item (item);
                }
            }
        }
    }

    public Project? get_selected_project () {
        Gtk.TreeIter iter;
        if (!project_combobox.get_active_iter (out iter)) {
            return null;
        }

        Value item;
        list_store.get_value (iter, 0, out item);

        return (Project) item;
    }

    public int64 generate_id (int len=10) {
        string allowed_characters = "0123456789";

        var password_builder = new StringBuilder ();
        for (var i = 0; i < len; i++) {
            var random_index = Random.int_range (0, allowed_characters.length);
            password_builder.append_c (allowed_characters[random_index]);
        }

        if (int64.parse (password_builder.str) <= 0) {
            return generate_id ();
        }
        
        return int64.parse (password_builder.str);
    }

    private void send_notification (string title, string body) {
        var notification = new Notification (title);
        notification.set_body (body);
        notification.set_icon (new ThemedIcon ("com.github.alainm23.planner"));
        notification.set_priority (GLib.NotificationPriority.LOW);

        application.send_notification ("com.github.alainm23.planner", notification);
    }
}