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

public class Layouts.ProjectRow : Gtk.ListBoxRow {
    public Objects.Project project { get; construct; }
    public bool show_subprojects { get; construct; }
    public bool drag_n_drop { get; construct; }
    
    private Widgets.IconColorProject icon_project;
    private Gtk.Label name_label;
    private Gtk.Label count_label;
    private Gtk.Revealer count_revealer;
    private Gtk.Button arrow_button;
    private Gtk.Revealer arrow_revealer;
    private Gtk.ListBox listbox;
    private Adw.Bin handle_grid;
    private Gtk.Revealer listbox_revealer;
    private Gtk.Stack progress_emoji_stack;
    private Gtk.Label due_label;
    private Gtk.Stack menu_stack;
    private Gtk.Revealer loading_revealer;

    public Gtk.Box main_content;
    public Gtk.Revealer main_revealer;

    private Gtk.Popover menu_popover = null;
    private Widgets.ContextMenu.MenuItem favorite_item;

    private Gtk.Grid motion_top_grid;
    private Gtk.Revealer motion_top_revealer;

    public Gee.HashMap <string, Layouts.ProjectRow> subprojects_hashmap = new Gee.HashMap <string, Layouts.ProjectRow> ();
    
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

    public bool is_loading {
        set {
            loading_revealer.reveal_child = value;
        }

        get {
            return loading_revealer.reveal_child;
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
        css_classes = { "selectable-item", "transition" };

        motion_top_grid = new Gtk.Grid () {
            height_request = 27,
            css_classes = { "drop-area", "drop-target" },
            margin_bottom = 3
        };

        motion_top_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = motion_top_grid
        };

        icon_project = new Widgets.IconColorProject (12) {
            margin_top = 3,
            margin_bottom = 3,
            margin_start = 3,
            margin_end = 3
        };

        icon_project.project = project;

        name_label = new Gtk.Label (project.name) {
            valign = Gtk.Align.CENTER,
            ellipsize = Pango.EllipsizeMode.END,
            hexpand = true,
            halign = Gtk.Align.START,
        };

        count_label = new Gtk.Label (null) {
            hexpand = true,
            margin_end = 6,
            halign = Gtk.Align.CENTER,
            css_classes = { "small-label", "dim-label" }
        };

        count_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = count_label
        };

        arrow_button = new Gtk.Button.from_icon_name ("pan-end-symbolic") {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            css_classes = { "flat", "transparent", "hidden-button", "no-padding" },
            margin_start = 6
        };

