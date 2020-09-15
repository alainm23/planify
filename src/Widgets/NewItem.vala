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

public class Widgets.NewItem : Gtk.ListBoxRow {
    public int64 project_id { get; set; }
    public int64 section_id { get; construct; }
    public int is_todoist { get; construct; }
    public int index { get; construct; }
    public bool has_index { get; set; default = false; }
    public string due_date { get; set; default = ""; }
    public Gtk.ListBox? listbox { get; construct; }
    private Gtk.ToggleButton project_button;
    private Widgets.ToggleButton reschedule_button;
    private Gtk.Image project_icon;
    private Gtk.Label project_label;
    private Gtk.Popover projects_popover = null;
    private Gtk.Popover reschedule_popover = null;
    private Widgets.ModelButton undated_button;
    private Gtk.ListBox projects_listbox;
    private Gtk.SearchEntry search_entry;

    public int64 temp_id_mapping {get; set; default = 0; }

    private uint timeout_id = 0;
    private uint focus_timeout = 0;

    private Widgets.Entry content_entry;
    private Gtk.Revealer main_revealer;
    private bool entry_menu_opened = false;

    public NewItem (int64 project_id, int64 section_id, 
                    int is_todoist, string due_date="", 
                    int index, Gtk.ListBox? listbox=null) {
        Object (
            project_id: project_id,
            section_id: section_id,
            is_todoist: is_todoist,
            due_date: due_date,
            index: index,
            listbox: listbox
        );

        can_focus = false;
        activatable = false;
        selectable = false;
        get_style_context ().add_class ("item-row");
        margin_end = 6;

        var checked_button = new Gtk.CheckButton ();
        checked_button.margin_start = 6;
        checked_button.get_style_context ().add_class ("priority-1");
        checked_button.valign = Gtk.Align.CENTER;

        content_entry = new Widgets.Entry ();
        content_entry.hexpand = true;
        content_entry.margin_start = 4;
        content_entry.placeholder_text = _("Task name");
        content_entry.get_style_context ().add_class ("flat");
        content_entry.get_style_context ().add_class ("new-entry");
        content_entry.get_style_context ().add_class ("no-padding-right");

        var content_grid = new Gtk.Grid ();
        content_grid.margin_end = 12;
        content_grid.margin_top = 3;
        content_grid.add (checked_button);
        content_grid.add (content_entry);

        var submit_button = new Gtk.Button ();
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var submit_spinner = new Gtk.Spinner ();
        submit_spinner.start ();

        var submit_stack = new Gtk.Stack ();
        submit_stack.expand = true;
        submit_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        submit_stack.add_named (new Gtk.Label (_("Add")), "label");
        submit_stack.add_named (submit_spinner, "spinner");

        submit_button.add (submit_stack);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("cancel-button");

        var buttons_grid = new Gtk.Grid ();
        buttons_grid.halign = Gtk.Align.START;
        buttons_grid.column_spacing = 6;
        buttons_grid.margin_start = 6;
        buttons_grid.column_homogeneous = true;
        buttons_grid.add (cancel_button);
        buttons_grid.add (submit_button);

        reschedule_button = new Widgets.ToggleButton (_("Schedule"), "office-calendar-symbolic");
        reschedule_button.get_style_context ().add_class ("flat");
        reschedule_button.halign = Gtk.Align.START;
        update_date_text ();

        var project = Planner.database.get_project_by_id (project_id);

        project_icon = new Gtk.Image ();
        project_icon.valign = Gtk.Align.CENTER;
        project_icon.halign = Gtk.Align.CENTER;
        project_icon.pixel_size = 14;
        project_icon.gicon = new ThemedIcon ("color-%i".printf (project.color));
        if (project.inbox_project == 1) {
            project_icon.gicon = new ThemedIcon ("planner-inbox");
        }

        project_label = new Gtk.Label (project.name);

        var project_grid = new Gtk.Grid ();
        project_grid.add (project_icon);
        project_grid.add (project_label);

        project_button = new Gtk.ToggleButton ();
        project_button.get_style_context ().add_class ("flat");
        project_button.halign = Gtk.Align.START;
        project_button.valign = Gtk.Align.CENTER;
        project_button.add (project_grid);

        var tools_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        tools_box.margin_bottom = 3;
        tools_box.margin_start = 6;
        tools_box.margin_top = 6;
        tools_box.hexpand = true;
        tools_box.pack_end (project_button, false, false, 0);
        tools_box.pack_end (reschedule_button, false, false, 0);
        
        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.row_spacing = 0;
        main_grid.expand = false;
        main_grid.margin_top = 6;
        main_grid.margin_bottom= 6;
        main_grid.margin_start = 6;
        main_grid.get_style_context ().add_class ("check-eventbox");
        main_grid.get_style_context ().add_class ("check-eventbox-border");
        main_grid.add (content_grid);
        main_grid.add (tools_box);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (main_grid);
        grid.add (buttons_grid);

        main_revealer = new Gtk.Revealer ();
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (grid);
        main_revealer.reveal_child = false;

        add (main_revealer);

        timeout_id = Timeout.add (150, () => {
            timeout_id = 0;

            content_entry.grab_focus ();
            main_revealer.reveal_child = true;
            
            grab_focus ();
            return false;
        });

        submit_button.clicked.connect (insert_item);

        content_entry.activate.connect (() => {
            insert_item ();
        });

        content_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_destroy ();
            }

