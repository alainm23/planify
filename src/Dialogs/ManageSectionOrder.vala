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

public class Dialogs.ManageSectionOrder : Adw.Dialog {
    public Objects.Project project { get; construct; }

    private Gtk.ListBox listbox;
    private Gtk.ListBox archived_listbox;
    private Widgets.ScrolledWindow scrolled_window;

    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();

    public ManageSectionOrder (Objects.Project project) {
        Object (
            project: project,
            title: _("Manage Sections"),
            content_width: 320,
            content_height: 450
        );
    }

    ~ManageSectionOrder () {
        debug ("Destroying - Dialogs.ManageSectionOrder\n");
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class ("flat");

        listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = START,
            css_classes = { "listbox-background" }
        };

        var label = new Gtk.Label (_("You can sort your sections by dragging and dropping")) {
            css_classes = { "caption", "dimmed" },
            halign = START,
            margin_start = 16,
            margin_end = 16,
            margin_top = 3,
            wrap = true,
            wrap_mode = CHAR,
            natural_wrap_mode = NONE,
            xalign = 0
        };

        var listbox_card = new Adw.Bin () {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 6,
            margin_top = 1,
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

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_bottom = 6,
        };
        content_box.append (listbox_card);
        content_box.append (label);
        content_box.append (archived_revealer);

        scrolled_window = new Widgets.ScrolledWindow (content_box);

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (headerbar);
        toolbar_view.content = scrolled_window;

        child = toolbar_view;
        add_sections ();
        Services.EventBus.get_default ().disconnect_typing_accel ();

        Timeout.add (225, () => {
            set_sort_func ();
            return GLib.Source.REMOVE;
        });

        signal_map[Services.Store.instance ().section_deleted.connect ((section) => {
            if (section.project_id == project.id) {
                archived_revealer.reveal_child = project.sections_archived.size > 0;
            }
        })] = Services.Store.instance ();

        signal_map[Services.Store.instance ().section_unarchived.connect ((section) => {
            if (section.project_id == project.id) {
                archived_revealer.reveal_child = project.sections_archived.size > 0;
            }
        })] = Services.Store.instance ();

        closed.connect (() => {
            clean_up ();
            Services.EventBus.get_default ().connect_typing_accel ();
        });
    }

    private void set_sort_func () {
        listbox.set_sort_func ((row1, row2) => {
            Objects.Section item1 = ((Widgets.SectionItemRow) row1).section;
            Objects.Section item2 = ((Widgets.SectionItemRow) row2).section;

            if (item1.id == "") {
                return 0;
            }

            return item1.section_order - item2.section_order;
        });

        listbox.set_sort_func (null);
    }

    private void update_section_section_order () {
        unowned Widgets.SectionItemRow ? section_row = null;
        var row_index = 0;

        do {
            section_row = (Widgets.SectionItemRow) listbox.get_row_at_index (row_index);

            if (section_row != null) {
                section_row.section.section_order = row_index;
                Services.Store.instance ().update_section (section_row.section);
            }

            row_index++;
        } while (section_row != null);
    }

    public void add_sections () {
        var inbox_section = new Objects.Section ();
        inbox_section.project_id = project.id;
        inbox_section.name = _("(No Section)");

        add_section (new Widgets.SectionItemRow (inbox_section, "order"));
        foreach (Objects.Section section in project.sections) {
            if (section.was_archived ()) {
                archived_listbox.append (new Widgets.SectionItemRow (section, "menu"));
            } else {
                add_section (new Widgets.SectionItemRow (section, "order"));
            }
        }
    }

    public void add_section (Widgets.SectionItemRow row) {
        signal_map[row.update_section.connect (() => {
            update_section_section_order ();
            project.section_sort_order_changed ();
        })] = row;

        listbox.append (row);
    }

    public void clean_up () {
        listbox.set_sort_func (null);

        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox)) {
            ((Widgets.SectionItemRow) child).clean_up ();
        }

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (archived_listbox)) {
            ((Widgets.SectionItemRow) child).clean_up ();
        }
    }
}
