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

public class Widgets.TaskRow : Gtk.ListBoxRow {
    public E.Source source { get; construct; }
    public ECal.Component task { get; construct set; }
    public bool completed { get; private set; }
    
    private Gtk.CheckButton checked_button;
    private Gtk.Label content_label;
    private Gtk.Box top_box;
    private Gtk.Button hidden_button;
    private Gtk.Revealer hidden_revealer;
    private Gtk.Revealer label_revealer;
    private Widgets.Entry content_entry;
    private Gtk.Revealer entry_revealer;
    private Widgets.TextView note_textview;
    private Gtk.Label note_label;
    private Gtk.Stack note_stack;
    private Gtk.Revealer bottom_revealer;
    private Gtk.Revealer main_revealer;
    private Gtk.Grid main_grid;
    private Gtk.Grid handle_grid;

    private uint timeout_id = 0;
    private bool receive_updates = true;

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

    public TaskRow (ECal.Component task, E.Source source) {
        Object (
            task: task,
            source: source
        );
    }

    public signal void task_changed (ECal.Component task);
    public signal void task_completed (ECal.Component task);

    construct {
        can_focus = false;
        get_style_context ().add_class ("item-row");

        hidden_button = new Gtk.Button.from_icon_name ("view-restore-symbolic", Gtk.IconSize.MENU);
        hidden_button.can_focus = false;
        hidden_button.margin_top = 1;
        hidden_button.margin_end = 3;
        hidden_button.tooltip_text = _("Hide Details");
        hidden_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hidden_button.get_style_context ().add_class ("hidden-button");

        hidden_revealer = new Gtk.Revealer ();
        hidden_revealer.valign = Gtk.Align.START;
        hidden_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        hidden_revealer.add (hidden_button);

        checked_button = new Gtk.CheckButton ();
        checked_button.can_focus = false;
        checked_button.margin_top = 6;
        checked_button.margin_start = 6;
        checked_button.valign = Gtk.Align.START;
        checked_button.halign = Gtk.Align.BASELINE;
        checked_button.get_style_context ().add_class ("priority-1");

        content_label = new Gtk.Label (null);
        content_label.hexpand = true;
        content_label.valign = Gtk.Align.START;
        content_label.xalign = 0;
        content_label.margin_top = 5;
        content_label.wrap = true;
        content_label.use_markup = true;

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

        // Note TextView
        note_textview = new Widgets.TextView ();
        note_textview.hexpand = true;
        note_textview.valign = Gtk.Align.START;
        note_textview.wrap_mode = Gtk.WrapMode.CHAR;
        note_textview.height_request = 42;
        note_textview.get_style_context ().add_class ("textview");

        // Note Label
        note_label = new Gtk.Label (null);
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

        var bottom_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        bottom_box.pack_start (note_stack, false, true, 0);

        bottom_revealer = new Gtk.Revealer ();
        bottom_revealer.valign = Gtk.Align.START;
        bottom_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        bottom_revealer.add (bottom_box);

        main_grid = new Gtk.Grid ();
        main_grid.hexpand = true;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.get_style_context ().add_class ("transition");
        main_grid.margin_bottom = 3;
        main_grid.add (top_box);
        main_grid.add (bottom_revealer);

        handle_grid = new Gtk.Grid ();
        handle_grid.hexpand = true;
        handle_grid.margin_start = 6;
        handle_grid.margin_top = 3;
        handle_grid.orientation = Gtk.Orientation.VERTICAL;

        handle_grid.add (main_grid);
        // handle_grid.add (motion_revealer);

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

        notify["task"].connect (() => {
            update_request ();
        });
        update_request ();

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
            save_timeout ();
        });

        hidden_button.clicked.connect (() => {
            if (reveal_child == false) {
                show_item ();
            } else {
                hide_item ();
            }
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
            save_timeout ();
            return false;
        });

        checked_button.toggled.connect (() => {
            if (task == null) {
                return;
            }
            task_completed (task);
        });
    }

    private void save_timeout () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
        }

        timeout_id = Timeout.add (500, () => {
            timeout_id = 0;
            receive_updates = false;
            save_task (task);
            return false;
        });
    }

    private void save_task (ECal.Component task) {
        unowned ICal.Component ical_task = task.get_icalcomponent ();

        //  if (due_switch.active) {
        //      ical_task.set_due (Util.date_time_to_ical (due_datepicker.date, due_timepicker.time));
        //      ical_task.set_due (Util.date_time_to_ical (due_datepicker.date, due_timepicker.time));
        //  } else {
        //      ical_task.set_due (new ICal.Time.null_time ());
        //  }

        // Clear the old description
        int count = ical_task.count_properties (ICal.PropertyKind.DESCRIPTION_PROPERTY);
        for (int i = 0; i < count; i++) {
            ICal.Property remove_prop;
            remove_prop = ical_task.get_first_property (ICal.PropertyKind.DESCRIPTION_PROPERTY);
            ical_task.remove_property (remove_prop);
        }

        // Add the new description - if we have any
        var description = note_textview.buffer.text;
        if (description != null && description.strip ().length > 0) {
            var property = new ICal.Property (ICal.PropertyKind.DESCRIPTION_PROPERTY);
            property.set_description (description.strip ());
            ical_task.add_property (property);
        }

        task.get_icalcomponent ().set_summary (content_entry.text);
        task_changed (task);
    }

    public void hide_item () {
        // preview_revealer.transition_duration = 150;
        // Planner.utils.remove_item_show_queue (this);

        bottom_revealer.reveal_child = false;
        main_grid.get_style_context ().remove_class ("item-row-selected");
        main_grid.get_style_context ().remove_class ("popover");

        entry_revealer.reveal_child = false;
        content_label.label = Planner.utils.get_markup_format (content_entry.text);
        label_revealer.reveal_child = true;
        hidden_revealer.reveal_child = false;

        // check_preview_box ();
        // update_checklist_progress ();

        timeout_id = Timeout.add (250, () => {
            timeout_id = 0;

            activatable = true;
            selectable = true;
            return false;
        });
    }

    public void show_item () {
        // preview_revealer.transition_duration = 0;

        bottom_revealer.reveal_child = true;
        main_grid.get_style_context ().add_class ("item-row-selected");
        main_grid.get_style_context ().add_class ("popover");

        entry_revealer.reveal_child = true;
        label_revealer.reveal_child = false;
        // preview_revealer.reveal_child = false;
        hidden_revealer.reveal_child = true;

        activatable = false;
        selectable = false;

        content_entry_focus ();
    }

    public void content_entry_focus () {
        content_entry.grab_focus_without_selecting ();
        if (content_entry.cursor_position < content_entry.text_length) {
           content_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) content_entry.text_length, false);
        }
    }

    private void update_note_label (string text) {
        if (text.strip () == "") {
            note_label.label = _("Note");
            note_label.opacity = 0.7;

            // note_preview_revealer.reveal_child = false;
        } else {
            note_label.label = Planner.utils.get_markup_format (text);
            note_label.opacity = 1.0;

            // note_preview_revealer.reveal_child = true;
        }
    }

    public void update_request () {
        if (receive_updates) {
            unowned ICal.Component ical_task = task.get_icalcomponent ();

            completed = ical_task.get_status () == ICal.PropertyStatus.COMPLETED;
            checked_button.active = completed;

            content_label.label = Planner.utils.get_markup_format (
                ical_task.get_summary () == null ? "" : ical_task.get_summary ()
            );
            content_entry.text = ical_task.get_summary () == null ? "" : ical_task.get_summary ();

            if (ical_task.get_description () != null) {
                note_textview.buffer.text = ical_task.get_description ();
                update_note_label (ical_task.get_description ());
            } else {
                note_textview.buffer.text = "";
                update_note_label ("");
            }
        } else {
            Timeout.add (1000, () => {
                receive_updates = true;
                return false;
            });
        }
    }
}
