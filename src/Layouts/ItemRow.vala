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
    public bool is_project_view { get; construct; }

    public string project_id { get; set; default = ""; }
    public string section_id { get; set; default = ""; }
    public string parent_id { get; set; default = ""; }

    private Gtk.Grid motion_top_grid;
    private Gtk.Revealer motion_top_revealer;

    private Gtk.CheckButton checked_button;
    private Gtk.Revealer checked_button_revealer;
    private Widgets.TextView content_textview;
    private Gtk.Revealer hide_loading_revealer;
    private Gtk.Label project_name_label;
    private Gtk.Revealer project_name_label_revealer;

    private Gtk.CheckButton select_checkbutton;
    private Gtk.Revealer select_revealer;

    private Gtk.Label content_label;
    private Gtk.Revealer content_label_revealer;
    private Gtk.Revealer content_entry_revealer;
    private Gtk.Box content_box;

    private Gtk.Label due_label;
    private Gtk.Box due_box;
    private Gtk.Label repeat_label;
    private Gtk.Revealer repeat_revealer;
    private Gtk.Revealer due_box_revealer;
    private Gtk.Revealer description_image_revealer;
    private Gtk.Revealer reminder_revelaer;
    private Gtk.Label reminder_count;
    private Gtk.Box action_box_right;

    private Gtk.Revealer detail_revealer;
    private Gtk.Revealer main_revealer;
    public Adw.Bin itemrow_box;
    private Gtk.Popover menu_handle_popover = null;

    private Widgets.LoadingButton hide_loading_button;
    private Widgets.Markdown.Buffer current_buffer;
    private Widgets.Markdown.EditView markdown_edit_view = null;
    private Gtk.Revealer markdown_revealer;
    private Widgets.ItemLabels item_labels;
    private Widgets.ScheduleButton schedule_button;
    private Widgets.LabelsSummary labels_summary;
    private Widgets.PriorityButton priority_button;
    private Widgets.LabelPicker.LabelButton label_button;
    private Widgets.PinButton pin_button;
    private Widgets.ReminderPicker.ReminderButton reminder_button;
    private Gtk.Button add_button;
    private Gtk.MenuButton attachments_button;
    private Widgets.Attachments attachments;
    private Gtk.Label attachments_count;
    private Gtk.Box action_box;
    private Gtk.Label show_subtasks_label;
    private Gtk.Revealer show_subtasks_revealer;

    private Widgets.SubItems subitems;
    private Gtk.MenuButton menu_button;
    private Gtk.Button hide_subtask_button;
    private Gtk.Button show_subtasks_button;
    private Gtk.Revealer hide_subtask_revealer;
    private Widgets.ContextMenu.MenuItem no_date_item;
    private Widgets.ContextMenu.MenuItem pinboard_item;

    private Gtk.DropControllerMotion drop_motion_ctrl;
    private Gtk.DragSource drag_source;
    private Gtk.DropTarget drop_target;
    private Gtk.DropTarget drop_order_target;
    private Gtk.DropTarget drop_magic_button_target;
    private Gtk.DropTarget drop_order_magic_button_target;
    
    private Gee.HashMap<ulong, weak GLib.Object> dnd_handlerses = new Gee.HashMap<ulong, weak GLib.Object> ();
    private ulong description_handler_change_id = 0;
    private Gee.HashMap<ulong, weak GLib.Object> signals_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    bool _edit = false;
    public bool edit {
        set {
            _edit = value;

            if (value) {
                add_css_class ("no-selectable");
                itemrow_box.add_css_class ("card");
                itemrow_box.add_css_class ("card-selected");

                build_markdown_edit_view ();

                detail_revealer.reveal_child = true;
                content_label_revealer.reveal_child = false;
                content_entry_revealer.reveal_child = true;
                project_name_label_revealer.reveal_child = false;
                labels_summary.reveal_child = false;
                hide_subtask_revealer.reveal_child = false;
                hide_loading_button.remove_css_class ("no-padding");
                hide_loading_revealer.reveal_child = true;
                show_subtasks_revealer.reveal_child = subitems.has_children && edit;

                // Due labels
                due_box_revealer.reveal_child = false;
                description_image_revealer.reveal_child = false;
                reminder_revelaer.reveal_child = false;

                if (complete_timeout != 0) {
                    itemrow_box.remove_css_class ("complete-animation");
                    content_label.remove_css_class ("dimmed");
                }

                _disable_drag_and_drop ();

                Timeout.add (250, () => {
                    content_textview.grab_focus ();
                    return GLib.Source.REMOVE;
                });
            } else {
                add_css_class ("no-selectable");
                itemrow_box.remove_css_class ("card-selected");
                itemrow_box.remove_css_class ("card");

                destroy_markdown_edit_view ();

                detail_revealer.reveal_child = false;
                content_label_revealer.reveal_child = true;
                content_entry_revealer.reveal_child = false;
                project_name_label_revealer.reveal_child = !is_project_view;
                hide_subtask_revealer.reveal_child = subitems.has_children;
                hide_loading_button.add_css_class ("no-padding");
                hide_loading_revealer.reveal_child = false;
                show_subtasks_revealer.reveal_child = false;

                check_due ();
                check_description ();
                check_reminders ();
                labels_summary.check_revealer ();

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

    public uint destroy_timeout { get; set; default = 0; }
    public uint complete_timeout { get; set; default = 0; }
    public bool drag_enabled { get; set; default = true; }

    public signal void item_added ();

    public ItemRow (Objects.Item item, bool is_project_view = false) {
        Object (
            item: item,
            is_project_view: is_project_view
        );
    }

    ~ItemRow () {
        print ("Destroying - Layouts.ItemRow - %s\n".printf (item.content));
    }

    construct {
        css_classes = { "row", "no-padding" };

        project_id = item.project_id;
        section_id = item.section_id;
        parent_id = item.parent_id;

        motion_top_grid = new Gtk.Grid () {
            height_request = 32,
            css_classes = { "drop-area", "drop-target" },
            margin_bottom = 3,
            margin_start = 19
        };

        motion_top_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = motion_top_grid
        };

        checked_button = new Gtk.CheckButton () {
            valign = Gtk.Align.CENTER,
            css_classes = { "priority-color" },
            sensitive = !item.project.is_deck
        };

        checked_button_revealer = new Gtk.Revealer () {
            child = checked_button,
            transition_type = SLIDE_RIGHT,
            reveal_child = true
        };

        // Due Label
        due_label = new Gtk.Label (null) {
            valign = CENTER,
            css_classes = { "caption" }
        };

        var repeat_image = new Gtk.Image.from_icon_name ("playlist-repeat-symbolic") {
            pixel_size = 12,
            margin_top = 3
        };

        repeat_label = new Gtk.Label (null) {
            valign = CENTER,
            ellipsize = END,
            css_classes = { "caption" },
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
            valign = CENTER,
            margin_end = 6
        };
        due_box.append (due_label);
        due_box.append (repeat_revealer);

        due_box_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = due_box
        };

        content_label = new Gtk.Label (null) {
            xalign = 0,
            wrap = false,
            ellipsize = END,
            use_markup = true
        };

        // Description Icon
        description_image_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = new Gtk.Image.from_icon_name ("paper-symbolic") {
                valign = Gtk.Align.CENTER,
                margin_start = 6,
                css_classes = { "dimmed" },
                pixel_size = 12
            }
        };

        // Reminder Icon
        var reminder_icon = new Gtk.Image.from_icon_name ("alarm-symbolic") {
            pixel_size = 12
        };

        reminder_count = new Gtk.Label (item.reminders.size.to_string ());
        reminder_count.add_css_class ("caption");

        var reminder_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3) {
            valign = Gtk.Align.CENTER,
            margin_start = 6,
            margin_top = 1,
            css_classes = { "dimmed" },
        };

        reminder_box.append (reminder_icon);
        reminder_box.append (reminder_count);

        reminder_revelaer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = reminder_box
        };

        var content_label_box = new Gtk.Box (HORIZONTAL, 0);
        content_label_box.append (due_box_revealer);
        content_label_box.append (content_label);
        content_label_box.append (description_image_revealer);
        content_label_box.append (reminder_revelaer);

        content_label_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_UP,
            transition_duration = 115,
            reveal_child = true,
            child = content_label_box
        };

        content_textview = new Widgets.TextView () {
            wrap_mode = WORD,
            accepts_tab = false,
            placeholder_text = _ ("To-do name"),
            hexpand = true,
            valign = CENTER
        };
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
            css_classes = { "flat", "dimmed", "no-padding" }
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

        project_name_label = new Gtk.Label (null) {
            css_classes = { "caption", "dimmed" },
            margin_start = 6,
            ellipsize = Pango.EllipsizeMode.END,
            max_width_chars = 16
        };

        project_name_label_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = project_name_label,
            reveal_child = !is_project_view
        };

        content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = CENTER,
            margin_start = 6
        };
        content_box.append (content_label_revealer);
        content_box.append (content_entry_revealer);


        var content_main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        content_main_box.append (checked_button_revealer);
        content_main_box.append (content_box);
        content_main_box.append (project_name_label_revealer);
        content_main_box.append (hide_loading_revealer);

        labels_summary = new Widgets.LabelsSummary (item) {
            margin_start = 24
        };

        current_buffer = new Widgets.Markdown.Buffer ();

        markdown_revealer = new Gtk.Revealer ();

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

        label_button.source = item.project.source;

        pin_button = new Widgets.PinButton () {
            sensitive = !item.completed
        };

        reminder_button = new Widgets.ReminderPicker.ReminderButton () {
            sensitive = !item.completed
        };

        add_button = new Gtk.Button.from_icon_name ("plus-large-symbolic") {
            valign = Gtk.Align.CENTER,
            tooltip_text = _ ("Add Subtasks"),
            css_classes = { "flat" },
            sensitive = !item.completed
        };

        attachments = new Widgets.Attachments ();
        attachments.present_item (item);

        attachments_button = new Gtk.MenuButton () {
            icon_name = "mail-attachment-symbolic",
            tooltip_text = _ ("Add Attachments"),
            popover = new Gtk.Popover () {
                has_arrow = false,
                child = attachments,
                width_request = 350
            },
            css_classes = { "flat" },
            sensitive = !item.completed
        };

        attachments_count = new Gtk.Label (item.attachments.size.to_string ()) {
            css_classes = { "badge", "caption" },
            width_request = 12,
            margin_end = 3,
            halign = END,
            valign = START,
            visible = item.attachments.size > 0
        };

        var attachments_button_overlay = new Gtk.Overlay () {
            child = attachments_button
        };
        attachments_button_overlay.add_overlay (attachments_count);

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

        action_box_right = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = Services.EventBus.get_default ().mobile_mode ? false : true,
            halign = Services.EventBus.get_default ().mobile_mode ? Gtk.Align.FILL : Gtk.Align.END
        };

        action_box_right.append (add_button);
        action_box_right.append (attachments_button_overlay);
        action_box_right.append (label_button);
        action_box_right.append (priority_button);
        action_box_right.append (reminder_button);
        action_box_right.append (pin_button);
        action_box_right.append (menu_button);

        action_box.append (schedule_button);
        action_box.append (action_box_right);

        var details_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        details_grid.append (markdown_revealer);
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
            margin_end = 3,
            margin_start = 6
        };
        _itemrow_box.append (handle_grid);
        _itemrow_box.append (select_revealer);

        itemrow_box = new Adw.Bin () {
            css_classes = { "transition", "drop-target" },
            child = _itemrow_box
        };

        subitems = new Widgets.SubItems (is_project_view);
        subitems.present_item (item);
        subitems.reveal_child = item.items.size > 0 && item.collapsed;

        show_subtasks_label = new Gtk.Label (null);

        var show_subtasks_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        show_subtasks_box.append (new Gtk.Image.from_icon_name ("go-next-symbolic") {
            pixel_size = 12
        });
        show_subtasks_box.append (show_subtasks_label);

        show_subtasks_button = new Gtk.Button () {
            css_classes = { "flat", "small-button", "hidden-button" },
            child = show_subtasks_box,
            margin_start = 16,
            margin_bottom = 3,
            halign = START
        };

        show_subtasks_revealer = new Gtk.Revealer () {
            child = show_subtasks_button,
            reveal_child = subitems.has_children && edit
        };

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.append (itemrow_box);
        box.append (show_subtasks_revealer);
        box.append (subitems);

        hide_subtask_button = new Gtk.Button () {
            valign = Gtk.Align.START,
            margin_start = 3,
            margin_top = 3,
            css_classes = { "flat", "dimmed", "no-padding", "hidden-button" },
            child = new Gtk.Image.from_icon_name ("go-next-symbolic") {
                pixel_size = 12
            }
        };

        if (item.collapsed) {
            hide_subtask_button.add_css_class ("opened");
            show_subtasks_button.add_css_class ("opened");
        }

        hide_subtask_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            reveal_child = subitems.has_children,
            child = hide_subtask_button
        };

        var h_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
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
        signals_map[handle_gesture_click.released.connect ((n_press, x, y) => {
            if (Services.EventBus.get_default ().multi_select_enabled) {
                select_checkbutton.active = !select_checkbutton.active;
                selected_toggled (select_checkbutton.active);
            } else {
                Timeout.add (100, () => {
                    show_details ();
                    return GLib.Source.REMOVE;
                });
            }
        })] = handle_gesture_click;

        signals_map[activate.connect (() => {
            show_details ();
        })] = this;

        signals_map[Services.EventBus.get_default ().mobile_mode_change.connect (() => {
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
        })] = Services.EventBus.get_default ();

        signals_map[Services.EventBus.get_default ().item_selected.connect ((item_id) => {
            edit = item.id == item_id;
        })] = Services.EventBus.get_default ();

        var content_controller_key = new Gtk.EventControllerKey ();
        content_textview.add_controller (content_controller_key);
        signals_map[content_controller_key.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == 65293) {
                edit = false;
                return Gdk.EVENT_STOP;
            } else if (keyval == 65289) {
                markdown_edit_view.view_focus ();
                return Gdk.EVENT_STOP;
            }

            return false;
        })] = content_controller_key;

        signals_map[content_controller_key.key_released.connect ((keyval, keycode, state) => {
            if (keyval == 65307) {
                edit = false;
            } else {
                update_content_description ();
            }
        })] = content_controller_key;

        var checked_button_gesture = new Gtk.GestureClick ();
        checked_button.add_controller (checked_button_gesture);
        signals_map[checked_button_gesture.pressed.connect (() => {
            checked_button_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            checked_button.active = !checked_button.active;
            checked_toggled (checked_button.active);
        })] = checked_button_gesture;

        signals_map[hide_loading_button.clicked.connect (() => {
            edit = false;
        })] = hide_loading_button;

        signals_map[schedule_button.duedate_changed.connect (() => {
            update_due (schedule_button.duedate);
        })] = schedule_button;

        signals_map[priority_button.changed.connect ((priority) => {
            if (item.priority != priority) {
                item.priority = priority;

                if (item.project.source_type == SourceType.TODOIST ||
                    item.project.source_type == SourceType.CALDAV) {
                    item.update_async ("");
                } else {
                    item.update_local ();
                }
            }
        })] = priority_button;

        signals_map[pin_button.changed.connect (() => {
            item.update_pin (!item.pinned);
        })] = pin_button;

        signals_map[label_button.labels_changed.connect ((labels) => {
            update_labels (labels);
        })] = label_button;

        signals_map[
            Services.Settings.get_default ().settings.changed["underline-completed-tasks"].connect (update_request)
        ] = Services.Settings.get_default ();

        signals_map[
            Services.Settings.get_default ().settings.changed["clock-format"].connect (update_request)
        ] = Services.Settings.get_default ();

        var menu_handle_gesture = new Gtk.GestureClick ();
        menu_handle_gesture.set_button (3);
        itemrow_box.add_controller (menu_handle_gesture);
        signals_map[menu_handle_gesture.released.connect ((n_press, x, y) => {
            if (!item.project.is_deck) {
                build_handle_context_menu (x, y);
            }
        })] = menu_handle_gesture;

        var multiselect_gesture = new Gtk.GestureClick ();
        select_checkbutton.add_controller (multiselect_gesture);
        signals_map[multiselect_gesture.pressed.connect (() => {
            multiselect_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            select_checkbutton.active = !select_checkbutton.active;
            selected_toggled (select_checkbutton.active);
        })] = multiselect_gesture;

        signals_map[Services.EventBus.get_default ().show_multi_select.connect ((active) => {
            if (active) {
                select_revealer.reveal_child = true;
                checked_button.sensitive = false;
                labels_summary.reveal_child = false;
                disable_drag_and_drop ();
            } else {
                select_revealer.reveal_child = false;
                checked_button.sensitive = true;

                if (!edit) {
                    labels_summary.check_revealer ();
                }

                if (drag_enabled) {
                    build_drag_and_drop ();
                }

                select_checkbutton.active = false;
            }
        })] = Services.EventBus.get_default ();

        var add_subitem_gesture = new Gtk.GestureClick ();
        add_button.add_controller (add_subitem_gesture);
        signals_map[add_subitem_gesture.pressed.connect ((n_press, x, y) => {
            add_subitem_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            subitems.prepare_new_item ();
        })] = add_subitem_gesture;

        signals_map[item.loading_change.connect (() => {
            is_loading = item.loading;
        })] = item;

        signals_map[item.sensitive_change.connect (() => {
            sensitive = item.sensitive;
        })] = item;

        signals_map[hide_subtask_button.clicked.connect (() => {
            item.collapsed = !item.collapsed;
            item.update_local ();
        })] = hide_subtask_button;

        signals_map[show_subtasks_button.clicked.connect (() => {
            item.collapsed = !item.collapsed;
            item.update_local ();
        })] = show_subtasks_button;

        signals_map[subitems.children_changes.connect (() => {
            check_hide_subtask_button ();
        })] = subitems;

        signals_map[item.collapsed_change.connect (() => {
            subitems.reveal_child = item.collapsed;

            if (item.collapsed) {
                hide_subtask_button.add_css_class ("opened");
                show_subtasks_button.add_css_class ("opened");
            } else {
                hide_subtask_button.remove_css_class ("opened");
                show_subtasks_button.remove_css_class ("opened");
            }
        })] = item;

        signals_map[item.show_item_changed.connect (() => {
            main_revealer.reveal_child = item.show_item;
        })] = item;

        signals_map[reminder_button.reminder_added.connect ((reminder) => {
            item.add_reminder (reminder);
        })] = reminder_button;

        signals_map[item.reminder_added.connect ((reminder) => {
            reminder_button.add_reminder (reminder, item.reminders);
            check_reminders ();
        })] = item;

        signals_map[item.reminder_deleted.connect ((reminder) => {
            reminder_button.delete_reminder (reminder, item.reminders);
            check_reminders ();
        })] = item;

        signals_map[Services.EventBus.get_default ().drag_items_end.connect ((project_id) => {
            if (item.project_id == project_id) {
                motion_top_revealer.reveal_child = false;
            }
        })] = Services.EventBus.get_default ();

        signals_map[attachments.update_count.connect ((count) => {
            attachments_count.label = count <= 0 ? "" : count.to_string ();
            attachments_count.visible = count > 0;
        })] = attachments;

        signals_map[attachments.file_selector_opened.connect ((active) => {
            if (active) {
                attachments_button.popover.popdown ();
            }
        })] = attachments;
    }

    private void show_details () {
        if (Services.Settings.get_default ().settings.get_boolean ("open-task-sidebar")) {
            Services.EventBus.get_default ().open_item (item);
        } else {
            if (Services.Settings.get_default ().settings.get_boolean ("attention-at-one")) {
                Services.EventBus.get_default ().item_selected (item.id);
            } else {
                edit = true;
            }
        }
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

    public override void select_row (bool active) {
        if (active) {
            itemrow_box.add_css_class ("complete-animation");
        } else {
            itemrow_box.remove_css_class ("complete-animation");
        }
    }

    private void update_content_description () {
        if (item.content != content_textview.buffer.text) {
            item.content = content_textview.buffer.text;
            content_label.label = MarkdownProcessor.get_default ().markup_string (item.content);
            content_label.tooltip_text = item.content.strip ();
            item.update_async_timeout (update_id);
            return;
        }

        if (item.description != current_buffer.get_all_text ().chomp ()) {
            item.description = current_buffer.get_all_text ().chomp ();
            item.update_async_timeout (update_id);
            return;
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

        content_label.label = MarkdownProcessor.get_default ().markup_string (item.content);
        content_label.tooltip_text = item.content;
        content_textview.set_text (item.content);

        // ItemType
        if (item.item_type == ItemType.TASK) {
            checked_button_revealer.reveal_child = true;
            action_box.margin_start = 16;
            content_box.margin_start = 6;
        } else {
            checked_button_revealer.reveal_child = false;
            action_box.margin_start = 0;
            content_box.margin_start = 0;
        }

        if (markdown_edit_view != null) {
            markdown_edit_view.left_margin = item.item_type == ItemType.TASK ? 24 : 3;
        }

        // Update Description
        if (description_handler_change_id != 0) {
            current_buffer.disconnect (description_handler_change_id);
            description_handler_change_id = 0;
        }

        current_buffer.text = item.description;

        if (description_handler_change_id == 0) {
            description_handler_change_id = current_buffer.changed.connect (() => {
                update_content_description ();
            });
        }

        project_name_label.label = item.project.name;
        if (item.has_parent) {
            if (item.parent.has_parent) {
                project_name_label.label += " /…/ " + item.parent.content;
            } else {
                project_name_label.label += " / " + item.parent.content;
            }
        }
        project_name_label.tooltip_text = project_name_label.label;

        labels_summary.update_request ();
        label_button.labels = item._get_labels ();
        schedule_button.update_from_item (item);
        priority_button.update_from_item (item);
        pin_button.update_from_item (item);
        reminder_button.set_reminders (item.reminders);

        show_subtasks_label.label = item.collapsed ? _ ("Hide Sub-tasks") : _ ("Show Sub-tasks");

        check_due ();
        check_description ();
        check_reminders ();

        if (!edit) {
            labels_summary.check_revealer ();
        }

        if (edit) {
            content_textview.editable = !item.completed && !item.project.is_deck;
            markdown_edit_view.is_editable = !item.completed && !item.project.is_deck;
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
                Utils.Datetime.get_date_from_string (item.completed_at)
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
        clean_up ();

        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            var list_parent = (Gtk.ListBox) parent;
            list_parent.remove (this);
            return GLib.Source.REMOVE;
        });
    }


    private void build_handle_context_menu (double x, double y) {
        if (menu_handle_popover != null) {
            if (item.has_due) {
                no_date_item.visible = true;
            } else {
                no_date_item.visible = false;
            }

            pinboard_item.title = item.pinned ? _ ("Unpin") : _ ("Pin");

            menu_handle_popover.pointing_to = { ((int) x), (int) y, 1, 1 };
            menu_handle_popover.popup ();
            return;
        }

        var today_item = new Widgets.ContextMenu.MenuItem (_ ("Today"), "star-outline-thick-symbolic");
        today_item.secondary_text = new GLib.DateTime.now_local ().format ("%a");

        var tomorrow_item = new Widgets.ContextMenu.MenuItem (_ ("Tomorrow"), "month-symbolic");
        tomorrow_item.secondary_text = new GLib.DateTime.now_local ().add_days (1).format ("%a");

        pinboard_item = new Widgets.ContextMenu.MenuItem (item.pinned ? _ ("Unpin") : _ ("Pin"), "pin-symbolic");

        no_date_item = new Widgets.ContextMenu.MenuItem (_ ("No Date"), "cross-large-circle-filled-symbolic");
        no_date_item.visible = item.has_due;

        var move_item = new Widgets.ContextMenu.MenuItem (_ ("Move"), "arrow3-right-symbolic");

        var add_item = new Widgets.ContextMenu.MenuItem (_ ("Add Subtask"), "plus-large-symbolic");
        var complete_item = new Widgets.ContextMenu.MenuItem (_ ("Complete"), "check-round-outline-symbolic");
        var edit_item = new Widgets.ContextMenu.MenuItem (_ ("Edit"), "edit-symbolic");
        var duplicate_item = new Widgets.ContextMenu.MenuItem (_ ("Duplicate"), "tabs-stack-symbolic");

        var delete_item = new Widgets.ContextMenu.MenuItem (_ ("Delete Task"), "user-trash-symbolic");
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

        signals_map[move_item.activate_item.connect (() => {
            Dialogs.ProjectPicker.ProjectPicker dialog;
            if (item.project.is_inbox_project) {
                dialog = new Dialogs.ProjectPicker.ProjectPicker.for_projects ();
            } else {
                dialog = new Dialogs.ProjectPicker.ProjectPicker.for_project (item.source);
            }

            dialog.add_sections (item.project.sections);
            dialog.project = item.project;
            dialog.section = item.section;
            dialog.present (Planify._instance.main_window);

            dialog.changed.connect ((type, id) => {
                if (type == "project") {
                    move (Services.Store.instance ().get_project (id), "");
                } else {
                    move (item.project, id);
                }
            });
        })] = move_item;

        signals_map[today_item.activate_item.connect (() => {
            update_date (Utils.Datetime.get_date_only (new DateTime.now_local ()));
        })] = today_item;

        signals_map[tomorrow_item.activate_item.connect (() => {
            update_date (Utils.Datetime.get_date_only (new DateTime.now_local ().add_days (1)));
        })] = tomorrow_item;

        signals_map[pinboard_item.activate_item.connect (() => {
            item.update_pin (!item.pinned);
        })] = pinboard_item;

        signals_map[no_date_item.activate_item.connect (() => {
            schedule_button.reset ();
        })] = no_date_item;

        signals_map[complete_item.activate_item.connect (() => {
            checked_button.active = !checked_button.active;
            checked_toggled (checked_button.active);
        })] = complete_item;

        signals_map[edit_item.activate_item.connect (() => {
            Services.EventBus.get_default ().open_item (item);
        })] = edit_item;

        signals_map[delete_item.activate_item.connect (() => {
            delete_request ();
        })] = delete_item;

        signals_map[add_item.activate_item.connect (() => {
            var dialog = new Dialogs.QuickAdd ();
            dialog.for_base_object (item);
            dialog.present (Planify._instance.main_window);
        })] = add_item;

        signals_map[duplicate_item.clicked.connect (() => {
            Util.get_default ().duplicate_item.begin (item, item.project_id, item.section_id, item.parent_id);
        })] = duplicate_item;
    }

    private Gtk.Popover build_button_context_menu () {
        var use_note_item = new Widgets.ContextMenu.MenuSwitch (_ ("Use as a Note"), "paper-symbolic");
        use_note_item.active = item.item_type == ItemType.NOTE;

        var copy_clipboard_item = new Widgets.ContextMenu.MenuItem (_ ("Copy to Clipboard"), "clipboard-symbolic");
        var duplicate_item = new Widgets.ContextMenu.MenuItem (_ ("Duplicate"), "tabs-stack-symbolic");
        var move_item = new Widgets.ContextMenu.MenuItem (_ ("Move"), "arrow3-right-symbolic");

        var delete_item = new Widgets.ContextMenu.MenuItem (_ ("Delete Task"), "user-trash-symbolic");
        delete_item.add_css_class ("menu-item-danger");

        var more_information_item = new Widgets.ContextMenu.MenuItem (_ ("Change History"), "rotation-edit-symbolic");

        var popover = new Gtk.Popover () {
            has_arrow = false,
            position = Gtk.PositionType.BOTTOM,
            width_request = 250
        };

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;

        if (!item.completed) {
            menu_box.append (use_note_item);
            menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
            menu_box.append (copy_clipboard_item);
            menu_box.append (duplicate_item);
            menu_box.append (move_item);

            signals_map[use_note_item.activate_item.connect (() => {
                item.item_type = use_note_item.active ? ItemType.NOTE : ItemType.TASK;
                item.update_local ();
            })] = use_note_item;

            signals_map[copy_clipboard_item.clicked.connect (() => {
                item.copy_clipboard ();
            })] = copy_clipboard_item;

            signals_map[duplicate_item.clicked.connect (() => {
                Util.get_default ().duplicate_item.begin (item, item.project_id, item.section_id, item.parent_id);
            })] = duplicate_item;

            signals_map[move_item.clicked.connect (() => {
                Dialogs.ProjectPicker.ProjectPicker dialog;
                if (item.project.is_inbox_project) {
                    dialog = new Dialogs.ProjectPicker.ProjectPicker.for_projects ();
                } else {
                    dialog = new Dialogs.ProjectPicker.ProjectPicker.for_project (item.source);
                }

                dialog.project = item.project;
                dialog.section = item.section;
                dialog.present (Planify._instance.main_window);

                dialog.changed.connect ((type, id) => {
                    if (type == "project") {
                        move (Services.Store.instance ().get_project (id), "");
                    } else {
                        move (item.project, id);
                    }
                });
            })] = move_item;
        }

        menu_box.append (delete_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (more_information_item);

        popover.child = menu_box;

         signals_map[delete_item.activate_item.connect (() => {
            delete_request ();
        })] = delete_item;

        signals_map[more_information_item.activate_item.connect (() => {
            var dialog = new Dialogs.ItemChangeHistory (item);
            dialog.present (Planify._instance.main_window);
        })] = more_information_item;

        return popover;
    }

    public override void checked_toggled (bool active, uint ? time = null) {
        bool old_checked = item.checked;

        if (active) {
            complete_item (old_checked, time);
        } else {
            if (complete_timeout != 0) {
                GLib.Source.remove (complete_timeout);
                complete_timeout = 0;
                itemrow_box.remove_css_class ("complete-animation");
                content_label.remove_css_class ("dimmed");
                content_label.remove_css_class ("line-through");
            } else {
                var old_completed_at = item.completed_at;

                item.checked = false;
                item.completed_at = "";
                _complete_item.begin (old_checked, old_completed_at);
            }
        }
    }

    private void complete_item (bool old_checked, uint ? time = null) {
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
            content_label.add_css_class ("dimmed");
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
                var old_completed_at = item.completed_at;

                item.checked = true;
                item.completed_at = new GLib.DateTime.now_local ().to_string ();
                _complete_item.begin (old_checked, old_completed_at);
            }

            return GLib.Source.REMOVE;
        });
    }

    private async void _complete_item (bool old_checked, string old_completed_at) {
        checked_button.sensitive = false;
        subitems.sensitive = false;

        HttpResponse response = yield item.complete_item (old_checked);

        if (!response.status) {
            _complete_item_error (response, old_checked, old_completed_at);
        }
    }

    private void _complete_item_error (HttpResponse response, bool old_checked, string old_completed_at) {
        item.checked = old_checked;
        item.completed_at = old_completed_at;

        is_loading = false;
        checked_button.sensitive = true;
        checked_button.active = false;
        subitems.sensitive = true;

        itemrow_box.remove_css_class ("complete-animation");
        content_label.remove_css_class ("dimmed");
        content_label.remove_css_class ("line-through");

        Services.EventBus.get_default ().send_error_toast (response.error_code, response.error);
    }

    public void update_content (string content = "") {
        content_textview.buffer.text = content;
    }

    public void update_priority (int priority) {
        item.priority = priority;
        item.update_async ("");
    }

    public void update_due (Objects.DueDate duedate) {
        item.update_due (duedate);
    }

    public void update_date (GLib.DateTime ? date) {
        item.update_date (date);
    }

    private void update_next_recurrency () {
        var promise = new Services.Promise<GLib.DateTime> ();

        signals_map[promise.resolved.connect ((result) => {
            recurrency_update_complete (result);
        })] = promise;

        item.update_next_recurrency (promise);
    }

    private void recurrency_update_complete (GLib.DateTime next_recurrency) {
        checked_button.active = false;
        complete_timeout = 0;
        itemrow_box.remove_css_class ("complete-animation");
        content_label.remove_css_class ("dimmed");
        content_label.remove_css_class ("line-through");

        var title = _ ("Completed. Next occurrence: %s".printf (
                           Utils.Datetime.get_default_date_format_from_date (next_recurrency)
        ));
        var toast = Util.get_default ().create_toast (title, 3);
        Services.EventBus.get_default ().send_toast (toast);
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
        var toast = new Adw.Toast (_ ("%s was deleted".printf (Util.get_default ().get_short_name (item.content))));
        toast.button_label = _ ("Undo");
        toast.priority = Adw.ToastPriority.HIGH;
        toast.timeout = 3;

        Services.EventBus.get_default ().send_toast (toast);

        signals_map[toast.dismissed.connect (() => {
            if (!main_revealer.reveal_child) {
                item.delete_item ();
            }
        })] = toast;

        signals_map[toast.button_clicked.connect (() => {
            main_revealer.reveal_child = true;
        })] = toast;
    }

    public void move (Objects.Project project, string section_id) {
        string project_id = project.id;

        if (item.project.source_id != project.source_id) {
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

        dnd_handlerses[drop_motion_ctrl.enter.connect ((x, y) => {
            var drop = drop_motion_ctrl.get_drop ();
            GLib.Value value = Value (typeof (Gtk.Widget));

            try {
                drop.drag.content.get_value (ref value);

                if (value.dup_object () is Layouts.ItemRow) {
                    var picked_widget = (Layouts.ItemBoard) value;

                    if (picked_widget.item.id == item.parent_id) {
                        return;
                    }

                    motion_top_grid.height_request = picked_widget.handle_grid.get_height ();
                    motion_top_revealer.reveal_child = drop_motion_ctrl.contains_pointer;
                } else if (value.dup_object () is Widgets.MagicButton) {
                    motion_top_grid.height_request = 30;
                    motion_top_revealer.reveal_child = drop_motion_ctrl.contains_pointer;
                }
            } catch (Error e) {
                debug (e.message);
            }
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

            Services.EventBus.get_default ().drag_items_end (item.project_id);
            Services.EventBus.get_default ().drag_n_drop_active (item.project_id, false);

            if (picked_widget == target_widget || target_widget == null) {
                return false;
            }

            string old_parent_id = picked_item.parent_id;
            string old_project_id = picked_item.project_id;
            string old_section_id = picked_item.section_id;

            picked_item.section_id = "";
            picked_item.parent_id = target_item.id;

            if (picked_item.project.source_type == SourceType.LOCAL) {
                target_item.collapsed = true;
                Services.Store.instance ().update_item (picked_item);
                Services.EventBus.get_default ().item_moved (picked_item, old_project_id, old_section_id, old_parent_id);
            } else if (picked_item.project.source_type == SourceType.TODOIST) {
                Services.Todoist.get_default ().move_item.begin (picked_item, "parent_id", picked_item.parent_id, (obj, res) => {
                    if (Services.Todoist.get_default ().move_item.end (res).status) {
                        target_item.collapsed = true;
                        Services.Store.instance ().update_item (picked_widget.item);
                        Services.EventBus.get_default ().item_moved (picked_item, old_project_id, old_section_id, old_parent_id);
                    }
                });
            } else if (picked_item.project.source_type == SourceType.CALDAV) {
                var caldav_client = Services.CalDAV.Core.get_default ().get_client (picked_item.project.source);
                caldav_client.add_item.begin (picked_item, true, (obj, res) => {
                    if (caldav_client.add_item.end (res).status) {
                        target_item.collapsed = true;
                        Services.Store.instance ().update_item (picked_widget.item);
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
            dialog.present (Planify._instance.main_window);

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

            dialog.present (Planify._instance.main_window);
            return true;
        })] = drop_order_magic_button_target;
    }

    private void build_drop_order_target () {
        drop_order_target = new Gtk.DropTarget (typeof (Layouts.ItemRow), Gdk.DragAction.MOVE);
        motion_top_grid.add_controller (drop_order_target);
        dnd_handlerses[drop_order_target.drop.connect ((value, x, y) => {
            var picked_widget = (Layouts.ItemRow) value;
            var target_widget = this;
            var old_project_id = "";
            var old_section_id = "";
            var old_parent_id = "";

            picked_widget.drag_end ();
            target_widget.drag_end ();

            Services.EventBus.get_default ().drag_items_end (item.project_id);

            if (picked_widget == target_widget || target_widget == null) {
                return false;
            }

            if (item.project.sort_order != 0) {
                item.project.sort_order = 0;
                Services.EventBus.get_default ().send_toast (
                    Util.get_default ().create_toast (_ ("Order changed to 'Custom sort order'"))
                );
                item.project.update_local ();
            }

            old_project_id = picked_widget.item.project_id;
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

                if (picked_widget.item.project.source_type == SourceType.LOCAL) {
                    Services.Store.instance ().move_item (picked_widget.item, old_project_id, old_section_id, old_parent_id);
                } else if (picked_widget.item.project.source_type == SourceType.TODOIST) {
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
                            Services.Store.instance ().move_item (picked_widget.item, old_project_id, old_section_id, old_parent_id);
                        }
                    });
                } else if (picked_widget.item.project.source_type == SourceType.CALDAV) {
                    var caldav_client = Services.CalDAV.Core.get_default ().get_client (picked_widget.item.project.source);
                    caldav_client.add_item.begin (picked_widget.item, true, (obj, res) => {
                        if (caldav_client.add_item.end (res).status) {
                            Services.Store.instance ().move_item (picked_widget.item, old_project_id, old_section_id, old_parent_id);
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
        subitems.disable_drag_and_drop ();
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

        dnd_handlerses.clear ();
    }

    public void drag_begin () {
        itemrow_box.add_css_class ("drop-begin");
        main_revealer.reveal_child = false;
        Services.EventBus.get_default ().drag_n_drop_active (item.project_id, true);
    }

    public void drag_end () {
        itemrow_box.remove_css_class ("drop-begin");
        main_revealer.reveal_child = item.show_item;
        Services.EventBus.get_default ().drag_n_drop_active (item.project_id, false);
    }

    private void update_items_item_order (Gtk.ListBox listbox) {
        unowned Layouts.ItemRow ? item_row = null;
        var row_index = 0;

        do {
            item_row = (Layouts.ItemRow) listbox.get_row_at_index (row_index);

            if (item_row != null) {
                item_row.item.child_order = row_index;
                Services.Store.instance ().update_item (item_row.item);
            }

            row_index++;
        } while (item_row != null);
    }

    private void build_markdown_edit_view () {
        if (markdown_edit_view != null) {
            return;
        }

        markdown_edit_view = new Widgets.Markdown.EditView () {
            left_margin = item.item_type == ItemType.TASK ? 24 : 3,
            right_margin = 6,
            top_margin = 3,
            bottom_margin = 12,
            is_editable = !item.completed && !item.project.is_deck
        };

        markdown_edit_view.buffer = current_buffer;

        markdown_revealer.child = markdown_edit_view;
        markdown_revealer.reveal_child = true;

        var description_gesture_click = new Gtk.GestureClick ();
        markdown_edit_view.add_controller (description_gesture_click);
        signals_map[description_gesture_click.released.connect ((n_press, x, y) => {
            description_gesture_click.set_state (Gtk.EventSequenceState.CLAIMED);
            markdown_edit_view.view_focus ();
        })] = description_gesture_click;

        signals_map[markdown_edit_view.escape.connect (() => {
            edit = false;
        })] = markdown_edit_view;
    }

    private void destroy_markdown_edit_view () {
        markdown_revealer.reveal_child = false;
        Timeout.add (markdown_revealer.transition_duration, () => {
            markdown_revealer.child = null;
            markdown_edit_view = null;
            return GLib.Source.REMOVE;
        });
    }

    public void clean_up () {
        if (menu_handle_popover != null) {
            menu_handle_popover.unparent ();
            menu_handle_popover = null;
        }

        foreach (var entry in signals_map.entries) {
            if (SignalHandler.is_connected (entry.value, entry.key)) {
                entry.value.disconnect (entry.key);
            }
        }

        signals_map.clear ();

        foreach (var entry in dnd_handlerses.entries) {
            if (SignalHandler.is_connected (entry.value, entry.key)) {
                entry.value.disconnect (entry.key);
            }
        }
        
        dnd_handlerses.clear ();

        if (description_handler_change_id != 0) {
            current_buffer.disconnect (description_handler_change_id);
            description_handler_change_id = 0;
        }

        subitems.clean_up ();
        attachments.clean_up ();
        
        current_buffer = null;
        markdown_edit_view = null;
    }
}

