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

public class Widgets.ContextMenu.MenuSwitch : Gtk.Button {
    public string title {
        set {
            menu_title.label = value;
        }
    }

    public string icon {
        set {
            if (value != null) {
                menu_icon_revealer.reveal_child = true;
                menu_icon.icon_name = value;
            } else {
                menu_icon_revealer.reveal_child = false;
            }
        }
    }

    public bool active {
        set {
            switch_widget.active = value;
        }

        get {
            return switch_widget.active;
        }
    }

    private Gtk.Image menu_icon;
    private Gtk.Revealer menu_icon_revealer;
    private Gtk.Label menu_title;
    private Gtk.Switch switch_widget;

    public signal void activate_item ();

    public MenuSwitch (string title, string? icon = null) {
        Object (
            title: title,
            icon: icon,
            hexpand: true,
            can_focus: false
        );
    }

    construct {
        add_css_class (Granite.STYLE_CLASS_FLAT);

        menu_icon = new Gtk.Image () {
            valign = Gtk.Align.CENTER
        };

        menu_icon_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            reveal_child = true
        };
        
        menu_icon_revealer.child = menu_icon;

        menu_title = new Gtk.Label (null);
        menu_title.use_markup = true;

        switch_widget = new Gtk.Switch () {
			valign = CENTER,
            hexpand = true,
            halign = END
		};

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true
        };

        content_box.append (menu_icon_revealer);
        content_box.append (menu_title);
        content_box.append (switch_widget);

        child = content_box;

        clicked.connect (() => {
            switch_widget.active = !switch_widget.active;
            activate_item ();
        });    
    }
}
