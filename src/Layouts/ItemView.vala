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

public class Layouts.ItemViewContent : Adw.Bin {
    public Objects.Item item { get; construct; }

    private Gtk.CheckButton checked_button;
    private Gtk.Entry content_entry;
    private Widgets.HyperTextView description_textview;
    private Widgets.ItemLabels item_labels;
    private Widgets.ScheduleButton schedule_button;
    private Widgets.PinButton pin_button;
    private Widgets.PriorityButton priority_button;
    private Widgets.LabelPicker.LabelButton label_button;
    private Widgets.ReminderButton reminder_button;
    private Gtk.MenuButton menu_button;
    private Gtk.Box action_box;

    public uint complete_timeout { get; set; default = 0; }
    public string update_id { get; set; default = Util.get_default ().generate_id (); }

    private bool _is_loading;
    public bool is_loading {
        set {
            _is_loading = value;
        }

        get {
            return _is_loading;
        }
    }

    public ItemViewContent (Objects.Item item) {
        Object (
            item: item,
            hexpand: true,
            vexpand: true
        );
    }

    construct {
        var headerbar = new Adw.HeaderBar () {
			title_widget = new Gtk.Label (null),
			hexpand = true,
			css_classes = { "flat" }
		};

        checked_button = new Gtk.CheckButton () {
            valign = Gtk.Align.START,
            margin_top = 3,
            css_classes = { "priority-color" }
        };

        content_entry = new Widgets.Entry () {
            hexpand = true,
            placeholder_text = _("To-do name"),
            editable = !item.completed,
            text = item.content,
            css_classes = { "font-bold" }
        };

        content_entry.add_css_class (Granite.STYLE_CLASS_FLAT);
        
        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            valign = Gtk.Align.START,
            hexpand = true,
            margin_top = 9,
            margin_start = 12,
            margin_end = 12
        };
        
        content_box.append (checked_button);
        content_box.append (content_entry);

        description_textview = new Widgets.HyperTextView (_("Add a description…")) {
            left_margin = 36,
            right_margin = 6,
            top_margin = 6,
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
            hexpand = true,
            editable = !item.completed
        };

        description_textview.remove_css_class ("view");

