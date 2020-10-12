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
    private Gtk.Menu menu = null;
    private Gtk.Image menu_image;
    private Gtk.ToggleButton reschedule_button;
    private Gtk.Image due_image;
    private Gtk.Label due_label;
    private Gtk.Label time_label;
    private Gtk.Revealer time_revealer;
    private Gtk.Popover reschedule_popover = null;

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

        menu_image = new Gtk.Image ();
        menu_image.gicon = new ThemedIcon ("view-more-symbolic");
        menu_image.pixel_size = 16;

        var menu_button = new Gtk.Button ();
        menu_button.image = menu_image;
        menu_button.valign = Gtk.Align.CENTER;
        menu_button.can_focus = false;
        menu_button.tooltip_text = _("Task Menu");
        menu_button.get_style_context ().add_class ("item-action-button");
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        reschedule_button = new Gtk.ToggleButton ();
        reschedule_button.get_style_context ().add_class ("flat");
        reschedule_button.halign = Gtk.Align.START;
        reschedule_button.add (get_schedule_grid ());

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        action_box.margin_top = 3;
        action_box.margin_start = 20;
        action_box.margin_bottom = 6;
        action_box.margin_end = 3;
        action_box.pack_start (reschedule_button, false, true, 0);
        // action_box.pack_start (labels_edit_box, false, true, 0);
        action_box.pack_end (menu_button, false, false, 0);
        // action_box.pack_end (reminder_button, false, true, 0);
        // action_box.pack_end (priority_button, false, false, 0);
        // action_box.pack_end (label_button, false, true, 0);
        // action_box.pack_end (checklist_button, false, true, 0);

        var bottom_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        bottom_box.pack_start (note_stack, false, true, 0);
        bottom_box.pack_end (action_box, false, true, 0);

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
            Planner.task_store.complete_task (source, task);
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

        reschedule_button.toggled.connect (() => {
            if (reschedule_button.active) {
                if (reschedule_popover == null) {
                    create_reschedule_popover ();
                }

                //  undated_button.visible = false;
                //  undated_button.no_show_all = true;
                //  if (due_date != "") {
                //      undated_button.visible = true;
                //      undated_button.no_show_all = false;
                //  }
                
                reschedule_popover.show_all ();
                reschedule_popover.popup ();
            }
        });

        Planner.event_bus.show_undo_task.connect ((uid, type) => {
            if (task.get_icalcomponent ().get_uid () == uid) {
                main_revealer.reveal_child = true;
            }
        });
    }

    private void activate_menu (bool visible=true) {
        if (menu == null) {
            build_context_menu ();
        }

        handle_grid.get_style_context ().add_class ("highlight");
        menu.popup_at_pointer (null);
    }

    private void build_context_menu () {
        menu = new Gtk.Menu ();
        menu.width_request = 235;

        menu.hide.connect (() => {
            handle_grid.get_style_context ().remove_class ("highlight");
        });

        var complete_menu = new Widgets.ImageMenuItem (_("Complete"), "emblem-default-symbolic");
        var edit_menu = new Widgets.ImageMenuItem (_("Edit"), "edit-symbolic");

        var today_menu = new Widgets.ImageMenuItem (_("Today"), "help-about-symbolic");
        today_menu.item_image.get_style_context ().add_class ("today-icon");
        today_menu.item_image.pixel_size = 14;

        var tomorrow_menu = new Widgets.ImageMenuItem (_("Tomorrow"), "x-office-calendar-symbolic");
        tomorrow_menu.item_image.get_style_context ().add_class ("upcoming-icon");
        tomorrow_menu.item_image.pixel_size = 14;

        var undated_menu = new Widgets.ImageMenuItem (_("Undated"), "window-close-symbolic");
        undated_menu.item_image.get_style_context ().add_class ("due-clear");
        undated_menu.item_image.pixel_size = 14;

        var date_separator = new Gtk.SeparatorMenuItem ();

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
        menu.add (share_menu);
        menu.add (duplicate_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (delete_menu);

        menu.show_all ();

        complete_menu.activate.connect (() => {
            // checked_button.active = !checked_button.active;
        });

        edit_menu.activate.connect (() => {
            // show_item ();
        });

        today_menu.activate.connect (() => {
            //  due_button.set_due (
            //      Planner.utils.get_format_date (
            //          new GLib.DateTime.now_local ()
            //      ).to_string ()
            //  );
        });

        tomorrow_menu.activate.connect (() => {
            //  due_button.set_due (
            //      Planner.utils.get_format_date (
            //          new GLib.DateTime.now_local ().add_days (1)
            //      ).to_string ()
            //  );
        });

        undated_menu.activate.connect (() => {
            // due_button.set_due ("");
        });

        share_text_menu.activate.connect (() => {
            // item.share_text ();
        });

        share_markdown_menu.activate.connect (() => {
            // item.share_markdown ();
        });

        duplicate_menu.activate.connect (() => {
            // item.get_duplicate ();
        });

        delete_menu.activate.connect (() => {
            Planner.task_store.remove_task (source, task, ECal.ObjModType.ALL);
            hide_destroy ();
            //  Planner.notifications.send_undo_notification (
            //      _("Task deleted"),
            //      Planner.utils.build_undo_object ("item_delete", "task", task.get_icalcomponent ().get_uid (), "", "")
            //  );
            //  main_revealer.reveal_child = false;
        });
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            destroy ();
            return GLib.Source.REMOVE;
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

        // Clear the old description
        int count = ical_task.count_properties (ICal.PropertyKind.DESCRIPTION_PROPERTY);
        for (int i = 0; i < count; i++) {
            unowned ICal.Property remove_prop;
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
        Planner.task_store.update_task (source, task, ECal.ObjModType.THIS_AND_FUTURE);
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

            checked_button.get_style_context ().remove_class ("checklist-completed");
            completed = ical_task.get_status () == ICal.PropertyStatus.COMPLETED;
            checked_button.active = completed;
            if (completed) {
                checked_button.get_style_context ().add_class ("checklist-completed");
            }
            
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

    private Gtk.Widget get_schedule_grid () {
        due_image = new Gtk.Image ();
        due_image.gicon = new ThemedIcon ("office-calendar-symbolic");
        due_image.valign = Gtk.Align.CENTER;
        due_image.pixel_size = 16;

        due_label = new Gtk.Label (_("Schedule"));
        due_label.use_markup = true;

        time_label = new Gtk.Label (null);
        time_label.use_markup = true;

        time_revealer = new Gtk.Revealer ();
        time_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        time_revealer.add (time_label);
        time_revealer.reveal_child = false;

        var main_grid = new Gtk.Grid ();
        main_grid.halign = Gtk.Align.CENTER;
        main_grid.valign = Gtk.Align.CENTER;
        main_grid.add (due_image);
        main_grid.add (due_label);
        main_grid.add (time_revealer);

        return main_grid;
    }

    private void create_reschedule_popover () {
        reschedule_popover = new Gtk.Popover (reschedule_button);
        reschedule_popover.position = Gtk.PositionType.RIGHT;

        var popover_grid = new Gtk.Grid ();
        popover_grid.margin_top = 6;
        popover_grid.width_request = 235;
        popover_grid.margin_bottom = 12;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (get_calendar_widget ());
        popover_grid.show_all ();

        reschedule_popover.add (popover_grid);

        reschedule_popover.closed.connect (() => {
            reschedule_button.active = false;
        });
    }

    private Gtk.Widget get_calendar_widget () {
        var today_button = new Widgets.ModelButton (_("Today"), "help-about-symbolic", "");
        today_button.get_style_context ().add_class ("due-menuitem");
        today_button.item_image.pixel_size = 14;
        today_button.color = 0;
        today_button.due_label = true;

        var tomorrow_button = new Widgets.ModelButton (_("Tomorrow"), "x-office-calendar-symbolic", "");
        tomorrow_button.get_style_context ().add_class ("due-menuitem");
        tomorrow_button.item_image.pixel_size = 14;
        tomorrow_button.color = 1;
        tomorrow_button.due_label = true;

        var undated_button = new Widgets.ModelButton (_("Undated"), "window-close-symbolic", "");
        undated_button.get_style_context ().add_class ("due-menuitem");
        undated_button.item_image.pixel_size = 14;
        undated_button.color = 2;
        undated_button.due_label = true;

        var calendar = new Widgets.Calendar.Calendar (true);
        calendar.hexpand = true;

        var time_header = new Gtk.Label (_("Time"));
        time_header.get_style_context ().add_class ("font-bold");

        var time_switch = new Gtk.Switch ();
        time_switch.get_style_context ().add_class ("active-switch");

        var time_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        time_box.hexpand = true;
        time_box.margin_start = 16;
        time_box.margin_end = 16;
        time_box.pack_start (time_header, false, false, 0);
        time_box.pack_end (time_switch, false, false, 0);
        
        var time_picker = new Granite.Widgets.TimePicker ();
        time_picker.margin_start = 16;
        time_picker.margin_end = 16;
        time_picker.margin_top = 6;

        var time_picker_revealer = new Gtk.Revealer ();
        time_picker_revealer.reveal_child = false;
        time_picker_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        time_picker_revealer.add (time_picker);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (today_button);
        grid.add (tomorrow_button);
        grid.add (undated_button);
        grid.add (calendar);
        grid.add (time_box);
        grid.add (time_picker_revealer);
        grid.show_all ();

        today_button.clicked.connect (() => {
            unowned ICal.Component ical_task = task.get_icalcomponent ();

            if (time_switch.active) {
                ical_task.set_due (Planner.utils.date_time_to_ical (new GLib.DateTime.now_local (), time_picker.time));
            } else {
                ical_task.set_due (Planner.utils.date_time_to_ical (new GLib.DateTime.now_local (), null));
            }

            Planner.task_store.update_task (source, task, ECal.ObjModType.THIS_AND_FUTURE);
        });

        tomorrow_button.clicked.connect (() => {
            unowned ICal.Component ical_task = task.get_icalcomponent ();

            if (time_switch.active) {
                ical_task.set_due (Planner.utils.date_time_to_ical (new GLib.DateTime.now_local ().add_days (1), time_picker.time));
            } else {
                ical_task.set_due (Planner.utils.date_time_to_ical (new GLib.DateTime.now_local ().add_days (1), null));
            }

            Planner.task_store.update_task (source, task, ECal.ObjModType.THIS_AND_FUTURE);
        });

        undated_button.clicked.connect (() => {
            unowned ICal.Component ical_task = task.get_icalcomponent ();
            ical_task.set_due (new ICal.Time.null_time ());
            Planner.task_store.update_task (source, task, ECal.ObjModType.THIS_AND_FUTURE);
        });

        calendar.selection_changed.connect ((date) => {
            unowned ICal.Component ical_task = task.get_icalcomponent ();

            if (time_switch.active) {
                ical_task.set_due (Planner.utils.date_time_to_ical (date, time_picker.time));
            } else {
                ical_task.set_due (Planner.utils.date_time_to_ical (date, null));
            }
            
            Planner.task_store.update_task (source, task, ECal.ObjModType.THIS_AND_FUTURE);
        });
        
        time_switch.notify["active"].connect (() => {
            time_picker_revealer.reveal_child = time_switch.active;

            //  if (time_switch.active && due_date == "") {
            //      due_date = new GLib.DateTime.now_local ().to_string ();
            //  }

            // update_due_date ();
        });

        time_picker.changed.connect (() => {
            // update_due_date ();
        });

        return grid;
    }
}
