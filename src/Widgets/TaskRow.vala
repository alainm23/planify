public class Widgets.TaskRow : Gtk.ListBoxRow {
    public Objects.Task task { get; construct; }

    private Gtk.CheckButton checked_button;
    private Gtk.Label name_label;
    private Gtk.Entry name_entry;
    private Gtk.Button close_button;
    private Gtk.Button remove_button;
    private Gtk.TextView note_view;
    private Gtk.Revealer bottom_box_revealer;
    private Gtk.Grid main_grid;
    private Gtk.EventBox name_eventbox;

    private Gtk.ListBox checklist;

    private Gtk.Box top_box;
    private Gtk.Revealer remove_revealer;
    private Gtk.Revealer close_revealer;

    public TaskRow (Objects.Task _task) {
        Object (
            task: _task,
            margin_start: 3,
            margin_end: 24,
            margin_top: 3,
            margin_bottom: 3
        );
    }

    construct {
        get_style_context ().add_class ("task");

        checked_button = new Gtk.CheckButton ();

        if (task.checked == 1) {
            checked_button.active = true;
        } else {
            checked_button.active = false;
        }

        name_label = new Gtk.Label (task.content);
        name_label.halign = Gtk.Align.START;
        name_label.use_markup = true;
        name_label.margin_bottom = 1;
        name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        name_eventbox = new Gtk.EventBox ();
        name_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        name_eventbox.add (name_label);

        name_entry = new Gtk.Entry ();
        name_entry.text = task.content;
        name_entry.hexpand = true;
        name_entry.margin_bottom = 1;
        name_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        name_entry.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        name_entry.get_style_context ().add_class ("planner-entry");
        name_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        name_entry.no_show_all = true;

        var checklist_preview = new Gtk.Grid ();
        checklist_preview.column_spacing = 6;
        checklist_preview.get_style_context ().add_class ("button");
        checklist_preview.get_style_context ().add_class ("checklist-preview");
        var checklist_label = new Gtk.Label ("4/10");

        checklist_preview.add (new Gtk.Image.from_icon_name ("format-justify-fill-symbolic", Gtk.IconSize.MENU));
        checklist_preview.add (checklist_label);

        close_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.MENU);
        close_button.height_request = 24;
        close_button.width_request = 24;
        close_button.get_style_context ().add_class ("button-overlay-circular");
        close_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        remove_button = new Gtk.Button.from_icon_name ("user-trash-symbolic", Gtk.IconSize.MENU);
        remove_button.height_request = 24;
        remove_button.width_request = 24;
        remove_button.get_style_context ().add_class ("button-overlay-circular");
        remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        close_revealer = new Gtk.Revealer ();
        close_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        close_revealer.add (close_button);
        close_revealer.reveal_child = false;
        close_revealer.valign = Gtk.Align.START;
        close_revealer.halign = Gtk.Align.END;

        remove_revealer = new Gtk.Revealer ();
        remove_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        remove_revealer.add (remove_button);
        remove_revealer.reveal_child = false;
        remove_revealer.margin_top = 32;
        remove_revealer.valign = Gtk.Align.START;
        remove_revealer.halign = Gtk.Align.END;

        top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.hexpand = true;
        top_box.pack_start (checked_button, false, false, 0);
        top_box.pack_start (name_eventbox, true, true, 6);
        top_box.pack_start (name_entry, true, true, 6);
        //top_box.pack_start (checklist_preview, false, false, 0);

        note_view = new Gtk.TextView ();
		note_view.set_wrap_mode (Gtk.WrapMode.WORD);
		note_view.buffer.text = task.note;
        note_view.get_style_context ().add_class ("note-view");

        var note_scrolled = new Gtk.ScrolledWindow (null, null);
        note_scrolled.height_request = 100;
        note_scrolled.add (note_view);

        var note_eventbox = new Gtk.EventBox ();
        note_eventbox.add (note_scrolled);

        checklist = new Gtk.ListBox  ();
        checklist.activate_on_single_click = true;
        checklist.get_style_context ().add_class (Gtk.STYLE_CLASS_BACKGROUND);
        checklist.selection_mode = Gtk.SelectionMode.SINGLE;

        string[] checklist_array = task.checklist.split (";");

        foreach (string str in checklist_array) {
            string check_name = str.substring (1, -1);
            bool check_active = false;

            if (str.substring (0, 1) == "0") {
                check_active = false;
            } else {
                check_active = true;
            }

            var row = new Widgets.CheckRow (check_name, check_active);
            checklist.add (row);

            checklist.show_all ();
	    }


        var checklist_button = new Gtk.CheckButton ();
        checklist_button.get_style_context ().add_class ("planner-radio-disable");
        checklist_button.sensitive = false;

        var checklist_entry = new Gtk.Entry ();
        checklist_entry.hexpand = true;
        checklist_entry.margin_bottom = 1;
        checklist_entry.max_length = 50;
        checklist_entry.placeholder_text = _("Checklist");
        checklist_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        checklist_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        checklist_entry.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        checklist_entry.get_style_context ().add_class ("planner-entry");

        var checklist_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        checklist_box.pack_start (checklist_button, false, false, 0);
        checklist_box.pack_start (checklist_entry, true, true, 6);

        var checklist_grid = new Gtk.Grid ();
        checklist_grid.orientation = Gtk.Orientation.VERTICAL;
        checklist_grid.add (checklist);
        checklist_grid.add (checklist_box);

        var note_checklist_grid = new Gtk.Grid ();
        note_checklist_grid.margin_end = 12;
        note_checklist_grid.column_spacing = 12;
        note_checklist_grid.column_homogeneous = true;
        note_checklist_grid.add (note_eventbox);
        note_checklist_grid.add (checklist_grid);

        var bottom_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        bottom_box.pack_start (note_checklist_grid);

        bottom_box_revealer = new Gtk.Revealer ();
        bottom_box_revealer.margin_start = 36;
        bottom_box_revealer.add (bottom_box);
        bottom_box_revealer.reveal_child = false;

        main_grid = new Gtk.Grid ();
        main_grid.margin_top = 3;
        main_grid.margin_end = 5;
        main_grid.expand = true;
        main_grid.get_style_context ().add_class ("task");
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (top_box);
        main_grid.add (bottom_box_revealer);

        var main_overlay = new Gtk.Overlay ();
        main_overlay.add_overlay (close_revealer);
        main_overlay.add_overlay (remove_revealer);
        main_overlay.add (main_grid);

        add (main_overlay);

        name_eventbox.button_press_event.connect ((event) => {
            name_label.label = name_entry.text;
            check_task_completed ();
            content_revealer ();

            //update_task ();
        });

        close_button.clicked.connect (() => {
            name_label.label = name_entry.text;
            check_task_completed ();
            hide_content ();
            //update_task ();
        });

        note_eventbox.button_press_event.connect ((event) => {
            Timeout.add (200, () => {
                note_view.grab_focus ();
                return false;
            });

            return false;
        });

        checked_button.toggled.connect (() => {
            check_task_completed ();
            //update_task ();
        });

        name_eventbox.enter_notify_event.connect ((event) => {
            name_label.get_style_context ().add_class ("label-accent");

            return false;
        });

        name_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            name_label.get_style_context ().remove_class ("label-accent");
            return false;
        });

        remove_button.clicked.connect (() => {
            Timeout.add (20, () => {
                this.opacity = this.opacity - 0.1;

                if (this.opacity <= 0) {
                    destroy ();
                    return false;
                }

                return true;
            });
        });

        checklist_entry.activate.connect (() => {
            if (checklist_entry.text != "") {
                var row = new Widgets.CheckRow (checklist_entry.text, false);
                checklist.add (row);

                checklist_entry.text = "";
                checklist.show_all ();
            }
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                name_label.label = name_entry.text;
                check_task_completed ();
                hide_content ();
            }

            return false;
        });

        note_view.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                name_label.label = name_entry.text;
                check_task_completed ();
                hide_content ();
            }

            return false;
        });
    }

    private void check_task_completed () {
        if (checked_button.active) {
            name_label.label = "<s>%s</s>".printf(name_label.label);
        } else {
            name_label.label = name_entry.text;
        }
    }


    private void content_revealer () {
        if (bottom_box_revealer.reveal_child) {
            main_grid.get_style_context ().remove_class ("popover");

            bottom_box_revealer.reveal_child = false;
            close_revealer.reveal_child = false;
            remove_revealer.reveal_child = false;

            top_box.margin_top = 0;
            top_box.margin_start = 0;

            name_entry.visible = false;
            name_eventbox.visible = true;
        } else {
            main_grid.get_style_context ().add_class ("popover");
            note_view.grab_focus ();

            bottom_box_revealer.reveal_child = true;
            close_revealer.reveal_child = true;
            remove_revealer.reveal_child = true;

            top_box.margin_top = 6;
            top_box.margin_start = 12;

            name_entry.visible = true;
            name_eventbox.visible = false;
        }
    }

    public void hide_content () {
        main_grid.get_style_context ().remove_class ("popover");

        top_box.margin_top = 0;
        top_box.margin_start = 0;

        name_entry.visible = false;
        name_eventbox.visible = true;

        close_revealer.reveal_child = false;
        bottom_box_revealer.reveal_child = false;
        remove_revealer.reveal_child = false;
    }

    /*
    public void update_task () {
        if (task_entry.text != "") {
            if (checked_button.active) {
                task.checked = 1;
            } else {
                task.checked = 0;
            }

            task.content = task_entry.text;
            task.note = note_view.buffer.text;
            /*

            if (Planner.database.update_task (task) == Sqlite.DONE) {

            }
        }
    }
    */
 }
