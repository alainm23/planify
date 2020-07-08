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

public class Widgets.AreaRow : Gtk.ListBoxRow {
    public Objects.Area area { get; construct; }
    public Gtk.ScrolledWindow scrolled { get; set; }

    private Gtk.Image area_image;
    private Gtk.Button submit_button;
    private Gtk.Label name_label;
    private Widgets.Entry name_entry;
    private Gtk.Stack name_stack;
    private Gtk.EventBox top_eventbox;
    private Gtk.ListBox listbox;
    private Gtk.Revealer listbox_revealer;
    private Gtk.Revealer motion_revealer;
    private Gtk.Revealer motion_area_revealer;
    private Gtk.Grid drop_grid;
    private Gtk.Revealer action_revealer;
    public Gtk.Revealer main_revealer;
    private Gtk.Menu menu = null;
    private bool menu_visible = false;
    private Gtk.Label count_label;

    private uint timeout;
    private uint timeout_id = 0;
    private uint toggle_timeout = 0;
    public Gee.ArrayList<Widgets.ProjectRow?> projects_list;
    private bool entry_menu_opened = false;

    private const Gtk.TargetEntry[] TARGET_ENTRIES = {
        {"PROJECTROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] TARGET_AREAS = {
        {"AREAROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public bool set_focus {
        set {
            submit_button.sensitive = true;
            action_revealer.reveal_child = true;
            name_stack.visible_child_name = "name_entry";

            name_entry.grab_focus_without_selecting ();
            if (name_entry.cursor_position < name_entry.text_length) {
                name_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) name_entry.text_length, false);
            }
        }
    }

    public AreaRow (Objects.Area area) {
        Object (
            area: area
        );
    }

