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

public class Widgets.ContextMenu.MenuPicker : Adw.Bin {
    public string title { get; construct; }
    public string ? icon { get; construct; }

    private Gtk.Image menu_icon;
    private Gtk.Revealer menu_icon_revealer;
    private Gtk.Label menu_title;
    private Gtk.Label value_label;
    private Gtk.ListBox listbox;
    private Gtk.CheckButton group_radio = new Gtk.CheckButton ();

    public string _selected;
    public string selected {
        get {
            return _selected;
        }

        set {
            _selected = value;
            update_selected (_selected);
        }
    }

    private Gee.HashMap<string, MenuItemPicker> item_map = new Gee.HashMap<string, MenuItemPicker> ();

    public MenuPicker (string title, string ? icon = null) {
        Object (
            title: title,
            icon: icon,
            hexpand: true
        );
    }

    ~MenuPicker () {
        debug ("Destroying - Widgets.ContextMenu.MenuPicker\n");
    }

    construct {
        menu_icon = new Gtk.Image () {
            valign = Gtk.Align.CENTER
        };

        menu_icon_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            reveal_child = false,
            child = menu_icon
        };

        if (icon != null) {
            menu_icon_revealer.reveal_child = true;
            menu_icon.icon_name = icon;
        }

        menu_title = new Gtk.Label (title);
        menu_title.use_markup = true;

        value_label = new Gtk.Label (null) {
            ellipsize = END
        };
        value_label.add_css_class ("dimmed");
        value_label.add_css_class ("caption");

        var arrow_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("go-next-symbolic"),
            pixel_size = 16,
            hexpand = true,
            halign = END
        };
        arrow_icon.add_css_class ("transition");
        arrow_icon.add_css_class ("hidden-button");

        var end_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            halign = END
        };
        end_box.append (value_label);
        end_box.append (arrow_icon);

        var itemselector_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true
        };

        itemselector_grid.append (menu_icon_revealer);
        itemselector_grid.append (menu_title);
        itemselector_grid.append (end_box);

        var button = new Gtk.Button ();
        button.child = itemselector_grid;
        button.add_css_class ("flat");
        button.add_css_class ("transition");
        button.add_css_class ("no-font-bold");

        listbox = new Gtk.ListBox () {
            css_classes = { "listbox-background" }
        };

        var listbox_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = listbox
        };

        var main_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true
        };

        main_grid.append (button);
        main_grid.append (listbox_revealer);

        child = main_grid;

        button.clicked.connect (() => {
            listbox_revealer.reveal_child = !listbox_revealer.reveal_child;
            if (listbox_revealer.reveal_child) {
                arrow_icon.add_css_class ("opened");
            } else {
                arrow_icon.remove_css_class ("opened");
            }
        });
    }

    public void update_selected (string value) {
        if (item_map.has_key (value)) {
            item_map[value].active = true;
            value_label.label = item_map[value].title;
        }
    }

    public void add_item (string title, string value) {
        if (item_map.has_key (value)) {
            return;
        }

        var row = new MenuItemPicker (title, value) {
            group = group_radio
        };

        if (value == selected) {
            row.active = true;
            value_label.label = title;
        }

        row.selected.connect ((value) => {
            selected = value;
        });

        item_map[value] = row;
        listbox.append (item_map[value]);
    }

    public class MenuItemPicker : Gtk.ListBoxRow {
        public string title { get; construct; }
        public string value { get; construct; }

        private Gtk.CheckButton radio_button;

        public bool active {
            set {
                radio_button.active = value;
            }

            get {
                return radio_button.active;
            }
        }

        public Gtk.CheckButton group {
            set {
                radio_button.group = value;
            }
        }

        public signal void selected (string value);

        public MenuItemPicker (string title, string value) {
            Object (
                title: title,
                value: value
            );
        }

        construct {
            add_css_class ("border-radius-6");
            add_css_class ("transition");

            radio_button = new Gtk.CheckButton.with_label (title) {
                hexpand = true,
                focus_on_click = false
            };

            radio_button.add_css_class ("checkbutton-label");

            var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
                margin_top = 3,
                margin_start = 3,
                margin_end = 3,
                margin_bottom = 3
            };

            content_box.append (radio_button);
            child = content_box;

            var gesture = new Gtk.GestureClick ();
            radio_button.add_controller (gesture);
            gesture.pressed.connect (() => {
                radio_button.active = !radio_button.active;
                selected (value);
            });

            activate.connect (() => {
                radio_button.active = !radio_button.active;
                selected (value);
            });
        }
    }
}
