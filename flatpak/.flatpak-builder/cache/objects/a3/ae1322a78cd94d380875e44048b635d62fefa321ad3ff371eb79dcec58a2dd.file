// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2015 Maya Developers (http://launchpad.net/maya)
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
 * Authored by: Maxwell Barvian
 */

public class Maya.View.Widgets.DateSwitcher : Gtk.Grid {
    public signal void left_clicked ();
    public signal void right_clicked ();

    private Gtk.Label label;
    public string text {
        get { return label.label; }
        set {
            string new_value = value.substring (value.index_of_nth_char (1));
            new_value = value.get_char (0).totitle ().to_string () + new_value;
            label.label = new_value;
        }
    }

    public DateSwitcher (int width_chars) {
        label.width_chars = width_chars;
    }

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        label = new Gtk.Label (null);
        label.vexpand = true;
        label.margin_start = label.margin_end = 3;
        var start_button = new Gtk.Button.from_icon_name ("pan-start-symbolic", Gtk.IconSize.MENU);
        start_button.get_style_context ().remove_class ("image-button");
        start_button.image.margin = 3;
        var end_button = new Gtk.Button.from_icon_name ("pan-end-symbolic", Gtk.IconSize.MENU);
        end_button.get_style_context ().remove_class ("image-button");
        end_button.image.margin = 3;
        var center_button = new Gtk.Button ();
        center_button.add (label);
        add (start_button);
        add (center_button);
        add (end_button);
        start_button.clicked.connect (() => left_clicked ());
        end_button.clicked.connect (() => right_clicked ());
    }
}

