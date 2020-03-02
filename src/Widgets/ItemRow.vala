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

public class Widgets.ItemRow : Gtk.ListBoxRow {
    public Objects.Item item { get; construct; }

    public bool _is_today = false;
    public bool is_today {
        get {
            return _is_today;
        }

        set {
            _is_today = value;
            duedate_preview_revealer.reveal_child = !value;

            project = Planner.database.get_project_by_id (item.project_id);
            project_preview_label.label = "<small>%s</small>".printf (project.name);
            project_preview_revealer.reveal_child = true;

            var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
            if (Planner.utils.is_before_today (datetime)) {
                duedate_preview_revealer.reveal_child = true;
                check_duedate_style ();
            }

            check_preview_box ();
        }
    }

    public GLib.DateTime? _upcoming = null;
    public GLib.DateTime? upcoming {
        get {
            return _upcoming;
        }

        set {
            _upcoming = value;
            duedate_preview_revealer.reveal_child = false;

            project = Planner.database.get_project_by_id (item.project_id);
            project_preview_label.label = "<small>%s</small>".printf (project.name);
            project_preview_revealer.reveal_child = true;

            check_preview_box ();
        }
    }

    private Objects.Project project { get; set; }

    private Gtk.Button hidden_button;
    private Gtk.Revealer hidden_revealer;
    private Gtk.CheckButton checked_button;
    private Gtk.Entry content_entry;
    private Gtk.Label content_label;
    private Gtk.Revealer label_revealer;
    private Gtk.Revealer entry_revealer;

    private Gtk.Box top_box;
    private Gtk.TextView note_textview;
    private Gtk.Label note_placeholder;
    private Gtk.Revealer note_preview_revealer;
    private Gtk.Revealer bottom_revealer;
    private Gtk.Revealer main_revealer;
    private Gtk.Grid main_grid;
    private Gtk.Label duedate_preview_label;
    private Gtk.Image project_preview_image;
    private Gtk.Label project_preview_label;
    private Gtk.Revealer project_preview_revealer;
    private Gtk.Revealer preview_revealer;
    private Gtk.Grid duedate_preview_grid;
    private Gtk.Box preview_box;
    private Gtk.Revealer motion_revealer;
    private Gtk.Revealer labels_preview_box_revealer;
    private Gtk.Revealer duedate_preview_revealer;
    private Gtk.Box labels_preview_box;
    private Gtk.Box labels_edit_box;

    private Gtk.Label reminder_preview_label;
    private Objects.Reminder? reminder = null;
    private Gtk.Revealer reminder_preview_revealer;

    private Widgets.NewCheck new_checklist;
    private Gtk.Revealer checklist_preview_revealer;
    private Gtk.ListBox check_listbox;
    private Gtk.Revealer separator_revealer;

    private Gtk.Menu projects_menu;
    private Gtk.Menu sections_menu;
    private Widgets.ImageMenuItem undated_menu;
    private Widgets.DueButton due_button;
    private Widgets.ImageMenuItem move_section_menu;
    private Gtk.Menu menu = null;

    private uint checked_timeout = 0;
    private uint timeout_id = 0;
    private bool save_off = false;

    public Gee.HashMap<string, bool> labels_hashmap;

