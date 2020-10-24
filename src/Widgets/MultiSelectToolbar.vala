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

public class Widgets.MultiSelectToolbar : Gtk.Revealer {
    public Gee.HashMap<string, Widgets.ItemRow> items_selected;
    private Gtk.Popover reschedule_popover = null;
    private Widgets.ToggleButton reschedule_button;
    private Widgets.ToggleButton priority_button;
    private Gtk.ToggleButton more_button;
    private Gtk.Popover move_popover = null;
    private Gtk.Popover more_popover = null;
    private Gtk.Popover priority_popover = null;
    private Widgets.ModelButton undated_button;
    private Widgets.ToggleButton move_button;
    private Gtk.ListBox projects_listbox;
    private Gtk.SearchEntry search_entry;
    private Widgets.ModelButton priority_4_menu;
    
    construct {
        items_selected = new Gee.HashMap <string, Widgets.ItemRow> ();

        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.END;
        transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        reveal_child = false;

        var done_button = new Gtk.Button ();
        done_button.label = _("Done");

        reschedule_button = new Widgets.ToggleButton (_("Schedule"), "office-calendar-symbolic");
        reschedule_button.margin_start = 6;
        reschedule_button.get_style_context ().add_class ("multi-select-toolbar-button");

        priority_button = new Widgets.ToggleButton (_("Priority"), "edit-flag-symbolic");
        priority_button.get_style_context ().add_class ("multi-select-toolbar-button");

        move_button = new Widgets.ToggleButton (_("Move"), "move-project-symbolic");
        move_button.get_style_context ().add_class ("multi-select-toolbar-button");

        var delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic", Gtk.IconSize.MENU);
        delete_button.get_style_context ().add_class ("multi-select-toolbar-button");

        var menu_icon = new Gtk.Image ();
        menu_icon.gicon = new ThemedIcon ("view-more-symbolic");
        menu_icon.pixel_size = 14;

        more_button = new Gtk.ToggleButton ();
        more_button.add (menu_icon);
        more_button.get_style_context ().add_class ("multi-select-toolbar-button");

        var notification_box = new Gtk.Grid ();
        notification_box.valign = Gtk.Align.CENTER;

        notification_box.add (done_button);
        notification_box.add (reschedule_button);
        notification_box.add (priority_button);
        notification_box.add (move_button);
        notification_box.add (delete_button);
        notification_box.add (more_button);

        var notification_frame = new Gtk.Frame (null);
        notification_frame.margin = 9;
        notification_frame.width_request = 200;
        notification_frame.height_request = 24;
        notification_frame.get_style_context ().add_class ("app-notification");
        notification_frame.add (notification_box);

        var notification_eventbox = new Gtk.EventBox ();
        notification_eventbox.margin_bottom = 12;
        notification_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        notification_eventbox.above_child = false;
        notification_eventbox.add (notification_frame);

        done_button.clicked.connect (() => {
            unselect_all ();
        });

        add (notification_eventbox);

        Planner.event_bus.select_item.connect ((row) => {
            if (items_selected.has_key (row.item.id.to_string ())) {
                items_selected.unset (row.item.id.to_string ());
                row.item_selected = false;
            } else {
                items_selected.set (row.item.id.to_string (), row);
                row.item_selected = true;
            }

            check_select_bar ();
        });

        Planner.event_bus.unselect_all.connect ((row) => {
            if (items_selected.size > 0) {
                unselect_all ();
            }
        });

        reschedule_button.toggled.connect (() => {
            if (reschedule_button.active) {
                if (reschedule_popover == null) {
                    create_reschedule_popover ();
                }
            }

            undated_button.visible = false;
            undated_button.no_show_all = true;
            foreach (string key in items_selected.keys) {
                var item = items_selected.get (key).item;
                if (item.due_date != "") {
                    undated_button.visible = true;
                    undated_button.no_show_all = false;
                }
            }

            
            reschedule_popover.show_all ();
            reschedule_popover.popup ();
        });

        move_button.toggled.connect (() => {
            if (move_button.active) {
                if (move_popover == null) {
                    create_move_popover ();
                }
            }

            foreach (var child in projects_listbox.get_children ()) {
                child.destroy ();
            }

            SearchProject item_menu;
            foreach (var project in Planner.database.get_all_projects ()) {
                item_menu = new SearchProject (project);
                projects_listbox.add (item_menu);
            }

            projects_listbox.show_all ();
            move_popover.show_all ();
            move_popover.popup ();
            search_entry.grab_focus ();
        });

        priority_button.toggled.connect (() => {
            if (priority_button.active) {
                if (priority_popover == null) {
                    create_priority_popover ();
                }
            }

            if (Planner.settings.get_enum ("appearance") == 0) {
                priority_4_menu.item_image.gicon = new ThemedIcon ("flag-outline-light");
            } else {
                priority_4_menu.item_image.gicon = new ThemedIcon ("flag-outline-dark");
            }

            priority_popover.show_all ();
            priority_popover.popup ();
        });

        delete_button.clicked.connect (() => {
            if (items_selected.size > 0) {
                var message = "";
                if (items_selected.size > 1) {
                    message = _("Are you sure you want to delete %i tasks?".printf (items_selected.size));
                } else {
                    foreach (string key in items_selected.keys) {
                        message = _("Are you sure you want to delete <b>%s</b>?".printf (
                            items_selected.get (key).item.content
                        ));
                    }
                }
                var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                    _("Delete taks"),
                    message,
                    "user-trash-full",
                Gtk.ButtonsType.CANCEL);
    
                var remove_button = new Gtk.Button.with_label (_("Delete"));
                remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);
    
                message_dialog.show_all ();
    
                if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                    foreach (string key in items_selected.keys) {
                        var item = items_selected.get (key).item;

                        Planner.database.delete_item (item);
                        if (item.is_todoist == 1) {
                            Planner.todoist.add_delete_item (item);
                        }
                    }

                    unselect_all ();
                }
    
                message_dialog.destroy ();
            }
        });

        more_button.toggled.connect (() => {
            if (more_button.active) {
                if (more_popover == null) {
                    create_more_popover ();
                }
            }

            more_popover.popup ();
        });
    }

    private void create_reschedule_popover () {
        reschedule_popover = new Gtk.Popover (reschedule_button);
        reschedule_popover.position = Gtk.PositionType.TOP;

        var popover_grid = new Gtk.Grid ();
        popover_grid.margin_top = 6;
        popover_grid.width_request = 235;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (get_calendar_widget ());
        popover_grid.show_all ();

        reschedule_popover.add (popover_grid);

        reschedule_popover.closed.connect (() => {
            reschedule_button.active = false;
        });
    }

    private void create_move_popover () {
        move_popover = new Gtk.Popover (move_button);
        move_popover.position = Gtk.PositionType.TOP;
        move_popover.width_request = 260;
        move_popover.height_request = 300;

        search_entry = new Gtk.SearchEntry ();
        search_entry.margin = 6;

        projects_listbox = new Gtk.ListBox ();
        projects_listbox.activate_on_single_click = true;
        projects_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        projects_listbox.expand = true;
        projects_listbox.set_filter_func ((row) => {
            var project = ((SearchProject) row).project;
            return search_entry.text.down () in project.name.down ();
        });

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        listbox_scrolled.expand = true;
        listbox_scrolled.add (projects_listbox);

        var popover_grid = new Gtk.Grid ();
        popover_grid.expand = true;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (search_entry);
        popover_grid.add (listbox_scrolled);
        popover_grid.show_all ();

        move_popover.add (popover_grid);

        move_popover.closed.connect (() => {
            move_button.active = false;
        });

        search_entry.search_changed.connect (() => {
            projects_listbox.invalidate_filter ();
        });

        projects_listbox.row_activated.connect ((row) => {
            move_project (((SearchProject) row).project);
        });
    }

    private void create_priority_popover () {
        priority_popover = new Gtk.Popover (priority_button);
        priority_popover.position = Gtk.PositionType.TOP;

        var priority_1_menu = new Widgets.ModelButton (_("Priority 1"), "priority-4", "");
        var priority_2_menu = new Widgets.ModelButton (_("Priority 2"), "priority-3", "");
        var priority_3_menu = new Widgets.ModelButton (_("Priority 3"), "priority-2", "");
        priority_4_menu = new Widgets.ModelButton (_("None"), "flag-outline-light", "");

        var popover_grid = new Gtk.Grid ();
        popover_grid.margin_top = 6;
        popover_grid.margin_bottom = 6;
        popover_grid.width_request = 150;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (priority_1_menu);
        popover_grid.add (priority_2_menu);
        popover_grid.add (priority_3_menu);
        popover_grid.add (priority_4_menu);
        popover_grid.show_all ();

        priority_popover.add (popover_grid);

        priority_popover.closed.connect (() => {
            priority_button.active = false;
        });

        priority_1_menu.clicked.connect (() => {
            set_priority (4);
        });

        priority_2_menu.clicked.connect (() => {
            set_priority (3);
        });

        priority_3_menu.clicked.connect (() => {
            set_priority (2);
        });

        priority_4_menu.clicked.connect (() => {
            set_priority (1);
        });
    }

    public void set_priority (int priority) {
        foreach (string key in items_selected.keys) {
            var item = items_selected.get (key).item;
            item.priority = priority;
            
            Planner.database.update_item (item);
            if (item.is_todoist == 1) {
                Planner.todoist.update_item (item);
            }
        }
  
        priority_popover.popdown ();
        unselect_all ();
    }

    private void create_more_popover () {
        more_popover = new Gtk.Popover (more_button);
        more_popover.position = Gtk.PositionType.TOP;

        var complete_menu = new Widgets.ModelButton (_("Complete"), "emblem-default-symbolic", "");
        // var duplicate_menu = new Widgets.ModelButton (_("Duplicate"), "edit-copy-symbolic", "");
        
        var popover_grid = new Gtk.Grid ();
        popover_grid.expand = true;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.margin_top = 6;
        popover_grid.margin_bottom = 6;
        popover_grid.width_request = 175;
        popover_grid.add (complete_menu);
        // popover_grid.add (duplicate_menu);
        popover_grid.show_all ();

        more_popover.add (popover_grid);

        more_popover.closed.connect (() => {
            more_button.active = false;
        });

        complete_menu.clicked.connect (() => {
            foreach (string key in items_selected.keys) {
                var item = items_selected.get (key).item;
                
                item.checked = 1;
                item.date_completed = new GLib.DateTime.now_local ().to_string ();

                Planner.database.update_item_completed (item, false);
                if (item.is_todoist == 1) {
                    Planner.todoist.item_complete (item);
                }
            }
      
            more_popover.popdown ();
            unselect_all ();
        });
    }

    private Gtk.Widget get_calendar_widget () {
        var today_button = new Widgets.ModelButton (_("Today"), "help-about-symbolic", "");
        today_button.get_style_context ().add_class ("due-menuitem");
        today_button.item_image.pixel_size = 14;
        today_button.color = 0;
        today_button.due_label = true;

        var tomorrow_button = new Widgets.ModelButton (_("Tomorrow"), "x-office-calendar-symbolic", "");
        tomorrow_button.get_style_context ().add_class ("due-menuitem");
        tomorrow_button.item_image.pixel_size = 14;
        tomorrow_button.color = 1;
        tomorrow_button.due_label = true;

        undated_button = new Widgets.ModelButton (_("Undated"), "window-close-symbolic", "");
        undated_button.get_style_context ().add_class ("due-menuitem");
        undated_button.item_image.pixel_size = 14;
        undated_button.color = 2;
        undated_button.due_label = true;

        var calendar = new Widgets.Calendar.Calendar ();
        calendar.hexpand = true;

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (today_button);
        grid.add (tomorrow_button);
        grid.add (undated_button);
        grid.add (calendar);
        grid.show_all ();

        today_button.clicked.connect (() => {
            set_due (
                Planner.utils.get_format_date (
                    new GLib.DateTime.now_local ()
                ).to_string ()
            );
        });

        tomorrow_button.clicked.connect (() => {
            set_due (
                Planner.utils.get_format_date (
                    new GLib.DateTime.now_local ().add_days (1)
                ).to_string ()
            );
        });

        undated_button.clicked.connect (() => {
            set_due ("");
        });

        calendar.selection_changed.connect ((date) => {
            set_due (Planner.utils.get_format_date (date).to_string ());
        });

        return grid;
    }

    private void set_due (string date) {
        foreach (string key in items_selected.keys) {
            var item = items_selected.get (key).item;
            bool new_date = false;
            if (item.due_date == "") {
                new_date = true;
            }
            
            item.due_date = date;
            Planner.database.set_due_item (item, new_date);
            if (item.is_todoist == 1) {
                Planner.todoist.update_item (item);
            }
        }

        reschedule_popover.popdown ();
        unselect_all ();
    }

    private void check_select_bar () {
        if (items_selected.size > 0) {
            // select_count_label.label = items_selected.size.to_string ();
            reveal_child = true;
            Planner.event_bus.magic_button_visible (false);
            Planner.event_bus.disconnect_typing_accel ();
        } else {
            reveal_child = false;
            Planner.event_bus.magic_button_visible (true);
            Planner.event_bus.connect_typing_accel ();
        }
    }

    private void unselect_all () {
        foreach (string key in items_selected.keys) {
            items_selected.get (key).item_selected = false;
        }

        items_selected.clear ();
        reveal_child = false;
        Planner.event_bus.magic_button_visible (true);
        Planner.event_bus.connect_typing_accel ();
    }

    private void move_project (Objects.Project project) {
        foreach (string key in items_selected.keys) {
            var item = items_selected.get (key).item;
            Planner.database.move_item (item, project.id);
            if (item.is_todoist == 1) {
                Planner.todoist.move_item (item, project.id);
            }
        }

        search_entry.text = "";
        move_popover.popdown ();
        unselect_all ();
    }
}

public class SearchProject : Gtk.ListBoxRow {
    public Objects.Project project { get; construct set; }

    public SearchProject (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        get_style_context ().add_class ("searchitem-row");

        var icon = new Gtk.Image ();
        icon.valign = Gtk.Align.CENTER;
        icon.halign = Gtk.Align.CENTER;
        icon.pixel_size = 16;
        icon.gicon = new ThemedIcon ("color-%i".printf (project.color));
        if (project.inbox_project == 1) {
            icon.gicon = new ThemedIcon ("planner-inbox");
        }

        var content_label = new Gtk.Label (Planner.utils.get_dialog_text (project.name));
        content_label.ellipsize = Pango.EllipsizeMode.END;
        content_label.xalign = 0;
        content_label.use_markup = true;
        content_label.tooltip_text = project.name;

        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.column_spacing = 6;
        grid.add (icon);
        grid.add (content_label);

        add (grid);
    }
}
