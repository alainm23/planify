public class Views.Upcoming : Gtk.EventBox {
    public MainWindow window { get; construct; }
    private Widgets.TaskNew task_new_revealer;
    private Gtk.ListBox tasks_list;
    private Gtk.Button add_task_button;
    private Gtk.Revealer add_task_revealer;
    private Gtk.FlowBox labels_flowbox;
    private Widgets.AlertView alert_view;
    private Widgets.Popovers.LabelsPopover labels_popover;
    private Gtk.Stack main_stack;

    public Upcoming () {
        Object (
            expand: true
        );
    }

    construct {
        get_style_context ().add_class (Granite.STYLE_CLASS_WELCOME);

        alert_view = new Widgets.AlertView (
            _("Get a bird's eye view of yours upcoming tasks"),
            _("This is your timeline for the next tasks."),
            "office-calendar-symbolic"
        );

        var upcoming_icon = new Gtk.Image.from_icon_name ("planner-upcoming", Gtk.IconSize.DND);

        var upcoming_label = new Gtk.Label ("<b>%s</b>".printf (Application.utils.UPCOMING_STRING));
        upcoming_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        upcoming_label.use_markup = true;

        var show_hide_all_button = new Gtk.ToggleButton ();
        show_hide_all_button.valign = Gtk.Align.CENTER;
        show_hide_all_button.halign = Gtk.Align.CENTER;
        show_hide_all_button.get_style_context ().add_class ("planner-zoom-in-menu");
        show_hide_all_button.tooltip_text = _("Open all tasks");

        var show_hide_image = new Gtk.Image.from_icon_name ("zoom-in-symbolic", Gtk.IconSize.MENU);
        show_hide_all_button.add (show_hide_image);

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
            share_dialog.upcoming = true;
            share_dialog.destroy.connect (Gtk.main_quit);
            share_dialog.show_all ();
        });

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

        top_box.pack_start (upcoming_icon, false, false, 0);
        top_box.pack_start (upcoming_label, false, false, 12);
        top_box.pack_end (settings_button, false, false, 12);
        top_box.pack_end (action_revealer, false, false, 0);

        tasks_list = new Gtk.ListBox  ();
        tasks_list.activate_on_single_click = true;
        tasks_list.selection_mode = Gtk.SelectionMode.SINGLE;
        tasks_list.valign = Gtk.Align.START;
        tasks_list.hexpand = true;

        add_task_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        add_task_button.height_request = 32;
        add_task_button.width_request = 32;
        //add_task_button.get_style_context ().add_class ("planner-add-button");
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

        task_new_revealer = new Widgets.TaskNew (true);
        task_new_revealer.valign = Gtk.Align.END;
        task_new_revealer.when_datetime = new GLib.DateTime.now_local ().add_days (1);

        labels_flowbox = new Gtk.FlowBox ();
        labels_flowbox.selection_mode = Gtk.SelectionMode.NONE;
        labels_flowbox.margin_start = 6;
        labels_flowbox.height_request = 38;
        labels_flowbox.expand = false;

        var labels_flowbox_revealer = new Gtk.Revealer ();
        labels_flowbox_revealer.margin_start = 3;
        labels_flowbox_revealer.margin_top = 6;
        labels_flowbox_revealer.add (labels_flowbox);
        labels_flowbox_revealer.reveal_child = false;

        var t_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        t_box.hexpand = true;
        t_box.pack_start (top_box, false, false, 0);
        t_box.pack_start (labels_flowbox_revealer, false, false, 0);

        var b_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        b_box.expand = true;
        b_box.pack_start (tasks_list, false, true, 0);

        main_stack = new Gtk.Stack ();
        main_stack.expand = true;
        main_stack.margin_start = 9;
        main_stack.margin_bottom = 9;
        main_stack.transition_duration = 350;
        main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        main_stack.add_named (b_box, "main");
        main_stack.add_named (alert_view, "alert");

        main_stack.visible_child_name = "main";

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.expand = true;
        box.pack_start (t_box, false, true, 0);
        box.pack_start (main_stack, false, true, 0);

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

        tasks_list.set_filter_func ((row) => {
            var item = row as Widgets.TaskRow;
            return item.task.checked == 0;
        });

        tasks_list.set_sort_func ((row1, row2) => {
            var item1 = row1 as Widgets.TaskRow;
            var item2 = row2 as Widgets.TaskRow;

            var date1 = new GLib.DateTime.from_iso8601 (item1.task.when_date_utc, new GLib.TimeZone.local ());
            var date2 = new GLib.DateTime.from_iso8601 (item2.task.when_date_utc, new GLib.TimeZone.local ());

            return date1.compare (date2);
        });

        Gdk.Display display = Gdk.Display.get_default ();
        Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);

        // Signals
        settings_button.toggled.connect (() => {
            if (action_revealer.reveal_child) {
                settings_button.get_style_context ().remove_class ("closed");
                action_revealer.reveal_child = false;
            } else {
                action_revealer.reveal_child = true;
                settings_button.get_style_context ().add_class ("closed");
            }
        });

        add_task_button.clicked.connect (() => {
            task_on_revealer ();
        });

        task_new_revealer.on_signal_close.connect (() => {
            task_on_revealer ();
        });

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
                task.is_inbox = 1;
                task.when_date_utc = new GLib.DateTime.now_local ().add_days (1).to_string ();

                if (Application.database.add_task (task) == Sqlite.DONE) {
                    // Notificacion Here ...
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

        tasks_list.remove.connect ((widget) => {
            check_visible_alertview ();
        });

        Application.database.update_task_signal.connect ((task) => {
            if (Application.utils.is_task_repeted (tasks_list, task.id) == false) {
                add_new_task (task);
            }

            foreach (Gtk.Widget element in tasks_list.get_children ()) {
                var row = element as Widgets.TaskRow;

                if (row.task.id == task.id) {
                    var _when = new GLib.DateTime.from_iso8601 (task.when_date_utc, new GLib.TimeZone.local ());

                    if ((Application.utils.is_upcoming (_when) == false) || task.when_date_utc == "") {
                        Timeout.add (20, () => {
                            row.opacity = row.opacity - 0.1;

                            if (row.opacity <= 0) {
                                row.destroy ();
                                return false;
                            }

                            return true;
                        });
                    } else {
                        row.set_update_task (task);
                    }
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

    public void check_visible_alertview () {
        if (Application.utils.is_listbox_empty (tasks_list)) {
            main_stack.visible_child_name = "alert";
        } else {
            main_stack.visible_child_name = "main";
        }

        show_all ();
    }

    private void add_new_task (Objects.Task task) {
        if (task.when_date_utc != "") {
            var when = new GLib.DateTime.from_iso8601 (task.when_date_utc, new GLib.TimeZone.local ());

            if (Application.utils.is_upcoming (when)) {
                var row = new Widgets.TaskRow (task);

                row.on_signal_update.connect ((_task) => {
                    var _when = new GLib.DateTime.from_iso8601 (_task.when_date_utc, new GLib.TimeZone.local ());

                    if ((Application.utils.is_upcoming (_when) == false) || _task.when_date_utc == "") {
                        string view = "";

                        if (_task.when_date_utc == "") {
                            if (_task.is_inbox == 1) {
                                view = Application.utils.INBOX_STRING;
                            } else {
                                var project = new Objects.Project ();
                                project = Application.database.get_project (_task.project_id);
                                view = project.name;
                            }
                        } else if (Application.utils.is_today (_when)) {
                            view = Application.utils.TODAY_STRING;
                        }

                        Application.notification.send_local_notification (
                            task.content,
                            _("It was moved to %s").printf (view),
                            "document-export",
                            3,
                            false
                        );

                        Timeout.add (20, () => {
                            row.opacity = row.opacity - 0.1;

                            if (row.opacity <= 0) {
                                row.destroy ();
                                return false;
                            }

                            return true;
                        });
                    }
                });

                tasks_list.add (row);
                tasks_list.show_all ();
            }

            check_visible_alertview ();
        }
    }

    public void apply_remove () {
        foreach (Gtk.Widget element in tasks_list.get_children ()) {
            var row = element as Widgets.TaskRow;
            var when = new GLib.DateTime.from_iso8601 (row.task.when_date_utc, new GLib.TimeZone.local ());

            if ((Application.utils.is_upcoming (when) == false) || row.task.when_date_utc == "") {
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
        all_tasks = Application.database.get_all_upcoming_tasks ();

        foreach (var task in all_tasks) {
            var row = new Widgets.TaskRow (task);

            tasks_list.add (row);

            row.on_signal_update.connect ((_task) => {
                var _when = new GLib.DateTime.from_iso8601 (_task.when_date_utc, new GLib.TimeZone.local ());

                if ((Application.utils.is_upcoming (_when) == false) || _task.when_date_utc == "") {
                    string view = "";

                    if (_task.when_date_utc == "") {
                        if (_task.is_inbox == 1) {
                            view = Application.utils.INBOX_STRING;
                        } else {
                            var project = new Objects.Project ();
                            project = Application.database.get_project (_task.project_id);
                            view = project.name;
                        }
                    } else if (Application.utils.is_today (_when)) {
                        view = Application.utils.TODAY_STRING;
                    }

                    Application.notification.send_local_notification (
                        task.content,
                        _("It was moved to %s").printf (view),
                        "document-export",
                        3,
                        false
                    );

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

            task_new_revealer.when_datetime = new GLib.DateTime.now_local ().add_days (1);
        }

        tasks_list.unselect_all ();
    }
}
