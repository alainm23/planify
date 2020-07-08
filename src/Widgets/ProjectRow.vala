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

public class Widgets.ProjectRow : Gtk.ListBoxRow {
    public Objects.Project project { get; construct; }
    public Gtk.ScrolledWindow scrolled { get; set; }
    
    private Widgets.ProjectProgress project_progress;
    private Gtk.Label name_label;
    private Gtk.Label count_label;
    private Gtk.Revealer count_revealer;

    private Gtk.Menu areas_menu;
    private Gtk.Menu menu = null;
    private Gtk.Button menu_button;
    private Widgets.ImageMenuItem move_area_menu;

    private Gtk.EventBox handle;

    private Gtk.Revealer motion_revealer;
    public Gtk.Revealer main_revealer;
    private Gtk.Label due_label;

    private int count = 0;
    private uint timeout_id = 0;

    private bool scroll_up = false;
    private bool scrolling = false;
    private bool should_scroll = false;
    public Gtk.Adjustment vadjustment;
    private Gtk.Revealer menu_revealer;
    private Gtk.Revealer due_revealer;
    private const int SCROLL_STEP_SIZE = 5;
    private const int SCROLL_DISTANCE = 30;
    private const int SCROLL_DELAY = 50;

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
        margin_top = 2;
        get_style_context ().add_class ("pane-row");
        get_style_context ().add_class ("project-row");

        project_progress = new Widgets.ProjectProgress (10);
        project_progress.margin = 2;
        project_progress.valign = Gtk.Align.CENTER;
        project_progress.halign = Gtk.Align.CENTER;
        project_progress.progress_fill_color = Planner.utils.get_color (project.color);
                
        var progress_grid = new Gtk.Grid ();
        progress_grid.get_style_context ().add_class ("project-progress-%s".printf (
            project.id.to_string ()
        ));
        progress_grid.add (project_progress);
        progress_grid.valign = Gtk.Align.CENTER;
        progress_grid.halign = Gtk.Align.CENTER;

        name_label = new Gtk.Label (project.name);
        name_label.tooltip_text = project.name;
        name_label.get_style_context ().add_class ("pane-item");
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        name_label.margin_start = 9;

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

        menu_button = new Gtk.Button ();
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

        menu_revealer = new Gtk.Revealer ();
        menu_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        menu_revealer.reveal_child = true;
        menu_revealer.add (menu_stack);

        var source_icon = new Gtk.Image ();
        source_icon.valign = Gtk.Align.CENTER;
        source_icon.get_style_context ().add_class ("dim-label");
        source_icon.pixel_size = 14;
        source_icon.margin_start = 6;

        if (project.is_todoist == 0) {
            source_icon.tooltip_text = _("Local Project");
            source_icon.icon_name = "planner-offline-symbolic";
        } else {
            source_icon.icon_name = "planner-online-symbolic";
            source_icon.tooltip_text = _("Todoist Project");
        }

        var source_revealer = new Gtk.Revealer ();
        source_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        source_revealer.add (source_icon);

        due_label = new Gtk.Label (null);
        due_label.use_markup = true;
        due_label.valign = Gtk.Align.CENTER;
        due_label.get_style_context ().add_class ("pane-due-button");

        due_revealer = new Gtk.Revealer ();
        due_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        due_revealer.add (due_label);

        var handle_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        handle_box.hexpand = true;
        handle_box.margin_start = 5;
        handle_box.margin_end = 3;
        handle_box.pack_start (progress_grid, false, false, 0);
        handle_box.pack_start (name_label, false, false, 0);
        handle_box.pack_start (source_revealer, false, false, 0);
        handle_box.pack_end (menu_revealer, false, false, 0);
        handle_box.pack_end (due_revealer, false, false, 0);

        var motion_grid = new Gtk.Grid ();
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;
        motion_grid.margin_top = 6;

        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.margin_top = grid.margin_bottom = 2;
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
        check_due_date ();

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
            source_revealer.reveal_child = true;

