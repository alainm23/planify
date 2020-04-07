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

public class Widgets.Pane : Gtk.EventBox {
    private Gtk.Stack stack;
    public Widgets.New new_project;

    //private Widgets.ActionRow search_row;
    private Widgets.ActionRow inbox_row;
    private Widgets.ActionRow today_row;
    private Widgets.ActionRow upcoming_row;

    private Gtk.ListBox listbox;
    private Gtk.ListBox project_listbox;
    private Gtk.ListBox area_listbox;

    private Gtk.Button add_button;
    private Gtk.Button sync_button;

    private Gtk.Image sync_image;
    private Gtk.Image error_image;

    public signal void activated (int id);
    public signal void show_quick_find ();

    private uint timeout;
    public Gee.ArrayList<Widgets.ProjectRow?> projects_list;

    private const Gtk.TargetEntry[] TARGET_ENTRIES = {
        {"PROJECTROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public bool sensitive_ui {
        set {
            if (value) {
                stack.visible_child_name = "scrolled";
            } else {
                stack.visible_child_name = "grid";
            }
        }
    }

    construct {
        projects_list = new Gee.ArrayList<Widgets.ProjectRow?> ();

        //search_row = new Widgets.ActionRow (_("Quick Find"), "system-search-symbolic", "search", _("Your Inbox is the default place to add new tasks so you can get them out of your head quickly, then come back and make a plan to take care of them later. It’s a great way to declutter your mind so you can focus on whatever you’re doing right now."));
        inbox_row = new Widgets.ActionRow (_("Inbox"), "mail-mailbox-symbolic", "inbox", _("Your Inbox is the default place to add new tasks so you can get them out of your head quickly, then come back and make a plan to take care of them later. It’s a great way to declutter your mind so you can focus on whatever you’re doing right now.")); // vala-lint=line-length

        string today_icon = "planner-today-day-symbolic";
        var hour = new GLib.DateTime.now_local ().get_hour ();
        if (hour >= 18 || hour <= 5) {
            today_icon = "planner-today-night-symbolic";
        }

        today_row = new Widgets.ActionRow (_("Today"), today_icon, "today", _("The Today view lets you see all the tasks due today across all your projects. Check in here every morning to make a realistic plan to tackle your day.")); // vala-lint=line-length
        upcoming_row = new Widgets.ActionRow (_("Upcoming"), "x-office-calendar-symbolic", "upcoming", _("Plan your week ahead with the Upcoming view. It shows everything on your agenda for the coming days: scheduled to-dos and calendar events.")); // vala-lint=line-length
        //var back_row = new Widgets.ActionRow (_("Trash"), "user-trash-symbolic", "upcoming", _("Upcoming"));

        add_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        add_button.valign = Gtk.Align.CENTER;
        add_button.halign = Gtk.Align.START;
        add_button.always_show_image = true;
        add_button.can_focus = false;
        add_button.label = _("Add List");
        add_button.get_style_context ().add_class ("flat");
        add_button.get_style_context ().add_class ("font-bold");
        add_button.get_style_context ().add_class ("add-button");

        var add_revealer = new Gtk.Revealer ();
        add_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        add_revealer.reveal_child = true;
        add_revealer.add (add_button);

        listbox = new Gtk.ListBox ();
        listbox.get_style_context ().add_class ("pane");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        listbox.add (inbox_row);
        listbox.add (today_row);
        listbox.add (upcoming_row);
        //listbox.add (back_row);

        var motion_grid = new Gtk.Grid ();
        motion_grid.margin_start = 6;
        motion_grid.margin_end = 6;
        motion_grid.margin_bottom = 6;
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;

        var motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        motion_revealer.add (motion_grid);

        var drag_grid = new Gtk.Grid ();
        drag_grid.height_request = 8;

        project_listbox = new Gtk.ListBox ();
        project_listbox.get_style_context ().add_class ("pane");
        project_listbox.activate_on_single_click = true;
        project_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        project_listbox.hexpand = true;

        area_listbox = new Gtk.ListBox ();
        area_listbox.get_style_context ().add_class ("pane");
        area_listbox.activate_on_single_click = true;
        area_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        area_listbox.hexpand = true;

        var listbox_grid = new Gtk.Grid ();
        listbox_grid.margin_start = listbox_grid.margin_end = 12;
        listbox_grid.orientation = Gtk.Orientation.VERTICAL;
        listbox_grid.add (listbox);
        listbox_grid.add (drag_grid);
        listbox_grid.add (motion_revealer);
        listbox_grid.add (project_listbox);
        listbox_grid.add (area_listbox);

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        listbox_scrolled.width_request = 252;
        listbox_scrolled.hexpand = true;
        listbox_scrolled.margin_bottom = 6;
        listbox_scrolled.add (listbox_grid);

        new_project = new Widgets.New ();

        // Search Button
        var search_button = new Gtk.Button ();
        search_button.can_focus = false;
        search_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl>F"}, _("Quick Find"));
        search_button.valign = Gtk.Align.CENTER;
        search_button.halign = Gtk.Align.CENTER;
        search_button.get_style_context ().add_class ("settings-button");
        search_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var search_image = new Gtk.Image ();
        search_image.gicon = new ThemedIcon ("edit-find-symbolic");
        search_image.pixel_size = 14;
        search_button.image = search_image;

        var settings_button = new Gtk.Button ();
        settings_button.margin_end = 1;
        settings_button.can_focus = false;
        settings_button.tooltip_text = _("Preferences");
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.halign = Gtk.Align.CENTER;
        settings_button.get_style_context ().add_class ("settings-button");
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var settings_image = new Gtk.Image ();
        settings_image.gicon = new ThemedIcon ("open-menu-symbolic");
        settings_image.pixel_size = 14;
        settings_button.image = settings_image;

        sync_image = new Gtk.Image ();
        sync_image.gicon = new ThemedIcon ("emblem-synchronizing-symbolic");
        sync_image.get_style_context ().add_class ("sync-image-rotate");
        sync_image.pixel_size = 16;

        error_image = new Gtk.Image ();
        error_image.gicon = new ThemedIcon ("dialog-warning-symbolic");
        error_image.pixel_size = 16;

        sync_button = new Gtk.Button ();
        sync_button.can_focus = false;
        sync_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl>S"}, _("Sync"));
        sync_button.valign = Gtk.Align.CENTER;
        sync_button.halign = Gtk.Align.CENTER;
        sync_button.get_style_context ().add_class ("sync");
        sync_button.get_style_context ().add_class ("settings-button");
        sync_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        sync_button.visible = Planner.settings.get_boolean ("todoist-account");
        sync_button.no_show_all = !Planner.settings.get_boolean ("todoist-account");

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        header_box.get_style_context ().add_class ("pane");
        header_box.pack_start (search_button, false, false, 0);
        header_box.pack_start (sync_button, false, false, 0);
        header_box.pack_start (settings_button, false, false, 0);

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        action_box.margin_end = 16;
        action_box.margin_bottom = 6;
        action_box.margin_start = 16;
        action_box.hexpand = true;
        action_box.pack_start (add_revealer, false, false, 0);
        action_box.pack_end (header_box, false, false, 0);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.get_style_context ().add_class ("pane");
        main_box.pack_start (listbox_scrolled, true, true, 0);
        main_box.pack_end (action_box, false, false, 0);

        var overlay = new Gtk.Overlay ();
        overlay.add_overlay (new_project);
        overlay.add (main_box);

        var grid = new Gtk.Grid ();
        grid.get_style_context ().add_class ("pane");
        grid.expand = true;

        stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        stack.add_named (overlay, "scrolled");
        stack.add_named (grid, "grid");

        add (stack);
        build_drag_and_drop ();
        check_network ();

        // Project Drag and Drop
        Gtk.drag_dest_set (drag_grid, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        drag_grid.drag_data_received.connect ((context, x, y, selection_data, target_type, time) => {
            Widgets.ProjectRow source;
            Gtk.Allocation alloc;

            var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
            source = (Widgets.ProjectRow) row;

            source.get_parent ().remove (source);
            projects_list.remove (source);

            source.project.area_id = 0;

            project_listbox.insert (source, 0);
            projects_list.insert (0, source);
            project_listbox.show_all ();

            update_project_order ();
        });

        drag_grid.drag_motion.connect ((context, x, y, time) => {
            motion_revealer.reveal_child = true;
            return true;
        });

        drag_grid.drag_leave.connect ((context, time) => {
            motion_revealer.reveal_child = false;
        });

        listbox.row_selected.connect ((row) => {
            if (row != null) {
                activated (row.get_index ());
                Planner.utils.pane_action_selected ();
                project_listbox.unselect_all ();
            }
        });

        project_listbox.row_selected.connect ((row) => {
            if (row != null) {
                var project = ((Widgets.ProjectRow) row).project;
                Planner.utils.pane_project_selected (project.id, 0);
            }
        });

        add_button.clicked.connect (() => {
            new_project.reveal = true;
        });

        Planner.database.area_added.connect ((area) => {
            var row = new Widgets.AreaRow (area);
            area_listbox.add (row);
            area_listbox.show_all ();

            row.set_focus = true;
        });

        Planner.utils.pane_project_selected.connect ((project_id, area_id) => {
            listbox.unselect_all ();

            if (area_id != 0) {
                project_listbox.unselect_all ();
            }
        });

        Planner.utils.select_pane_project.connect ((project_id) => {
            project_listbox.foreach ((widget) => {
                var row = (Widgets.ProjectRow) widget;

                if (row.project.id == project_id) {
                    project_listbox.select_row (row);
                }
            });
        });

        Planner.database.project_added.connect ((project) => {
            if (project.inbox_project == 0 && project.area_id == 0) {
                var row = new Widgets.ProjectRow (project);
                row.destroy.connect (() => {
                    project_row_removed (row);
                });

                project_listbox.add (row);
                projects_list.add (row);

                project_listbox.show_all ();
            }
        });

        Planner.database.project_moved.connect ((project) => {
            Idle.add (() => {
                if (project.area_id == 0) {
                    var row = new Widgets.ProjectRow (project);
                    row.destroy.connect (() => {
                        project_row_removed (row);
                    });

                    project_listbox.add (row);
                    projects_list.add (row);

                    project_listbox.show_all ();
                }

                return false;
            });
        });

        var network_monitor = GLib.NetworkMonitor.get_default ();
        network_monitor.network_changed.connect (() => {
            check_network ();
        });

        Planner.utils.drag_item_activated.connect ((value) => {
            if (value) {
                upcoming_row.title_name.label = _("Tomorrow");
            } else {
                upcoming_row.title_name.label = _("Upcoming");
            }
        });

        Planner.database.reset.connect (() => {
            stack.visible_child_name = "grid";

            project_listbox.foreach ((widget) => {
                Idle.add (() => {
                    widget.destroy ();

                    return false;
                });
            });

            area_listbox.foreach ((widget) => {
                Idle.add (() => {
                    widget.destroy ();

                    return false;
                });
            });
        });

        search_button.clicked.connect (() => {
            //  show_quick_find ();
            var dialog = new Dialogs.QuickFind ();
            dialog.destroy.connect (Gtk.main_quit);
            dialog.show_all ();
        });

        settings_button.clicked.connect (() => {
            var dialog = new Dialogs.Preferences.Preferences ();
            dialog.destroy.connect (Gtk.main_quit);
            dialog.show_all ();
        });

        sync_button.clicked.connect (() => {
            Planner.todoist.sync ();
        });

        Planner.todoist.sync_started.connect (() => {
            sync_button.sensitive = false;
            sync_button.get_style_context ().add_class ("is_loading");
        });

        Planner.todoist.sync_finished.connect (() => {
            sync_button.sensitive = true;
            sync_button.get_style_context ().remove_class ("is_loading");
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "todoist-account") {
                sync_button.visible = Planner.settings.get_boolean ("todoist-account");
                sync_button.no_show_all = !Planner.settings.get_boolean ("todoist-account");
            }
        });
    }

    private void check_network () {
        var available = GLib.NetworkMonitor.get_default ().get_network_available ();

        if (available) {
            sync_button.tooltip_text = _("Sync");
            sync_button.image = sync_image;
        } else {
            sync_button.image = error_image;
            sync_button.tooltip_markup = "<b>%s</b>\n%s".printf (_("Offline mode is on"), _("Looks like you'are not connected to the\ninternet. Changes you make in offline\nmode will be synced when you reconnect")); // vala-lint=line-length
        }
    }

    private void build_drag_and_drop () {
        Gtk.drag_dest_set (project_listbox, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        project_listbox.drag_data_received.connect (on_drag_data_received);
    }

    private void on_drag_data_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.ProjectRow target;
        Widgets.ProjectRow source;
        Gtk.Allocation alloc;

        target = (Widgets.ProjectRow) project_listbox.get_row_at_y (y);
        target.get_allocation (out alloc);

        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ProjectRow) row;

        if (target != null) {
            source.get_parent ().remove (source);
            projects_list.remove (source);

            source.project.area_id = 0;

            project_listbox.insert (source, target.get_index () + 1);
            projects_list.insert (target.get_index () + 1, source);

            project_listbox.show_all ();

            update_project_order ();
        }
    }