        arrow_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            child = arrow_button
        };

        if (project.collapsed) {
            arrow_button.add_css_class ("opened");
        }

        menu_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        due_label = new Gtk.Label (null) {
            use_markup = true,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            css_classes = { "pane-due-button", "small-label" }
        };

        menu_stack.add_named (due_label, "due_label");
        menu_stack.add_named (count_revealer, "count_revealer");

        var end_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            halign = END
        };
        end_box.append (menu_stack);
        end_box.append (arrow_revealer);

        var loading_spinner = new Gtk.Spinner () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            spinning = true
        };

        loading_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            child = loading_spinner
        };

        var projectrow_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_start = 3,
            margin_top = 3,
            margin_end = 3,
            margin_bottom = 3
        };
        
        projectrow_box.append (icon_project);
        projectrow_box.append (name_label);
        projectrow_box.append (end_box);
        projectrow_box.append (loading_revealer);

        handle_grid = new Adw.Bin () {
            css_classes = { "transition", "drop-target" },
            child = projectrow_box
        };

        listbox = new Gtk.ListBox () {
            hexpand = true,
            css_classes = { "bg-transparent" }
        };

        var listbox_grid = new Adw.Bin () {
            margin_start = 12,
            child = listbox
        };

        listbox_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = project.collapsed,
            child = listbox_grid
        };

        main_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_content.append (handle_grid);
        main_content.append (listbox_revealer);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.append (motion_top_revealer);
        box.append (main_content);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = box
        };

        child = main_revealer;
        update_request ();
        update_count_label (project.project_count);
        Services.Settings.get_default ().settings.bind ("show-tasks-count", count_revealer, "reveal_child", GLib.SettingsBindFlags.DEFAULT);
        
        if (drag_n_drop) {
            build_drag_and_drop.begin ();
        }

        if (show_subprojects) {
            add_subprojects ();
        }
        
        Timeout.add (main_revealer.transition_duration, () => {
            progress_emoji_stack.visible_child_name = project.icon_style == ProjectIconStyle.PROGRESS ? "progress" : "emoji";            
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        var select_gesture = new Gtk.GestureClick ();
        select_gesture.set_button (1);
        handle_grid.add_controller (select_gesture);

        select_gesture.pressed.connect (() => {
            Timeout.add (Constants.DRAG_TIMEOUT, () => {
                if (!on_drag) {
                    Services.EventBus.get_default ().pane_selected (PaneType.PROJECT, project.id_string);
                }

                return GLib.Source.REMOVE;
            });
        });

        var menu_gesture = new Gtk.GestureClick () {
            button = 3
        };
        handle_grid.add_controller (menu_gesture);
        menu_gesture.pressed.connect ((n_press, x, y) => {
            build_context_menu (x, y);
        });

        var motion_gesture = new Gtk.EventControllerMotion ();
        handle_grid.add_controller (motion_gesture);

        motion_gesture.enter.connect (() => {
            arrow_revealer.reveal_child = has_subprojects;
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
            project.update_local ();
        });

        Services.EventBus.get_default ().pane_selected.connect ((pane_type, id) => {
            if (pane_type == PaneType.PROJECT && project.id_string == id) {
                add_css_class ("selected");
            } else {
                remove_css_class ("selected");
            }
        });

        project.updated.connect (update_request);
        project.deleted.connect (hide_destroy);

        project.project_count_updated.connect (() => {
            update_count_label (project.project_count);
            icon_project.update_request ();
        });

        project.subproject_added.connect ((subproject) => {
            add_subproject (subproject);
        });

        Services.EventBus.get_default ().project_parent_changed.connect ((subproject, old_parent_id, collapsed) => {
            if (old_parent_id == project.id) {
                if (subprojects_hashmap.has_key (subproject.id_string)) {
                    subprojects_hashmap [subproject.id_string].hide_destroy ();
                    subprojects_hashmap.unset (subproject.id_string);
                }
            }

            if (subproject.parent_id == project.id) {
                add_subproject (subproject);

                if (collapsed) {
                    project.collapsed = true;
                    arrow_button.add_css_class ("opened");
                }
            }
        });
    }

    private void update_count_label (int count) {
        count_label.label = count <= 0 ? "" : count.to_string ();
    }

    private async void build_drag_and_drop () {
        // Motion Drop
        build_drop_motion ();

        // Drag Souyrce
        build_drag_source ();

        // Magic Button
        var drop_magic_button_target = new Gtk.DropTarget (typeof (Widgets.MagicButton), Gdk.DragAction.MOVE);
        handle_grid.add_controller (drop_magic_button_target);
        drop_magic_button_target.drop.connect ((value, x, y) => {
            var dialog = new Dialogs.Project.new (project.backend_type, false, project.id);
            dialog.show ();
            return true;
        });

        // Drop
        build_drop_project_target ();
        build_drop_item_target ();

        // Drop Order
        var drop_order_target = new Gtk.DropTarget (typeof (Layouts.ProjectRow), Gdk.DragAction.MOVE);
        motion_top_grid.add_controller (drop_order_target);
        drop_order_target.drop.connect ((value, x, y) => {
            var picked_widget = (Layouts.ProjectRow) value;
            var target_widget = this;

            var picked_project = picked_widget.project;
            var target_project = target_widget.project;
    
            if (picked_widget == target_widget || target_widget == null) {
                return false;
            }

            var projects_sort = Services.Settings.get_default ().settings.get_enum ("projects-sort-by");
            if (projects_sort != 0) {
                Services.Settings.get_default ().settings.set_enum ("projects-sort-by", 0);
                Services.EventBus.get_default ().send_notification (
                    Util.get_default ().create_toast (_("Projects sort changed to 'Custom sort order'"))
                );
            }
    
            var source_list = (Gtk.ListBox) picked_widget.parent;
            var target_list = (Gtk.ListBox) target_widget.parent;

            if (picked_project.parent_id != target_project.parent_id) {
                picked_project.parent_id = target_project.parent_id;

                if (picked_project.backend_type == BackendType.TODOIST) {
                    Services.Todoist.get_default ().move_project_section.begin (picked_project, target_project.parent_id, (obj, res) => {
                        if (Services.Todoist.get_default ().move_project_section.end (res).status) {
                            Services.Database.get_default ().update_project (picked_project);
                        }
                    });
                } else if (picked_project.backend_type == BackendType.LOCAL) {
                    Services.Database.get_default ().update_project (picked_project);
                }
            }

            source_list.remove (picked_widget);
            target_list.insert (picked_widget, target_widget.get_index ());
            update_projects_child_order (target_list);

            return true;
        });
    }

    private void build_drop_motion () {
        var drop_motion_ctrl = new Gtk.DropControllerMotion ();
        add_controller (drop_motion_ctrl);
        drop_motion_ctrl.motion.connect ((x, y) => {
            var drop = drop_motion_ctrl.get_drop ();
            GLib.Value value = Value (typeof (Gtk.Widget));

            try {
                drop.drag.content.get_value (ref value);

                if (value.dup_object () is Layouts.ProjectRow) {
                    var picked_widget = (Layouts.ProjectRow) value;
                    if (picked_widget.project.backend_type == project.backend_type) {
                        motion_top_revealer.reveal_child = drop_motion_ctrl.contains_pointer;
                    }
                }
            } catch (Error e) {
                debug (e.message);
            }
        });

        drop_motion_ctrl.leave.connect (() => {
            motion_top_revealer.reveal_child = false;
        });
    }

    private void build_drag_source () {
        var drag_source = new Gtk.DragSource ();
        drag_source.set_actions (Gdk.DragAction.MOVE);
        handle_grid.add_controller (drag_source);

        drag_source.prepare.connect ((source, x, y) => {
            return new Gdk.ContentProvider.for_value (this);
        });

        drag_source.drag_begin.connect ((source, drag) => {
            var paintable = new Gtk.WidgetPaintable (handle_grid);
            source.set_icon (paintable, 0, 0);
            drag_begin ();
        });
        
        drag_source.drag_cancel.connect ((source, drag, reason) => {
            drag_end ();
            return true;
        });

        drag_source.drag_end.connect ((source, drag, delete_data) => {
            drag_end ();
        });
    }

    private void build_drop_project_target () {
        var drop_target = new Gtk.DropTarget (typeof (Layouts.ProjectRow), Gdk.DragAction.MOVE);
        handle_grid.add_controller (drop_target);
        drop_target.accept.connect ((drop) => {
            GLib.Value value = Value (typeof (Gtk.Widget));

            try {
                drop.drag.content.get_value (ref value);
            } catch (Error e) {
                debug (e.message);
            }

            if (value.dup_object () is Layouts.ProjectRow) {
                var picked_widget = (Layouts.ProjectRow) value;
                if (picked_widget.project.backend_type == project.backend_type) {
                    return true;
                }
            }

            return false;
        });

        drop_target.drop.connect ((value, x, y) => {
            var picked_widget = (Layouts.ProjectRow) value;
            var target_widget = this;

            var picked_project = picked_widget.project;
            var target_project = target_widget.project;

            if (picked_widget == target_widget || target_widget == null) {
                return false;
            }

            string old_parent_id = picked_project.parent_id;
            picked_project.parent_id = target_project.id;
            
            if (picked_project.backend_type == BackendType.TODOIST) {
                Services.Todoist.get_default ().move_project_section.begin (picked_project, target_project.id, (obj, res) => {
                    if (Services.Todoist.get_default ().move_project_section.end (res).status) {
                        Services.Database.get_default ().update_project (picked_project);
                        Services.EventBus.get_default ().project_parent_changed (picked_project, old_parent_id, true);
                    }
                });
            } else if (picked_project.backend_type == BackendType.LOCAL) {
                Services.Database.get_default ().update_project (picked_project);
                Services.EventBus.get_default ().project_parent_changed (picked_project, old_parent_id, true);
            }

            return true;
        });
    }

    private void build_drop_item_target () {
        var drop_row_target = new Gtk.DropTarget (typeof (Layouts.ItemRow), Gdk.DragAction.MOVE);
        handle_grid.add_controller (drop_row_target);

        drop_row_target.accept.connect ((drop) => {
            GLib.Value value = Value (typeof (Gtk.Widget));

            try {
                drop.drag.content.get_value (ref value);
            } catch (Error e) {
                debug (e.message);
            }

            if (value.dup_object () is Layouts.ItemRow) {
                var picked_widget = (Layouts.ItemRow) value;
                if (picked_widget.item.project.backend_type == project.backend_type) {
                    return true;
                }
            }

            return false;
        });

        drop_row_target.drop.connect ((value, x, y) => {
            var picked_widget = (Layouts.ItemRow) value;
            var target_widget = this;
            picked_widget.item.move (target_widget.project, "");
            return true;
        });

        var drop_board_target = new Gtk.DropTarget (typeof (Layouts.ItemBoard), Gdk.DragAction.MOVE);
        handle_grid.add_controller (drop_board_target);

        drop_board_target.accept.connect ((drop) => {
            GLib.Value value = Value (typeof (Gtk.Widget));

            try {
                drop.drag.content.get_value (ref value);
            } catch (Error e) {
                debug (e.message);
            }

            if (value.dup_object () is Layouts.ItemBoard) {
                var picked_widget = (Layouts.ItemBoard) value;
                if (picked_widget.item.project.backend_type == project.backend_type) {
                    return true;
                }
            }

            return false;
        });

        drop_board_target.drop.connect ((value, x, y) => {
            var picked_widget = (Layouts.ItemBoard) value;
            var target_widget = this;
            picked_widget.item.move (target_widget.project, "");
            return true;
        });
    }

    public void drag_begin () {
        handle_grid.add_css_class ("drop-begin");
        on_drag = true;
        main_revealer.reveal_child = false;
        listbox_revealer.reveal_child = false;
    }

    public void drag_end () {
        handle_grid.remove_css_class ("drop-begin");
        on_drag = false;
        main_revealer.reveal_child = true;
        listbox_revealer.reveal_child = project.collapsed;
    }

    private void update_projects_child_order (Gtk.ListBox listbox) {
        unowned Layouts.ProjectRow? project_row = null;
        var row_index = 0;

        do {
            project_row = (Layouts.ProjectRow) listbox.get_row_at_index (row_index);

            if (project_row != null) {
                project_row.project.child_order = row_index;
                Services.Database.get_default ().update_project (project_row.project);
            }

            row_index++;
        } while (project_row != null);
    }
    
    private void build_context_menu (double x, double y) {
        if (menu_popover != null) {
            favorite_item.title = project.is_favorite ? _("Remove From Favorites") : _("Add to Favorites");
            menu_popover.pointing_to = { ((int) x), (int) y, 1, 1 };
            menu_popover.popup ();
            return;
        }
        
        favorite_item = new Widgets.ContextMenu.MenuItem (project.is_favorite ? _("Remove From Favorites") : _("Add to Favorites"), "star-outline-thick-symbolic");
        var edit_item = new Widgets.ContextMenu.MenuItem (_("Edit Project"), "edit-symbolic");
        var refresh_item = new Widgets.ContextMenu.MenuItem (_("Refresh"), "update-symbolic");
        var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete Project"), "user-trash-symbolic");
        delete_item.add_css_class ("menu-item-danger");

        var share_markdown_item = new Widgets.ContextMenu.MenuItem (_("Share"), "share-alt-symbolic");
        var share_email_item = new Widgets.ContextMenu.MenuItem (_("Send by E-Mail"), "mail-symbolic");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (favorite_item);

        if (!project.is_deck) {
            menu_box.append (edit_item);
        }
        
        if (project.backend_type == BackendType.CALDAV) {
            menu_box.append (refresh_item);
        }
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (share_markdown_item);
        menu_box.append (share_email_item);

        if (project.id != Services.Settings.get_default ().settings.get_string ("todoist-inbox-project-id") &&
        project.id != Services.Settings.get_default ().settings.get_string ("local-inbox-project-id")) {
            if (!project.is_deck) {
                menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
                menu_box.append (delete_item);
            }
        }

        menu_popover = new Gtk.Popover () {
            has_arrow = false,
            halign = Gtk.Align.START,
            child = menu_box,
            width_request = 250
        };

        menu_popover.set_parent (this);
        menu_popover.pointing_to = { ((int) x), (int) y, 1, 1 };
        menu_popover.popup ();

        favorite_item.clicked.connect (() => {
            menu_popover.popdown ();

            project.is_favorite = !project.is_favorite;
            Services.Database.get_default ().update_project (project);
            Services.EventBus.get_default ().favorite_toggled (project);
            project.update ();
        });

        edit_item.clicked.connect (() => {
            menu_popover.popdown ();

            var dialog = new Dialogs.Project (project);
            dialog.show ();
        });

        refresh_item.clicked.connect (() => {
            menu_popover.popdown ();

            is_loading = true;
            Services.CalDAV.Core.get_default ().sync_tasklist.begin (project, (obj, res) => {
                Services.CalDAV.Core.get_default ().sync_tasklist.end (res);
                is_loading = false;
            });
        });

        delete_item.clicked.connect (() => {
            menu_popover.popdown ();
            
            var dialog = new Adw.MessageDialog (
                (Gtk.Window) Planify.instance.main_window, 
                _("Delete Project %s?".printf (project.name)),
                _("This can not be undone")
            );

            var spinner = new Gtk.Spinner () {
                margin_top = 6,
                valign = Gtk.Align.CENTER,
                halign = Gtk.Align.CENTER,
                spinning = true
            };

            var spinner_revealer = new Gtk.Revealer () {
                child = spinner
            };

            dialog.extra_child = spinner_revealer;
            dialog.add_response ("cancel", _("Cancel"));
            dialog.add_response ("delete", _("Delete"));
            dialog.close_response = "cancel";
            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.show ();

            dialog.response.connect ((response) => {
                if (response == "delete") {
                    if (project.backend_type == BackendType.LOCAL) {
                        Services.Database.get_default ().delete_project (project);
                    } else if (project.backend_type == BackendType.TODOIST) {
                        dialog.set_response_enabled ("cancel", false);
                        dialog.set_response_enabled ("delete", false);
                        spinner_revealer.reveal_child = true;

                        Services.Todoist.get_default ().delete.begin (project, (obj, res) => {
                            if (Services.Todoist.get_default ().delete.end (res).status) {
                                Services.Database.get_default ().delete_project (project);
                            }
                        });
                    } else if (project.backend_type == BackendType.CALDAV) {
                        dialog.set_response_enabled ("cancel", false);
                        dialog.set_response_enabled ("delete", false);
                        spinner_revealer.reveal_child = true;

                        Services.CalDAV.Core.get_default ().delete_tasklist.begin (project, (obj, res) => {
                            if (Services.CalDAV.Core.get_default ().delete_tasklist.end (res)) {
                                Services.Database.get_default ().delete_project (project);
                            }
                        });
                    }
                }
            });
        });

        share_markdown_item.clicked.connect (() => {
            menu_popover.popdown ();
            project.share_markdown ();
        });

        share_email_item.clicked.connect (() => {
            menu_popover.popdown ();
            project.share_mail ();
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
        icon_project.update_request ();
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
        menu_stack.visible_child_name = project.due_date == "" ? "count_revealer" : "due_label";
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
