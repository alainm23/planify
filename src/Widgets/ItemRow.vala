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

    private Gtk.Button hidden_button;
    private Gtk.Revealer hidden_revealer;
    private Gtk.CheckButton checked_button;
    private Widgets.Entry content_entry;
    private Gtk.Label content_label;
    private Gtk.Revealer label_revealer;
    private Gtk.Revealer entry_revealer;

    private Gtk.Image menu_image;
    private Gtk.Image checklist_icon;
    private Gtk.Image reminder_preview_image;
    private Gtk.Image checklist_preview_image;
    private Gtk.Box top_box;
    private Widgets.TextView note_textview;
    private Gtk.Label note_label;
    private Gtk.Stack note_stack;
    private Gtk.Revealer note_preview_revealer;
    private Gtk.Revealer bottom_revealer;
    private Gtk.Revealer main_revealer;
    private Gtk.Grid main_grid;
    private Gtk.Label duedate_preview_label;
    private Gtk.Image project_preview_image;
    private Gtk.Label project_preview_label;
    private Gtk.Image duedate_repeat_image;
    private Gtk.Label checklist_preview_label;
    private Gtk.Revealer duedate_repeat_revealer;
    private Gtk.Revealer project_preview_revealer;
    private Gtk.Revealer preview_revealer;
    private Gtk.Grid duedate_preview_grid;
    private Gtk.Box preview_box;
    private Gtk.Revealer motion_revealer;
    private Gtk.Revealer labels_preview_box_revealer;
    private Gtk.Grid handle_grid;
    // private Gtk.Image duedate_preview_image;
    private Gtk.Revealer duedate_preview_revealer;
    private Gtk.Box labels_preview_box;
    private Gtk.Box labels_edit_box;
    private Gtk.Revealer labels_edit_revealer;

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
    private Widgets.ImageMenuItem edit_menu;
    private Widgets.ImageMenuItem today_menu;
    private Widgets.ImageMenuItem tomorrow_menu;
    private Gtk.SeparatorMenuItem date_separator;
    private Gtk.Menu menu = null;

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

    public bool item_selected {
        set {
            if (value) {
                handle_grid.get_style_context ().add_class ("item-ctrl-selected");
            } else {
                handle_grid.get_style_context ().remove_class ("item-ctrl-selected");
            }
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

    private Objects.Project project { get; set; }

    private string _view;
    public string view {
        get {
            return _view;
        }

        set {
            _view = value;

            if (view == "today" || view == "upcoming" || view == "label") {
                duedate_preview_revealer.reveal_child = false;

                project = Planner.database.get_project_by_id (item.project_id);
                project_preview_label.label = "<small>%s</small>".printf (project.name);
                project_preview_revealer.reveal_child = true;

                if (project.inbox_project == 1) {
                    project_preview_image.gicon = new ThemedIcon ("color-41");
                } else {
                    project_preview_image.gicon = new ThemedIcon ("color-%i".printf (project.color));
                }

                var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
                if (Planner.utils.is_overdue (datetime)) {
                    duedate_preview_revealer.reveal_child = true;
                    check_duedate_style ();
                }

                check_preview_box ();
            }
        }
    }

    public ItemRow (Objects.Item item, string view="project") {
        Object (
            item: item,
            view: view
        );
    }

    construct {
        can_focus = false;
        get_style_context ().add_class ("item-row");
        labels_hashmap = new Gee.HashMap<string, bool> ();

        hidden_button = new Gtk.Button.from_icon_name ("view-restore-symbolic", Gtk.IconSize.MENU);
        hidden_button.can_focus = false;
        hidden_button.margin_top = 1;
        hidden_button.margin_end = 3;
        hidden_button.tooltip_text = _("Hide Details");
        hidden_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hidden_button.get_style_context ().add_class ("hidden-button");

        hidden_revealer = new Gtk.Revealer ();
        hidden_revealer.valign = Gtk.Align.START;
        hidden_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        hidden_revealer.add (hidden_button);

        checked_button = new Gtk.CheckButton ();
        checked_button.can_focus = false;
        checked_button.margin_top = 6;
        checked_button.margin_start = 6;
        checked_button.valign = Gtk.Align.START;
        checked_button.halign = Gtk.Align.BASELINE;
        checked_button.active = item.checked == 1;

        check_priority_style ();

        content_label = new Gtk.Label (Planner.utils.get_markup_format (item.content));
        content_label.hexpand = true;
        content_label.valign = Gtk.Align.START;
        content_label.xalign = 0;
        content_label.margin_top = 5;
        content_label.use_markup = true;
        content_label.wrap = true;

        label_revealer = new Gtk.Revealer ();
        label_revealer.valign = Gtk.Align.START;
        label_revealer.transition_type = Gtk.RevealerTransitionType.NONE;
        label_revealer.transition_duration = 125;
        label_revealer.add (content_label);
        label_revealer.reveal_child = true;

        content_entry = new Widgets.Entry ();
        content_entry.valign = Gtk.Align.START;
        content_entry.placeholder_text = _("Task name");
        content_entry.get_style_context ().add_class ("flat");
        content_entry.get_style_context ().add_class ("content-entry");
        content_entry.get_style_context ().add_class ("font-bold");
        content_entry.get_style_context ().add_class ("no-padding-left");
        content_entry.text = item.content;
        content_entry.hexpand = true;
        content_entry.margin_top = 2;

        entry_revealer = new Gtk.Revealer ();
        entry_revealer.valign = Gtk.Align.START;
        entry_revealer.transition_type = Gtk.RevealerTransitionType.NONE;
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
        project_preview_image.pixel_size = 12;
        //project_preview_image.get_style_context ().add_class ("project-color-%s".printf (item.project_id.to_string ()));

        project_preview_label = new Gtk.Label (null);
        project_preview_label.use_markup = true;

        var project_preview_grid = new Gtk.Grid ();
        project_preview_grid.column_spacing = 3;
        project_preview_grid.margin_end = 6;
        project_preview_grid.halign = Gtk.Align.CENTER;
        project_preview_grid.valign = Gtk.Align.START;
        project_preview_grid.add (project_preview_image);
        project_preview_grid.add (project_preview_label);

        project_preview_revealer = new Gtk.Revealer ();
        project_preview_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        project_preview_revealer.add (project_preview_grid);

        duedate_preview_label = new Gtk.Label (null);
        duedate_preview_label.use_markup = true;

        duedate_repeat_image = new Gtk.Image ();
        duedate_repeat_image.valign = Gtk.Align.CENTER;
        duedate_repeat_image.pixel_size = 9;
        duedate_repeat_image.margin_top = 2;
        duedate_repeat_image.gicon = new ThemedIcon ("media-playlist-repeat-symbolic");

        duedate_repeat_revealer = new Gtk.Revealer ();
        duedate_repeat_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        duedate_repeat_revealer.add (duedate_repeat_image);

        duedate_preview_grid = new Gtk.Grid ();
        duedate_preview_grid.column_spacing = 3;
        duedate_preview_grid.margin_end = 6;
        duedate_preview_grid.halign = Gtk.Align.CENTER;
        duedate_preview_grid.valign = Gtk.Align.START;
        //  duedate_preview_grid.add (duedate_preview_image);
        duedate_preview_grid.add (duedate_preview_label);
        duedate_preview_grid.add (duedate_repeat_revealer);

        if (item.due_is_recurring == 1) {
            // duedate_preview_image.gicon = new ThemedIcon ("view-refresh-symbolic");
            duedate_preview_grid.tooltip_text = item.due_string;
        } else {
            // duedate_preview_image.gicon = new ThemedIcon ("office-calendar-symbolic");
            duedate_preview_grid.tooltip_text = "";
        }

        duedate_preview_revealer = new Gtk.Revealer ();
        duedate_preview_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        duedate_preview_revealer.add (duedate_preview_grid);
        duedate_preview_revealer.reveal_child = false;

        check_duedate_style ();

        // Reminder
        reminder = Planner.database.get_first_reminders_by_item (item.id);

        reminder_preview_image = new Gtk.Image ();
        reminder_preview_image.pixel_size = 12;
        reminder_preview_image.valign = Gtk.Align.END;
        reminder_preview_image.margin_bottom = 1;

        reminder_preview_label = new Gtk.Label (null);
        reminder_preview_label.use_markup = true;

        var reminder_preview_grid = new Gtk.Grid ();
        reminder_preview_grid.column_spacing = 3;
        reminder_preview_grid.margin_end = 6;
        reminder_preview_grid.halign = Gtk.Align.CENTER;
        reminder_preview_grid.valign = Gtk.Align.START;
        reminder_preview_grid.add (reminder_preview_image);
        reminder_preview_grid.add (reminder_preview_label);

        reminder_preview_revealer = new Gtk.Revealer ();
        reminder_preview_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        reminder_preview_revealer.add (reminder_preview_grid);

        // Checklist
        checklist_preview_image = new Gtk.Image ();
        checklist_preview_image.pixel_size = 12;
        checklist_preview_image.valign = Gtk.Align.END;
        checklist_preview_image.margin_bottom = 1;

        checklist_preview_label = new Gtk.Label (null);
        checklist_preview_label.use_markup = true;

        var checklist_preview_grid = new Gtk.Grid ();
        checklist_preview_grid.column_spacing = 3;
        checklist_preview_grid.margin_end = 6;
        checklist_preview_grid.valign = Gtk.Align.START;
        checklist_preview_grid.add (checklist_preview_image);
        checklist_preview_grid.add (checklist_preview_label);

        checklist_preview_revealer = new Gtk.Revealer ();
        checklist_preview_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        checklist_preview_revealer.add (checklist_preview_grid);

        // Note
        var note_preview_image = new Gtk.Image ();
        note_preview_image.gicon = new ThemedIcon ("text-x-generic-symbolic");
        note_preview_image.pixel_size = 10;
        note_preview_image.margin_end = 6;
        note_preview_image.valign = Gtk.Align.CENTER;

        note_preview_revealer = new Gtk.Revealer ();
        note_preview_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        note_preview_revealer.add (note_preview_image);

        // Labels Preview
        labels_preview_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        labels_preview_box.margin_end = 6;
        labels_preview_box.valign = Gtk.Align.START;

        labels_preview_box_revealer = new Gtk.Revealer ();
        labels_preview_box_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        labels_preview_box_revealer.add (labels_preview_box);

        preview_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        preview_box.margin_start = 27;
        preview_box.hexpand = true;
        preview_box.pack_start (duedate_preview_revealer, false, false, 0);
        preview_box.pack_start (project_preview_revealer, false, false, 0);
        preview_box.pack_start (reminder_preview_revealer, false, false, 0);
        preview_box.pack_start (checklist_preview_revealer, false, false, 0);
        preview_box.pack_start (note_preview_revealer, false, false, 0);
        preview_box.pack_start (labels_preview_box_revealer, false, false, 0);

        preview_revealer = new Gtk.Revealer ();
        preview_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        preview_revealer.transition_duration = 0;
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
        note_textview = new Widgets.TextView ();
        note_textview.hexpand = true;
        note_textview.valign = Gtk.Align.START;
        note_textview.wrap_mode = Gtk.WrapMode.CHAR;
        note_textview.height_request = 42;
        note_textview.get_style_context ().add_class ("textview");
        note_textview.buffer.text = item.note;

        // Note Label
        note_label = new Gtk.Label ("");
        update_note_label (item.note);
        note_label.valign = Gtk.Align.START;
        note_label.height_request = 42;
        note_label.margin_end = 3;
        note_label.wrap = true;
        note_label.wrap_mode = Pango.WrapMode.CHAR;
        note_label.xalign = 0;
        note_label.yalign = 0;
        note_label.use_markup = true;

        var note_eventbox = new Gtk.EventBox ();
        note_eventbox.hexpand = true;
        note_eventbox.add (note_label);

        note_stack = new Gtk.Stack ();
        note_stack.hexpand = true;
        note_stack.margin_start = 28;
        note_stack.margin_end = 12;
        note_stack.margin_top = 3;
        note_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        note_stack.vhomogeneous = false;
        note_stack.add_named (note_eventbox, "label");
        note_stack.add_named (note_textview, "textview");
        Gtk.drag_dest_set (note_stack, Gtk.DestDefaults.ALL, TARGET_ENTRIES_CHECK, Gdk.DragAction.MOVE);
        note_stack.drag_data_received.connect ((context, x, y, selection_data, target_type, time) => {
            Widgets.CheckRow source;

            var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
            source = (Widgets.CheckRow) row;

            if (source.item.parent_id != item.id) {
                source.item.parent_id = item.id;

                if (source.item.is_todoist == 1) {
                    Planner.todoist.move_item_to_parent (source.item, item.id);
                }
            }

            source.get_parent ().remove (source);

            check_listbox.insert (source, 0);
            check_listbox.show_all ();

            update_check_order ();
        });

        // Checklist ListBox
        check_listbox = new Gtk.ListBox ();
        check_listbox.margin_top = 12;
        check_listbox.margin_start = 22;
        check_listbox.get_style_context ().add_class ("check-listbox");
        Gtk.drag_dest_set (check_listbox, Gtk.DestDefaults.ALL, TARGET_ENTRIES_CHECK, Gdk.DragAction.MOVE);
        check_listbox.drag_data_received.connect (on_drag_data_received);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_start = 24;
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
        labels_edit_box.margin_start = 27;
        labels_edit_box.margin_top = 12;
        labels_edit_box.margin_bottom = 12;

        labels_edit_revealer = new Gtk.Revealer ();
        labels_edit_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        labels_edit_revealer.add (labels_edit_box);

        due_button = new Widgets.DueButton (item);

        var reminder_button = new Widgets.ReminderButton (item);

        var priority_button = new Widgets.PriorityButton (item);

        var label_button = new Widgets.LabelButton (item.id);

        checklist_icon = new Gtk.Image ();
        checklist_icon.pixel_size = 16;

        var checklist_button = new Gtk.Button ();
        checklist_button.image = checklist_icon;
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
        
        menu_image = new Gtk.Image ();
        menu_image.gicon = new ThemedIcon ("view-more-symbolic");
        menu_image.pixel_size = 16;
        check_icon_style ();

        var menu_button = new Gtk.Button ();
        menu_button.image = menu_image;
        menu_button.valign = Gtk.Align.CENTER;
        menu_button.can_focus = false;
        menu_button.tooltip_text = _("Task Menu");
        menu_button.get_style_context ().add_class ("item-action-button");
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        action_box.margin_top = 3;
        action_box.margin_start = 20;
        action_box.margin_bottom = 3;
        action_box.margin_end = 3;
        action_box.pack_start (due_button, false, true, 0);
        // action_box.pack_start (labels_edit_box, false, true, 0);
        action_box.pack_end (menu_button, false, false, 0);
        action_box.pack_end (reminder_button, false, true, 0);
        action_box.pack_end (priority_button, false, false, 0);
        action_box.pack_end (label_button, false, true, 0);
        action_box.pack_end (checklist_button, false, true, 0);

        var bottom_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        bottom_box.pack_start (note_stack, false, true, 0);
        bottom_box.pack_start (check_listbox, false, false, 0);
        bottom_box.pack_start (separator_revealer, false, false, 0);
        bottom_box.pack_start (new_checklist, false, false, 0);
        bottom_box.pack_start (labels_edit_revealer, false, false, 0);
        bottom_box.pack_end (action_box, false, true, 0);

        bottom_revealer = new Gtk.Revealer ();
        bottom_revealer.valign = Gtk.Align.START;
        bottom_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        bottom_revealer.add (bottom_box);

        /*
            Motion Revealer
        */

        var motion_grid = new Gtk.Grid ();
        motion_grid.margin_bottom = 3;
        motion_grid.margin_top = 6;
        motion_grid.margin_start = 6;
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

        handle_grid = new Gtk.Grid ();
        handle_grid.hexpand = true;
        handle_grid.margin_start = 6;
        handle_grid.margin_top = 3;
        handle_grid.orientation = Gtk.Orientation.VERTICAL;

        handle_grid.add (main_grid);
        handle_grid.add (motion_revealer);

        var handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.expand = true;
        handle.above_child = false;
        handle.add (handle_grid);

        main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = true;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (handle);

        add (main_revealer);
        update_checklist_progress ();
        
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);
        drag_end.connect (clear_indicator);

        build_drag_and_drop (false);

        add_all_checks ();
        add_all_labels ();

        Planner.settings.changed.connect ((key) => {
            if (key == "appearance") {
                check_icon_style ();
            }
        });

        checklist_button.clicked.connect (() => {
            new_checklist.reveal_child = true;
        });

        content_entry.key_release_event.connect ((key) => {
            // print ("keyval: %i\n".printf ((int32) key.keyval));
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

        Planner.event_bus.drag_magic_button_activated.connect ((value) => {
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
                labels_edit_revealer.reveal_child = true;
                labels_hashmap.set (label.id.to_string (), true);
                check_preview_box ();
            }
        });

        Planner.database.item_label_deleted.connect ((id, item_id, label) => {
            if (item.id == item_id) {
                labels_hashmap.unset (label.id.to_string ());
                labels_preview_box_revealer.reveal_child = labels_hashmap.size > 0;
                labels_edit_revealer.reveal_child = labels_hashmap.size > 0;
                check_preview_box ();
            }
        });

        delete_button.clicked.connect (() => {
            Planner.notifications.send_undo_notification (
                _("Task deleted"),
                Planner.utils.build_undo_object ("item_delete", "item", item.id, "", "")
            );
            main_revealer.reveal_child = false;
        });

        Planner.database.item_deleted.connect ((i) => {
            Idle.add (() => {
                if (item.id == i.id) {
                    destroy ();
                }

                return false;
            });
        });

        Planner.database.show_undo_item.connect ((i, type) => {
            if (item.id == i.id) {
                main_revealer.reveal_child = true;
            }

            if (type == "item_complete") {
                item.checked = 0;
                item.date_completed = "";
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
            activate_menu (false);
        });

        checked_button.toggled.connect (checked_toggled);

        check_listbox.remove.connect (() => {
            check_checklist_separator ();
        });

        note_eventbox.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS) {
                note_stack.visible_child_name = "textview";
                note_textview.grab_focus ();

                return true;
            }

            return false;
        });

        note_textview.focus_out_event.connect (() => {
            note_stack.visible_child_name = "label";
            update_note_label (note_textview.buffer.text);
            
            save (false);
            return false;
        });

        note_textview.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                note_stack.visible_child_name = "label";
                update_note_label (note_textview.buffer.text);
                hide_item ();
            }

            return false;
        });

        Planner.database.update_due_item.connect ((i) => {
            if (item.id == i.id) {
                item.due_date = i.due_date;
                item.due_is_recurring = i.due_is_recurring;
                item.due_string = i.due_string;
                item.due_lang = i.due_lang;

                var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());

                duedate_preview_label.label = "<small>%s</small>".printf (
                    Planner.utils.get_relative_date_from_date (datetime)
                );
                duedate_preview_revealer.reveal_child = true;
                check_preview_box ();

                check_duedate_style ();
                due_button.update_date_text (item);
            }
        });

        Planner.database.add_due_item.connect ((i) => {
            if (item.id == i.id) {
                item.due_date = i.due_date;
                item.due_is_recurring = i.due_is_recurring;
                item.due_string = i.due_string;
                item.due_lang = i.due_lang;

                duedate_preview_label.label = "<small>%s</small>".printf (
                    Planner.utils.get_relative_date_from_date (
                        new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ())
                    )
                );

                duedate_preview_revealer.reveal_child = true;
                check_preview_box ();
                check_duedate_style ();
                due_button.update_date_text (i);
            }
        });

        Planner.database.remove_due_item.connect ((i) => {
            if (item.id == i.id) {
                item.due_date = "";
                item.due_is_recurring = 0;
                item.due_string = "";
                item.due_lang = "";

                duedate_preview_label.label = "";

                duedate_preview_revealer.reveal_child = false;
                check_preview_box ();
                check_duedate_style ();
                due_button.update_date_text (i);
            }
        });

        Planner.database.item_updated.connect ((i) => {
            Idle.add (() => {
                if (item.id == i.id) {
                    save_off = true;

                    item.content = i.content;
                    item.note = i.note;
                    item.priority = i.priority;

                    content_entry.text = item.content;
                    content_label.label = Planner.utils.get_markup_format (item.content);
                    note_textview.buffer.text = item.note;

                    check_priority_style ();
                    priority_button.update_icon (item);

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

                if (view != "project") {
                    project = Planner.database.get_project_by_id (item.project_id);
                    project_preview_label.label = "<small>%s</small>".printf (project.name);
                    project_preview_image.gicon = new ThemedIcon ("color-%i".printf (project.color));
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

        //  Planner.database.item_completed.connect ((i) => {
        //      Idle.add (() => {
        //          if (item.id == i.id) {
        //              hide_destroy ();
        //          }

        //          return false;
        //      });
        //  });

        Planner.database.delete_undo_item.connect ((i) => {
            Idle.add (() => {
                if (item.id == i.id) {
                    destroy ();
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
                project_preview_label.label = "<small>%s</small>".printf (project.name);
                project_preview_image.gicon = new ThemedIcon ("color-%i".printf (project.color));
            }
        });

        Planner.database.project_deleted.connect ((id) => {
            if (item.project_id == id) {
                hide_destroy ();
            }
        });

        Planner.database.section_deleted.connect ((s) => {
            if (item.section_id == s.id) {
                hide_destroy ();
            }
        });

        check_listbox.row_activated.connect ((row) => {
            var item = ((Widgets.CheckRow) row);
            item.edit ();
        });

        Planner.utils.highlight_item.connect ((item_id) => {
            if (item.id == item_id) {
                get_style_context ().add_class ("item-highlight");

                Timeout.add (700, () => {
                    get_style_context ().remove_class ("item-highlight");

                    return false;
                });
            }
        });
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;

        Timeout.add (500, () => {
            destroy ();
            return false;
        });
    }

    private void checked_toggled () {
        if (checked_button.active) {
            checked_button.active = false;

            if (item.due_is_recurring == 1) {
                GLib.DateTime next_due = Planner.utils.get_next_recurring_due_date (item, +1);

                Planner.database.update_item_recurring_due_date (item, +1);
                Planner.notifications.send_undo_notification (
                    _("Completed. Next occurrence: %s".printf (Planner.utils.get_default_date_format_from_date (next_due))),
                    Planner.utils.build_undo_object ("item_reschedule", "item", item.id, "", "")
                );
            } else {
                item.checked = 1;
                item.date_completed = new GLib.DateTime.now_local ().to_string ();

                Planner.database.update_item_completed (item, true);
                if (item.is_todoist == 1) {
                    Planner.todoist.item_complete (item);
                }

                Planner.notifications.send_undo_notification (
                    _("1 task completed"),
                    Planner.utils.build_undo_object ("item_complete", "item", item.id, "", "")
                );
                main_revealer.reveal_child = false;
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
        bottom_revealer.reveal_child = true;
        main_grid.get_style_context ().add_class ("item-row-selected");
        main_grid.get_style_context ().add_class ("popover");

        entry_revealer.reveal_child = true;
        label_revealer.reveal_child = false;
        preview_revealer.reveal_child = false;
        hidden_revealer.reveal_child = true;

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
        content_label.label = Planner.utils.get_markup_format (content_entry.text);
        label_revealer.reveal_child = true;
        hidden_revealer.reveal_child = false;

        check_preview_box ();
        update_checklist_progress ();

        timeout_id = Timeout.add (250, () => {
            timeout_id = 0;

            activatable = true;
            selectable = true;
            return false;
        });
    }

    private void check_preview_box () {
        if (null != bottom_revealer && bottom_revealer.reveal_child == false) {
            preview_revealer.reveal_child = duedate_preview_revealer.reveal_child ||
            note_preview_revealer.reveal_child ||
            checklist_preview_revealer.reveal_child ||
            reminder_preview_revealer.reveal_child ||
            labels_preview_box_revealer.reveal_child ||
            project_preview_revealer.reveal_child;
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
        Planner.event_bus.magic_button_activated (
            item.project_id,
            item.section_id,
            item.is_todoist,
            this.get_index () + 1,
            view,
            item.due_date
        );
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = ((Widgets.ItemRow) widget).top_box;

        Gtk.Allocation alloc;
        row.get_allocation (out alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr = new Cairo.Context (surface);
        cr.set_source_rgba (0, 0, 0, 0);
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
        row.draw (cr);
        row.get_style_context ().remove_class ("drag-begin");

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
            content_label.tooltip_text = content_entry.text;
            item.content = content_entry.text;
            item.note = note_textview.buffer.text;

            if (online) {
                item.save ();
            } else {
                item.save_local ();
            }
        }
    }

    private void update_checklist_progress () {
        checklist_preview_label.label = "<small>%i/%i</small>".printf (
            Planner.database.get_count_checked_items_by_parent (item.id),
            Planner.database.get_all_count_items_by_parent (item.id)
        );
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
            labels_edit_revealer.reveal_child = true;
            labels_hashmap.set (label.id.to_string (), true);

            check_preview_box ();
        }
    }

    private void check_duedate_style () {
        duedate_preview_label.get_style_context ().remove_class ("today-label-button");
        duedate_preview_label.get_style_context ().remove_class ("overdue");
        duedate_preview_label.get_style_context ().remove_class ("upcoming-label-button");

        duedate_repeat_image.get_style_context ().remove_class ("today-label-button");
        duedate_repeat_image.get_style_context ().remove_class ("overdue");
        duedate_repeat_image.get_style_context ().remove_class ("upcoming-label-button");

        if (item.due_date != "") {
            var date = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
            if (Planner.utils.is_today (date)) {
                duedate_preview_grid.margin_start = 0;

                duedate_preview_label.get_style_context ().add_class ("today-label-button");
                duedate_repeat_image.get_style_context ().add_class ("today-label-button");
            } else if (Planner.utils.is_overdue (date)) {
                duedate_preview_grid.margin_start = 3;

                duedate_preview_label.get_style_context ().add_class ("overdue");
                duedate_repeat_image.get_style_context ().add_class ("overdue");
            } else {
                duedate_preview_grid.margin_start = 3;
                duedate_preview_label.get_style_context ().add_class ("upcoming-label-button");
                duedate_repeat_image.get_style_context ().add_class ("upcoming-label-button");
            }

            if (item.due_is_recurring == 1) {
                duedate_repeat_revealer.reveal_child = true;
                duedate_repeat_image.tooltip_text = item.due_string;
            } else {
                duedate_repeat_revealer.reveal_child = false;
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

    private void check_icon_style () {
        if (Planner.settings.get_enum ("appearance") == 0) {
            checklist_icon.gicon = new ThemedIcon ("add-circle-outline-light");
            menu_image.gicon = new ThemedIcon ("ellipsis-vertical-outline-light");
            reminder_preview_image.gicon = new ThemedIcon ("notifications-outline-light");
            checklist_preview_image.gicon = new ThemedIcon ("checkmark-circle-outline-light");
        } else {
            checklist_icon.gicon = new ThemedIcon ("add-circle-outline-dark");
            menu_image.gicon = new ThemedIcon ("ellipsis-vertical-outline-dark");
            reminder_preview_image.gicon = new ThemedIcon ("notifications-outline-dark");
            checklist_preview_image.gicon = new ThemedIcon ("checkmark-circle-outline-dark");
        }
    }

    private void activate_menu (bool visible=true) {
        if (menu == null) {
            build_context_menu (item);
        }

        if (item.due_date == "") {
            undated_menu.visible = false;
            undated_menu.no_show_all = true;
        } else {
            undated_menu.visible = visible;
            undated_menu.no_show_all = !visible;
        }

        edit_menu.visible = visible;
        edit_menu.no_show_all = !visible;

        today_menu.visible = visible;
        today_menu.no_show_all = !visible;

        tomorrow_menu.visible = visible;
        tomorrow_menu.no_show_all = !visible;

        date_separator.visible = visible;
        date_separator.no_show_all = !visible;

        foreach (var child in projects_menu.get_children ()) {
            child.destroy ();
        }

        foreach (var child in sections_menu.get_children ()) {
            child.destroy ();
        }

        Widgets.ImageMenuItem item_menu;
        int is_todoist = Planner.database.get_project_by_id (Planner.settings.get_int64 ("inbox-project")).is_todoist;
        if (item.is_todoist == is_todoist) {
            item_menu = new Widgets.ImageMenuItem (_("Inbox"), "planner-inbox");
            item_menu.activate.connect (() => {
                int64 inbox_id = Planner.settings.get_int64 ("inbox-project");

                Planner.database.move_item (item, inbox_id);
                if (item.is_todoist == 1) {
                    Planner.todoist.move_item (item, inbox_id);
                }

                string move_template = _("Task moved to <b>%s</b>");
                Planner.notifications.send_notification (
                    move_template.printf (
                        Planner.database.get_project_by_id (inbox_id).name
                    )
                );
            });

            projects_menu.add (item_menu);
        }

        foreach (var project in Planner.database.get_all_projects ()) {
            if (item.project_id != project.id && project.inbox_project == 0 && project.is_todoist == item.is_todoist) {
                item_menu = new Widgets.ImageMenuItem (project.name, "color-%i".printf (project.color));
                item_menu.activate.connect (() => {
                    Planner.database.move_item (item, project.id);
                    if (item.is_todoist == 1) {
                        Planner.todoist.move_item (item, project.id);
                    }

                    string move_template = _("Task moved to <b>%s</b>");
                    Planner.notifications.send_notification (
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

        projects_menu.show_all ();
        sections_menu.show_all ();

        menu.popup_at_pointer (null);
    }

    private void build_context_menu (Objects.Item item) {
        menu = new Gtk.Menu ();
        menu.width_request = 235;

        var complete_menu = new Widgets.ImageMenuItem (_("Complete"), "emblem-default-symbolic");
        edit_menu = new Widgets.ImageMenuItem (_("Edit"), "edit-symbolic");

        today_menu = new Widgets.ImageMenuItem (_("Today"), "help-about-symbolic");
        today_menu.item_image.get_style_context ().add_class ("today-icon");

        tomorrow_menu = new Widgets.ImageMenuItem (_("Tomorrow"), "x-office-calendar-symbolic");
        tomorrow_menu.item_image.get_style_context ().add_class ("upcoming-icon");

        undated_menu = new Widgets.ImageMenuItem (_("Undated"), "window-close-symbolic");
        undated_menu.item_image.get_style_context ().add_class ("due-clear");

        date_separator = new Gtk.SeparatorMenuItem ();

        var move_project_menu = new Widgets.ImageMenuItem (_("Move to Project"), "move-project-symbolic");
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
        menu.add (date_separator);
        menu.add (move_project_menu);
        menu.add (move_section_menu);
        menu.add (share_menu);
        menu.add (duplicate_menu);
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
            due_button.set_due (new GLib.DateTime.now_local ().to_string ());
        });

        tomorrow_menu.activate.connect (() => {
            due_button.set_due (new GLib.DateTime.now_local ().add_days (1).to_string ());
        });

        undated_menu.activate.connect (() => {
            due_button.set_due ("");
        });

        share_text_menu.activate.connect (() => {
            item.share_text ();
        });

        share_markdown_menu.activate.connect (() => {
            item.share_markdown ();
        });

        duplicate_menu.activate.connect (() => {
            item.get_duplicate ();
        });

        delete_menu.activate.connect (() => {
            Planner.notifications.send_undo_notification (
                _("Task deleted"),
                Planner.utils.build_undo_object ("item_delete", "item", item.id, "", "")
            );
            main_revealer.reveal_child = false;
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

    private void check_priority_style () {
        checked_button.get_style_context ().remove_class ("priority-4");
        checked_button.get_style_context ().remove_class ("priority-3");
        checked_button.get_style_context ().remove_class ("priority-2");
        checked_button.get_style_context ().remove_class ("priority-1");

        if (item.priority == 0 || item.priority == 1) {
            checked_button.get_style_context ().add_class ("priority-1");
        } else if (item.priority == 2) {
            checked_button.get_style_context ().add_class ("priority-2");
        } else if (item.priority == 3) {
            checked_button.get_style_context ().add_class ("priority-3");
        } else if (item.priority == 4) {
            checked_button.get_style_context ().add_class ("priority-4");
        } else {
            checked_button.get_style_context ().add_class ("priority-1");
        }
    }

    private void update_note_label (string text) {
        if (text.strip () == "") {
            note_label.label = _("Note");
            note_label.opacity = 0.7;

            note_preview_revealer.reveal_child = false;
        } else {
            note_label.label = Planner.utils.get_markup_format (text);
            note_label.opacity = 1.0;

            note_preview_revealer.reveal_child = true;
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
