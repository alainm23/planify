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

public class Widgets.ContextMenu.MenuCheckPicker : Adw.Bin {
    public string title { get; construct; }
    public string ? icon { get; construct; }

    private Gtk.Image menu_icon;
    private Gtk.Revealer menu_icon_revealer;
    private Gtk.Label menu_title;
    private Gtk.ListBox listbox;

    public Gee.HashMap<string, Widgets.ContextMenu.MenuItemCheckPicker> filters_map;

    public signal void filter_change (Objects.Filters.FilterItem filter, bool active);

    public MenuCheckPicker (string title, string ? icon = null) {
        Object (
            title: title,
            icon: icon,
            hexpand: true
        );
    }

    ~MenuCheckPicker () {
        print ("Destroying - Widgets.ContextMenu.MenuCheckPicker\n");
    }

    construct {
        filters_map = new Gee.HashMap<string, Widgets.ContextMenu.MenuItemCheckPicker> ();

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

        var arrow_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("go-next-symbolic"),
            pixel_size = 16,
            hexpand = true,
            halign = END
        };
        arrow_icon.add_css_class ("transition");
        arrow_icon.add_css_class ("hidden-button");

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

        button.clicked.connect (() => {
            listbox_revealer.reveal_child = !listbox_revealer.reveal_child;
            if (listbox_revealer.reveal_child) {
                arrow_icon.add_css_class ("opened");
            } else {
                arrow_icon.remove_css_class ("opened");
            }
        });
    }

    public void set_items (Gee.ArrayList<Objects.Filters.FilterItem> filters) {
        filters_map.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox)) {
            listbox.remove (child);
        }

        foreach (Objects.Filters.FilterItem filter in filters) {
            filters_map[filter.id] = new Widgets.ContextMenu.MenuItemCheckPicker (filter);

            filters_map[filter.id].checked.connect ((filter, active) => {
                filter_change (filter, active);
            });

            listbox.append (filters_map[filter.id]);
        }
    }

    public void unchecked (Objects.Filters.FilterItem filter) {
        if (filters_map.has_key (filter.id)) {
            filters_map[filter.id].active = false;
        }
    }
}

public class Widgets.ContextMenu.MenuItemCheckPicker : Gtk.ListBoxRow {
    public Objects.Filters.FilterItem filter { get; construct; }

    private Gtk.CheckButton check_button;

    public bool active {
        set {
            check_button.active = value;
        }

        get {
            return check_button.active;
        }
    }

    public signal void checked (Objects.Filters.FilterItem filter, bool active);

    public MenuItemCheckPicker (Objects.Filters.FilterItem filter) {
        Object (
            filter: filter
        );
    }

    construct {
        add_css_class ("border-radius-6");

        check_button = new Gtk.CheckButton.with_label (filter.name) {
            hexpand = true,
            css_classes = { "checkbutton-label" }
        };

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_top = 3,
            margin_start = 3,
            margin_end = 3,
            margin_bottom = 3
        };

        content_box.append (check_button);
        child = content_box;

        var gesture = new Gtk.GestureClick ();
        add_controller (gesture);
        gesture.pressed.connect (() => {
            gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            check_button.active = !check_button.active;
            checked (filter, check_button.active);
        });

        activate.connect (() => {
            check_button.active = !check_button.active;
            checked (filter, check_button.active);
        });
    }
}