    construct {
        can_focus = false;
        get_style_context ().add_class ("area-row");
        projects_list = new Gee.ArrayList<Widgets.ProjectRow?> ();

        area_image = new Gtk.Image ();
        area_image.halign = Gtk.Align.CENTER;
        area_image.valign = Gtk.Align.CENTER;
        area_image.gicon = new ThemedIcon ("folder-outline");
        area_image.pixel_size = 18;
        if (area.collapsed == 1) {
            area_image.gicon = new ThemedIcon ("folder-open-outline");
        }

        var menu_image = new Gtk.Image ();
        menu_image.gicon = new ThemedIcon ("view-more-symbolic");
        menu_image.pixel_size = 14;

        var menu_button = new Gtk.Button ();
        menu_button.can_focus = false;
        menu_button.valign = Gtk.Align.CENTER;
        menu_button.tooltip_text = _("Section Menu");
        menu_button.image = menu_image;
        menu_button.get_style_context ().remove_class ("button");
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        menu_button.get_style_context ().add_class ("hidden-button");

        count_label = new Gtk.Label (Planner.database.get_project_count_by_area (area.id).to_string ());
        count_label.valign = Gtk.Align.CENTER;
        count_label.opacity = 0;
        count_label.use_markup = true;
        count_label.width_chars = 3;

        var menu_stack = new Gtk.Stack ();
        menu_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        menu_stack.add_named (count_label, "count_label");
        menu_stack.add_named (menu_button, "menu_button");

        name_label = new Gtk.Label (area.name);
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("pane-area");
        name_label.valign = Gtk.Align.CENTER;
        name_label.set_ellipsize (Pango.EllipsizeMode.END);

        name_entry = new Widgets.Entry ();
        name_entry.width_chars = 16;
        name_entry.placeholder_text = _("Task name");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("pane-area");
        name_entry.get_style_context ().add_class ("pane-entry");

        name_entry.text = area.name;
        name_entry.hexpand = true;

        name_stack = new Gtk.Stack ();
        name_stack.margin_start = 9;
        name_stack.transition_type = Gtk.StackTransitionType.NONE;
        name_stack.add_named (name_label, "name_label");
        name_stack.add_named (name_entry, "name_entry");

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin_start = 5;
        top_box.margin_top = 1;
        top_box.margin_bottom = 1;
        top_box.pack_start (area_image, false, false, 0);
        top_box.pack_start (name_stack, false, true, 0);
        top_box.pack_end (menu_stack, false, false, 0);

        submit_button = new Gtk.Button.with_label (_("Save"));
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("planner-button");

        var action_grid = new Gtk.Grid ();
        action_grid.halign = Gtk.Align.START;
        action_grid.column_homogeneous = true;
        action_grid.margin_top = 6;
        action_grid.margin_bottom = 6;
        action_grid.margin_start = 34;
        action_grid.column_spacing = 6;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        action_revealer = new Gtk.Revealer ();
        action_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        action_revealer.add (action_grid);
        action_revealer.reveal_child = false;

        top_eventbox = new Gtk.EventBox ();
        top_eventbox.margin_start = 5;
        top_eventbox.margin_end = 5;
        top_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        top_eventbox.add (top_box);
        top_eventbox.get_style_context ().add_class ("toogle-box");

        listbox = new Gtk.ListBox ();
        listbox.valign = Gtk.Align.START;
        listbox.get_style_context ().add_class ("pane");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        listbox_revealer = new Gtk.Revealer ();
        listbox_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        listbox_revealer.add (listbox);
        listbox_revealer.reveal_child = false;
        
        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_start = 6;
        separator.margin_end = 6;

        var motion_grid = new Gtk.Grid ();
        motion_grid.margin_start = 6;
        motion_grid.margin_end = 6;
        motion_grid.height_request = 24;
        motion_grid.get_style_context ().add_class ("grid-motion");

        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        drop_grid = new Gtk.Grid ();
        drop_grid.margin_start = 6;
        drop_grid.margin_end = 6;
        drop_grid.height_request = 12;

        var motion_area_grid = new Gtk.Grid ();
        motion_area_grid.margin_start = 6;
        motion_area_grid.margin_end = 6;
        motion_area_grid.height_request = 24;
        motion_area_grid.margin_bottom = 12;
        motion_area_grid.get_style_context ().add_class ("grid-motion");

        motion_area_revealer = new Gtk.Revealer ();
        motion_area_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_area_revealer.add (motion_area_grid);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.hexpand = true;
        main_box.pack_start (top_eventbox, false, false, 0);
        main_box.pack_start (action_revealer, false, false, 0);
        main_box.pack_start (motion_revealer, false, false, 0);
        main_box.pack_start (listbox_revealer, false, false, 0);
        main_box.pack_start (drop_grid, false, false, 0);
        main_box.pack_start (motion_area_revealer, false, false, 0);

        main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = true;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (main_box);

        add (main_revealer);
        add_all_projects ();
        build_drag_and_drop ();

        if (area.collapsed == 1) {
            listbox_revealer.reveal_child = true;
            count_label.opacity = 0;
        }

        listbox.row_selected.connect ((row) => {
            if (row != null) {
                var project = ((Widgets.ProjectRow) row).project;
                Planner.utils.pane_project_selected (project.id, area.id);
            }
        });

        name_entry.activate.connect (() => {
            save_area ();
        });

        name_entry.changed.connect (() => {
            if (name_entry.text != "") {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                action_revealer.reveal_child = false;
                name_stack.visible_child_name = "name_label";
                name_entry.text = area.name;
            }

            return false;
        });

        name_entry.focus_out_event.connect (() => {
            if (entry_menu_opened == false) {
                save_area ();
            }
        });

        name_entry.populate_popup.connect ((menu) => {
            entry_menu_opened = true;
            menu.hide.connect (() => {
                entry_menu_opened = false;
            });
        });

        submit_button.clicked.connect (() => {
            save_area ();
        });

        cancel_button.clicked.connect (() => {
            action_revealer.reveal_child = false;
            name_stack.visible_child_name = "name_label";
            name_entry.text = area.name;
        });

        top_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                if (timeout_id != 0) {
                    Source.remove (timeout_id);
                }
    
                timeout_id = Timeout.add (250, () => {
                    timeout_id = 0;

                    if (menu_visible == false) {
                        toggle_hidden ();
                    }
                    return false;
                });                
            }

