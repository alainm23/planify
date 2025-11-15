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

public class Layouts.ItemBoard : Layouts.ItemBase {
    private Gtk.Grid motion_top_grid;
    private Gtk.Revealer motion_top_revealer;

    private Gtk.CheckButton checked_button;
    private Gtk.Revealer checked_button_revealer;
    private Gtk.Label content_label;
    private Gtk.Box content_box;

    private Widgets.LoadingButton hide_loading_button;
    private Gtk.Revealer hide_loading_revealer;

    private Gtk.Label description_label;
    private Gtk.Revealer description_revealer;

    private Gtk.Label due_label;
    private Gtk.Box due_box;
    private Gtk.Label repeat_label;
    private Gtk.Revealer repeat_revealer;
    private Gtk.Revealer due_box_revealer;
    private Widgets.LabelsSummary labels_summary;
    private Gtk.Revealer reminder_revealer;
    private Gtk.Label reminder_count;
    private Gtk.Label subtaks_label;
    private Gtk.Revealer subtaks_revealer;
    private Gtk.Revealer footer_revealer;

    public Gtk.Box handle_grid;
    public Adw.Bin card_widget;
    public Gtk.Box footer_box;
    private Gtk.Popover menu_handle_popover = null;
    private Widgets.ContextMenu.MenuItem no_date_item;
    private Widgets.ContextMenu.MenuItem pinboard_item;
    private Gtk.Revealer main_revealer;

    private Gtk.CheckButton select_checkbutton;
    private Gtk.Revealer select_revealer;

    public uint complete_timeout { get; set; default = 0; }

    private bool _is_loading;
    public bool is_loading {
        set {
            _is_loading = value;
            
            hide_loading_button.is_loading = _is_loading;
            set_loading_state (_is_loading);
        }

        get {
            return _is_loading;
        }
    }

    private bool _pin_mode = false;
    public bool pin_mode {
        get {
            return _pin_mode;
        }
        set {
            _pin_mode = value;

            if (_pin_mode) {
                hide_loading_revealer.reveal_child = true;
                card_widget.margin_end = 6;
                card_widget.margin_top = 6;
                handle_grid.width_request = 200;
                hide_loading_button.margin_end = 0;
                hide_loading_button.margin_top = 0;
            } else {
                card_widget.margin_end = 0;
                card_widget.margin_top = 0;
                handle_grid.width_request = -1;
                hide_loading_button.margin_end = 6;
                hide_loading_button.margin_top = 6;
            }
        }
}


    public bool on_drag = false;

    public ItemBoard (Objects.Item item) {
        Object (
            item: item
        );
    }

    ~ItemBoard () {
        debug ("Destroying - Layouts.ItemBoard - %s\n".printf (item.content));
    }

    construct {
        add_css_class ("br-12");
        add_css_class ("row");
        add_css_class ("no-padding");

        motion_top_grid = new Gtk.Grid () {
            css_classes = { "drop-area", "drop-target" },
            margin_bottom = 3
        };

        motion_top_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = motion_top_grid
        };

        checked_button = new Gtk.CheckButton () {
            valign = Gtk.Align.START,
            css_classes = { "priority-color" }
        };

        checked_button_revealer = new Gtk.Revealer () {
            child = checked_button,
            transition_type = SLIDE_RIGHT,
            reveal_child = true
        };

        content_label = new Gtk.Label (item.content) {
            wrap = true,
            hexpand = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
            xalign = 0,
            yalign = 0,
            use_markup = true
        };

        hide_loading_button = new Widgets.LoadingButton.with_icon ("window-close", 16) {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            tooltip_text = _ ("Unpin"),
            css_classes = { "min-height-0", "view-button" },
            margin_end = 6,
            margin_top = 6
        };

        hide_loading_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            valign = Gtk.Align.START,
            halign = Gtk.Align.END,
            vexpand = true,
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

