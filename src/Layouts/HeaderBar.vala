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
    private Gtk.Label title2_label;
    private Gtk.Revealer back_button_revealer;
    private Gtk.Box start_box;
    private Gtk.Button back_button;
    private Gtk.Button sidebar_button;

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

    private string _title2;
    public string title2 {
        set {
            _title2 = value;
            title2_label.label = _title2;
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
		sidebar_button = new Gtk.Button () {
			valign = Gtk.Align.CENTER,
            css_classes = { "flat" },
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Open/Close Sidebar"), "M"),
		};

        update_sidebar_icon ();

        // Back Button
        back_button = new Gtk.Button.from_icon_name ("go-previous-symbolic") {
            valign = Gtk.Align.CENTER,
            margin_end = 6,
            css_classes = { "flat" },
            tooltip_text = _("Back")
        };

        back_button_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = back_button,
            reveal_child = false
		};

        // Title
        title_label = new Gtk.Label (null) {
            css_classes = { "font-bold" },
            ellipsize = Pango.EllipsizeMode.END
        };

        title2_label = new Gtk.Label (null) {
            css_classes = { "font-bold", "caption" },
            ellipsize = Pango.EllipsizeMode.END,
            margin_start = 6,
            margin_top = 3
        };
            
        start_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        start_box.append (sidebar_button);
        start_box.append (back_button_revealer);
        start_box.append (title_label);
        start_box.append (title2_label);

        headerbar = new Adw.HeaderBar () {
			hexpand = true,
            show_title = false
		};

        headerbar.pack_start (start_box);

        child = headerbar;

        sidebar_button.clicked.connect (() => {
			bool slim_mode = Services.Settings.get_default ().settings.get_boolean ("slim-mode");
            Services.Settings.get_default ().settings.set_boolean ("slim-mode", !slim_mode);
		});

        back_button.clicked.connect (() => {
            back_activated ();
        });

        Services.Settings.get_default ().settings.changed.connect ((key) => {
			if (key == "slim-mode") {
                update_sidebar_icon ();
            }
        });
    }

    private void update_sidebar_icon () {
        if (Services.Settings.get_default ().settings.get_boolean ("slim-mode")) {
            sidebar_button.icon_name = "dock-left-symbolic";
        } else {
            sidebar_button.icon_name = "dock-right-symbolic";
        }
    }
    
    public void pack_end (Gtk.Widget widget) {
        headerbar.pack_end (widget);
    }
}
