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

    private Gtk.Label size_label;
    private Widgets.ScheduleButton schedule_button;
    private Widgets.LabelPicker.LabelButton label_button;
    private Widgets.PriorityButton priority_button;
    private Gtk.MenuButton menu_button;
    private Widgets.LoadingButton done_button;

    public Gee.HashMap<string, Layouts.ItemBase> items_selected = new Gee.HashMap <string, Layouts.ItemBase> ();
    public Gee.HashMap<string, Objects.Label> labels = new Gee.HashMap <string, Objects.Label> ();
    public signal void closed ();

    public MultiSelectToolbar (Objects.Project project) {
        Object (
            project: project,
            hexpand: true,
            valign: Gtk.Align.END
        );
    }

    construct {
        css_classes = { "sidebar" };

        size_label = new Gtk.Label (null) {
            css_classes = { "font-bold" }
        };

        schedule_button = new Widgets.ScheduleButton () {
            sensitive = false
        };
        schedule_button.visible_no_date = true;

        label_button = new Widgets.LabelPicker.LabelButton (project.backend_type) {
            sensitive = false
        };

        priority_button = new Widgets.PriorityButton () {
            sensitive = false
        };
        priority_button.set_priority (Constants.PRIORITY_4);
        
        menu_button = new Gtk.MenuButton () {
            css_classes = { Granite.STYLE_CLASS_FLAT },
            valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
            child = new Widgets.DynamicIcon.from_icon_name ("dots-vertical"),
            popover = build_menu_popover (),
            sensitive = false
        };

        done_button = new Widgets.LoadingButton.with_label (_("Done")) {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            margin_start = 12,
            width_request = 100,
            css_classes = { Granite.STYLE_CLASS_SUGGESTED_ACTION }
        };

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            margin_top = 9,
            margin_bottom = 9
        };

        content_box.append (size_label);
        content_box.append (schedule_button);
        content_box.append (label_button);
        content_box.append (priority_button);
        content_box.append (menu_button);
        content_box.append (done_button);

        child = content_box;

        Services.EventBus.get_default ().select_item.connect ((_row) => {
            var row = (Layouts.ItemBase) _row;

            if (items_selected.has_key (row.item.id)) {
                items_selected.unset (row.item.id);
                row.select_row (false);
            } else {
                items_selected [row.item.id] = row;
                row.select_row (true);
            }

            check_labels (row.item, true);
            check_select_bar ();
        });

        Services.EventBus.get_default ().unselect_item.connect ((_row) => {
            var row = (Layouts.ItemBase) _row;

            if (items_selected.has_key (row.item.id)) {
                items_selected.unset (row.item.id);
                row.select_row (false);
            }

            check_labels (row.item, false);
            check_select_bar ();
        });

        done_button.clicked.connect (() => {
            unselect_all ();
        });

        Services.EventBus.get_default ().request_escape.connect (() => {
            unselect_all ();
		});

        Services.EventBus.get_default ().unselect_all.connect (() => {
            unselect_all ();
        });

        schedule_button.date_changed.connect ((datetime) => {
            set_datetime (datetime);
        });

        label_button.labels_changed.connect ((labels) => {
            set_labels (labels);
        });

        priority_button.changed.connect ((priority) => {
            set_priority (priority);
        });
    }

    private void update_items (Gee.ArrayList<Objects.Item> objects) {
        if (project.backend_type == BackendType.LOCAL) {
            foreach (Objects.Item item in objects) {
                item.update_async ("");
            }

            unselect_all ();
        } else if (project.backend_type == BackendType.TODOIST) {
            done_button.is_loading =  true;
            Services.Todoist.get_default ().update_items (objects, (obj, res) => {
                Services.Todoist.get_default ().update_items.end (res);

                foreach (Objects.Item item in objects) {
                    item.update_local ();
                }
                
                done_button.is_loading =  false;
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

    private void set_labels (Gee.HashMap <string, Objects.Label> new_labels) {
        Gee.ArrayList<Objects.Item> objects = new Gee.ArrayList<Objects.Item> ();

        foreach (string key in items_selected.keys) {
            var item = items_selected[key].item;
            item.check_labels (new_labels);
            objects.add (item);
        }

        update_items (objects);
    }

    private Gtk.Popover build_menu_popover () {
        var complete_item = new Widgets.ContextMenu.MenuItem (_("Mask as Completed"), "planner-check-circle");
        
        var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete"), "planner-trash");
        delete_item.add_css_class ("menu-item-danger");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (complete_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (delete_item);

        var popover = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            position = Gtk.PositionType.TOP
        };

        complete_item.clicked.connect (() => {
            popover.popdown ();

            foreach (string key in items_selected.keys) {
                items_selected[key].checked_toggled (true, 0);
            }
    
            unselect_all ();
        });

        delete_item.clicked.connect (() => {
            popover.popdown ();

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

        return popover;
    }

    private void unselect_all () {
        foreach (string key in items_selected.keys) {
            items_selected [key].select_row (false);
        }
        
        items_selected.clear ();
        labels.clear ();
        size_label.label = null;
        closed ();
    }

    private void check_select_bar () {
        bool active = items_selected.size > 0;

        size_label.label = active ? "(%d)".printf (items_selected.size) : "";
        schedule_button.sensitive = active;
        priority_button.sensitive = active;
        label_button.sensitive = active;
        menu_button.sensitive = active;
    }

    private void check_labels (Objects.Item item, bool active) {
        if (active) {
            foreach (Objects.Label label in item._get_labels ()) {
                if (!labels.has_key (label.id)) {
                    labels[label.id] = label;
                }
            }
        } else {
            foreach (Objects.Label label in item._get_labels ()) {
                if (labels.has_key (label.id)) {
                    labels.unset (label.id);
                }
            }
        }
        
        Gee.ArrayList<Objects.Label> _labels = new Gee.ArrayList<Objects.Label> ();
        foreach (Objects.Label label in labels.values) {
            _labels.add (label);
        }

        label_button.labels = _labels;
    }
}
