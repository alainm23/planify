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

public class Widgets.ProjectPicker.ProjectPickerPopover : Gtk.Popover {
    private Widgets.ProjectPickerCore project_picker_core;

    public signal void selected (Objects.Project project);

    public ProjectPickerPopover () {
        Object (
            height_request: 300,
            width_request: 275,
            has_arrow: false,
            position: Gtk.PositionType.BOTTOM
        );
    }

    ~ProjectPickerPopover () {
        debug ("Destroying - Widgets.ProjectPicker.ProjectPickerPopover\n");
    }

    construct {
        project_picker_core = new Widgets.ProjectPickerCore ();

        child = project_picker_core;
        add_css_class ("popover-contents");

        project_picker_core.selected.connect ((project) => {
            selected (project);
        });

        project_picker_core.close.connect (() => {
            popdown ();
        });

        destroy.connect (() => {
            project_picker_core.clean_up ();
        });
    }

    public void set_selected_project (Objects.Project project) {
        project_picker_core.set_selected_project (project);
    }

    public void clean_up () {
        if (project_picker_core != null) {
            project_picker_core.clean_up ();
        }
    }
}
