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

public class Widgets.MultiSelectToolbar : Adw.Bin {
    public Objects.Project project { get; construct; }

    private Widgets.ScheduleButton schedule_button;
    private Widgets.LabelPicker.LabelButton label_button;
    private Widgets.PriorityButton priority_button;

    private Gtk.Button menu_button;
    private Gtk.Popover menu_picker = null;

    public Gee.HashMap<string, Layouts.ItemRow> items_selected = new Gee.HashMap <string, Layouts.ItemRow> ();

    public signal void closed ();

    public MultiSelectToolbar (Objects.Project project) {
        Object (
            project: project,
            hexpand: true,
            halign: Gtk.Align.CENTER,
            valign: Gtk.Align.END
        );
    }

    construct {
        schedule_button = new Widgets.ScheduleButton () {
            sensitive = false
        };
        schedule_button.visible_no_date = true;

        label_button = new Widgets.LabelPicker.LabelButton () {
            sensitive = false
        };

        priority_button = new Widgets.PriorityButton () {
            sensitive = false
        };
        priority_button.set_priority (Constants.PRIORITY_4);

        var menu_image = new Widgets.DynamicIcon ();
        menu_image.size = 16;
        menu_image.update_icon_name ("dots-vertical");
        
        menu_button = new Gtk.Button ();
        menu_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        menu_button.child = menu_image;

        var done_button = new Widgets.LoadingButton.with_label (_("Done")) {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            margin_start = 12,
            css_classes = { Granite.STYLE_CLASS_SUGGESTED_ACTION, "small-button" }
        };

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            margin_top = 6,
            margin_bottom = 6
        };

        content_box.append (schedule_button);
        content_box.append (label_button);
        content_box.append (priority_button);
        content_box.append (menu_button);
        content_box.append (done_button);

        child = content_box;

        Services.EventBus.get_default ().select_item.connect ((_row) => {
            var row = (Layouts.ItemRow) _row;

            if (items_selected.has_key (row.item.id_string)) {
                items_selected.unset (row.item.id_string);
                row.is_row_selected = false;
            } else {
                items_selected [row.item.id_string] = row;
                row.is_row_selected = true;
            }

            check_select_bar ();
        });

        Services.EventBus.get_default ().unselect_item.connect ((_row) => {
            var row = (Layouts.ItemRow) _row;

            if (items_selected.has_key (row.item.id_string)) {
                items_selected.unset (row.item.id_string);
                row.is_row_selected = false;
            }

            check_select_bar ();
        });

        done_button.clicked.connect (() => {
            unselect_all ();
        });

        schedule_button.date_changed.connect ((datetime) => {
            set_datetime (datetime);
        });

        label_button.labels_changed.connect ((labels) => {
            
        });

        priority_button.changed.connect ((priority) => {
            set_priority (priority);
        });

        menu_button.clicked.connect (open_menu);

        Services.EventBus.get_default ().unselect_all.connect (() => {
            if (items_selected.size > 0) {
                unselect_all ();
            }
        });
    }

    private void update_items (Gee.ArrayList<Objects.Item> objects) {
        if (project.backend_type == BackendType.LOCAL) {
            foreach (Objects.Item item in objects) {
                item.update_async ("");
            }

            unselect_all ();
        } else if (project.backend_type == BackendType.TODOIST) {
            Services.Todoist.get_default ().update_items (objects, (obj, res) => {
                Services.Todoist.get_default ().update_items.end (res);

                foreach (Objects.Item item in objects) {
                    item.update_local ();
                }
    
                unselect_all ();
            });
        }
    }

    private void set_datetime (DateTime? datetime) {
        Gee.ArrayList<Objects.Item> objects = new Gee.ArrayList<Objects.Item> ();
        foreach (string key in items_selected.keys) {
            var item = items_selected[key].item;

            item.due.date = datetime == null ? "" : Util.get_default ().get_todoist_datetime_format (datetime);

            if (item.due.date == "") {
                item.due.reset ();
            }

            objects.add (item);
        }

        update_items (objects);
    }

    private void set_priority (int priority) {
        Gee.ArrayList<Objects.Item> objects = new Gee.ArrayList<Objects.Item> ();

        foreach (string key in items_selected.keys) {
            var item = items_selected[key].item;

            if (item.priority != priority) {
                item.priority = priority;

                objects.add (item);
            }
        }

        update_items (objects);
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

        var complete_item = new Widgets.ContextMenu.MenuItem (_("Mask as Completed"), "planner-check-circle");
        
        var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete"), "planner-trash");
        delete_item.add_css_class ("menu-item-danger");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (complete_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
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


            var dialog = new Adw.MessageDialog ((Gtk.Window) Planify.instance.main_window, 
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

    private void unselect_all () {
        foreach (string key in items_selected.keys) {
            items_selected [key].is_row_selected = false;
        }

        items_selected.clear ();
        closed ();
    }

    private void check_select_bar () {
        bool active = items_selected.size > 0;
        schedule_button.sensitive = active;
        priority_button.sensitive = active;
    }
}