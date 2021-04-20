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

public class Dialogs.Preferences.ItemTimePicker : Gtk.EventBox {
    public ItemTimePicker (string title, string key, bool visible_separator=true) {
        int hour, minute;
        Planner.settings.get (key, "(ii)", out hour, out minute);

        var title_label = new Gtk.Label (title);
        title_label.wrap = true;
        title_label.xalign = 0;
        title_label.get_style_context ().add_class ("font-weight-600");
        
        var time_picker = new Granite.Widgets.TimePicker ();
        time_picker.get_style_context ().add_class ("border-radius-4");
        time_picker.get_style_context ().add_class ("popover-entry");
        time_picker.time = Planner.utils.get_time_by_hour_minute (hour, minute);

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.margin_start = 12;
        box.margin_end = 12;
        box.margin_top = 6;
        box.margin_bottom = 6;
        box.hexpand = true;
        box.pack_start (title_label, false, true, 0);
        box.pack_end (time_picker, false, false, 0);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.get_style_context ().add_class ("preferences-view");
        main_box.hexpand = true;
        main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);
        main_box.pack_start (box, false, true, 0);

        if (visible_separator == true) {
            main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);
        }

        time_picker.time_changed.connect (() => {
            Planner.settings.set (key, "(ii)", time_picker.time.get_hour (), time_picker.time.get_minute ());
        });

        add (main_box);
    }
}