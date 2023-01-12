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

public class Widgets.MultiSelectToolbar : Gtk.Grid {
    public Gee.HashMap<string, Layouts.ItemRow> items_selected;

    private Gtk.Revealer main_revealer;

    private Gtk.Button schedule_button;
    private Widgets.DateTimePicker.DateTimePicker datetime_picker = null;

    private Gtk.Button label_button;
    private Widgets.LabelPicker.LabelPicker labels_picker = null;

    private Gtk.Button priority_button;
    private Gtk.Popover priority_picker = null;

    private Gtk.Button menu_button;
    private Gtk.Popover menu_picker = null;

    public MultiSelectToolbar () {
        Object (
            hexpand: true,
            halign: Gtk.Align.CENTER
        );
    }

    construct {
        items_selected = new Gee.HashMap <string, Layouts.ItemRow> ();

        var done_button = new Widgets.LoadingButton.with_label (_("Done")) {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            margin_start = 24
        };

        done_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
        done_button.add_css_class ("small-button");

        var schedule_label = new Gtk.Label (_("Schedule")) {
            xalign = 0
        };

        var schedule_image = new Widgets.DynamicIcon ();
        schedule_image.update_icon_name ("planner-calendar");
        schedule_image.size = 19;  

        var schedule_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        schedule_box.append (schedule_image);
        schedule_box.append (schedule_label);

        schedule_button = new Gtk.Button ();
        schedule_button.get_style_context ().add_class (Granite.STYLE_CLASS_FLAT);
        schedule_button.child = schedule_box;

        var label_image = new Widgets.DynamicIcon ();
        label_image.update_icon_name ("planner-tag");
        label_image.size = 19;  

        label_button = new Gtk.Button ();
        label_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        label_button.child = label_image;

        var priority_image = new Widgets.DynamicIcon ();
        priority_image.update_icon_name ("planner-flag");
        priority_image.size = 19;  

        priority_button = new Gtk.Button ();

        priority_button.get_style_context ().add_class (Granite.STYLE_CLASS_FLAT);
        priority_button.child = priority_image;

        var menu_image = new Widgets.DynamicIcon ();
        menu_image.size = 19;
        menu_image.update_icon_name ("dots-horizontal");
        
        menu_button = new Gtk.Button ();
        menu_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        menu_button.child = menu_image;

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        content_box.valign = Gtk.Align.CENTER;

        content_box.append (schedule_button);
        content_box.append (label_button);
        content_box.append (priority_button);
        //  content_box.add (move_button);
        content_box.append (menu_button);
        content_box.append (done_button);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            reveal_child = false
        };

        main_revealer.child = content_box;

        attach (main_revealer, 0, 0);

        Planner.event_bus.select_item.connect ((row) => {
            if (items_selected.has_key (row.item.id_string)) {
                items_selected.unset (row.item.id_string);
                row.is_row_selected = false;
            } else {
                items_selected [row.item.id_string] = row;
                row.is_row_selected = true;
            }

            check_select_bar ();
        });

        Planner.event_bus.unselect_item.connect ((row) => {
            if (items_selected.has_key (row.item.id_string)) {
                items_selected.unset (row.item.id_string);
                row.is_row_selected = false;
            }

            check_select_bar ();
        });

        Planner.event_bus.show_multi_select.connect ((value) => {
            main_revealer.reveal_child = value;
        });

        done_button.clicked.connect (() => {
            unselect_all ();
        });

