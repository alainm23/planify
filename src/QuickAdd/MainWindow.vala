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

public class MainWindow : Gtk.Window {
    private const string TODAY = _("today");
    private const string TOMORROW = _("tomorrow");
    private const string DATE_1D = _("1d");
    private const string DATE_1W = _("1w");
    private const string DATE_1M = _("1m");

    private Gtk.CheckButton checked_button;
    private Gtk.Stack stack;
    private Gtk.Entry content_entry;

    private DBusClient dbus_client;
    private Gtk.ToggleButton priority_button;
    private Gtk.Image priority_image;
    private Gtk.Popover priority_popover = null;
    private Gtk.Popover reschedule_popover = null;
    private ModelButton priority_4_menu;
    private Gtk.ToggleButton project_button;
    private Gtk.Popover projects_popover = null;
    private ModelButton undated_button;
    private Gtk.Image project_icon;
    private Gtk.Label project_label;
    private Gtk.ListBox projects_listbox;
    private Gtk.SearchEntry search_entry;
    private Gtk.ToggleButton reschedule_button;
    private Gtk.Switch time_switch;
    private Granite.Widgets.TimePicker time_picker;
    private Gtk.Revealer time_picker_revealer;
    private Gtk.Image due_image;
    private Gtk.Label due_label;
    private Gtk.Label time_label;
    private Gtk.Revealer time_revealer;
    private bool entry_menu_opened = false;

