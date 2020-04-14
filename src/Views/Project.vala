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

public class Views.Project : Gtk.EventBox {
    public Objects.Project project { get; construct; }

    private Gtk.Label name_label;
    private Gtk.Entry name_entry;
    private Gtk.Revealer action_revealer;
    private Gtk.TextView note_textview;
    private Gtk.Label note_placeholder;
    private Gtk.Stack name_stack;

    private Gtk.ListBox listbox;
    private Gtk.ListBox section_listbox;
    private Gtk.Revealer motion_revealer;
    private Gtk.Revealer motion_section_revealer;

    private Gtk.ModelButton show_completed_button;
    private Gtk.Switch show_completed_switch;
    private Gtk.ListBox completed_listbox;
    private Gtk.Revealer completed_revealer;
    private Gtk.Stack main_stack;

    private Gtk.Label progress_label;
    private Gtk.Label duedate_label;
    private Gtk.LevelBar progress_bar;
    private Gtk.LevelBar duedate_bar;

    private Gtk.Entry section_name_entry;
    private Gtk.ToggleButton section_button;
    private Gtk.Popover new_section_popover = null;
    private Gtk.Popover popover = null;
    private Gtk.ToggleButton settings_button;

    private Gtk.Popover progress_popover = null;
    private Gtk.ToggleButton progress_button;

    private uint timeout = 0;
    public Gee.ArrayList<Widgets.ItemRow?> items_list;
    public Gee.ArrayList<Widgets.ItemRow?> items_opened;
    public Gee.HashMap <string, Widgets.ItemRow> items_uncompleted_added;
    public Gee.HashMap<string, Widgets.ItemCompletedRow> items_completed_added;

    private int64 temp_id_mapping { get; set; default = 0; }

