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

public class Widgets.ContextMenu.MenuItem : Gtk.Button {
    public string title {
        set {
            menu_title.label = value;
        }
    }

    public string icon {
        set {
            if (value != null) {
                menu_icon_revealer.reveal_child = true;
                menu_icon.update_icon_name (value);
            } else {
                menu_icon_revealer.reveal_child = false;
            }
        }
    }

    private Widgets.DynamicIcon menu_icon;
    private Gtk.Revealer menu_icon_revealer;
    private Gtk.Label menu_title;
    private Gtk.Label secondary_label;
    private Gtk.Revealer loading_revealer;

    public signal void activate_item ();

    public string secondary_text {
        set {
            secondary_label.label = value;
        }
    }

    bool _is_loading;
    public bool is_loading {
        get {
            return _is_loading;
        }

        set {
            loading_revealer.reveal_child = value;
            _is_loading = value;
        }
    }

    public MenuItem (string title, string? icon = null) {
        Object (
            title: title,
            icon: icon,
            hexpand: true,
            can_focus: false
        );
    }

    construct {
        add_css_class (Granite.STYLE_CLASS_FLAT);

        menu_icon = new Widgets.DynamicIcon () {
            valign = Gtk.Align.CENTER
        };
        menu_icon.size = 16;

        menu_icon_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            reveal_child = true
        };
        
        menu_icon_revealer.child = menu_icon;

        menu_title = new Gtk.Label (null);
        menu_title.use_markup = true;

        secondary_label = new Gtk.Label (null) {
            hexpand = true,
            halign = Gtk.Align.END,
            margin_end = 0
        };

        secondary_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var loading_spinner = new Gtk.Spinner () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER
        };
        loading_spinner.add_css_class ("submit-spinner");
        loading_spinner.start ();

        loading_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT
        };

        loading_revealer.child = loading_spinner;

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true
        };

        content_box.append (menu_icon_revealer);
        content_box.append (menu_title);
        content_box.append (secondary_label);
        content_box.append (loading_revealer);

        child = content_box;

        clicked.connect (() => {
            activate_item ();
        });
    }
}
