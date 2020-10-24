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
    public int64 section_id { get; set; }
    public int is_todoist { get; set; }
    public int index { get; set; }
    public string due_date { get; set; default = ""; }
    public int priority { get; set; default = 1; }
    public Gtk.ListBox? listbox { get; set; default = null; }

    public E.Source source { get; set; default = null; }

    private Gtk.CheckButton checked_button;
    private Gtk.ToggleButton project_button;
    private Gtk.ToggleButton reschedule_button;
    private Gtk.ToggleButton priority_button;
    private Gtk.Stack submit_stack;
    private Gtk.Image priority_image;
    private Gtk.Image project_icon;
    private Gtk.Grid source_color;
    private Gtk.Label project_label;
    private Gtk.Popover projects_popover = null;
    private Gtk.Popover reschedule_popover = null;
    private Gtk.Popover priority_popover = null;
    private Widgets.ModelButton priority_4_menu;
    private Widgets.ModelButton undated_button;
    private Gtk.ListBox projects_listbox;
    private Gtk.SearchEntry search_entry;
    private Gtk.Switch time_switch;
    private Granite.Widgets.TimePicker time_picker;
    private Gtk.Revealer time_picker_revealer;
    private Gtk.Image due_image;
    private Gtk.Label due_label;
    private Gtk.Label time_label;
    private Gtk.Revealer time_revealer;

    public int64 temp_id_mapping { get; set; default = 0; }
    private const string TODAY = _("today");
    private const string TOMORROW = _("tomorrow");
    private const string DATE_1D = _("1d");
    private const string DATE_1W = _("1w");
    private const string DATE_1M = _("1m");

    private uint timeout_id = 0;
    private uint focus_timeout = 0;

    private Widgets.Entry content_entry;
    private Gtk.Revealer main_revealer;
    private bool entry_menu_opened = false;

    public bool loading {
        set {
            if (value) {
                submit_stack.visible_child_name = "spinner";
                sensitive = false;
            } else {
                submit_stack.visible_child_name = "label";
                sensitive = true;
            }
        }
    }

    public NewItem (int64 project_id,
                    int64 section_id,
                    int is_todoist,
                    string due_date="",
                    int index=-1,
                    Gtk.ListBox? listbox=null,
                    int priority=1) {
        this.project_id = project_id;
        this.section_id = section_id;
        this.is_todoist = is_todoist;
        this.due_date = due_date;
        this.index = index;
        this.listbox = listbox;
        this.priority = priority;

        build_ui ();
    }

    public NewItem.for_source (E.Source source, Gtk.ListBox? listbox=null) {
        this.source = source;
        this.listbox = listbox;
        
        build_ui ();
    }

    private void build_ui () {
        can_focus = false;
        activatable = false;
        selectable = false;
        get_style_context ().add_class ("item-row");
        margin_end = 6;

        checked_button = new Gtk.CheckButton ();
        checked_button.margin_start = 6;
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

        submit_stack = new Gtk.Stack ();
        submit_stack.expand = true;
        submit_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        submit_stack.add_named (new Gtk.Label (_("Add Task")), "label");
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

        reschedule_button = new Gtk.ToggleButton ();
        reschedule_button.get_style_context ().add_class ("flat");
        reschedule_button.halign = Gtk.Align.START;
        reschedule_button.add (get_schedule_grid ());
        update_due_date ();

        if (source == null) {
            var project = Planner.database.get_project_by_id (project_id);

            project_icon = new Gtk.Image ();
            project_icon.valign = Gtk.Align.CENTER;
            project_icon.halign = Gtk.Align.CENTER;
            project_icon.pixel_size = 14;
            project_icon.gicon = new ThemedIcon ("color-%i".printf (project.color));
            if (project.inbox_project == 1) {
                project_icon.gicon = new ThemedIcon ("planner-inbox");
            }
        } else {
            var task_list = (E.SourceTaskList?) source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);

            source_color = new Gtk.Grid ();
            source_color.valign = Gtk.Align.CENTER;
            source_color.halign = Gtk.Align.CENTER;
            source_color.width_request = 12;
            source_color.height_request = 12;
            source_color.get_style_context ().add_class ("source-color");
            apply_color (task_list.dup_color ());
        }

        project_label = new Gtk.Label (null);
        if (source == null) {
            project_label.label = Planner.database.get_project_by_id (project_id).name;
        } else {
            project_label.label = source.display_name;
        }

        var project_grid = new Gtk.Grid ();
        if (source == null) {
            project_grid.add (project_icon);
        } else {
            project_grid.add (source_color);
        }
        project_grid.add (project_label);

        project_button = new Gtk.ToggleButton ();
        project_button.get_style_context ().add_class ("flat");
        project_button.halign = Gtk.Align.START;
        project_button.valign = Gtk.Align.CENTER;
        project_button.add (project_grid);

        priority_image = new Gtk.Image ();
        priority_image.pixel_size = 16;
        priority_image.gicon = new ThemedIcon ("edit-flag-symbolic");

        priority_button = new Gtk.ToggleButton ();
        priority_button.margin_end = 6;
        priority_button.get_style_context ().add_class ("flat");
        priority_button.add (priority_image);

        var tools_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        tools_box.margin_bottom = 3;
        tools_box.margin_start = 6;
        tools_box.margin_top = 6;
        tools_box.hexpand = true;
        tools_box.pack_end (project_button, false, false, 0);
        tools_box.pack_end (reschedule_button, false, false, 0);
        tools_box.pack_end (priority_button, false, false, 0);

        var note_textview = new Widgets.TextView ();
        note_textview.margin_top = 6;
        note_textview.margin_end = 12;
        note_textview.margin_start = 27;
        note_textview.hexpand = true;
        note_textview.valign = Gtk.Align.START;
        note_textview.wrap_mode = Gtk.WrapMode.CHAR;
        note_textview.get_style_context ().add_class ("textview");
        note_textview.get_style_context ().add_class ("note-textview");

        var note_revealer = new Gtk.Revealer ();
        note_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        note_revealer.add (note_textview);
        note_revealer.reveal_child = false;

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
        main_grid.add (note_revealer);
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
            if (content_entry.text.strip () != "") {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }

            parse_item_tags (content_entry.text);
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
                    listbox,
                    priority
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

        notify["priority"].connect (() => {
            update_priority (priority);
        });

        notify["due_date"].connect (() => {
            update_due_date ();
        });

        if (priority == 1) {
            priority = 4 - Planner.settings.get_enum ("default-priority");
            update_priority (priority);
        } else {
            update_priority (priority);
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

    private void create_priority_popover () {
        priority_popover = new Gtk.Popover (priority_button);
        priority_popover.position = Gtk.PositionType.BOTTOM;

        var priority_1_menu = new Widgets.ModelButton (_("Priority 1"), "priority-4", "");
        var priority_2_menu = new Widgets.ModelButton (_("Priority 2"), "priority-3", "");
        var priority_3_menu = new Widgets.ModelButton (_("Priority 3"), "priority-2", "");
        priority_4_menu = new Widgets.ModelButton (_("None"), "flag-outline-light", "");

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

    private void update_priority (int p) {
        priority = p;

        checked_button.get_style_context ().remove_class ("priority-4");
        checked_button.get_style_context ().remove_class ("priority-3");
        checked_button.get_style_context ().remove_class ("priority-2");
        checked_button.get_style_context ().remove_class ("priority-1");

        if (p == 1 || p == 0) {
            if (Planner.settings.get_enum ("appearance") == 0) {
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

        var calendar = new Widgets.Calendar.Calendar (true);
        calendar.hexpand = true;

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
        });

        tomorrow_button.clicked.connect (() => {
            due_date = new GLib.DateTime.now_local ().add_days (1).to_string ();
            update_due_date ();
        });

        undated_button.clicked.connect (() => {
            due_date = "";
            update_due_date ();
        });

        calendar.selection_changed.connect ((date) => {
            due_date = date.to_string ();
            update_due_date ();
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

    public void entry_grab_focus () {
        content_entry.grab_focus ();
    }

    public void hide_destroy () {
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
            if (source == null) {
                var item = new Objects.Item ();
                item.priority = priority;         
                item.project_id = project_id;
                item.section_id = section_id;
                item.is_todoist = is_todoist;
                item.due_date = due_date;
                item.content = content_entry.text;
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
                            listbox,
                            priority
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
            } else {
                loading = true;

                var task = new ECal.Component ();
                task.set_new_vtype (ECal.ComponentVType.TODO);

                // unowned ICal.Component ical_task = task.get_icalcomponent ();
                
                task.get_icalcomponent ().set_summary (content_entry.text);
                // Planner.task_store.add_task (source, task, this);
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

    private string get_datetime_from_string (string date) {
        if (date != "") {
            return get_datetime (new GLib.DateTime.from_iso8601 (date, new GLib.TimeZone.local ()));
        }

        return date;
    }

    public void update_due_date () {
        due_date = get_datetime_from_string (due_date);

        due_label.label = _("Schedule");
        due_image.gicon = new ThemedIcon ("office-calendar-symbolic");

        due_image.get_style_context ().remove_class ("overdue-label");
        due_image.get_style_context ().remove_class ("today");
        due_image.get_style_context ().remove_class ("upcoming");

        time_revealer.reveal_child = false;
        if (due_date != "") {
            var datetime = new GLib.DateTime.from_iso8601 (due_date, new GLib.TimeZone.local ());
            due_label.label = Planner.utils.get_relative_date_from_date (datetime);

            if (Planner.utils.has_time (datetime)) {
                time_label.label = datetime.format (Planner.utils.get_default_time_format ());
                time_revealer.reveal_child = true;
            }

            if (Planner.utils.is_today (datetime)) {
                due_image.gicon = new ThemedIcon ("help-about-symbolic");
                due_image.get_style_context ().add_class ("today");
            } else if (Planner.utils.is_overdue (datetime)) {
                due_image.gicon = new ThemedIcon ("calendar-overdue");
                due_image.get_style_context ().add_class ("overdue-label");
            } else {
                due_image.gicon = new ThemedIcon ("office-calendar-symbolic");
                due_image.get_style_context ().add_class ("upcoming");
            }
        }
    }

    private void apply_color (string color) {
        string _css = """
            .source-color {
                background: alpha (%s, 0.85);
                border: 1px solid %s;
                border-radius: 50%;
                box-shadow:
                    inset 0 1px 0 0 alpha (@inset_dark_color, 0.7),
                    inset 0 0 0 1px alpha (@inset_dark_color, 0.3),
                    0 1px 0 0 alpha (@bg_highlight_color, 0.3);
            }
        """;

        var provider = new Gtk.CssProvider ();

        try {
            var css = _css.printf (
                color,
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
}
