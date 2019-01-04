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
        upcoming_item.margin_bottom = 6;

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
        //add_project_button.get_style_context ().add_class ("planner-add-button");
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

        add (scrolled_window);
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
            if (row.get_index () == 0 || row.get_index () == 1 || row.get_index () == 2) {
                on_selected_item ("item", row.get_index ());
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

            check_number_labels ();
        });

        Application.signals.go_action_page.connect ((index) => {
            if (index == 0) {
                listbox.select_row (inbox_item);
            } else if (index == 1) {
                listbox.select_row (today_item);
            } else if (index == 2) {
                listbox.select_row (upcoming_item);
            }
        });

        Application.signals.go_project_page.connect ((project_id) => {
            listbox.set_filter_func ((row) => {
                if (row.get_index () != 0 && row.get_index () != 1 && row.get_index () != 2 && row.get_index () != 3) {
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
                if (row.get_index () != 0 && row.get_index () != 1 && row.get_index () != 2 && row.get_index () != 3) {
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

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_top = 6;
        separator.margin_bottom = 6;

        var separator_row = new Gtk.ListBoxRow ();
        separator_row.selectable = false;
        separator_row.activatable = false;
        separator_row.add (separator);

        listbox.insert (separator_row, 3);

        listbox.show_all ();
    }
}