        schedule_button.clicked.connect (open_datetime_picker);
        label_button.clicked.connect (open_labels_picker);
        priority_button.clicked.connect (open_priority_picker);
        menu_button.clicked.connect (open_menu);
    }

    private void open_datetime_picker () {
        if (datetime_picker == null) {
            datetime_picker = new Widgets.DateTimePicker.DateTimePicker ();
            datetime_picker.set_parent (schedule_button);
                    
            datetime_picker.date_changed.connect (() => {
                set_datetime (datetime_picker.datetime);
            });
        }

        datetime_picker.visible_no_date = false;
        datetime_picker.popup ();
    }

    private void set_datetime (DateTime datetime) {
        foreach (string key in items_selected.keys) {
            items_selected[key].update_due (datetime);
        }

        unselect_all ();
    }

    private void open_priority_picker () {
        if (priority_picker != null) {
            priority_picker.popup ();
            return;
        }

        var priority_1_item = new Widgets.ContextMenu.MenuItem (_("Priority 1: high"), "planner-priority-1");
        var priority_2_item = new Widgets.ContextMenu.MenuItem (_("Priority 2: medium"), "planner-priority-2");
        var priority_3_item = new Widgets.ContextMenu.MenuItem (_("Priority 3: low"), "planner-priority-3");
        var priority_4_item = new Widgets.ContextMenu.MenuItem (_("Priority 4: none"), "planner-flag");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (priority_1_item);
        menu_box.append (priority_2_item);
        menu_box.append (priority_3_item);
        menu_box.append (priority_4_item);

        priority_picker = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            position = Gtk.PositionType.BOTTOM
        };

        priority_picker.set_parent (priority_button);
        priority_picker.popup();

        priority_1_item.clicked.connect (() => {
            priority_picker.popdown ();
            set_priority (Constants.PRIORITY_1);
        });

        priority_2_item.clicked.connect (() => {
            priority_picker.popdown ();
            set_priority (Constants.PRIORITY_2);
        });

        priority_3_item.clicked.connect (() => {
            priority_picker.popdown ();
            set_priority (Constants.PRIORITY_3);
        });

        priority_4_item.clicked.connect (() => {
            priority_picker.popdown ();
            set_priority (Constants.PRIORITY_4);
        });
    }

    private void set_priority (int priority) {
        foreach (string key in items_selected.keys) {
            items_selected[key].update_priority (priority);
        }

        unselect_all ();
    }

    private void open_labels_picker () {
        if (labels_picker == null) {
            labels_picker = new Widgets.LabelPicker.LabelPicker ();
            labels_picker.set_parent (label_button);
            
            labels_picker.closed.connect (() => {
                set_labels (labels_picker.labels_map);
            });
        }

        labels_picker.popup ();
    }

    private void set_labels (Gee.HashMap <string, Objects.Label> labels) {
        foreach (string key in items_selected.keys) {
            items_selected[key].update_labels (labels);
        }

        unselect_all ();
    }

    private void open_menu () {
        if (menu_picker != null) {
            menu_picker.popup ();
            return;
        }

        var complete_item = new Widgets.ContextMenu.MenuItem (_("Mask as Completed"), "planner-check-circle");        var priority_2_item = new Widgets.ContextMenu.MenuItem (_("Priority 2: medium"), "planner-priority-2");
        
        var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete"), "planner-trash");
        delete_item.get_style_context ().add_class ("menu-item-danger");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (complete_item);
        menu_box.append (new Dialogs.ContextMenu.MenuSeparator ());
        menu_box.append (delete_item);

        menu_picker = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            position = Gtk.PositionType.BOTTOM
        };

        menu_picker.set_parent (menu_button);
        menu_picker.popup();

        complete_item.clicked.connect (() => {
            menu_picker.popdown ();

            foreach (string key in items_selected.keys) {
                items_selected[key].checked_toggled (true, 0);
            }
    
            unselect_all ();
        });

        delete_item.clicked.connect (() => {
            menu_picker.popdown ();

            string title = _("Delete To-Do");
            string message = _("Are you sure you want to delete this to-do?");
            if (items_selected.size > 1) {
                title = _("Delete %d To-Dos".printf (items_selected.size));
                message = _("Are you sure you want to delete these %d to-dos?".printf (items_selected.size));
            }


            var dialog = new Adw.MessageDialog ((Gtk.Window) Planner.instance.main_window, 
            title, message);

            dialog.body_use_markup = true;
            dialog.add_response ("cancel", _("Cancel"));
            dialog.add_response ("delete", _("Delete"));
            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.show ();

            dialog.response.connect ((response) => {
                if (response == "delete") {
                    foreach (string key in items_selected.keys) {
                        items_selected[key].delete_request (false);
                    }
            
                    unselect_all ();
                }
            });
        });
    }

    private void check_select_bar () {
        if (items_selected.size > 0) {
            Planner.event_bus.magic_button_visible (false);
            Planner.event_bus.disconnect_typing_accel ();
        } else {
            Planner.event_bus.magic_button_visible (true);
            Planner.event_bus.connect_typing_accel ();
        }
    }

    private void unselect_all () {
        foreach (string key in items_selected.keys) {
            items_selected [key].is_row_selected = false;
        }

        items_selected.clear ();
        main_revealer.reveal_child = false;
        Planner.event_bus.magic_button_visible (true);
        Planner.event_bus.connect_typing_accel ();
        Planner.event_bus.show_multi_select (false);
        Planner.event_bus.multi_select_enabled = false;
    }
}