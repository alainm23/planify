public class Views.Today : Gtk.EventBox {
    public MainWindow window { get; construct; }
    private Widgets.TaskNew task_new_revealer;
    private Gtk.ListBox tasks_list;
    private Gtk.Button add_task_button;
    private Gtk.Revealer add_task_revealer;
    public Gtk.InfoBar infobar;
    private Gtk.Label infobar_label;
    private Gtk.FlowBox labels_flowbox;
    private Widgets.AlertView alert_view;
    private Widgets.Popovers.LabelsPopover labels_popover;

    private bool show_all_tasks = true;
    private Gtk.Button show_all_tasks_button;
    public Today () {
        Object (
            expand: true
        );
    }

    construct {
        get_style_context ().add_class (Granite.STYLE_CLASS_WELCOME);

        alert_view = new Widgets.AlertView (
            _("You're all done for today!"),
            _("Enjoy your day"),
            "emblem-default-symbolic"
        );
        alert_view.margin_bottom = 64;
        alert_view.no_show_all = true;
        alert_view.visible = false;

        var today_icon = new Gtk.Image.from_icon_name ("planner-today-" + new GLib.DateTime.now_local ().get_day_of_month ().to_string (), Gtk.IconSize.DND);

        var today_name = new Gtk.Label ("<b>%s</b>".printf (_("Today")));
        today_name.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        today_name.use_markup = true;

        var show_all_button = new Gtk.Button.from_icon_name ("zoom-in-symbolic", Gtk.IconSize.MENU);
        show_all_button.get_style_context ().add_class ("planner-zoom-in-menu");
        show_all_button.tooltip_text = _("Open all tasks");
        show_all_button.valign = Gtk.Align.CENTER;
        show_all_button.halign = Gtk.Align.CENTER;

        var hide_all_button = new Gtk.Button.from_icon_name ("zoom-out-symbolic", Gtk.IconSize.MENU);
        hide_all_button.get_style_context ().add_class ("planner-zoom-out-menu");
        hide_all_button.tooltip_text = _("Close all tasks");
        hide_all_button.valign = Gtk.Align.CENTER;
        hide_all_button.halign = Gtk.Align.CENTER;

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

        var action_grid = new Gtk.Grid ();
        action_grid.column_spacing = 12;

        action_grid.add (labels_button);
        action_grid.add (paste_button);
        action_grid.add (share_button);
        action_grid.add (show_all_button);
        action_grid.add (hide_all_button);

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
        top_box.margin_start = 24;
        top_box.margin_end = 16;
        top_box.margin_top = 24;

        top_box.pack_start (today_icon, false, false, 0);
        top_box.pack_start (today_name, false, false, 12);
        top_box.pack_end (settings_button, false, false, 12);
        top_box.pack_end (action_revealer, false, false, 0);

        tasks_list = new Gtk.ListBox  ();
        tasks_list.activate_on_single_click = true;
        tasks_list.selection_mode = Gtk.SelectionMode.SINGLE;
        tasks_list.expand = true;
        tasks_list.margin_start = 20;
        tasks_list.margin_end = 6;
        tasks_list.margin_top = 6;

        add_task_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
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

        task_new_revealer = new Widgets.TaskNew (true);
        task_new_revealer.valign = Gtk.Align.END;
        task_new_revealer.when_button.set_date (new GLib.DateTime.now_local (), false, new GLib.DateTime.now_local ());

        show_all_tasks_button = new Gtk.Button.with_label (_("Show completed tasks"));
        show_all_tasks_button.can_focus = false;
        show_all_tasks_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        show_all_tasks_button.valign = Gtk.Align.END;
        show_all_tasks_button.halign = Gtk.Align.START;
        show_all_tasks_button.margin_bottom = 6;
        show_all_tasks_button.margin_start = 12;

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
		});

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
        box.pack_start (labels_flowbox_revealer, false, false, 0);
        box.pack_start (alert_view, true, true, 0);
        box.pack_start (tasks_list, true, true, 0);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (box);

        infobar = new Gtk.InfoBar ();
        infobar.add_button (_("OK"), 1);
        infobar.get_style_context ().add_class ("planner-infobar");
        infobar.revealed = false;

        infobar_label = new Gtk.Label ("");
        infobar.get_content_area ().add (infobar_label);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (infobar, false, false, 0);
        main_box.pack_start (scrolled, true, true, 0);

        var main_overlay = new Gtk.Overlay ();
        main_overlay.add_overlay (add_task_revealer);
        main_overlay.add_overlay (task_new_revealer);
        main_overlay.add_overlay (show_all_tasks_button);
        main_overlay.add (main_box);

        add (main_overlay);
        update_tasks_list ();
        check_visible_alertview ();

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

            show_all_tasks_button.visible = false;
            show_all_tasks_button.no_show_all = true;
        });

        task_new_revealer.on_signal_close.connect (() => {
            task_on_revealer ();

            show_all_tasks_button.visible = true;
            show_all_tasks_button.no_show_all = false;
        });

        paste_button.clicked.connect (() => {
            string text = clipboard.wait_for_text ();

            if (text == "") {
                // Notificacion Here ...
            } else {
                var task = new Objects.Task ();
                task.content = text;
                task.is_inbox = 1;
                task.when_date_utc = new GLib.DateTime.now_local ().to_string ();

                if (Planner.database.add_task (task) == Sqlite.DONE) {
                    // Notificacion Here ...
                }
            }

            tasks_list.unselect_all ();
        });

        hide_all_button.clicked.connect (() => {
            foreach (Gtk.Widget element in tasks_list.get_children ()) {
                var row = element as Widgets.TaskRow;
                row.hide_content ();
            }
        });

        show_all_button.clicked.connect (() => {
            foreach (Gtk.Widget element in tasks_list.get_children ()) {
                var row = element as Widgets.TaskRow;
                row.show_content ();
            }
        });

        this.event.connect ((event) => {
            var button_press = Planner.settings.get_enum ("button-press");

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


        infobar.response.connect ((id) => {
            infobar_apply_remove ();
        });

        labels_button.clicked.connect (() => {
            labels_popover.update_label_list ();
            labels_popover.show_all ();
        });

        labels_popover.on_selected_label.connect ((label) => {
            if (Planner.utils.is_label_repeted (labels_flowbox, label.id) == false) {
                var child = new Widgets.LabelChild (label);
                labels_flowbox.add (child);
            }

            labels_flowbox_revealer.reveal_child = !Planner.utils.is_empty (labels_flowbox);
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
            if (Planner.utils.is_empty (labels_flowbox)) {
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

        Planner.database.update_task_signal.connect ((task) => {
            if (Planner.utils.is_task_repeted (tasks_list, task.id) == false) {
                add_new_task (task);
            }
        });

        Planner.database.add_task_signal.connect (() => {
            var task = Planner.database.get_last_task ();
            add_new_task (task);
        });
    }

    public void check_visible_alertview () {
        if (Planner.utils.is_listbox_empty (tasks_list)) {
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
        var when = new GLib.DateTime.from_iso8601 (task.when_date_utc, new GLib.TimeZone.local ());

        if (Granite.DateTime.is_same_day (new GLib.DateTime.now_local (), when)) {
            var row = new Widgets.TaskRow (task);

            row.on_signal_update.connect (() => {
                int i = 0;
                foreach (Gtk.Widget element in tasks_list.get_children ()) {
                    var item = element as Widgets.TaskRow;

                    var _when = new GLib.DateTime.from_iso8601 (item.task.when_date_utc, new GLib.TimeZone.local ());

                    if (Granite.DateTime.is_same_day (new GLib.DateTime.now_local (), _when) == false) {
                        i = i + 1;
                        item.name_label.opacity = 0.7;
                    }
                }

                if (i > 0) {
                    infobar_label.label = i.to_string () + " " + _("to-do moved out of the Today");
                    infobar.revealed = true;
                } else {
                    infobar.revealed = false;
                }

                tasks_list.unselect_all ();
            });

            tasks_list.add (row);
            tasks_list.show_all ();
        }

        check_visible_alertview ();
    }

    public void infobar_apply_remove () {
        infobar.revealed = false;

        foreach (Gtk.Widget element in tasks_list.get_children ()) {
            var row = element as Widgets.TaskRow;

            var when = new GLib.DateTime.from_iso8601 (row.task.when_date_utc, new GLib.TimeZone.local ());

            if (Granite.DateTime.is_same_day (new GLib.DateTime.now_local (), when) == false) {
                tasks_list.remove (element);
            }
        }
    }

    public void update_tasks_list () {
        foreach (Gtk.Widget element in tasks_list.get_children ()) {
            tasks_list.remove (element);
        }

        var all_tasks = new Gee.ArrayList<Objects.Task?> ();
        all_tasks = Planner.database.get_all_today_tasks ();

        foreach (var task in all_tasks) {
            var row = new Widgets.TaskRow (task);
            tasks_list.add (row);

            row.on_signal_update.connect (() => {
                int i = 0;
                foreach (Gtk.Widget element in tasks_list.get_children ()) {
                    var item = element as Widgets.TaskRow;

                    var when = new GLib.DateTime.from_iso8601 (item.task.when_date_utc, new GLib.TimeZone.local ());

                    if (Granite.DateTime.is_same_day (new GLib.DateTime.now_local (), when) == false) {
                        i = i + 1;
                        item.name_label.opacity = 0.7;
                    }
                }

                if (i > 0) {
                    infobar_label.label = i.to_string () + " " + _("to-do moved out of the Today");
                    infobar.revealed = true;
                } else {
                    infobar.revealed = false;
                }

                tasks_list.unselect_all ();
            });
        }

        tasks_list.show_all ();

        if (Planner.utils.is_listbox_empty (tasks_list)) {
            alert_view.visible = true;
            alert_view.no_show_all = false;

            tasks_list.visible = false;
            tasks_list.no_show_all = true;
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

            task_new_revealer.when_button.set_date (new GLib.DateTime.now_local (), false, new GLib.DateTime.now_local ());
        }

        tasks_list.unselect_all ();
    }
}
