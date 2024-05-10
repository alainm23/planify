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
    private Gtk.ListBox archived_listbox;
    private Widgets.ScrolledWindow scrolled_window;

    public ManageSectionOrder (Objects.Project project) {
        Object (
            project: project,
            deletable: true,
            resizable: true,
            modal: true,
            title: _("Manage Sections"),
            width_request: 320,
            height_request: 420,
            transient_for: (Gtk.Window) Planify.instance.main_window
        );
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);

        listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = START,
            css_classes = { "listbox-background" }
        };

        var listbox_card = new Adw.Bin () {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 6,
            margin_top = 3,
            css_classes = { "card" },
            child = listbox,
            valign = START
        };

        var archived_title = new Gtk.Label (_("Archived")) {
            halign = START,
            css_classes = { "heading", "h4" },
            margin_start = 16
        };

        archived_listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = START,
            css_classes = { "listbox-background" }
        };

        var archived_listbox_card = new Adw.Bin () {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 6,
            margin_top = 3,
            css_classes = { "card" },
            child = archived_listbox,
            valign = START
        };

        var archived_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 12
        };
        archived_box.append (archived_title);
        archived_box.append (archived_listbox_card);

        var archived_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = archived_box,
            reveal_child = project.sections_archived.size > 0
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.append (listbox_card);
        content_box.append (archived_revealer);

        scrolled_window = new Widgets.ScrolledWindow (content_box);

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (headerbar);
		toolbar_view.content = scrolled_window;

        content = toolbar_view;
        add_sections ();

        Timeout.add (225, () => {
            set_sort_func ();
            return GLib.Source.REMOVE;
        });

        Services.Database.get_default ().section_deleted.connect ((section) => {
            if (section.project_id == project.id) {
                archived_revealer.reveal_child = project.sections_archived.size > 0;
            }
        });

        Services.Database.get_default ().section_unarchived.connect ((section) => {
            if (section.project_id == project.id) {
                archived_revealer.reveal_child = project.sections_archived.size > 0;
            }
        });
    }
    
    private void set_sort_func () {
        listbox.set_sort_func ((row1, row2) => {
            Objects.Section item1 = ((Dialogs.ProjectPicker.SectionPickerRow) row1).section;
            Objects.Section item2 = ((Dialogs.ProjectPicker.SectionPickerRow) row2).section;

            if (item1.id == "") {
                return 0;
            }

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
        var inbox_section = new Objects.Section ();
        inbox_section.project_id = project.id;
        inbox_section.name = _("(No Section)");

        add_section (new Dialogs.ProjectPicker.SectionPickerRow (inbox_section, "order"));
        foreach (Objects.Section section in project.sections) {
            if (!section.was_archived ()) {
                add_section (new Dialogs.ProjectPicker.SectionPickerRow (section, "order"));
            } else {
                archived_listbox.append (new Dialogs.ProjectPicker.SectionPickerRow (section, "menu"));
            }
        }
    }

    public void add_section (Dialogs.ProjectPicker.SectionPickerRow row) {
        row.update_section.connect (() => {
            update_section_section_order ();
            project.section_sort_order_changed ();
        });

        listbox.append (row);
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}
