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

public class Widgets.ProjectPicker.SectionRow : Gtk.ListBoxRow {
    public Objects.Section section { get; construct; }

    public SectionRow (Objects.Section section) {
        Object (
            section: section
        );
    }

    public SectionRow.for_no_section () {
        Objects.Section _section = new Objects.Section ();
        _section.name = _("No Section");

        Object (
            section: _section
        );
    }

    construct {
        css_classes = { "row" };

        var name_label = new Gtk.Label (section.name) {
            halign = Gtk.Align.START,
            margin_start = 3
        };

        var container = new Adw.Bin () {
            child = name_label,
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6
        };
        
        child = container;
    }
}