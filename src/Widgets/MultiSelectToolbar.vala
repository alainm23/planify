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

public class Widgets.MultiSelectToolbar : Gtk.Revealer {
    public Gee.HashMap<string, Layouts.ItemRow> items_selected;

    public MultiSelectToolbar () {
        Object (
            halign: Gtk.Align.CENTER,
            valign: Gtk.Align.END,
            transition_type: Gtk.RevealerTransitionType.SLIDE_UP,
            reveal_child: false
        );
    }

    construct {
        items_selected = new Gee.HashMap <string, Layouts.ItemRow> ();

        var close_image = new Gtk.Image ();
        close_image.gicon = new ThemedIcon ("close-symbolic");
        close_image.pixel_size = 16;

        var close_button = new Gtk.Button () {
            can_focus = false,
            valign = Gtk.Align.START,
            halign = Gtk.Align.START
        };
        
        close_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        close_button.get_style_context ().add_class ("magic-button");
        close_button.get_style_context ().add_class ("close-button");
        
        close_button.add (close_image);

        var schedule_label = new Gtk.Label (_("Schedule")) {
            xalign = 0
        };

        var schedule_image = new Widgets.DynamicIcon ();
        schedule_image.update_icon_name ("planner-calendar");
        schedule_image.size = 19;  

        var schedule_grid = new Gtk.Grid () {
            column_spacing = 3
        };
        schedule_grid.add (schedule_image);
        schedule_grid.add (schedule_label);

        var schedule_button = new Gtk.Button () {
            can_focus = false
        };

        schedule_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        schedule_button.add (schedule_grid);

        var label_image = new Widgets.DynamicIcon ();
        label_image.update_icon_name ("planner-tag");
        label_image.size = 19;  

        var label_button = new Gtk.Button () {
            can_focus = false
        };

        label_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        label_button.add (label_image);

        var priority_image = new Widgets.DynamicIcon ();
        priority_image.update_icon_name ("planner-flag");
        priority_image.size = 19;  

        var priority_button = new Gtk.Button () {
            can_focus = false
        };

        priority_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        priority_button.add (priority_image);

        var move_image = new Widgets.DynamicIcon ();
        move_image.update_icon_name ("chevron-right");
        move_image.size = 19;  

        var move_button = new Gtk.Button () {
            can_focus = false
        };

        move_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        move_button.add (move_image);

        var menu_image = new Widgets.DynamicIcon ();
        menu_image.size = 19;
        menu_image.update_icon_name ("dots-horizontal");
        
        var menu_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };
        
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        menu_button.add (menu_image);
 
        var content_grid = new Gtk.Grid ();
        content_grid.column_spacing = 3;
        content_grid.valign = Gtk.Align.CENTER;

        content_grid.add (schedule_button);
        content_grid.add (label_button);
        content_grid.add (priority_button);
        content_grid.add (move_button);
        content_grid.add (menu_button);

        var frame = new Gtk.Frame (null);
        frame.margin = 9;
        frame.margin_bottom = 20;
        frame.get_style_context ().add_class (Granite.STYLE_CLASS_CARD);
        frame.get_style_context ().add_class ("padding-6");
        frame.add (content_grid);
        
        var overlay = new Gtk.Overlay ();
        overlay.add_overlay (close_button);
        overlay.add (frame);

        var eventbox = new Gtk.EventBox () {
            margin_bottom = 12
        };
        eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        eventbox.above_child = false;
        eventbox.add (overlay);

        add (eventbox);

        close_button.clicked.connect (() => {
            unselect_all ();
        });

        schedule_button.clicked.connect (open_datetime_picker);
        menu_button.clicked.connect (open_menu);
        priority_button.clicked.connect (open_priority_picker);
        label_button.clicked.connect (open_labels_picker);
        move_button.clicked.connect (open_project_picker);

        Planner.event_bus.unselect_all.connect ((row) => {
            if (items_selected.size > 0) {
                unselect_all ();
            }
        });

