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

    private Gtk.Menu areas_menu;
    private Gtk.Menu menu = null;
    private Gtk.ToggleButton menu_button;
    private Widgets.ImageMenuItem move_area_menu;

    private Gtk.EventBox handle;

    private Gtk.Revealer motion_revealer;
    public Gtk.Revealer main_revealer;

    private int count = 0;
    private uint timeout_id = 0;

    private const Gtk.TargetEntry[] TARGET_ENTRIES = {
        {"PROJECTROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] TARGET_ENTRIES_ITEM = {
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
        project_progress.line_cap = Cairo.LineCap.ROUND;
        project_progress.radius_filled = true;
        project_progress.line_width = 2;
        project_progress.valign = Gtk.Align.CENTER;
        project_progress.halign = Gtk.Align.CENTER;
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
        grid_color.get_style_context ().add_class ("project-%s".printf (project.id.to_string ()));
        grid_color.set_size_request (13, 13);
        grid_color.valign = Gtk.Align.CENTER;
        grid_color.halign = Gtk.Align.CENTER;

        name_label = new Gtk.Label (project.name);
        name_label.tooltip_text = project.name;
        name_label.get_style_context ().add_class ("pane-item");
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

        count_label = new Gtk.Label (null);
        count_label.valign = Gtk.Align.CENTER;
        count_label.opacity = 0.7;
        count_label.use_markup = true;
        count_label.width_chars = 3;

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
        menu_button.tooltip_text = _("Project Menu");
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
        source_icon.margin_top = 3;
        source_icon.pixel_size = 14;

        if (project.is_todoist == 0) {
            source_icon.tooltip_text = _("Local Project");
            source_icon.icon_name = "planner-offline-symbolic";
        } else {
            source_icon.icon_name = "planner-online-symbolic";
            source_icon.tooltip_text = _("Todoist Project");
        }

        var handle_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 7);
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
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.margin_start = 4;
        grid.margin_top = grid.margin_bottom = 3;
        grid.add (handle_box);
        grid.add (motion_revealer);

        handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.expand = true;
        handle.above_child = false;
        handle.add (grid);

        main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = true;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (handle);

        add (main_revealer);
        apply_color (Planner.utils.get_color (project.color));

        Timeout.add (125, () => {
            update_count ();
            return false;
        });

        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, TARGET_ENTRIES, Gdk.DragAction.MOVE);
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

            menu_stack.visible_child_name = "count_revealer";
            return true;
        });

        menu_button.toggled.connect (() => {
            if (menu_button.active) {
                activate_menu ();
            }
        });

        Planner.database.project_updated.connect ((p) => {
            if (project != null && p.id == project.id) {
                project.name = p.name;
                project.color = p.color;
                name_label.label = p.name;
                project_progress.progress_fill_color = Planner.utils.get_color (p.color);

                apply_color (Planner.utils.get_color (p.color));
            }
        });

        Planner.database.project_deleted.connect ((id) => {
            if (project != null && id == project.id) {
                main_revealer.reveal_child = false;

                Timeout.add (500, () => {
                    destroy ();
                    return false;
                });
            }
        });

        Planner.utils.drag_item_activated.connect ((active) => {
            build_drag_and_drop (active);
        });

        Planner.database.update_project_count.connect ((id, items_0, items_1) => {
            if (project.id == id) {
                project_progress.percentage = ((double) items_1 / ((double) items_0 + (double) items_1));
                count = items_0;
                check_count_label ();
            }
        });

        Planner.database.check_project_count.connect ((id) => {
            if (project.id == id) {
                update_count ();
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

    private void apply_color (string color) {
        string _css = """
            .project-color-%s {
                color: %s
            }
        """;

        var provider = new Gtk.CssProvider ();

        try {
            var css = _css.printf (
                project.id.to_string (),
                color
            );

            provider.load_from_data (css, css.length);
            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (), provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } catch (GLib.Error e) {
            return;
        }
    }

    private void update_count () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }

        timeout_id = Timeout.add (500, () => {
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

            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, TARGET_ENTRIES_ITEM, Gdk.DragAction.MOVE);
            drag_data_received.connect (on_drag_item_received);
            drag_motion.connect (on_drag_item_motion);
            drag_leave.connect (on_drag_item_leave);

        } else {
            drag_data_received.disconnect (on_drag_item_received);
            drag_motion.disconnect (on_drag_item_motion);
            drag_leave.disconnect (on_drag_item_leave);

            Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION, TARGET_ENTRIES, Gdk.DragAction.MOVE);
            drag_motion.connect (on_drag_motion);
            drag_leave.connect (on_drag_leave);
            drag_end.connect (clear_indicator);
        }
    }

    private void on_drag_item_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type) {
        Widgets.ItemRow source;
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        Planner.database.move_item (source.item, project.id);
        if (source.item.is_todoist == 0) {
            Planner.todoist.move_item (source.item, project.id);
        }
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = ((ProjectRow) widget).handle;

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

        cr.set_source_rgba (255, 255, 255, 0.7);
        cr.rectangle (0, 0, alloc.width, alloc.height);
        cr.fill ();

        row.draw (cr);
        Gtk.drag_set_icon_surface (context, surface);
        main_revealer.reveal_child = false;
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
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

    private void activate_menu () {
        if (menu == null) {
            build_context_menu (project);
        }

        foreach (var child in areas_menu.get_children ()) {
            child.destroy ();
        }

        Widgets.ImageMenuItem item_menu;
        if (project.area_id != 0) {
            item_menu = new Widgets.ImageMenuItem (_("No Area"), "window-close-symbolic");
            item_menu.activate.connect (() => {
                if (Planner.database.move_project (project, 0)) {
                    main_revealer.reveal_child = false;

                    Timeout.add (500, () => {
                        destroy ();
                        return false;
                    });
                }
            });

            areas_menu.add (item_menu);
        }

        int area_count = 0;
        foreach (Objects.Area area in Planner.database.get_all_areas ()) {
            if (area.id != project.area_id) {
                item_menu = new Widgets.ImageMenuItem (area.name, "planner-work-area-symbolic");
                item_menu.activate.connect (() => {
                    if (Planner.database.move_project (project, area.id)) {
                        main_revealer.reveal_child = false;

                        Timeout.add (500, () => {
                            destroy ();
                            return false;
                        });
                    }
                });

                areas_menu.add (item_menu);
            }

            area_count++;
        }

        if (area_count > 0) {
            move_area_menu.visible = true;
            move_area_menu.no_show_all = false;
        } else {
            move_area_menu.visible = false;
            move_area_menu.no_show_all = true;
        }

        areas_menu.show_all ();
        menu.popup_at_pointer (null);
    }

    private void build_context_menu (Objects.Project project) {
        menu = new Gtk.Menu ();
        menu.width_request = 200;

        var edit_menu = new Widgets.ImageMenuItem (_("Edit"), "edit-symbolic");

        move_area_menu = new Widgets.ImageMenuItem (_("Move to Area"), "planner-work-area-symbolic");
        areas_menu = new Gtk.Menu ();
        move_area_menu.set_submenu (areas_menu);

        var share_menu = new Widgets.ImageMenuItem (_("Share"), "emblem-shared-symbolic");
        var share_list_menu = new Gtk.Menu ();
        share_menu.set_submenu (share_list_menu);

        var share_text_menu = new Widgets.ImageMenuItem (_("Text"), "text-x-generic-symbolic");
        var share_markdown_menu = new Widgets.ImageMenuItem (_("Markdown"), "planner-markdown-symbolic");

        share_list_menu.add (share_text_menu);
        share_list_menu.add (share_markdown_menu);
        share_list_menu.show_all ();

        var delete_menu = new Widgets.ImageMenuItem (_("Delete"), "user-trash-symbolic");
        delete_menu.item_image.get_style_context ().add_class ("label-danger");

        menu.add (edit_menu);
        menu.add (move_area_menu);
        //menu.add (share_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (delete_menu);

        menu.show_all ();


        edit_menu.activate.connect (() => {
            var dialog = new Dialogs.ProjectSettings (project);
            dialog.destroy.connect (Gtk.main_quit);
            dialog.show_all ();
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
                Planner.database.delete_project (project.id);
                if (project.is_todoist == 1) {
                    Planner.todoist.delete_project (project);
                }
            }

            message_dialog.destroy ();
        });

        share_text_menu.activate.connect (() => {
            project.share_text ();
        });

        share_markdown_menu.activate.connect (() => {
            project.share_markdown ();
        });
    }
}
