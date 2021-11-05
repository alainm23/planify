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

public class Widgets.ProjectRow : Gtk.ListBoxRow {
    public Objects.Project project { get; construct; }

    private Gtk.Label name_label;
    private Gtk.Revealer main_revealer;
    private Widgets.ProjectProgress project_progress;

    public ProjectRow (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        get_style_context ().add_class ("selectable-item");
        
        project_progress = new Widgets.ProjectProgress (18);
        project_progress.enable_subprojects = true;
        project_progress.valign = Gtk.Align.CENTER;
        project_progress.halign = Gtk.Align.CENTER;
        project_progress.progress_fill_color = Util.get_default ().get_color (project.color);

        name_label = new Gtk.Label (project.name);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

        var main_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin = 3
        };
        main_grid.add (project_progress);
        main_grid.add (name_label);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.add (main_grid);

        add (main_revealer);

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });
    }
}