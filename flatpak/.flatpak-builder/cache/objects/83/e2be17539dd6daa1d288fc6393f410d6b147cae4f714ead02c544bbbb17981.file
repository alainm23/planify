// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2017 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Maxwell Barvian <maxwell@elementary.io>
 *              Corentin Noël <corentin@elementary.io>
 */

public class Maya.MainWindow : Gtk.ApplicationWindow {
    public Gtk.Paned hpaned;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            height_request: 400,
            icon_name: "office-calendar",
            width_request: 625
        );
    }

    construct {
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/io/elementary/calendar");

        var infobar_label = new Gtk.Label (null);
        infobar_label.show ();

        var infobar = new Gtk.InfoBar ();
        infobar.message_type = Gtk.MessageType.ERROR;
        infobar.no_show_all = true;
        infobar.show_close_button = true;
        infobar.get_content_area ().add (infobar_label);

        hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (infobar);
        grid.add (hpaned);

        add (grid);

        infobar.response.connect ((id) => infobar.hide ());

        Model.CalendarModel.get_default ().error_received.connect ((message) => {
            Idle.add (() => {
                infobar_label.label = message;
                infobar.show ();
                return false;
            });
        });
    }
}
