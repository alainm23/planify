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

    private Widgets.ActionRow inbox_row;
    private Widgets.ActionRow today_row;
    private Widgets.ActionRow upcoming_row;

    public Gtk.ListBox listbox;
    public Gtk.ListBox project_listbox;
    private Gtk.ListBox area_listbox;
    private Gtk.ScrolledWindow listbox_scrolled;
    public Gtk.Grid listbox_grid;

    private Gtk.Button add_button;
    private Gtk.Button sync_button;

    private Gtk.Image sync_image;
    private Gtk.Image error_image;

    public signal void activated (PaneView view);
    public signal void show_quick_find ();
    public signal void tasklist_selected (E.Source source);
    public signal void label_selected (Objects.Label label);

    private uint timeout;
    public Gee.ArrayList<Widgets.ProjectRow?> projects_list;
    public Gee.ArrayList<Widgets.AreaRow?> areas_list;

    private const Gtk.TargetEntry[] TARGET_ENTRIES = {
        {"PROJECTROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] TARGET_PANEVIEW = {
        {"PANEVIEWROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] TARGET_AREAS = {
        {"AREAROW", Gtk.TargetFlags.SAME_APP, 0}
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

    private Gtk.Widget get_search_row () {
        var icon = new Gtk.Image ();
        icon.halign = Gtk.Align.CENTER;
        icon.valign = Gtk.Align.CENTER;
        icon.gicon = new ThemedIcon ("system-search-symbolic");
        icon.pixel_size = 14;
        icon.get_style_context ().add_class ("search-icon");

        var title = new Gtk.Label (_("Quick Find"));
        title.margin_bottom = 1;
        title.get_style_context ().add_class ("pane-item");
        title.use_markup = true;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.margin_start = 2;
        box.pack_start (icon, false, false, 0);
        box.pack_start (title, false, false, 0);

        return box;
    }

    construct {
        projects_list = new Gee.ArrayList<Widgets.ProjectRow?> ();
        areas_list = new Gee.ArrayList<Widgets.AreaRow?> ();

        var search_row = new Gtk.Button ();
        search_row.can_focus = false;
        search_row.get_style_context ().add_class ("flat");
        search_row.add (get_search_row ());
        search_row.margin_bottom = 6;
        
        inbox_row = new Widgets.ActionRow (PaneView.INBOX);
        today_row = new Widgets.ActionRow (PaneView.TODAY);
        upcoming_row = new Widgets.ActionRow (PaneView.UPCOMING);
        
        add_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        add_button.valign = Gtk.Align.CENTER;
        add_button.halign = Gtk.Align.START;
        add_button.always_show_image = true;
        add_button.can_focus = false;
        add_button.label = _("Add Project");
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

        var motion_grid = new Gtk.Grid ();
        motion_grid.margin_start = 6;
        motion_grid.margin_end = 6;
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;

        project_listbox = new Gtk.ListBox ();
        project_listbox.margin_top = 6;
        project_listbox.get_style_context ().add_class ("pane");
        project_listbox.activate_on_single_click = true;
        project_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        project_listbox.hexpand = true;

        var motion_area_grid = new Gtk.Grid ();
        motion_area_grid.margin_start = 6;
        motion_area_grid.margin_end = 6;
        motion_area_grid.margin_bottom = 12;
        motion_area_grid.height_request = 24;
        motion_area_grid.get_style_context ().add_class ("grid-motion");

        area_listbox = new Gtk.ListBox ();
        area_listbox.get_style_context ().add_class ("pane");
        area_listbox.activate_on_single_click = true;
        area_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        area_listbox.hexpand = true;

        //  var caldav_widget = new Widgets.CalDavList ();
        //  caldav_widget.tasklist_selected.connect ((source) => {
        //      tasklist_selected (source);

        //      project_listbox.unselect_all ();
        //      listbox.unselect_all ();
        //  });
        var drop_area_grid = new Gtk.Grid ();
        drop_area_grid.margin_start = 6;
        drop_area_grid.margin_end = 6;
        drop_area_grid.height_request = 12;

        var motion_area_revealer = new Gtk.Revealer ();
        motion_area_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        motion_area_revealer.add (motion_area_grid);

        Gtk.drag_dest_set (drop_area_grid, Gtk.DestDefaults.ALL, TARGET_AREAS, Gdk.DragAction.MOVE);
        drop_area_grid.drag_data_received.connect ((context, x, y, selection_data, target_type, time) => {
            Widgets.AreaRow source;
            Gtk.Allocation alloc;
    
            var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
            source = (Widgets.AreaRow) row;
            
            source.get_parent ().remove (source);
            areas_list.remove (source);
            
            area_listbox.insert (source, 0);
            areas_list.insert (0, source);
            area_listbox.show_all ();

            update_area_order ();
        });

        drop_area_grid.drag_motion.connect ((context, x, y, time) => {
            motion_area_revealer.reveal_child = true;
            return true;
        });

        drop_area_grid.drag_leave.connect ((context, time) => {
            motion_area_revealer.reveal_child = false;
        });

        listbox_grid = new Gtk.Grid ();
        listbox_grid.margin_start = 6;
        listbox_grid.margin_end = 6;
        listbox_grid.margin_top = 3;
        listbox_grid.orientation = Gtk.Orientation.VERTICAL;
        listbox_grid.add (search_row);
        listbox_grid.add (listbox);
        listbox_grid.add (project_listbox);
        listbox_grid.add (drop_area_grid);
        listbox_grid.add (motion_area_revealer);
        listbox_grid.add (area_listbox);
        // listbox_grid.add (caldav_widget);

        if (Planner.settings.get_boolean ("use-system-decoration")) {
            listbox_grid.margin_top = 18;
        }

        listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        listbox_scrolled.width_request = 238;
        listbox_scrolled.hexpand = true;
        listbox_scrolled.margin_bottom = 6;
        listbox_scrolled.add (listbox_grid);

        new_project = new Widgets.New ();

        // Search Button
        var search_button = new Gtk.Button ();
        search_button.can_focus = false;
        search_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl>f"}, _("Quick Find"));
        search_button.valign = Gtk.Align.CENTER;
        search_button.halign = Gtk.Align.CENTER;
        search_button.get_style_context ().add_class ("settings-button");
        search_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var search_image = new Gtk.Image ();
        search_image.gicon = new ThemedIcon ("edit-find-symbolic");
        search_image.pixel_size = 14;
        search_button.image = search_image;

        var settings_button = new Gtk.Button ();
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
        header_box.pack_start (sync_button, false, false, 0);
        header_box.pack_start (settings_button, false, false, 0);

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        action_box.margin_end = 9;
        action_box.margin_bottom = 6;
        action_box.margin_start = 9;
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

        Planner.database.opened.connect (() => {
            listbox.foreach ((row) => {
                listbox.remove (row);
            });

            string[] array = Planner.settings.get_strv ("views-order");
            foreach (var view in array) {
                if (view == "inbox") {
                    listbox.add (inbox_row);
                } else if (view == "today") {
                    listbox.add (today_row);
                } else if (view == "upcoming") {
                    listbox.add (upcoming_row);
                }
            }

            listbox.show_all ();
        });

        search_row.clicked.connect (() => {
            var dialog = new Dialogs.QuickFind ();
            dialog.destroy.connect (Gtk.main_quit);
            dialog.show_all ();
        });

        listbox.row_selected.connect ((row) => {
            if (row != null && Planner.database.is_database_empty () != true) {
                Planner.event_bus.unselect_all ();
                
                activated (((Widgets.ActionRow) row).view);
                Planner.utils.pane_action_selected ();
                project_listbox.unselect_all ();
            }
        });

        project_listbox.row_selected.connect ((row) => {
            if (row != null) {
                Planner.event_bus.unselect_all ();
                
                var project = ((Widgets.ProjectRow) row).project;
                Planner.utils.pane_project_selected (project.id, 0);
            }
        });

        add_button.clicked.connect (() => {
            Planner.event_bus.unselect_all ();
            new_project.reveal = true;
        });

        Planner.database.area_added.connect ((area) => {
            var row = new Widgets.AreaRow (area);
            row.scrolled = listbox_scrolled;
            row.destroy.connect (() => {
                area_row_removed (row);
            });

            area_listbox.add (row);
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
                row.scrolled = listbox_scrolled;
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
                    row.scrolled = listbox_scrolled;
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
            sync_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl>S"}, _("Sync"));
            sync_button.image = sync_image;
        } else {
            sync_button.image = error_image;
            sync_button.tooltip_markup = "<b>%s</b>\n%s".printf (_("Offline mode is on"), _("Looks like you'are not connected to the\ninternet. Changes you make in offline\nmode will be synced when you reconnect")); // vala-lint=line-length
        }
    }

    public void add_label (Objects.Label label) {
        // labels_widget.add_label (label);
    }

    private void build_drag_and_drop () {
        Gtk.drag_dest_set (listbox, Gtk.DestDefaults.ALL, TARGET_PANEVIEW, Gdk.DragAction.MOVE);
        listbox.drag_data_received.connect (on_drag_paneview_received);

        Gtk.drag_dest_set (project_listbox, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        project_listbox.drag_data_received.connect (on_drag_project_received);

        Gtk.drag_dest_set (area_listbox, Gtk.DestDefaults.ALL, TARGET_AREAS, Gdk.DragAction.MOVE);
        area_listbox.drag_data_received.connect (on_drag_area_received);
    }

    private void on_drag_paneview_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {

        Widgets.ActionRow target;
        Widgets.ActionRow source;
        Gtk.Allocation alloc;

        target = (Widgets.ActionRow) listbox.get_row_at_y (y);
        target.get_allocation (out alloc);

        var row = ((Gtk.Widget[]) selection_data.get_data ()) [0];
        source = (Widgets.ActionRow) row;

        if (target != null) {
            source.get_parent ().remove (source);
            listbox.remove (source);

            if (target.get_index () == 0) {
                if (y < (alloc.height / 2)) {
                    listbox.insert (source, 0);
                } else {
                    listbox.insert (source, target.get_index () + 1);
                }
            } else {
                listbox.insert (source, target.get_index () + 1);
            }

            listbox.show_all ();
            update_views_order ();
        }
    }

    private void on_drag_project_received (Gdk.DragContext context, int x, int y,
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

            if (target.get_index () == 0) {
                if (y < (alloc.height / 2)) {
                    project_listbox.insert (source, 0);
                    projects_list.insert (0, source);
                } else {
                    project_listbox.insert (source, target.get_index () + 1);
                    projects_list.insert (target.get_index () + 1, source);
                }
            } else {
                project_listbox.insert (source, target.get_index () + 1);
                projects_list.insert (target.get_index () + 1, source);
            }

            project_listbox.show_all ();
            update_project_order ();
        }
    }

    private void on_drag_area_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.AreaRow target;
        Widgets.AreaRow source;
        Gtk.Allocation alloc;

        target = (Widgets.AreaRow) area_listbox.get_row_at_y (y);
        target.get_allocation (out alloc);

        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.AreaRow) row;

        if (target != null) {
            source.get_parent ().remove (source);
            areas_list.remove (source);

            area_listbox.insert (source, target.get_index () + 1);
            areas_list.insert (target.get_index () + 1, source);
            area_listbox.show_all ();

            update_area_order ();
        }
    }

    public void add_all_projects () {
        foreach (var project in Planner.database.get_all_projects_no_area ()) {
            var row = new Widgets.ProjectRow (project);
            row.scrolled = listbox_scrolled;
            row.destroy.connect (() => {
                project_row_removed (row);
            });

            project_listbox.add (row);
            projects_list.add (row);

            if (Planner.settings.get_boolean ("homepage-project")) {
                if (Planner.settings.get_int64 ("homepage-project-id") == project.id) {
                    timeout = Timeout.add (125, () => {
                        timeout = 0;
                        project_listbox.select_row (row);
                        return GLib.Source.REMOVE;
                    });
                }
            }
        }

        project_listbox.show_all ();
    }

    public void add_all_areas () {
        foreach (var area in Planner.database.get_all_areas ()) {
            var row = new Widgets.AreaRow (area);
            row.scrolled = listbox_scrolled;
            row.destroy.connect (() => {
                area_row_removed (row);
            });

            area_listbox.add (row);
            areas_list.add (row);
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

            return GLib.Source.REMOVE;
        });
    }

    private void update_area_order () {
        timeout = Timeout.add (250, () => {
            new Thread<void*> ("update_area_order", () => {
                for (int index = 0; index < areas_list.size; index++) {
                    Planner.database.update_area_item_order (areas_list [index].area.id, index);
                }

                return null;
            });

            return GLib.Source.REMOVE;
        });
    }

    private void update_views_order () {
        string[] array = {};
        listbox.foreach ((widget) => {
            var item = ((Widgets.ActionRow) widget);
            array += item.get_view_string ();
        });
        Planner.settings.set_strv ("views-order", array);
    }

    public void select_item (PaneView view) {
        if (view == PaneView.INBOX) {
            listbox.select_row (inbox_row);
        } else if (view == PaneView.TODAY) {
            listbox.select_row (today_row);
        } else if (view == PaneView.UPCOMING) {
            listbox.select_row (upcoming_row);
        } else {
            listbox.unselect_all ();
        }
    }

    private void project_row_removed (Widgets.ProjectRow row) {
        projects_list.remove (row);
    }

    private void area_row_removed (Widgets.AreaRow row) {
        areas_list.remove (row);
    }

    public bool visible_new_widget () {
        return new_project.reveal;
    }

    public void set_visible_new_widget (bool value) {
        new_project.reveal = false;
    }
}
