

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

public class Layouts.HeaderItem : Adw.Bin {
    public string _header_title;
    public string header_title {
        get {
            return _header_title;
        }

        set {
            _header_title = value;
            name_label.label = _header_title;
            name_label.visible = value != null;
        }
    }
    
    public string _placeholder_message;
    public string placeholder_message {
        get {
            return _placeholder_message;
        }

        set {
            _placeholder_message = value;
            placeholder_label.label = _placeholder_message;
        }
    }

    public bool reveal {
        get {
            return content_revealer.reveal_child;
        }

        set {
            content_revealer.reveal_child = value;
        }
    }

    public Gtk.ListBox items {
        get {
            return listbox;
        }
    }

    private Gtk.Label name_label;
    private Gtk.Label placeholder_label;
    private Gtk.ListBox listbox;
    private Adw.Bin content_grid;
    private Gtk.Box action_box;
    private Gtk.Revealer content_revealer;
    private Gtk.Revealer separator_revealer;
    public signal void add_activated ();
    public signal void row_activated (Gtk.Widget widget);

    private bool has_children {
        get {
            return Util.get_default ().get_children (listbox).length () > 0;
        }
    }

    public bool show_separator {
        set {
            separator_revealer.reveal_child = value;
        }
    }

    public bool reveal_child {
        set {
            content_revealer.reveal_child = value;
        }
    }

    public bool separator_space {
        set {
            if (value) {
                listbox.add_css_class ("listbox-separator-3");
            }
        }
    }

    public bool separator_lines {
        set {
            if (value) {
                listbox.add_css_class ("separator-lines");
            }
        }
    }

    public bool listbox_no_margin {
        set {
            if (value) {
                listbox.margin_top = 0;
                listbox.margin_bottom = 0;
                listbox.margin_start = 0;
                listbox.margin_end = 0;
            }
        }
    }
    
    public HeaderItem (string? header_title = null) {
        Object (
            header_title: header_title
        );
    }

    construct {
        name_label = new Gtk.Label (null) {
            halign = Gtk.Align.START
        };

        name_label.add_css_class (Granite.STYLE_CLASS_H4_LABEL);
        name_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        listbox = new Gtk.ListBox () {
            hexpand = true
        };
        
        listbox.set_placeholder (get_placeholder ());
        listbox.add_css_class ("bg-transparent");

        content_grid = new Adw.Bin () {
            child = listbox
        };

        action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            halign = END
        };

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            margin_start = 6,
            margin_end = 6
        };

        header_box.append (name_label);
        header_box.append (action_box);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3,
            margin_start = 3,
            margin_bottom = 3
        };

        separator_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = separator
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            margin_top = 3
        };

        content_box.append (header_box);
        content_box.append (separator_revealer);
        content_box.append (content_grid);

        content_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = content_box
        };

        child = content_revealer;

        listbox.row_activated.connect ((row) => {
            row_activated (row);
        });
    }

    private Gtk.Widget get_placeholder () {
        placeholder_label = new Gtk.Label (null) {
            wrap = true,
            justify = Gtk.Justification.CENTER
        };
        
        placeholder_label.add_css_class ("dim-label");
        placeholder_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var content_box = new Adw.Bin () {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12,
            child = placeholder_label
        };

        return content_box;
    }


    public void add_child (Gtk.Widget widget) {
        listbox.append (widget);
    }

    public void insert_child (Gtk.Widget widget, int position) {
        listbox.insert (widget, position);
    }

    public void clear () {
        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox) ) {
            listbox.remove (child);
        }
    }

    public void add_widget_end (Gtk.Widget widget) {
        action_box.append (widget);
    }

    public void remove_child (Gtk.Widget widget) {
        listbox.remove (widget);
    }

    public void check_visibility (int size) {
        content_revealer.reveal_child = size > 0;
    }

    public void set_sort_func (owned Gtk.ListBoxSortFunc? sort_func) {
        listbox.set_sort_func ((owned) sort_func);
    }

    public void set_filter_func (owned Gtk.ListBoxFilterFunc? filter_func) {
        listbox.set_filter_func ((owned) filter_func);
    }

    public void invalidate_filter () {
        listbox.invalidate_filter ();
    }
}
