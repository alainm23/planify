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

public class Widgets.SectionPicker.SectionButton : Adw.Bin {
    private Gtk.Label section_label;
    private Widgets.SectionPicker.SectionPicker picker;

    public signal void selected (Objects.Section section);
    
    public SectionButton () {
        Object (
            tooltip_text: _("Set Section")
        );
    }

    construct {
        var title_label = new Gtk.Label (_("Section")) {
            halign = START,
            css_classes = { "title-4", "caption" }
        };

        section_label = new Gtk.Label (_("Select Section")) {
            xalign = 0,
            use_markup = true,
            halign = START,
            ellipsize = Pango.EllipsizeMode.END,
            css_classes = { "caption" }
        };

        var card_grid = new Gtk.Grid () {
            column_spacing = 12,
            margin_start = 12,
            margin_end = 6,
            margin_top = 6,
            margin_bottom = 6,
            vexpand = true,
            hexpand = true
        };
        card_grid.attach (new Gtk.Image.from_icon_name ("arrow3-right-symbolic"), 0, 0, 1, 2);
        card_grid.attach (title_label, 1, 0, 1, 1);
        card_grid.attach (section_label, 1, 1, 1, 1);

        picker = new Widgets.SectionPicker.SectionPicker ();
        picker.set_parent (card_grid);

        css_classes = { "card", "activatable" };
        child = card_grid;
        hexpand = true;
        vexpand = true;

        var click_gesture = new Gtk.GestureClick ();
        card_grid.add_controller (click_gesture);
        click_gesture.pressed.connect ((n_press, x, y) => {
            picker.show ();
        });
        
        picker.selected.connect ((section) => {
            selected (section);
        });
    }

    public void set_sections (Gee.ArrayList<Objects.Section> sections) {
        picker.set_sections (sections);
    }

    public void update_from_item (Objects.Item item) {
        section_label.label = _("No Section");
        section_label.tooltip_text = null;

        if (item.parent_id != "") {
            return;
        }

        if (item.section_id != "") {
            section_label.label = item.section.name;
            section_label.tooltip_text = item.section.name;
        }

        picker.set_section (item.section_id);
    }
}
