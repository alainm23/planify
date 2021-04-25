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
    public bool created {get; construct; }
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
    private Widgets.ScheduleButton reschedule_button;

    private Gtk.Label duedate_preview_label;
    private Gtk.Revealer duedate_preview_revealer;
    private Gtk.Revealer preview_revealer;
    private Gtk.Box preview_box;

    private Gtk.Button submit_button;
    private Gtk.Stack submit_stack;
    private Gtk.Button cancel_button;
    private Services.Tasks.Store task_store;

    private uint focus_timeout = 0;
    private uint timeout_id = 0;
    private bool receive_updates = true;
    private bool entry_menu_opened = false;
    
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

    public bool loading {
        set {
            if (value) {
                submit_stack.visible_child_name = "spinner";
                sensitive = false;
            } else {
                submit_stack.visible_child_name = "label";
                sensitive = true;
            }
        }
    }

    public TaskRow.for_source (E.Source source) {
        var task = new ECal.Component ();
        task.set_new_vtype (ECal.ComponentVType.TODO);

        Object (
            task: task,
            source: source,
            created: false
        );
    }

    public TaskRow.for_component (ECal.Component task, E.Source source) {
        Object (
            task: task,
            source: source,
            created: true
        );
    }

    construct {
        task_store = Services.Tasks.Store.get_default ();
        can_focus = false;
        get_style_context ().add_class ("item-row");

        hidden_button = new Gtk.Button.from_icon_name ("view-restore-symbolic", Gtk.IconSize.MENU);
        hidden_button.can_focus = false;
        hidden_button.margin_top = 1;
        hidden_button.margin_end = 3;
        hidden_button.tooltip_text = _("Hide Details");
        hidden_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hidden_button.get_style_context ().add_class ("hidden-button");
        hidden_button.visible = created;
        hidden_button.no_show_all = !created;

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
        content_entry.sensitive = task.get_icalcomponent ().get_status () != ICal.PropertyStatus.COMPLETED;

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
        note_eventbox.sensitive = task.get_icalcomponent ().get_status () != ICal.PropertyStatus.COMPLETED;

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
        menu_button.visible = created;
        menu_button.no_show_all = !created;
        menu_button.tooltip_text = _("Task Menu");
        menu_button.get_style_context ().add_class ("item-action-button");
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        reschedule_button = new Widgets.ScheduleButton.new_item ();

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        action_box.margin_top = 3;
        action_box.margin_start = 20;
        action_box.margin_bottom = 6;
        action_box.margin_end = 3;
        action_box.sensitive = task.get_icalcomponent ().get_status () != ICal.PropertyStatus.COMPLETED;
        action_box.pack_start (reschedule_button, false, true, 0);
        action_box.pack_end (menu_button, false, false, 0);

        var bottom_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        bottom_box.pack_start (note_stack, false, true, 0);
        bottom_box.pack_end (action_box, false, true, 0);

        bottom_revealer = new Gtk.Revealer ();
        bottom_revealer.valign = Gtk.Align.START;
        bottom_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        bottom_revealer.add (bottom_box);

        duedate_preview_label = new Gtk.Label (null);
        duedate_preview_label.use_markup = true;
        duedate_preview_label.valign = Gtk.Align.CENTER;
        
        duedate_preview_revealer = new Gtk.Revealer ();
        duedate_preview_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        duedate_preview_revealer.add (duedate_preview_label);

        preview_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        preview_box.margin_start = 28;
        preview_box.margin_end = 9;
        preview_box.hexpand = true;
        preview_box.pack_start (duedate_preview_revealer, false, false, 0);

        preview_revealer = new Gtk.Revealer ();
        preview_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        preview_revealer.transition_duration = 150;
        preview_revealer.reveal_child = false;
        preview_revealer.add (preview_box);
        
        main_grid = new Gtk.Grid ();
        main_grid.hexpand = true;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.get_style_context ().add_class ("transition");
        main_grid.margin_bottom = 3;
        main_grid.add (top_box);
        main_grid.add (preview_revealer);
        main_grid.add (bottom_revealer);

        // Action Button
        submit_button = new Gtk.Button ();
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var submit_spinner = new Gtk.Spinner ();
        submit_spinner.start ();

        submit_stack = new Gtk.Stack ();
        submit_stack.expand = true;
        submit_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        submit_stack.add_named (new Gtk.Label (_("Add Task")), "label");
        submit_stack.add_named (submit_spinner, "spinner");

        submit_button.add (submit_stack);

        cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("cancel-button");

        var action_grid = new Gtk.Grid ();
        action_grid.halign = Gtk.Align.START;
        action_grid.column_spacing = 6;
        action_grid.margin_start = 3;
        action_grid.column_homogeneous = true;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);
        action_grid.visible = !created;
        action_grid.no_show_all = created;

        handle_grid = new Gtk.Grid ();
        handle_grid.hexpand = true;
        handle_grid.margin_start = 6;
        handle_grid.margin_top = 3;
        handle_grid.orientation = Gtk.Orientation.VERTICAL;

        handle_grid.add (main_grid);
        handle_grid.add (action_grid);

        var handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.expand = true;
        handle.above_child = false;
        handle.add (handle_grid);

        main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = false;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (handle);

        add (main_revealer);

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;

            if (!created) {
                show_item ();
            }

            return GLib.Source.REMOVE;
        });

        notify["task"].connect (() => {
            update_request ();
        });

        update_request ();

        cancel_button.clicked.connect (() => {
            hide_destroy ();
        });

        content_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                if (created) {
                    hide_item ();
                } else {
                    hide_destroy ();
                }
            }

            return false;
        });

        content_entry.focus_out_event.connect (() => {
            focus_timeout = Timeout.add (1000, () => {
                focus_timeout = 0;
                if (!created && entry_menu_opened == false && content_entry.text.strip () == "") {
                    hide_destroy ();
                }
                
                return false;
            });

            return false;
        }); 

        content_entry.focus_in_event.connect (() => {
            if (focus_timeout != 0) {
                GLib.Source.remove (focus_timeout);
            }

            return false;
        });

        content_entry.populate_popup.connect ((menu) => {
            entry_menu_opened = true;
            menu.hide.connect (() => {
                entry_menu_opened = false;
            });
        });

        content_entry.activate.connect (() => {
            if (created) {
                hide_item ();
            } else {
                add_task ();
            }
        });

        content_entry.changed.connect (() => {
            if (!created && content_entry.text.strip () != "") {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }
            
            if (created) {
                save_timeout ();
            }
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

        note_textview.focus_in_event.connect (() => {
            if (focus_timeout != 0) {
                GLib.Source.remove (focus_timeout);
            }

            return false;
        });

        checked_button.toggled.connect (() => {
            if (task == null || created == false) {
                return;
            }
            
            main_revealer.reveal_child = false;
            task_store.complete_task (source, task);
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

        submit_button.clicked.connect (add_task);

        reschedule_button.popover_opened.connect ((active) => {
            entry_menu_opened = active;

            if (active == false) {
                content_entry.grab_focus_without_selecting ();
                if (content_entry.cursor_position < content_entry.text_length) {
                content_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) content_entry.text_length, false);
                }
            }

            if (created) {
                save_task (task);
            }
        });

        //  Planner.event_bus.show_undo_task.connect ((uid, type) => {
        //      if (task.get_icalcomponent ().get_uid () == uid) {
        //          main_revealer.reveal_child = true;
        //      }
        //  });
    }

    private void add_task () {
        if (content_entry.text.strip () != "") {
            loading = true;
            unowned ICal.Component ical_task = task.get_icalcomponent ();

            if (reschedule_button.has_datetime ()) {
                var due_icaltime = CalDAVUtil.duedate_to_ical (reschedule_button.duedate);
                ical_task.set_due (due_icaltime);
                ical_task.set_dtstart (due_icaltime);
            } else {
                var null_icaltime = new ICal.Time.null_time ();
                ical_task.set_due (null_icaltime);
                ical_task.set_dtstart (null_icaltime);
            }

            var description = note_textview.buffer.text;
            if (description != null && description.strip ().length > 0) {
                var property = new ICal.Property (ICal.PropertyKind.DESCRIPTION_PROPERTY);
                property.set_description (description.strip ());
                ical_task.add_property (property);
            }

            task.get_icalcomponent ().set_summary (content_entry.text);
            task_store.add_task (source, task, this);
        }
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
            task_store.remove_task (source, task, ECal.ObjModType.ALL);
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
            ICal.Property remove_prop;
            remove_prop = ical_task.get_first_property (ICal.PropertyKind.DESCRIPTION_PROPERTY);
            ical_task.remove_property (remove_prop);
        }

        if (reschedule_button.has_datetime ()) {
            var due_icaltime = CalDAVUtil.duedate_to_ical (reschedule_button.duedate);
            ical_task.set_due (due_icaltime);
            ical_task.set_dtstart (due_icaltime);
        } else {
            var null_icaltime = new ICal.Time.null_time ();
            ical_task.set_due (null_icaltime);
            ical_task.set_dtstart (null_icaltime);
        }

        // Add the new description - if we have any
        var description = note_textview.buffer.text;
        if (description != null && description.strip ().length > 0) {
            var property = new ICal.Property (ICal.PropertyKind.DESCRIPTION_PROPERTY);
            property.set_description (description.strip ());
            ical_task.add_property (property);
        }

        task.get_icalcomponent ().set_summary (content_entry.text);
        task_store.update_task (source, task, ECal.ObjModType.THIS_AND_FUTURE);
    }

    public void hide_item () {
        preview_revealer.transition_duration = 150;

        bottom_revealer.reveal_child = false;
        main_grid.get_style_context ().remove_class ("item-row-selected");
        main_grid.get_style_context ().remove_class ("popover");

        entry_revealer.reveal_child = false;
        content_label.label = Planner.utils.get_markup_format (content_entry.text);
        label_revealer.reveal_child = true;
        hidden_revealer.reveal_child = false;

        check_preview_box ();

        timeout_id = Timeout.add (bottom_revealer.transition_duration, () => {
            timeout_id = 0;

            activatable = true;
            selectable = true;
            return false;
        });
    }

    public void show_item () {
        preview_revealer.transition_duration = 0;

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
        if (created) {
            if (receive_updates) {
                content_entry.get_style_context ().remove_class ("entry-no-border");
                content_entry.get_style_context ().remove_class ("content-entry");

                unowned ICal.Component ical_task = task.get_icalcomponent ();

                checked_button.get_style_context ().remove_class ("checklist-completed");
                completed = ical_task.get_status () == ICal.PropertyStatus.COMPLETED;
                checked_button.active = completed;

                if (completed) {
                    checked_button.get_style_context ().add_class ("checklist-completed");
                    content_entry.get_style_context ().add_class ("entry-no-border");
                } else {
                    content_entry.get_style_context ().add_class ("content-entry");
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

                if (!ical_task.get_due ().is_null_time ()) {
                    reschedule_button.set_datetime (CalDAVUtil.ical_to_date_time (ical_task.get_due ()));
                    
                    if (completed) {
                        duedate_preview_revealer.reveal_child = false;
                    } else {
                        duedate_preview_revealer.reveal_child = true;
                    }
                } else {
                    duedate_preview_revealer.reveal_child = false;
                }

                check_preview_box ();
                update_duedate_style ();
            } else {
                Timeout.add (2500, () => {
                    receive_updates = true;
                    return false;
                });
            }
        }
    }

    private void update_duedate_style () {
        unowned ICal.Component ical_task = task.get_icalcomponent ();
        duedate_preview_label.label = "";

        duedate_preview_label.get_style_context ().remove_class ("today-label-button");
        duedate_preview_label.get_style_context ().remove_class ("overdue");
        duedate_preview_label.get_style_context ().remove_class ("upcoming-label-button");

        if (!completed && !ical_task.get_due ().is_null_time ()) {
            var datetime = CalDAVUtil.ical_to_date_time (ical_task.get_due ());
            var datetime_label = Planner.utils.get_relative_date_from_date (datetime);

            if (Planner.utils.has_time (datetime)) {
                datetime_label += " " + datetime.format (Planner.utils.get_default_time_format ());
            }

            if (Planner.utils.is_today (datetime)) {      
                duedate_preview_label.get_style_context ().add_class ("today-label-button");
            } else if (Planner.utils.is_overdue (datetime)) {
                duedate_preview_label.get_style_context ().add_class ("overdue");
            } else {
                duedate_preview_label.get_style_context ().add_class ("upcoming-label-button");
            }
            
            duedate_preview_label.label = "<small>%s</small>".printf (datetime_label);
        }
    }

    private void check_preview_box () {
        if (null != bottom_revealer && bottom_revealer.reveal_child == false) {
            preview_revealer.reveal_child = duedate_preview_revealer.reveal_child;
        }
    }
}
