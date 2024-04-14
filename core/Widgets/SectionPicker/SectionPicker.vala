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

public class Widgets.SectionPicker.SectionPicker : Gtk.Popover {
    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox listbox;

    public signal void selected (Objects.Section section);

    public SectionPicker () {
        Object (
            position: Gtk.PositionType.BOTTOM,
            width_request: 275,
            height_request: 300
        );
    }

    construct {
        css_classes = { "popover-contents" };
        
        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Search"),
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_top = 9,
            margin_start = 9,
            margin_end = 9,
            margin_bottom = 9
        };

        listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = Gtk.Align.START,
            css_classes = { "listbox-separator-3", "listbox-background" }
        };

        listbox.set_filter_func ((row) => {
            return search_entry.text.down () in ((Widgets.SectionPicker.SectionPickerRow) row).section.name.down ();
        });

        var listbox_content = new Adw.Bin () {
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 6,
            child = listbox,
            css_classes = { "card" },
            valign = Gtk.Align.START
        };

        var listbox_scrolled = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = listbox_content
        };

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (search_entry);
		toolbar_view.content = listbox_scrolled;

        child = toolbar_view;

        listbox.row_activated.connect ((row) => {
            var section = ((Widgets.SectionPicker.SectionPickerRow) row).section;
            selected (section);
            popdown ();
        });

        search_entry.search_changed.connect (() => {
            listbox.invalidate_filter ();
        });
    }

    public void set_sections (Gee.ArrayList<Objects.Section> sections) {
        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox)) {
            listbox.remove (child);
        }

        var _section = new Objects.Section ();
        _section.name = _("No Section");
        listbox.append (new Widgets.SectionPicker.SectionPickerRow (_section));
        foreach (Objects.Section section in sections) {
            listbox.append (new Widgets.SectionPicker.SectionPickerRow (section));
        }
    }

    public void set_section (string section_id) {
        Services.EventBus.get_default ().section_picker_changed (section_id);
    }
}