            return false;
        });

        top_eventbox.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.@2BUTTON_PRESS && evt.button == 1) {
                if (timeout_id != 0) {
                    Source.remove (timeout_id);
                }

                action_revealer.reveal_child = true;
                name_stack.visible_child_name = "name_entry";

                name_entry.grab_focus_without_selecting ();
                if (name_entry.cursor_position < name_entry.text_length) {
                    name_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) name_entry.text_length, false);
                }

                return true;
            } else if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                activate_menu ();
                return true;
            }

            return false;
        });

        menu_button.clicked.connect (() => {
            activate_menu ();
        });

        top_eventbox.enter_notify_event.connect ((event) => {
            menu_stack.visible_child_name = "menu_button";
            return true;
        });

        top_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            menu_stack.visible_child_name = "count_label";
            //  if (listbox_revealer.reveal_child) {
            //      count_label.opacity = 0;
            //  } else {
            //      count_label.opacity = 0.7;
            //  }

            return true;
        });

        Planner.database.project_added.connect ((project) => {
            Idle.add (() => {
                if (project.inbox_project == 0 && project.area_id == area.id) {
                    var row = new Widgets.ProjectRow (project);
                    row.scrolled = scrolled;
                    row.destroy.connect (() => {
                        project_row_removed (row);
                    });

                    listbox.add (row);
                    projects_list.add (row);
                    listbox.show_all ();

                    listbox_revealer.reveal_child = true;
                    area.collapsed = 1;

                    save_area ();
                }

                return false;
            });
        });

        Planner.database.project_moved.connect ((project) => {
            Idle.add (() => {
                if (project.area_id == area.id) {
                    var row = new Widgets.ProjectRow (project);
                    row.scrolled = scrolled;
                    row.destroy.connect (() => {
                        project_row_removed (row);
                    });

                    listbox.add (row);
                    projects_list.add (row);
                    listbox.show_all ();

                    listbox_revealer.reveal_child = true;
                    area.collapsed = 1;

                    save_area ();
                }

                return false;
            });
        });

        Planner.utils.pane_project_selected.connect ((project_id, area_id) => {
            if (area.id != area_id || area_id == 0) {
                listbox.unselect_all ();
            }
        });

        Planner.utils.pane_action_selected.connect (() => {
            listbox.unselect_all ();
        });
    }

    private void toggle_hidden () {
        if (toggle_timeout != 0) {
            Source.remove (timeout_id);
            top_eventbox.get_style_context ().remove_class ("active");
        }

        top_eventbox.get_style_context ().add_class ("active");
        toggle_timeout = Timeout.add (750, () => {
            toggle_timeout = 0;
            top_eventbox.get_style_context ().remove_class ("active");
            return false;
        });

        if (listbox_revealer.reveal_child) {
            listbox_revealer.reveal_child = false;
            area_image.gicon = new ThemedIcon ("folder-outline");
            area.collapsed = 0;
        } else {
            listbox_revealer.reveal_child = true;
            area_image.gicon = new ThemedIcon ("folder-open-outline");
            area.collapsed = 1;
        }

        save_area ();
    }

    public void add_all_projects () {
        foreach (Objects.Project project in Planner.database.get_all_projects_by_area (area.id)) {
            if (project.inbox_project == 0) {
                var row = new Widgets.ProjectRow (project);
                row.scrolled = scrolled;
                row.destroy.connect (() => {
                    project_row_removed (row);
                });

                listbox.add (row);
                projects_list.add (row);

                if (Planner.settings.get_boolean ("homepage-project")) {
                    if (Planner.settings.get_int64 ("homepage-project-id") == project.id) {
                        if (timeout != 0) {
                            Source.remove (timeout);   
                        }

                        timeout = Timeout.add (125, () => {
                            timeout = 0;
                            listbox.select_row (row);
                            return false;
                        });
                    }
                }
            }

        }

        listbox.show_all ();
    }

    public void save_area () {
        if (name_entry.text != "") {
            area.name = name_entry.text;
            name_label.label = area.name;

            area.save ();
            action_revealer.reveal_child = false;
            name_stack.visible_child_name = "name_label";
        }
    }

    private void build_drag_and_drop () {
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, TARGET_AREAS, Gdk.DragAction.MOVE);
        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);
        drag_end.connect (clear_indicator);

        Gtk.drag_dest_set (drop_grid, Gtk.DestDefaults.MOTION, TARGET_AREAS, Gdk.DragAction.MOVE);
        drop_grid.drag_motion.connect (on_drag_area_motion);
        drop_grid.drag_leave.connect (on_drag_area_leave);

        Gtk.drag_dest_set (listbox, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        listbox.drag_data_received.connect (on_drag_data_received);

        Gtk.drag_dest_set (top_eventbox, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        top_eventbox.drag_data_received.connect (on_drag_project_received);
        top_eventbox.drag_motion.connect (on_drag_motion);
        top_eventbox.drag_leave.connect (on_drag_leave);
    }

    public bool on_drag_area_motion (Gdk.DragContext context, int x, int y, uint time) {
        motion_area_revealer.reveal_child = true;
        return true;
    }

    public void on_drag_area_leave (Gdk.DragContext context, uint time) {
        motion_area_revealer.reveal_child = false;
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
        }

        var row = ((Widgets.AreaRow) widget).top_eventbox;

        Gtk.Allocation alloc;
        row.get_allocation (out alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr = new Cairo.Context (surface);
        cr.set_source_rgba (0, 0, 0, 0.5);
        cr.set_line_width (1);

        cr.move_to (0, 0);
        cr.line_to (alloc.width, 0);
        cr.line_to (alloc.width, alloc.height);
        cr.line_to (0, alloc.height);
        cr.line_to (0, 0);
        cr.stroke ();

        cr.set_source_rgba (255, 255, 255, 0);
        cr.rectangle (0, 0, alloc.width, alloc.height);
        cr.fill ();

        row.get_style_context ().add_class ("drag-begin");
        row.draw (cr);
        row.get_style_context ().remove_class ("drag-begin");

        Gtk.drag_set_icon_surface (context, surface);
        main_revealer.reveal_child = false;
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (Widgets.AreaRow))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("AREAROW"), 32, data
        );
    }

    public void clear_indicator (Gdk.DragContext context) {
        main_revealer.reveal_child = true;
    }

    private void on_drag_data_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.ProjectRow target;
        Widgets.ProjectRow source;
        Gtk.Allocation alloc;

        target = (Widgets.ProjectRow ) listbox.get_row_at_y (y);
        target.get_allocation (out alloc);

        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ProjectRow ) row;

        if (target != null) {
            source.get_parent ().remove (source);
            projects_list.remove (source);

            source.project.area_id = area.id;

            listbox.insert (source, target.get_index () + 1);
            projects_list.insert (target.get_index () + 1, source);

            listbox.show_all ();

            update_project_order ();
        }
    }

    private void on_drag_project_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type) {
        Widgets.ProjectRow source;
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ProjectRow) row;

        source.get_parent ().remove (source);
        projects_list.remove (source);

        listbox.insert (source, 0);
        projects_list.insert (0, source);
        listbox.show_all ();

        update_project_order ();

        listbox_revealer.reveal_child = true;
        area.collapsed = 1;

        save_area ();
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        motion_revealer.reveal_child = true;
        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        motion_revealer.reveal_child = false;
    }

    private void update_project_order () {
        timeout = Timeout.add (250, () => {
            new Thread<void*> ("update_project_order", () => {
                for (int index = 0; index < projects_list.size; index++) {
                    Planner.database.update_project_item_order (projects_list [index].project.id, area.id, index);
                }

                return null;
            });

            return false;
        });
    }

    private void activate_menu () {
        if (menu == null) {
            build_context_menu (area);
        }

        top_eventbox.get_style_context ().add_class ("highlight");
        menu_visible = true;
        menu.popup_at_pointer (null);
    }

    private void build_context_menu (Objects.Area area) {
        menu = new Gtk.Menu ();
        menu.width_request = 200;

        menu.hide.connect (() => {
            top_eventbox.get_style_context ().remove_class ("highlight");
            menu_visible = false;
        });

        var add_menu = new Widgets.ImageMenuItem (_("Add project"), "list-add-symbolic");
        add_menu.get_style_context ().add_class ("add-button-menu");

        var edit_menu = new Widgets.ImageMenuItem (_("Edit"), "edit-symbolic");
        var delete_menu = new Widgets.ImageMenuItem (_("Delete"), "user-trash-symbolic");
        delete_menu.get_style_context ().add_class ("menu-danger");

        menu.add (add_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (edit_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (delete_menu);

        menu.show_all ();

        add_menu.activate.connect (() => {
            Planner.utils.insert_project_to_area (area.id);
        });

        edit_menu.activate.connect (() => {
            action_revealer.reveal_child = true;
            name_stack.visible_child_name = "name_entry";

            name_entry.grab_focus_without_selecting ();
            name_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) name_entry.text_length, false);
        });

        delete_menu.activate.connect (() => {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Delete folder"),
                _("Are you sure you want to delete <b>%s</b>?".printf (area.name)),
                "user-trash-full",
                Gtk.ButtonsType.CLOSE
            );

            Gtk.CheckButton custom_widget = null;
            if (Planner.database.projects_area_exists (area.id)) {
                custom_widget = new Gtk.CheckButton.with_label (_("Delete projects"));
                custom_widget.show ();
                message_dialog.custom_bin.add (custom_widget);
            }

            var remove_button = new Gtk.Button.with_label (_("Delete"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                if (Planner.database.delete_area (area)) {
                    if (custom_widget != null && custom_widget.active) {
                        delete_projects ();
                    } else {
                        move_projects ();
                    }
                }
            }

            message_dialog.destroy ();
        });
    }

    private void move_projects () {
        foreach (Objects.Project project in Planner.database.get_all_projects_by_area (area.id)) {
            Planner.database.move_project (project, 0);
        }

        main_revealer.reveal_child = false;

        Timeout.add (500, () => {
            destroy ();
            return false;
        });
    }

    private void delete_projects () {
        foreach (Objects.Project project in Planner.database.get_all_projects_by_area (area.id)) {
            Planner.database.delete_project (project.id);
            if (project.is_todoist == 1) {
                Planner.todoist.delete_project (project);
            }
        }

        main_revealer.reveal_child = false;

        Timeout.add (500, () => {
            destroy ();
            return false;
        });
    }

    private void project_row_removed (Widgets.ProjectRow row) {
        projects_list.remove (row);
    }
}
