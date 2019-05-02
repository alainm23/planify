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

public class Dialogs.Settings : Gtk.Dialog {
    private Gtk.Label settings_label;
    private Gtk.SearchEntry search_entry;

    public Settings () {
        Object (
            transient_for: Application.instance.main_window,
            deletable: false,
            resizable: false,
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            modal: true
        );
    }
    
    construct {
        title = _("Settings");
        height_request = 500;
        width_request = 600;

        // Settings
        settings_label = new Gtk.Label ("<b>%s</b>".printf (_("Settings")));
        settings_label.use_markup = true;
        settings_label.get_style_context ().add_class ("h3");

        // Search Entry
        search_entry = new Gtk.SearchEntry ();
        search_entry.valign = Gtk.Align.CENTER;
        search_entry.halign = Gtk.Align.CENTER;
        search_entry.width_request = 200;
        search_entry.get_style_context ().add_class ("headerbar-search");
        search_entry.placeholder_text = _("Quick find");

        var top_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        top_box.margin_start = 24;
        top_box.margin_end = 24;
        top_box.pack_start (settings_label, false, false, 0);
        top_box.pack_end (search_entry, false, false, 0);

        var content_grid = new Gtk.Grid ();
        content_grid.orientation = Gtk.Orientation.VERTICAL;
        content_grid.add (top_box);

        ((Gtk.Container) get_content_area ()).add (content_grid);
    }
}