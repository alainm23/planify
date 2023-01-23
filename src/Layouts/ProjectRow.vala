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

public class Layouts.ProjectRow : Gtk.ListBoxRow {
    public Objects.Project project { get; construct; }
    public bool show_subprojects { get; construct; }
    public bool drag_n_drop { get; construct; }
    
    private Widgets.CircularProgressBar circular_progress_bar;
    private Gtk.Label emoji_label;
    private Gtk.Label name_label;
    private Gtk.Label count_label;
    private Gtk.Revealer count_revealer;
    private Gtk.Button arrow_button;
    private Gtk.ListBox listbox;
    public Gtk.Grid handle_grid;
    private Gtk.Revealer listbox_revealer;
    private Gtk.Stack progress_emoji_stack;
    private Gtk.Label due_label;
    private Gtk.Stack menu_stack;

    public Gtk.Box main_content;
    public Gtk.Revealer main_revealer;

    private Gtk.Popover menu_popover = null;
    private Widgets.ContextMenu.MenuItem favorite_item;

    public Gee.HashMap <string, Layouts.ProjectRow> subprojects_hashmap;
    
    public bool on_drag = false;

    private bool has_subprojects {
        get {
            return Util.get_default ().get_children (listbox).length () > 0;
        }
    }

    public bool reveal_child {
        set {
            main_revealer.reveal_child = value;
        }

        get {
            return main_revealer.reveal_child;
        }
    }

    public ProjectRow (Objects.Project project, bool show_subprojects = true, bool drag_n_drop = true) {
        Object (
            project: project,
            show_subprojects: show_subprojects,
            drag_n_drop: drag_n_drop,
            focusable: false
        );
    }

    construct {
        add_css_class ("selectable-item");
        add_css_class ("transition");

        subprojects_hashmap = new Gee.HashMap <string, Layouts.ProjectRow> ();

        circular_progress_bar = new Widgets.CircularProgressBar (10);
        circular_progress_bar.percentage = project.percentage;
        circular_progress_bar.color = project.color;

        emoji_label = new Gtk.Label (project.emoji) {
            halign = Gtk.Align.CENTER
        };

        progress_emoji_stack = new Gtk.Stack ();
        progress_emoji_stack.add_named (circular_progress_bar, "progress");
        progress_emoji_stack.add_named (emoji_label, "emoji");

        name_label = new Gtk.Label (project.name);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        name_label.hexpand = true;
        name_label.halign = Gtk.Align.START;

        count_label = new Gtk.Label (project.project_count.to_string ()) {
            hexpand = true,
            halign = Gtk.Align.CENTER
        };

        count_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        count_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        count_revealer = new Gtk.Revealer () {
            reveal_child = int.parse (count_label.label) > 0,
            transition_type = Gtk.RevealerTransitionType.CROSSFADE
        };

        count_revealer.child = count_label;

        var chevron_right_image = new Widgets.DynamicIcon ();
        chevron_right_image.size = 19;
        chevron_right_image.update_icon_name ("chevron-right"); 

        arrow_button = new Gtk.Button ();
        arrow_button.valign = Gtk.Align.CENTER;
        arrow_button.halign = Gtk.Align.CENTER;
        arrow_button.can_focus = false;
        arrow_button.child = chevron_right_image;
        arrow_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        arrow_button.add_css_class ("transparent");
        arrow_button.add_css_class ("hidden-button");
        arrow_button.add_css_class ("no-padding");
        arrow_button.add_css_class (project.collapsed ? "opened" : "");

        menu_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE,
            halign = Gtk.Align.END
        };

        due_label = new Gtk.Label (null);
        due_label.use_markup = true;
        due_label.valign = Gtk.Align.CENTER;
        due_label.halign = Gtk.Align.CENTER;
        due_label.add_css_class ("pane-due-button");
        due_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        if (project.due_date != "") {
            menu_stack.add_named (due_label, "due_label");
            menu_stack.add_named (count_revealer, "count_revealer");
            menu_stack.add_named (arrow_button, "arrow_button");
        } else {
            menu_stack.add_named (count_revealer, "count_revealer");
            menu_stack.add_named (arrow_button, "arrow_button");
            menu_stack.add_named (due_label, "due_label");
        }

