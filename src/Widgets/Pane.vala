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
    public Widgets.ToolsMenu tools_menu;

    private Widgets.ActionRow inbox_row;
    private Widgets.ActionRow today_row;
    private Widgets.ActionRow upcoming_row;

    public Gtk.ListBox listbox;
    public Gtk.ListBox project_listbox;
    private Gtk.ScrolledWindow listbox_scrolled;
    public Gtk.Grid listbox_grid;

    public Gtk.Box add_project_buttonbox;
    public Gtk.ScrolledWindow buttonbox_scrolled;
    private Gtk.MenuButton add_button;
    private Widgets.SourceButton todoist_source_button;
    private Gtk.Popover add_project_popover;

    public signal void show_quick_find ();
    public signal void tasklist_selected (E.Source source);
    public signal void label_selected (Objects.Label label);
    public signal void project_selected (int64 id);
    public signal void view_selected (int64 id);

    private uint timeout;
    public Gee.ArrayList<Widgets.ProjectRow?> projects_list;

    private const Gtk.TargetEntry[] TARGET_ENTRIES = {
        {"PROJECTROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] TARGET_PANEVIEW = {
        {"PANEVIEWROW", Gtk.TargetFlags.SAME_APP, 0}
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

        var search_row = new Gtk.Button ();
        search_row.can_focus = false;
        search_row.get_style_context ().add_class ("flat");
        search_row.add (get_search_row ());
        search_row.margin_bottom = 6;
        
        inbox_row = new Widgets.ActionRow (PaneView.INBOX);
        today_row = new Widgets.ActionRow (PaneView.TODAY);
        upcoming_row = new Widgets.ActionRow (PaneView.UPCOMING);

        add_project_buttonbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        add_project_buttonbox.margin_top = 6;
        add_project_buttonbox.margin_bottom = 6;
        add_project_buttonbox.width_request = Planner.settings.get_int ("pane-position") - 28;
        add_project_buttonbox.expand = true;

        buttonbox_scrolled = new Gtk.ScrolledWindow (null, null);
        buttonbox_scrolled.expand = true;
        buttonbox_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        buttonbox_scrolled.vscrollbar_policy = Gtk.PolicyType.NEVER;
        buttonbox_scrolled.add (add_project_buttonbox);

        Planner.settings.changed.connect ((key) => {
            if (key == "pane-position") {
                add_project_buttonbox.width_request = Planner.settings.get_int ("pane-position") - 28; 
            }
        });
        
        add_project_popover = new Gtk.Popover (null);
        add_project_popover.add (buttonbox_scrolled);

        var add_button = new Gtk.MenuButton () {
            label = ("Add Project"),
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.START,
            image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
            always_show_image = true,
            popover = add_project_popover
        };
        add_button.get_style_context ().add_class ("flat");
        add_button.get_style_context ().add_class ("font-bold");
        add_button.get_style_context ().add_class ("add-button");

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

        listbox_grid = new Gtk.Grid ();
        listbox_grid.margin_start = 6;
        listbox_grid.margin_end = 9;
        listbox_grid.margin_top = 3;
        listbox_grid.orientation = Gtk.Orientation.VERTICAL;
        listbox_grid.add (search_row);
        listbox_grid.add (listbox);
        listbox_grid.add (project_listbox);

        if (Planner.settings.get_boolean ("use-system-decoration")) {
            listbox_grid.margin_top = 18;
        }

        listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        listbox_scrolled.width_request = 228;
        listbox_scrolled.hexpand = true;
        listbox_scrolled.margin_bottom = 6;
        listbox_scrolled.add (listbox_grid);

        new_project = new Widgets.New ();
        tools_menu = new Widgets.ToolsMenu ();

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
        settings_image.gicon = new ThemedIcon ("view-more-symbolic");
        settings_image.pixel_size = 16;
        settings_button.image = settings_image;

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        header_box.get_style_context ().add_class ("pane");
        header_box.pack_start (tools_menu, false, false, 0);

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        action_box.margin = 6;
        action_box.margin_end = 13;
        action_box.margin_start = 9;
        action_box.hexpand = true;
        action_box.pack_start (add_button, false, false, 0);
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
        add_local_source_button ();

        add_project_popover.show.connect (() => {
            valid_todoist_source_button ();
        });

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

        Planner.todoist.first_sync_finished.connect (() => {
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
        
        Planner.event_bus.pane_selected.connect ((pane_type, id) => {
            Planner.event_bus.unselect_all ();

            if (pane_type == PaneType.PROJECT) {
                project_selected (int64.parse (id));
            } else if (pane_type == PaneType.ACTION) {
                view_selected (int.parse (id));
            } else if (pane_type == PaneType.LABEL) {
                label_selected (Planner.database.get_label_by_id (int64.parse (id)));
            }
        });

        settings_button.clicked.connect (() => {
            Planner.event_bus.unselect_all ();
            tools_menu.check_network_available ();
        });

        Planner.database.project_added.connect ((project) => {
            Idle.add (() => {
                if (project.inbox_project == 0 && project.parent_id == 0) {
                    var row = new Widgets.ProjectRow (project);
                    // row.scrolled = l1istbox_scrolled;
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

        Planner.database.project_moved.connect ((project, parent_id, old_parent_id) => {
            if (old_parent_id == 0) {
                project_listbox.foreach ((widget) => {
                    var row = (Widgets.ProjectRow) widget;

                    if (row.project.id == project.id) {
                        row.destroy ();
                    }
                });
            }

            if (parent_id == 0) {
                project.parent_id = 0;

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
        });

        search_button.clicked.connect (() => {
            var dialog = new Dialogs.QuickFind ();
            dialog.destroy.connect (Gtk.main_quit);
            dialog.show_all ();
        });
    }

    private void valid_todoist_source_button () {
        if (todoist_source_button == null) {
            todoist_source_button = new Widgets.SourceButton (
                "Todoist",
                Planner.settings.get_string ("todoist-user-email"),
                "planner-online-symbolic",
                "todoist",
                "planner"
            );

            todoist_source_button.clicked.connect (() => {
                todoist_source_button.temp_id_mapping = Planner.utils.generate_id ();

                var project = new Objects.Project ();
                project.name = _("New Project");
                project.color = GLib.Random.int_range (30, 50);
                project.id = Planner.utils.generate_id ();
                project.is_todoist = 1;
                Planner.todoist.add_project (project, null, todoist_source_button.temp_id_mapping);
            });

            add_project_buttonbox.add (todoist_source_button);
            buttonbox_scrolled.show_all ();
            add_project_buttonbox.show_all ();
        }

        todoist_source_button.visible = Planner.settings.get_boolean ("todoist-account");
    }

    public void add_local_source_button () {
        var local_source_button = new Widgets.SourceButton (
            _("Planner"),
            _("Planner Project"),
            "planner-offline-symbolic",
            "planner-project",
            "planner"
        );

        local_source_button.clicked.connect (() => {
            var project = new Objects.Project ();
            project.name = _("New Project");
            project.color = GLib.Random.int_range (30, 50);
            project.id = Planner.utils.generate_id ();
            if (Planner.database.insert_project (project)) {
                add_project_popover.popdown ();

                Timeout.add (250, () => {
                    Planner.event_bus.pane_selected (PaneType.PROJECT, project.id.to_string ());
                    Planner.event_bus.edit_project (project.id);
                    return GLib.Source.REMOVE;
                });
            }
        });

        add_project_buttonbox.add (local_source_button);
        buttonbox_scrolled.show_all ();
        add_project_buttonbox.show_all ();
    }

    public void add_label (Objects.Label label) {
        // labels_widget.add_label (label);
    }

    private void build_drag_and_drop () {
        Gtk.drag_dest_set (listbox, Gtk.DestDefaults.ALL, TARGET_PANEVIEW, Gdk.DragAction.MOVE);
        listbox.drag_data_received.connect (on_drag_paneview_received);

        Gtk.drag_dest_set (project_listbox, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        project_listbox.drag_data_received.connect (on_drag_project_received);
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
            
            if (source.project.parent_id != 0 && source.project.is_todoist == 1) {
                source.project.parent_id = 0;
                Planner.todoist.move_project.begin (source.project, 0);
            }

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

    public void add_all_projects () {
        foreach (var project in Planner.database.get_all_projects_no_parent ()) {
            var row = new Widgets.ProjectRow (project);
            row.scrolled = listbox_scrolled;
            row.destroy.connect (() => {
                project_row_removed (row);
            });

            project_listbox.add (row);
            projects_list.add (row);
        }

        project_listbox.show_all ();
    }

    private void update_project_order () {
        Timeout.add (250, () => {
            new Thread<void*> ("update_project_order", () => {
                for (int index = 0; index < projects_list.size; index++) {
                    Planner.database.update_project_item_order (projects_list [index].project.id, 0, index);
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

    public bool visible_new_widget () {
        return new_project.reveal;
    }

    public bool visible_tool_widget () {
        return false;
    }

    public void set_visible_new_widget (bool value) {
        new_project.reveal = false;
    }

    public void set_visible_tool_widget (bool value) {

    }
}
