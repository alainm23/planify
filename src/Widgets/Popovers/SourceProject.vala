/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Widgets.Popovers.SourceProject : Gtk.Popover {
    public signal void source_changed (bool is_computer);
    public SourceProject (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.BOTTOM
        );
    }

    construct {
        var title_label = new Gtk.Label ("<small>%s</small>".printf (_("Create to")));
        title_label.use_markup = true;
        title_label.expand = true;
        title_label.halign = Gtk.Align.CENTER;
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
        
        var local_radio = new Gtk.RadioButton (null);
        local_radio.margin_end = 3;
        local_radio.hexpand = true;
        local_radio.halign = Gtk.Align.END;

        var local_icon = new Gtk.Image ();
        local_icon.gicon = new ThemedIcon ("computer-symbolic");
        local_icon.pixel_size = 32;

        var local_label = new Gtk.Label (_("Local"));
        local_label.halign = Gtk.Align.START;
        local_label.use_markup = true;
        
        var local_description = new Gtk.Label ("<small>%s</small>".printf (_("Create project in this computer")));
        local_description.use_markup = true;
        local_description.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var local_grid = new Gtk.Grid ();
        local_grid.column_spacing = 9;
        local_grid.margin_top = 6;
        local_grid.attach (local_icon,        0, 0, 1, 2);
        local_grid.attach (local_label,       1, 0, 1, 1);
        local_grid.attach (local_description, 1, 1, 1, 1);
        local_grid.attach (local_radio,       2, 0, 2, 2);
        
        var local_eventbox = new Gtk.EventBox ();
        local_eventbox.hexpand = true;
        local_eventbox.add (local_grid);

        var todoist_radio = new Gtk.RadioButton.from_widget (local_radio);
        todoist_radio.margin_end = 3;
        todoist_radio.hexpand = true;
        todoist_radio.halign = Gtk.Align.END;

        var todoist_icon = new Gtk.Image ();
        todoist_icon.gicon = new ThemedIcon ("planner-todoist");
        todoist_icon.pixel_size = 32;

        var todoist_label = new Gtk.Label (_("Todoist"));
        todoist_label.halign = Gtk.Align.START;
        todoist_label.use_markup = true;

        var todoist_description = new Gtk.Label ("<small>%s</small>".printf (Application.user.email));
        todoist_description.use_markup = true;
        todoist_description.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        
        var todoist_grid = new Gtk.Grid ();
        todoist_grid.column_spacing = 9;
        todoist_grid.margin_top = 6;
        todoist_grid.attach (todoist_icon,        0, 0, 1, 2);
        todoist_grid.attach (todoist_label,       1, 0, 1, 1);
        todoist_grid.attach (todoist_description, 1, 1, 1, 1);
        todoist_grid.attach (todoist_radio,       2, 0, 2, 2);

        var todoist_eventbox = new Gtk.EventBox ();
        todoist_eventbox.hexpand = true;
        todoist_eventbox.add (todoist_grid);

        var main_grid = new Gtk.Grid ();
        main_grid.row_spacing = 3;
        main_grid.width_request = 250;
        main_grid.margin = 6;
        main_grid.margin_top = 0;
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (title_label);
        main_grid.add (local_eventbox);
        main_grid.add (todoist_eventbox);

        add (main_grid);

        local_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                local_radio.active = true;
            }

            return false;
        });

        todoist_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                todoist_radio.active = true;
            }

            return false;
        });

        local_radio.toggled.connect (() => {
            source_changed (local_radio.active);
        });


        Application.database.user_added.connect ((user) => {
            if (user.is_todoist) {
                todoist_description.label = user.email;
            }
        });
    }
}