        var projectrow_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_start = 6,
            margin_top = 3,
            margin_end = 3,
            margin_bottom = 3
        };
        
        projectrow_box.append (progress_emoji_stack);
        projectrow_box.append (name_label);
        projectrow_box.append (menu_stack);

        handle_grid = new Gtk.Grid ();
        handle_grid.add_css_class ("transition");
        handle_grid.attach (projectrow_box, 0, 0);

        listbox = new Gtk.ListBox () {
            hexpand = true
        };

        listbox.add_css_class ("bg-transparent");

        var listbox_grid = new Gtk.Grid () {
            margin_start = 12,
            margin_top = 3
        };

        listbox_grid.attach (listbox, 0, 0);

        listbox_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = project.collapsed
        };

        listbox_revealer.child = listbox_grid;

        main_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        main_content.append (handle_grid);
        main_content.append (listbox_revealer);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.child = main_content;

        child = main_revealer;
        update_request ();

        if (drag_n_drop) {
            build_drag_and_drop ();
        }

        if (show_subprojects) {
            add_subprojects ();
        }
        
        Timeout.add (main_revealer.transition_duration, () => {
            if (project.icon_style == ProjectIconStyle.PROGRESS) {
                progress_emoji_stack.visible_child_name = "progress";
            } else {
                progress_emoji_stack.visible_child_name = "emoji";
            }
            
            main_revealer.reveal_child = true;
            
            return GLib.Source.REMOVE;
        });

        var select_gesture = new Gtk.GestureClick ();
        select_gesture.set_button (1);
        handle_grid.add_controller (select_gesture);

        select_gesture.pressed.connect (() => {
            Timeout.add (Constants.DRAG_TIMEOUT, () => {
                if (!on_drag) {
                    Planner.event_bus.pane_selected (PaneType.PROJECT, project.id_string);
                }

                return GLib.Source.REMOVE;
            });
        });

        var menu_gesture = new Gtk.GestureClick ();
        menu_gesture.set_button (3);
        handle_grid.add_controller (menu_gesture);

        menu_gesture.pressed.connect ((n_press, x, y) => {
            build_context_menu (x, y);
        });

        var motion_gesture = new Gtk.EventControllerMotion ();
        handle_grid.add_controller (motion_gesture);

        motion_gesture.enter.connect (() => {
            if (has_subprojects) {
                menu_stack.visible_child_name = "arrow_button";
            }
        });

        motion_gesture.leave.connect (() => {
            if (project.due_date == "") {
                menu_stack.visible_child_name = "count_revealer";
            } else {
                menu_stack.visible_child_name = "due_label";
            }
        });

        var arrow_gesture = new Gtk.GestureClick ();
        arrow_gesture.set_button (1);
        arrow_button.add_controller (arrow_gesture);

        arrow_gesture.pressed.connect (() => {
            arrow_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            listbox_revealer.reveal_child = !listbox_revealer.reveal_child;
            update_listbox_revealer ();
            project.update ();
        });

        Planner.event_bus.pane_selected.connect ((pane_type, id) => {
            if (pane_type == PaneType.PROJECT && project.id_string == id) {
                handle_grid.add_css_class ("selectable-item-selected");
            } else {
                handle_grid.remove_css_class ("selectable-item-selected");
            }
        });

        project.updated.connect (update_request);
        project.deleted.connect (hide_destroy);

        project.project_count_updated.connect (() => {
            count_label.label = project.project_count.to_string ();
            circular_progress_bar.percentage = project.percentage;
            count_revealer.reveal_child = int.parse (count_label.label) > 0;
        });

        project.subproject_added.connect ((subproject) => {
            add_subproject (subproject);
        });

        Planner.event_bus.project_parent_changed.connect ((subproject, old_parent_id) => {
            if (old_parent_id == project.id) {
                if (subprojects_hashmap.has_key (subproject.id_string)) {
                    subprojects_hashmap [subproject.id_string].hide_destroy ();
                    subprojects_hashmap.unset (subproject.id_string);
                }
            }

            if (subproject.parent_id == project.id) {
                add_subproject (subproject);
            }
        });
    }

    private void build_drag_and_drop () {
        var drag_source = new Gtk.DragSource ();
        drag_source.set_actions (Gdk.DragAction.MOVE);
        
        drag_source.prepare.connect ((source, x, y) => {
            return new Gdk.ContentProvider.for_value (this);
        });

        drag_source.drag_begin.connect ((source, drag) => {
            var paintable = new Gtk.WidgetPaintable (handle_grid);
            source.set_icon (paintable, 0, 0);
            drag_begin ();
        });
        
        drag_source.drag_end.connect ((source, drag, delete_data) => {
            drag_end ();
        });

        drag_source.drag_cancel.connect ((source, drag, reason) => {
            drag_end ();
            return false;
        });

        add_controller (drag_source);

        var drop_target = new Gtk.DropTarget (typeof (Layouts.ProjectRow), Gdk.DragAction.MOVE);
        drop_target.preload = true;

        drop_target.on_drop.connect ((value, x, y) => {
            if (Planner.settings.get_enum ("projects-sort-by") == 0) {
                Planner.event_bus.send_notification (
                    Util.get_default ().create_toast (_("Project list order changed to Custom Sort Order."))
                );
            }

            Planner.settings.set_enum ("projects-sort-by", 1);

            var picked_widget = (Layouts.ProjectRow) value;
            var target_widget = this;
            
            Gtk.Allocation alloc;
            target_widget.get_allocation (out alloc);

            picked_widget.drag_end ();
            target_widget.drag_end ();

            if (picked_widget == target_widget || target_widget == null) {
                return false;
            }

            var source_list = (Gtk.ListBox) picked_widget.parent;
            var target_list = (Gtk.ListBox) target_widget.parent;

            source_list.remove (picked_widget);
            
            if (target_widget.get_index () == 0) {
                if (y < (alloc.height / 2)) {
                    target_list.insert (picked_widget, 0);
                } else {
                    target_list.insert (picked_widget, target_widget.get_index () + 1);
                }
            } else {
                target_list.insert (picked_widget, target_widget.get_index () + 1);
            }

            return true;
        });

        add_controller (drop_target);
    }

    public void drag_begin () {
        handle_grid.add_css_class ("card");
        on_drag = true;
        opacity = 0.3;
        listbox_revealer.reveal_child = false;
    }

    public void drag_end () {
        handle_grid.remove_css_class ("card");
        on_drag = false;
        opacity = 1;
        listbox_revealer.reveal_child =  project.collapsed;
    }
    
    private void build_context_menu (double x, double y) {
        if (menu_popover != null) {
            favorite_item.title = project.is_favorite ? ("Remove from favorites") : ("Add to favorites");

            menu_popover.pointing_to = { (int) x, (int) y, 1, 1 };
            menu_popover.popup ();
            return;
        }
        
        favorite_item = new Widgets.ContextMenu.MenuItem (project.is_favorite ? ("Remove from favorites") : ("Add to favorites"), "planner-star");
        var edit_item = new Widgets.ContextMenu.MenuItem (("Edit project"), "planner-edit");
        var move_item = new Widgets.ContextMenu.MenuItem (_("Move to project"), "chevron-right");
        var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete project"), "planner-trash");
        delete_item.add_css_class ("menu-item-danger");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (favorite_item);
        menu_box.append (edit_item);
        menu_box.append (move_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (delete_item);

        menu_popover = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            position = Gtk.PositionType.RIGHT
        };

        menu_popover.set_parent (this);
        menu_popover.pointing_to = { (int) x, (int) y, 1, 1 };

        menu_popover.popup();

        favorite_item.clicked.connect (() => {
            menu_popover.popdown ();

            project.is_favorite = !project.is_favorite;
            Services.Database.get_default ().update_project (project);
            Planner.event_bus.favorite_toggled (project);
            project.update (true);
        });

        edit_item.clicked.connect (() => {
            menu_popover.popdown ();

            var dialog = new Dialogs.Project (project);
            dialog.show ();
        });

        delete_item.clicked.connect (() => {
            menu_popover.popdown ();

            var dialog = new Adw.MessageDialog ((Gtk.Window) Planner.instance.main_window, 
            _("Delete project"), _("Are you sure you want to delete <b>%s</b>?".printf (Util.get_default ().get_dialog_text (project.short_name))));

            dialog.body_use_markup = true;
            dialog.add_response ("cancel", _("Cancel"));
            dialog.add_response ("delete", _("Delete"));
            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.show ();

            dialog.response.connect ((response) => {
                if (response == "delete") {
                    if (project.backend_type == BackendType.TODOIST) {
                        //  remove_button.is_loading = true;
                        Services.Todoist.get_default ().delete.begin (project, (obj, res) => {
                            Services.Todoist.get_default ().delete.end (res);
                            Services.Database.get_default ().delete_project (project);
                            // remove_button.is_loading = false;
                            // message_dialog.hide_destroy ();
                        });
                    } else {
                        Services.Database.get_default ().delete_project (project);
                    }
                }
            });
        });
    }

    private void update_listbox_revealer () {
        if (listbox_revealer.reveal_child) {
            project.collapsed = true;
            arrow_button.add_css_class ("opened");
        } else {
            arrow_button.remove_css_class ("opened");
            project.collapsed = false;
        }
    }

    public void update_request () {
        if (project.icon_style == ProjectIconStyle.PROGRESS) {
            progress_emoji_stack.visible_child_name = "progress";
        } else {
            progress_emoji_stack.visible_child_name = "emoji";
        }
        
        circular_progress_bar.color = project.color;
        emoji_label.label = project.emoji;
        name_label.label = project.name;

        check_due_date ();
    }

    private void check_due_date () {
        if (project.due_date != "") {
            var datetime = Util.get_default ().get_date_from_string (project.due_date);
            due_label.label = Util.get_default ().get_relative_date_from_date (datetime);
        }

        // Workaround to fix small bug when collapsing/expanding project - this causes save and would
        // hide currently hovered arrow
        if (menu_stack.visible_child_name != "arrow_button") {
            menu_stack.visible_child_name = project.due_date == "" ? "count_revealer" : "due_label";
        }
    }

    private void add_subprojects () {
        foreach (Objects.Project subproject in project.subprojects) {
            add_subproject (subproject);
        }
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }

    public void add_subproject (Objects.Project project) {
        if (!subprojects_hashmap.has_key (project.id_string) && show_subprojects) {
            subprojects_hashmap [project.id_string] = new Layouts.ProjectRow (project);
            listbox.append (subprojects_hashmap [project.id_string]);
        }
    }
}