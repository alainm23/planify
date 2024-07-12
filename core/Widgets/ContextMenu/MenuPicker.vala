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
    public string? icon { get; construct; }
    public Gee.ArrayList<string> items_list { get; construct; }

    private Gtk.Image menu_icon;
    private Gtk.Revealer menu_icon_revealer;
    private Gtk.Label menu_title;
    private Gtk.ListBox listbox;

    public Gee.HashMap <int, Widgets.ContextMenu.MenuItemPicker> items_map = new Gee.HashMap <int, Widgets.ContextMenu.MenuItemPicker> ();

    public int _selected;
    public int selected {
        get {
            return _selected;
        }

        set {
            _selected = value;
            items_map[_selected].active = true;
        }
    }

    public MenuPicker (string title, string? icon = null, Gee.ArrayList<string> items_list) {
        Object (
            title: title,
            icon: icon,
            items_list: items_list,
            hexpand: true
        );
    }

    construct {
        menu_icon = new Gtk.Image () {
            css_classes = { "dim-label" },
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

        var arrow_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("go-next-symbolic"),
            pixel_size = 16,
            hexpand = true,
            halign = END
        };
        arrow_icon.add_css_class ("transition");
        arrow_icon.add_css_class ("hidden-button");
        arrow_icon.add_css_class ("dim-label");

        var itemselector_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true
        };

        itemselector_grid.append (menu_icon_revealer);
        itemselector_grid.append (menu_title);
        itemselector_grid.append (arrow_icon);

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
        _build_list ();

        button.clicked.connect (() => {
            listbox_revealer.reveal_child = !listbox_revealer.reveal_child;
            if (listbox_revealer.reveal_child) {
                arrow_icon.add_css_class ("opened");
            } else {
                arrow_icon.remove_css_class ("opened");
            }
        });
    }

    public void update_selected (int index) {
        items_map[index].active = true;
    }
    
    private void _build_list () {
        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox) ) {
            listbox.remove (child);
        }

        var group = new Gtk.CheckButton ();
        var index = 0;
        foreach (string item in items_list) {
            items_map[index] = new Widgets.ContextMenu.MenuItemPicker (item, group);

            items_map[index].selected.connect ((i) => {
                selected = i;
            });

            listbox.append (items_map[index]);
            index++;
        }
    }
}

public class Widgets.ContextMenu.MenuItemPicker : Gtk.ListBoxRow {
    public string title { get; construct; }
    public Gtk.CheckButton group { get; construct; }

    private Gtk.CheckButton radio_button;

    public bool active {
        set {
            radio_button.active = value;
        }

        get {
            return radio_button.active;
        }
    }

    public signal void selected (int index);

    public MenuItemPicker (string title, Gtk.CheckButton group) {
        Object (
            title: title,
            group: group
        );
    }

    construct {
        add_css_class ("no-selectable");
        add_css_class ("transition");

        radio_button = new Gtk.CheckButton.with_label (title) {
            hexpand = true,
			focus_on_click = false,
            group = group
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
            selected (get_index ());
        });
    }
}
