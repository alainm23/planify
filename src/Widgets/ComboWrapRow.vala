/*
* Copyright © 2025 Alain M. (https://github.com/alainm23/planify)
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

public class Widgets.ComboWrapRow : Adw.PreferencesRow {
    private Gtk.Label _title_label;
    private Gtk.Label _subtitle_label;
    private Adw.WrapBox _wrap_box;

    public string title {
        owned get {
             return _title_label.label;
        }

        set {
            _title_label.label = value;
        }
    }

    public string subtitle {
        owned get {
            return _subtitle_label.label;
        }

        set {
            _subtitle_label.label = value;
        }
    }

    public Gtk.StringList model {
        set {
            for (uint i = 0; i < value.get_n_items (); i++) {
                var button = new Gtk.Button.with_label (value.get_string (i));
                button.add_css_class ("tiny-button");
                button.add_css_class ("caption");

                int index = (int) i;
                button.clicked.connect (() => {
                    selected = index;
                });

                _wrap_box.append (button);
            }
        }
    }

    public int selected {
        set {
            var child = _wrap_box.get_first_child ();
            int index = 0;
            while (child != null) {
                if (child is Gtk.Button) {
                    var button = (Gtk.Button) child;
                    if (index == value) {
                        button.add_css_class ("color-primary");
                    } else {
                        button.remove_css_class ("color-primary");
                    }
                }
                child = child.get_next_sibling ();
                index++;
            }
        }

        get {
            var child = _wrap_box.get_first_child ();
            int index = 0;
            while (child != null) {
                if (child is Gtk.Button && ((Gtk.Button) child).has_css_class ("color-primary")) {
                    return index;
                }
                child = child.get_next_sibling ();
                index++;
            }
            return -1;
        }
    }

    construct {
        _title_label = new Gtk.Label (null) {
            hexpand = true,
            xalign = 0,
            wrap = true
        };

        _subtitle_label = new Gtk.Label (null) {
            xalign = 0,
            hexpand = true,
            use_markup = true,
            wrap = true
        };
        _subtitle_label.add_css_class ("dimmed");
        _subtitle_label.add_css_class ("caption");

        var _text_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3) {
            hexpand = true,
            valign = Gtk.Align.CENTER
        };

        _text_box.append (_title_label);
        _text_box.append (_subtitle_label);

        _wrap_box = new Adw.WrapBox () {
            line_spacing = 6,
            child_spacing = 6
        };

        var main_box = new Gtk.Box (VERTICAL, 12) {
            margin_start = 12,
            margin_end = 12,
            margin_top = 8,
            margin_bottom = 8
        };
        
        main_box.append (_text_box);
        main_box.append (_wrap_box);

        child = main_box;
    }


}