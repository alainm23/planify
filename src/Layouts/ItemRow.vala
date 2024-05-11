/*
* Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
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

public class Layouts.ItemRow : Layouts.ItemBase {
    public string project_id { get; set; default = ""; }
    public string section_id { get; set; default = ""; }
    public string parent_id { get; set; default = ""; }

    private Gtk.Grid motion_top_grid;
    private Gtk.Revealer motion_top_revealer;

    private Gtk.CheckButton checked_button;
    private Gtk.Revealer checked_button_revealer;
    private Widgets.TextView content_textview;
    private Gtk.Revealer hide_loading_revealer;
    private Gtk.Revealer project_label_revealer;

    private Gtk.CheckButton select_checkbutton;
    private Gtk.Revealer select_revealer;

    private Gtk.Label content_label;
    private Gtk.Revealer content_label_revealer;
    private Gtk.Revealer content_entry_revealer;

    private Gtk.Label due_label;
    private Gtk.Box due_box;
    private Gtk.Label repeat_label;
    private Gtk.Revealer repeat_revealer;
    private Gtk.Revealer due_box_revealer;
    private Gtk.Revealer description_image_revealer;
    private Gtk.Revealer pin_image_revealer;
    private Gtk.Revealer reminder_revelaer;
    private Gtk.Label reminder_count;
    
    private Gtk.Revealer detail_revealer;
    private Gtk.Revealer main_revealer;
    public Adw.Bin itemrow_box;
    private Gtk.Popover menu_handle_popover = null;
    
    private Widgets.LoadingButton hide_loading_button;
    private Widgets.HyperTextView description_textview;
    private Widgets.ItemLabels item_labels;
    private Widgets.ScheduleButton schedule_button;
    private Widgets.LabelsSummary labels_summary;
    private Widgets.PriorityButton priority_button;
    private Widgets.LabelPicker.LabelButton label_button;
    private Widgets.PinButton pin_button;
    private Widgets.ReminderPicker.ReminderButton reminder_button;
    private Gtk.Button add_button;
    private Gtk.MenuButton attachments_button;
    private Gtk.Box action_box;

    private Widgets.SubItems subitems;
    private Gtk.MenuButton menu_button;
    private Gtk.Button hide_subtask_button;
    private Gtk.Revealer hide_subtask_revealer;
    private Widgets.ContextMenu.MenuItem no_date_item;
    
    private Gtk.DropControllerMotion drop_motion_ctrl;
    private Gtk.DragSource drag_source;
    private Gtk.DropTarget drop_target;
    private Gtk.DropTarget drop_order_target;
    private Gtk.DropTarget drop_magic_button_target;
    private Gtk.DropTarget drop_order_magic_button_target;
    private Gee.HashMap<ulong, GLib.Object> dnd_handlerses = new Gee.HashMap<ulong, GLib.Object> ();

    bool _edit = false;
    public bool edit {
        set {
            _edit = value;
            
            if (value) {
                add_css_class ("row");
                itemrow_box.add_css_class ("card");
                itemrow_box.add_css_class ("card-selected");
                itemrow_box.add_css_class ("card-border");

                detail_revealer.reveal_child = true;
                content_label_revealer.reveal_child = false;
                content_entry_revealer.reveal_child = true;
                project_label_revealer.reveal_child = false;
                labels_summary.reveal_child = false;
                hide_subtask_revealer.reveal_child = false;
                hide_loading_button.remove_css_class ("no-padding");
                hide_loading_revealer.reveal_child = true;

                // Due labels
                due_box_revealer.reveal_child = false;
                description_image_revealer.reveal_child = false;
                pin_image_revealer.reveal_child = false;
                reminder_revelaer.reveal_child = false;

                if (complete_timeout != 0) {
                    itemrow_box.remove_css_class ("complete-animation");
                    content_label.remove_css_class ("dim-label");
                }

                _disable_drag_and_drop ();

                Timeout.add (250, () => {
                    content_textview.grab_focus ();
                    return GLib.Source.REMOVE;
                });        
            } else {
                remove_css_class ("row");
                itemrow_box.remove_css_class ("card-selected");
                itemrow_box.remove_css_class ("card");
                itemrow_box.remove_css_class ("card-border");

                detail_revealer.reveal_child = false;
                content_label_revealer.reveal_child = true;
                content_entry_revealer.reveal_child = false;
                project_label_revealer.reveal_child = show_project_label;
                hide_subtask_revealer.reveal_child = subitems.has_children;
                hide_loading_button.add_css_class ("no-padding");
                hide_loading_revealer.reveal_child = false;
                labels_summary.check_revealer ();

                update_request ();

                if (drag_enabled) {
                    build_drag_and_drop ();   
                }
            }
        }
        get {
            return _edit;
        }
    }

    public bool reveal {
        set {
            main_revealer.reveal_child = true;
        }

        get {
            return main_revealer.reveal_child;
        }
    }

    private bool _is_loading;
    public bool is_loading {
        set {
            _is_loading = value;

            if (_is_loading) {
                hide_loading_revealer.reveal_child = _is_loading;
                hide_loading_button.is_loading = _is_loading;
            } else {
                hide_loading_button.is_loading = _is_loading;
                hide_loading_revealer.reveal_child = edit;
            }
        }

        get {
            return _is_loading;
        }
    }

    private bool _show_project_label = false;
    public bool show_project_label {
        set {
            _show_project_label = value;
            project_label_revealer.reveal_child = _show_project_label;
        }

        get {
            return _show_project_label;
        }
    }

    public uint destroy_timeout { get; set; default = 0; }
    public uint complete_timeout { get; set; default = 0; }
    public bool on_drag = false;
    public bool drag_enabled { get; set; default = true; }

    public signal void item_added ();
    public signal void widget_destroyed ();

    public ItemRow (Objects.Item item) {
        Object (
            item: item,
            focusable: false,
            can_focus: true
        );
    }

    construct {
        css_classes = { "no-selectable", "no-padding" };

        project_id = item.project_id;
        section_id = item.section_id;
        parent_id = item.parent_id;

        motion_top_grid = new Gtk.Grid () {
            height_request = 27,
            css_classes = { "drop-area", "drop-target" },
            margin_bottom = 3,
            margin_start = 21
        };

        motion_top_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = motion_top_grid
        };

        checked_button = new Gtk.CheckButton () {
            valign = Gtk.Align.CENTER,
            css_classes = { "priority-color" },
            sensitive = !item.project.is_deck,
            tooltip_text = item.content
        };

        checked_button_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SWING_RIGHT,
            child = checked_button,
            valign = Gtk.Align.CENTER,
            reveal_child = true
        };

        content_label = new Gtk.Label (item.content) {
            hexpand = true,
            xalign = 0,
            wrap = false,
            ellipsize = Pango.EllipsizeMode.END
        };

        content_label_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_UP,
            transition_duration = 115,
            reveal_child = true,
            child = content_label
        };

        content_textview = new Widgets.TextView ();
        content_textview.wrap_mode = Gtk.WrapMode.WORD;
        content_textview.buffer.text = item.content;
        content_textview.editable = !item.completed && !item.project.is_deck;
        content_textview.remove_css_class ("view");
        content_textview.add_css_class ("font-bold");

        content_entry_revealer = new Gtk.Revealer () {
            valign = Gtk.Align.CENTER,
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            transition_duration = 115,
            reveal_child = false,
            child = content_textview
        };

        hide_loading_button = new Widgets.LoadingButton.with_icon ("go-up-symbolic", 16) {
            valign = Gtk.Align.START,
            css_classes = { "flat", "dim-label", "no-padding" }
        };
        
        hide_loading_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            valign = Gtk.Align.START,
            child = hide_loading_button
        };

        select_checkbutton = new Gtk.CheckButton () {
            valign = Gtk.Align.CENTER,
            margin_start = 6,
            css_classes = { "circular-check" }
        };

        select_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = select_checkbutton
        };

        var project_label = new Gtk.Label (item.project.short_name) {
            css_classes = { "small-label", "dim-label" },
            margin_start = 6
        };

        project_label_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = project_label
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.CENTER,
            margin_start = 6,
            hexpand = true
        };
        content_box.append (content_label_revealer);
        content_box.append (content_entry_revealer);

        // Due Label
        due_label = new Gtk.Label (null) {
            valign = Gtk.Align.CENTER,
            css_classes = { "small-label" }
        };

        var repeat_image = new Gtk.Image.from_icon_name ("playlist-repeat-symbolic") {
            pixel_size = 12,
            margin_top = 3
        };

        repeat_label = new Gtk.Label (null) {
            valign = Gtk.Align.CENTER,
            css_classes = { "small-label" },
            ellipsize = Pango.EllipsizeMode.END
        };

        var repeat_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_start = 6
        };

        repeat_box.append (repeat_image);
        repeat_box.append (repeat_label);

        repeat_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = repeat_box
        };

        due_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 6
        };
        due_box.append (due_label);
        due_box.append (repeat_revealer);
    
        due_box_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = due_box
        };

        // Description Icon
        description_image_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = new Gtk.Image.from_icon_name ("text-justify-left-symbolic") {
                valign = Gtk.Align.CENTER,
                margin_start = 6,
                css_classes = { "dim-label" }
            }
        };

        // Pin Icon
        pin_image_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = new Gtk.Image.from_icon_name ("pin-symbolic") {
                valign = Gtk.Align.CENTER,
                margin_start = 6,
                css_classes = { "dim-label" },
                pixel_size = 13
            }
        };

        // Reminder Icon
        var reminder_icon = new Gtk.Image.from_icon_name ("alarm-symbolic") {
            pixel_size = 13
        };

        reminder_count = new Gtk.Label (item.reminders.size.to_string ());
        
        var reminder_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3) {
            valign = Gtk.Align.CENTER,
            margin_start = 6,
            css_classes = { "dim-label" },
        };
        
        reminder_box.append (reminder_icon);
        reminder_box.append (reminder_count);

        reminder_revelaer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = reminder_box
        };

        var content_main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        content_main_box.append (checked_button_revealer);
        content_main_box.append (due_box_revealer);
        content_main_box.append (content_box);
        content_main_box.append (hide_loading_revealer);

        labels_summary = new Widgets.LabelsSummary (item) {
            margin_start = 24
        };

        description_textview = new Widgets.HyperTextView (_("Add a description…")) {
            height_request = 64,
            left_margin = 24,
            right_margin = 6,
            top_margin = 3,
            bottom_margin = 12,
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
            hexpand = true,
            editable = !item.completed && !item.project.is_deck
        };

        description_textview.remove_css_class ("view");

        var description_scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = description_textview
        };

        item_labels = new Widgets.ItemLabels (item) {
            margin_start = 24,
            sensitive = !item.completed
        };

        schedule_button = new Widgets.ScheduleButton () {
            sensitive = !item.completed
        };

        priority_button = new Widgets.PriorityButton () {
            sensitive = !item.completed
        };
        
        label_button = new Widgets.LabelPicker.LabelButton () {
            sensitive = !item.completed
        };
        
        label_button.backend_type = item.project.backend_type;

        pin_button = new Widgets.PinButton () {
            sensitive = !item.completed
        };

        reminder_button = new Widgets.ReminderPicker.ReminderButton () {
            sensitive = !item.completed
        };

        add_button = new Gtk.Button.from_icon_name ("plus-large-symbolic") {
            valign = Gtk.Align.CENTER,
            tooltip_text = _("Add Subtasks"),
            css_classes = { "flat" },
            sensitive = !item.completed
        };

        var attachments = new Widgets.Attachments ();
        attachments.present_item (item);
        
        attachments_button = new Gtk.MenuButton () {
            icon_name = "mail-attachment-symbolic",
            tooltip_text = _("Add Attachments"),
            popover = new Gtk.Popover () {
                child = attachments,
                width_request = 350
            },
            css_classes = { "flat" },
            sensitive = !item.completed
        };
        
        menu_button = new Gtk.MenuButton () {
            icon_name = "view-more-symbolic",
            popover = build_button_context_menu (),
            css_classes = { "flat" },
            hexpand = Services.EventBus.get_default ().mobile_mode ? true : false,
            halign = Services.EventBus.get_default ().mobile_mode ? Gtk.Align.END : Gtk.Align.FILL
        };
    
        action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 16,
            margin_top = 6,
            hexpand = true,
            sensitive = !item.project.is_deck
        };

        if (Services.EventBus.get_default ().mobile_mode) {
            action_box.orientation = Gtk.Orientation.VERTICAL;
        }

        var action_box_right = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = Services.EventBus.get_default ().mobile_mode ? false : true,
            halign = Services.EventBus.get_default ().mobile_mode ? Gtk.Align.FILL : Gtk.Align.END
        };

        action_box_right.append (add_button);
        action_box_right.append (attachments_button);
        action_box_right.append (label_button);
        action_box_right.append (priority_button);
        action_box_right.append (reminder_button);
        action_box_right.append (pin_button);
        action_box_right.append (menu_button);

        action_box.append (schedule_button);
        action_box.append (action_box_right);

        Services.EventBus.get_default ().mobile_mode_change.connect (() => {
            if (Services.EventBus.get_default ().mobile_mode) {
                action_box_right.hexpand = false;
                action_box_right.halign = Gtk.Align.FILL;

                menu_button.hexpand = true;
                menu_button.halign = Gtk.Align.END;

                action_box.orientation = Gtk.Orientation.VERTICAL;
            } else {
                action_box_right.hexpand = true;
                action_box_right.halign = Gtk.Align.END;

                menu_button.hexpand = false;
                menu_button.halign = Gtk.Align.FILL;

                action_box.orientation = Gtk.Orientation.HORIZONTAL;
            }
        });

        var details_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        details_grid.append (description_scrolled_window);
        details_grid.append (item_labels);
        details_grid.append (action_box);

        detail_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = details_grid
        };

        var handle_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.START,
            css_classes = { "transition", "drop-target" }
        };
        handle_grid.append (content_main_box);
        handle_grid.append (labels_summary);
        handle_grid.append (detail_revealer);

        var _itemrow_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_top = 3,
            margin_bottom = 3,
            margin_start = 3,
            margin_end = 3
        };
        _itemrow_box.append (handle_grid);
        _itemrow_box.append (pin_image_revealer);
        _itemrow_box.append (reminder_revelaer);
        _itemrow_box.append (description_image_revealer);
        _itemrow_box.append (select_revealer);
        _itemrow_box.append (project_label_revealer);

        itemrow_box = new Adw.Bin () {
            css_classes = { "transition", "drop-target" },
            child = _itemrow_box
        };

        subitems = new Widgets.SubItems ();
        subitems.present_item (item);
        subitems.reveal_child = item.collapsed;

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.append (itemrow_box);
        box.append (subitems);

        hide_subtask_button = new Gtk.Button.from_icon_name ("pan-end-symbolic") {
            valign = Gtk.Align.START,
            margin_top = 3,
            css_classes = { "flat", "dim-label", "no-padding", "hidden-button" }
        };

        if (item.collapsed) {
            hide_subtask_button.add_css_class ("opened");
        }

        hide_subtask_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            reveal_child = subitems.has_children,
            child = hide_subtask_button
        };

        var h_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        h_box.append (hide_subtask_revealer);
        h_box.append (box);
        
        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.append (motion_top_revealer);
        main_box.append (h_box);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = main_box
        };
        
        child = main_revealer;
        update_request ();

        if (!item.checked && !item.project.is_deck) {                
            build_drag_and_drop ();
        }

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        connect_signals ();
    }

    private void connect_signals () {
        var handle_gesture_click = new Gtk.GestureClick ();
        itemrow_box.add_controller (handle_gesture_click);
        handle_gesture_click.pressed.connect ((n_press, x, y) => {
            if (Services.EventBus.get_default ().multi_select_enabled) {
                select_checkbutton.active = !select_checkbutton.active;
                selected_toggled (select_checkbutton.active);             
            } else {
                Timeout.add (Constants.DRAG_TIMEOUT, () => {
                    if (!on_drag) {
                        if (Services.Settings.get_default ().settings.get_boolean ("open-task-sidebar")) {
                            Services.EventBus.get_default ().open_item (item);
                        } else {
                            edit = true;
                        }
                    }

                    return GLib.Source.REMOVE;
                });
            }
        });

        var description_gesture_click = new Gtk.GestureClick ();
        description_textview.add_controller (description_gesture_click);
        description_gesture_click.pressed.connect ((n_press, x, y) => {
            description_gesture_click.set_state (Gtk.EventSequenceState.CLAIMED);
            description_textview.grab_focus ();
        });

        var content_controller_key = new Gtk.EventControllerKey ();
        content_textview.add_controller (content_controller_key);
        content_controller_key.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == 65293) {
                edit = false;    
                return Gdk.EVENT_STOP;
            } else if (keyval == 65289) {
                description_textview.grab_focus ();
                return Gdk.EVENT_STOP;
            }

            return false;
        });

        content_controller_key.key_released.connect ((keyval, keycode, state) => {            
            if (keyval == 65307) {
                edit = false;
            } else { 
                update ();
            }
        });

        var description_controller_key = new Gtk.EventControllerKey ();
        description_textview.add_controller (description_controller_key);
        description_controller_key.key_released.connect ((keyval, keycode, state) => {
            if (keyval == 65307) {
                edit = false;
            } else {
                update ();
            }
        });

        var checked_button_gesture = new Gtk.GestureClick ();
        checked_button.add_controller (checked_button_gesture);
        checked_button_gesture.pressed.connect (() => {
            checked_button_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            checked_button.active = !checked_button.active;
            checked_toggled (checked_button.active);
        });

        var hide_loading_gesture = new Gtk.GestureClick ();
        hide_loading_button.add_controller (hide_loading_gesture);
        hide_loading_gesture.pressed.connect (() => {
            hide_loading_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            edit = false;
        });

        schedule_button.date_changed.connect ((datetime) => {
            update_due (datetime);
        });

        priority_button.changed.connect ((priority) => {
            if (item.priority != priority) {
                item.priority = priority;

                if (item.project.backend_type == BackendType.TODOIST ||
                    item.project.backend_type == BackendType.CALDAV) {
                    item.update_async ("");
                } else {
                    item.update_local ();
                }
            }
        });

        pin_button.changed.connect (() => {
            update_pinned (!item.pinned);
        });

        label_button.labels_changed.connect ((labels) => {
            update_labels (labels);
        });

        Services.Settings.get_default ().settings.changed.connect ((key) => {
            if (key == "underline-completed-tasks" || key == "clock-format") {
                update_request ();
            }
        });

        var menu_handle_gesture = new Gtk.GestureClick ();
        menu_handle_gesture.set_button (3);
        itemrow_box.add_controller (menu_handle_gesture);
        menu_handle_gesture.pressed.connect ((n_press, x, y) => {
            if (!item.project.is_deck) {
                build_handle_context_menu (x, y);
            }
        });

        var multiselect_gesture = new Gtk.GestureClick ();
        select_checkbutton.add_controller (multiselect_gesture);

        multiselect_gesture.pressed.connect (() => {
            multiselect_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            select_checkbutton.active = !select_checkbutton.active;
            selected_toggled (select_checkbutton.active);
        });    

        Services.EventBus.get_default ().show_multi_select.connect ((active) => {            
            if (active) {
                select_revealer.reveal_child = true;
                checked_button_revealer.reveal_child = false;
                labels_summary.reveal_child = false;
                disable_drag_and_drop ();
            } else {
                select_revealer.reveal_child = false;
                checked_button_revealer.reveal_child = true;

                if (!edit) {
                    labels_summary.check_revealer ();
                }
                
                if (drag_enabled) {
                    build_drag_and_drop ();   
                }
                
                select_checkbutton.active = false;
            }
        });

        var add_subitem_gesture = new Gtk.GestureClick ();
        add_button.add_controller (add_subitem_gesture);
        add_subitem_gesture.pressed.connect ((n_press, x, y) => {
            add_subitem_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            subitems.prepare_new_item ();
        });

        item.loading_change.connect (() => {
            is_loading = item.loading;
        });

        item.sensitive_change.connect (() => {
            sensitive = item.sensitive;
        });

        hide_subtask_button.clicked.connect (() => {
            item.collapsed = !item.collapsed;
            item.update_local ();
        });

        subitems.children_changes.connect (() => {
            check_hide_subtask_button ();
        });

        item.collapsed_change.connect (() => {
            subitems.reveal_child = item.collapsed;

            if (item.collapsed) {
                hide_subtask_button.add_css_class ("opened");
            } else {
                hide_subtask_button.remove_css_class ("opened");
            }
        });

        item.show_item_changed.connect (() => {
            main_revealer.reveal_child = item.show_item;
        });

        reminder_button.reminder_added.connect ((reminder) => {
            reminder.item_id = item.id;

            if (item.project.backend_type == BackendType.TODOIST) {
                item.loading = true;
                Services.Todoist.get_default ().add.begin (reminder, (obj, res) => {
                    HttpResponse response = Services.Todoist.get_default ().add.end (res);
                    item.loading = false;

                    if (response.status) {
                        reminder.id = response.data;
                    } else {
                        reminder.id = Util.get_default ().generate_id (reminder);
                    }

                    item.add_reminder_if_not_exists (reminder);
                });
            } else {
                reminder.id = Util.get_default ().generate_id (reminder);
                item.add_reminder_if_not_exists (reminder);
            }
        });

        item.reminder_added.connect ((reminder) => {
            reminder_button.add_reminder (reminder, item.reminders);
            check_reminders ();
        });

        item.reminder_deleted.connect ((reminder) => {
            reminder_button.delete_reminder (reminder, item.reminders);
            check_reminders ();
        });
    }

    public void check_hide_subtask_button () {
        if (!edit) {
            hide_subtask_revealer.reveal_child = subitems.has_children;
        }
    }

    private void selected_toggled (bool active) {
        if (select_checkbutton.active) {
            Services.EventBus.get_default ().select_item (this);
        } else {
            Services.EventBus.get_default ().unselect_item (this);
        }
    }

    private void update () {
        if (item.content != content_textview.buffer.text ||
            item.description != description_textview.get_text ()) {
            item.content = content_textview.buffer.text;
            item.description = description_textview.get_text ();
            item.update_async_timeout (update_id);
        }
    }

    public override void select_row (bool active) {
        if (active) {
            itemrow_box.add_css_class ("complete-animation");
        } else {
            itemrow_box.remove_css_class ("complete-animation");
        }
    }

    public override void update_request () {
        if (complete_timeout <= 0) {
            Util.get_default ().set_widget_priority (item.priority, checked_button);
            checked_button.active = item.completed;

            if (item.completed && Services.Settings.get_default ().settings.get_boolean ("underline-completed-tasks")) {
                content_label.add_css_class ("line-through");
            } else if (item.completed && !Services.Settings.get_default ().settings.get_boolean ("underline-completed-tasks")) {
                content_label.remove_css_class ("line-through");
            }
        }

        content_label.label = item.content;
        content_label.tooltip_text = item.content;
        content_textview.buffer.text = item.content;
        description_textview.set_text (item.description);
                
        labels_summary.update_request ();
        label_button.labels = item._get_labels ();
        schedule_button.update_from_item (item);
        priority_button.update_from_item (item);
        pin_button.update_from_item (item);
        reminder_button.set_reminders (item.reminders);
        
        check_due ();
        check_description ();
        check_pinboard ();
        check_reminders ();

        if (!edit) {
            labels_summary.check_revealer ();
        }

        if (edit) {
            content_textview.editable = !item.completed && !item.project.is_deck;
            description_textview.editable = !item.completed && !item.project.is_deck;
            item_labels.sensitive = !item.completed && !item.project.is_deck;
            
            schedule_button.sensitive = !item.completed;
            priority_button.sensitive = !item.completed;
            label_button.sensitive = !item.completed;
            pin_button.sensitive = !item.completed;
            reminder_button.sensitive = !item.completed;
            add_button.sensitive = !item.completed;
            attachments_button.sensitive = !item.completed;
        }
    }

    private void check_description () {
        description_image_revealer.reveal_child = !edit && Util.get_default ().line_break_to_space (item.description).length > 0;
    }

    private void check_pinboard () {
        pin_image_revealer.reveal_child = !edit && item.pinned;
    }

    private void check_reminders () {
        reminder_count.label = item.reminders.size.to_string ();
        reminder_revelaer.reveal_child = !edit && item.reminders.size > 0;
    }

    private void check_due () {
        due_box.remove_css_class ("overdue-grid");
        due_box.remove_css_class ("today-grid");
        due_box.remove_css_class ("upcoming-grid");

        if (item.completed) {
            due_label.label = Utils.Datetime.get_relative_date_from_date (
                Utils.Datetime.get_format_date (
                    Utils.Datetime.get_date_from_string (item.completed_at)
                )
            );
            due_box.add_css_class ("completed-grid");
            due_box_revealer.reveal_child = true;
            return;
        }

        if (item.has_due) {
            due_label.label = Utils.Datetime.get_relative_date_from_date (item.due.datetime);

            if (!edit) {
                due_box_revealer.reveal_child = true;
            }

            repeat_revealer.reveal_child = item.due.is_recurring;
            if (item.due.is_recurring) {
                due_label.label += ", ";
                repeat_label.label = Utils.Datetime.get_recurrency_weeks (
                    item.due.recurrency_type, item.due.recurrency_interval,
                    item.due.recurrency_weeks
                ).down ();
            }

            if (Utils.Datetime.is_today (item.due.datetime)) {
                due_box.add_css_class ("today-grid");
            } else if (Utils.Datetime.is_overdue (item.due.datetime)) {
                due_box.add_css_class ("overdue-grid");
            } else {
                due_box.add_css_class ("upcoming-grid");
            }
        } else {
            due_label.label = "";
            repeat_label.label = "";

            due_box_revealer.reveal_child = false;
            repeat_revealer.reveal_child = false;
        }
    }

    public override void hide_destroy () {
        widget_destroyed ();
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }
    
    public void update_pinned (bool pinned) {
        item.pinned = pinned;
        
        if (item.project.backend_type == BackendType.CALDAV) {
            item.update_async ("");
        } else {
            item.update_local ();
        }
    }

    private void build_handle_context_menu (double x, double y) {
        if (menu_handle_popover != null) {
            if (item.has_due) {
                no_date_item.visible = true;
            } else {
                no_date_item.visible = false;
            }

            menu_handle_popover.pointing_to = { ((int) x), (int) y, 1, 1 };
            menu_handle_popover.popup ();
            return;
        }

        var today_item = new Widgets.ContextMenu.MenuItem (_("Today"), "star-outline-thick-symbolic");
        today_item.secondary_text = new GLib.DateTime.now_local ().format ("%a");

        var tomorrow_item = new Widgets.ContextMenu.MenuItem (_("Tomorrow"), "month-symbolic");
        tomorrow_item.secondary_text = new GLib.DateTime.now_local ().add_days (1).format ("%a");

        var pinboard_item = new Widgets.ContextMenu.MenuItem (_("Pin"), "pin-symbolic");
        
        no_date_item = new Widgets.ContextMenu.MenuItem (_("No Date"), "cross-large-circle-filled-symbolic");
        no_date_item.visible = item.has_due;

        var move_item = new Widgets.ContextMenu.MenuItem (_("Move"), "arrow3-right-symbolic");

        var add_item = new Widgets.ContextMenu.MenuItem (_("Add Subtask"), "plus-large-symbolic");
        var complete_item = new Widgets.ContextMenu.MenuItem (_("Complete"), "check-round-outline-symbolic");
        var edit_item = new Widgets.ContextMenu.MenuItem (_("Edit"), "edit-symbolic");
        var duplicate_item = new Widgets.ContextMenu.MenuItem (_("Duplicate"), "tabs-stack-symbolic");

        var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete Task"), "user-trash-symbolic");
        delete_item.add_css_class ("menu-item-danger");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;

        if (!item.completed && !item.project.is_deck) {
            menu_box.append (today_item);
            menu_box.append (tomorrow_item);
            menu_box.append (pinboard_item);
            menu_box.append (no_date_item);
            menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
            menu_box.append (move_item);
            menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
            menu_box.append (complete_item);
            menu_box.append (edit_item);
            menu_box.append (add_item);
            menu_box.append (duplicate_item);
            menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        }

        if (!item.project.is_deck) {
            menu_box.append (delete_item);
        }

        menu_handle_popover = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            halign = Gtk.Align.START,
            width_request = 250
        };

        menu_handle_popover.set_parent (this);
        menu_handle_popover.pointing_to = { ((int) x), (int) y, 1, 1 };
        menu_handle_popover.popup ();

        move_item.activate_item.connect (() => {
            menu_handle_popover.popdown ();

            BackendType backend_type;
            if (item.project.is_inbox_project) {
                backend_type = BackendType.ALL;
            } else {
                backend_type = item.project.backend_type;
            }

            var dialog = new Dialogs.ProjectPicker.ProjectPicker (PickerType.PROJECTS, backend_type);
            dialog.add_sections (item.project.sections);
            dialog.project = item.project;
            dialog.section = item.section;
            dialog.show ();

            dialog.changed.connect ((type, id) => {
                if (type == "project") {
                    move (Services.Database.get_default ().get_project (id), "");
                } else {
                    move (item.project, id);
                }
            });
        });

        today_item.activate_item.connect (() => {
            menu_handle_popover.popdown ();
            update_due (Utils.Datetime.get_format_date (new DateTime.now_local ()));
        });

        tomorrow_item.activate_item.connect (() => {
            menu_handle_popover.popdown ();
            update_due (Utils.Datetime.get_format_date (new DateTime.now_local ().add_days (1)));
        });

        pinboard_item.activate_item.connect (() => {
            menu_handle_popover.popdown ();
            update_pinned (!item.pinned);
        });

        no_date_item.activate_item.connect (() => {
            menu_handle_popover.popdown ();
            update_due (null);
        });

        complete_item.activate_item.connect (() => {
            menu_handle_popover.popdown ();
            checked_button.active = !checked_button.active;
            checked_toggled (checked_button.active);
        });

        edit_item.activate_item.connect (() => {
            menu_handle_popover.popdown ();
            Services.EventBus.get_default ().open_item (item);
        });

        delete_item.activate_item.connect (() => {
            menu_handle_popover.popdown ();
            delete_request ();
        });

        add_item.activate_item.connect (() => {
            menu_handle_popover.popdown ();

            var dialog = new Dialogs.QuickAdd ();
            dialog.for_base_object (item);
            dialog.show ();
        });

        duplicate_item.clicked.connect (() => {
            menu_handle_popover.popdown ();
            Util.get_default ().duplicate_item.begin (item, item.project_id, item.section_id, item.parent_id);
        });
    }

    private string get_updated_info () {
        string added_at = _("Added at");
        string updated_at = _("Updated at");
        string added_date = Utils.Datetime.get_relative_date_from_date (item.added_datetime);
        string updated_date = "(" + _("Not available") + ")";
        if (item.updated_at != "") {
            updated_date = Utils.Datetime.get_relative_date_from_date (item.updated_datetime);
        }

        return "<b>%s:</b> %s\n<b>%s:</b> %s".printf (added_at, added_date, updated_at, updated_date);
    }

    private Gtk.Popover build_button_context_menu () {
        var back_item = new Widgets.ContextMenu.MenuItem (_("Back"), "go-previous-symbolic");

        var copy_clipboard_item = new Widgets.ContextMenu.MenuItem (_("Copy to Clipboard"), "clipboard-symbolic");
        var duplicate_item = new Widgets.ContextMenu.MenuItem (_("Duplicate"), "tabs-stack-symbolic");
        var move_item = new Widgets.ContextMenu.MenuItem (_("Move"), "arrow3-right-symbolic");
        var repeat_item = new Widgets.ContextMenu.MenuItem (_("Repeat"), "playlist-repeat-symbolic");
        repeat_item.arrow = true;

        var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete Task"), "user-trash-symbolic");
        delete_item.add_css_class ("menu-item-danger");

        var more_information_item = new Widgets.ContextMenu.MenuItem ("", null);
        more_information_item.add_css_class ("small-label");

        var popover = new Gtk.Popover () {
            has_arrow = false,
            position = Gtk.PositionType.BOTTOM,
            width_request = 225
        };

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;

        if (!item.completed) {
            menu_box.append (copy_clipboard_item);
            menu_box.append (duplicate_item);
            menu_box.append (move_item);
            menu_box.append (repeat_item);
            menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        }

        
        menu_box.append (delete_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (more_information_item);

        var menu_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT,
            vhomogeneous = false
        };

        menu_stack.add_named (menu_box, "menu");
        menu_stack.add_named (get_repeat_widget (popover, back_item), "repeat");

        popover.child = menu_stack;

        copy_clipboard_item.clicked.connect (() => {
            popover.popdown ();
            item.copy_clipboard ();
        });

        duplicate_item.clicked.connect (() => {
            popover.popdown ();
            Util.get_default ().duplicate_item.begin (item, item.section_id, item.parent_id);
        });

        move_item.clicked.connect (() => {            
            popover.popdown ();
            
            var dialog = new Dialogs.ProjectPicker.ProjectPicker (PickerType.PROJECTS, item.project.backend_type);
            dialog.add_sections (item.project.sections);
            dialog.project = item.project;
            dialog.section = item.section;
            dialog.show ();

            dialog.changed.connect ((type, id) => {
                if (type == "project") {
                    move (Services.Database.get_default ().get_project (id), "");
                } else {
                    move (item.project, id);
                }
            });
        });

        repeat_item.clicked.connect (() => {
            menu_stack.set_visible_child_name ("repeat");
        });

        popover.closed.connect (() => {
            menu_stack.set_visible_child_name ("menu");
        });

        back_item.clicked.connect (() => {
            menu_stack.set_visible_child_name ("menu");
        });

        popover.show.connect (() => {
            more_information_item.title = get_updated_info ();
        });

        delete_item.activate_item.connect (() => {
            popover.popdown ();
            delete_request ();
        });

        return popover;
    }

    private Gtk.Widget get_repeat_widget (Gtk.Popover popover, Widgets.ContextMenu.MenuItem back_item) {
        var none_item = new Widgets.ContextMenu.MenuItem (_("None"));
        var daily_item = new Widgets.ContextMenu.MenuItem (_("Daily"));
        var weekly_item = new Widgets.ContextMenu.MenuItem (_("Weekly"));
        var monthly_item = new Widgets.ContextMenu.MenuItem (_("Monthly"));
        var yearly_item = new Widgets.ContextMenu.MenuItem (_("Yearly"));
        var custom_item = new Widgets.ContextMenu.MenuItem (_("Custom"));
        
        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (back_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (daily_item);
        menu_box.append (weekly_item);
        menu_box.append (monthly_item);
        menu_box.append (yearly_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (none_item);
        menu_box.append (custom_item);
        
        daily_item.clicked.connect (() => {
            popover.popdown ();

            var duedate = new Objects.DueDate ();
            duedate.is_recurring = true;
            duedate.recurrency_type = RecurrencyType.EVERY_DAY;
            duedate.recurrency_interval = 1;

            item.set_recurrency (duedate);
        });

        weekly_item.clicked.connect (() => {
            popover.popdown ();

            var duedate = new Objects.DueDate ();
            duedate.is_recurring = true;
            duedate.recurrency_type = RecurrencyType.EVERY_WEEK;
            duedate.recurrency_interval = 1;

            item.set_recurrency (duedate);
        });

        monthly_item.clicked.connect (() => {
            popover.popdown ();

            var duedate = new Objects.DueDate ();
            duedate.is_recurring = true;
            duedate.recurrency_type = RecurrencyType.EVERY_MONTH;
            duedate.recurrency_interval = 1;

            item.set_recurrency (duedate);
        });

        yearly_item.clicked.connect (() => {
            popover.popdown ();

            var duedate = new Objects.DueDate ();
            duedate.is_recurring = true;
            duedate.recurrency_type = RecurrencyType.EVERY_YEAR;
            duedate.recurrency_interval = 1;

            item.set_recurrency (duedate);
        });

        none_item.clicked.connect (() => {
            popover.popdown ();

            var duedate = new Objects.DueDate ();
            duedate.is_recurring = false;
            duedate.recurrency_type = RecurrencyType.NONE;
            duedate.recurrency_interval = 0;

            item.set_recurrency (duedate);
        });

        custom_item.clicked.connect (() => {
            popover.popdown ();

            var dialog = new Dialogs.RepeatConfig ();
            dialog.show ();

            if (item.has_due) {
                dialog.duedate = item.due;
            }

            dialog.change.connect ((duedate) => {
                item.set_recurrency (duedate);
            });
        });

        return menu_box;
    }

    public override void checked_toggled (bool active, uint? time = null) {
        bool old_checked = item.checked;

        if (active) {
            complete_item (old_checked, time);
        } else {
            if (complete_timeout != 0) {
                GLib.Source.remove (complete_timeout);
                complete_timeout = 0;
                itemrow_box.remove_css_class ("complete-animation");
                content_label.remove_css_class ("dim-label");
                content_label.remove_css_class ("line-through");
            } else {
                item.checked = false;
                item.completed_at = "";
                _complete_item (old_checked);
            }
        }
    }

    private void complete_item (bool old_checked, uint? time = null) {
        if (Services.Settings.get_default ().settings.get_boolean ("task-complete-tone")) {
            Util.get_default ().play_audio ();
        }

        uint timeout = 2500;
        if (Services.Settings.get_default ().settings.get_enum ("complete-task") == 0) {
            timeout = 0;
        }

        if (time != null) {
            timeout = time;
        }

        if (!edit) {
            content_label.add_css_class ("dim-label");
            itemrow_box.add_css_class ("complete-animation");
            if (Services.Settings.get_default ().settings.get_boolean ("underline-completed-tasks")) {
                content_label.add_css_class ("line-through");
            }
        }

        complete_timeout = Timeout.add (timeout, () => {
            complete_timeout = 0;

            if (item.due.is_recurring && !item.due.is_recurrency_end) {
                update_next_recurrency ();
            } else {
                item.checked = true;
                item.completed_at = Utils.Datetime.get_format_date (
                    new GLib.DateTime.now_local ()
                ).to_string ();    
                _complete_item (old_checked);   
            }
            
            return GLib.Source.REMOVE;
        });
    }

    private void _complete_item (bool old_checked) {
        if (item.project.backend_type == BackendType.LOCAL) {
            Services.Database.get_default ().checked_toggled (item, old_checked);
        } else if (item.project.backend_type == BackendType.TODOIST) {
            checked_button.sensitive = false;
            is_loading = true;
            Services.Todoist.get_default ().complete_item.begin (item, (obj, res) => {
                if (Services.Todoist.get_default ().complete_item.end (res).status) {
                    Services.Database.get_default ().checked_toggled (item, old_checked);
                    is_loading = false;
                    checked_button.sensitive = true;
                }
            });
        } else if (item.project.backend_type == BackendType.CALDAV) {
            checked_button.sensitive = false;
            is_loading = true;
            Services.CalDAV.Core.get_default ().complete_item.begin (item, (obj, res) => {
                if (Services.CalDAV.Core.get_default ().complete_item.end (res).status) {
                    Services.Database.get_default ().checked_toggled (item, old_checked);
                    is_loading = false;
                    checked_button.sensitive = true;
                }
            });
        }
    }

    public void update_content (string content = "") {
        content_textview.buffer.text = content;
    }

    public void update_priority (int priority) {
        item.priority = priority;
        item.update_async ("");
    }

    public void update_due (GLib.DateTime? datetime) {
        item.due.date = datetime == null ? "" : Utils.Datetime.get_todoist_datetime_format (datetime);

        if (item.due.date == "") {
            item.due.reset ();
        }

        item.update_async ("");
    }

    private void update_next_recurrency () {
        var promise = new Services.Promise<GLib.DateTime> ();

        promise.resolved.connect ((result) => {
            recurrency_update_complete (result);
        });

        item.update_next_recurrency (promise);
    }

    private void recurrency_update_complete (GLib.DateTime next_recurrency) {
        checked_button.active = false;
        complete_timeout = 0;
        itemrow_box.remove_css_class ("complete-animation");
        content_label.remove_css_class ("dim-label");
        content_label.remove_css_class ("line-through");

        var title = _("Completed. Next occurrence: %s".printf (
            Utils.Datetime.get_default_date_format_from_date (next_recurrency)
        ));
        var toast = Util.get_default ().create_toast (title, 3);
        Services.EventBus.get_default ().send_notification (toast);
    }

    public void update_labels (Gee.HashMap<string, Objects.Label> new_labels) {
        bool update = false;
        
        foreach (var entry in new_labels.entries) {
            if (item.get_label (entry.key) == null) {
                item.add_label_if_not_exists (entry.value);
                update = true;
            }
        }
        
        foreach (var label in item._get_labels ()) {
            if (!new_labels.has_key (label.id)) {
                item.delete_item_label (label.id);
                update = true;
            }
        }

        if (!update) {
            return;
        }

        item.update_async ("");
    }

    public override void delete_request (bool undo = true) {
        main_revealer.reveal_child = false;

        if (undo) {
            delete_undo ();
        } else {
            item.delete_item ();
        }
    }

    private void delete_undo () {
        var toast = new Adw.Toast (_("%s was deleted".printf (Util.get_default ().get_short_name (item.content))));
        toast.button_label = _("Undo");
        toast.priority = Adw.ToastPriority.HIGH;
        toast.timeout = 3;

        Services.EventBus.get_default ().send_notification (toast);

        toast.dismissed.connect (() => {
            if (!main_revealer.reveal_child) {
                item.delete_item ();
            }
        });

        toast.button_clicked.connect (() => {
            main_revealer.reveal_child = true;
        });
    }

    public void move (Objects.Project project, string section_id) {
        string project_id = project.id;

        if (item.project.backend_type != project.backend_type) {
            Util.get_default ().move_backend_type_item.begin (item, project);
        } else {
            if (item.project_id != project_id || item.section_id != section_id) {
                item.move (project, section_id);
            }
        }
    }
    
    public void build_drag_and_drop () {
        // Drop Motion
        build_drop_motion ();

        // Drag Souyrce
        build_drag_source ();

        // Drop
        build_drop_target ();

        // Drop Magic Button
        build_drop_magic_button_target ();

        // Drop Order
        build_drop_order_target ();
    }

    private void build_drop_motion () {
        drop_motion_ctrl = new Gtk.DropControllerMotion ();
        add_controller (drop_motion_ctrl);

        dnd_handlerses[drop_motion_ctrl.motion.connect ((x, y) => {
            var drop = drop_motion_ctrl.get_drop ();
            GLib.Value value = Value (typeof (Gtk.Widget));

            try {
                drop.drag.content.get_value (ref value);
            } catch (Error e) {
                debug (e.message);
            }

            if (value.dup_object () is Layouts.ItemBoard) {
                var picked_widget = (Layouts.ItemBoard) value;
                motion_top_grid.height_request = picked_widget.handle_grid.get_height ();
            } else {
                motion_top_grid.height_request = 32;
            }
            
            motion_top_revealer.reveal_child = drop_motion_ctrl.contains_pointer;
        })] = drop_motion_ctrl;

        dnd_handlerses[drop_motion_ctrl.leave.connect (() => {
            motion_top_revealer.reveal_child = false;
        })] = drop_motion_ctrl;
    }

    private void build_drag_source () {
        drag_source = new Gtk.DragSource ();
        drag_source.set_actions (Gdk.DragAction.MOVE);
        itemrow_box.add_controller (drag_source);

        dnd_handlerses[drag_source.prepare.connect ((source, x, y) => {
            return new Gdk.ContentProvider.for_value (this);
        })] = drag_source;

        dnd_handlerses[drag_source.drag_begin.connect ((source, drag) => {
            var paintable = new Gtk.WidgetPaintable (itemrow_box);
            source.set_icon (paintable, 0, 0);
            drag_begin ();
        })] = drag_source;

        dnd_handlerses[drag_source.drag_end.connect ((source, drag, delete_data) => {
            drag_end ();
        })] = drag_source;

        dnd_handlerses[drag_source.drag_cancel.connect ((source, drag, reason) => {
            drag_end ();
            return false;
        })] = drag_source;
    }

    private void build_drop_target () {
        drop_target = new Gtk.DropTarget (typeof (Layouts.ItemRow), Gdk.DragAction.MOVE);
        itemrow_box.add_controller (drop_target);

        dnd_handlerses[drop_target.drop.connect ((value, x, y) => {
            var picked_widget = (Layouts.ItemRow) value;
            var target_widget = this;

            var picked_item = picked_widget.item;
            var target_item = target_widget.item;

            if (picked_widget == target_widget || target_widget == null) {
                return false;
            }

            string old_parent_id = picked_item.parent_id;
            string old_project_id = picked_item.project_id;
            string old_section_id = picked_item.section_id;

            picked_item.section_id = "";
            picked_item.parent_id = target_item.id;

            if (picked_item.project.backend_type == BackendType.LOCAL) {
                target_item.collapsed = true;
                Services.Database.get_default ().update_item (picked_item);
                Services.EventBus.get_default ().item_moved (picked_item, old_project_id, old_section_id, old_parent_id);
            } else if (picked_item.project.backend_type == BackendType.TODOIST) {
                Services.Todoist.get_default ().move_item.begin (picked_item, "parent_id", picked_item.parent_id, (obj, res) => {
                    if (Services.Todoist.get_default ().move_item.end (res).status) {
                        target_item.collapsed = true;
                        Services.Database.get_default ().update_item (picked_widget.item);
                        Services.EventBus.get_default ().item_moved (picked_item, old_project_id, old_section_id, old_parent_id);
                    }
                });
            } else if (picked_item.project.backend_type == BackendType.CALDAV) {
                Services.CalDAV.Core.get_default ().add_task.begin (picked_item, true, (obj, res) => {
                    if (Services.CalDAV.Core.get_default ().add_task.end (res).status) {
                        target_item.collapsed = true;
                        Services.Database.get_default ().update_item (picked_widget.item);
                        Services.EventBus.get_default ().item_moved (picked_item, old_project_id, old_section_id, old_parent_id);
                    }
                });
            }

            return true;
        })] = drop_target;
    }

    private void build_drop_magic_button_target () {
        drop_magic_button_target = new Gtk.DropTarget (typeof (Widgets.MagicButton), Gdk.DragAction.MOVE);
        itemrow_box.add_controller (drop_magic_button_target);

        dnd_handlerses[drop_magic_button_target.drop.connect ((value, x, y) => {
            var dialog = new Dialogs.QuickAdd ();
            dialog.for_base_object (item);
            dialog.show ();

            return true;
        })] = drop_magic_button_target;

        drop_order_magic_button_target = new Gtk.DropTarget (typeof (Widgets.MagicButton), Gdk.DragAction.MOVE);
        motion_top_grid.add_controller (drop_order_magic_button_target);
        dnd_handlerses[drop_order_magic_button_target.drop.connect ((value, x, y) => {            
            var dialog = new Dialogs.QuickAdd ();
            dialog.set_index (get_index ());
            
            if (item.has_parent) {
                dialog.for_base_object (item.parent);
            } else {
                if (item.section_id != "") {
                    dialog.for_base_object (item.section);
                } else {
                    dialog.for_base_object (item.project);
                }
            }

            dialog.show ();
            return true;
        })] = drop_order_magic_button_target;
    }

    private void build_drop_order_target () {
        drop_order_target = new Gtk.DropTarget (typeof (Layouts.ItemRow), Gdk.DragAction.MOVE);
        motion_top_grid.add_controller (drop_order_target);
        dnd_handlerses[drop_order_target.drop.connect ((value, x, y) => {
            var picked_widget = (Layouts.ItemRow) value;
            var target_widget = this;
            var old_section_id = "";
            var old_parent_id = "";

            picked_widget.drag_end ();
            target_widget.drag_end ();

            if (picked_widget == target_widget || target_widget == null) {
                return false;
            }

            if (item.project.sort_order != 0) {
                item.project.sort_order = 0;
                Services.EventBus.get_default ().send_notification (
                    Util.get_default ().create_toast (_("Order changed to 'Custom sort order'"))
                );
			    item.project.update_local ();
            }

            old_section_id = picked_widget.item.section_id;
            old_parent_id = picked_widget.item.parent_id;

            if (picked_widget.item.project_id != target_widget.item.project_id ||
                picked_widget.item.section_id != target_widget.item.section_id ||
                picked_widget.item.parent_id != target_widget.item.parent_id) {

                if (picked_widget.item.project_id != target_widget.item.project_id) {
                    picked_widget.item.project_id = target_widget.item.project_id;
                }

                if (picked_widget.item.section_id != target_widget.item.section_id) {
                    picked_widget.item.section_id = target_widget.item.section_id;
                }

                if (picked_widget.item.parent_id != target_widget.item.parent_id) {
                    picked_widget.item.parent_id = target_widget.item.parent_id;
                }

                if (picked_widget.item.project.backend_type == BackendType.LOCAL) {
                    Services.Database.get_default ().update_item (picked_widget.item);
                } else if (picked_widget.item.project.backend_type == BackendType.TODOIST) {
                    string move_id = picked_widget.item.project_id;
                    string move_type = "project_id";

                    if (picked_widget.item.section_id != "") {
                        move_id = picked_widget.item.section_id;
                        move_type = "section_id";
                    }

                    if (picked_widget.item.has_parent) {
                        move_id = picked_widget.item.parent_id;
                        move_type = "parent_id";
                    }
                    
                    Services.Todoist.get_default ().move_item.begin (picked_widget.item, move_type, move_id, (obj, res) => {
                        if (Services.Todoist.get_default ().move_item.end (res).status) {
                            Services.Database.get_default ().update_item (picked_widget.item);
                        }
                    });
                } else if (picked_widget.item.project.backend_type == BackendType.CALDAV) {
                    Services.CalDAV.Core.get_default ().add_task.begin (picked_widget.item, true, (obj, res) => {
                        if (Services.CalDAV.Core.get_default ().add_task.end (res).status) {
                            Services.Database.get_default ().update_item (picked_widget.item);
                        }
                    });
                }
            }

            var source_list = (Gtk.ListBox) picked_widget.parent;
            var target_list = (Gtk.ListBox) target_widget.parent;

            source_list.remove (picked_widget);
            target_list.insert (picked_widget, target_widget.get_index ());
            Services.EventBus.get_default ().update_inserted_item_map (picked_widget, old_section_id, old_parent_id);
            update_items_item_order (target_list);

            return true;
        })] = drop_order_target;
    }

    public void disable_drag_and_drop () {
        drag_enabled = false;
        _disable_drag_and_drop ();
    }

    private void _disable_drag_and_drop () {
        remove_controller (drop_motion_ctrl);
        itemrow_box.remove_controller (drag_source);
        itemrow_box.remove_controller (drop_target);
        itemrow_box.remove_controller (drop_magic_button_target);
        motion_top_grid.remove_controller (drop_order_target);
        motion_top_grid.remove_controller (drop_order_magic_button_target);

        foreach (var entry in dnd_handlerses.entries) {
            entry.value.disconnect (entry.key);
        }
    }

    public void drag_begin () {
        itemrow_box.add_css_class ("drop-begin");
        on_drag = true;
        main_revealer.reveal_child = false;
        Services.EventBus.get_default ().drag_n_drop_active (item.project_id, true);
    }

    public void drag_end () {
        itemrow_box.remove_css_class ("drop-begin");
        on_drag = false;
        main_revealer.reveal_child = item.show_item;
        Services.EventBus.get_default ().drag_n_drop_active (item.project_id, false);
    }
    
    private void update_items_item_order (Gtk.ListBox listbox) {
        unowned Layouts.ItemRow? item_row = null;
        var row_index = 0;

        do {
            item_row = (Layouts.ItemRow) listbox.get_row_at_index (row_index);

            if (item_row != null) {
                item_row.item.child_order = row_index;
                Services.Database.get_default ().update_item (item_row.item);
            }

            row_index++;
        } while (item_row != null);
    }
}