    public void add_all_projects () {
        foreach (var project in Planner.database.get_all_projects_no_area ()) {
            var row = new Widgets.ProjectRow (project);
            row.destroy.connect (() => {
                project_row_removed (row);
            });

            project_listbox.add (row);
            projects_list.add (row);

            if (Planner.settings.get_boolean ("homepage-project")) {
                if (Planner.settings.get_int64 ("homepage-project-id") == project.id) {
                    timeout = Timeout.add (125, () => {
                        project_listbox.select_row (row);

                        Source.remove (timeout);
                        return false;
                    });
                }
            }
        }

        project_listbox.show_all ();
    }

    public void add_all_areas () {
        foreach (var area in Planner.database.get_all_areas ()) {
            var row = new Widgets.AreaRow (area);
            area_listbox.add (row);
        }

        area_listbox.show_all ();
    }

    private void update_project_order () {
        timeout = Timeout.add (250, () => {
            new Thread<void*> ("update_project_order", () => {
                for (int index = 0; index < projects_list.size; index++) {
                    Planner.database.update_project_item_order (projects_list [index].project.id, 0, index);
                }

                return null;
            });

            return false;
        });
    }

    public void select_item (int id) {
        if (id == 0) {
            listbox.select_row (inbox_row);
        } else if (id == 1) {
            listbox.select_row (today_row);
        } else {
            listbox.select_row (upcoming_row);
        }
    }

    private void project_row_removed (Widgets.ProjectRow row) {
        projects_list.remove (row);
    }

    public bool visible_new_widget () {
        return new_project.reveal;
    }

    public void set_visible_new_widget (bool value) {
        new_project.reveal = false;
    }
}
