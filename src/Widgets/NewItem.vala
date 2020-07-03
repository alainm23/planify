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
    public int64 project_id { get; construct; }
    public int64 section_id { get; construct; }
    public int is_todoist { get; construct; }
    public int index { get; construct; }
    public bool has_index { get; set; default = false; }
    public string due_date { get; set; default = ""; }
    public Gtk.ListBox? listbox { get; construct; }

    public int64 temp_id_mapping {get; set; default = 0; }

    private uint timeout_id = 0;

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
    }

    construct {
        can_focus = false;
        activatable = false;
        selectable = false;
        get_style_context ().add_class ("item-row");
        margin_end = 6;
        margin_start = 6;

        var checked_button = new Gtk.CheckButton ();
        checked_button.margin_start = 6;
        checked_button.get_style_context ().add_class ("checklist-border");
        checked_button.valign = Gtk.Align.CENTER;

        content_entry = new Widgets.Entry ();
        content_entry.hexpand = true;
        content_entry.margin_start = 4;
        content_entry.margin_bottom = 1;
        content_entry.placeholder_text = _("Task name");
        content_entry.get_style_context ().add_class ("flat");
        content_entry.get_style_context ().add_class ("new-entry");
        content_entry.get_style_context ().add_class ("no-padding-right");

        var content_grid = new Gtk.Grid ();
        content_grid.get_style_context ().add_class ("check-eventbox");
        content_grid.get_style_context ().add_class ("check-eventbox-border");
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

        var action_grid = new Gtk.Grid ();
        action_grid.halign = Gtk.Align.START;
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 6;
        action_grid.margin_bottom = 6;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.row_spacing = 9;
        main_grid.expand = false;
        main_grid.margin_top = 6;
        main_grid.add (content_grid);
        main_grid.add (action_grid);

        main_revealer = new Gtk.Revealer ();
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        main_revealer.add (main_grid);
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
            if (entry_menu_opened == false) {
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

                    hide_destroy ();
                }
            }
        }
    }
}