        content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 6,
            margin_start = 6,
            margin_end = 6
        };

        content_box.add_css_class ("transition");
        content_box.append (checked_button_revealer);
        content_box.append (content_label);
        content_box.append (select_revealer);

        description_label = new Gtk.Label (null) {
            xalign = 0,
            lines = 1,
            ellipsize = Pango.EllipsizeMode.END,
            margin_start = 30,
            margin_end = 6,
            css_classes = { "dimmed", "caption", "transition" }
        };
        
        description_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = description_label
        };

        // Due Label
        due_label = new Gtk.Label (null) {
            valign = Gtk.Align.CENTER,
            css_classes = { "caption" }
        };

        var repeat_image = new Gtk.Image.from_icon_name ("playlist-repeat-symbolic") {
            pixel_size = 12,
            margin_top = 3
        };

        repeat_label = new Gtk.Label (null) {
            valign = Gtk.Align.CENTER,
            css_classes = { "caption" },
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
            valign = CENTER,
            margin_end = 6
        };
        due_box.append (due_label);
        due_box.append (repeat_revealer);

        due_box_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = due_box
        };

        labels_summary = new Widgets.LabelsSummary (item, 1, true) {
            end_margin = 6
        };

        var reminder_icon = new Gtk.Image.from_icon_name ("alarm-symbolic") {
            pixel_size = 12
        };

        reminder_count = new Gtk.Label (item.reminders.size.to_string ());
        reminder_count.add_css_class ("caption");

        var reminder_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3) {
            valign = Gtk.Align.CENTER,
            margin_end = 6
        };
        reminder_box.add_css_class ("upcoming-grid");

        reminder_box.append (reminder_icon);
        reminder_box.append (reminder_count);

        reminder_revealer = new Gtk.Revealer () {
            transition_type = SLIDE_RIGHT,
            child = reminder_box
        };

        subtaks_label = new Gtk.Label (null);
        subtaks_label.add_css_class ("caption");

        var subtaks_container = new Adw.Bin () {
            child = subtaks_label
        };
        subtaks_container.add_css_class ("upcoming-grid");

        subtaks_revealer = new Gtk.Revealer () {
            transition_type = SLIDE_RIGHT,
            child = subtaks_container
        };

        footer_box = new Gtk.Box (HORIZONTAL, 0) {
            hexpand = true,
            margin_start = 30,
            margin_top = 3,
            margin_end = 6
        };

        footer_box.append (due_box_revealer);
        footer_box.append (labels_summary);
        footer_box.append (reminder_revealer);
        footer_box.append (subtaks_revealer);

        footer_revealer = new Gtk.Revealer () {
            transition_type = SLIDE_DOWN,
            child = footer_box
        };

        handle_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        handle_grid.append (content_box);
        handle_grid.append (description_revealer);
        handle_grid.append (footer_revealer);

        card_widget = new Adw.Bin () {
            margin_top = 3,
            margin_end = 3,
            margin_bottom = 3,
            child = handle_grid
        };

        card_widget.add_css_class ("card");
        card_widget.add_css_class ("border-radius-9");
        card_widget.add_css_class ("pb-6");
        card_widget.add_css_class ("activatable");
        card_widget.add_css_class ("task-item");

        var overlay = new Gtk.Overlay ();
        overlay.child = card_widget;
        overlay.add_overlay (hide_loading_revealer);

        var v_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 3
        };
        v_box.append (motion_top_revealer);
        v_box.append (overlay);

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vscrollbar_policy = Gtk.PolicyType.NEVER,
            child = v_box
        };

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = scrolled_window
        };

        child = main_revealer;
        update_request ();

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        update_request ();

        if (!item.pinned && !item.checked) {
            build_drag_and_drop ();
        }

        var checked_button_gesture = new Gtk.GestureClick ();
        checked_button.add_controller (checked_button_gesture);
        signals_map[checked_button_gesture.pressed.connect (() => {
            checked_button_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            checked_button.active = !checked_button.active;
            checked_toggled (checked_button.active);
        })] = checked_button_gesture;

        var select_button_gesture = new Gtk.GestureClick ();
        select_checkbutton.add_controller (select_button_gesture);
        signals_map[select_button_gesture.pressed.connect (() => {
            select_button_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            select_checkbutton.active = !select_checkbutton.active;
            selected_toggled (select_checkbutton.active);
        })] = select_button_gesture;

        var detail_gesture_click = new Gtk.GestureClick ();
        card_widget.add_controller (detail_gesture_click);
        signals_map[detail_gesture_click.released.connect ((n_press, x, y) => {
            if (Services.EventBus.get_default ().ctrl_key_pressed) {
                Idle.add (() => {
                    if (item.project == null) {
                        return GLib.Source.REMOVE;
                    }
                    
                    if (!Services.EventBus.get_default ().multi_select_enabled) {
                        item.project.show_multi_select = true;
                    }
                    
                    select_checkbutton.active = !select_checkbutton.active;
                    selected_toggled (select_checkbutton.active);
                    
                    return GLib.Source.REMOVE;
                });
                
                return;
            }
            
            if (Services.EventBus.get_default ().multi_select_enabled) {
                select_checkbutton.active = !select_checkbutton.active;
                selected_toggled (select_checkbutton.active);
            } else {
                if (!on_drag) {
                    open_detail ();
                }
            }
        })] = detail_gesture_click;

        var menu_handle_gesture = new Gtk.GestureClick ();
        menu_handle_gesture.set_button (3);
        card_widget.add_controller (menu_handle_gesture);
        signals_map[menu_handle_gesture.pressed.connect ((n_press, x, y) => {
            if (!item.completed) {
                build_handle_context_menu (x, y);
            }
        })] = menu_handle_gesture;

        signals_map[item.reminder_added.connect (() => {
            update_request ();
        })] = item;

        signals_map[item.reminder_deleted.connect (() => {
            update_request ();
        })] = item;

        signals_map[item.item_added.connect (() => {
            update_request ();
        })] = item;

        signals_map[item.updated.connect ((_item, _update_id) => {
            if (item.id == _item.id && update_id != _update_id) {
                update_request ();
            }
        })] = item;

        signals_map[Services.Store.instance ().item_deleted.connect ((_item) => {
            if (item.id == _item.parent_id) {
                update_request ();
            }
        })] = Services.Store.instance ();

        signals_map[Services.EventBus.get_default ().item_moved.connect ((_item, old_project_id, old_section_id, old_parent_id) => {
            if (item.id == old_parent_id) {
                update_request ();
            }

            if (item.id == _item.parent_id) {
                update_request ();
            }
        })] = Services.EventBus.get_default ();

        signals_map[Services.EventBus.get_default ().checked_toggled.connect ((_item) => {
            if (item.id == _item.parent_id) {
                update_request ();
            }
        })] = Services.EventBus.get_default ();

        signals_map[Services.EventBus.get_default ().show_multi_select.connect ((active) => {
            if (active) {
                select_revealer.reveal_child = true;
                checked_button.sensitive = false;
            } else {
                select_revealer.reveal_child = false;
                checked_button.sensitive = true;
                select_checkbutton.active = false;
            }
        })] = Services.EventBus.get_default ();

        signals_map[item.show_item_changed.connect (() => {
            main_revealer.reveal_child = item.show_item;
        })] = item;

        signals_map[item.loading_change.connect (() => {
            is_loading = item.loading;
        })] = item;

        signals_map[item.sensitive_change.connect (() => {
            sensitive = item.sensitive;
        })] = item;

        signals_map[Services.EventBus.get_default ().drag_items_end.connect ((project_id) => {
            if (item.project_id == project_id) {
                motion_top_revealer.reveal_child = false;
            }
        })] = Services.EventBus.get_default ();

        signals_map[hide_loading_button.clicked.connect (() => {
            item.update_pin (false);
        })] = hide_loading_button;

        signals_map[Services.EventBus.get_default ().day_changed.connect (() => {
            update_due_label ();
        })] = Services.EventBus.get_default ();

        signals_map[activate.connect (() => {
            open_detail ();
        })] = this;
    }

    private void update_next_recurrency () {
        var promise = new Services.Promise<GLib.DateTime> ();

        promise.resolved.connect ((result) => {
            recurrency_update_complete (result);
        });

        item.update_next_recurrency (promise);
    }

    private void open_detail () {
        Services.EventBus.get_default ().open_item (item);
    }

    public override void checked_toggled (bool active, uint ? time = null) {
        bool old_checked = item.checked;

        if (active) {
            complete_item (old_checked, time);
        } else {
            if (complete_timeout != 0) {
                GLib.Source.remove (complete_timeout);
                complete_timeout = 0;
                card_widget.remove_css_class ("complete");
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

        uint timeout = 3000;
        if (Services.Settings.get_default ().settings.get_enum ("complete-task") == 0) {
            timeout = 0;
        }

        if (time != null) {
            timeout = time;
        }

        content_label.add_css_class ("dimmed");
        card_widget.add_css_class ("complete");
        if (Services.Settings.get_default ().settings.get_boolean ("underline-completed-tasks")) {
            content_label.add_css_class ("line-through");
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
        
        HttpResponse response = yield item.complete_item (old_checked);

        if (response.status) {
            _show_task_completed_toast ();
        } else {
            _complete_item_error (response, old_checked, old_completed_at);
        }
    }

    private void _complete_item_error (HttpResponse response, bool old_checked, string old_completed_at) {
        item.checked = old_checked;
        item.completed_at = old_completed_at;

        is_loading = false;
        checked_button.sensitive = true;
        checked_button.active = false;

        card_widget.remove_css_class ("complete");
        content_label.remove_css_class ("dimmed");
        content_label.remove_css_class ("line-through");

        Services.EventBus.get_default ().send_error_toast (response.error_code, response.error);
    }

    private void recurrency_update_complete (GLib.DateTime next_recurrency) {
        checked_button.active = false;
        complete_timeout = 0;

        var title = _ ("Completed. Next occurrence: %s".printf (Utils.Datetime.get_default_date_format_from_date (next_recurrency)));
        var toast = Util.get_default ().create_toast (title, 3);

        Services.EventBus.get_default ().send_toast (toast);
    }

    public override void update_request () {
        if (complete_timeout <= 0) {
            Util.get_default ().set_widget_priority (item.priority, checked_button);
            checked_button.active = item.completed;
        }

        content_label.label = MarkdownProcessor.get_default ().markup_string (item.content);
        content_label.tooltip_text = item.content.strip ();

        // ItemType
        verify_item_type ();

        description_label.label = Util.get_default ().line_break_to_space (item.description);
        description_label.tooltip_text = item.description.strip ();
        description_revealer.reveal_child = description_label.label.length > 0;

        update_due_label ();
        labels_summary.update_request ();
        labels_summary.check_revealer ();
        reminder_count.label = item.reminders.size.to_string ();
        reminder_revealer.reveal_child = item.reminders.size > 0;
        update_subtasks ();
        footer_revealer.reveal_child = due_box_revealer.reveal_child || labels_summary.reveal_child ||
                                       reminder_revealer.reveal_child || subtaks_revealer.reveal_child;
    }

    private void verify_item_type () {
        if (item.item_type == ItemType.TASK) {
            checked_button_revealer.reveal_child = true;
            description_label.margin_start = 30;
            footer_box.margin_start = 30;
            content_box.margin_start = 6;
        } else {
            checked_button_revealer.reveal_child = false;
            description_label.margin_start = 9;
            footer_box.margin_start = 9;
            content_box.margin_start = 3;
        }
    }

    public void update_due_label () {
        due_box.remove_css_class ("overdue-grid");
        due_box.remove_css_class ("today-grid");
        due_box.remove_css_class ("upcoming-grid");

        if (item.completed) {
            due_label.label = Utils.Datetime.get_relative_date_from_date (
                Utils.Datetime.get_date_only (
                    Utils.Datetime.get_date_from_string (item.completed_at)
                )
            );
            due_box.add_css_class ("completed-grid");
            due_box_revealer.reveal_child = true;
            return;
        }

        if (item.has_due) {
            due_label.label = Utils.Datetime.get_relative_date_from_date (item.due.datetime);
            due_box_revealer.reveal_child = true;

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

    private void update_subtasks () {
        subtaks_revealer.reveal_child = item.items.size > 0;
        int checked = 0;
        foreach (Objects.Item item in item.items) {
            if (item.checked) {
                checked++;
            }
        }
        subtaks_label.label = "%d/%d".printf (checked, item.items.size);
    }

    private void build_handle_context_menu (double x, double y) {
        if (menu_handle_popover != null) {
            if (item.has_due) {
                no_date_item.visible = true;
            } else {
                no_date_item.visible = false;
            }

            pinboard_item.title = item.pinned ? _ ("Unpin") : _ ("Pin");

            menu_handle_popover.pointing_to = { (int) x, (int) y, 1, 1 };
            menu_handle_popover.popup ();
            return;
        }

        var today_item = new Widgets.ContextMenu.MenuItem (_ ("Today"), "star-outline-thick-symbolic");
        today_item.secondary_text = new GLib.DateTime.now_local ().format ("%a");

        var tomorrow_item = new Widgets.ContextMenu.MenuItem (_ ("Tomorrow"), "today-calendar-symbolic");
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
        menu_box.append (delete_item);

        menu_handle_popover = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            halign = Gtk.Align.START,
            width_request = 250
        };

        menu_handle_popover.set_parent (this);
        menu_handle_popover.pointing_to = { (int) x, (int) y, 1, 1 };
        menu_handle_popover.popup ();

        move_item.activate_item.connect (() => {
            Dialogs.ProjectPicker.ProjectPicker dialog;
            if (item.project.is_inbox_project) {
                dialog = new Dialogs.ProjectPicker.ProjectPicker.for_projects ();
            } else {
                dialog = new Dialogs.ProjectPicker.ProjectPicker.for_project (item.source);
            }

            dialog.project = item.project;
            dialog.present (Planify._instance.main_window);

            dialog.changed.connect ((type, id) => {
                if (type == "project") {
                    move (Services.Store.instance ().get_project (id), "");
                } else {
                    move (item.project, id);
                }
            });
        });

        today_item.activate_item.connect (() => {
            update_date (Utils.Datetime.get_date_only (new DateTime.now_local ()));
        });

        tomorrow_item.activate_item.connect (() => {
            update_date (Utils.Datetime.get_date_only (new DateTime.now_local ().add_days (1)));
        });

        pinboard_item.activate_item.connect (() => {
            item.update_pin (!item.pinned);
        });

        no_date_item.activate_item.connect (() => {
            update_date (null);
        });

        complete_item.activate_item.connect (() => {
            checked_button.active = !checked_button.active;
            checked_toggled (checked_button.active);
        });

        edit_item.activate_item.connect (() => {
            open_detail ();
        });

        delete_item.activate_item.connect (() => {
            delete_request ();
        });

        add_item.activate_item.connect (() => {
            var dialog = new Dialogs.QuickAdd ();
            dialog.for_base_object (item);
            dialog.present (Planify._instance.main_window);
        });

        duplicate_item.clicked.connect (() => {
            Util.get_default ().duplicate_item.begin (item, item.project_id, item.section_id, item.parent_id);
        });
    }

    private void build_drag_and_drop () {
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
        var drop_motion_ctrl = new Gtk.DropControllerMotion ();
        add_controller (drop_motion_ctrl);

        signals_map[drop_motion_ctrl.enter.connect ((x, y) => {
            var drop = drop_motion_ctrl.get_drop ();
            GLib.Value value = Value (typeof (Gtk.Widget));

            try {
                drop.drag.content.get_value (ref value);

                if (value.dup_object () is Layouts.ItemBoard) {
                    var picked_widget = (Layouts.ItemBoard) value;

                    if (picked_widget.item.id == item.parent_id) {
                        return;
                    }

                    motion_top_grid.height_request = picked_widget.card_widget.get_height ();
                    motion_top_revealer.reveal_child = drop_motion_ctrl.contains_pointer && item.project.sorted_by == SortedByType.MANUAL;
                } else if (value.dup_object () is Widgets.MagicButton) {
                    motion_top_grid.height_request = 32;
                    motion_top_revealer.reveal_child = drop_motion_ctrl.contains_pointer && item.project.sorted_by == SortedByType.MANUAL;
                }
            } catch (Error e) {
                debug (e.message);
            }
        })] = drop_motion_ctrl;

        signals_map[drop_motion_ctrl.leave.connect (() => {
            motion_top_revealer.reveal_child = false;
        })] = drop_motion_ctrl;
    }

    private void build_drag_source () {
        var drag_source = new Gtk.DragSource ();
        drag_source.set_actions (Gdk.DragAction.MOVE);
        card_widget.add_controller (drag_source);

        signals_map[drag_source.prepare.connect ((source, x, y) => {
            return new Gdk.ContentProvider.for_value (this);
        })] = drag_source;

        signals_map[drag_source.drag_begin.connect ((source, drag) => {
            var paintable = new Gtk.WidgetPaintable (card_widget);
            source.set_icon (paintable, 0, 0);
            drag_begin ();
        })] = drag_source;

        signals_map[drag_source.drag_end.connect ((source, drag, delete_data) => {
            drag_end ();
        })] = drag_source;

        signals_map[drag_source.drag_cancel.connect ((source, drag, reason) => {
            drag_end ();
            return false;
        })] = drag_source;
    }

    private void build_drop_target () {
        var drop_target = new Gtk.DropTarget (typeof (Layouts.ItemBoard), Gdk.DragAction.MOVE);
        card_widget.add_controller (drop_target);

        signals_map[drop_target.accept.connect ((drop) => {
            GLib.Value value = Value (typeof (Gtk.Widget));

            try {
                drop.drag.content.get_value (ref value);
            } catch (Error e) {
                debug (e.message);
            }

            if (value.dup_object () is Layouts.ItemBoard) {
                var picked_widget = (Layouts.ItemBoard) value;
                if (picked_widget.item.id != item.parent_id) {
                    return true;
                }
            }

            return false;
        })] = drop_target;

        signals_map[drop_target.drop.connect ((value, x, y) => {
            var picked_widget = (Layouts.ItemBase) value;
            var target_widget = this;

            var picked_item = picked_widget.item;
            var target_item = target_widget.item;

            Services.EventBus.get_default ().drag_items_end (item.project_id);

            if (picked_widget == target_widget || target_widget == null) {
                return false;
            }

            string old_parent_id = picked_item.parent_id;
            string old_project_id = picked_item.project_id;
            string old_section_id = picked_item.section_id;

            picked_item.section_id = "";
            picked_item.parent_id = target_item.id;

            if (picked_item.project.source_type == SourceType.LOCAL) {
                Services.Store.instance ().update_item (picked_item);
                Services.EventBus.get_default ().item_moved (picked_item, old_project_id, old_section_id, old_parent_id);
            } else if (picked_item.project.source_type == SourceType.TODOIST) {
                Services.Todoist.get_default ().move_item.begin (picked_item, "parent_id", picked_item.parent_id, (obj, res) => {
                    if (Services.Todoist.get_default ().move_item.end (res).status) {
                        Services.Store.instance ().update_item (picked_widget.item);
                        Services.EventBus.get_default ().item_moved (picked_item, old_project_id, old_section_id, old_parent_id);
                    }
                });
            } else if (picked_item.project.source_type == SourceType.CALDAV) {
                var caldav_client = Services.CalDAV.Core.get_default ().get_client (picked_item.project.source);
                caldav_client.add_item.begin (picked_item, true, (obj, res) => {
                    if (caldav_client.add_item.end (res).status) {
                        Services.Store.instance ().update_item (picked_widget.item);
                        Services.EventBus.get_default ().item_moved (picked_item, old_project_id, old_section_id, old_parent_id);
                    }
                });
            }

            return true;
        })] = drop_target;
    }

    private void build_drop_magic_button_target () {
        var drop_magic_button_target = new Gtk.DropTarget (typeof (Widgets.MagicButton), Gdk.DragAction.MOVE);
        card_widget.add_controller (drop_magic_button_target);

        signals_map[drop_magic_button_target.drop.connect ((value, x, y) => {
            var dialog = new Dialogs.QuickAdd ();
            dialog.for_base_object (item);
            dialog.present (Planify._instance.main_window);

            return true;
        })] = drop_magic_button_target;

        var drop_order_magic_button_target = new Gtk.DropTarget (typeof (Widgets.MagicButton), Gdk.DragAction.MOVE);
        motion_top_grid.add_controller (drop_order_magic_button_target);
        signals_map[drop_order_magic_button_target.drop.connect ((value, x, y) => {
            var dialog = new Dialogs.QuickAdd () {
                position = get_index ()
            };

            if (item.section_id != "") {
                dialog.for_base_object (item.section);
            } else {
                dialog.for_base_object (item.project);
            }

            dialog.present (Planify._instance.main_window);

            return true;
        })] = drop_order_magic_button_target;
    }

    private void build_drop_order_target () {
        var drop_order_target = new Gtk.DropTarget (typeof (Layouts.ItemBoard), Gdk.DragAction.MOVE);
        motion_top_grid.add_controller (drop_order_target);
        signals_map[drop_order_target.drop.connect ((value, x, y) => {
            var picked_widget = (Layouts.ItemBoard) value;
            var target_widget = this;

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

            string old_section_id = picked_widget.item.section_id;
            string old_parent_id = picked_widget.item.parent_id;

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

                if (picked_widget.item.project.source_type == SourceType.TODOIST) {
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
                            Services.Store.instance ().update_item (picked_widget.item);
                        }
                    });
                } else if (picked_widget.item.project.source_type == SourceType.LOCAL) {
                    Services.Store.instance ().update_item (picked_widget.item);
                }
            }

            var source_list = (Gtk.ListBox) picked_widget.parent;
            source_list.remove (picked_widget);

            var target_list = (Gtk.ListBox) target_widget.parent;
            int new_index = target_widget.get_index ();
            
            target_list.insert (picked_widget, new_index);
            Services.EventBus.get_default ().update_inserted_item_map (picked_widget, old_section_id, old_parent_id);

            Utils.TaskUtils.update_single_item_order (target_list, picked_widget, new_index);

            return true;
        })] = drop_order_target;
    }

    public void drag_begin () {
        card_widget.add_css_class ("drop-begin");
        on_drag = true;
        main_revealer.reveal_child = false;
    }

    public void drag_end () {
        card_widget.remove_css_class ("drop-begin");
        on_drag = false;
        main_revealer.reveal_child = item.show_item;
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

        if (item.project.source_id != project.source_id) {
            Util.get_default ().move_backend_type_item.begin (item, project);
        } else {
            if (item.project_id != project_id || item.section_id != section_id) {
                item.move (project, section_id);
            }
        }
    }

    public void update_date (GLib.DateTime ? date) {
        item.update_date (date);
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
            card_widget.add_css_class ("complete");
        } else {
            card_widget.remove_css_class ("complete");
        }
    }

    public override void hide_destroy () {
        main_revealer.reveal_child = false;
        clean_up ();
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }

    public void hide_widget () {
        main_revealer.reveal_child = false;
    }

    private void set_loading_state (bool loading) {
        if (pin_mode) {
            hide_loading_revealer.reveal_child = true;
        } else {
            hide_loading_revealer.reveal_child = loading;
        }
    }

    public override void clean_up () {
        foreach (var entry in signals_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signals_map.clear ();

    }
}
