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
    private Gtk.FlowBox labels_flowbox;

    Gtk.ToggleButton show_hide_all_button;

    private Widgets.AlertView alert_view;

    private Widgets.Popovers.LabelsPopover labels_popover;

    private bool show_all_tasks = true;
    private Gtk.Button show_all_tasks_button;

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

        alert_view.margin_bottom = 64;
        alert_view.no_show_all = true;
        alert_view.visible = false;

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
        name_entry.hexpand = false;
        name_entry.text = project.name;
        name_entry.placeholder_text = _("Name");

        deadline_project_button = new Gtk.ToggleButton ();
        deadline_project_button.margin_top = 2;
        deadline_project_button.get_style_context ().add_class ("no-padding");
        deadline_project_button.get_style_context ().add_class ("planner-when-preview");
        deadline_project_button.valign = Gtk.Align.CENTER;

        deadline_project_label = new Gtk.Label (null);
        deadline_project_button.get_style_context ().add_class ("h4");
        deadline_project_button.add (deadline_project_label);

        if (project.deadline == "") {
            deadline_project_button.visible = false;
            deadline_project_button.no_show_all = true;
        } else {
            deadline_project_button.visible = true;
            deadline_project_button.no_show_all = false;

            string date_format = Granite.DateTime.get_default_date_format (false, true, true);
            var deadline_datetime = new GLib.DateTime.from_iso8601 (project.deadline, new GLib.TimeZone.local ());

            if (Application.utils.is_today (deadline_datetime)) {
                deadline_project_label.label = Application.utils.TODAY_STRING;
            } else if (Application.utils.is_tomorrow (deadline_datetime)) {
                deadline_project_label.label = Application.utils.TOMORROW_STRING;
            } else {
                deadline_project_label.label = deadline_datetime.format (date_format);
            }
        }

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
        top_box.margin_end = 16;
        top_box.margin_top = 24;

        top_box.pack_start (color_button, false, false, 0);
        top_box.pack_start (deadline_project_button, false, false, 6);
        top_box.pack_start (name_entry, true, true, 6);
        top_box.pack_end (settings_button, false, false, 12);
        top_box.pack_end (action_revealer, false, false, 0);

        note_view = new Gtk.TextView ();
        note_view.opacity = 0.7;
		note_view.set_wrap_mode (Gtk.WrapMode.WORD);
        note_view.margin_start = 18;
        note_view.margin_top = 6;
        note_view.margin_end = 32;
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
        tasks_list.valign = Gtk.Align.START;
        tasks_list.hexpand = true;
        tasks_list.margin_start = 20;
        tasks_list.margin_end = 6;
        tasks_list.margin_top = 6;

        tasks_list.set_sort_func ((row1, row2) => {
            var item1 = row1 as Widgets.TaskRow;
            if (item1.task.checked == 0) {
                return 0;
            } else {
                return 1;
            }
        });

        add_task_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        add_task_button.height_request = 32;
        add_task_button.width_request = 32;
        add_task_button.get_style_context ().add_class ("planner-add-new-task");
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

        task_new_revealer = new Widgets.TaskNew (false, project.id);
        task_new_revealer.valign = Gtk.Align.END;

        show_all_tasks_button = new Gtk.Button.with_label (_("Show completed tasks"));
        show_all_tasks_button.can_focus = false;
        show_all_tasks_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        show_all_tasks_button.get_style_context ().add_class ("h4");
        show_all_tasks_button.valign = Gtk.Align.START;
        show_all_tasks_button.halign = Gtk.Align.START;
        show_all_tasks_button.margin_start = 14;

        labels_flowbox = new Gtk.FlowBox ();
        labels_flowbox.selection_mode = Gtk.SelectionMode.NONE;
        labels_flowbox.margin_start = 6;
        labels_flowbox.height_request = 38;
        labels_flowbox.expand = false;

        var labels_flowbox_revealer = new Gtk.Revealer ();
        labels_flowbox_revealer.margin_start = 12;
        labels_flowbox_revealer.margin_top = 6;
        labels_flowbox_revealer.add (labels_flowbox);
        labels_flowbox_revealer.reveal_child = false;

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.expand = true;
        box.pack_start (top_box, false, false, 0);
        box.pack_start (note_view, false, false, 0);
        box.pack_start (labels_flowbox_revealer, false, false, 0);
        box.pack_start (alert_view, true, true, 0);
        box.pack_start (tasks_list, false, true, 0);
        box.pack_start (show_all_tasks_button, false, true, 0);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (box);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (scrolled, true, true, 0);

        var main_overlay = new Gtk.Overlay ();
        main_overlay.add_overlay (add_task_revealer);
        main_overlay.add_overlay (task_new_revealer);
        main_overlay.add (main_box);

        add (main_overlay);
        update_tasks_list ();
        check_visible_alertview ();
        tasks_list.set_filter_func ((row) => {
            var item = row as Widgets.TaskRow;
            return item.task.checked == 0;
        });

        tasks_list.invalidate_sort ();

        // Signals
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

        show_all_tasks_button.clicked.connect (() => {
			if (show_all_tasks) {
                show_all_tasks = false;
                show_all_tasks_button.label = _("Hide completed tasks");

                tasks_list.set_filter_func ((row) => {
                    var item = row as Widgets.TaskRow;
                    return true;
                });
			} else {
                show_all_tasks = true;
                show_all_tasks_button.label = _("Show completed tasks");

                tasks_list.set_filter_func ((row) => {
                    var item = row as Widgets.TaskRow;
                    return item.task.checked == 0;
                });
			}

            check_visible_alertview ();
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
            var button_press = Application.settings.get_enum ("button-press");

            if (button_press == 0) {

            } else if (button_press == 1) {
                if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                    foreach (Gtk.Widget element in tasks_list.get_children ()) {
                        var row = element as Widgets.TaskRow;
                        row.hide_content ();
                    }
                }
            } else {
                if (event.type == Gdk.EventType.@3BUTTON_PRESS) {
                    foreach (Gtk.Widget element in tasks_list.get_children ()) {
                        var row = element as Widgets.TaskRow;
                        row.hide_content ();
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

        tasks_list.invalidate_sort ();
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
            alert_view.visible = true;
            alert_view.no_show_all = false;

            tasks_list.visible = false;
            tasks_list.no_show_all = true;

            show_all_tasks_button.visible = false;
            show_all_tasks_button.no_show_all = true;
        }
    }

    private void update_project () {
        if (name_entry.text == "") {
            name_entry.text = project.name;
        } else {
            project.name = name_entry.text;

            if (Application.database.update_project (project) == Sqlite.DONE) {

            }
        }
    }

    public void check_visible_alertview () {
        if (Application.utils.is_listbox_empty (tasks_list)) {
            alert_view.visible = true;
            alert_view.no_show_all = false;

            tasks_list.visible = false;
            tasks_list.no_show_all = true;

            show_all_tasks_button.visible = false;
            show_all_tasks_button.no_show_all = true;
        } else {
            alert_view.visible = false;
            alert_view.no_show_all = true;

            tasks_list.visible = true;
            tasks_list.no_show_all = false;

            show_all_tasks_button.visible = true;
            show_all_tasks_button.no_show_all = false;
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
        } else {
            task_new_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            task_new_revealer.reveal_child = true;

            add_task_revealer.reveal_child = false;
            task_new_revealer.name_entry.grab_focus ();
        }

        tasks_list.unselect_all ();
    }
}
