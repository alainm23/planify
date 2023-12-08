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

public class Dialogs.ManageSectionOrder : Adw.Window {
    public Objects.Project project { get; construct; }
    private Gtk.ListBox listbox;

    public ManageSectionOrder (Objects.Project project) {
        Object (
            project: project,
            deletable: true,
            resizable: true,
            modal: true,
            title: _("Manage Section Order"),
            width_request: 320,
            height_request: 450,
            transient_for: (Gtk.Window) Planify.instance.main_window
        );
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);

        listbox = new Gtk.ListBox () {
            hexpand = true,
            margin_top = 6,
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 6
        };

        listbox.add_css_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12
        };
        
        listbox_grid.attach (listbox, 0, 0);
        listbox_grid.add_css_class (Granite.STYLE_CLASS_CARD);

        var listbox_scrolled = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = listbox_grid
        };

        var submit_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Update")) {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };
        submit_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.append (headerbar);
        content_box.append (listbox_scrolled);
        content_box.append (submit_button);

        content = content_box;
        add_sections ();

        Timeout.add (225, () => {
            set_sort_func ();
            return GLib.Source.REMOVE;
        });

        submit_button.clicked.connect (() => {
            update_section_section_order ();
            project.section_sort_order_changed ();
            hide_destroy ();
        });
    }
    
    private void set_sort_func () {
        listbox.set_sort_func ((row1, row2) => {
            Objects.Section item1 = ((Dialogs.ProjectPicker.SectionPickerRow) row1).section;
            Objects.Section item2 = ((Dialogs.ProjectPicker.SectionPickerRow) row2).section;

            return item1.section_order - item2.section_order;
        });

        listbox.set_sort_func (null);
    }

    private void update_section_section_order () {
        unowned Dialogs.ProjectPicker.SectionPickerRow? section_row = null;
        var row_index = 0;

        do {
            section_row = (Dialogs.ProjectPicker.SectionPickerRow) listbox.get_row_at_index (row_index);

            if (section_row != null) {
                section_row.section.section_order = row_index;
                Services.Database.get_default ().update_section (section_row.section);
            }

            row_index++;
        } while (section_row != null);
    }


    public void add_sections () {
        foreach (Objects.Section section in project.sections) {
            listbox.append (new Dialogs.ProjectPicker.SectionPickerRow (section, "order"));
        }
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}
