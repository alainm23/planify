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

public class Views.Board : Adw.Bin {
    public Objects.Project project { get; construct; }

    private Layouts.SectionBoard inbox_board;
    private Gtk.FlowBox flowbox;

    public Gee.HashMap <string, Layouts.SectionBoard> sections_map;

    public Board (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        var description_widget = new Widgets.EditableTextView (_("Note")) {
            text = project.description,
            margin_top = 6,
            margin_start = 27,
            margin_end = 12
        };

        var filters = new Widgets.FilterFlowBox (project) {
            valign = Gtk.Align.START,
            vexpand = false,
            vexpand_set = true
        };

        filters.flowbox.margin_start = 24;
        filters.flowbox.margin_top = 12;
        filters.flowbox.margin_end = 12;
        filters.flowbox.margin_bottom = 3;

        sections_map = new Gee.HashMap <string, Layouts.SectionBoard> ();

        flowbox = new Gtk.FlowBox () {
            vexpand = true,
            max_children_per_line = 1,
            orientation = Gtk.Orientation.VERTICAL,
            halign = Gtk.Align.START
        };

        flowbox.set_sort_func ((child1, child2) => {
            Layouts.SectionBoard item1 = ((Layouts.SectionBoard) child1);
            Layouts.SectionBoard item2 = ((Layouts.SectionBoard) child2);

            if (item1.is_inbox_section) {
                return 0;
            }

            return item1.section.section_order - item2.section.section_order;
        });

        flowbox.set_filter_func ((child) => {
            Layouts.SectionBoard item = ((Layouts.SectionBoard) child);

            if (item.is_inbox_section) {
                return !project.inbox_section_hidded;
            }

            return !item.section.hidded;
        });

        var flowbox_grid = new Adw.Bin () {
            vexpand = true,
            margin_top = 12,
            margin_start = 16,
            margin_end = 16,
            halign = Gtk.Align.START,
            child = flowbox
        };

        var flowbox_scrolled = new Widgets.ScrolledWindow (flowbox_grid, Gtk.Orientation.HORIZONTAL);
        flowbox_scrolled.margin = 100;

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			hexpand = true,
			vexpand = true
		};

        if (!project.is_inbox_project) {
            content_box.append (description_widget);
        }
        content_box.append (filters);
		content_box.append (flowbox_scrolled);

        child = content_box;
        update_request ();
        add_sections ();

        project.section_added.connect ((section) => {
            add_section (section);

            if (section.activate_name_editable) {
                Timeout.add (175, () => {
                    flowbox_scrolled.hadjustment.set_value (
                        flowbox_scrolled.hadjustment.get_upper () - flowbox_scrolled.hadjustment.get_page_size ()
                    );
                    return GLib.Source.REMOVE;
                });
            }
        });

        project.section_sort_order_changed.connect (() => {
            flowbox.invalidate_sort ();
            flowbox.invalidate_filter ();
        });

        Services.Database.get_default ().section_moved.connect ((section, old_project_id) => {
            if (project.id == old_project_id && sections_map.has_key (section.id_string)) {
                    sections_map [section.id_string].hide_destroy ();
                    sections_map.unset (section.id_string);
            }

            if (project.id == section.project_id &&
                !sections_map.has_key (section.id_string)) {
                    add_section (section);
            }
        });

        Services.Database.get_default ().section_deleted.connect ((section) => {
            if (sections_map.has_key (section.id_string)) {
                sections_map [section.id_string].hide_destroy ();
                sections_map.unset (section.id_string);
            }
        });

        project.updated.connect (() => {
            update_request ();
        });

        description_widget.changed.connect (() => {
            project.description = description_widget.text;
            project.update_local ();
        });
    }
    
    public void update_request () {}

    public void add_sections () {
        add_inbox_section ();
        foreach (Objects.Section section in project.sections) {
            add_section (section);
        }
    }

    private void add_inbox_section () {
        inbox_board = new Layouts.SectionBoard.for_project (project);
        flowbox.append (inbox_board);
    }

    private void add_section (Objects.Section section) {
        if (!sections_map.has_key (section.id)) {
            sections_map[section.id] = new Layouts.SectionBoard (section);
            flowbox.append (sections_map[section.id]);
        }
    }

    public void prepare_new_item (string content = "") {
        inbox_board.prepare_new_item (content);
    }
}
