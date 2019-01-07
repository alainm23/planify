/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Widgets.TaskRow : Gtk.ListBoxRow {
    public Objects.Task task { get; construct; }

    private Gtk.FlowBox labels_flowbox;
    private Gtk.CheckButton checked_button;
    public Gtk.Label name_label;
    private Gtk.Entry name_entry;
    private Gtk.Button close_button;
    private Gtk.Button remove_button;

    private Gtk.Image note_preview_icon;
    private Gtk.Image label_preview_icon;
    private Gtk.Label checklist_preview_label;
    private Gtk.Box checklist_preview_box;
    private Gtk.Label when_preview_label;

    public Gtk.Box previews_box;
    private Gtk.Label project_preview_label;
    private Gtk.Box reminder_preview_box;
    private Gtk.Label reminder_preview_label;
    public Gtk.Box project_preview_box;

    private Gtk.Revealer labels_flowbox_revealer;

    private Gtk.TextView note_view;
    private Gtk.Label note_view_placeholder_label;
    public Gtk.Revealer bottom_box_revealer;
    private Gtk.Grid main_grid;
    private Gtk.EventBox name_eventbox;
    private Gtk.ListBox checklist;

    private Gtk.Box top_box;
    private Gtk.Revealer remove_revealer;
    private Gtk.Revealer close_revealer;

    public Gtk.Box project_box;

    private Widgets.WhenButton when_button;
    /*
    private const Gtk.TargetEntry targetEntriesProjectRow [] = {
		{ "ProjectRow", Gtk.TargetFlags.SAME_APP, 0 }
	};
    */
    public signal void on_signal_update (Objects.Task task);
    public signal void on_signal_remove (Objects.Task task);

    public TaskRow (Objects.Task _task) {
        Object (
            task: _task
        );
    }

    construct {
        get_style_context ().add_class ("task");

        checked_button = new Gtk.CheckButton ();
        checked_button.can_focus = false;

        if (task.checked == 1) {
            checked_button.active = true;
        } else {
            checked_button.active = false;
        }

        tooltip_text = task.content;

        name_label = new Gtk.Label (task.content);
        name_label.margin_start = 6;
        name_label.halign = Gtk.Align.START;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        name_label.use_markup = true;
        name_label.margin_bottom = 1;
        name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        name_entry = new Gtk.Entry ();
        name_entry.text = task.content;
        name_entry.hexpand = true;
        name_entry.margin_bottom = 1;
        name_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        name_entry.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        name_entry.get_style_context ().add_class ("planner-entry");
        name_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        name_entry.no_show_all = true;

        close_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.MENU);
        close_button.height_request = 24;
        close_button.width_request = 24;
        close_button.get_style_context ().add_class ("button-close");

        close_revealer = new Gtk.Revealer ();
        close_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        close_revealer.add (close_button);
        close_revealer.reveal_child = false;
        close_revealer.valign = Gtk.Align.START;
        close_revealer.halign = Gtk.Align.END;

        note_preview_icon = new Gtk.Image ();
        note_preview_icon.gicon = new ThemedIcon ("planner-note-symbolic");
        note_preview_icon.pixel_size = 14;

        check_note_preview_icon ();

        label_preview_icon = new Gtk.Image ();
        label_preview_icon.gicon = new ThemedIcon ("planner-label-symbolic");
        label_preview_icon.pixel_size = 14;

        check_label_preview_icon ();

        var checklist_preview_icon = new Gtk.Image ();
        checklist_preview_icon.gicon = new ThemedIcon ("planner-checklist-symbolic");
        checklist_preview_icon.pixel_size = 14;

        checklist_preview_label = new Gtk.Label (null);
        checklist_preview_label.use_markup = true;

        checklist_preview_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        checklist_preview_box.pack_start (checklist_preview_icon, false, false, 0);
        checklist_preview_box.pack_start (checklist_preview_label, false, false, 3);

        check_checklist_progress ();

        when_preview_label = new Gtk.Label (null);
        when_preview_label.margin_start = 6;
        when_preview_label.valign = Gtk.Align.CENTER;
        when_preview_label.use_markup = true;
        when_preview_label.get_style_context ().add_class ("planner-when-preview");

        check_when_preview_icon ();

        var reminder_preview_icon = new Gtk.Image ();
        reminder_preview_icon.gicon = new ThemedIcon ("planner-notification-symbolic");
        reminder_preview_icon.pixel_size = 14;

        reminder_preview_label = new Gtk.Label (null);

        reminder_preview_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        reminder_preview_box.pack_start (reminder_preview_icon, false, false, 0);
        reminder_preview_box.pack_start (reminder_preview_label, false, false, 3);

        check_reminder_preview_icon ();

        var project_preview_icon = new Gtk.Grid ();
		project_preview_icon.get_style_context ().add_class ("proyect-%i".printf (task.project_id));
		project_preview_icon.set_size_request (12, 12);
		project_preview_icon.margin = 6;

        project_preview_label = new Gtk.Label (null);

        project_preview_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        project_preview_box.pack_start (project_preview_label, false, false, 0);
        project_preview_box.pack_start (project_preview_icon, false, false, 3);

        if (task.is_inbox == 1) {
            project_preview_label.label = _("Inbox");
        } else {
            var project = Application.database.get_project (task.project_id);
            project_preview_label.label = project.name;
        }

        previews_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        previews_box.pack_start (when_preview_label, false, false, 0);
        previews_box.pack_start (name_label, false, false, 0);
        previews_box.pack_start (note_preview_icon, false, false, 3);
        previews_box.pack_start (label_preview_icon, false, false, 3);
        previews_box.pack_start (checklist_preview_box, false, false, 3);
        previews_box.pack_start (reminder_preview_box, false, false, 3);
        previews_box.pack_end (project_preview_box, false, false, 0);

        name_eventbox = new Gtk.EventBox ();
        name_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        name_eventbox.add (previews_box);

        top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.hexpand = true;
        top_box.pack_start (checked_button, false, false, 0);
        top_box.pack_start (name_eventbox, true, true, 0);
        top_box.pack_start (name_entry, true, true, 6);

        note_view = new Gtk.TextView ();
        note_view.opacity = 0.8;
		note_view.set_wrap_mode (Gtk.WrapMode.WORD);
        note_view.height_request = 50;
        note_view.margin_start = 36;
        note_view.margin_end = 12;
		note_view.buffer.text = task.note;
        note_view.get_style_context ().add_class ("note-view");

        note_view_placeholder_label = new Gtk.Label (_("Note"));
        note_view_placeholder_label.opacity = 0.65;
        note_view.add (note_view_placeholder_label);

        if (note_view.buffer.text != "") {
            note_view_placeholder_label.visible = false;
            note_view_placeholder_label.no_show_all = true;
        }

        var note_eventbox = new Gtk.EventBox ();
        note_eventbox.add (note_view);

        checklist = new Gtk.ListBox  ();
        checklist.activate_on_single_click = true;
        checklist.get_style_context ().add_class ("view");
        checklist.selection_mode = Gtk.SelectionMode.SINGLE;

        update_checklist ();

        var checklist_button = new Gtk.CheckButton ();
        checklist_button.get_style_context ().add_class ("planner-radio-disable");
        checklist_button.sensitive = false;

        var checklist_entry = new Gtk.Entry ();
        checklist_entry.hexpand = true;
        checklist_entry.margin_bottom = 1;
        checklist_entry.placeholder_text = _("Checklist");
        checklist_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        checklist_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        checklist_entry.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        checklist_entry.get_style_context ().add_class ("planner-entry");

        var checklist_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        checklist_box.pack_start (checklist_button, false, false, 0);
        checklist_box.pack_start (checklist_entry, true, true, 6);

        var checklist_grid = new Gtk.Grid ();
        checklist_grid.margin_start = 36;
        checklist_grid.margin_end = 12;
        checklist_grid.orientation = Gtk.Orientation.VERTICAL;
        checklist_grid.add (checklist);
        checklist_grid.add (checklist_box);

        labels_flowbox = new Gtk.FlowBox ();
        labels_flowbox.selection_mode = Gtk.SelectionMode.NONE;
        labels_flowbox.margin_start = 6;
        labels_flowbox.height_request = 38;
        labels_flowbox.expand = true;

        labels_flowbox_revealer = new Gtk.Revealer ();
        labels_flowbox_revealer.margin_start = 22;
        labels_flowbox_revealer.margin_top = 6;
        labels_flowbox_revealer.add (labels_flowbox);
        labels_flowbox_revealer.reveal_child = false;

        update_labels ();

        bool has_reminder = false;
        if (task.has_reminder == 0) {
            has_reminder = false;
            task.reminder_time = new GLib.DateTime.now_local ().to_string ();
        } else {
            has_reminder = true;
        }

        when_button = new Widgets.WhenButton ();
        when_button.set_date (
            new GLib.DateTime.from_iso8601 (task.when_date_utc, new GLib.TimeZone.local ()),
            has_reminder,
            new GLib.DateTime.from_iso8601 (task.reminder_time, new GLib.TimeZone.local ())
        );

        var labels = new Widgets.LabelButton ();

        var move_button = new Widgets.MoveButton ();
        move_button.tooltip_text = _("Move task");

        remove_button = new Gtk.Button.from_icon_name ("user-trash-symbolic", Gtk.IconSize.MENU);
        remove_button.tooltip_text = _("Delete task");
        remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        remove_button.valign = Gtk.Align.CENTER;

        var menu_button = new Gtk.ToggleButton ();
        menu_button.can_focus = false;
        menu_button.add (new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.MENU));
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        menu_button.get_style_context ().add_class ("settings-button");
        menu_button.get_style_context ().add_class ("menu-button");

        var menu_popover = new Widgets.Popovers.TaskMenu (menu_button);

        var action_box =  new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        action_box.margin_top = 6;
        action_box.margin_end = 3;
        action_box.margin_bottom = 6;
        action_box.margin_start = 28;
        action_box.valign = Gtk.Align.CENTER;
        action_box.pack_start (when_button, false, false, 0);
        action_box.pack_start (labels, false, false, 0);
        action_box.pack_end (menu_button, false, false, 0);
        action_box.pack_end (remove_button, false, false, 0);
        action_box.pack_end (move_button, false, false, 0);

        var bottom_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        bottom_box.pack_start (note_eventbox);
        bottom_box.pack_start (checklist_grid);
        bottom_box.pack_start (labels_flowbox_revealer);
        bottom_box.pack_start (action_box);

        bottom_box_revealer = new Gtk.Revealer ();
        bottom_box_revealer.add (bottom_box);
        bottom_box_revealer.transition_duration = 300;
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
        main_overlay.add (main_grid);

        var main_eventbox = new Gtk.EventBox ();
        main_eventbox.margin_start = 6;
        main_eventbox.margin_end = 9;
        main_eventbox.margin_bottom = 3;
        main_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        main_eventbox.add (main_overlay);

        add (main_eventbox);
        check_task_completed ();
        //build_drag_and_drop ();

        // Signals
        menu_button.toggled.connect (() => {
            if (menu_button.active) {
                menu_popover.show_all ();
            }
        });

        menu_popover.closed.connect (() => {
            menu_button.active = false;
        });

        menu_popover.on_selected_menu.connect ((index) => {
            if (index == 0) {

            } else if (index == 1) {
                if (Application.database.add_task (task) == Sqlite.DONE) {
                    var _task = Application.database.get_last_task ();
                    Application.signals.go_task_page (_task.id, _task.project_id);
                }
            } else {
                // Share task
                var share_dialog = new Dialogs.ShareDialog (Application.instance.main_window);
                share_dialog.task = task.id;
                share_dialog.destroy.connect (Gtk.main_quit);
                share_dialog.show_all ();
            }
        });

        move_button.on_selected_project.connect ((is_inbox, project) => {
            if (is_inbox) {
                task.is_inbox = 1;
                task.project_id = 0;

                project_preview_label.label = _("Inbox");
                project_preview_icon.get_style_context ().add_class ("proyect-%i".printf (task.project_id));

                hide_content ();
            } else {
                task.is_inbox = 0;
                task.project_id = project.id;

                project_preview_label.label = project.name;
                project_preview_icon.get_style_context ().add_class ("proyect-%i".printf (task.project_id));

                hide_content ();
            }

            Application.notification.send_local_notification (
                task.content,
                _("It was moved to <b>%s</b>").printf (project_preview_label.label),
                "document-export",
                3,
                false
            );
        });

        name_entry.focus_in_event.connect (() => {
            name_entry.secondary_icon_name = "edit-clear-symbolic";
            return false;
        });

        name_entry.focus_out_event.connect (() => {
            name_entry.secondary_icon_name = null;
            return false;
        });

        name_entry.changed.connect (() => {
            name_entry.text = Application.utils.first_letter_to_up (name_entry.text);
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                name_label.label = name_entry.text;
                check_task_completed ();
                hide_content ();
            }

            return false;
        });

        name_entry.activate.connect (() => {
            check_task_completed ();
            hide_content ();
        });

        name_entry.icon_press.connect ((pos, event) => {
			if (pos == Gtk.EntryIconPosition.SECONDARY) {
				name_entry.text = "";
			}
		});

        name_eventbox.button_press_event.connect ((event) => {
            check_task_completed ();
            show_content ();
        });

        close_button.clicked.connect (() => {
            close_revealer.reveal_child = false;
            remove_revealer.reveal_child = false;

            check_task_completed ();
            hide_content ();
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
            update_task ();
        });

        name_eventbox.enter_notify_event.connect ((event) => {
            /*
            name_label.get_style_context ().add_class ("text-hover");
            previews_box.get_style_context ().add_class ("text-hover");
            get_style_context ().add_class ("task-hover");
            */

            return false;
        });

        name_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }
            /*
            name_label.get_style_context ().remove_class ("text-hover");
            previews_box.get_style_context ().remove_class ("text-hover");
            get_style_context ().remove_class ("task-hover");
            */
            return false;
        });

        remove_button.clicked.connect (() => {
            close_revealer.reveal_child = false;
            remove_revealer.reveal_child = false;

            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Are you sure you want to delete this task?"),
                "",
                "dialog-warning",
            Gtk.ButtonsType.CANCEL);

            var remove_button = new Gtk.Button.with_label (_("Delete Task"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                if (Application.database.remove_task (task) == Sqlite.DONE) {
                    /*
                    var task_preview = "";
                    if (task.content.length > 15) {
                        task_preview = task.content.substring (0, 14) + " ...";
                    } else {
                        task_preview = task.content;
                    }
                    */
                    on_signal_remove (task);

                    Timeout.add (20, () => {
                        this.opacity = this.opacity - 0.1;

                        if (this.opacity <= 0) {
                            destroy ();
                            return false;
                        }

                        return true;
                    });
                }
            }

            message_dialog.destroy ();
        });

        checklist_entry.activate.connect (() => {
            if (checklist_entry.text != "") {
                var row = new Widgets.CheckRow (checklist_entry.text, false);
                checklist.add (row);

                checklist_entry.text = "";
                checklist.show_all ();
            }
        });

        checklist_entry.changed.connect (() => {
            checklist_entry.text = Application.utils.first_letter_to_up (checklist_entry.text);
        });

        checklist_entry.focus_out_event.connect (() => {
            if (checklist_entry.text != "") {
                var row = new Widgets.CheckRow (checklist_entry.text, false);
                checklist.add (row);

                checklist_entry.text = "";
                checklist.show_all ();
            }

            return false;
        });

        note_view.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                check_task_completed ();
                hide_content ();
            }

            return false;
        });

        main_eventbox.enter_notify_event.connect ((event) => {
            if (bottom_box_revealer.reveal_child == true) {
                close_revealer.reveal_child = true;
                remove_revealer.reveal_child = true;
            }

            return false;
        });

        main_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            close_revealer.reveal_child = false;
            remove_revealer.reveal_child = false;

            return false;
        });

        labels.on_selected_label.connect ((label) => {
            if (is_repeted (label.id) == false) {
                var child = new Widgets.LabelChild (label);
                labels_flowbox.add (child);
            }

            labels_flowbox_revealer.reveal_child = !is_empty (labels_flowbox);
            labels_flowbox.show_all ();
        });

        labels_flowbox.remove.connect ((widget) => {
            labels_flowbox_revealer.reveal_child = !is_empty (labels_flowbox);
        });

        note_view.focus_out_event.connect (() => {
            if (note_view.buffer.text == "") {
                note_view_placeholder_label.visible = true;
                note_view_placeholder_label.no_show_all = false;
            }

            return false;
        });

        note_view.focus_in_event.connect (() => {
            note_view_placeholder_label.visible = false;
            note_view_placeholder_label.no_show_all = true;

            return false;
        });

        Application.signals.go_task_page.connect ((task_id, project_id) => {
            if (task.id == task_id) {
                bool b = false;
                int c = 0;

                Timeout.add (200, () => {
                    if (b) {
                        name_label.get_style_context ().add_class ("text-hover");
                        previews_box.get_style_context ().add_class ("text-hover");
                        get_style_context ().add_class ("task-hover");

                        b = false;
                    } else {
                        name_label.get_style_context ().remove_class ("text-hover");
                        previews_box.get_style_context ().remove_class ("text-hover");
                        get_style_context ().remove_class ("task-hover");

                        b = true;
                    }

                    c = c + 1;

                    if (c > 5) {
                        c = 0;

                        name_label.get_style_context ().remove_class ("text-hover");
                        previews_box.get_style_context ().remove_class ("text-hover");
                        get_style_context ().remove_class ("task-hover");

                        return false;
                    }

                    return true;
                });
            }
        });
    }

    private bool is_repeted (int id) {
        foreach (Gtk.Widget element in labels_flowbox.get_children ()) {
            var child = element as Widgets.LabelChild;
            if (child.label.id == id) {
                return true;
            }
        }

        return false;
    }

    private bool is_empty (Gtk.FlowBox flowbox) {
        int l = 0;
        foreach (Gtk.Widget element in flowbox.get_children ()) {
            l = l + 1;
        }

        if (l <= 0) {
            return true;
        } else {
            return false;
        }
    }

    private void update_checklist () {
        foreach (Gtk.Widget element in checklist.get_children ()) {
            checklist.remove (element);
        }

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
	    }

        checklist.show_all ();
    }

    private void update_labels () {
        foreach (Gtk.Widget element in labels_flowbox.get_children ()) {
            labels_flowbox.remove (element);
        }

        string[] labels_array = task.labels.split (";");

        foreach (string id in labels_array) {
            var label = Application.database.get_label (id);

            if (label.id != 0) {
                var child = new Widgets.LabelChild (label);
                labels_flowbox.add (child);
            }
        }

        labels_flowbox.show_all ();

        if (is_empty (labels_flowbox) == false) {
            labels_flowbox_revealer.reveal_child = true;
        }
    }

    private void check_task_completed () {
        if (name_entry.text != "") {
            name_label.label = name_entry.text;
        }

        if (checked_button.active) {
            previews_box.opacity = 0.7;
        } else {
            previews_box.opacity = 1;
        }
    }

    public void check_checklist_progress () {
        if (task.checklist == "") {
            checklist_preview_box.visible = false;
            checklist_preview_box.no_show_all = true;
        } else {
            checklist_preview_box.visible = true;
            checklist_preview_box.no_show_all = false;

            string[] checklist_array = task.checklist.split (";");
            int all = -1;
            int completed = 0;

            foreach (string str in checklist_array) {
                if (str.substring (0, 1) == "1") {
                    completed = completed + 1;
                }

                all = all + 1;
            }

            checklist_preview_label.label = "%i/%i".printf (completed, all);
        }
    }

    public void check_when_preview_icon () {
        if (task.when_date_utc == "") {
            when_preview_label.no_show_all = true;
            when_preview_label.visible = false;
        } else {
            when_preview_label.no_show_all = false;
            when_preview_label.visible = true;

            var when_datetime = new GLib.DateTime.from_iso8601 (task.when_date_utc, new GLib.TimeZone.local ());
            string date_format = Application.utils.get_default_date_format_from_date (when_datetime);

            if (Application.utils.is_today (when_datetime)) {
                when_preview_label.label = "<small>%s</small>".printf (_("Today"));
            } else if (Application.utils.is_tomorrow (when_datetime)) {
                when_preview_label.label = "<small>%s</small>".printf (_("Tomorrow"));
            } else {
                when_preview_label.label = "<small>%s</small>".printf (when_datetime.format (date_format));
            }
        }
    }

    public void check_reminder_preview_icon () {
        if (task.has_reminder == 0) {
            reminder_preview_box.no_show_all = true;
            reminder_preview_box.visible = false;
        } else {
            reminder_preview_box.no_show_all = false;
            reminder_preview_box.visible = true;

            string time_format = Granite.DateTime.get_default_time_format (true, false);
            var reminder_datetime = new GLib.DateTime.from_iso8601 (task.reminder_time, new GLib.TimeZone.local ());
            reminder_preview_label.label = reminder_datetime.format (time_format);
        }
    }

    public void show_content () {
        main_grid.get_style_context ().add_class ("popover");
        main_grid.get_style_context ().add_class ("planner-popover");

        bottom_box_revealer.reveal_child = true;

        main_grid.margin_start = 5;
        top_box.margin_top = 6;
        top_box.margin_start = 12;
        project_box.margin_end = 6;

        name_entry.visible = true;
        name_eventbox.visible = false;
        name_eventbox.no_show_all = true;

        close_revealer.halign = Gtk.Align.START;
        has_tooltip = false;

        name_entry.text = name_label.label;
    }

    public void hide_content () {
        main_grid.get_style_context ().remove_class ("popover");
        main_grid.get_style_context ().remove_class ("planner-popover");

        main_grid.margin_start = 0;
        top_box.margin_top = 0;
        top_box.margin_start = 0;
        project_box.margin_end = 0;

        name_entry.visible = false;
        name_eventbox.visible = true;
        name_eventbox.no_show_all = false;

        bottom_box_revealer.reveal_child = false;
        close_revealer.halign = Gtk.Align.END;

        if (name_entry.text != "") {
            update_task ();
            tooltip_text = name_entry.text;
            has_tooltip = true;
        }
    }

    public void check_note_preview_icon () {
        if (task.note == "") {
            note_preview_icon.visible = false;
            note_preview_icon.no_show_all = true;
        } else {
            note_preview_icon.visible = true;
            note_preview_icon.no_show_all = false;
        }
    }

    public void check_label_preview_icon () {
        if (task.labels == "") {
            label_preview_icon.visible = false;
            label_preview_icon.no_show_all = true;
        } else {
            label_preview_icon.visible = true;
            label_preview_icon.no_show_all = false;
        }
    }

    public void set_update_task (Objects.Task _task) {
        task.id = _task.id;
        task.checked = _task.checked;
        task.project_id = _task.project_id;
        task.list_id = _task.list_id;
        task.task_order = _task.task_order;
        task.is_inbox = _task.is_inbox;
        task.has_reminder = _task.has_reminder;
        task.sidebar_width = _task.sidebar_width;
        task.was_notified = _task.was_notified;
        task.content = _task.content;
        task.note = _task.note;
        task.when_date_utc = _task.when_date_utc;
        task.reminder_time = _task.reminder_time;
        task.labels = _task.labels;
        task.checklist = _task.checklist;

        if (_task.checked == 1) {
            checked_button.active = true;
        } else {
            checked_button.active = false;
        }

        name_label.label = _task.content;
        name_entry.text = _task.content;

        if (task.is_inbox == 1) {
            project_preview_label.label = _("Inbox");
        } else {
            var project = Application.database.get_project (task.project_id);
            project_preview_label.label = project.name;
        }

        note_view.buffer.text = task.note;
        if (note_view.buffer.text != "") {
            note_view_placeholder_label.visible = false;
            note_view_placeholder_label.no_show_all = true;
        }

        bool has_reminder = false;
        if (task.has_reminder == 0) {
            has_reminder = false;
            task.reminder_time = new GLib.DateTime.now_local ().to_string ();
        } else {
            has_reminder = true;
        }

        when_button.set_date (
            new GLib.DateTime.from_iso8601 (task.when_date_utc, new GLib.TimeZone.local ()),
            has_reminder,
            new GLib.DateTime.from_iso8601 (task.reminder_time, new GLib.TimeZone.local ())
        );

        check_note_preview_icon ();
        check_label_preview_icon ();
        check_checklist_progress ();
        check_when_preview_icon ();
        check_reminder_preview_icon ();
        update_checklist ();
        update_labels ();
        show_all ();
    }

    public void update_task () {
        task.project_id = task.project_id;
        task.content = name_entry.text;
        task.note = note_view.buffer.text;

        check_note_preview_icon ();

        if (checked_button.active) {
            task.checked = 1;
        } else {
            task.checked = 0;
        }

        if (when_button.has_when) {
            task.when_date_utc = when_button.when_datetime.to_string ();

            if (Application.utils.is_today (when_button.when_datetime)) {
                when_preview_label.label = "<small>%s</small>".printf (_("Today"));
            } else if (Application.utils.is_tomorrow (when_button.when_datetime)) {
                when_preview_label.label = "<small>%s</small>".printf (_("Tomorrow"));
            } else {
                string date_format = Application.utils.get_default_date_format_from_date (when_button.when_datetime);
                when_preview_label.label = "<small>%s</small>".printf (when_button.when_datetime.format (date_format));
            }

            when_preview_label.visible = true;
            when_preview_label.no_show_all = false;
        } else {
            task.when_date_utc = "";

            when_preview_label.visible = false;
            when_preview_label.no_show_all = true;
        }

        if (when_button.reminder_datetime.to_string () != task.reminder_time) {
            task.was_notified = 0;

            if (when_button.has_reminder) {
                // Send Notification
                string date = "";
                string time = "";

                string time_format = Granite.DateTime.get_default_time_format (true, false);
                time = when_button.reminder_datetime.format (time_format);

                if (Application.utils.is_today (when_button.when_datetime)) {
                    date = _("Today").down ();
                } else if (Application.utils.is_tomorrow (when_button.when_datetime)) {
                    date = _("Tomorrow").down ();
                } else {
                    string date_format = Application.utils.get_default_date_format_from_date (when_button.when_datetime);
                    date = when_button.when_datetime.format (date_format);
                }

                Application.notification.send_local_notification (
                    task.content,
                    _("You'll be notified %s at %s".printf (date, time)),
                    "preferences-system-time",
                    5,
                    false);
            }
        }

        if (when_button.has_reminder) {
            task.has_reminder = 1;
            task.reminder_time = when_button.reminder_datetime.to_string ();

            reminder_preview_box.visible = true;
            reminder_preview_box.no_show_all = false;

            string time_format = Granite.DateTime.get_default_time_format (true, false);
            reminder_preview_label.label = when_button.reminder_datetime.format (time_format);
        } else {
            task.has_reminder = 0;
            task.reminder_time = "";

            reminder_preview_box.visible = false;
            reminder_preview_box.no_show_all = true;
        }

        task.labels = "";
        foreach (Gtk.Widget element in labels_flowbox.get_children ()) {
            var child = element as Widgets.LabelChild;
            task.labels = task.labels + child.label.id.to_string () + ";";
        }

        task.checklist = "";
        foreach (Gtk.Widget element in checklist.get_children ()) {
            var row = element as Widgets.CheckRow;
            task.checklist = task.checklist + row.get_check ();
        }


        if (Application.database.update_task (task) == Sqlite.DONE) {
            Application.database.update_task_signal (task);
            on_signal_update (task);

            check_label_preview_icon ();
            check_checklist_progress ();

            show_all ();
        }
    }

    /*
    private void build_drag_and_drop () {
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, targetEntriesProjectRow, Gdk.DragAction.MOVE);

        drag_begin.connect (on_drag_begin);
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = (widget as Widgets.TaskRow);

        Gtk.Allocation alloc;
		row.get_allocation (out alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr = new Cairo.Context (surface);
		cr.set_source_rgba (0, 0, 0, 0.3);
		cr.set_line_width (1);

        cr.move_to (0, 0);
		cr.line_to (alloc.width, 0);
		cr.line_to (alloc.width, alloc.height);
		cr.line_to (0, alloc.height);
		cr.line_to (0, 0);
		cr.stroke ();

        cr.set_source_rgba (255, 255, 255, 0.5);
		cr.rectangle (0, 0, alloc.width, alloc.height);
		cr.fill ();

        row.main_grid.draw (cr);

		Gtk.drag_set_icon_surface (context, surface);
    }
    */
 }
