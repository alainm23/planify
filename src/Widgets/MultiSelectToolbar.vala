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
    private Gtk.Button move_button;
    private Widgets.LabelPicker.LabelButton label_button;
    private Widgets.PriorityButton priority_button;
    private Gtk.MenuButton menu_button;
    private Widgets.LoadingButton done_button;
    private Widgets.ContextMenu.MenuItem complete_item;
    private Widgets.ContextMenu.MenuItem delete_item;

    public Gee.HashMap<string, Layouts.ItemBase> items_selected = new Gee.HashMap<string, Layouts.ItemBase> ();
    public Gee.HashMap<string, Objects.Label> labels = new Gee.HashMap<string, Objects.Label> ();
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

        size_label = new Gtk.Label ("0") {
            css_classes = { "font-bold", "card" },
            width_request = 32,
            height_request = 24,
            valign = Gtk.Align.CENTER,
            margin_end = 6
        };

        schedule_button = new Widgets.ScheduleButton () {
            sensitive = false,
            visible_clear_button = false,
            visible_no_date = true
        };

        move_button = new Gtk.Button.from_icon_name ("arrow3-right-symbolic") {
            sensitive = false,
            tooltip_text = _ ("Move to Project"),
        };
        move_button.add_css_class ("flat");

        label_button = new Widgets.LabelPicker.LabelButton () {
            sensitive = false,
            source = project.source
        };

        priority_button = new Widgets.PriorityButton () {
            sensitive = false
        };

        priority_button.set_priority (Constants.PRIORITY_4);

        menu_button = new Gtk.MenuButton () {
            css_classes = { "flat" },
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            icon_name = "view-more-symbolic",
            popover = build_menu_popover ()
        };

        done_button = new Widgets.LoadingButton.with_label (_ ("Done")) {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            margin_start = 12,
            width_request = 100,
            css_classes = { "suggested-action" }
        };

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            margin_top = 9,
            margin_bottom = 9
        };

        content_box.append (size_label);
        content_box.append (schedule_button);
        content_box.append (move_button);
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
                items_selected[row.item.id] = row;
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

        Services.EventBus.get_default ().unselect_all.connect (() => {
            unselect_all ();
        });

        done_button.clicked.connect (() => {
            unselect_all ();
        });

        schedule_button.duedate_changed.connect (() => {
            set_datetime (schedule_button.duedate);
        });

        move_button.clicked.connect (() => {
            Dialogs.ProjectPicker.ProjectPicker dialog;
            if (project.is_inbox_project) {
                dialog = new Dialogs.ProjectPicker.ProjectPicker.for_projects ();
            } else {
                dialog = new Dialogs.ProjectPicker.ProjectPicker.for_source (project.source);
            }

            dialog.project = project;

            dialog.changed.connect ((type, id) => {
                move (Services.Store.instance ().get_project (id));
            });

            dialog.present (Planify._instance.main_window);
        });

        label_button.labels_changed.connect ((labels) => {
            if (labels.size > 0) {
                set_labels (labels);
            }
        });

        priority_button.changed.connect ((priority) => {
            set_priority (priority);
        });
    }

    private void update_items (Gee.ArrayList<Objects.Item> objects) {
        if (project.source_type == SourceType.LOCAL || project.source_type == SourceType.CALDAV) {
            foreach (Objects.Item item in objects) {
                item.update_async ("");
            }            
        } else if (project.source_type == SourceType.TODOIST) {
            done_button.is_loading = true;
            Services.Todoist.get_default ().update_items.begin (objects, (obj, res) => {
                Services.Todoist.get_default ().update_items.end (res);

                foreach (Objects.Item item in objects) {
                    item.update_local ();
                }

                done_button.is_loading = false;
            });
        }

        unselect_all ();
    }

    private void set_datetime (Objects.DueDate duedate) {
        Gee.ArrayList<Objects.Item> objects = new Gee.ArrayList<Objects.Item> ();
        foreach (string key in items_selected.keys) {
            var item = items_selected[key].item;
            item.update_due (duedate);
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

    private void set_labels (Gee.HashMap<string, Objects.Label> new_labels) {
        Gee.ArrayList<Objects.Item> objects = new Gee.ArrayList<Objects.Item> ();

        foreach (string key in items_selected.keys) {
            var item = items_selected[key].item;
            item.check_labels (new_labels);
            objects.add (item);
        }

        update_items (objects);
    }

    private Gtk.Popover build_menu_popover () {
        complete_item = new Widgets.ContextMenu.MenuItem (_ ("Mark as Completed"), "check-round-outline-symbolic");

        delete_item = new Widgets.ContextMenu.MenuItem (_ ("Delete"), "user-trash-symbolic");
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
            foreach (string key in items_selected.keys) {
                items_selected[key].checked_toggled (true, 0);
            }

            unselect_all ();
        });

        delete_item.clicked.connect (() => {
            string title = _ ("Delete To-Do");
            string message = _ ("Are you sure you want to delete this to-do?");
            if (items_selected.size > 0) {
                title = GLib.ngettext (
                    "Delete %d To-Do",
                    "Delete %d To-Dos",
                    items_selected.size
                ).printf (items_selected.size);

                message = GLib.ngettext (
                    "Are you sure you want to delete this %d to-do?",
                    "Are you sure you want to delete these %d to-dos?",
                    items_selected.size
                ).printf (items_selected.size);
            }

            var dialog = new Adw.AlertDialog (title, message);

            dialog.body_use_markup = true;
            dialog.add_response ("cancel", _ ("Cancel"));
            dialog.add_response ("delete", _ ("Delete"));
            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.present (Planify._instance.main_window);

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
            items_selected[key].select_row (false);
        }

        items_selected.clear ();
        labels.clear ();
        size_label.label = "0";
        closed ();
    }

    private void check_select_bar () {
        bool active = items_selected.size > 0;
        foreach (Layouts.ItemBase item_base in items_selected.values) {
            if (item_base.item.checked) {
                active = false;
                break;
            }
        }

        size_label.label = items_selected.size.to_string ();
        schedule_button.sensitive = active;
        move_button.sensitive = active;
        priority_button.sensitive = active;
        label_button.sensitive = active;
        complete_item.sensitive = active;
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

    public void move (Objects.Project project) {
        int count = items_selected.size;
        
        foreach (string key in items_selected.keys) {
            var item = items_selected[key].item;

            string project_id = project.id;

            if (item.project.source_id != project.source_id) {
                Util.get_default ().move_backend_type_item.begin (item, project, "", false);
            } else {
                if (item.project_id != project_id || item.section_id != "") {
                    item.move (project, "", false);
                }
            }
        }

        string message;
        if (count == 1) {
            message = _("Task moved to %s").printf (project.name);
        } else {
            message = GLib.ngettext (
                "Task moved to %s",
                "%d tasks moved to %s",
                count
            ).printf (count, project.name);
        }

        Services.EventBus.get_default ().send_toast (
            Util.get_default ().create_toast (message)
        );

        unselect_all ();
    }
}
