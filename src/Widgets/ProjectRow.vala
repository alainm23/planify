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
    private Gtk.ToggleButton menu_button;
    private Gtk.PopoverMenu menu_popover = null;
    private Gtk.Grid areas_grid;
    private Gtk.Grid colors_grid;
    
    public Gtk.Box handle_box;
    private Gtk.EventBox handle;

    private Gtk.Revealer motion_revealer;
    public Gtk.Revealer main_revealer;

    private int count = 0;
    private uint timeout_id = 0;

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
        margin_start = margin_end = 6;
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
        project_progress.progress_fill_color = Planner.utils.get_color (project.color);
        
        project_progress.radius_fill_color = "#a7b2cb";
        if (Planner.settings.get_boolean ("prefer-dark-style")) {
            project_progress.radius_fill_color = "#666666";
        }

        Planner.settings.changed.connect ((key) => {
            if (key == "prefer-dark-style") {
                if (Planner.settings.get_boolean ("prefer-dark-style")) {
                    project_progress.radius_fill_color = "#666666";
                } else {
                    project_progress.radius_fill_color = "#a7b2cb";
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

        count_label = new Gtk.Label (null);
        count_label.valign = Gtk.Align.CENTER;
        count_label.margin_top = 3;
        count_label.opacity = 0.7;
        count_label.use_markup = true;
        count_label.width_chars = 4;

        count_revealer = new Gtk.Revealer ();
        count_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        count_revealer.add (count_label);

        var menu_icon = new Gtk.Image ();
        menu_icon.gicon = new ThemedIcon ("view-more-symbolic");
        menu_icon.pixel_size = 14;

        menu_button = new Gtk.ToggleButton ();
        menu_button.valign = Gtk.Align.CENTER;
        menu_button.halign = Gtk.Align.CENTER;
        menu_button.can_focus = false;
        menu_button.image = menu_icon;
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        menu_button.get_style_context ().add_class ("dim-label");
        menu_button.get_style_context ().add_class ("menu-button");

        var menu_stack = new Gtk.Stack ();
        menu_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        menu_stack.add_named (count_revealer, "count_revealer");
        menu_stack.add_named (menu_button, "menu_button");

        var source_icon = new Gtk.Image ();
        source_icon.valign = Gtk.Align.CENTER;
        source_icon.get_style_context ().add_class ("dim-label");
        //source_icon.get_style_context ().add_class ("text-color");
        source_icon.pixel_size = 14;
        source_icon.margin_top = 3;
        source_icon.margin_start = 3;

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
        handle_box.pack_start (source_icon, false, false, 0);
        handle_box.pack_end (menu_stack, false, false, 0);
        
        var motion_grid = new Gtk.Grid ();
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;
            
        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        var grid = new Gtk.Grid ();
        grid.margin_start = 3;
        grid.orientation = Gtk.Orientation.VERTICAL;

        grid.add (handle_box);
        grid.add (motion_revealer);
        
        handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.expand = true;
        handle.above_child = false;
        handle.add (grid);

        main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = true;
        main_revealer.transition_duration = 125;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (handle);

        add (main_revealer);

        Timeout.add (125, () => {
            Planner.database.get_project_count (project.id);
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

        handle.enter_notify_event.connect ((event) => {
            menu_stack.visible_child_name = "menu_button";

            return true;
        });

        handle.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            if (menu_popover.visible == false) {
                menu_stack.visible_child_name = "count_revealer";
            }
            
            return true;
        });

        menu_button.toggled.connect (() => {
            if (menu_button.active) {
                activate_menu ();
            }
        });

        Planner.database.project_updated.connect ((p) => {
            if (project != null && p.id == project.id) {
                name_label.label = p.name;
                project_progress.progress_fill_color = Planner.utils.get_color (p.color);
            }
        });

        Planner.database.project_deleted.connect ((id) => {
            if (project != null && id == project.id) {
                destroy ();
            }
        });

        /*
        Planner.todoist.project_deleted_started.connect ((id) => {
            if (project.id == id) {
                sensitive = false;
            }
        });

        Planner.todoist.project_deleted_error.connect ((id, http_code, error_message) => {
            if (project.id == id) {
                sensitive = true;
            }
        });
        */

        Planner.utils.drag_item_activated.connect ((active) => {
            build_drag_and_drop (active);
        });

        // Project count
        Planner.database.item_added.connect ((item) => {
            if (project.id == item.project_id) {
                update_count ();
            }
        });

        Planner.database.item_deleted.connect ((item) => {
            if (project.id == item.project_id) {
                update_count ();
            }
        });

        Planner.database.item_completed.connect ((item) => {
            if (project.id == item.project_id) {
                update_count ();
            }
        });

        Planner.database.section_deleted.connect ((section) => {
            if (project.id == section.project_id) {
                update_count ();
            }
        });

        Planner.database.item_moved.connect (() => {
            Idle.add (() => {
                update_count ();

                return false;
            });
        });

        Planner.database.section_moved.connect ((section, id, old_project_id) => {
            Idle.add (() => {
                if (project.id == id || project.id == old_project_id) {
                    update_count ();
                }

                return false;
            });
        });

        Planner.database.subtract_task_counter.connect ((id) => {
            Idle.add (() => {
                update_count ();

                return false;
            });
        });

        Planner.database.update_project_count.connect ((id, items_0, items_1) => {
            if (project.id == id) {
                project_progress.percentage = ((double) items_1 / ((double) items_0 + (double) items_1));
                count = items_0;
                check_count_label ();
            }
        });

        Planner.database.project_id_updated.connect ((current_id, new_id) => {
            Idle.add (() => {
                if (project.id == current_id) {
                    project.id = new_id;
                }

                return false;
            });
        });
    }

    private void update_count () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }

        timeout_id = Timeout.add (250, () => {
            Planner.database.get_project_count (project.id);
            
            Source.remove (timeout_id);
            timeout_id = 0;
            return false;
        });
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

        Planner.database.move_item (source.item, project.id);
        if (source.item.is_todoist == 0) {
            Planner.todoist.move_item (source.item, project.id);
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
        main_revealer.reveal_child = false;
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
        main_revealer.reveal_child = true;
    }

    private void build_menu_popover () {
        /* Colors Menu */
        var colors_button = new Widgets.ModelButton (_("Colors"), "preferences-color-symbolic", _("Project color"), true);

        var back_button = new Gtk.ModelButton ();
        back_button.margin_top = 3;
        back_button.text = _("Back");
        back_button.inverted = true;
        back_button.menu_name = "main";

        var sub_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        sub_separator.margin_top = sub_separator.margin_bottom = 3;
        sub_separator.hexpand = true;

        var colors_widget = new Widgets.ColorGrid ();

        colors_grid = new Gtk.Grid ();
        colors_grid.orientation = Gtk.Orientation.VERTICAL;
        colors_grid.width_request = 200;
        colors_grid.name = "colors-menu";
        colors_grid.add (back_button);
        colors_grid.add (sub_separator);
        colors_grid.add (colors_widget);
        colors_grid.show_all ();

        var areas_button = new Widgets.ModelButton (_("Move to area"), "planner-work-area-symbolic", _("Project area"), true);

        var area_back_button = new Gtk.ModelButton ();
        area_back_button.margin_top = 3;
        area_back_button.text = _("Back");
        area_back_button.inverted = true;
        area_back_button.menu_name = "main";

        var area_sub_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        area_sub_separator.margin_top = area_sub_separator.margin_bottom = 3;
        area_sub_separator.hexpand = true;

        areas_grid = new Gtk.Grid ();
        areas_grid.orientation = Gtk.Orientation.VERTICAL;
        areas_grid.width_request = 200;
        areas_grid.margin_bottom = 3;

        var areas_menu_grid = new Gtk.Grid ();
        areas_menu_grid.orientation = Gtk.Orientation.VERTICAL;
        areas_menu_grid.width_request = 200;
        areas_menu_grid.name = "areas-menu";
        areas_menu_grid.add (area_back_button);
        areas_menu_grid.add (area_sub_separator);
        areas_menu_grid.add (areas_grid);
        areas_menu_grid.show_all ();

        var delete_menu = new Widgets.PopoverButton (_("Delete project"), "user-trash-symbolic");

        var separator_01 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator_01.margin_top = separator_01.margin_bottom = 3;
        separator_01.hexpand = true;

        //  var separator_02 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        //  separator_02.margin_top = separator_02.margin_bottom = 3;
        //  separator_02.hexpand = true;

        var grid = new Gtk.Grid ();
        grid.margin_top = 3;
        grid.margin_bottom = 3;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.width_request = 200;
        grid.name = "main";
        grid.add (colors_button);
        grid.add (areas_button);
        grid.add (separator_01);
        grid.add (delete_menu);
        grid.show_all ();

        menu_popover = new Gtk.PopoverMenu ();
        menu_popover.position = Gtk.PositionType.BOTTOM;
        menu_popover.relative_to = menu_button;
        menu_popover.add (grid);
        menu_popover.add (colors_grid);
        menu_popover.add (areas_menu_grid);
        menu_popover.child_set_property (grid, "submenu", "main");
        menu_popover.child_set_property (colors_grid, "submenu", "colors-menu");
        menu_popover.child_set_property (areas_menu_grid, "submenu", "areas-menu");

        colors_button.clicked.connect (() => {
            menu_popover.visible_submenu = "colors-menu";
        });

        areas_button.clicked.connect (() => {
            menu_popover.visible_submenu = "areas-menu";
        });

        delete_menu.clicked.connect (() => {
            menu_popover.popdown ();

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
                Planner.database.delete_project (project.id);
                if (project.is_todoist == 1) {
                    Planner.todoist.delete_project (project);
                }
            }

            message_dialog.destroy ();
        });

        colors_widget.color_selected.connect ((color) => {
            project.color = color;
            project.save ();
        });

        menu_popover.closed.connect (() => {
            menu_button.active = false;
        });
    }

    private void activate_menu () {
        if (menu_popover == null) {
            build_menu_popover ();
        }

        foreach (var child in areas_grid.get_children ()) {
            child.destroy ();
        }

        Widgets.ModelButton item;
        if (project.area_id != 0) {
            item = new Widgets.ModelButton (_("No Area"), "window-close-symbolic");
            item.clicked.connect (() => {
                if (Planner.database.move_project (project, 0)) {
                    destroy ();
                }
            });

            areas_grid.add (item);
        }

        foreach (Objects.Area area in Planner.database.get_all_areas ()) {
            if (area.id != project.area_id) {
                item = new Widgets.ModelButton (area.name, "planner-work-area-symbolic");
                item.clicked.connect (() => {
                    if (Planner.database.move_project (project, area.id)) {
                        destroy ();
                    }
                });

                areas_grid.add (item);
            }
        }

        areas_grid.show_all ();
        menu_popover.popup ();
        
        /*
        if (menu == null) {
            build_context_menu (project);
        } 

        

        Widgets.ImageMenuItem item;
        

        foreach (Objects.Area area in Planner.database.get_all_areas ()) {
            if (area.id != project.area_id) {
                item = new Widgets.ImageMenuItem (area.name, "planner-work-area-symbolic");
                item.activate.connect (() => {
                    if (Planner.database.move_project (project, area.id)) {
                        destroy ();
                    }
                });

                work_areas.add (item);
            }
        }

        work_areas.show_all ();
        menu.popup_at_pointer (null);
        */
    }
}