public class Views.Project : Gtk.EventBox {
    public weak MainWindow parent_window { get; construct; }
    public Objects.Project project { get; construct; }

    private Gtk.Entry name_entry;
    private Gtk.ToggleButton deadline_project_button;
    private Gtk.Label deadline_project_label;
    private Gtk.TextView note_view;

    private Widgets.TaskNew task_new_revealer;
    private Gtk.ListBox tasks_list;
    private Gtk.Button add_task_button;

    private Gtk.Revealer add_task_revealer;
    private Gtk.Revealer show_completed_revealer;
    private Gtk.Revealer notes_revealer;

    private Gtk.FlowBox labels_flowbox;

    Gtk.ToggleButton show_hide_all_button;

    private Gtk.Box box;

    private Widgets.AlertView alert_view;

    private Widgets.Popovers.LabelsPopover labels_popover;

    private Gtk.Stack main_stack;

    public Project (Objects.Project _project, MainWindow parent) {
        Object (
            parent_window: parent,
            project: _project,
            expand: true
        );
    }

    construct {
        get_style_context ().add_class (Granite.STYLE_CLASS_WELCOME);

        alert_view = new Widgets.AlertView (
            _("keep your tasks organized in projects"),
            _("Tap + to add a task."),
            "planner-startup-symbolic"
        );

        var color_image = new Gtk.Image ();
        color_image.gicon = new ThemedIcon ("mail-unread-symbolic");
        color_image.get_style_context ().add_class ("proyect-%i".printf (project.id));
        color_image.pixel_size = 24;

        var color_button = new Gtk.Button ();
        color_button.valign = Gtk.Align.CENTER;
        color_button.halign = Gtk.Align.CENTER;
        color_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        color_button.get_style_context ().add_class ("button-circular");
        color_button.get_style_context ().add_class ("no-padding");
        color_button.tooltip_text = _("Add new project");
        color_button.add (color_image);

        name_entry = new Gtk.Entry ();
        name_entry.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        name_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        name_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        name_entry.get_style_context ().add_class ("planner-entry");
        name_entry.get_style_context ().add_class ("no-padding");
        name_entry.get_style_context ().add_class ("planner-entry-bold");
        name_entry.text = project.name;
        name_entry.placeholder_text = _("Name");

        deadline_project_button = new Gtk.ToggleButton ();
        deadline_project_button.margin_top = 3;
        deadline_project_button.margin_bottom = 3;
        deadline_project_button.margin_start = 17;
        deadline_project_button.can_focus = false;
        deadline_project_button.halign = Gtk.Align.START;
        //deadline_project_button.get_style_context ().add_class ("no-padding");
        deadline_project_button.get_style_context ().add_class ("planner-when-preview");
        deadline_project_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        deadline_project_button.valign = Gtk.Align.CENTER;

        deadline_project_label = new Gtk.Label (_("Deadline"));
        deadline_project_label.margin_bottom = 1;
        deadline_project_button.get_style_context ().add_class ("h3");

        var deadline_project_icon = new Gtk.Image ();
        deadline_project_icon.gicon = new ThemedIcon ("office-calendar-symbolic");
        deadline_project_icon.pixel_size = 16;

        var deadline_grid = new Gtk.Grid ();
        deadline_grid.add (deadline_project_icon);
        deadline_grid.add (deadline_project_label);

        deadline_project_button.add (deadline_grid);

        var deadline_project_revealer = new Gtk.Revealer ();
        deadline_project_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        deadline_project_revealer.add (deadline_project_button);
        deadline_project_revealer.reveal_child = true;

        if (project.deadline == "") {
            //deadline_project_revealer.reveal_child = false;

        } else {
            //deadline_project_revealer.reveal_child = true;

            var deadline_datetime = new GLib.DateTime.from_iso8601 (project.deadline, new GLib.TimeZone.local ());

            if (Application.utils.is_today (deadline_datetime)) {
                deadline_project_label.label = Application.utils.TODAY_STRING;
            } else if (Application.utils.is_tomorrow (deadline_datetime)) {
                deadline_project_label.label = Application.utils.TOMORROW_STRING;
            } else {
                deadline_project_label.label = deadline_datetime.format (Application.utils.get_default_date_format_from_date (deadline_datetime));
            }
        }

        var deadline_popover = new Widgets.Popovers.DeadlinePopover (deadline_project_button);

        deadline_project_button.toggled.connect (() => {
            if (deadline_project_button.active) {
                deadline_popover.show_all ();
            }
        });

        deadline_popover.closed.connect (() => {
            deadline_project_button.active = false;

            update_project ();
        });

        deadline_popover.selection_changed.connect ((date) => {
            if (Application.utils.is_today (date)) {
                deadline_project_label.label = Application.utils.TODAY_STRING;
            } else if (Application.utils.is_tomorrow (date)) {
                deadline_project_label.label = Application.utils.TOMORROW_STRING;
            } else {
                deadline_project_label.label = date.format (Application.utils.get_default_date_format_from_date (date));
            }

            project.deadline = date.to_string ();
        });

        deadline_popover.selection_double_changed.connect ((date) => {
            if (Application.utils.is_today (date)) {
                deadline_project_label.label = Application.utils.TODAY_STRING;
            } else if (Application.utils.is_tomorrow (date)) {
                deadline_project_label.label = Application.utils.TOMORROW_STRING;;
            } else {
                deadline_project_label.label = date.format (Application.utils.get_default_date_format_from_date (date));
            }

            project.deadline = date.to_string ();
        });

        deadline_popover.clear.connect (() => {
            deadline_project_label.label = _("Deadline");
            project.deadline = "";
        });

        var paste_button = new Gtk.Button.from_icon_name ("planner-paste-symbolic", Gtk.IconSize.MENU);
        paste_button.get_style_context ().add_class ("planner-paste-menu");
        paste_button.tooltip_text = _("Paste");
        paste_button.valign = Gtk.Align.CENTER;
        paste_button.halign = Gtk.Align.CENTER;

        var labels_button = new Gtk.Button.from_icon_name ("planner-label-symbolic", Gtk.IconSize.MENU);
        labels_button.get_style_context ().add_class ("planner-label-menu");
        labels_button.tooltip_text = _("Filter by Label");
        labels_button.valign = Gtk.Align.CENTER;
        labels_button.halign = Gtk.Align.CENTER;

        labels_popover = new Widgets.Popovers.LabelsPopover (labels_button);
        labels_popover.position = Gtk.PositionType.BOTTOM;

        var share_button = new Gtk.Button.from_icon_name ("planner-share-symbolic", Gtk.IconSize.MENU);
        share_button.get_style_context ().add_class ("planner-share-menu");
        share_button.tooltip_text = _("Share");
        share_button.valign = Gtk.Align.CENTER;
        share_button.halign = Gtk.Align.CENTER;

        share_button.clicked.connect (() => {
            var share_dialog = new Dialogs.ShareDialog (Application.instance.main_window);
            share_dialog.project = project.id;
            share_dialog.destroy.connect (Gtk.main_quit);
            share_dialog.show_all ();
        });

        show_hide_all_button = new Gtk.ToggleButton ();
        show_hide_all_button.valign = Gtk.Align.CENTER;
        show_hide_all_button.halign = Gtk.Align.CENTER;
        show_hide_all_button.get_style_context ().add_class ("planner-zoom-in-menu");
        show_hide_all_button.tooltip_text = _("Open all tasks");

        var show_hide_image = new Gtk.Image.from_icon_name ("zoom-in-symbolic", Gtk.IconSize.MENU);
        show_hide_all_button.add (show_hide_image);

        var action_grid = new Gtk.Grid ();
        action_grid.column_spacing = 12;

        action_grid.add (labels_button);
        action_grid.add (paste_button);
        action_grid.add (share_button);
        action_grid.add (show_hide_all_button);

        var action_revealer = new Gtk.Revealer ();
        action_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        action_revealer.add (action_grid);

        var settings_button = new Gtk.ToggleButton ();
		settings_button.active = true;
        settings_button.valign = Gtk.Align.START;
		settings_button.get_style_context ().add_class ("show-settings-button");
        settings_button.get_style_context ().add_class ("button-circular");
        settings_button.get_style_context ().remove_class ("button");
		settings_button.add (new Gtk.Image.from_icon_name ("pan-start-symbolic", Gtk.IconSize.MENU));

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.valign = Gtk.Align.START;
        top_box.hexpand = true;
        top_box.margin_start = 12;
        top_box.margin_top = 12;

        top_box.pack_start (color_button, false, false, 0);
        top_box.pack_start (name_entry, true, true, 6);
        top_box.pack_end (settings_button, false, false, 12);
        top_box.pack_end (action_revealer, false, false, 0);

        note_view = new Gtk.TextView ();
		//note_view.set_wrap_mode (Gtk.WrapMode.WORD);
        note_view.margin_start = 18;
        note_view.margin_top = 6;
        note_view.margin_end = 16;
		note_view.buffer.text = project.note;
        note_view.get_style_context ().add_class ("note-view");

        var note_view_placeholder_label = new Gtk.Label (_("Note"));
        note_view_placeholder_label.opacity = 0.65;
        note_view.add (note_view_placeholder_label);

        if (note_view.buffer.text != "") {
            note_view_placeholder_label.visible = false;
            note_view_placeholder_label.no_show_all = true;
        }

        tasks_list = new Gtk.ListBox  ();
        tasks_list.activate_on_single_click = true;
        tasks_list.selection_mode = Gtk.SelectionMode.SINGLE;
        tasks_list.hexpand = true;

        add_task_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        add_task_button.can_focus = false;
        add_task_button.height_request = 32;
        add_task_button.width_request = 32;
        add_task_button.get_style_context ().add_class ("button-circular");
        add_task_button.get_style_context ().add_class ("no-padding");
        add_task_button.tooltip_text = _("Add new task");

        add_task_revealer = new Gtk.Revealer ();
        add_task_revealer.valign = Gtk.Align.END;
        add_task_revealer.halign = Gtk.Align.END;
        add_task_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        add_task_revealer.add (add_task_button);
        add_task_revealer.margin = 12;
        add_task_revealer.reveal_child = true;

        var show_completed_button = new Gtk.ToggleButton ();
        show_completed_button.can_focus = false;
        show_completed_button.height_request = 32;
        show_completed_button.width_request = 32;
        show_completed_button.get_style_context ().add_class ("button-circular");
        show_completed_button.get_style_context ().add_class ("no-padding");
        show_completed_button.tooltip_text = _("Show completed tasks");

        var show_completed_icon = new Gtk.Image ();
        show_completed_icon.gicon = new ThemedIcon ("emblem-default-symbolic");
        show_completed_icon.pixel_size = 16;

        show_completed_button.add (show_completed_icon);

        show_completed_revealer = new Gtk.Revealer ();
        show_completed_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        show_completed_revealer.add (show_completed_button);
        show_completed_revealer.reveal_child = true;

        var notes_button = new Gtk.ToggleButton ();
        notes_button.can_focus = false;
        notes_button.height_request = 32;
        notes_button.width_request = 32;
        notes_button.get_style_context ().add_class ("button-circular");
        notes_button.tooltip_text = _("Notes");
        notes_button.add (new Gtk.Image.from_icon_name ("text-x-generic-symbolic", Gtk.IconSize.SMALL_TOOLBAR));

        notes_revealer = new Gtk.Revealer ();
        notes_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        notes_revealer.add (notes_button);
        notes_revealer.reveal_child = true;

        var stacks_buttons_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        stacks_buttons_box.margin = 12;
        stacks_buttons_box.valign = Gtk.Align.END;
        stacks_buttons_box.halign = Gtk.Align.START;
        stacks_buttons_box.pack_start (show_completed_revealer, false, false, 0);
        //stacks_buttons_box.pack_start (notes_revealer, false, false, 12);

        task_new_revealer = new Widgets.TaskNew (false, project.id);
        task_new_revealer.valign = Gtk.Align.END;

        labels_flowbox = new Gtk.FlowBox ();
        labels_flowbox.selection_mode = Gtk.SelectionMode.NONE;
        labels_flowbox.margin_start = 6;
        labels_flowbox.height_request = 38;
        labels_flowbox.expand = false;

        var labels_flowbox_revealer = new Gtk.Revealer ();
        labels_flowbox_revealer.valign = Gtk.Align.START;
        labels_flowbox_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        labels_flowbox_revealer.margin_start = 6;
        labels_flowbox_revealer.margin_top = 6;
        labels_flowbox_revealer.add (labels_flowbox);
        labels_flowbox_revealer.reveal_child = false;

        var t_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        t_box.hexpand = true;
        t_box.pack_start (top_box, false, false, 0);
        t_box.pack_start (deadline_project_revealer, false, false, 0);
        t_box.pack_start (note_view, false, false, 0);
        t_box.pack_start (labels_flowbox_revealer, false, false, 0);

        var b_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        b_box.expand = true;
        b_box.pack_start (tasks_list, false, true, 0);

        var notes_flowbox = new Gtk.FlowBox ();
        notes_flowbox.row_spacing = 12;
        notes_flowbox.column_spacing = 12;
        notes_flowbox.margin = 12;
        notes_flowbox.selection_mode = Gtk.SelectionMode.NONE;
        notes_flowbox.expand = true;

        notes_flowbox.add (new Widgets.NoteChild ());
        notes_flowbox.add (new Widgets.NoteChild ());
        notes_flowbox.add (new Widgets.NoteChild ());

        main_stack = new Gtk.Stack ();
        main_stack.expand = true;
        main_stack.margin_start = 12;
        main_stack.margin_bottom = 9;
        main_stack.transition_duration = 350;
        main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        main_stack.add_named (b_box, "main");
        main_stack.add_named (alert_view, "alert");
        main_stack.add_named (notes_flowbox, "notes");

        main_stack.visible_child_name = "main";

        box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.expand = true;
        box.pack_start (t_box, false, true, 0);
        box.pack_start (main_stack, false, true, 0);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (box);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (scrolled, true, true, 0);

        var eventbox = new Gtk.EventBox ();
        eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        eventbox.add (main_box);

        var main_overlay = new Gtk.Overlay ();
        main_overlay.add_overlay (add_task_revealer);
        main_overlay.add_overlay (task_new_revealer);
        main_overlay.add_overlay (stacks_buttons_box);
        main_overlay.add (eventbox);

        add (main_overlay);
        update_tasks_list ();

        if (Application.utils.is_listbox_empty (tasks_list)) {
            Timeout.add (200, () => {
                main_stack.visible_child_name = "alert";
                return false;
            });
        } else {
            Timeout.add (200, () => {
                main_stack.visible_child_name = "main";
                return false;
            });
        }

        show_all ();

        tasks_list.set_filter_func ((row) => {
            var item = row as Widgets.TaskRow;
            return item.task.checked == 0;
        });

        tasks_list.set_sort_func ((row1, row2) => {
            var item1 = row1 as Widgets.TaskRow;
            if (item1.task.checked == 0) {
                return 0;
            } else {
                return 1;
            }
        });

        // Signals
        notes_button.toggled.connect (() => {
            if (notes_button.active) {
                main_stack.visible_child_name = "main";
            } else {
                main_stack.visible_child_name = "notes";
            }
        });

        show_completed_button.toggled.connect (() => {
            if (show_completed_button.active) {
                show_completed_button.tooltip_text = _("Hide completed tasks");
                show_completed_icon.icon_name = "list-remove";

                tasks_list.set_filter_func ((row) => {
                    var item = row as Widgets.TaskRow;
                    return true;
                });
            } else {
                show_completed_button.tooltip_text = _("Show completed tasks");
                show_completed_icon.icon_name = "emblem-default-symbolic";

                tasks_list.set_filter_func ((row) => {
                    var item = row as Widgets.TaskRow;
                    return item.task.checked == 0;
                });
            }
        });
        /*
        eventbox.enter_notify_event.connect ((event) => {
            deadline_project_revealer.reveal_child = true;

            return false;
        });

        eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            if (deadline_project_button.active == false) {
                if (project.deadline == "") {
                    deadline_project_revealer.reveal_child = false;
                }
            }

            return false;
        });
        */

        show_hide_all_button.toggled.connect (() => {
          if (show_hide_all_button.active) {
              show_hide_all_button.tooltip_text = _("Close all tasks");
              show_hide_image.icon_name = "zoom-out-symbolic";

              foreach (Gtk.Widget element in tasks_list.get_children ()) {
                  var row = element as Widgets.TaskRow;
                  row.show_content ();
              }
          } else {
              show_hide_all_button.tooltip_text = _("Open all tasks");
              show_hide_image.icon_name = "zoom-in-symbolic";

              foreach (Gtk.Widget element in tasks_list.get_children ()) {
                  var row = element as Widgets.TaskRow;
                  row.hide_content ();
              }
          }
        });

        name_entry.focus_out_event.connect (() => {
            update_project ();
            return false;
        });

        name_entry.activate.connect (() => {
            update_project ();
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                update_project ();
            }

            return false;
        });

