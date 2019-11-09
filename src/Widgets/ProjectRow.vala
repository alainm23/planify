/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Widgets.ProjectRow : Gtk.ListBoxRow { 
    public Objects.Project project { get; construct; }

    private Gtk.Grid grid_color;
    private Gtk.Label name_label;
    private Gtk.Label count_label;
    private Gtk.Revealer count_revealer;
  
    private Gtk.Menu work_areas;
    private Gtk.Menu menu = null;
    public Gtk.Box handle_box;
    private Gtk.EventBox handle;

    private Gtk.Revealer motion_revealer;
    public Gtk.Revealer main_revealer;

    private int count = 0;

    private const Gtk.TargetEntry[] targetEntries = {
        {"PROJECTROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] targetEntriesItem = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public bool reveal_drag_motion {
        set {   
            motion_revealer.reveal_child = value;
        }
        get {
            return motion_revealer.reveal_child;
        }
    }

    public ProjectRow (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        //count = Application.database.get_count_items_by_project (project.id);

        get_style_context ().add_class ("pane-row");
        get_style_context ().add_class ("project-row");

        var project_progress = new Widgets.ProjectProgress ();
        project_progress.margin_start = 6;
        project_progress.line_cap =  Cairo.LineCap.ROUND;
        project_progress.radius_filled = true;
        project_progress.line_width = 2;
        project_progress.valign = Gtk.Align.CENTER;
        project_progress.halign = Gtk.Align.CENTER;
        project_progress.margin_top = 1;
        project_progress.progress_fill_color = Application.utils.get_color (project.color);
        
        project_progress.radius_fill_color = "#d3d3d3";
        if (Application.settings.get_boolean ("prefer-dark-style")) {
            project_progress.radius_fill_color = "#666666";
        }

        Application.settings.changed.connect ((key) => {
            if (key == "prefer-dark-style") {
                if (Application.settings.get_boolean ("prefer-dark-style")) {
                    project_progress.radius_fill_color = "#666666";
                } else {
                    project_progress.radius_fill_color = "#d3d3d3";
                }
            }
        });

        grid_color = new Gtk.Grid ();
        grid_color.margin_start = 8;
		grid_color.get_style_context ().add_class ("project-%s".printf (project.id.to_string ()));
        grid_color.set_size_request (13, 13);
        grid_color.valign = Gtk.Align.CENTER;
        grid_color.halign = Gtk.Align.CENTER;

        name_label = new Gtk.Label (project.name);
        name_label.margin_top = 6;
        name_label.margin_bottom = 6;
        name_label.margin_start = 6;
        name_label.tooltip_text = project.name;
        name_label.get_style_context ().add_class ("pane-item");
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        name_label.use_markup = true;

        count_label = new Gtk.Label (null);
        count_label.margin_start = 3;
        count_label.valign = Gtk.Align.CENTER;
        count_label.margin_top = 3;
        count_label.opacity = 0.7;
        count_label.use_markup = true;

        count_revealer = new Gtk.Revealer ();
        count_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        count_revealer.add (count_label);

        var source_icon = new Gtk.Image ();
        source_icon.valign = Gtk.Align.CENTER;
        source_icon.get_style_context ().add_class ("dim-label");
        source_icon.get_style_context ().add_class ("text-color");
        source_icon.pixel_size = 14;
        source_icon.margin_top = 3;
        source_icon.margin_end = 12;

        var source_revealer = new Gtk.Revealer ();
        source_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        source_revealer.add (source_icon);

        if (project.is_todoist == 0) {
            source_icon.tooltip_text = _("Local Project");
            source_icon.icon_name = "planner-offline-symbolic";
        } else {
            source_icon.icon_name = "planner-online-symbolic";
            source_icon.tooltip_text = _("Todoist Project");
        }
        
        handle_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        handle_box.hexpand = true;
        handle_box.pack_start (project_progress, false, false, 0);
        handle_box.pack_start (name_label, false, false, 0);
        handle_box.pack_start (count_revealer, false, false, 0);
        handle_box.pack_end (source_revealer, false, false, 0);
        
        var motion_grid = new Gtk.Grid ();
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;
            
        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        var grid = new Gtk.Grid ();
        grid.margin_start = 6;
        grid.orientation = Gtk.Orientation.VERTICAL;

        grid.add (handle_box);
        grid.add (motion_revealer);
        
        handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.expand = true;
        handle.above_child = false;
        handle.add (grid);

        add (handle);

        Timeout.add (125, () => {
            Application.database.get_project_count (project);
            return false;
        });
        

        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, targetEntries, Gdk.DragAction.MOVE);
        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);

        build_drag_and_drop (false);

        button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                activate_menu ();
                return true;
            }

            return false;
        });

        handle.event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                open_edit_dialog ();
            }

            return false;
        });

        handle.enter_notify_event.connect ((event) => {
            source_revealer.reveal_child = true;
            return true;
        });

        handle.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            source_revealer.reveal_child = false;

            return true;
        });

        Application.database.project_updated.connect ((p) => {
            if (project != null && p.id == project.id) {
                name_label.label = p.name;
                project_progress.progress_fill_color = Application.utils.get_color (p.color);
            }
        });

        Application.database.project_deleted.connect ((p) => {
            if (project != null && p.id == project.id) {
                destroy ();
            }
        });

        Application.todoist.project_deleted_started.connect ((id) => {
            if (project.id == id) {
                sensitive = false;
            }
        });

        Application.todoist.project_deleted_error.connect ((id, http_code, error_message) => {
            if (project.id == id) {
                sensitive = true;
            }
        });

        Application.utils.drag_item_activated.connect ((active) => {
            build_drag_and_drop (active);
        });

        Application.database.item_added.connect ((item) => {
            if (project.id == item.project_id) {
                Application.database.get_project_count (project);
            }
        });

        Application.database.item_deleted.connect ((item) => {
            if (project.id == item.project_id && item.checked == 0) {
                Application.database.get_project_count (project);
            }
        });

        Application.database.item_completed.connect ((item) => {
            if (project.id == item.project_id) {
                Application.database.get_project_count (project);
            }
        });
        
        Application.database.item_moved.connect ((item) => {
            Idle.add (() => {
                Application.database.get_project_count (project);

                return false;
            });
        });

        Application.database.subtract_task_counter.connect ((id) => {
            Idle.add (() => {
                Application.database.get_project_count (project);

                return false;
            });
        });

        Application.database.update_project_count.connect ((id, items_0, items_1) => {
            if (project.id == id) {
                project_progress.percentage = ((double) items_1 / ((double) items_0 + (double) items_1));
                count = items_0;
                check_count_label ();
            }
        });
    }

    private void update_count () {

    }

    private void check_count_label () {
        count_label.label = "<small>%i</small>".printf (count);

        if (count <= 0) {
            count_revealer.reveal_child = false;
        } else {
            count_revealer.reveal_child = true;
        }
    }

    private void build_drag_and_drop (bool value) {
        if (value) {    
            drag_motion.disconnect (on_drag_motion);
            drag_leave.disconnect (on_drag_leave);
            drag_end.disconnect (clear_indicator);

            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, targetEntriesItem, Gdk.DragAction.MOVE);
            drag_data_received.connect (on_drag_item_received);
            drag_motion.connect (on_drag_item_motion);
            drag_leave.connect (on_drag_item_leave);

        } else {
            drag_data_received.disconnect (on_drag_item_received);
            drag_motion.disconnect (on_drag_item_motion);
            drag_leave.disconnect (on_drag_item_leave);

            Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION, targetEntries, Gdk.DragAction.MOVE);
            drag_motion.connect (on_drag_motion);
            drag_leave.connect (on_drag_leave);
            drag_end.connect (clear_indicator);
        }
    }

    private void on_drag_item_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type) {
        Widgets.ItemRow source;
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        if (source.item.is_todoist == 0) {
            if (Application.database.move_item (source.item, project.id)) {
                source.get_parent ().remove (source);
            }
        } else {
            Application.todoist.move_item (source.item, project.id);
        }
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = (ProjectRow) widget;

        Gtk.Allocation alloc;
        row.get_allocation (out alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr = new Cairo.Context (surface);
        cr.set_source_rgba (0, 0, 0, 0.3);
        cr.set_line_width (1);

        cr.move_to (0, 0);
        cr.line_to (alloc.width, 0);
        cr.line_to (alloc.width, alloc.height);
        cr.line_to (0, alloc.height);
        cr.line_to (0, 0);
        cr.stroke ();
  
        cr.set_source_rgba (255, 255, 255, 0.5);
        cr.rectangle (0, 0, alloc.width, alloc.height);
        cr.fill ();

        row.handle_box.draw (cr);

        Gtk.drag_set_icon_surface (context, surface);

        row.visible = false;
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context, Gtk.SelectionData selection_data, uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (ProjectRow))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("PROJECTROW"), 32, data
        );
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        reveal_drag_motion = true;   
        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        reveal_drag_motion = false;
    }

    public bool on_drag_item_motion (Gdk.DragContext context, int x, int y, uint time) {
        get_style_context ().add_class ("highlight");  
        return true;
    }

    public void on_drag_item_leave (Gdk.DragContext context, uint time) {
        get_style_context ().remove_class ("highlight");
    }

    public void clear_indicator (Gdk.DragContext context) {
        reveal_drag_motion = false;

        visible = true;
        show_all ();
    }

    private void activate_menu () {
        if (menu == null) {
            build_context_menu (project);
        } 

        foreach (var child in work_areas.get_children ()) {
            child.destroy ();
        }

        Widgets.ImageMenuItem item;
        if (project.area_id != 0) {
            item = new Widgets.ImageMenuItem (_("No Area"), "window-close-symbolic");
            item.activate.connect (() => {
                if (Application.database.move_project (project, 0)) {
                    destroy ();
                }
            });

            work_areas.add (item);
        }

        foreach (Objects.Area area in Application.database.get_all_areas ()) {
            if (area.id != project.area_id) {
                item = new Widgets.ImageMenuItem (area.name, "planner-work-area-symbolic");
                item.activate.connect (() => {
                    if (Application.database.move_project (project, area.id)) {
                        destroy ();
                    }
                });

                work_areas.add (item);
            }
        }

        work_areas.show_all ();
        menu.popup_at_pointer (null);
    }
 
    private void build_context_menu (Objects.Project project) {
        menu = new Gtk.Menu ();
        menu.width_request = 200;

        var project_menu = new Widgets.ImageMenuItem (project.name, "planner-project-symbolic");

        var edit_menu = new Widgets.ImageMenuItem (_("Edit project"), "edit-symbolic");

        var move_menu = new Widgets.ImageMenuItem (_("Move project"), "planner-work-area-symbolic");
        work_areas = new Gtk.Menu ();
        move_menu.set_submenu (work_areas);

        var export_menu = new Widgets.ImageMenuItem (_("Export"), "document-export-symbolic");

        var share_menu = new Widgets.ImageMenuItem (_("Share"), "emblem-shared-symbolic");

        var archive_menu = new Widgets.ImageMenuItem (_("Archive"), "planner-archive-symbolic");

        var delete_menu = new Widgets.ImageMenuItem (_("Delete project"), "user-trash-symbolic");

        
        menu.add (project_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        //menu.add (finalize_menu);
        menu.add (edit_menu);
        menu.add (move_menu);
        //menu.add (new Gtk.SeparatorMenuItem ());
        //menu.add (export_menu);
        //menu.add (share_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        //menu.add (archive_menu);
        menu.add (delete_menu);

        menu.show_all ();

        edit_menu.activate.connect (() => {
            open_edit_dialog ();
        }); 

        delete_menu.activate.connect (() => {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Delete project"),
                _("Are you sure you want to delete <b>%s</b>?".printf (project.name)),
                "user-trash-full",
            Gtk.ButtonsType.CANCEL);

            var remove_button = new Gtk.Button.with_label (_("Delete"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                if (project.is_todoist == 0) {
                    if (Application.database.delete_project (project)) {
                        destroy ();
                    }  
                } else {
                    Application.todoist.delete_project (project);
                }
            }

            message_dialog.destroy ();
        });
    }

    private void open_edit_dialog () {
        var edit_dialog = new Dialogs.ProjectSettings (project);
        edit_dialog.destroy.connect (Gtk.main_quit);
        edit_dialog.show_all ();
    }
}