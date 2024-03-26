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

public class Widgets.LabelPicker.LabelButton : Adw.Bin {
    private Gtk.MenuButton button; 
    private Widgets.LabelPicker.LabelPicker labels_picker;

    public Gee.ArrayList<Objects.Label> labels {
        set {
            labels_picker.labels = value;
        }
    }

    BackendType _backend_type;
    public BackendType backend_type {
        set {
            _backend_type = value;
            labels_picker.backend_type = _backend_type;
        }

        get {
            return _backend_type;
        }
    }

    public signal void labels_changed (Gee.HashMap<string, Objects.Label> labels);

    public LabelButton () {
        Object (
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Add Labels")
        );
    }

    construct {
        labels_picker = new Widgets.LabelPicker.LabelPicker ();

        button = new Gtk.MenuButton () {
            icon_name = "tag-outline-symbolic",
            popover = labels_picker,
            css_classes = { Granite.STYLE_CLASS_FLAT }
        };
        
        child = button;

        labels_picker.closed.connect (() => {
            labels_changed (labels_picker.picked);
        });
    }

    public void reset () {
        labels_picker.reset ();
    }
}