        var description_scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            height_request = 164,
            hexpand = true,
            child = description_textview
        };

        var subitems = new Widgets.SubItems.for_board (item) {
            margin_start = 26,
            margin_end = 6,
            margin_top = 6,
            reveal_child = true
        };

        item_labels = new Widgets.ItemLabels (item) {
            margin_start = 34,
            margin_top = 6,
            margin_bottom = 6,
            sensitive = !item.completed
        };
        
        schedule_button = new Widgets.ScheduleButton ();
        pin_button = new Widgets.PinButton (item);
        priority_button = new Widgets.PriorityButton ();
        priority_button.update_from_item (item);
        label_button = new Widgets.LabelPicker.LabelButton ();
        label_button.backend_type = item.project.backend_type;
        label_button.labels = item._get_labels ();
        reminder_button = new Widgets.ReminderButton (item);

        menu_button = new Gtk.MenuButton () {
            icon_name = "view-more-symbolic",
            popover = build_button_context_menu (),
            css_classes = { "flat" }
        };

        var add_button = new Gtk.Button.from_icon_name ("plus-large-symbolic") {
            valign = Gtk.Align.CENTER,
            tooltip_text = _("Add subtask"),
            margin_top = 1,
            css_classes = { "flat" }
        };

        action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            margin_start = 26,
            margin_bottom = 3
        };

        var action_box_right = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            halign = Gtk.Align.END,
            margin_end = 3
        };

        action_box_right.append (add_button);
        action_box_right.append (label_button);
        action_box_right.append (priority_button);
        action_box_right.append (reminder_button);
        action_box_right.append (pin_button);
        action_box_right.append (menu_button);

        action_box.append (schedule_button);
        action_box.append (action_box_right);

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 24,
            margin_end = 24,
            valign = START,
            hexpand = true,
            css_classes = { "card", "sidebar-card" }
        };
        
        content.append (content_box);
        content.append (description_scrolled_window);
        content.append (subitems);
        content.append (item_labels);
        content.append (action_box);

        var v_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.START,
            margin_bottom = 24
        };
        v_box.append (headerbar);
        v_box.append (content);
        
        child = v_box;
        update_request ();

        Services.Database.get_default ().item_updated.connect ((_item, _update_id) => {
            if (item.id == _item.id && update_id != _update_id) {
                update_request ();
            }
        });

        schedule_button.date_changed.connect ((datetime) => {
            update_due (datetime);
        });

        priority_button.changed.connect ((priority) => {
            if (item.priority != priority) {
                item.priority = priority;

                if (item.project.backend_type == BackendType.TODOIST) {
                    item.update_async ("");
                } else if (item.project.backend_type == BackendType.LOCAL) {
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

        var content_controller_key = new Gtk.EventControllerKey ();
        content_entry.add_controller (content_controller_key);
        content_controller_key.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == 65293) {
                return Gdk.EVENT_STOP;
            } else if (keyval == 65289) {
                description_textview.grab_focus ();
                return Gdk.EVENT_STOP;
            }

            return false;
        });


        content_controller_key.key_released.connect ((keyval, keycode, state) => {            
            // Sscape
            if (keyval == 65307) {
            } else { 
                update ();
            }
        });

        var description_controller_key = new Gtk.EventControllerKey ();
        description_textview.add_controller (description_controller_key);
        description_controller_key.key_released.connect ((keyval, keycode, state) => {
            if (keyval == 65307) {
            } else if (keyval == 65289) {
                schedule_button.grab_focus ();
            } else {
                update ();
            }
        });

        item.loading_changed.connect ((value) => {
            
        });

        add_button.clicked.connect (() => {
            subitems.prepare_new_item ();
        });

        var checked_button_gesture = new Gtk.GestureClick ();
        checked_button.add_controller (checked_button_gesture);
        checked_button_gesture.pressed.connect (() => {
            checked_button.active = !checked_button.active;
            checked_toggled (checked_button.active);
        });
    }

    public void checked_toggled (bool active, uint? time = null) {
        bool old_checked = item.checked;

        if (active) {
            complete_item (old_checked, time);
        } else {
            if (complete_timeout != 0) {
                GLib.Source.remove (complete_timeout);
                complete_timeout = 0;
            } else {
                item.checked = false;
                item.completed_at = "";
                _complete_item (old_checked);
            }
        }
    }

    private void complete_item (bool old_checked, uint? time = null) {
        uint timeout = 2500;
        if (Services.Settings.get_default ().settings.get_enum ("complete-task") == 0) {
            timeout = 0;
        }

        if (time != null) {
            timeout = time;
        }

        complete_timeout = Timeout.add (timeout, () => {
            complete_timeout = 0;

            if (item.due.is_recurring && !item.due.is_recurrency_end) {
                update_next_recurrency ();
            } else {
                item.checked = true;
                item.completed_at = Util.get_default ().get_format_date (
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
            Services.CalDAV.get_default ().complete_item.begin (item, (obj, res) => {
                if (Services.CalDAV.get_default ().complete_item.end (res).status) {
                    Services.Database.get_default ().checked_toggled (item, old_checked);
                    is_loading = false;
                    checked_button.sensitive = true;
                }
            });
        }
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
        
        var title = _("Completed. Next occurrence: %s".printf (
            Util.get_default ().get_default_date_format_from_date (next_recurrency)
        ));
        var toast = Util.get_default ().create_toast (title, 3);
        Services.EventBus.get_default ().send_notification (toast);
    }

    private void update () {
        if (item.content != content_entry.text ||
            item.description != description_textview.get_text ()) {
            item.content = content_entry.text;
            item.description = description_textview.get_text ();
            item.update_async_timeout (update_id);
        }
    }

    public void update_due (GLib.DateTime? datetime) {
        item.due.date = datetime == null ? "" : Util.get_default ().get_todoist_datetime_format (datetime);

        if (item.due.date == "") {
            item.due.reset ();
        }

        item.update_async ("");
    }

    public void update_pinned (bool pinned) {
        item.pinned = pinned;
        item.update_local ();
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

    public void update_request () {
        if (complete_timeout <= 0) {
            Util.get_default ().set_widget_priority (item.priority, checked_button);
            checked_button.active = item.completed;

            //  if (item.completed && Services.Settings.get_default ().settings.get_boolean ("underline-completed-tasks")) {
            //      content_label.add_css_class ("line-through");
            //  } else if (item.completed && !Services.Settings.get_default ().settings.get_boolean ("underline-completed-tasks")) {
            //      content_label.remove_css_class ("line-through");
            //  }
        }

        content_entry.text = item.content;
        description_textview.set_text (item.description);
                
        schedule_button.update_from_item (item);
        priority_button.update_from_item (item);
        pin_button.update_request ();

        content_entry.editable = !item.completed;
        description_textview.editable = !item.completed;
        item_labels.sensitive = !item.completed;
        action_box.sensitive = !item.completed;
    }

    private string get_updated_info () {
        string added_at = _("Added at");
        string updated_at = _("Updated at");
        string added_date = Util.get_default ().get_relative_date_from_date (item.added_datetime);
        string updated_date = "(" + _("Not available") + ")";
        if (item.updated_at != "") {
            updated_date = Util.get_default ().get_relative_date_from_date (item.updated_datetime);
        }

        return "<b>%s:</b> %s\n<b>%s:</b> %s".printf (added_at, added_date, updated_at, updated_date);
    }

    private Gtk.Popover build_button_context_menu () {
        var copy_clipboard_item = new Widgets.ContextMenu.MenuItem (_("Copy to Clipboard"), "clipboard-symbolic");
        var duplicate_item = new Widgets.ContextMenu.MenuItem (_("Duplicate"), "tabs-stack-symbolic");
        var move_item = new Widgets.ContextMenu.MenuItem (_("Move"), "arrow3-right-symbolic");
        var repeat_item = new Widgets.ContextMenu.MenuItem (_("Repeat"), "arrow-circular-top-right-symbolic");
        repeat_item.arrow = true;

        var more_information_item = new Widgets.ContextMenu.MenuItem ("", null);
        more_information_item.add_css_class ("small-label");

        var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete Task"), "user-trash-symbolic");
        delete_item.add_css_class ("menu-item-danger");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (copy_clipboard_item);
        menu_box.append (duplicate_item);
        menu_box.append (move_item);
        menu_box.append (repeat_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (delete_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (more_information_item);

        var popover = new Gtk.Popover () {
            has_arrow = false,
            position = Gtk.PositionType.BOTTOM,
            width_request = 225
        };

        var menu_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT,
            vhomogeneous = false
        };

        menu_stack.add_named (menu_box, "menu");
        menu_stack.add_named (get_repeat_widget (popover), "repeat");

        popover.child = menu_stack;

        copy_clipboard_item.clicked.connect (() => {
            popover.popdown ();
            item.copy_clipboard ();
        });

        duplicate_item.clicked.connect (() => {
            popover.popdown ();
            item.duplicate ();
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

        popover.show.connect (() => {
            more_information_item.title = get_updated_info ();
        });

        delete_item.activate_item.connect (() => {
            popover.popdown ();
            delete_request ();
        });

        return popover;
    }

    private Gtk.Widget get_repeat_widget (Gtk.Popover popover) {
        var none_item = new Widgets.ContextMenu.MenuItem (_("None"));
        var daily_item = new Widgets.ContextMenu.MenuItem (_("Daily"));
        var weekly_item = new Widgets.ContextMenu.MenuItem (_("Weekly"));
        var monthly_item = new Widgets.ContextMenu.MenuItem (_("Monthly"));
        var yearly_item = new Widgets.ContextMenu.MenuItem (_("Yearly"));
        var custom_item = new Widgets.ContextMenu.MenuItem (_("Custom"));
        
        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
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

    public void delete_request (bool undo = true) {
        var dialog = new Adw.MessageDialog (
            (Gtk.Window) Planify.instance.main_window,
            _("Delete To-Do"), _("Are you sure you want to delete this to-do?")
        );

        dialog.add_response ("cancel", _("Cancel"));
        dialog.add_response ("delete", _("Delete"));
        dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
        dialog.show ();

        dialog.response.connect ((response) => {
            if (response == "delete") {
                item.delete_item ();
            }
        });
    }

    public void move (Objects.Project project, string section_id) {
        string project_id = project.id;

        if (item.project_id != project_id || item.section_id != section_id) {
            item.move (project, section_id);
        }
    }
}