    public int priority { get; set; default = 1; }
    public string due_date { get; set; default = ""; }
    public Project project { get; set; }

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            resizable: false,
            width_request: 700,
            skip_taskbar_hint: true,
            window_position: Gtk.WindowPosition.CENTER_ALWAYS
        );
    }

    construct {
        stick ();
        set_keep_above (true);

        dbus_client = DBusClient.get_default ();

        checked_button = new Gtk.CheckButton ();
        checked_button.margin_start = 6;
        checked_button.get_style_context ().add_class ("priority-1");
        checked_button.valign = Gtk.Align.CENTER;

        content_entry = new Gtk.Entry ();
        content_entry.hexpand = true;
        content_entry.placeholder_text = _("Task name");
        content_entry.get_style_context ().add_class ("flat");
        content_entry.get_style_context ().add_class ("content-entry");
        content_entry.get_style_context ().add_class ("no-padding-right");

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
        top_box.margin_top = 3;
        top_box.margin_end = 9;
        top_box.hexpand = true;
        top_box.pack_start (checked_button, false, false, 0);
        top_box.pack_start (content_entry, false, true, 0);

        var submit_button = new Gtk.Button ();
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var submit_spinner = new Gtk.Spinner ();
        submit_spinner.start ();

        var submit_stack = new Gtk.Stack ();
        submit_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        submit_stack.add_named (new Gtk.Label (_("Add Task")), "label");
        submit_stack.add_named (submit_spinner, "spinner");

        submit_button.add (submit_stack);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("view");

        var action_grid = new Gtk.Grid ();
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 6;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        priority_image = new Gtk.Image ();
        priority_image.pixel_size = 16;
        priority_image.gicon = new ThemedIcon ("edit-flag-symbolic");

        priority_button = new Gtk.ToggleButton ();
        priority_button.get_style_context ().add_class ("flat");
        priority_button.add (priority_image);

        // Project Button
        if (PlannerQuickAdd.settings.get_boolean ("quick-add-save-last-project")) {
            project = PlannerQuickAdd.database.get_project_by_id (PlannerQuickAdd.settings.get_int64 ("quick-add-project-selected"));
        } else {
            project = PlannerQuickAdd.database.get_project_by_id (PlannerQuickAdd.settings.get_int64 ("inbox-project"));
        }

        project_icon = new Gtk.Image ();
        project_icon.valign = Gtk.Align.CENTER;
        project_icon.halign = Gtk.Align.CENTER;
        project_icon.pixel_size = 16;
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

        reschedule_button = new Gtk.ToggleButton ();
        reschedule_button.get_style_context ().add_class ("flat");
        reschedule_button.halign = Gtk.Align.START;
        reschedule_button.add (get_schedule_grid ());
        update_due_date ();

        var tools_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        tools_box.margin_bottom = 3;
        tools_box.margin_start = 6;
        tools_box.margin_top = 6;
        tools_box.hexpand = true;
        tools_box.pack_end (project_button, false, false, 0);
        tools_box.pack_end (reschedule_button, false, false, 0);
        tools_box.pack_end (priority_button, false, false, 0);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.row_spacing = 0;
        main_grid.expand = false;
        main_grid.margin_top = 6;
        main_grid.margin_bottom= 6;
        main_grid.margin_start = 6;
        main_grid.get_style_context ().add_class ("check-grid");
        main_grid.add (top_box);
        main_grid.add (tools_box);

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        action_box.margin_top = 6;
        action_box.margin_start = 5;
        action_box.hexpand = true;
        action_box.pack_start (action_grid, false, false, 0);
        // action_box.pack_end (project_button, false, false, 0);
        // action_box.pack_end (priority_button, false, false, 0);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.margin = 12;
        main_box.margin_end = 16;
        main_box.expand = true;
        main_box.pack_start (main_grid, false, false, 0);
        main_box.pack_end (action_box, false, false, 0);

        var warning_image = new Gtk.Image ();
        warning_image.gicon = new ThemedIcon ("dialog-warning");
        warning_image.pixel_size = 32;

        var warning_label = new Gtk.Label (_("I'm sorry, Quick Add can't find any project available, try creating a project from Planner."));
        warning_label.wrap = true;
        warning_label.max_width_chars = 42;
        warning_label.xalign = 0;

        var warning_grid = new Gtk.Grid ();
        warning_grid.halign = Gtk.Align.CENTER;
        warning_grid.valign = Gtk.Align.CENTER;
        warning_grid.column_spacing = 12;
        warning_grid.add (warning_image);
        warning_grid.add (warning_label);

        stack = new Gtk.Stack ();
        stack.expand = true;
        stack.valign = Gtk.Align.START;
        stack.get_style_context ().add_class ("fake-window");
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        stack.add_named (main_box, "main_box");
        stack.add_named (warning_grid, "warning_grid");

        var event_box = new Gtk.EventBox ();
        event_box.expand = true;
        event_box.height_request = 300;
        
        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (stack);
        grid.add (event_box);

        add (grid);

        Timeout.add (125, () => {
            if (PlannerQuickAdd.database.is_database_empty ()) {
                stack.visible_child_name = "warning_grid";
            } else {
                stack.visible_child_name = "main_box";
                content_entry.grab_focus ();
            }

            return false;
        });
        
        get_style_context ().add_class ("quick-add");

        cancel_button.clicked.connect (() => {
            hide ();
            /* Retain the window for a short time so that the keybinding
             * listener does not instantiate a new one right after closing
            */
            Timeout.add (500, () => {
                destroy ();
                return false;
            });
        });

        content_entry.changed.connect (() => {
            if (content_entry.text.strip () != "") {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }

            parse_item_tags (content_entry.text);
        });

        submit_button.clicked.connect (add_item);
        content_entry.activate.connect (add_item);

        content_entry.populate_popup.connect ((menu) => {
            entry_menu_opened = true;
            menu.hide.connect (() => {
                entry_menu_opened = false;
            });
        });

        PlannerQuickAdd.database.item_added_started.connect (() => {
            sensitive = false;
            submit_stack.visible_child_name = "spinner";
        });

        PlannerQuickAdd.database.item_added_completed.connect (() => {
            sensitive = true;
            submit_stack.visible_child_name = "label";
        });

        PlannerQuickAdd.database.item_added_error.connect ((http_code, error_message) => {

        });

        PlannerQuickAdd.database.item_added.connect ((item) => {
            hide ();

            send_notification (item.content, _("The task was correctly added."));

            content_entry.text = "";
            content_entry.grab_focus ();

            try {
                dbus_client.interface.add_item (item.id);
            } catch (Error e) {
                debug (e.message);
            }

            Timeout.add (500, () => {
                destroy ();
                return false;
            });
        });

        focus_out_event.connect ((event) => {
            if (Posix.isatty (Posix.STDIN_FILENO) == false &&
                PlannerQuickAdd.database.is_adding == false &&
                entry_menu_opened == false) {
                hide ();

                Timeout.add (500, () => {
                    destroy ();
                    return false;
                });
            }

            return Gdk.EVENT_STOP;
        });

        priority_button.toggled.connect (() => {
            if (priority_button.active) {
                if (priority_popover == null) {
                    create_priority_popover ();
                }
            }

            if (PlannerQuickAdd.settings.get_enum ("appearance") == 0) {
                priority_4_menu.item_image.gicon = new ThemedIcon ("flag-outline-light");
            } else {
                priority_4_menu.item_image.gicon = new ThemedIcon ("flag-outline-dark");
            }

            priority_popover.show_all ();
            priority_popover.popup ();
        });

        notify["priority"].connect (() => {
            update_priority (priority);
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
                foreach (var p in PlannerQuickAdd.database.get_all_projects ()) {
                    item_menu = new SearchProject (p);
                    projects_listbox.add (item_menu);
                }
    
                projects_listbox.show_all ();
                projects_popover.show_all ();
                projects_popover.popup ();
                search_entry.grab_focus ();
            }
        });

        event_box.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                hide ();
                /* Retain the window for a short time so that the keybinding
                * listener does not instantiate a new one right after closing
                */
                Timeout.add (500, () => {
                    destroy ();
                    return false;
                });

                return true;
            }

            return false;
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

    private void create_projects_popover () {
        projects_popover = new Gtk.Popover (project_button);
        projects_popover.position = Gtk.PositionType.BOTTOM;
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
            project = ((SearchProject) row).project;

            PlannerQuickAdd.settings.set_int64 ("quick-add-project-selected", project.id);
            project_label.label = project.name;
            project_icon.gicon = new ThemedIcon ("color-%i".printf (project.color));

            if (project.inbox_project == 1) {
                project_icon.gicon = new ThemedIcon ("planner-inbox");
                project_icon.pixel_size = 16;
            }

            projects_popover.popdown ();
        });
    }

    private void create_reschedule_popover () {
        reschedule_popover = new Gtk.Popover (reschedule_button);
        reschedule_popover.position = Gtk.PositionType.TOP;

        var popover_grid = new Gtk.Grid ();
        popover_grid.margin_top = 6;
        popover_grid.width_request = 235;
        popover_grid.margin_bottom = 12;
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

    private void create_priority_popover () {
        priority_popover = new Gtk.Popover (priority_button);
        priority_popover.position = Gtk.PositionType.BOTTOM;

        var priority_1_menu = new ModelButton (_("Priority 1"), "priority-4", "");
        var priority_2_menu = new ModelButton (_("Priority 2"), "priority-3", "");
        var priority_3_menu = new ModelButton (_("Priority 3"), "priority-2", "");
        priority_4_menu = new ModelButton (_("None"), "flag-outline-light", "");

        var popover_grid = new Gtk.Grid ();
        popover_grid.margin_top = 3;
        popover_grid.margin_bottom = 3;
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
            entry_menu_opened = false;

            content_entry.grab_focus_without_selecting ();
            if (content_entry.cursor_position < content_entry.text_length) {
            content_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) content_entry.text_length, false);
            }
        });

        priority_popover.show.connect (() => {
            entry_menu_opened = true;
        });

        priority_1_menu.clicked.connect (() => {
            update_priority (4);
            priority_popover.popdown ();
        });

        priority_2_menu.clicked.connect (() => {
            update_priority (3);
            priority_popover.popdown ();
        });

        priority_3_menu.clicked.connect (() => {
            update_priority (2);
            priority_popover.popdown ();
        });

        priority_4_menu.clicked.connect (() => {
            update_priority (1);
            priority_popover.popdown ();
        });
    }

    private Gtk.Widget get_calendar_widget () {
        var today_button = new ModelButton (_("Today"), "help-about-symbolic", "");
        today_button.get_style_context ().add_class ("due-menuitem");
        today_button.item_image.pixel_size = 14;
        today_button.color = 0;
        today_button.due_label = true;

        var tomorrow_button = new ModelButton (_("Tomorrow"), "x-office-calendar-symbolic", "");
        tomorrow_button.get_style_context ().add_class ("due-menuitem");
        tomorrow_button.item_image.pixel_size = 14;
        tomorrow_button.color = 1;
        tomorrow_button.due_label = true;

        undated_button = new ModelButton (_("Undated"), "window-close-symbolic", "");
        undated_button.get_style_context ().add_class ("due-menuitem");
        undated_button.item_image.pixel_size = 14;
        undated_button.color = 2;
        undated_button.due_label = true;

        var calendar = new Gtk.Calendar ();
        calendar.margin_start = 12;
        calendar.margin_end = 12;

        var time_header = new Gtk.Label (_("Time"));
        time_header.get_style_context ().add_class ("font-bold");

        time_switch = new Gtk.Switch ();
        time_switch.get_style_context ().add_class ("active-switch");

        var time_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        time_box.hexpand = true;
        time_box.margin_start = 16;
        time_box.margin_end = 16;
        time_box.pack_start (time_header, false, false, 0);
        time_box.pack_end (time_switch, false, false, 0);
        
        time_picker = new Granite.Widgets.TimePicker ();
        time_picker.margin_start = 16;
        time_picker.margin_end = 16;
        time_picker.margin_top = 6;

        time_picker_revealer = new Gtk.Revealer ();
        time_picker_revealer.reveal_child = false;
        time_picker_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        time_picker_revealer.add (time_picker);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (today_button);
        grid.add (tomorrow_button);
        grid.add (undated_button);
        grid.add (calendar);
        grid.add (time_box);
        grid.add (time_picker_revealer);
        grid.show_all ();

        today_button.clicked.connect (() => {
            due_date = new GLib.DateTime.now_local ().to_string ();
            update_due_date ();
            reschedule_popover.popdown ();
        });

        tomorrow_button.clicked.connect (() => {
            due_date = new GLib.DateTime.now_local ().add_days (1).to_string ();
            update_due_date ();
            reschedule_popover.popdown ();
        });

        undated_button.clicked.connect (() => {
            due_date = "";
            update_due_date ();
            reschedule_popover.popdown ();
        });

        calendar.day_selected.connect (() => {
            due_date = new GLib.DateTime.local (
                calendar.year,
                calendar.month + 1,
                calendar.day,
                0,
                0,
                0
            ).to_string ();
            update_due_date ();
            reschedule_popover.popdown ();
        });
        
        time_switch.notify["active"].connect (() => {
            time_picker_revealer.reveal_child = time_switch.active;

            if (time_switch.active && due_date == "") {
                due_date = new GLib.DateTime.now_local ().to_string ();
            }

            update_due_date ();
        });

        time_picker.changed.connect (() => {
            update_due_date ();
        });

        return grid;
    }

    private void update_priority (int p) {
        priority = p;

        checked_button.get_style_context ().remove_class ("priority-4");
        checked_button.get_style_context ().remove_class ("priority-3");
        checked_button.get_style_context ().remove_class ("priority-2");
        checked_button.get_style_context ().remove_class ("priority-1");

        if (p == 1 || p == 0) {
            if (PlannerQuickAdd.settings.get_enum ("appearance") == 0) {
                priority_image.gicon = new ThemedIcon ("flag-outline-light");
            } else {
                priority_image.gicon = new ThemedIcon ("flag-outline-dark");
            }
        } else {
            priority_image.gicon = new ThemedIcon ("priority-%i".printf (p));
        }

        if (priority == 0 || priority == 1) {
            checked_button.get_style_context ().add_class ("priority-1");
        } else if (priority == 2) {
            checked_button.get_style_context ().add_class ("priority-2");
        } else if (priority == 3) {
            checked_button.get_style_context ().add_class ("priority-3");
        } else if (priority == 4) {
            checked_button.get_style_context ().add_class ("priority-4");
            priority_image.get_style_context ().add_class ("priority-4-icon");
        } else {
            checked_button.get_style_context ().add_class ("priority-1");
        }
    }

    private void add_item () {
        if (content_entry.text.strip () != "") {
            var item = new Item ();
            item.content = content_entry.text;
            item.priority = priority;  
            item.id = generate_id ();
            item.project_id = project.id;
            item.is_todoist = project.is_todoist;
            item.due_date = due_date;

            if (project.is_todoist == 1) {
                PlannerQuickAdd.database.add_todoist_item (item);
            } else {
                PlannerQuickAdd.database.insert_item (item);
            }
            //  if (project.inbox_project == 1) {
            //      if (PlannerQuickAdd.database.get_project_by_id (PlannerQuickAdd.settings.get_int64 ("inbox-project")).is_todoist == 1) {
            //          PlannerQuickAdd.database.add_todoist_item (item);
            //      } else {
            //          PlannerQuickAdd.database.insert_item (item);
            //      }
            //  } else {
            //      if (project.is_todoist == 0) {
            //          PlannerQuickAdd.database.insert_item (item);
            //      } else {
            //          PlannerQuickAdd.database.add_todoist_item (item);
            //      }
            //  }
        }
    }

    public void parse_item_tags (string text) {
        Regex word_regex = /\S+\s*/;
        MatchInfo match_info;
        
        try {
            var match_text = text.strip ();
            for (word_regex.match (match_text, 0, out match_info) ; match_info.matches () ; match_info.next ()) {
                var word = match_info.fetch (0);
                var stripped = word.strip ().down ();

                switch (stripped) {
                    case TODAY:
                        due_date = get_datetime (new GLib.DateTime.now_local ()).to_string ();
                        update_due_date ();
                        break;
                    case TOMORROW:
                        due_date = get_datetime (new GLib.DateTime.now_local ().add_days (1)).to_string ();
                        update_due_date ();
                        break;
                    case DATE_1D:
                        due_date = get_datetime (new GLib.DateTime.now_local ().add_days (1)).to_string ();
                        update_due_date ();
                        break;
                    case DATE_1W:
                        due_date = get_datetime (new GLib.DateTime.now_local ().add_days (7)).to_string ();
                        update_due_date ();
                        break;
                    case DATE_1M:
                        due_date = get_datetime (new GLib.DateTime.now_local ().add_months (1)).to_string ();
                        update_due_date ();
                        break;
                    case "p1":
                        priority = 4;
                        break;
                    case "p2":
                        priority = 3;
                        break;
                    case "p3":
                        priority = 2;
                        break;
                    case "p4":
                        priority = 1;
                        break;
                    default:
                        break;
                }
            }
        } catch (GLib.RegexError ex) {
            
        }
    }

    public int64 generate_id (int len=10) {
        string allowed_characters = "0123456789";

        var password_builder = new StringBuilder ();
        for (var i = 0; i < len; i++) {
            var random_index = Random.int_range (0, allowed_characters.length);
            password_builder.append_c (allowed_characters[random_index]);
        }

        if (int64.parse (password_builder.str) <= 0) {
            return generate_id ();
        }

        return int64.parse (password_builder.str);
    }

    private void send_notification (string title, string body) {
        var notification = new Notification (title);
        notification.set_body (body);
        notification.set_icon (new ThemedIcon ("com.github.alainm23.planner"));
        notification.set_priority (GLib.NotificationPriority.LOW);

        application.send_notification ("com.github.alainm23.planner", notification);
    }

    private void update_due_date () {
        due_date = get_datetime_from_string (due_date);

        due_label.label = _("Schedule");
        due_image.gicon = new ThemedIcon ("office-calendar-symbolic");

        due_image.get_style_context ().remove_class ("overdue-label");
        due_image.get_style_context ().remove_class ("today");
        due_image.get_style_context ().remove_class ("upcoming");

        time_revealer.reveal_child = false;
        if (due_date != "") {
            var datetime = new GLib.DateTime.from_iso8601 (due_date, new GLib.TimeZone.local ());
            due_label.label = get_relative_date_from_date (datetime);

            if (has_time (datetime)) {
                time_label.label = datetime.format (get_default_time_format ());
                time_revealer.reveal_child = true;
            }

            if (is_today (datetime)) {
                due_image.gicon = new ThemedIcon ("help-about-symbolic");
                due_image.get_style_context ().add_class ("today");
            } else if (is_overdue (datetime)) {
                due_image.gicon = new ThemedIcon ("calendar-overdue");
                due_image.get_style_context ().add_class ("overdue-label");
            } else {
                due_image.gicon = new ThemedIcon ("office-calendar-symbolic");
                due_image.get_style_context ().add_class ("upcoming");
            }
        }
    }

    public string get_default_time_format () {
        var settings = new Settings ("org.gnome.desktop.interface");
        return Granite.DateTime.get_default_time_format (settings.get_enum ("clock-format") == 1, false);
    }

    private bool has_time (GLib.DateTime datetime) {
        bool returned = true;
        if (datetime.get_hour () == 0 && datetime.get_minute () == 0 && datetime.get_second () == 0) {
            returned = false;
        }

        return returned;
    }

    private bool is_today (GLib.DateTime date) {
        return Granite.DateTime.is_same_day (date, new GLib.DateTime.now_local ());
    }

    private bool is_overdue (GLib.DateTime date) {
        var now = get_format_date (new DateTime.now_local ());

        if (get_format_date (date).compare (now) == -1) {
            return true;
        }

        return false;
    }

    private GLib.DateTime get_format_date (GLib.DateTime date) {
        return new DateTime.local (
            date.get_year (),
            date.get_month (),
            date.get_day_of_month (),
            0,
            0,
            0
        );
    }

    private bool is_tomorrow (GLib.DateTime date) {
        return Granite.DateTime.is_same_day (date, new GLib.DateTime.now_local ().add_days (1));
    }

    private string get_relative_date_from_date (GLib.DateTime date) {
        if (is_today (date)) {
            return _("Today");
        } else if (is_tomorrow (date)) {
            return _("Tomorrow");
        } else if (is_overdue (date)) {
            return Granite.DateTime.get_relative_datetime (date);
        } else {
            return get_default_date_format_from_date (date);
        }
    }

    private string get_default_date_format_from_date (GLib.DateTime date) {
        var now = new GLib.DateTime.now_local ();

        if (date.get_year () == now.get_year ()) {
            return date.format (Granite.DateTime.get_default_date_format (false, true, false));
        } else {
            return date.format (Granite.DateTime.get_default_date_format (false, true, true));
        }
    }

    private Gtk.Widget get_schedule_grid () {
        due_image = new Gtk.Image ();
        due_image.gicon = new ThemedIcon ("office-calendar-symbolic");
        due_image.valign = Gtk.Align.CENTER;
        due_image.pixel_size = 16;

        due_label = new Gtk.Label (_("Schedule"));
        due_label.use_markup = true;

        time_label = new Gtk.Label (null);
        time_label.use_markup = true;

        time_revealer = new Gtk.Revealer ();
        time_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        time_revealer.add (time_label);
        time_revealer.reveal_child = false;

        var main_grid = new Gtk.Grid ();
        main_grid.halign = Gtk.Align.CENTER;
        main_grid.valign = Gtk.Align.CENTER;
        main_grid.add (due_image);
        main_grid.add (due_label);
        main_grid.add (time_revealer);

        return main_grid;
    }

    private string get_datetime_from_string (string date) {
        if (date != "") {
            return get_datetime (new GLib.DateTime.from_iso8601 (date, new GLib.TimeZone.local ()));
        }

        return date;
    }

    private string get_datetime (GLib.DateTime date) {
        GLib.DateTime datetime;
        if (time_switch.active) {
            datetime = new GLib.DateTime.local (
                date.get_year (),
                date.get_month (),
                date.get_day_of_month (),
                time_picker.time.get_hour (),
                time_picker.time.get_minute (),
                time_picker.time.get_second ()
            );
        } else {
            datetime = new GLib.DateTime.local (
                date.get_year (),
                date.get_month (),
                date.get_day_of_month (),
                0,
                0,
                0
            );
        }

        return datetime.to_string ();
    }
}

