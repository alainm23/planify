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

public class Widgets.SettingsHeader : Adw.Bin {
    public bool show_back_button { get; construct; }

    public string title {
        set {
            title_label.label = value;
        }
    }

    private Gtk.Label title_label;
    
    public signal void done_activated ();
    public signal void back_activated ();

    public SettingsHeader (string title, bool show_back_button = true) {
        Object (
            title: title,
            show_back_button: show_back_button,
            hexpand: true
        );
    }

    construct {
        var back_image = new Widgets.DynamicIcon.from_icon_name ("go-previous-symbolic");

        var back_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        back_grid.append (back_image);

        var back_button = new Gtk.Button () {
            can_focus = false,
            valign = Gtk.Align.CENTER,
            child = back_grid
        };

        back_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        
        title_label = new Gtk.Label (null);
        title_label.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);

        var headerbar = new Gtk.HeaderBar () {
			title_widget = title_label,
			show_title_buttons = true,
			hexpand = true
		};

        headerbar.add_css_class ("flat");

        if (show_back_button) {
            headerbar.pack_start (back_button);
        }

        child = headerbar;

        back_button.clicked.connect (() => {
            back_activated ();
        });
    }
}