    private const Gtk.TargetEntry[] TARGET_ENTRIES = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] TARGET_ENTRIES_MAGIC_BUTTON = {
        {"MAGICBUTTON", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] TARGET_ENTRIES_CHECK = {
        {"CHECKROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public signal void update_headers ();

    public bool reveal_child {
        set {
            if (value) {
                show_item ();
            }
        }
        get {
            return bottom_revealer.reveal_child;
        }
    }

    public bool reveal_drag_motion {
        set {
            motion_revealer.reveal_child = value;
        }
        get {
            return motion_revealer.reveal_child;
        }
    }

    public ItemRow (Objects.Item item) {
        Object (
            item: item
        );
    }

    construct {
        can_focus = false;
        margin_start = 6;
        margin_top = 3;
        get_style_context ().add_class ("item-row");
        labels_hashmap = new Gee.HashMap<string, bool> ();

        hidden_button = new Gtk.Button.from_icon_name ("view-restore-symbolic", Gtk.IconSize.MENU);
        hidden_button.can_focus = false;
        hidden_button.margin_top = 1;
        hidden_button.margin_end = 3;
        hidden_button.tooltip_text = _("View Details");
        hidden_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hidden_button.get_style_context ().add_class ("hidden-button");

        hidden_revealer = new Gtk.Revealer ();
        hidden_revealer.valign = Gtk.Align.START;
        hidden_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        hidden_revealer.add (hidden_button);

        checked_button = new Gtk.CheckButton ();
        checked_button.can_focus = false;
        checked_button.margin_top = 6;
        checked_button.valign = Gtk.Align.START;
        checked_button.halign = Gtk.Align.BASELINE;
        checked_button.get_style_context ().add_class ("checklist-button");
        checked_button.active = item.checked == 1;

        content_label = new Gtk.Label (item.content);
        content_label.hexpand = true;
        content_label.valign = Gtk.Align.START;
        content_label.xalign = 0;
        content_label.margin_top = 5;
        content_label.get_style_context ().add_class ("label");
        content_label.wrap = true;

        label_revealer = new Gtk.Revealer ();
        label_revealer.valign = Gtk.Align.START;
        label_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        label_revealer.transition_duration = 125;
        label_revealer.add (content_label);
        label_revealer.reveal_child = true;

        content_entry = new Gtk.Entry ();
        content_entry.valign = Gtk.Align.START;
        content_entry.placeholder_text = _("Task name");
        content_entry.get_style_context ().add_class ("flat");
        content_entry.get_style_context ().add_class ("label");
        content_entry.get_style_context ().add_class ("content-entry");
        content_entry.get_style_context ().add_class ("font-bold");
        content_entry.get_style_context ().add_class ("no-padding-left");
        content_entry.text = item.content;
        content_entry.hexpand = true;

        entry_revealer = new Gtk.Revealer ();
        entry_revealer.valign = Gtk.Align.START;
        entry_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        entry_revealer.transition_duration = 125;
        entry_revealer.add (content_entry);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.hexpand = true;
        content_box.add (entry_revealer);
        content_box.add (label_revealer);

        top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.pack_start (checked_button, false, false, 0);
        top_box.pack_start (content_box, false, true, 8);
        top_box.pack_end (hidden_revealer, false, false, 0);

        // Preview Icons
        project_preview_image = new Gtk.Image ();
        project_preview_image.gicon = new ThemedIcon ("mail-unread-symbolic");
        project_preview_image.pixel_size = 16;
        project_preview_image.get_style_context ().add_class ("project-color-%s".printf (item.project_id.to_string ()));

        project_preview_label = new Gtk.Label (null);
        project_preview_label.get_style_context ().add_class ("pane-item");
        project_preview_label.margin_end = 6;
        project_preview_label.use_markup = true;

        var project_preview_grid = new Gtk.Grid ();
        project_preview_grid.column_spacing = 3;
        project_preview_grid.margin_end = 6;
        project_preview_grid.halign = Gtk.Align.CENTER;
        project_preview_grid.valign = Gtk.Align.CENTER;
        project_preview_grid.add (project_preview_image);
        project_preview_grid.add (project_preview_label);

        project_preview_revealer = new Gtk.Revealer ();
        project_preview_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        project_preview_revealer.add (project_preview_grid);

        var duedate_preview_image = new Gtk.Image ();
        duedate_preview_image.valign = Gtk.Align.CENTER;
        duedate_preview_image.gicon = new ThemedIcon ("office-calendar-symbolic");
        duedate_preview_image.pixel_size = 12;

        duedate_preview_label = new Gtk.Label (null);
        duedate_preview_label.get_style_context ().add_class ("pane-item");
        duedate_preview_label.use_markup = true;

        duedate_preview_grid = new Gtk.Grid ();
        duedate_preview_grid.column_spacing = 3;
        duedate_preview_grid.margin_end = 6;
        duedate_preview_grid.halign = Gtk.Align.CENTER;
        duedate_preview_grid.valign = Gtk.Align.CENTER;
        duedate_preview_grid.add (duedate_preview_image);
        duedate_preview_grid.add (duedate_preview_label);

        duedate_preview_revealer = new Gtk.Revealer ();
        duedate_preview_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        duedate_preview_revealer.add (duedate_preview_grid);
        duedate_preview_revealer.reveal_child = false;

        check_duedate_style ();

        // Reminder
        reminder = Planner.database.get_first_reminders_by_item (item.id);

        var reminder_preview_image = new Gtk.Image ();
        reminder_preview_image.valign = Gtk.Align.CENTER;
        reminder_preview_image.gicon = new ThemedIcon ("alarm-symbolic");
        reminder_preview_image.pixel_size = 12;

        reminder_preview_label = new Gtk.Label (null);
        reminder_preview_label.get_style_context ().add_class ("pane-item");
        reminder_preview_label.use_markup = true;

        var reminder_preview_grid = new Gtk.Grid ();
        reminder_preview_grid.column_spacing = 3;
        reminder_preview_grid.margin_end = 6;
        reminder_preview_grid.halign = Gtk.Align.CENTER;
        reminder_preview_grid.valign = Gtk.Align.CENTER;
        reminder_preview_grid.add (reminder_preview_image);
        reminder_preview_grid.add (reminder_preview_label);

        reminder_preview_revealer = new Gtk.Revealer ();
        reminder_preview_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        reminder_preview_revealer.add (reminder_preview_grid);

        // Checklist
        var checklist_preview_image = new Gtk.Image ();
        checklist_preview_image.margin_end = 6;
        checklist_preview_image.gicon = new ThemedIcon ("view-list-compact-symbolic");
        checklist_preview_image.pixel_size = 14;
        checklist_preview_image.margin_top = 1;
        checklist_preview_image.get_style_context ().add_class ("dim-label");

        checklist_preview_revealer = new Gtk.Revealer ();
        checklist_preview_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        checklist_preview_revealer.add (checklist_preview_image);

        // Note
        var note_preview_image = new Gtk.Image ();
        note_preview_image.gicon = new ThemedIcon ("emblem-documents-symbolic");
        note_preview_image.pixel_size = 12;
        note_preview_image.margin_end = 6;
        note_preview_image.get_style_context ().add_class ("dim-label");

        note_preview_revealer = new Gtk.Revealer ();
        note_preview_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        note_preview_revealer.add (note_preview_image);

        // Labels Preview
        labels_preview_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        labels_preview_box.margin_end = 6;

        labels_preview_box_revealer = new Gtk.Revealer ();
        labels_preview_box_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        labels_preview_box_revealer.add (labels_preview_box);

        preview_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        preview_box.margin_start = 22;
        preview_box.hexpand = true;
        preview_box.pack_start (project_preview_revealer, false, false, 0);
        preview_box.pack_start (duedate_preview_revealer, false, false, 0);
        preview_box.pack_start (reminder_preview_revealer, false, false, 0);
        preview_box.pack_start (checklist_preview_revealer, false, false, 0);
        preview_box.pack_start (note_preview_revealer, false, false, 0);
        preview_box.pack_start (labels_preview_box_revealer, false, false, 0);

        preview_revealer = new Gtk.Revealer ();
        preview_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        preview_revealer.add (preview_box);

        // Preview Box Validator
        if (item.due_date != "") {
            duedate_preview_label.label = "<small>%s</small>".printf (
                Planner.utils.get_relative_date_from_string (item.due_date)
            );
            duedate_preview_revealer.reveal_child = true;
            check_preview_box ();
        }

        check_reminder_preview_label (reminder);
        Planner.utils.clock_format_changed.connect (() => {
            check_reminder_preview_label (reminder);
        });

        if (item.note != "") {
            note_preview_revealer.reveal_child = true;
            check_preview_box ();
        }

        // Note TextView
        note_textview = new Gtk.TextView ();
        note_textview.margin_start = 22;
        note_textview.buffer.text = item.note;
        note_textview.wrap_mode = Gtk.WrapMode.WORD;
        note_textview.get_style_context ().add_class ("textview");
        note_textview.height_request = 42;

        note_placeholder = new Gtk.Label (_("Note"));
        note_placeholder.opacity = 0.7;
        note_textview.add (note_placeholder);
        if (item.note != "") {
            note_placeholder.visible = false;
            note_placeholder.no_show_all = true;
        }

        // Checklist ListBox
        check_listbox = new Gtk.ListBox ();
        check_listbox.margin_top = 6;
        check_listbox.margin_start = 18;
        check_listbox.get_style_context ().add_class ("check-listbox");
        Gtk.drag_dest_set (check_listbox, Gtk.DestDefaults.ALL, TARGET_ENTRIES_CHECK, Gdk.DragAction.MOVE);
        check_listbox.drag_data_received.connect (on_drag_data_received);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_start = 18;
        separator.margin_bottom = 6;
        separator.margin_end = 9;

        separator_revealer = new Gtk.Revealer ();
        separator_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        separator_revealer.add (separator);

        // New Checklist Widget
        new_checklist = new Widgets.NewCheck (item.id, item.project_id, item.section_id, item.is_todoist);

        /*
            Actions
        */

        labels_edit_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);

        due_button = new Widgets.DueButton (item);

        var reminder_button = new Widgets.ReminderButton (item);

        var label_button = new Widgets.LabelButton (item.id);
        label_button.margin_start = 12;

        var checklist_icon = new Gtk.Image ();
        checklist_icon.gicon = new ThemedIcon ("view-list-compact-symbolic");
        checklist_icon.pixel_size = 18;

        var checklist_button = new Gtk.Button ();
        checklist_button.image = checklist_icon;
        checklist_button.margin_end = 12;
        checklist_button.tooltip_text = _("Add Checklist");
        checklist_button.get_style_context ().add_class ("flat");
        checklist_button.get_style_context ().add_class ("item-action-button");

        var delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic", Gtk.IconSize.MENU);
        delete_button.can_focus = false;
        delete_button.valign = Gtk.Align.CENTER;
        delete_button.tooltip_text = _("Delete Task");
        delete_button.get_style_context ().add_class ("flat");
        delete_button.get_style_context ().add_class ("item-action-button");
        delete_button.get_style_context ().add_class ("menu-danger");

        var menu_image = new Gtk.Image ();
        menu_image.gicon = new ThemedIcon ("view-more-symbolic");
        menu_image.pixel_size = 14;

        var menu_button = new Gtk.Button ();
        menu_button.image = menu_image;
        menu_button.valign = Gtk.Align.CENTER;
        menu_button.can_focus = false;
        menu_button.tooltip_text = _("Task Menu");
        menu_button.get_style_context ().add_class ("item-action-button");
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        action_box.margin_top = 3;
        action_box.margin_start = 24;
        action_box.margin_bottom = 6;
        action_box.margin_end = 6;
        action_box.pack_start (labels_edit_box, false, true, 0);
        action_box.pack_end (menu_button, false, false, 0);
        action_box.pack_end (delete_button, false, false, 0);
        action_box.pack_end (checklist_button, false, true, 0);
        action_box.pack_end (label_button, false, true, 0);
        action_box.pack_end (reminder_button, false, true, 0);
        action_box.pack_end (due_button, false, true, 0);

        var bottom_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        bottom_box.pack_start (note_textview, false, true, 0);
        bottom_box.pack_start (check_listbox, false, false, 0);
        bottom_box.pack_start (separator_revealer, false, false, 0);
        bottom_box.pack_start (new_checklist, false, false, 0);
        bottom_box.pack_end (action_box, false, true, 0);

        bottom_revealer = new Gtk.Revealer ();
        bottom_revealer.valign = Gtk.Align.START;
        bottom_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        bottom_revealer.add (bottom_box);

        /*
            Motion Revealer
        */

        var motion_grid = new Gtk.Grid ();
        motion_grid.margin_end = 16;
        motion_grid.margin_top = 3;
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;

        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        main_grid = new Gtk.Grid ();
        main_grid.hexpand = true;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.get_style_context ().add_class ("transition");
        main_grid.add (top_box);
        main_grid.add (preview_revealer);
        main_grid.add (bottom_revealer);

        var grid = new Gtk.Grid ();
        grid.hexpand = true;
        grid.orientation = Gtk.Orientation.VERTICAL;

        grid.add (main_grid);
        grid.add (motion_revealer);

        var handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.expand = true;
        handle.above_child = false;
        handle.add (grid);

        main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = true;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (handle);

        add (main_revealer);

        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);
        drag_end.connect (clear_indicator);

        build_drag_and_drop (false);

        add_all_checks ();
        add_all_labels ();

        checklist_button.clicked.connect (() => {
            new_checklist.reveal_child = true;
        });

        content_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_item ();
            }

            return false;
        });

        content_entry.activate.connect (() => {
            hide_item ();
        });

        content_entry.changed.connect (() => {
            save ();
        });

        note_textview.buffer.changed.connect (() => {
            save (false);

            if (note_textview.buffer.text == "") {
                note_preview_revealer.reveal_child = false;
            } else {
                note_preview_revealer.reveal_child = true;
            }

            check_preview_box ();
        });

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

        note_textview.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_item ();
            }

            return false;
        });

        Planner.utils.drag_magic_button_activated.connect ((value) => {
            build_drag_and_drop (value);
        });

        hidden_button.clicked.connect (() => {
            if (reveal_child == false) {
                show_item ();
            } else {
                hide_item ();
            }
        });

        Planner.database.item_added.connect ((i) => {
            if (item.id == i.parent_id) {
                var row = new Widgets.CheckRow (i);

                row.hide_item.connect (hide_item);

                check_listbox.add (row);
                check_listbox.show_all ();

                check_checklist_separator ();
            }
        });

        Planner.database.item_label_added.connect ((id, item_id, label) => {
            if (item.id == item_id && labels_hashmap.has_key (label.id.to_string ()) == false) {
                var l = new Widgets.LabelPreview (id, item_id, label);
                var g = new Widgets.LabelItem (id, item.id, label);

                labels_preview_box.add (l);
                labels_edit_box.add (g);

                labels_preview_box.show_all ();
                labels_edit_box.show_all ();

                labels_preview_box_revealer.reveal_child = true;
                labels_hashmap.set (label.id.to_string (), true);
                check_preview_box ();
            }
        });

        Planner.database.item_label_deleted.connect ((id, item_id, label) => {
            if (item.id == item_id) {
                labels_hashmap.unset (label.id.to_string ());
                labels_preview_box_revealer.reveal_child = labels_hashmap.size > 0;
                check_preview_box ();
            }
        });

        delete_button.clicked.connect (() => {
            if (Planner.database.add_item_to_delete (item)) {
                get_style_context ().remove_class ("item-row-selected");
                main_revealer.reveal_child = false;
            }
        });

        Planner.database.item_deleted.connect ((i) => {
            Idle.add (() => {
                if (item.id == i.id) {
                    destroy ();
                }

                return false;
            });
        });

        Planner.database.show_undo_item.connect ((id) => {
            if (item.id == id) {
                hide_item ();
                hidden_revealer.reveal_child = false;
                main_revealer.reveal_child = true;
            }
        });

        button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                if (bottom_revealer.reveal_child == false) {
                    activate_menu ();
                }

                return true;
            }

            return false;
        });

        menu_button.clicked.connect (() => {
            activate_menu ();
        });

        checked_button.toggled.connect (checked_toggled);

        check_listbox.remove.connect (() => {
            check_checklist_separator ();
        });

        Planner.database.update_due_item.connect ((i) => {
            if (item.id == i.id) {
                var datetime = new GLib.DateTime.from_iso8601 (i.due_date, new GLib.TimeZone.local ());

                duedate_preview_label.label = "<small>%s</small>".printf (
                    Planner.utils.get_relative_date_from_date (datetime)
                );
                duedate_preview_revealer.reveal_child = true;
                check_preview_box ();

                check_duedate_style ();
                due_button.update_date_text (i.due_date);

                if (is_today) {
                    duedate_preview_revealer.reveal_child = false;
                    check_preview_box ();

                    if (Planner.utils.is_today (datetime) == false &&
                        Planner.utils.is_before_today (datetime) == false) {
                        hide_item ();

                        Timeout.add (1000, () => {
                            destroy ();
                            return false;
                        });
                    }
                }

                if (upcoming != null) {
                    duedate_preview_revealer.reveal_child = false;
                    check_preview_box ();

                    if (Granite.DateTime.is_same_day (datetime, upcoming) == false) {
                        hide_item ();

                        Timeout.add (1000, () => {
                            destroy ();
                            return false;
                        });
                    }
                }
            }
        });

        Planner.database.add_due_item.connect ((i) => {
            if (item.id == i.id) {
                duedate_preview_label.label = "<small>%s</small>".printf (
                    Planner.utils.get_relative_date_from_date (
                        new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ())
                    )
                );

                duedate_preview_revealer.reveal_child = true;
                check_preview_box ();
                check_duedate_style ();
                due_button.update_date_text (i.due_date);
            }
        });

        Planner.database.remove_due_item.connect ((i) => {
            if (item.id == i.id) {
                duedate_preview_label.label = "";

                duedate_preview_revealer.reveal_child = false;
                check_preview_box ();
                check_duedate_style ();
                due_button.update_date_text (i.due_date);

                if (is_today || upcoming != null) {
                    hide_item ();

                    Timeout.add (1500, () => {
                        destroy ();
                        return false;
                    });
                }
            }
        });

        Planner.database.item_updated.connect ((i) => {
            Idle.add (() => {
                if (item.id == i.id) {
                    save_off = true;

                    item.content = i.content;
                    item.note = i.note;

                    content_entry.text = item.content;
                    content_label.label = item.content;
                    note_textview.buffer.text = item.note;

                    if (note_textview.buffer.text == "") {
                        note_placeholder.visible = true;
                        note_placeholder.no_show_all = false;
                    } else {
                        note_placeholder.visible = false;
                        note_placeholder.no_show_all = true;
                    }

                    Timeout.add (250, () => {
                        save_off = false;
                        return false;
                    });
                }

                return false;
            });
        });

        Planner.database.item_moved.connect ((i, project_id, old_project_id) => {
            if (item.id == i.id) {
                item.project_id = project_id;

                if (upcoming != null || is_today == true) {
                    project = Planner.database.get_project_by_id (item.project_id);

                    foreach (string c in project_preview_image.get_style_context ().list_classes ()) {
                        project_preview_image.get_style_context ().remove_class (c);
                    }
                    project_preview_image.get_style_context ().add_class ("project-color-%s".printf (project.id.to_string ()));
                    project_preview_label.label = "<small>%s</small>".printf (project.name);

                    project_preview_revealer.reveal_child = true;
                }
            }
        });

        Planner.database.reminder_deleted.connect ((id) => {
            if (reminder != null && reminder.id == id) {
                reminder = Planner.database.get_first_reminders_by_item (item.id);
                check_reminder_preview_label (reminder);
            }
        });

        Planner.database.reminder_added.connect (() => {
            reminder = Planner.database.get_first_reminders_by_item (item.id);
            check_reminder_preview_label (reminder);
        });

        /*
        Planner.instance.go_view.connect ((type, id, id2) => {
            if (item.id == id) {
                bool b = false;
                int c = 0;

                Timeout.add (200, () => {
                    if (b) {
                        get_style_context ().add_class ("item-hover");

                        b = false;
                    } else {
                        get_style_context ().remove_class ("item-hover");

                        b = true;
                    }

                    c = c + 1;

                    if (c > 5) {
                        c = 0;
                        get_style_context ().remove_class ("item-hover");

                        return false;
                    }

                    return true;
                });
            }
        });
        */

        Planner.database.item_completed.connect ((i) => {
            Idle.add (() => {
                if (item.id == i.id) {
                    if (i.checked == 1) {
                        checked_button.active = true;
                        content_label.get_style_context ().add_class ("label-line-through");
                        sensitive = false;

                        checked_timeout = Timeout.add (750, () => {
                            main_revealer.reveal_child = false;
                            return false;
                        });
                    }
                }

                return false;
            });
        });

        Planner.database.item_id_updated.connect ((current_id, new_id) => {
            Idle.add (() => {
                if (item.id == current_id) {
                    item.id = new_id;
                }

                return false;
            });
        });

        Planner.database.project_id_updated.connect ((current_id, new_id) => {
            Idle.add (() => {
                if (item.project_id == current_id) {
                    item.project_id = new_id;
                }

                return false;
            });
        });

        Planner.database.section_id_updated.connect ((current_id, new_id) => {
            Idle.add (() => {
                if (item.section_id == current_id) {
                    item.section_id = new_id;
                }

                return false;
            });
        });

        Planner.database.project_updated.connect ((project) => {
            if (item.project_id == project.id) {
                foreach (string c in project_preview_image.get_style_context ().list_classes ()) {
                    project_preview_image.get_style_context ().remove_class (c);
                }
                project_preview_image.get_style_context ().add_class ("project-color-%s".printf (project.id.to_string ()));
                project_preview_label.label = "<small>%s</small>".printf (project.name);
            }
        });

        Planner.database.project_deleted.connect ((id) => {
            if (item.project_id == id) {
                main_revealer.reveal_child = false;

                Timeout.add (500, () => {
                    destroy ();
                    return false;
                });
            }
        });

        Planner.database.section_deleted.connect ((s) => {
            if (item.section_id == s.id) {
                main_revealer.reveal_child = false;

                Timeout.add (500, () => {
                    destroy ();
                    return false;
                });
            }
        });

        check_listbox.row_activated.connect ((row) => {
            var item = ((Widgets.CheckRow) row);
            item.edit ();
        });
    }

    private void checked_toggled () {
        if (checked_button.active) {
            item.checked = 1;
            item.date_completed = new GLib.DateTime.now_local ().to_string ();

            Planner.database.update_item_completed (item);
            if (item.is_todoist == 1) {
                Planner.todoist.item_complete (item);
            }
        }
    }

    public void content_entry_focus () {
        content_entry.grab_focus_without_selecting ();
        if (content_entry.cursor_position < content_entry.text_length) {
           content_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) content_entry.text_length, false);
        }
    }

    public void show_item () {
        if (is_today == false && upcoming == null) {
            Planner.utils.add_item_show_queue (this);
        } else {
            if (is_today) {
                Planner.utils.add_item_show_queue_view (this, "today");
            }

            if (upcoming != null) {
                Planner.utils.add_item_show_queue_view (this, "upcoming");
            }
        }

        bottom_revealer.reveal_child = true;
        main_grid.get_style_context ().add_class ("item-row-selected");
        main_grid.get_style_context ().add_class ("popover");

        entry_revealer.reveal_child = true;
        label_revealer.reveal_child = false;
        preview_revealer.reveal_child = false;
        hidden_revealer.reveal_child = true;

        hidden_button.tooltip_text = _("Hiding");

        activatable = false;
        selectable = false;

        content_entry_focus ();
    }

    public void hide_item () {
        Planner.utils.remove_item_show_queue (this);

        bottom_revealer.reveal_child = false;
        main_grid.get_style_context ().remove_class ("item-row-selected");
        main_grid.get_style_context ().remove_class ("popover");

        entry_revealer.reveal_child = false;
        label_revealer.reveal_child = true;
        hidden_revealer.reveal_child = false;

        check_preview_box ();

        hidden_button.tooltip_text = _("View Details");

        timeout_id = Timeout.add (250, () => {
            activatable = true;
            selectable = true;

            Source.remove (timeout_id);
            timeout_id = 0;

            return false;
        });
    }

    private void check_preview_box () {
        if (bottom_revealer.reveal_child == false) {
            preview_revealer.reveal_child = duedate_preview_revealer.reveal_child ||
            note_preview_revealer.reveal_child ||
            checklist_preview_revealer.reveal_child ||
            reminder_preview_revealer.reveal_child ||
            labels_preview_box_revealer.reveal_child ||
            project_preview_revealer.reveal_child;
        }

        if (project_preview_revealer.reveal_child) {
            preview_box.margin_start = 20;
        } else {
            preview_box.margin_start = 22;
        }
    }

    private void build_drag_and_drop (bool is_magic_button_active) {
        if (is_magic_button_active) {
            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, TARGET_ENTRIES_MAGIC_BUTTON, Gdk.DragAction.MOVE);
            this.drag_data_received.connect (on_drag_magic_button_received);
        } else {
            this.drag_data_received.disconnect (on_drag_magic_button_received);
            Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        }

        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);
    }

    private void on_drag_magic_button_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        Planner.utils.magic_button_activated (
            item.project_id,
            item.section_id,
            item.is_todoist,
            false,
            this.get_index () + 1
        );
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = ((Widgets.ItemRow) widget).top_box;

        Gtk.Allocation alloc;
        row.get_allocation (out alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr = new Cairo.Context (surface);
        cr.set_source_rgba (0, 0, 0, 0.5);
        cr.set_line_width (1);

        cr.move_to (0, 0);
        cr.line_to (alloc.width, 0);
        cr.line_to (alloc.width, alloc.height);
        cr.line_to (0, alloc.height);
        cr.line_to (0, 0);
        cr.stroke ();

        cr.set_source_rgba (255, 255, 255, 0);
        cr.rectangle (0, 0, alloc.width, alloc.height);
        cr.fill ();

        row.get_style_context ().add_class ("drag-begin");
        row.margin_start = 6;
        row.draw (cr);
        row.get_style_context ().remove_class ("drag-begin");
        row.margin_start = 0;

        Gtk.drag_set_icon_surface (context, surface);
        main_revealer.reveal_child = false;
        Planner.utils.drag_item_activated (true);
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (ItemRow))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("ITEMROW"), 32, data
        );
    }

    public void clear_indicator (Gdk.DragContext context) {
        reveal_drag_motion = false;
        main_revealer.reveal_child = true;
        Planner.utils.drag_item_activated (false);
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        reveal_drag_motion = true;
        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        reveal_drag_motion = false;
    }

    private void save (bool online=true) {
        if (save_off == false) {
            content_label.label = content_entry.text;

            content_label.tooltip_text = item.content;
            item.content = content_entry.text;
            item.note = note_textview.buffer.text;

            if (online) {
                item.save ();
            } else {
                item.save_local ();
            }
        }
    }

    private void add_all_checks () {
        foreach (var check in Planner.database.get_all_cheks_by_item (item.id)) {
            var row = new Widgets.CheckRow (check);

            row.hide_item.connect (hide_item);

            check_listbox.add (row);
            check_listbox.show_all ();
        }

        check_checklist_separator ();
    }

    private void add_all_labels () {
        foreach (var label in Planner.database.get_labels_by_item (item.id)) {
            var l = new Widgets.LabelPreview (label.item_label_id, item.id, label);
            var g = new Widgets.LabelItem (label.item_label_id, item.id, label);

            labels_preview_box.add (l);
            labels_edit_box.add (g);

            labels_preview_box.show_all ();
            labels_edit_box.show_all ();

            labels_preview_box_revealer.reveal_child = true;
            labels_hashmap.set (label.id.to_string (), true);

            check_preview_box ();
        }
    }

    private void check_duedate_style () {
        if (item.due_date != "") {
            var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());

            duedate_preview_grid.get_style_context ().remove_class ("duedate-today");
            duedate_preview_grid.get_style_context ().remove_class ("duedate-expired");
            duedate_preview_grid.get_style_context ().remove_class ("duedate-upcoming");

            if (Planner.utils.is_today (datetime)) {
                duedate_preview_grid.get_style_context ().add_class ("duedate-today");
            }

            if (Planner.utils.is_upcoming (datetime)) {
                duedate_preview_grid.get_style_context ().add_class ("duedate-upcoming");
            } else {
                duedate_preview_grid.get_style_context ().add_class ("duedate-expired");
            }
        }
    }

    private void check_checklist_separator () {
        if (check_listbox.get_children ().length () > 0) {
            checklist_preview_revealer.reveal_child = true;
            separator_revealer.reveal_child = true;
        } else {
            checklist_preview_revealer.reveal_child = false;
            separator_revealer.reveal_child = false;
        }

        check_preview_box ();
    }

    private void activate_menu () {
        if (menu == null) {
            build_context_menu (item);
        }

        foreach (var child in projects_menu.get_children ()) {
            child.destroy ();
        }

        foreach (var child in sections_menu.get_children ()) {
            child.destroy ();
        }

        Widgets.ImageMenuItem item_menu;
        int is_todoist = 0;
        if (Planner.settings.get_boolean ("inbox-project-sync")) {
            is_todoist = 1;
        }

        if (item.is_todoist == is_todoist) {
            item_menu = new Widgets.ImageMenuItem (_("Inbox"), "mail-mailbox-symbolic");
            item_menu.activate.connect (() => {
                int64 inbox_id = Planner.settings.get_int64 ("inbox-project");

                Planner.database.move_item (item, inbox_id);
                if (item.is_todoist == 1) {
                    Planner.todoist.move_item (item, inbox_id);
                }

                string move_template = _("Task moved to <b>%s</b>");
                Planner.notifications.send_notification (
                    0,
                    move_template.printf (
                        Planner.database.get_project_by_id (inbox_id).name
                    )
                );
            });

            projects_menu.add (item_menu);
        }

        foreach (var project in Planner.database.get_all_projects ()) {
            if (item.project_id != project.id && project.inbox_project == 0 && project.is_todoist == item.is_todoist) {
                item_menu = new Widgets.ImageMenuItem (project.name, "planner-project-symbolic");
                item_menu.activate.connect (() => {
                    Planner.database.move_item (item, project.id);
                    if (item.is_todoist == 1) {
                        Planner.todoist.move_item (item, project.id);
                    }

                    string move_template = _("Task moved to <b>%s</b>");
                    Planner.notifications.send_notification (
                        0,
                        move_template.printf (
                            project.name
                        )
                    );
                });

                projects_menu.add (item_menu);
            }
        }

        if (item.section_id != 0) {
            item_menu = new Widgets.ImageMenuItem (_("No Section"), "window-close-symbolic");
            item_menu.activate.connect (() => {
                Planner.database.move_item_section (item, 0);
                if (item.is_todoist == 1) {
                    Planner.todoist.move_item_to_section (item, 0);
                }
            });

            sections_menu.add (item_menu);
        }

        int section_count = 0;
        foreach (var section in Planner.database.get_all_sections_by_project (item.project_id)) {
            if (item.section_id != section.id) {
                item_menu = new Widgets.ImageMenuItem (section.name, "go-jump-symbolic");
                item_menu.activate.connect (() => {
                    Planner.database.move_item_section (item, section.id);
                    if (item.is_todoist == 1) {
                        Planner.todoist.move_item_to_section (item, section.id);
                    }

                    string move_template = _("Task moved to <b>%s</b>");
                    Planner.notifications.send_notification (
                        0,
                        move_template.printf (
                            section.name
                        )
                    );
                });

                sections_menu.add (item_menu);
            }

            section_count++;
        }

        if (section_count > 0) {
            move_section_menu.visible = true;
            move_section_menu.no_show_all = false;
        } else {
            move_section_menu.visible = false;
            move_section_menu.no_show_all = true;
        }

        if (item.due_date == "") {
            undated_menu.visible = false;
            undated_menu.no_show_all = true;
        } else {
            undated_menu.visible = true;
            undated_menu.no_show_all = false;
        }

        projects_menu.show_all ();
        sections_menu.show_all ();

        menu.popup_at_pointer (null);
    }

    private void build_context_menu (Objects.Item item) {
        menu = new Gtk.Menu ();
        menu.width_request = 235;

        var complete_menu = new Widgets.ImageMenuItem (_("Complete"), "emblem-default-symbolic");
        var edit_menu = new Widgets.ImageMenuItem (_("Edit"), "edit-symbolic");

        string today_icon = "planner-today-day-symbolic";
        string today_css = "today-day-icon";
        var hour = new GLib.DateTime.now_local ().get_hour ();
        if (hour >= 18 || hour <= 5) {
            today_icon = "planner-today-night-symbolic";
            today_css = "today-night-icon";
        }

        var today_menu = new Widgets.ImageMenuItem (_("Today"), today_icon);
        today_menu.item_image.get_style_context ().add_class (today_css);

        var tomorrow_menu = new Widgets.ImageMenuItem (_("Tomorrow"), "x-office-calendar-symbolic");
        tomorrow_menu.item_image.get_style_context ().add_class ("upcoming-icon");

        undated_menu = new Widgets.ImageMenuItem (_("Undated"), "window-close-symbolic");
        undated_menu.item_image.get_style_context ().add_class ("due-clear");

        var move_project_menu = new Widgets.ImageMenuItem (_("Move to Project"), "planner-project-symbolic");
        projects_menu = new Gtk.Menu ();
        move_project_menu.set_submenu (projects_menu);

        move_section_menu = new Widgets.ImageMenuItem (_("Move to Section"), "go-jump-symbolic");
        sections_menu = new Gtk.Menu ();
        move_section_menu.set_submenu (sections_menu);

        var share_menu = new Widgets.ImageMenuItem (_("Share"), "emblem-shared-symbolic");
        var share_list_menu = new Gtk.Menu ();
        share_menu.set_submenu (share_list_menu);

        var share_text_menu = new Widgets.ImageMenuItem (_("Text"), "text-x-generic-symbolic");
        var share_markdown_menu = new Widgets.ImageMenuItem (_("Markdown"), "planner-markdown-symbolic");

        share_list_menu.add (share_text_menu);
        share_list_menu.add (share_markdown_menu);
        share_list_menu.show_all ();

        var duplicate_menu = new Widgets.ImageMenuItem (_("Duplicate"), "edit-copy-symbolic");
        var delete_menu = new Widgets.ImageMenuItem (_("Delete"), "user-trash-symbolic");
        delete_menu.get_style_context ().add_class ("menu-danger");

        menu.add (complete_menu);
        menu.add (edit_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (today_menu);
        menu.add (tomorrow_menu);
        menu.add (undated_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (move_project_menu);
        menu.add (move_section_menu);
        menu.add (share_menu);
        //menu.add (duplicate_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (delete_menu);

        menu.show_all ();

        complete_menu.activate.connect (() => {
            checked_button.active = !checked_button.active;
        });

        edit_menu.activate.connect (() => {
            show_item ();
        });

        today_menu.activate.connect (() => {
            due_button.set_due (new GLib.DateTime.now_local ());
        });

        tomorrow_menu.activate.connect (() => {
            due_button.set_due (new GLib.DateTime.now_local ().add_days (1));
        });

        undated_menu.activate.connect (() => {
            due_button.set_due (null);
        });

        share_text_menu.activate.connect (() => {
            item.share_text ();
        });

        share_markdown_menu.activate.connect (() => {
            item.share_markdown ();
        });

        duplicate_menu.activate.connect (() => {
            Planner.database.insert_item (item.get_duplicate ());
        });

        delete_menu.activate.connect (() => {
            if (Planner.database.add_item_to_delete (item)) {
                get_style_context ().remove_class ("item-row-selected");
                main_revealer.reveal_child = false;
            }
        });
    }

    public void check_reminder_preview_label (Objects.Reminder? reminder) {
        if (reminder != null) {
            reminder_preview_label.label = "<small>%s %s</small>".printf (
                Planner.utils.get_relative_date_from_string (reminder.due_date),
                Planner.utils.get_relative_time_from_string (reminder.due_date)
            );
            reminder_preview_revealer.reveal_child = true;
        } else {
            reminder_preview_label.label = "";
            reminder_preview_revealer.reveal_child = false;
        }

        check_preview_box ();
    }

    private void on_drag_data_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.CheckRow target;
        Widgets.CheckRow source;
        Gtk.Allocation alloc;

        target = (Widgets.CheckRow) check_listbox.get_row_at_y (y);
        target.get_allocation (out alloc);

        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.CheckRow) row;

        if (target != null) {
            if (source.item.parent_id != item.id) {
                source.item.parent_id = item.id;

                if (source.item.is_todoist == 1) {
                    Planner.todoist.move_item_to_parent (source.item, item.id);
                }
            }

            source.get_parent ().remove (source);
            check_listbox.insert (source, target.get_index () + 1);
            check_listbox.show_all ();

            update_check_order ();
        }
    }

    private void update_check_order () {
        Timeout.add (150, () => {
            new Thread<void*> ("update_check_order", () => {
                check_listbox.foreach ((widget) => {
                    var row = (Gtk.ListBoxRow) widget;
                    int index = row.get_index ();

                    var check = ((Widgets.CheckRow) row).item;
                    Planner.database.update_check_order (check, item.id, index);
                });

                return null;
            });

            return false;
        });
    }
}
