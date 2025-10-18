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

public class Dialogs.ProjectPicker.ProjectPicker : Adw.Dialog {
    public Objects.Source ? source { get; construct; }

    private Widgets.ProjectPickerCore project_picker_core;

    public Objects.Project project {
        set {
            project_picker_core.set_selected_project (value);
        }
    }

    public signal void changed (string type, string id);

    public ProjectPicker.for_project (Objects.Source source) {
        Object (
            source: source,
            title: _("Move"),
            content_width: 400,
            content_height: 550
        );
    }

    public ProjectPicker.for_projects () {
        Object (
            source: null,
            title: _("Move"),
            content_width: 400,
            content_height: 550
        );
    }

    ~ProjectPicker () {
        debug ("Destroying Dialogs.ProjectPicker.ProjectPicker\n");
    }

    construct {
        project_picker_core = new Widgets.ProjectPickerCore (source);

        var toolbar_view = new Adw.ToolbarView () {
            content = project_picker_core
        };
        toolbar_view.add_top_bar (new Adw.HeaderBar ());

        child = toolbar_view;
        Services.EventBus.get_default ().disconnect_all_accels ();

        project_picker_core.selected.connect ((project) => {
            changed ("project", project.id);
        });

        project_picker_core.close.connect (() => {
            close ();
        });

        closed.connect (() => {
            clean_up ();
            Services.EventBus.get_default ().connect_all_accels ();
        });
    }

    public void clean_up () {
        if (project_picker_core != null) {
            project_picker_core.clean_up ();
        }
    }
}