public class ModelButton : Gtk.Button {
    public bool arrow { get; construct; }
    private Gtk.Label item_label;
    public Gtk.Image item_image;

    public string icon {
        set {
            item_image.gicon = new ThemedIcon (value);
        }
    }
    public string tooltip {
        set {
            tooltip_text = value;
        }
    }
    public string text {
        set {
            item_label.label = value;
        }
    }

    public int color {
        set {
            if (value == 0) {
                item_image.get_style_context ().add_class ("today-icon");
                //  var hour = new GLib.DateTime.now_local ().get_hour ();
                //  if (hour >= 18 || hour <= 6) {
                //      item_image.get_style_context ().add_class ("today-night-icon");
                //  } else {
                //      item_image.get_style_context ().add_class ("today-icon");
                //  }
            } else if (value == 1) {
                item_image.get_style_context ().add_class ("upcoming-icon");
            } else {
                item_image.get_style_context ().add_class ("due-clear");
            }
        }
    }

    public bool due_label {
        set {
            if (value) {
                item_label.get_style_context ().add_class ("due-label");
            }
        }
    }

    public ModelButton (string text, string icon, string tooltip = "", bool arrow = false) {
        Object (
            icon: icon,
            text: text,
            tooltip: tooltip,
            arrow: arrow,
            expand: true
        );
    }