            return false;
        });

        content_entry.focus_out_event.connect (() => {
            focus_timeout = Timeout.add (1000, () => {
                focus_timeout = 0;
                if (entry_menu_opened == false && content_entry.text.strip () == "") {
                    timeout_id = Timeout.add (250, () => {
                        timeout_id = 0;
        
                        if (temp_id_mapping == 0) {
                            hide_destroy ();
                        }
        
                        return false;
                    });
                }

                return false;
            });

            return false;
        }); 

        content_entry.focus_in_event.connect (() => {
            if (focus_timeout != 0) {
                GLib.Source.remove (focus_timeout);
            }

            return false;
        });

        content_entry.changed.connect (() => {
            if (content_entry.text != "") {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }
        });

        cancel_button.clicked.connect (() => {
            hide_destroy ();
        });

        Planner.todoist.item_added_started.connect ((id) => {
            if (temp_id_mapping == id) {
                submit_stack.visible_child_name = "spinner";
                sensitive = false;
            }
        });

        Planner.todoist.item_added_completed.connect ((id) => {
            if (temp_id_mapping == id) {
                var i = index;
                if (i != -1) {
                    i++;
                }

                var new_item = new Widgets.NewItem (
                    project_id,
                    section_id,
                    is_todoist,
                    due_date,
                    i,
                    listbox
                );

                if (index == -1) {
                    listbox.add (new_item);
                } else {
                    listbox.insert (new_item, i);
                }

                listbox.show_all ();
                hide_destroy ();
            }
        });

        Planner.todoist.item_added_error.connect ((id) => {
            if (temp_id_mapping == id) {
                submit_stack.visible_child_name = "label";
                sensitive = true;
                content_entry.text = "";
            }
        });

        content_entry.populate_popup.connect ((menu) => {
            entry_menu_opened = true;
            menu.hide.connect (() => {
                entry_menu_opened = false;
            });
        });

        project_button.toggled.connect (() => {
            if (project_button.active) {
                if (projects_popover == null) {
                    create_projects_popover ();
                }

                foreach (var child in projects_listbox.get_children ()) {
                    child.destroy ();
                }
    
                SearchProject item_menu;
                foreach (var p in Planner.database.get_all_projects ()) {
                    item_menu = new SearchProject (p);
                    projects_listbox.add (item_menu);
                }
    
                projects_listbox.show_all ();
                projects_popover.show_all ();
                projects_popover.popup ();
                search_entry.grab_focus ();
            }
        });

        reschedule_button.toggled.connect (() => {
            if (reschedule_button.active) {
                if (reschedule_popover == null) {
                    create_reschedule_popover ();
                }

                //  undated_button.visible = false;
                //  undated_button.no_show_all = true;
                //  if (due_date != "") {
                //      undated_button.visible = true;
                //      undated_button.no_show_all = false;
                //  }
                
                reschedule_popover.show_all ();
                reschedule_popover.popup ();
            }
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

        reschedule_popover.show.connect (() => {
            entry_menu_opened = true;
        });

        reschedule_popover.closed.connect (() => {
            reschedule_button.active = false;
            entry_menu_opened = false;

            content_entry.grab_focus_without_selecting ();
            if (content_entry.cursor_position < content_entry.text_length) {
            content_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) content_entry.text_length, false);
            }
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
            due_date = get_datetime (new GLib.DateTime.now_local ());
            update_date_text ();
            reschedule_popover.popdown ();
        });

        tomorrow_button.clicked.connect (() => {
            due_date = get_datetime (new GLib.DateTime.now_local ().add_days (1));
            update_date_text ();
            reschedule_popover.popdown ();
        });

        undated_button.clicked.connect (() => {
            due_date = "";
            update_date_text ();
            reschedule_popover.popdown ();
        });

        calendar.selection_changed.connect ((date) => {
            due_date = get_datetime (date);
            update_date_text ();
            reschedule_popover.popdown ();
        });

        return grid;
    }

    private string get_datetime (GLib.DateTime date) {
        GLib.DateTime datetime;
        //  if (time_switch.active) {
        //      datetime = new GLib.DateTime.local (
        //          date.get_year (),
        //          date.get_month (),
        //          date.get_day_of_month (),
        //          time_picker.time.get_hour (),
        //          time_picker.time.get_minute (),
        //          time_picker.time.get_second ()
        //      );
        //  } else {
            datetime = new GLib.DateTime.local (
                date.get_year (),
                date.get_month (),
                date.get_day_of_month (),
                0,
                0,
                0
            );
        // }

        return datetime.to_string ();
    }

    public void entry_grab_focus () {
        content_entry.grab_focus ();
    }

    private void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (500, () => {
            destroy ();
            return false;
        });
    }

    private void insert_item () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
        }

        if (content_entry.text.strip () != "") {
            var item = new Objects.Item ();            
            item.project_id = project_id;
            item.section_id = section_id;
            item.is_todoist = is_todoist;
            item.due_date = due_date;
            Planner.utils.parse_item_tags (item, content_entry.text);
            temp_id_mapping = Planner.utils.generate_id ();
            
            if (is_todoist == 1) {
                Planner.todoist.add_item (item, index, temp_id_mapping);
            } else {
                item.id = Planner.utils.generate_id ();
                if (Planner.database.insert_item (item, index)) {
                    var i = index;
                    if (i != -1) {
                        i++;
                    }

                    var new_item = new Widgets.NewItem (
                        project_id,
                        section_id,
                        is_todoist,
                        due_date,
                        i,
                        listbox
                    );

                    if (index == -1) {
                        listbox.add (new_item);
                    } else {
                        listbox.insert (new_item, i);
                    }

                    listbox.show_all ();
                    hide_destroy ();
                }
            }
        }
    }

    private void create_projects_popover () {
        projects_popover = new Gtk.Popover (project_button);
        projects_popover.position = Gtk.PositionType.TOP;
        projects_popover.width_request = 260;
        projects_popover.height_request = 300;

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

        projects_popover.add (popover_grid);

        projects_popover.show.connect (() => {
            entry_menu_opened = true;
        });

        projects_popover.closed.connect (() => {
            project_button.active = false;
            entry_menu_opened = false;

            content_entry.grab_focus_without_selecting ();
            if (content_entry.cursor_position < content_entry.text_length) {
            content_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) content_entry.text_length, false);
            }
        });

        search_entry.search_changed.connect (() => {
            projects_listbox.invalidate_filter ();
        });

        projects_listbox.row_activated.connect ((row) => {
            var project = ((SearchProject) row).project;
            project_label.label = project.name;
            project_id = project.id;
            project_icon.gicon = new ThemedIcon ("color-%i".printf (project.color));

            if (project.inbox_project == 1) {
                project_icon.gicon = new ThemedIcon ("planner-inbox");
            }

            projects_popover.popdown ();
        });
    }

    public void update_date_text () {
        reschedule_button.item_label.label = _("Schedule");
        reschedule_button.item_image.get_style_context ().remove_class ("overdue-label");
        reschedule_button.item_image.get_style_context ().remove_class ("today");
        reschedule_button.item_image.get_style_context ().remove_class ("upcoming");

        if (due_date != "") {
            var date = new GLib.DateTime.from_iso8601 (due_date, new GLib.TimeZone.local ());
            reschedule_button.item_label.label = Planner.utils.get_relative_date_from_date (date);

            if (Planner.utils.is_today (date)) {
                reschedule_button.item_image.gicon = new ThemedIcon ("help-about-symbolic");
                reschedule_button.item_image.get_style_context ().add_class ("today");
            } else if (Planner.utils.is_overdue (date)) {
                reschedule_button.item_image.gicon = new ThemedIcon ("office-calendar-symbolic");
            } else {
                reschedule_button.item_image.gicon = new ThemedIcon ("office-calendar-symbolic");
                reschedule_button.item_image.get_style_context ().add_class ("upcoming");
            }
        }
    }
}
