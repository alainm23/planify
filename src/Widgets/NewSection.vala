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

public class Widgets.NewSection : Gtk.ListBoxRow {
    public int64 project_id { get; set; }
    public int is_todoist { get; set; }
    public int index { get; set; }
    public int64 temp_id_mapping {get; set; default = 0; }

    private Widgets.Entry name_entry;
    private Gtk.Revealer main_revealer;
    private Gtk.Stack submit_stack;
    private GLib.Cancellable cancellable = null;
    private uint focus_timeout = 0;
    private bool entry_menu_opened = false;

    public NewSection (int64 project_id, int is_todoist, int index) {
        Object (
            project_id: project_id,
            is_todoist: is_todoist,
            index: index
        );
    }

    construct {
        get_style_context ().add_class ("item-row");

        name_entry = new Widgets.Entry ();
        name_entry.hexpand = true;
        name_entry.valign = Gtk.Align.CENTER;
        name_entry.placeholder_text = _("Name this section");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("transparent");
        name_entry.get_style_context ().add_class ("font-bold");
        name_entry.get_style_context ().add_class ("new-item-entry");

        var name_grid = new Gtk.Grid ();
        name_grid.get_style_context ().add_class ("new-section-grid");
        name_grid.margin_start = 42;
        name_grid.margin_end = 38;
        name_grid.add (name_entry);

        var submit_button = new Gtk.Button ();
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var submit_spinner = new Gtk.Spinner ();
        submit_spinner.start ();

        submit_stack = new Gtk.Stack ();
        submit_stack.expand = true;
        submit_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        submit_stack.add_named (new Gtk.Label (_("Add Section")), "label");
        submit_stack.add_named (submit_spinner, "spinner");

        submit_button.add (submit_stack);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("planner-button");

        var action_grid = new Gtk.Grid ();
        action_grid.halign = Gtk.Align.START;
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 6;
        action_grid.margin_start = 42;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        var main_grid = new Gtk.Grid ();
        main_grid.row_spacing = 6;
        main_grid.margin_top = 6;
        main_grid.margin_bottom = 12;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (name_grid);
        main_grid.add (action_grid);

        main_revealer = new Gtk.Revealer ();
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (main_grid);
        main_revealer.reveal_child = false;

        add (main_revealer);

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            grab_focus ();
            name_entry.grab_focus ();

            return GLib.Source.REMOVE;
        });

        submit_button.clicked.connect (insert_section);

        name_entry.activate.connect (() => {
            insert_section ();
        });

        name_entry.focus_out_event.connect (() => {
            focus_timeout = Timeout.add (1000, () => {
                if (entry_menu_opened == false && name_entry.text.strip () == "") {
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

        name_entry.focus_in_event.connect (() => {
            if (focus_timeout != 0) {
                GLib.Source.remove (focus_timeout);
            }

            return false;
        });

        name_entry.populate_popup.connect ((menu) => {
            entry_menu_opened = true;
            menu.hide.connect (() => {
                entry_menu_opened = false;
            });
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_destroy ();
            }

            return false;
        });

        name_entry.changed.connect (() => {
            if (name_entry.text != "") {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }
        });

        cancel_button.clicked.connect (() => {
            if (cancellable != null) {
                cancellable.cancel ();
            }
            
            hide_destroy ();
        });

        Planner.todoist.section_added_started.connect ((id) => {
            if (temp_id_mapping == id) {
                submit_stack.visible_child_name = "spinner";
                submit_button.sensitive = false;
            }
        });

        Planner.todoist.section_added_completed.connect ((id) => {
            if (temp_id_mapping == id) {
                hide_destroy ();
            }
        });

        Planner.todoist.section_added_error.connect ((id) => {
            if (temp_id_mapping == id) {
                submit_stack.visible_child_name = "label";
                submit_button.sensitive = true;
            }
        });
    }

    private void insert_section () {
        if (name_entry.text != "") {
            var section = new Objects.Section ();
            section.name = name_entry.text;
            section.project_id = project_id;
            section.is_todoist = is_todoist;

            if (is_todoist == 0) {
                section.id = Planner.utils.generate_id ();
                Planner.database.insert_section (section, index);
            } else {
                cancellable = new Cancellable ();
                temp_id_mapping = Planner.utils.generate_id ();

                Planner.todoist.add_section.begin (section, cancellable, temp_id_mapping, index);
            }
        }
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}