            return true;
        });

        handle.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            menu_stack.visible_child_name = "count_revealer";
            source_revealer.reveal_child = false;

            return true;
        });

        menu_button.clicked.connect (() => {
            activate_menu ();
        });
  
        Planner.database.project_updated.connect ((p) => {
            if (project != null && p.id == project.id) {
                project.name = p.name;
                project.color = p.color;
                project.note = p.note;
                project.due_date = p.due_date;

                name_label.label = p.name;
                project_progress.progress_fill_color = Planner.utils.get_color (p.color);

                apply_color (Planner.utils.get_color (p.color));
                check_due_date ();
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

        Planner.database.update_all_bage.connect (() => {
            update_count ();
        });
    }

    private void apply_color (string color) {
        string _css = """
            .project-progress-%s {
                border-radius: 50%;
                border: 1.5px solid %s;
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
        }

        timeout_id = Timeout.add (500, () => {
            timeout_id = 0;
            count = Planner.database.get_count_items_by_project (project.id);
            check_count_label ();

            // Progress update
            project_progress.percentage = get_percentage (
                Planner.database.get_count_checked_items_by_project (project.id),
                Planner.database.get_all_count_items_by_project (project.id)
            );
            
            return false;
        });
    }

    private double get_percentage (int a, int b) {
        return (double) a / (double) b;
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

        if (source.item.is_todoist == project.is_todoist) {
            Planner.database.move_item (source.item, project.id);
            if (source.item.is_todoist == 1) {
                Planner.todoist.move_item (source.item, project.id);
            }

            string move_template = _("Task moved to <b>%s</b>");
            Planner.notifications.send_notification (
                move_template.printf (
                    Planner.database.get_project_by_id (project.id).name
                )
            );
        } else {
            Planner.notifications.send_notification (
                _("Unable to move task")
            );
        }
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = ((ProjectRow) widget).handle;

        Gtk.Allocation alloc;
        row.get_allocation (out alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr = new Cairo.Context (surface);
        cr.set_source_rgba (0, 0, 0, 0);
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
        uchar[] data = new uchar[(sizeof (ProjectRow))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("PROJECTROW"), 32, data
        );
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        reveal_drag_motion = true;
        
        int index = get_index ();
        Gtk.Allocation alloc;
        get_allocation (out alloc);

        int real_y = (index * alloc.height) - alloc.height + y;
        check_scroll (real_y);

        if (should_scroll && !scrolling) {
            scrolling = true;
            Timeout.add (SCROLL_DELAY, scroll);
        }

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

        get_style_context ().add_class ("highlight");
        
        foreach (var child in areas_menu.get_children ()) {
            child.destroy ();
        }

        Widgets.ImageMenuItem item_menu;
        if (project.area_id != 0) {
            item_menu = new Widgets.ImageMenuItem (_("No Folder"), "window-close-symbolic");
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
                item_menu = new Widgets.ImageMenuItem (area.name, "folder-outline");
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

        menu.hide.connect (() => {
            get_style_context ().remove_class ("highlight");
        });

        var edit_menu = new Widgets.ImageMenuItem (_("Edit"), "edit-symbolic");
        move_area_menu = new Widgets.ImageMenuItem (_("Move"), "move-project-symbolic");
        areas_menu = new Gtk.Menu ();
        move_area_menu.set_submenu (areas_menu);

        var share_menu = new Widgets.ImageMenuItem (_("Share"), "emblem-shared-symbolic");
        var share_list_menu = new Gtk.Menu ();
        share_menu.set_submenu (share_list_menu);

        var share_mail = new Widgets.ImageMenuItem (_("Send by e-mail"), "internet-mail-symbolic");
        var share_markdown_menu = new Widgets.ImageMenuItem (_("Markdown"), "planner-markdown-symbolic");

        share_list_menu.add (share_markdown_menu);
        share_list_menu.add (share_mail);
        share_list_menu.show_all ();

        // var duplicate_menu = new Widgets.ImageMenuItem (_("Duplicate"), "edit-copy-symbolic");

        var delete_menu = new Widgets.ImageMenuItem (_("Delete"), "user-trash-symbolic");
        delete_menu.get_style_context ().add_class ("menu-danger");

        menu.add (edit_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (move_area_menu);
        menu.add (share_menu);
        // menu.add (duplicate_menu);
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

        share_mail.activate.connect (() => {
            project.share_mail ();
        });

        share_markdown_menu.activate.connect (() => {
            project.share_markdown ();
        });
    }

    private void check_scroll (int y) {
        vadjustment = scrolled.vadjustment;

        if (vadjustment == null) {
            return;
        }

        double vadjustment_min = vadjustment.value;
        double vadjustment_max = vadjustment.page_size + vadjustment_min;
        double show_min = double.max (0, y - SCROLL_DISTANCE);
        double show_max = double.min (vadjustment.upper, y + SCROLL_DISTANCE);

        if (vadjustment_min > show_min) {
            should_scroll = true;
            scroll_up = true;
        } else if (vadjustment_max < show_max) {
            should_scroll = true;
            scroll_up = false;
        } else {
            should_scroll = false;
        }
    }

    private bool scroll () {
        if (should_scroll) {
            if (scroll_up) {
                vadjustment.value -= SCROLL_STEP_SIZE;
            } else {
                vadjustment.value += SCROLL_STEP_SIZE;
            }
        } else {
            scrolling = false;
        }

        return should_scroll;
    }

    private void check_due_date () {
        if (project.due_date == "") {
            due_revealer.reveal_child = false;
            menu_revealer.reveal_child = true;
        } else {
            due_revealer.reveal_child = true;
            menu_revealer.reveal_child = false;
            var due = new GLib.DateTime.from_iso8601 (project.due_date, new GLib.TimeZone.local ());
            due_label.label = "<small>%s</small>".printf (Planner.utils.get_relative_date_from_date (due));
        }
    } 
}
