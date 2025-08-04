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
    private Gtk.Image menu_icon;
    private Gtk.Revealer menu_icon_revealer;
    private Gtk.Label menu_title;
    private Gtk.Label secondary_label;
    private Gtk.Revealer loading_revealer;
    private Gtk.Revealer secondary_label_revealer;
    private Gtk.Revealer select_revealer;
    private Gtk.Revealer arrow_revealer;

    public signal void activate_item ();

    public string title {
        set {
            menu_title.label = value;
        }
    }

    bool _autohide_popover = true;
    public bool autohide_popover {
        get {
            return _autohide_popover;
        }

        set {
            _autohide_popover = value;
        }
    }

    public string icon {
        set {
            if (value != null) {
                menu_icon_revealer.reveal_child = true;
                menu_icon.gicon = new ThemedIcon (value);
            } else {
                menu_icon_revealer.reveal_child = false;
            }
        }
    }

    public string secondary_text {
        set {
            secondary_label.label = value;
            secondary_label_revealer.reveal_child = value.length > 0;
        }
    }

    bool _is_loading = false;
    public bool is_loading {
        get {
            return _is_loading;
        }

        set {
            _is_loading = value;
            loading_revealer.reveal_child = _is_loading;
        }
    }

    bool _selected = false;
    public bool selected {
        get {
            return _selected;
        }

        set {
            _selected = value;
            select_revealer.reveal_child = _selected;
        }
    }

    bool _arrow = false;
    public bool arrow {
        get {
            return _arrow;
        }

        set {
            _arrow = value;
            arrow_revealer.reveal_child = _arrow;
        }
    }

    public int max_width_chars {
        set {
            menu_title.max_width_chars = value;
        }
    }

    public MenuItem (string title, string ? icon = null) {
        Object (
            title: title,
            icon: icon,
            hexpand: true
        );
    }

    construct {
        add_css_class ("flat");
        add_css_class ("no-font-bold");

        menu_icon = new Gtk.Image ();

        menu_icon_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            child = menu_icon,
            reveal_child = true
        };

        menu_title = new Gtk.Label (null) {
            use_markup = true,
            ellipsize = Pango.EllipsizeMode.END
        };

        select_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            child = new Gtk.Image.from_icon_name ("object-select-symbolic")
        };

        arrow_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            child = new Gtk.Image.from_icon_name ("go-next-symbolic") {
                css_classes = { "dim-label" },
                margin_start = 6
            }
        };

        secondary_label = new Gtk.Label (null) {
            css_classes = { "dim-label", "no-font-bold" },
            ellipsize = Pango.EllipsizeMode.END
        };

        secondary_label_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            child = secondary_label
        };

        loading_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            child = new Adw.Spinner () {
                css_classes = { "submit-spinner" }
            }
        };

        var end_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            halign = END
        };

        end_box.append (secondary_label_revealer);
        end_box.append (loading_revealer);
        end_box.append (select_revealer);
        end_box.append (arrow_revealer);

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true
        };

        content_box.append (menu_icon_revealer);
        content_box.append (menu_title);
        content_box.append (end_box);

        child = content_box;

        clicked.connect (() => {
            activate_item ();

            if (autohide_popover) {
                var popover = (Gtk.Popover) get_ancestor (typeof (Gtk.Popover));
                if (popover != null) {
                    popover.popdown ();
                }
            }
        });
    }
}
