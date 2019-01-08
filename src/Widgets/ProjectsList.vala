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
    private Gtk.ListBox listbox;
    private Widgets.ItemRow inbox_item;
    private Widgets.ItemRow today_item;
    private Widgets.ItemRow upcoming_item;
    private Widgets.ItemRow all_tasks_item;
    private Widgets.ItemRow completed_item;

    public signal void on_selected_item (string type, int index);
    public ProjectsList () {
        Object (
            expand: true
        );
    }

    construct {
        get_style_context ().add_class ("welcome");
        get_style_context ().add_class ("view");
        orientation = Gtk.Orientation.VERTICAL;

        inbox_item = new Widgets.ItemRow (_("Inbox"), "planner-inbox");
        inbox_item.primary_text = Application.database.get_inbox_number ().to_string ();

        today_item = new Widgets.ItemRow (_("Today"), "planner-today-" + new GLib.DateTime.now_local ().get_day_of_month ().to_string ());
        today_item.primary_text = Application.database.get_today_number ().to_string ();

        upcoming_item = new Widgets.ItemRow (_("Upcoming"), "planner-upcoming");

        all_tasks_item = new Widgets.ItemRow (_("All Tasks"), "user-bookmarks");
        all_tasks_item.primary_text = Application.database.get_all_tasks_number ().to_string ();
        all_tasks_item.reveal_child = false;

        completed_item = new Widgets.ItemRow (_("Completed Tasks"), "emblem-default");
        completed_item.primary_text = Application.database.get_completed_number ().to_string  ();
        completed_item.reveal_child = false;

        check_number_labels ();

        listbox = new Gtk.ListBox  ();
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.expand = true;

        var add_project_button = new Gtk.ToggleButton ();
        add_project_button.can_focus = false;
        add_project_button.valign = Gtk.Align.CENTER;
        add_project_button.halign = Gtk.Align.CENTER;
        add_project_button.margin = 6;
        add_project_button.width_request = 48;
        add_project_button.get_style_context ().add_class ("button-circular");
        add_project_button.tooltip_text = _("Add new project");
        add_project_button.add (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR));

        var settings_button = new Gtk.ToggleButton ();
        settings_button.add (new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.MENU));
        settings_button.tooltip_text = _("Settings");
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.halign = Gtk.Align.CENTER;
        settings_button.margin_end = 12;
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        settings_button.get_style_context ().add_class ("settings-button");

        var action_bar = new Gtk.ActionBar ();
        action_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        action_bar.get_style_context ().add_class ("planner-actionbar");
        action_bar.set_center_widget (add_project_button);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.valign = Gtk.Align.START;
        main_grid.expand = true;

        main_grid.add (listbox);

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.add (main_grid);

        var eventbox = new Gtk.EventBox ();
        eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        eventbox.add (scrolled_window);

        add (eventbox);
        add (action_bar);

        add_project_button.grab_focus ();
        update_project_list ();

        if (Application.settings.get_enum ("start-page") == 0) {
            listbox.select_row (inbox_item);
        } else if (Application.settings.get_enum ("start-page") == 1) {
            listbox.select_row (today_item);
        } else {
            listbox.select_row (upcoming_item);
        }

        // Events
        eventbox.enter_notify_event.connect ((event) => {
            /*
            all_tasks_item.reveal_child = true;
            completed_item.reveal_child = true;

            all_tasks_item.margin_start = all_tasks_item.margin_top = all_tasks_item.margin_end = 6;
            completed_item.margin_start = completed_item.margin_top = completed_item.margin_end = completed_item.margin_bottom = 6;

            all_tasks_item.selectable = true;
            completed_item.selectable = true;
            */
            return false;
        });

        eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }
            /*
            all_tasks_item.reveal_child = false;
            completed_item.reveal_child = false;

            all_tasks_item.margin = 0;
            completed_item.margin = 0;

            all_tasks_item.selectable = false;
            completed_item.selectable = false;
            */
            return false;
        });

        var add_popover = new Widgets.Popovers.NewProject (add_project_button);

        add_project_button.toggled.connect (() => {
          if (add_project_button.active) {
            add_popover.show_all ();
          }
        });

        add_popover.closed.connect (() => {
            add_project_button.active = false;
        });

        Application.database.on_add_project_signal.connect (() => {
            var project = Application.database.get_last_project ();
            var row = new Widgets.ProjectRow (project);
            listbox.add (row);
            listbox.show_all ();
        });


        listbox.row_activated.connect ((row) => {
            if (row.get_index () == 0 || row.get_index () == 1 || row.get_index () == 2 || row.get_index () == 3 || row.get_index () == 4) {
                on_selected_item ("item", row.get_index ());

                if (row.get_index () == 3 || row.get_index () == 4) {
                    listbox.unselect_all ();
                }
            } else {
                var project = row as Widgets.ProjectRow;
                on_selected_item ("project", project.project.id);
            }
        });

        Application.database.update_indicators.connect (() => {
            inbox_item.primary_text = Application.database.get_inbox_number ().to_string ();

            today_item.primary_text = Application.database.get_today_number ().to_string ();
            today_item.secondary_text = Application.database.get_before_today_number ().to_string ();

            upcoming_item.primary_text = Application.database.get_upcoming_number ().to_string ();

            all_tasks_item.primary_text = Application.database.get_all_tasks_number ().to_string ();

            completed_item.primary_text = Application.database.get_completed_number ().to_string  ();

            check_number_labels ();
        });

        Application.signals.go_action_page.connect ((index) => {
            if (index == 0) {
                listbox.select_row (inbox_item);
            } else if (index == 1) {
                listbox.select_row (today_item);
            } else if (index == 2) {
                listbox.select_row (upcoming_item);
            } else if (index == 3) {
                //listbox.select_row (all_tasks_item);
            } else if (index == 4) {
                //listbox.select_row (completed_item);
            }
        });

        Application.signals.go_project_page.connect ((project_id) => {
            listbox.set_filter_func ((row) => {
                if (row.get_index () != 0 && row.get_index () != 1 && row.get_index () != 2 && row.get_index () != 3 && row.get_index () != 4 && row.get_index () != 5) {
                    var project = row as Widgets.ProjectRow;

                    if (project.project.id == project_id) {
                        listbox.select_row (project);
                    }
                }

                return true;
            });
        });

        Application.signals.go_task_page.connect ((task_id, project_id) => {
            listbox.set_filter_func ((row) => {
                if (row.get_index () != 0 && row.get_index () != 1 && row.get_index () != 2 && row.get_index () != 3 && row.get_index () != 4 && row.get_index () != 5) {
                    var project = row as Widgets.ProjectRow;

                    if (project.project.id == project_id) {
                        listbox.select_row (project);
                    }
                }

                return true;
            });
        });
    }

    private void check_number_labels () {
        if (int.parse (inbox_item.primary_text) <= 0) {
            inbox_item.revealer_primary_label = false;
        } else {
            inbox_item.revealer_primary_label = true;
        }

        if (int.parse (today_item.primary_text) <= 0) {
            today_item.revealer_primary_label = false;
        } else {
            today_item.revealer_primary_label = true;
        }

        if (int.parse (today_item.secondary_text) <= 0) {
            today_item.revealer_secondary_label = false;
        } else {
            today_item.revealer_secondary_label = true;
        }

        if (int.parse (upcoming_item.primary_text) <= 0) {
            upcoming_item.revealer_primary_label = false;
        } else {
            upcoming_item.revealer_primary_label = true;
        }

        if (int.parse (all_tasks_item.primary_text) <= 0) {
            all_tasks_item.revealer_primary_label = false;
        } else {
            all_tasks_item.revealer_primary_label = true;
        }

        if (int.parse (completed_item.primary_text) <= 0) {
            completed_item.revealer_primary_label = false;
        } else {
            completed_item.revealer_primary_label = true;
        }
    }

    public void update_project_list () {
        foreach (Gtk.Widget element in listbox.get_children ()) {
            listbox.remove (element);
        }

        var all_projects = new Gee.ArrayList<Objects.Project?> ();
        all_projects= Application.database.get_all_projects ();

        foreach (var project in all_projects) {
            var row = new Widgets.ProjectRow (project);
            listbox.add (row);
        }

        listbox.insert (inbox_item, 0);
        listbox.insert (today_item, 1);
        listbox.insert (upcoming_item, 2);
        listbox.insert (all_tasks_item, 3);
        listbox.insert (completed_item, 4);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_top = 12;
        separator.margin_bottom = 6;

        var separator_row = new Gtk.ListBoxRow ();
        separator_row.selectable = false;
        separator_row.activatable = false;
        separator_row.add (separator);

        listbox.insert (separator_row, 5);

        listbox.show_all ();
    }
}
