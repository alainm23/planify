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
    public Objects.Item item { get; construct; }

    private Gtk.MenuButton button; 
    private Widgets.LabelPicker.LabelPicker labels_picker;

    public signal void labels_changed (Gee.HashMap <string, Objects.Label> labels);

    public LabelButton (Objects.Item item) {
        Object (
            item: item,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Add label(s)")
        );
    }

    construct {
        labels_picker = new Widgets.LabelPicker.LabelPicker ();

        button = new Gtk.MenuButton () {
            child = new Widgets.DynamicIcon.from_icon_name ("planner-tag"),
            popover = labels_picker,
            css_classes = { Granite.STYLE_CLASS_FLAT }
        };
        
        child = button;

        labels_picker.show.connect (() => {
            labels_picker.item = item;
        });

        labels_picker.closed.connect (() => {
            labels_changed (labels_picker.labels_map);
        });
    }
}