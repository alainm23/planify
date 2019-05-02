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

public class Widgets.ProjectsList : Gtk.Grid {
    private Gtk.ListBox items_listbox;
    private Gtk.ListBox projects_listbox;
    private Widgets.ItemRow inbox_item;
    private Widgets.ItemRow today_item;
    private Widgets.ItemRow upcoming_item;
    private Widgets.ItemRow team_inbox_item;

    private bool has_team_inbox = false;

    private Gee.HashMap <int64?, Widgets.ProjectRow> projects_hashmap;

    public signal void on_selected_item (string type, int64 index);
    public ProjectsList () {
        Object (
            expand: true
        );
    }

    construct {
        get_style_context ().add_class ("paned-right");
        orientation = Gtk.Orientation.VERTICAL;

        projects_hashmap = new Gee.HashMap<int64?, Widgets.ProjectRow?> ();
        
        inbox_item = new Widgets.ItemRow (_("Inbox"), 
                                            "mail-mailbox-symbolic", 
                                            "inbox",
                                            _("Create new task"));
        //inbox_item.revealer_primary_label = true;
        //inbox_item.primary_text = "5";

        today_item = new Widgets.ItemRow (_("Today"), 
                                            "office-calendar-symbolic", 
                                            "today", 
                                            _("Create new task"));
        upcoming_item = new Widgets.ItemRow (_("Upcoming"), 
                                               "go-jump-symbolic", 
                                               "upcoming",
                                               _("Create new task"));
        items_listbox = new Gtk.ListBox  ();
        items_listbox.activate_on_single_click = true;
        items_listbox.get_style_context ().add_class (Gtk.STYLE_CLASS_BACKGROUND);
        items_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        items_listbox.hexpand = true;
        items_listbox.margin_bottom = 3;

        items_listbox.add (inbox_item);
        items_listbox.add (today_item);
        items_listbox.add (upcoming_item);

        var show_image = new Gtk.Image.from_icon_name ("pan-end-symbolic", Gtk.IconSize.MENU);
        show_image.get_style_context ().add_class ("show-button");
        show_image.get_style_context ().add_class ("closed");

        var show_label = new Gtk.Label ("<b>%s</b>".printf (_("Projects")));
        show_label.use_markup = true;
    
        var show_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 11);
        show_box.margin_bottom = 3;
        show_box.margin_start = 6;
        show_box.margin_top = 3;
        show_box.pack_start (show_image, false, false, 0);
        show_box.pack_start (show_label, false, false, 0);

        var show_eventbox = new Gtk.EventBox ();
        show_eventbox.add (show_box);

        var add_projects_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        add_projects_button.can_focus = false;
        add_projects_button.tooltip_text = _("Add new project");
        add_projects_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var show_projects_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        show_projects_box.hexpand = true;
        show_projects_box.pack_start (show_eventbox, true, true, 0);
        show_projects_box.pack_end (add_projects_button, false, false, 3);

        var main_show_projects = new Gtk.Grid ();
        main_show_projects.orientation = Gtk.Orientation.VERTICAL;
        main_show_projects.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_show_projects.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_show_projects.add (show_projects_box);
        main_show_projects.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        // Projects List
        projects_listbox = new Gtk.ListBox ();
        projects_listbox.activate_on_single_click = true;
        projects_listbox.get_style_context ().add_class (Gtk.STYLE_CLASS_BACKGROUND);
        projects_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        projects_listbox.hexpand = true;
        projects_listbox.valign = Gtk.Align.START;

        projects_listbox.set_sort_func  ((row_1, row_2) => {
            var item_1 = row_1 as Widgets.ProjectRow;
            var item_2 = row_2 as Widgets.ProjectRow;

            if (item_1.project.child_order > item_2.project.child_order) {
                return 1;
            } else {
                return 0;
            }
        });

        var projects_list_revealer = new Gtk.Revealer ();
        projects_list_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        projects_list_revealer.reveal_child = true;
        projects_list_revealer.add (projects_listbox);

        var new_project = new Widgets.NewProject ();

        add_projects_button.clicked.connect (() => {
            new_project.reveal_new_project = !new_project.reveal_new_project;
        });
        
        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.expand = true;

        main_grid.add (items_listbox);
        main_grid.add (main_show_projects);
        main_grid.add (projects_list_revealer);
        main_grid.add (new_project);

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.margin_bottom = 6;
        scrolled_window.width_request = 250;
        scrolled_window.add (main_grid);

        var eventbox = new Gtk.EventBox ();
        eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        eventbox.add (scrolled_window);

        add (eventbox);
            
        if (Application.settings.get_enum ("start-page") == 0) {
            projects_listbox.select_row (inbox_item);
        } else if (Application.settings.get_enum ("start-page") == 1) {
            projects_listbox.select_row (today_item);
        } else {
            projects_listbox.select_row (upcoming_item);
        }

        Application.database.start_create_projects.connect (() => {
            update_project_list ();
        });

        projects_listbox.row_activated.connect ((row) => {
            items_listbox.unselect_all ();
            new_project.reveal_new_project = false;
        });

        items_listbox.row_activated.connect ((row) => {
            projects_listbox.unselect_all ();
            new_project.reveal_new_project = false;
            
            if (has_team_inbox) {

            } else {

            }
        });

        show_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                if (projects_list_revealer.reveal_child) {
                    projects_list_revealer.reveal_child = false;
                    new_project.reveal_new_project = false;
                    show_image.get_style_context ().remove_class ("closed");
                } else {
                    projects_list_revealer.reveal_child = true;
                    show_image.get_style_context ().add_class ("closed");
                }
            }

            return false;
        });

        Application.database.project_added.connect ((project) => {
            if (project.inbox_project == false) {
                var row = new Widgets.ProjectRow (project);
                projects_hashmap.set (project.id, row);
            
                projects_listbox.add (row);
                projects_listbox.show_all ();

                projects_listbox.invalidate_sort ();
            }

            if (project.team_inbox) {
                team_inbox_item = new Widgets.ItemRow (_("Team Inbox"), 
                                               "mail-mailbox-symbolic", 
                                               "team_inbox",
                                               _("Create new task"));
                items_listbox.add (team_inbox_item);
                items_listbox.show_all ();
            }
        });
    }
    
    public void update_project_list () {
        var all_projects = new Gee.ArrayList<Objects.Project?> ();
        all_projects= Application.database.get_all_projects ();
            
        foreach (Objects.Project project in all_projects) {
            if (project.inbox_project == false && project.team_inbox == false && project.is_favorite == 0) {
                var row = new Widgets.ProjectRow (project);
                projects_listbox.add (row);
                projects_listbox.show_all ();
            }

            if (project.team_inbox) {
                team_inbox_item = new Widgets.ItemRow (_("Team Inbox"), 
                                               "mail-mailbox-symbolic", 
                                               "team_inbox",
                                               _("Create new task"));
                items_listbox.insert (team_inbox_item, 0);
                items_listbox.show_all ();

                has_team_inbox = true;
            }
        }

        projects_listbox.invalidate_sort ();
    }
}
