/*
 * Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
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

public class Dialogs.ProjectPicker.ProjectPickerSourceRow : Gtk.ListBoxRow {
    public Objects.Source source { get; construct; }

    private Layouts.HeaderItem group;

    public ProjectPickerSourceRow (Objects.Source source) {
        Object (
            source: source
        );
    }

    ~ProjectPickerSourceRow () {
        print ("Destroying Dialogs.ProjectPicker.ProjectPickerSourceRow\n");
    }

    construct {
        css_classes = { "no-selectable", "no-padding" };

        group = new Layouts.HeaderItem (source.display_name) {
            card = true,
            reveal = true
        };

        child = group;
        add_projects ();

        destroy.connect (() => {
            foreach (Gtk.ListBoxRow row in group.get_children ()) {
                (row as Dialogs.ProjectPicker.ProjectPickerRow).clean_up ();
            }

            group.clear ();
        }); 
    }

    private void add_projects () {
        foreach (Objects.Project project in Services.Store.instance ().get_projects_by_source (source.id)) {
            if (project.is_archived || project.is_inbox_project || project.is_deck) {
                continue;
            }

            group.add_child (new Dialogs.ProjectPicker.ProjectPickerRow (project));
        }
    }

    public void filter (string search) {
        int size = 0;
        group.set_filter_func ((row) => {
            var project = ((Dialogs.ProjectPicker.ProjectPickerRow) row).project;
            var return_value = search.down () in project.name.down ();

            if (return_value) {
                size++;
            }

            return return_value;
        });

        group.reveal_child = size > 0;
    }
}
