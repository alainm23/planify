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
    private Widgets.TextView content_textview;
    private Widgets.HyperTextView description_textview;
    private Widgets.ItemLabels item_labels;
    private Widgets.ScheduleButton schedule_button;
    private Widgets.PinButton pin_button;
    private Widgets.PriorityButton priority_button;
    private Widgets.LabelPicker.LabelButton label_button;
    private Widgets.ReminderButton reminder_button;
    private Gtk.Box action_box;

    public uint complete_timeout { get; set; default = 0; }
    public string update_id { get; set; default = Util.get_default ().generate_id (); }

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
            margin_top = 12,
            css_classes = { "priority-color" }
        };

        content_textview = new Widgets.TextView () {
            top_margin = 12,
            hexpand = true,
            vexpand = false,
            valign = START,
            wrap_mode = Gtk.WrapMode.CHAR,
            editable = !item.completed
        };
        content_textview.buffer.text = item.content;
        content_textview.remove_css_class ("view");
        
        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            valign = Gtk.Align.START,
            hexpand = true,
            margin_start = 12
        };
        
        content_box.append (checked_button);
        content_box.append (content_textview);

        description_textview = new Widgets.HyperTextView (_("Add a description")) {
            left_margin = 36,
            right_margin = 6,
            top_margin = 6,
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
            hexpand = true,
            editable = !item.completed,
            css_classes = { "dim-label" }
        };

        description_textview.remove_css_class ("view");

        var description_scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            height_request = 128,
            hexpand = true,
            child = description_textview
        };

        item_labels = new Widgets.ItemLabels (item) {
            margin_start = 34,
            margin_top = 12,
            margin_bottom = 6,
            sensitive = !item.completed
        };
        
        schedule_button = new Widgets.ScheduleButton ();
        pin_button = new Widgets.PinButton (item);
        priority_button = new Widgets.PriorityButton ();
        priority_button.update_from_item (item);
        label_button = new Widgets.LabelPicker.LabelButton (item.project.backend_type);
        label_button.labels = item._get_labels ();
        reminder_button = new Widgets.ReminderButton (item);

        action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            margin_start = 26,
            margin_bottom = 3
        };

        var action_box_right = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            halign = Gtk.Align.END,
            margin_end = 3
        };

        action_box_right.append (label_button);
        action_box_right.append (priority_button);
        action_box_right.append (reminder_button);
        action_box_right.append (pin_button);

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
        content.append (item_labels);
        content.append (action_box);

        // Sub Items
        var subitems = new Widgets.SubItems.for_board (item) {
            margin_start = 16,
            margin_end = 19,
            margin_top = 6
        };
        subitems.reveal_child = true;

        var v_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.START,
            margin_bottom = 24
        };
        v_box.append (headerbar);
        v_box.append (content);
        v_box.append (subitems);

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
        content_textview.add_controller (content_controller_key);
        content_controller_key.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == 65293) {
                // popdown ();
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
                // popdown ();
            } else { 
                update ();
            }
        });

        var description_controller_key = new Gtk.EventControllerKey ();
        description_textview.add_controller (description_controller_key);
        description_controller_key.key_released.connect ((keyval, keycode, state) => {
            if (keyval == 65307) {
                // popdown ();
            } else if (keyval == 65289) {
                schedule_button.grab_focus ();
            } else {
                update ();
            }
        });



        item.loading_changed.connect ((value) => {
            
        });
    }

    private void update () {
        if (item.content != content_textview.buffer.text ||
            item.description != description_textview.get_text ()) {
            item.content = content_textview.buffer.text;
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

        content_textview.buffer.text = item.content;
        description_textview.set_text (item.description);
                
        schedule_button.update_from_item (item);
        priority_button.update_from_item (item);
        pin_button.update_request ();

        content_textview.editable = !item.completed;
        description_textview.editable = !item.completed;
        item_labels.sensitive = !item.completed;
        action_box.sensitive = !item.completed;
    }
}