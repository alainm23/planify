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

public class Widgets.NewCheck : Gtk.EventBox {
    public int64 item_id { get; construct; }
    public int64 project_id { get; construct; }
    public int64 section_id { get; construct; }
    public int is_todoist { get; construct; }
    public int64 temp_id_mapping {get; set; default = 0; }

    private Widgets.Entry name_entry;
    private Gtk.Revealer revealer;

    public bool reveal_child {
        set {
            revealer.reveal_child = value;

            if (value) {
                name_entry.grab_focus ();
            }
        }
        get {
            return revealer.reveal_child;
        }
    }

    public NewCheck (int64 item_id, int64 project_id, int64 section_id, int is_todoist=0) {
        Object (
            item_id: item_id,
            project_id: project_id,
            section_id: section_id,
            is_todoist: is_todoist
        );
    }

    construct {
        var loading_spinner = new Gtk.Spinner ();
        loading_spinner.start ();
        loading_spinner.margin_end = 6;

        var loading_revealer = new Gtk.Revealer ();
        loading_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        loading_revealer.add (loading_spinner);
        //loading_revealer.reveal_child = true;

        var checked_button = new Gtk.CheckButton ();
        checked_button.margin_start = 5;
        checked_button.get_style_context ().add_class ("checklist-button");
        checked_button.get_style_context ().add_class ("checklist-check");
        checked_button.valign = Gtk.Align.CENTER;

        name_entry = new Widgets.Entry ();
        name_entry.hexpand = true;
        name_entry.margin_start = 6;
        name_entry.placeholder_text = _("Subtask name");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("check-entry");

        var main_box = new Gtk.Grid ();
        main_box.get_style_context ().add_class ("check-eventbox");
        main_box.get_style_context ().add_class ("check-eventbox-border");
        main_box.margin_bottom = 6;
        main_box.margin_end = 6;
        main_box.margin_start = 22;
        main_box.add (checked_button);
        main_box.add (name_entry);
        main_box.add (loading_revealer);

        revealer = new Gtk.Revealer ();
        revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        revealer.add (main_box);

        add (revealer);

        name_entry.activate.connect (() => {
            insert_item ();
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                name_entry.text = "";
                reveal_child = false;
            }

            return false;
        });

        name_entry.focus_out_event.connect (() => {
            if (name_entry.text != "") {
                // insert_item ();
                // reveal_child = false;
            } else {
                name_entry.text = "";
                reveal_child = false;
            }

            return false;
        });

        Planner.todoist.item_added_started.connect ((id) => {
            if (temp_id_mapping == id) {
                loading_revealer.reveal_child = true;
                sensitive = false;
            }
        });

        Planner.todoist.item_added_completed.connect ((id) => {
            if (temp_id_mapping == id) {
                loading_revealer.reveal_child = false;
                sensitive = true;

                name_entry.text = "";
                name_entry.grab_focus ();
            }
        });

        Planner.todoist.item_added_error.connect ((id) => {
            if (temp_id_mapping == id) {

            }
        });
    }

    private void insert_item () {
        if (name_entry.text != "") {
            var item = new Objects.Item ();
            item.content = name_entry.text;
            item.parent_id = item_id;
            item.project_id = project_id;
            item.section_id = section_id;
            item.is_todoist = is_todoist;

            temp_id_mapping = Planner.utils.generate_id ();

            if (is_todoist == 0) {
                item.id = Planner.utils.generate_id ();
                if (Planner.database.insert_item (item)) {
                    name_entry.text = "";
                }
            } else {
                Planner.todoist.add_item (item, 0, temp_id_mapping);
            }
        }
    }
}