    private const Gtk.TargetEntry[] TARGET_ENTRIES = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] TARGET_ENTRIES_SECTION = {
        {"SECTIONROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public Project (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        items_completed_added = new Gee.HashMap<string, Widgets.ItemCompletedRow> ();
        items_uncompleted_added = new Gee.HashMap <string, Widgets.ItemRow> ();
        items_list = new Gee.ArrayList<Widgets.ItemRow?> ();
        items_opened = new Gee.ArrayList<Widgets.ItemRow?> ();

        name_label = new Gtk.Label (project.name);
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("title-label");
        name_label.get_style_context ().add_class ("font-bold");

        var name_eventbox = new Gtk.EventBox ();
        name_eventbox.valign = Gtk.Align.START;
        name_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        name_eventbox.hexpand = true;
        name_eventbox.add (name_label);

        name_entry = new Gtk.Entry ();
        name_entry.text = project.name;
        name_entry.get_style_context ().add_class ("font-bold");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("title-label");
        name_entry.get_style_context ().add_class ("project-name-entry");
        name_entry.hexpand = true;

        name_stack = new Gtk.Stack ();
        name_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        name_stack.add_named (name_eventbox, "name_label");
        name_stack.add_named (name_entry, "name_entry");

        var project_progress = new Widgets.ProjectProgress (10);
        project_progress.margin = 2;
        project_progress.valign = Gtk.Align.CENTER;
        project_progress.halign = Gtk.Align.CENTER;
        if (Planner.settings.get_boolean ("prefer-dark-style")) {
            project_progress.progress_fill_color = "#FFFFFF";
        } else {
            project_progress.progress_fill_color = "#000000";
        }

        var progress_grid = new Gtk.Grid ();
        progress_grid.get_style_context ().add_class ("project-progress-view");
        progress_grid.add (project_progress);
        progress_grid.valign = Gtk.Align.CENTER;
        progress_grid.halign = Gtk.Align.CENTER;

        progress_button = new Gtk.ToggleButton ();
        progress_button.valign = Gtk.Align.CENTER;
        progress_button.halign = Gtk.Align.CENTER;
        progress_button.can_focus = false;
        progress_button.margin_end = 3;
        progress_button.get_style_context ().add_class ("flat");
        progress_button.add (progress_grid);

        var section_image = new Gtk.Image ();
        section_image.gicon = new ThemedIcon ("go-jump-symbolic");
        section_image.pixel_size = 16;

        section_button = new Gtk.ToggleButton ();
        section_button.valign = Gtk.Align.CENTER;
        section_button.halign = Gtk.Align.CENTER;
        section_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl><Shift>S"}, _("Add Section"));
        section_button.can_focus = false;
        section_button.get_style_context ().add_class ("flat");
        section_button.add (section_image);

        var add_person_button = new Gtk.Button.from_icon_name ("contact-new-symbolic", Gtk.IconSize.MENU);
        add_person_button.valign = Gtk.Align.CENTER;
        add_person_button.halign = Gtk.Align.CENTER;
        add_person_button.tooltip_text = _("Invite person");
        add_person_button.can_focus = false;
        add_person_button.margin_start = 6;
        add_person_button.get_style_context ().add_class ("flat");

        var comment_button = new Gtk.Button.from_icon_name ("internet-chat-symbolic", Gtk.IconSize.MENU);
        comment_button.valign = Gtk.Align.CENTER;
        comment_button.halign = Gtk.Align.CENTER;
        comment_button.can_focus = false;
        comment_button.tooltip_text = _("Project comments");
        comment_button.margin_start = 6;
        comment_button.get_style_context ().add_class ("flat");

        var search_button = new Gtk.Button.from_icon_name ("edit-find-symbolic", Gtk.IconSize.MENU);
        search_button.valign = Gtk.Align.CENTER;
        search_button.halign = Gtk.Align.CENTER;
        search_button.can_focus = false;
        search_button.tooltip_text = _("Search task");
        search_button.margin_start = 6;
        search_button.get_style_context ().add_class ("flat");

        var settings_image = new Gtk.Image ();
        settings_image.gicon = new ThemedIcon ("view-more-symbolic");
        settings_image.pixel_size = 14;

        settings_button = new Gtk.ToggleButton ();
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.can_focus = false;
        settings_button.tooltip_text = _("Project Menu");
        settings_button.image = settings_image;
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_end = 24;
        top_box.margin_start = 36;

        var submit_button = new Gtk.Button.with_label (_("Save"));
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("planner-button");

        var action_grid = new Gtk.Grid ();
        action_grid.halign = Gtk.Align.START;
        action_grid.margin_top = 6;
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 6;
        action_grid.margin_start = 36;
        action_grid.margin_bottom = 6;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        action_revealer = new Gtk.Revealer ();
        action_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        action_revealer.add (action_grid);

        top_box.pack_start (name_stack, false, true, 0);
        top_box.pack_end (settings_button, false, false, 0);
        // top_box.pack_end (search_button, false, false, 0);
        if (project.is_todoist == 1) {
            // top_box.pack_end (add_person_button, false, false, 0);
            // top_box.pack_end (comment_button, false, false, 0);
        }
        top_box.pack_end (section_button, false, false, 0);
        top_box.pack_end (progress_button, false, false, 0);

        note_textview = new Gtk.TextView ();
        note_textview.tooltip_text = _("Add a description");
        note_textview.hexpand = true;
        note_textview.valign = Gtk.Align.START;
        note_textview.margin_top = 6;
        note_textview.margin_bottom = 3;
        note_textview.wrap_mode = Gtk.WrapMode.WORD;
        note_textview.get_style_context ().add_class ("project-textview");
        note_textview.margin_start = 37;
        note_textview.margin_end = 36;

        note_placeholder = new Gtk.Label (_("Description"));
        note_placeholder.opacity = 0.7;
        note_textview.add (note_placeholder);

        note_textview.buffer.text = Planner.utils.line_break_to_space (project.note);

        if (project.note != "") {
            note_placeholder.visible = false;
            note_placeholder.no_show_all = true;
        } else {
            note_placeholder.visible = true;
            note_placeholder.no_show_all = false;
        }

        listbox = new Gtk.ListBox ();
        listbox.margin_start = 24;
        listbox.valign = Gtk.Align.START;
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.margin_bottom = 3;
        // listbox.set_filter_func (filter_function);
        // listbox.set_sort_func (sort_function);
        listbox.hexpand = true;

        completed_listbox = new Gtk.ListBox ();
        completed_listbox.valign = Gtk.Align.START;
        completed_listbox.get_style_context ().add_class ("listbox");
        completed_listbox.activate_on_single_click = true;
        completed_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        completed_listbox.hexpand = true;

        completed_revealer = new Gtk.Revealer ();
        completed_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        completed_revealer.add (completed_listbox);
        completed_revealer.margin_bottom = 32;
        if (project.show_completed == 1) {
            completed_revealer.reveal_child = true;
        }

        var motion_grid = new Gtk.Grid ();
        motion_grid.margin_start = 36;
        motion_grid.margin_end = 24;
        motion_grid.margin_bottom = 12;
        motion_grid.margin_top = 6;
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;

        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        motion_revealer.add (motion_grid);

        section_listbox = new Gtk.ListBox ();
        section_listbox.valign = Gtk.Align.START;
        section_listbox.get_style_context ().add_class ("listbox");
        section_listbox.activate_on_single_click = true;
        section_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        section_listbox.hexpand = true;
        Gtk.drag_dest_set (section_listbox, Gtk.DestDefaults.ALL, TARGET_ENTRIES_SECTION, Gdk.DragAction.MOVE);
        section_listbox.drag_data_received.connect (on_drag_section_received);

        var motion_section_grid = new Gtk.Grid ();
        motion_section_grid.margin_start = 24;
        motion_section_grid.margin_end = 16;
        motion_section_grid.get_style_context ().add_class ("grid-motion");
        motion_section_grid.height_request = 24;

        motion_section_revealer = new Gtk.Revealer ();
        motion_section_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        motion_section_revealer.add (motion_section_grid);

        var drag_section_grid = new Gtk.Grid ();
        drag_section_grid.margin_start = 24;
        drag_section_grid.margin_end = 16;
        drag_section_grid.height_request = 16;

        Gtk.drag_dest_set (drag_section_grid, Gtk.DestDefaults.ALL, TARGET_ENTRIES_SECTION, Gdk.DragAction.MOVE);
        drag_section_grid.drag_data_received.connect ((context, x, y, selection_data, target_type, time) => {
            Widgets.SectionRow source;

            var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
            source = (Widgets.SectionRow) row;

            source.get_parent ().remove (source);

            section_listbox.insert (source, (int32) section_listbox.get_children ().length ());
            section_listbox.show_all ();

            update_section_order ();
        });

        drag_section_grid.drag_motion.connect ((context, x, y, time) => {
            motion_section_revealer.reveal_child = true;
            return true;
        });

        drag_section_grid.drag_leave.connect ((context, time) => {
            motion_section_revealer.reveal_child = false;
        });

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.expand = true;
        box.margin_bottom = 3;
        box.margin_end = 3;
        box.pack_start (motion_revealer, false, false, 0);
        box.pack_start (listbox, false, false, 0);
        box.pack_start (completed_revealer, false, false, 0);
        box.pack_start (section_listbox, false, false, 0);
        box.pack_start (drag_section_grid, false, false, 0);
        box.pack_start (motion_section_revealer, false, false, 0);

        var main_scrolled = new Gtk.ScrolledWindow (null, null);
        main_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        main_scrolled.expand = true;
        main_scrolled.add (box);

        var placeholder_view = new Widgets.Placeholder (
            _("What will you accomplish?"),
            _("Tap + to add a task to this project."),
            "planner-project-symbolic"
        );
        placeholder_view.reveal_child = true;

        main_stack = new Gtk.Stack ();
        main_stack.hexpand = true;
        main_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        main_stack.add_named (main_scrolled, "project");
        main_stack.add_named (placeholder_view, "placeholder");

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (action_revealer, false, false, 0);
        main_box.pack_start (note_textview, false, false, 0);
        main_box.pack_start (main_stack, false, true, 0);

        add (main_box);

        build_drag_and_drop ();
        add_all_items ();
        add_completed_items ();
        add_all_sections ();
        show_all ();
        check_listbox_margin ();

        // Check Placeholder view
        Timeout.add (125, () => {
            Planner.database.get_project_count (project.id);

            note_textview.visible = false;
            note_textview.visible = true;

            check_placeholder_view ();

            return false;
        });

        listbox.row_activated.connect ((row) => {
            var item = ((Widgets.ItemRow) row);
            item.reveal_child = true;
        });

        section_listbox.remove.connect ((row) => {
            check_placeholder_view ();
        });

        submit_button.clicked.connect (() => {
            save (true);
        });

        cancel_button.clicked.connect (() => {
            action_revealer.reveal_child = false;
            name_stack.visible_child_name = "name_label";
            name_entry.text = project.name;
        });

        name_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                action_revealer.reveal_child = true;
                name_stack.visible_child_name = "name_entry";

                name_entry.grab_focus_without_selecting ();
                if (name_entry.cursor_position < name_entry.text_length) {
                    name_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) name_entry.text_length, false);
                }
            }

            return false;
        });

        name_entry.activate.connect (() => {
            save (true);
        });

        name_entry.changed.connect (() => {
            if (name_entry.text.strip () != "" && project.name != name_entry.text) {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                action_revealer.reveal_child = false;
                name_stack.visible_child_name = "name_label";
                name_entry.text = project.name;
            }

            return false;
        });

        settings_button.toggled.connect (() => {
            if (settings_button.active) {
                if (popover == null) {
                    create_popover ();
                }

                popover.show_all ();
            }
        });

        note_textview.focus_in_event.connect (() => {
            note_placeholder.visible = false;
            note_placeholder.no_show_all = true;

            return false;
        });

        note_textview.focus_out_event.connect (() => {
            if (note_textview.buffer.text == "") {
                note_placeholder.visible = true;
                note_placeholder.no_show_all = false;
            }

            return false;
        }); 

        note_textview.buffer.changed.connect (() => {
            save (false);
        });

        section_button.toggled.connect (() => {
            open_new_section ();
        });

        progress_button.toggled.connect (() => {
            open_progress_popover ();
        });

        completed_listbox.remove.connect (() => {
            check_task_complete_visible ();
        });

        Planner.database.project_updated.connect ((p) => {
            if (project != null && p.id == project.id) {
                project = p;

                name_label.label = p.name;
                name_entry.text = p.name;
                note_textview.buffer.text = p.note;

                if (note_textview.buffer.text != "") {
                    note_placeholder.visible = false;
                    note_placeholder.no_show_all = true;
                } else {
                    note_placeholder.visible = true;
                    note_placeholder.no_show_all = false;
                }
            }
        });

        Planner.database.section_added.connect ((section) => {
            if (project.id == section.project_id) {
                var row = new Widgets.SectionRow (section);
                section_listbox.add (row);
                section_listbox.show_all ();

                update_section_order ();
                main_stack.visible_child_name = "project";

                if (row.get_index () != 0) {
                    row.margin_top = 12;
                }
            }
        });

        Planner.database.item_added.connect ((item) => {
            if (project.id == item.project_id && item.section_id == 0 && item.parent_id == 0) {
                var row = new Widgets.ItemRow (item);
                row.destroy.connect (() => {
                    item_row_removed (row);
                });

                items_uncompleted_added.set (item.id.to_string (), row);
                listbox.add (row);
                items_list.add (row);

                listbox.show_all ();
                check_placeholder_view ();
                check_listbox_margin ();
            }
        });

        Planner.database.item_added_with_index.connect ((item, index) => {
            if (project.id == item.project_id && item.section_id == 0) {
                var row = new Widgets.ItemRow (item);
                row.destroy.connect (() => {
                    item_row_removed (row);
                });

                items_uncompleted_added.set (item.id.to_string (), row);
                listbox.insert (row, index);
                items_list.insert (index, row);

                listbox.show_all ();
                check_placeholder_view ();
                check_listbox_margin ();
            }
        });

        Planner.database.show_undo_item.connect ((item, type) => {
            if (project.id == item.project_id) {
                check_placeholder_view ();
                check_listbox_margin ();
            }
        });

        Planner.database.item_uncompleted.connect ((item) => {
            Idle.add (() => {
                if (project.id == item.project_id) {
                    if (item.section_id == 0 && item.parent_id == 0) {
                        if (items_completed_added.has_key (item.id.to_string ())) {
                            items_completed_added.get (item.id.to_string ()).hide_destroy ();
                            items_completed_added.unset (item.id.to_string ());
                        }

                        if (items_uncompleted_added.has_key (item.id.to_string ()) == false) {
                            var row = new Widgets.ItemRow (item);
                            row.destroy.connect (() => {
                                item_row_removed (row);
                            });

                            listbox.add (row);
                            items_uncompleted_added.set (item.id.to_string (), row);
                            items_list.add (row);

                            listbox.show_all ();
                        }
                    }
                }

                check_listbox_margin ();
                check_placeholder_view ();
                
                return false;
            });
        });

        Planner.database.item_completed.connect ((item) => {
            Idle.add (() => {
                if (project.id == item.project_id) {
                    if (item.checked == 1 && item.section_id == 0) {
                        if (items_uncompleted_added.has_key (item.id.to_string ())) {
                            items_uncompleted_added.get (item.id.to_string ()).destroy ();
                            items_uncompleted_added.unset (item.id.to_string ());
                        }

                        if (items_completed_added.has_key (item.id.to_string ()) == false) {
                            var row = new Widgets.ItemCompletedRow (item);

                            items_completed_added.set (item.id.to_string (), row);
                            completed_listbox.insert (row, 0);
                            completed_listbox.show_all ();
                        }
                    }
                }

                check_listbox_margin ();
                check_placeholder_view ();

                return false;
            });
        });

        Planner.utils.magic_button_activated.connect ((project_id, section_id, is_todoist, last, index) => {
            if (project.id == project_id && section_id == 0) {
                var new_item = new Widgets.NewItem (
                    project_id,
                    section_id,
                    is_todoist
                );

                if (last) {
                    listbox.add (new_item);
                } else {
                    new_item.has_index = true;
                    new_item.index = index;
                    listbox.insert (new_item, index);
                }

                listbox.show_all ();
                main_stack.visible_child_name = "project";
            }
        });

        Planner.database.item_moved.connect ((item, project_id, old_project_id) => {
            Idle.add (() => {
                if (project.id == old_project_id) {
                    if (items_uncompleted_added.has_key (item.id.to_string ())) {
                        var row = items_uncompleted_added.get (item.id.to_string ());

                        items_list.remove (row);
                        items_uncompleted_added.unset (item.id.to_string ());

                        row.hide_destroy ();
                    }

                    check_placeholder_view ();
                    check_listbox_margin ();
                }

                if (project.id == project_id && item.section_id == 0) {
                    item.project_id = project_id;

                    var row = new Widgets.ItemRow (item);
                    row.destroy.connect (() => {
                        item_row_removed (row);
                    });

                    listbox.add (row);
                    items_uncompleted_added.set (item.id.to_string (), row);
                    items_list.add (row);

                    listbox.show_all ();

                    check_placeholder_view ();
                    check_listbox_margin ();
                }

                return false;
            });
        });

        Planner.database.item_section_moved.connect ((i, section_id, old_section_id) => {
            Idle.add (() => {
                print ("old_section_id: %s\n".printf (old_section_id.to_string ()));

                if (old_section_id == 0) {
                    if (items_uncompleted_added.has_key (i.id.to_string ())) {
                        var row = items_uncompleted_added.get (i.id.to_string ());

                        items_list.remove (row);
                        items_uncompleted_added.unset (i.id.to_string ());

                        row.hide_destroy ();
                    }

                    check_placeholder_view ();
                    check_listbox_margin ();
                }

                if (0 == section_id) {
                    i.section_id = 0;

                    var row = new Widgets.ItemRow (i);
                    row.destroy.connect (() => {
                        item_row_removed (row);
                    });

                    listbox.add (row);
                    items_list.add (row);
                    items_uncompleted_added.set (i.id.to_string (), row);

                    listbox.show_all ();

                    check_placeholder_view ();
                    check_listbox_margin ();
                }

                return false;
            });
        });

        Planner.database.section_moved.connect ((section, project_id, old_project_id) => {
            Idle.add (() => {
                if (project.id == old_project_id) {
                    section_listbox.foreach ((widget) => {
                        var row = (Widgets.SectionRow) widget;

                        if (row.section.id == section.id) {
                            row.destroy ();
                        }
                    });

                    check_placeholder_view ();
                    check_listbox_margin ();
                }

                if (project.id == project_id) {
                    section.project_id = project_id;

                    var row = new Widgets.SectionRow (section);
                    section_listbox.add (row);
                    section_listbox.show_all ();

                    check_placeholder_view ();
                    check_listbox_margin ();
                }

                return false;
            });
        });

        Planner.database.project_id_updated.connect ((current_id, new_id) => {
            Idle.add (() => {
                if (project.id == current_id) {
                    project.id = new_id;
                }

                return false;
            });
        });

        Planner.utils.add_item_show_queue.connect ((row) => {
            if (project.id == row.item.project_id) {
                items_opened.add (row);
            }
        });

        Planner.utils.remove_item_show_queue.connect ((row) => {
            if (project.id == row.item.project_id) {
                remove_item_show_queue (row);
            }
        });

        Planner.database.update_project_count.connect ((id, items_0, items_1) => {
            if (project.id == id) {
                project_progress.percentage = ((double) items_1 / ((double) items_0 + (double) items_1));
                progress_button.tooltip_text = _("Project's progress: %s".printf (
                    GLib.Math.floor ((project_progress.percentage * 100)).to_string ())
                ) + "%";
            }
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "prefer-dark-style") {
                if (Planner.settings.get_boolean ("prefer-dark-style")) {
                    project_progress.progress_fill_color = "#FFFFFF";
                } else {
                    project_progress.progress_fill_color = "#000000";
                }
            }
        });
    }

    private void remove_item_show_queue (Widgets.ItemRow row) {
        items_opened.remove (row);
    }

    public void hide_last_item () {
        if (items_opened.size > 0) {
            var last = items_opened [items_opened.size - 1];
            remove_item_show_queue (last);
            last.hide_item ();

            if (items_opened.size > 0) {
                var focus = items_opened [items_opened.size - 1];
                focus.grab_focus ();
                focus.content_entry_focus ();
            }
        }
    }

    private void save (bool todoist=true) {
        if (project != null) {
            project.note = note_textview.buffer.text;
            project.name = name_entry.text;

            name_label.label = name_entry.text;
            action_revealer.reveal_child = false;
            name_stack.visible_child_name = "name_label";

            project.save (todoist);
        }
    }

    private void add_all_items () {
        foreach (var item in Planner.database.get_all_items_by_project_no_section_no_parent (project.id)) {
            var row = new Widgets.ItemRow (item);
            row.destroy.connect (() => {
                item_row_removed (row);
            });

            listbox.add (row);
            items_uncompleted_added.set (item.id.to_string (), row);
            items_list.add (row);

            listbox.show_all ();
        }
    }

    private void add_completed_items () {
        var all = Planner.database.get_all_completed_items_by_project_no_section_no_parent (project.id);

        foreach (var item in all) {
            var row = new Widgets.ItemCompletedRow (item);

            completed_listbox.add (row);
            items_completed_added.set (item.id.to_string (), row);
            completed_listbox.show_all ();
        }
    }

    private void add_all_sections () {
        foreach (var section in Planner.database.get_all_sections_by_project (project.id)) {
            var row = new Widgets.SectionRow (section);
            section_listbox.add (row);
            section_listbox.show_all ();

            if (row.get_index () == 0) {
                row.margin_top = 0;
            }
        }
    }

    private void build_drag_and_drop () {
        Gtk.drag_dest_set (listbox, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        listbox.drag_data_received.connect (on_drag_data_received);

        Gtk.drag_dest_set (note_textview, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        note_textview.drag_data_received.connect (on_drag_item_received);
        note_textview.drag_motion.connect (on_drag_motion);
        note_textview.drag_leave.connect (on_drag_leave);
    }

    private void on_drag_data_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.ItemRow target;
        Widgets.ItemRow source;
        Gtk.Allocation alloc;

        target = (Widgets.ItemRow) listbox.get_row_at_y (y);
        target.get_allocation (out alloc);

        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        if (target != null) {
            if (source.item.section_id != 0) {
                source.item.section_id = 0;

                if (source.item.is_todoist == 1) {
                    Planner.todoist.move_item_to_section (source.item, 0);
                }
            }

            source.get_parent ().remove (source);
            items_list.remove (source);
            items_uncompleted_added.set (source.item.id.to_string (), source);

            listbox.insert (source, target.get_index () + 1);
            items_list.insert (target.get_index () + 1, source);
            items_uncompleted_added.set (source.item.id.to_string (), source);

            listbox.show_all ();
            update_item_order ();
        }
    }

    private void on_drag_item_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.ItemRow source;
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        if (source.item.section_id != 0) {
            source.item.section_id = 0;

            if (source.item.is_todoist == 1) {
                Planner.todoist.move_item_to_section (source.item, 0);
            }
        }

        source.get_parent ().remove (source);
        items_list.remove (source);
        items_uncompleted_added.set (source.item.id.to_string (), source);

        listbox.insert (source, 0);
        items_list.insert (0, source);
        items_uncompleted_added.set (source.item.id.to_string (), source);

        listbox.show_all ();
        update_item_order ();
        check_listbox_margin ();
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        motion_revealer.reveal_child = true;
        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        motion_revealer.reveal_child = false;
    }

    private void update_item_order () {
        timeout = Timeout.add (250, () => {
            new Thread<void*> ("update_item_order", () => {
                for (int index = 0; index < items_list.size; index++) {
                    Planner.database.update_item_order (items_list [index].item, 0, index);
                }

                return null;
            });

            return false;
        });
    }

    private void create_popover () {
        popover = new Gtk.Popover (settings_button);
        popover.position = Gtk.PositionType.BOTTOM;

        var edit_menu = new Widgets.ModelButton (_("Edit"), "edit-symbolic", "");
        //var archive_menu = new Widgets.ModelButton (_("Archive project"), "planner-archive-symbolic");

        var delete_menu = new Widgets.ModelButton (_("Delete"), "user-trash-symbolic");
        delete_menu.get_style_context ().add_class ("menu-danger");

        // Show Complete
        var show_completed_image = new Gtk.Image ();
        show_completed_image.gicon = new ThemedIcon ("emblem-default-symbolic");
        show_completed_image.valign = Gtk.Align.START;
        show_completed_image.pixel_size = 16;

        var show_completed_label = new Gtk.Label (_("Show Completed"));
        show_completed_label.hexpand = true;
        show_completed_label.valign = Gtk.Align.START;
        show_completed_label.xalign = 0;
        show_completed_label.margin_start = 9;

        show_completed_switch = new Gtk.Switch ();
        show_completed_switch.margin_start = 12;
        show_completed_switch.get_style_context ().add_class ("planner-switch");
        if (project.show_completed == 1) {
            show_completed_switch.active = true;
        }

        var show_completed_grid = new Gtk.Grid ();
        show_completed_grid.add (show_completed_image);
        show_completed_grid.add (show_completed_label);
        show_completed_grid.add (show_completed_switch);

        show_completed_button = new Gtk.ModelButton ();
        show_completed_button.get_style_context ().add_class ("popover-model-button");
        show_completed_button.get_child ().destroy ();
        show_completed_button.add (show_completed_grid);

        var separator_01 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator_01.margin_top = 3;
        separator_01.margin_bottom = 3;

        var separator_02 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator_02.margin_top = 3;
        separator_02.margin_bottom = 3;

        var popover_grid = new Gtk.Grid ();
        popover_grid.width_request = 250;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.margin_top = 3;
        popover_grid.margin_bottom = 3;
        popover_grid.add (edit_menu);
        popover_grid.add (separator_01);
        popover_grid.add (show_completed_button);
        popover_grid.add (delete_menu);

        popover.add (popover_grid);

        popover.closed.connect (() => {
            settings_button.active = false;
        });

        edit_menu.clicked.connect (() => {
            var dialog = new Dialogs.ProjectSettings (project);
            dialog.destroy.connect (Gtk.main_quit);
            dialog.show_all ();

            popover.popdown ();
        });

        delete_menu.clicked.connect (() => {
            popover.popdown ();

            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Delete project"),
                _("Are you sure you want to delete <b>%s</b>?".printf (project.name)),
                "user-trash-full",
            Gtk.ButtonsType.CANCEL);

            var remove_button = new Gtk.Button.with_label (_("Delete"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                Planner.database.delete_project (project.id);
                if (project.is_todoist == 1) {
                    Planner.todoist.delete_project (project);
                }
            }

            message_dialog.destroy ();
        });

        show_completed_button.button_release_event.connect (() => {
            show_completed_switch.activate ();

            if (show_completed_switch.active) {
                project.show_completed = 0;
                completed_revealer.reveal_child = false;
            } else {
                project.show_completed = 1;
                completed_revealer.reveal_child = true;
            }

            check_placeholder_view ();
            check_listbox_margin ();
            Planner.database.project_show_completed (project);
            save (false);
            return Gdk.EVENT_STOP;
        });
    }

    private void on_drag_section_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.SectionRow target;
        Widgets.SectionRow source;
        Gtk.Allocation alloc;

        target = (Widgets.SectionRow) section_listbox.get_row_at_y (y);
        target.get_allocation (out alloc);

        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.SectionRow) row;

        if (target != null) {
            source.get_parent ().remove (source);

            section_listbox.insert (source, target.get_index ());
            section_listbox.show_all ();

            update_section_order ();
        }
    }

    private void update_section_order () {
        timeout = Timeout.add (150, () => {
            new Thread<void*> ("update_section_order", () => {
                section_listbox.foreach ((widget) => {
                    var row = (Gtk.ListBoxRow) widget;
                    int index = row.get_index ();

                    var section = ((Widgets.SectionRow) row).section;

                    new Thread<void*> ("update_section_order", () => {
                        Planner.database.update_section_item_order (section.id, index);
                        return null;
                    });
                });

                return null;
            });

            Source.remove (timeout);
            timeout = 0;

            return false;
        });
    }

    private void check_task_complete_visible () {
        //  int count = 0;
        //  completed_listbox.foreach ((widget) => {
        //      count++;
        //  });

        //  if (count <= 0) {
        //      // completed_revealer.reveal_child = false;
        //  }
    }

    public void open_new_section () {
        if (new_section_popover == null) {
            build_new_section_popover ();
        }

        new_section_popover.show_all ();
        section_name_entry.grab_focus ();
    }

    public void open_progress_popover () {
        if (progress_popover == null) {
            build_progress_popover ();
        }

        int checked = Planner.database.get_count_checked_items_by_project (project.id);
        int all = Planner.database.get_all_count_items_by_project (project.id);

        progress_bar.value = (double) checked / (double) all;
        progress_label.label = "%i/%i".printf (
            checked,
            all
        );


        progress_popover.show_all ();
    }

    public void build_progress_popover () {
        progress_popover = new Gtk.Popover (progress_button);
        progress_popover.position = Gtk.PositionType.BOTTOM;

        var productivity_labe = new Gtk.Label ("<small>%s</small>".printf (_("Productivity")));
        productivity_labe.use_markup = true;
        productivity_labe.get_style_context ().add_class ("dim-label");
        productivity_labe.get_style_context ().add_class ("font-weight-600");

        var progress_header = new Granite.HeaderLabel (_("Progress:"));
        progress_label = new Gtk.Label (null);
        progress_label.get_style_context ().add_class ("dim-label");

        var progress_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        progress_box.pack_start (progress_header, false, false, 0);
        progress_box.pack_end (progress_label, false, false, 0);

        progress_bar = new Gtk.LevelBar.for_interval (0, 1);
        progress_bar.hexpand = true;

        var duedate_header = new Granite.HeaderLabel (_("Due date:"));
        duedate_label = new Gtk.Label (null);
        duedate_label.get_style_context ().add_class ("dim-label");

        var duedate_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        duedate_box.margin_top = 6;
        duedate_box.pack_start (duedate_header, false, false, 0);
        duedate_box.pack_end (duedate_label, false, false, 0);

        duedate_bar = new Gtk.LevelBar.for_interval (0, 1);
        duedate_bar.hexpand = true;

        var popover_grid = new Gtk.Grid ();
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.margin = 12;
        popover_grid.margin_top = 6;
        popover_grid.width_request = 250;
        popover_grid.add (productivity_labe);
        popover_grid.add (progress_box);
        popover_grid.add (progress_bar);
        popover_grid.add (duedate_box);
        popover_grid.add (duedate_bar);

        progress_popover.add (popover_grid);

        progress_popover.closed.connect (() => {
            progress_button.active = false;
        });
    }

    private void build_new_section_popover () {
        new_section_popover = new Gtk.Popover (section_button);
        new_section_popover.position = Gtk.PositionType.BOTTOM;

        var name_label = new Granite.HeaderLabel (_("Name:"));

        section_name_entry = new Gtk.Entry ();
        section_name_entry.hexpand = true;

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
        cancel_button.get_style_context ().add_class ("planner-button");

        var action_grid = new Gtk.Grid ();
        action_grid.expand = false;
        action_grid.halign = Gtk.Align.START;
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 6;
        action_grid.margin_top = 12;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        var popover_grid = new Gtk.Grid ();
        popover_grid.width_request = 250;
        popover_grid.margin = 6;
        popover_grid.margin_top = 0;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (name_label);
        popover_grid.add (section_name_entry);
        popover_grid.add (action_grid);

        new_section_popover.add (popover_grid);

        new_section_popover.closed.connect (() => {
            section_button.active = false;
        });

        submit_button.clicked.connect (insert_section);

        section_name_entry.activate.connect (() => {
            insert_section ();
        });

        section_name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                section_name_entry.text = "";
                new_section_popover.popdown ();
            }

            return false;
        });

        section_name_entry.changed.connect (() => {
            if (section_name_entry.text != "") {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }
        });

        cancel_button.clicked.connect (() => {
            section_name_entry.text = "";
            new_section_popover.popdown ();
        });

        Planner.todoist.section_added_started.connect ((id) => {
            if (temp_id_mapping == id) {
                submit_stack.visible_child_name = "spinner";
                popover_grid.sensitive = false;
            }
        });

        Planner.todoist.section_added_completed.connect ((id) => {
            if (temp_id_mapping == id) {
                submit_stack.visible_child_name = "label";
                temp_id_mapping = 0;

                popover_grid.sensitive = true;

                section_name_entry.text = "";
                new_section_popover.popdown ();
            }
        });

        Planner.todoist.section_added_error.connect ((id) => {
            if (temp_id_mapping == id) {
                submit_stack.visible_child_name = "label";
                temp_id_mapping = 0;

                popover_grid.sensitive = true;

                section_name_entry.text = "";
                new_section_popover.popdown ();
            }
        });
    }

    private void insert_section () {
        if (section_name_entry.text != "") {
            var section = new Objects.Section ();
            section.name = section_name_entry.text;
            section.project_id = project.id;
            section.is_todoist = project.is_todoist;

            if (project.is_todoist == 0) {
                section.id = Planner.utils.generate_id ();
                Planner.database.insert_section (section);

                section_name_entry.text = "";
                new_section_popover.popdown ();
            } else {
                temp_id_mapping = Planner.utils.generate_id ();
                section.is_todoist = 1;

                Planner.todoist.add_section (section, temp_id_mapping);
            }
        }
    }

    private void check_placeholder_view () {
        if (project.show_completed == 0) {
            if (items_uncompleted_added.size > 0 || Planner.database.get_count_sections_by_project (project.id) > 0) {
                main_stack.visible_child_name = "project";
            } else {
                main_stack.visible_child_name = "placeholder";
            }
        } else {
            if (items_uncompleted_added.size > 0 || Planner.database.get_count_sections_by_project (project.id) > 0) {
                main_stack.visible_child_name = "project";
            } else {
                if (items_completed_added.size > 0) {
                    main_stack.visible_child_name = "project";
                } else {
                    main_stack.visible_child_name = "placeholder";
                }
            }
        }
    }

    private void item_row_removed (Widgets.ItemRow row) {
        items_list.remove (row);

        items_uncompleted_added.unset (row.item.id.to_string ());
        items_completed_added.unset (row.item.id.to_string ());

        check_listbox_margin ();
    }

    private void check_listbox_margin () {
        if (project.show_completed == 0) {
            if (items_uncompleted_added.size > 0) {
                completed_revealer.margin_bottom = 32;
            } else {
                completed_revealer.margin_bottom = 6;
            }
        } else {
            if (items_uncompleted_added.size > 0) {
                completed_revealer.margin_bottom = 32;
            } else {
                if (items_completed_added.size > 0) {
                    completed_revealer.margin_bottom = 32;
                } else {
                    completed_revealer.margin_bottom = 6;
                }
            }
        }
    }

    //  private bool filter_function (Gtk.ListBoxRow row) {
    //      if (((Widgets.ItemRow) row).item.checked == 1) {
    //          return false;
    //      }

    //      return true;
    //  }

    //  private int sort_function (Gtk.ListBoxRow row1, Gtk.ListBoxRow row2) {
    //      var row1_completed = ((Widgets.ItemRow) row1).item.checked;
    //      var row2_completed = ((Widgets.ItemRow) row2).item.checked;

    //      if (row1_completed == 1 && row2_completed == 0) {
    //          return 1;
    //      } else if (row2_completed == 1 && row1_completed == 0) {
    //          return -1;
    //      }

    //      return 0;
    //  }
}