        Planner.event_bus.select_item.connect ((row) => {
            if (items_selected.has_key (row.item.id_string)) {
                items_selected.unset (row.item.id_string);
                row.item_selected = false;
            } else {
                items_selected [row.item.id_string] = row;
                row.item_selected = true;
            }

            check_select_bar ();
        });
    }

    private void check_select_bar () {
        if (items_selected.size > 0) {
            reveal_child = true;
            Planner.event_bus.magic_button_visible (false);
            Planner.event_bus.disconnect_typing_accel ();
        } else {
            reveal_child = false;
            Planner.event_bus.magic_button_visible (true);
            Planner.event_bus.connect_typing_accel ();
        }
    }

    private void open_datetime_picker () {
        var datetime_picker = new Dialogs.DateTimePicker.DateTimePicker ();
        datetime_picker.popup ();

        datetime_picker.date_changed.connect (() => {
            set_datetime (datetime_picker.datetime);
        });
    }

    private void open_menu () {
        var menu = new Dialogs.ContextMenu.Menu ();

        var complete_item = new Dialogs.ContextMenu.MenuItem (_("Complete"), "planner-check-circle");

        var delete_item = new Dialogs.ContextMenu.MenuItem (_("Delete task"), "planner-trash");
        delete_item.get_style_context ().add_class ("menu-item-danger");

        menu.add_item (complete_item);
        menu.add_item (new Dialogs.ContextMenu.MenuSeparator ());
        menu.add_item (delete_item);

        menu.popup ();

        delete_item.activate_item.connect (() => {
            menu.hide_destroy ();

            foreach (string key in items_selected.keys) {
                items_selected[key].delete_request ();
            }
    
            unselect_all ();
        });

        complete_item.activate_item.connect (() => {
            menu.hide_destroy ();

            foreach (string key in items_selected.keys) {
                items_selected[key].checked_toggled (true, 0);
            }
    
            unselect_all ();
        });
    }

    private void open_priority_picker () {
        var menu = new Dialogs.ContextMenu.Menu ();

        var priority_1_item = new Dialogs.ContextMenu.MenuItem (_("Priority 1: high"), "planner-priority-1");
        var priority_2_item = new Dialogs.ContextMenu.MenuItem (_("Priority 2: medium"), "planner-priority-2");
        var priority_3_item = new Dialogs.ContextMenu.MenuItem (_("Priority 3: low"), "planner-priority-3");
        var priority_4_item = new Dialogs.ContextMenu.MenuItem (_("Priority 4: none"), "planner-flag");

        menu.add_item (priority_1_item);
        menu.add_item (priority_2_item);
        menu.add_item (priority_3_item);
        menu.add_item (priority_4_item);

        menu.popup ();

        priority_1_item.clicked.connect (() => {
            menu.hide_destroy ();
            set_priority (Constants.PRIORITY_1);
        });

        priority_2_item.clicked.connect (() => {
            menu.hide_destroy ();
            set_priority (Constants.PRIORITY_2);
        });

        priority_3_item.clicked.connect (() => {
            menu.hide_destroy ();
            set_priority (Constants.PRIORITY_3);
        });

        priority_4_item.clicked.connect (() => {
            menu.hide_destroy ();
            set_priority (Constants.PRIORITY_4);
        });
    }

    public void set_priority (int priority) {
        foreach (string key in items_selected.keys) {
            items_selected[key].update_priority (priority);
        }

        unselect_all ();
    }

    public void set_datetime (GLib.DateTime? date) {
        foreach (string key in items_selected.keys) {
            items_selected[key].update_due (date);
        }

        unselect_all ();
    }

    public void set_labels (Gee.HashMap <string, Objects.Label> labels) {
        foreach (string key in items_selected.keys) {
            items_selected[key].update_labels (labels);
        }

        unselect_all ();
    }

    private void open_project_picker () {
        var picker = new Dialogs.ProjectPicker.ProjectPicker (false);
        picker.popup ();

        picker.changed.connect ((project_id, section_id) => {
            foreach (string key in items_selected.keys) {
                items_selected[key].move (project_id, section_id);
            }
    
            unselect_all ();
        });
    }

    private void open_labels_picker () {
        var dialog = new Dialogs.LabelPicker.LabelPicker ();
        
        dialog.labels_changed.connect ((labels) => {
            set_labels (labels);
        });

        dialog.popup ();
    }

    private void unselect_all () {
        foreach (string key in items_selected.keys) {
            items_selected [key].item_selected = false;
        }

        items_selected.clear ();
        reveal_child = false;
        Planner.event_bus.magic_button_visible (true);
        Planner.event_bus.connect_typing_accel ();
    }
}