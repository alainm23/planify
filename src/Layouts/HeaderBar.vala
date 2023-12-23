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

public class Layouts.HeaderBar : Adw.Bin {
    private Adw.HeaderBar headerbar;
    private Gtk.Label title_label;
    private Gtk.Revealer back_button_revealer;

    private string _title;
    public string title {
        set {
            _title = value;
            title_label.label = _title;
        }

        get {
            return _title;
        }
    }

    public bool back_revealer {
        set {
            back_button_revealer.reveal_child = value;
        }

        get {
            return back_button_revealer.reveal_child;
        }
    }

    public signal void back_activated ();

    construct {
        // Sidebar   
        var sidebar_image = new Widgets.DynamicIcon ();

		if (Services.Settings.get_default ().settings.get_boolean ("slim-mode")) {
			sidebar_image.update_icon_name ("sidebar-left");
		} else {
			sidebar_image.update_icon_name ("sidebar-right");
		}

		var sidebar_button = new Gtk.Button () {
			valign = Gtk.Align.CENTER,
            child = sidebar_image
		};

		sidebar_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        // Back Button
        var back_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            child = new Widgets.DynamicIcon.from_icon_name ("go-previous-symbolic")
        };

        back_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        back_button_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = back_button,
            reveal_child = false
		};

        // Title
        title_label = new Gtk.Label (null) {
            use_markup = true,
            css_classes = { "font-bold" }
        };
        
        headerbar = new Adw.HeaderBar () {
			hexpand = true,
            show_title = false
		};

        headerbar.pack_start (sidebar_button);
        headerbar.pack_start (back_button_revealer);
        headerbar.pack_start (title_label);

        child = headerbar;

        sidebar_button.clicked.connect (() => {
			bool slim_mode = Services.Settings.get_default ().settings.get_boolean ("slim-mode");
            Services.Settings.get_default ().settings.set_boolean ("slim-mode", !slim_mode);
		});

        back_button.clicked.connect (() => {
            back_activated ();
        });
    }

    public void pack_end (Gtk.Widget widget) {
        headerbar.pack_end (widget);
    }
}