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
    public int64 parent_id { get; set; }
    public int is_todoist { get; set; }
    public int index { get; set; }
    public string due_date { get; set; default = ""; }
    public int priority { get; set; default = 1; }
    public Gtk.ListBox? listbox { get; set; default = null; }
    public E.Source source { get; set; default = null; }

    private Gtk.CheckButton checked_button;
    private Gtk.ToggleButton project_button;
    private Gtk.ToggleButton priority_button;
    private Widgets.ScheduleButton reschedule_button;
    private Gtk.Stack submit_stack;
    private Gtk.Image priority_image;
    private Gtk.Image project_icon;
    private Gtk.Grid source_color;
    private Gtk.Label project_label;
    private Gtk.Popover projects_popover = null;
    private Gtk.Popover priority_popover = null;
    private GLib.Cancellable cancellable = null;
    private Widgets.ModelButton priority_4_menu;
    private Widgets.ModelButton undated_button;
    private Gtk.ListBox projects_listbox;
    private Gtk.SearchEntry search_entry;

    public int64 temp_id_mapping { get; set; default = 0; }
    private const string TODAY = _("today");
    private const string TOMORROW = _("tomorrow");
    private const string DATE_1D = _("1d");
    private const string DATE_1W = _("1w");
    private const string DATE_1M = _("1m");
    public Gee.HashMap <string, Widgets.LabelItem> labels_map;

    private uint timeout_id = 0;
    private uint focus_timeout = 0;

    private Widgets.Entry content_entry;
    private Widgets.TextView note_textview;
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
                    int priority=1,
                    int64 parent_id=0) {
        this.project_id = project_id;
        this.section_id = section_id;
        this.is_todoist = is_todoist;
        this.due_date = due_date;
        this.index = index;
        this.listbox = listbox;
        this.priority = priority;
        this.parent_id = parent_id;

        build_ui ();
    }

    public NewItem.for_source (E.Source source, Gtk.ListBox? listbox=null) {
        this.source = source;
        this.listbox = listbox;
        
        build_ui ();
    }

    private void build_ui () {
        labels_map = new Gee.HashMap <string, Widgets.LabelItem> ();

        can_focus = false;
        activatable = false;
        selectable = false;
        get_style_context ().add_class ("item-row");

        checked_button = new Gtk.CheckButton ();
        checked_button.margin_start = 6;
        checked_button.valign = Gtk.Align.CENTER;

        content_entry = new Widgets.Entry ();
        content_entry.hexpand = true;
        content_entry.margin_start = 6;
        content_entry.placeholder_text = _("Task name");
        content_entry.get_style_context ().add_class ("flat");
        content_entry.get_style_context ().add_class ("new-entry");
        content_entry.get_style_context ().add_class ("no-padding-right");
        content_entry.get_style_context ().add_class ("font-bold");

        var content_grid = new Gtk.Grid ();
        content_grid.margin_end = 12;
        // content_grid.margin_top = 3;
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
        buttons_grid.margin_start = 9;
        buttons_grid.column_homogeneous = true;
        buttons_grid.add (cancel_button);
        buttons_grid.add (submit_button);

        reschedule_button = new Widgets.ScheduleButton.new_item ();
        reschedule_button.set_new_item_due_date (due_date);

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
        project_button.get_style_context ().add_class ("transparent");
        project_button.halign = Gtk.Align.START;
        project_button.valign = Gtk.Align.CENTER;
        project_button.add (project_grid);

        priority_image = new Gtk.Image ();
        priority_image.pixel_size = 16;
        priority_image.gicon = new ThemedIcon ("edit-flag-symbolic");

        priority_button = new Gtk.ToggleButton ();
        priority_button.get_style_context ().add_class ("flat");
        priority_button.get_style_context ().add_class ("transparent");
        priority_button.add (priority_image);

        var label_button = new Widgets.LabelButton.new_item ();
        label_button.labels_map = labels_map;
        label_button.get_style_context ().add_class ("transparent");

        var note_image = new Gtk.Image ();
        note_image.pixel_size = 16;
        note_image.icon_name = "text-x-generic-symbolic";

        var note_placeholder = new Gtk.Label (_("Note"));
        note_placeholder.opacity = 0.7;

        var tools_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        tools_box.margin_bottom = 3;
        tools_box.margin_top = 6;
        tools_box.margin_start = 20;
        tools_box.hexpand = true;
        tools_box.pack_start (reschedule_button, false, false, 0);
        tools_box.pack_end (project_button, false, false, 0);
        tools_box.pack_end (priority_button, false, false, 0);
        tools_box.pack_end (label_button, false, false, 0);

        note_textview = new Widgets.TextView ();
        note_textview.margin_top = 6;
        note_textview.margin_end = 9;
        note_textview.margin_start = 28;
        note_textview.height_request = 42;
        note_textview.hexpand = true;
        note_textview.valign = Gtk.Align.START;
        note_textview.wrap_mode = Gtk.WrapMode.CHAR;
        note_textview.get_style_context ().add_class ("textview");
        note_textview.add (note_placeholder);
        
        var labels_edit_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        labels_edit_box.margin_start = 27;
        labels_edit_box.margin_bottom = 6;

        var labels_edit_revealer = new Gtk.Revealer ();
        labels_edit_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        labels_edit_revealer.add (labels_edit_box);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.row_spacing = 0;
        main_grid.expand = false;
        // main_grid.margin_top = 6;
        main_grid.margin_bottom = 6;
        main_grid.margin_start = 6;
        main_grid.get_style_context ().add_class ("item-row-selected");
        main_grid.get_style_context ().add_class ("popover");
        main_grid.add (content_grid);
        main_grid.add (note_textview);
        main_grid.add (labels_edit_revealer);
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

        Timeout.add (main_revealer.transition_duration, () => {
            content_entry.grab_focus ();
            main_revealer.reveal_child = true;
            grab_focus ();

            return GLib.Source.REMOVE;
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
                if (entry_menu_opened == false && content_entry.text.strip () == "") {
                    Timeout.add (250, () => {        
                        if (temp_id_mapping == 0) {
                            hide_destroy ();
                        }
        
                        return GLib.Source.REMOVE;
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

        note_textview.focus_out_event.connect (() => {
            if (note_textview.buffer.text.strip () == "") {
                note_placeholder.visible = true;
            } else {
                note_placeholder.visible = false;
            }

            focus_timeout = Timeout.add (1000, () => {
                focus_timeout = 0;
                if (entry_menu_opened == false && content_entry.text.strip () == "") {
                    timeout_id = Timeout.add (250, () => {
                        timeout_id = 0;
        
                        if (temp_id_mapping == 0) {
                            hide_destroy ();
                        }
        
                        return GLib.Source.REMOVE;
                    });
                }

                return GLib.Source.REMOVE;
            });

            return false;
        });

        note_textview.focus_in_event.connect (() => {
            note_placeholder.visible = false;

            if (focus_timeout != 0) {
                GLib.Source.remove (focus_timeout);
            }

            return false;
        });

        cancel_button.clicked.connect (() => {
            if (cancellable != null) {
                cancellable.cancel ();
            }
            
            hide_destroy ();
        });

        Planner.todoist.item_added_started.connect ((id) => {
            if (temp_id_mapping == id) {
                submit_stack.visible_child_name = "spinner";
                submit_button.sensitive = false;
                main_grid.sensitive = false;
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
                    priority,
                    parent_id
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

        Planner.todoist.item_added_error.connect ((id, error_code, error_message) => {
            if (temp_id_mapping == id) {
                submit_stack.visible_child_name = "label";
                submit_button.sensitive = true;
                main_grid.sensitive = true;

                if (error_code != 0) {
                    Planner.notifications.send_notification (error_message, NotificationStyle.ERROR);
                }
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

        label_button.closed.connect (() => {
            label_button.active = false;
            entry_menu_opened = false;

            content_entry.grab_focus_without_selecting ();
            if (content_entry.cursor_position < content_entry.text_length) {
            content_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) content_entry.text_length, false);
            }
        });

        label_button.show_popover.connect (() => {
            entry_menu_opened = true;
        });

        reschedule_button.popover_opened.connect ((active) => {
            entry_menu_opened = active;

            if (active == false) {
                content_entry.grab_focus_without_selecting ();
                if (content_entry.cursor_position < content_entry.text_length) {
                content_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) content_entry.text_length, false);
                }
            }
        });

        label_button.label_selected.connect ((label, active) => {
            if (active && labels_map.has_key (label.id.to_string ()) == false) {
                var label_item_row = new Widgets.LabelItem (0, 0, label);
                label_item_row.destroy.connect (() => {
                    labels_map.unset (label.id.to_string ());
                });

                labels_edit_revealer.reveal_child = true;
                labels_edit_box.add (label_item_row);
                labels_edit_box.show_all ();

                labels_map.set (label.id.to_string (), label_item_row);
            } else if (active == false) {
                if (labels_map.has_key (label.id.to_string ())) {
                    labels_map.get (label.id.to_string ()).hide_destroy ();
                }
            }
        });

        label_button.clear.connect (() => {
            foreach (Gtk.Widget element in labels_edit_box.get_children ()) {
                labels_edit_box.remove (element);
            }

            labels_map.clear ();
        });

        notify["priority"].connect (() => {
            update_priority (priority);
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
                        reschedule_button.set_new_item_due_date (due_date);
                        break;
                    case TOMORROW:
                        due_date = get_datetime (new GLib.DateTime.now_local ().add_days (1)).to_string ();
                        reschedule_button.set_new_item_due_date (due_date);
                        break;
                    case DATE_1D:
                        due_date = get_datetime (new GLib.DateTime.now_local ().add_days (1)).to_string ();
                        reschedule_button.set_new_item_due_date (due_date);
                        break;
                    case DATE_1W:
                        due_date = get_datetime (new GLib.DateTime.now_local ().add_days (7)).to_string ();
                        reschedule_button.set_new_item_due_date (due_date);
                        break;
                    case DATE_1M:
                        due_date = get_datetime (new GLib.DateTime.now_local ().add_months (1)).to_string ();
                        reschedule_button.set_new_item_due_date (due_date);
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

    private string get_datetime (GLib.DateTime date) {
        var datetime = new GLib.DateTime.local (
            date.get_year (),
            date.get_month (),
            date.get_day_of_month (),
            0,
            0,
            0
        );

        return datetime.to_string ();
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

    public void entry_grab_focus () {
        content_entry.grab_focus ();
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
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
                item.parent_id = parent_id;
                item.is_todoist = is_todoist;
                item.due_date = reschedule_button.get_due_date ();
                item.content = content_entry.text;
                item.note = note_textview.buffer.text;
                temp_id_mapping = Planner.utils.generate_id ();
                
                if (is_todoist == 1) {
                    cancellable = new Cancellable ();
                    Planner.todoist.add_item.begin (
                        item,
                        cancellable,
                        index,
                        temp_id_mapping,
                        labels_map.values);
                } else {
                    item.id = Planner.utils.generate_id ();
                    if (Planner.database.insert_item (item, index)) {
                        foreach (Widgets.LabelItem label_item in labels_map.values) {
                            Planner.database.add_item_label (item.id, label_item.label);
                        }

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
                            priority,
                            parent_id
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

                unowned ICal.Component ical_task = task.get_icalcomponent ();
                
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