    construct {
        get_style_context ().remove_class ("button");
        get_style_context ().add_class ("flat");
        get_style_context ().add_class ("menuitem");
        get_style_context ().add_class ("no-border");
        can_focus = false;

        item_image = new Gtk.Image ();
        item_image.valign = Gtk.Align.CENTER;
        item_image.halign = Gtk.Align.CENTER;
        item_image.pixel_size = 16;

        item_label = new Gtk.Label (null);

        var arrow_image = new Gtk.Image ();
        arrow_image.gicon = new ThemedIcon ("pan-end-symbolic");
        arrow_image.valign = Gtk.Align.CENTER;
        arrow_image.halign = Gtk.Align.CENTER;
        arrow_image.get_style_context ().add_class ("dim-label");
        arrow_image.pixel_size = 16;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        box.margin_start = 3;
        box.margin_end = 3;
        box.pack_start (item_image, false, false, 0);
        box.pack_start (item_label, false, true, 0);
        if (arrow) {
            box.pack_end (arrow_image, false, false, 0);
        }

        add (box);
    }
}

public class SearchProject : Gtk.ListBoxRow {
    public Project project { get; construct set; }

    public SearchProject (Project project) {
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

        var content_label = new Gtk.Label (project.name);
        content_label.ellipsize = Pango.EllipsizeMode.END;
        content_label.xalign = 0;
        content_label.tooltip_text = project.name;

        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.column_spacing = 6;
        grid.add (icon);
        grid.add (content_label);

        add (grid);
    }
}
