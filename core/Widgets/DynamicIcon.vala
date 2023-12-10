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

public class Widgets.DynamicIcon : Adw.Bin {
    public string icon_name { get; set; default = null; }
    public int size { get; set; default = 16; }
    
    private Gtk.Image icon;

    public DynamicIcon () {
        Object(
            halign: Gtk.Align.CENTER,
            valign: Gtk.Align.CENTER
        );
    }

    public DynamicIcon.from_icon_name (string icon_name) {
        Object(
            halign: Gtk.Align.CENTER,
            valign: Gtk.Align.CENTER,
            icon_name: icon_name
        );

        generate_icon ();
    }

    construct {
        icon = new Gtk.Image () {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        };

        child = icon;

        notify["size"].connect (() => {
            generate_icon ();
        });



        Services.Settings.get_default ().settings.changed.connect ((key) => {
			if (key == "system-appearance" || key == "appearance" || key == "dark-mode") {
                generate_icon ();
			}
		});
    }

    public void update_icon_name (string icon_name) {
        this.icon_name = icon_name;
        generate_icon ();
    }

    private void generate_icon () {
        if (icon_name == null) {
            return;
        }

        bool dark_mode = Services.Settings.get_default ().settings.get_boolean ("dark-mode");
        if (Services.Settings.get_default ().settings.get_boolean ("system-appearance")) {
            dark_mode = Granite.Settings.get_default ().prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        }
        
        if (Utils.get_default ().is_dynamic_icon (icon_name)) {
            icon.gicon = new ThemedIcon ("%s-%s".printf (
                icon_name, dark_mode ? "dark" : "light"
            ));  
            icon.pixel_size = size; 
        } else {
            icon.gicon = new ThemedIcon (icon_name);
            icon.pixel_size = size;
        }
    }
}