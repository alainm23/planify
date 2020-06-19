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

public class Widgets.NewSection : Gtk.Revealer {
    public int64 project_id { get; set; }
    public int is_todoist { get; set; }
    public int64 temp_id_mapping {get; set; default = 0; }

    private Widgets.Entry name_entry;

    public signal void cancel_activated ();

    public bool reveal {
        set {
            reveal_child = value;

            if (value) {
                name_entry.grab_focus ();

                grab_focus ();
            } else {
                name_entry.text = "";
                cancel_activated ();
            }
        }
        get {
            return reveal_child;
        }
    }

    public NewSection (int64 project_id, int is_todoist) {
        Object (
            project_id: project_id,
            is_todoist: is_todoist
        );
    }

    construct {
        transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;

        var loading_spinner = new Gtk.Spinner ();
        loading_spinner.start ();

        var loading_revealer = new Gtk.Revealer ();
        loading_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        loading_revealer.add (loading_spinner);

        name_entry = new Widgets.Entry ();
        name_entry.hexpand = true;
        name_entry.valign = Gtk.Align.CENTER;
        name_entry.placeholder_text = _("Section name");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("header-title");
        name_entry.get_style_context ().add_class ("header-entry");
        name_entry.get_style_context ().add_class ("content-entry");

        var top_grid = new Gtk.Grid ();
        top_grid.margin_start = 14;
        top_grid.column_spacing = 12;
        top_grid.add (loading_revealer);
        top_grid.add (name_entry);

        var submit_button = new Gtk.Button.with_label (_("Add"));
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));

        var action_grid = new Gtk.Grid ();
        action_grid.halign = Gtk.Align.START;
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 6;
        action_grid.margin_start = 40;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_start = 41;
        separator.margin_end = 32;
        separator.margin_bottom = 6;

        var main_grid = new Gtk.Grid ();
        main_grid.margin_top = 6;
        main_grid.margin_bottom = 12;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (top_grid);
        main_grid.add (separator);
        main_grid.add (action_grid);

        add (main_grid);

        submit_button.clicked.connect (insert_section);

        name_entry.activate.connect (() => {
            insert_section ();
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                reveal = false;
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
            reveal = false;
        });

        Planner.todoist.section_added_started.connect ((id) => {
            if (temp_id_mapping == id) {
                loading_revealer.reveal_child = true;
                sensitive = false;
            }
        });

        Planner.todoist.section_added_completed.connect ((id) => {
            if (temp_id_mapping == id) {
                loading_revealer.reveal_child = false;
                temp_id_mapping = 0;
                sensitive = true;

                reveal = false;
            }
        });

        Planner.todoist.section_added_error.connect ((id) => {
            if (temp_id_mapping == id) {
                loading_revealer.reveal_child = false;
                temp_id_mapping = 0;
                print ("Add Section Error\n");
                sensitive = true;
                reveal = false;
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
                Planner.database.insert_section (section);

                reveal = false;
            } else {
                temp_id_mapping = Planner.utils.generate_id ();
                section.is_todoist = 1;

                Planner.todoist.add_section (section, temp_id_mapping);
            }
        }
    }
}