        color_button.clicked.connect (() => {
            var color_dialog = new Gtk.ColorChooserDialog (_("Select Your Favorite Color"), parent_window);
    		if (color_dialog.run () == Gtk.ResponseType.OK) {
                project.color = Application.utils.rgb_to_hex_string (color_dialog.rgba);

                update_project ();
    		}

    		color_dialog.close ();
        });

        settings_button.toggled.connect (() => {
            if (action_revealer.reveal_child) {
                settings_button.get_style_context ().remove_class ("closed");
                action_revealer.reveal_child = false;
            } else {
                action_revealer.reveal_child = true;
                settings_button.get_style_context ().add_class ("closed");
            }
        });

        Gdk.Display display = Gdk.Display.get_default ();
        Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);

        paste_button.clicked.connect (() => {
            settings_button.get_style_context ().remove_class ("closed");
            action_revealer.reveal_child = false;

            string text = clipboard.wait_for_text ();

            if (text == "") {
                // Notificacion Here ...
                Application.notification.send_local_notification (
                    _("Empty clipboard"),
                    _("Try copying some text and try again"),
                    "dialog-error",
                    3,
                    false);
            } else {
                var task = new Objects.Task ();
                task.content = text;
                task.project_id = project.id;

                if (Application.database.add_task (task) == Sqlite.DONE) {
                    Application.notification.send_local_notification (
                        _("His task was created from the clipboard"),
                        _("Tap to undo"),
                        "edit-paste",
                        3,
                        true);
                }
            }

            tasks_list.unselect_all ();
        });

        this.event.connect ((event) => {
            var button_press = Application.settings.get_enum ("quick-save");

            if (button_press == 0) {

            } else if (button_press == 1) {
                if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                    foreach (Gtk.Widget element in tasks_list.get_children ()) {
                        var row = element as Widgets.TaskRow;

                        if (row.bottom_box_revealer.reveal_child) {
                            row.hide_content ();
                        }
                    }
                }
            } else {
                if (event.type == Gdk.EventType.@3BUTTON_PRESS) {
                    foreach (Gtk.Widget element in tasks_list.get_children ()) {
                        var row = element as Widgets.TaskRow;

                        if (row.bottom_box_revealer.reveal_child) {
                            row.hide_content ();
                        }
                    }
                }
            }

            tasks_list.unselect_all ();
            return false;
        });

        note_view.focus_out_event.connect (() => {
            if (note_view.buffer.text == "") {
                note_view_placeholder_label.visible = true;
                note_view_placeholder_label.no_show_all = false;
            }

            project.note = note_view.buffer.text;
            update_project ();

            return false;
        });

        note_view.focus_in_event.connect (() => {
            note_view_placeholder_label.visible = false;
            note_view_placeholder_label.no_show_all = true;

            return false;
        });

        add_task_button.clicked.connect (() => {
            task_on_revealer ();;
        });

        task_new_revealer.on_signal_close.connect (() => {
            task_on_revealer ();
        });

        tasks_list.remove.connect ((widget) => {
            check_visible_alertview ();
        });

        labels_button.clicked.connect (() => {
            labels_popover.update_label_list ();
            labels_popover.show_all ();
        });

        labels_popover.on_selected_label.connect ((label) => {
            if (Application.utils.is_label_repeted (labels_flowbox, label.id) == false) {
                var child = new Widgets.LabelChild (label);
                labels_flowbox.add (child);
            }

            labels_flowbox_revealer.reveal_child = !Application.utils.is_empty (labels_flowbox);
            labels_flowbox.show_all ();
            labels_popover.popdown ();

            // Filter
            tasks_list.set_filter_func ((row) => {
                var item = row as Widgets.TaskRow;
                var labels = new Gee.ArrayList<int> ();
                var _labels = new Gee.ArrayList<int> ();

                foreach (string label_id in item.task.labels.split (";")) {
                    labels.add (int.parse (label_id));
                }

                foreach (Gtk.Widget element in labels_flowbox.get_children ()) {
                    var child = element as Widgets.LabelChild;
                    _labels.add (child.label.id);
                }

                // Filter
                foreach (int x in labels) {
                    if (x in _labels) {
                        return true;
                    }
                }

                return false;
            });
        });

        labels_flowbox.remove.connect ((widget) => {
            if (Application.utils.is_empty (labels_flowbox)) {
                labels_flowbox_revealer.reveal_child = false;
                tasks_list.set_filter_func ((row) => {
                    return true;
                });
            } else {
                // Filter
                tasks_list.set_filter_func ((row) => {
                    var item = row as Widgets.TaskRow;
                    var labels = new Gee.ArrayList<int> ();
                    var _labels = new Gee.ArrayList<int> ();

                    foreach (string label_id in item.task.labels.split (";")) {
                        labels.add (int.parse (label_id));
                    }

                    foreach (Gtk.Widget element in labels_flowbox.get_children ()) {
                        var child = element as Widgets.LabelChild;
                        _labels.add (child.label.id);
                    }

                    // Filter
                    foreach (int x in labels) {
                        if (x in _labels) {
                            return true;
                        }
                    }

                    return false;
                });
            }
        });

        Application.database.update_project_signal.connect ((_project) => {
            if (project.id == _project.id) {
                name_entry.text = _project.name;
            }
        });

        Application.database.update_task_signal.connect ((task) => {
            if (Application.utils.is_task_repeted (tasks_list, task.id) == false) {
                add_new_task (task);
            }

            foreach (Gtk.Widget element in tasks_list.get_children ()) {
                var row = element as Widgets.TaskRow;

                if (row.task.id == task.id) {
                    row.set_update_task (task);
                }
            }
        });

        Application.database.add_task_signal.connect (() => {
            var task = Application.database.get_last_task ();
            add_new_task (task);
        });

        Application.database.on_signal_remove_task.connect ((task) => {
            foreach (Gtk.Widget element in tasks_list.get_children ()) {
                var row = element as Widgets.TaskRow;

                if (row.task.id == task.id) {
                    tasks_list.remove (element);
                }
            }
        });
    }

    public void apply_remove () {
        foreach (Gtk.Widget element in tasks_list.get_children ()) {
            var row = element as Widgets.TaskRow;

            if (row.task.project_id != project.id) {
                tasks_list.remove (element);
            }
        }

        //tasks_list.invalidate_sort ();
    }

    public void update_tasks_list () {
        foreach (Gtk.Widget element in tasks_list.get_children ()) {
            tasks_list.remove (element);
        }

        var all_tasks = new Gee.ArrayList<Objects.Task?> ();
        all_tasks = Application.database.get_all_tasks_by_project (project.id);

        foreach (var task in all_tasks) {
            var row = new Widgets.TaskRow (task);
            row.project_preview_box.visible = false;
            row.project_preview_box.no_show_all = true;

            tasks_list.add (row);

            row.on_signal_update.connect ((_task) => {
                if (_task.project_id != project.id) {
                    Timeout.add (20, () => {
                        row.opacity = row.opacity - 0.1;

                        if (row.opacity <= 0) {
                            row.destroy ();
                            return false;
                        }

                        return true;
                    });
                }

                tasks_list.unselect_all ();
            });

            tasks_list.show_all ();
        }

        if (Application.utils.is_listbox_empty (tasks_list)) {
            main_stack.visible_child_name = "alert";
        }
    }

    public void update_project () {
        if (name_entry.text == "") {
            name_entry.text = project.name;
        } else {
            project.name = name_entry.text;

            if (Application.database.update_project (project) == Sqlite.DONE) {

            }
        }

        /*
        Thread<void*> thread = new Thread<void*>.try ("Conntections Thread.", () => {
            return null;
        });
        */
    }

    public void check_visible_alertview () {
        if (Application.utils.is_listbox_empty (tasks_list)) {
            main_stack.visible_child_name = "alert";
            //box.valign = Gtk.Align.FILL;
        } else {
            main_stack.visible_child_name = "main";
            //box.valign = Gtk.Align.START;
        }

        show_all ();
    }

    private void add_new_task (Objects.Task task) {
        if (task.project_id == project.id) {
            var row = new Widgets.TaskRow (task);
            row.project_preview_box.visible = false;
            row.project_preview_box.no_show_all = true;

            tasks_list.add (row);

            row.on_signal_update.connect ((_task) => {
                if (_task.project_id != project.id) {
                    Timeout.add (20, () => {
                        row.opacity = row.opacity - 0.1;

                        if (row.opacity <= 0) {
                            row.destroy ();
                            return false;
                        }

                        return true;
                    });
                }

                tasks_list.unselect_all ();
            });

            tasks_list.show_all ();
        }

        check_visible_alertview ();
    }

    private void task_on_revealer () {
        if (task_new_revealer.reveal_child) {
            task_new_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
            task_new_revealer.reveal_child = false;

            add_task_revealer.reveal_child = true;
            show_completed_revealer.reveal_child = true;
        } else {
            task_new_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            task_new_revealer.reveal_child = true;

            add_task_revealer.reveal_child = false;
            show_completed_revealer.reveal_child = false;

            task_new_revealer.name_entry.grab_focus ();
        }

        tasks_list.unselect_all ();
    }
}
