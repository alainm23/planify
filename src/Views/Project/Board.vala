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

    private Gtk.Label description_label;
    private Widgets.HyperTextView description_textview;
    private Gtk.Popover description_popover = null;

    private Layouts.SectionBoard inbox_board;
    private Gtk.FlowBox flowbox;

    public Gee.HashMap <string, Layouts.SectionBoard> sections_map;

    public Board (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        description_label = new Gtk.Label (null) {
            wrap = true,
            xalign = 0,
            yalign = 0,
            margin_start = 26,
            margin_top = 6,
            margin_end = 12
        };
        
        var description_gesture_click = new Gtk.GestureClick ();
        description_label.add_controller (description_gesture_click);
        description_gesture_click.pressed.connect ((n_press, x, y) => {
            build_description_popover ();
        });

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

        content_box.append (description_label);
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
    }
    
    public void update_request () {
        description_label.label = project.description;
        if (description_label.label.length <= 0) {
            description_label.label = _("Note");
            description_label.add_css_class ("dim-label");
        }
    }

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

    private void build_description_popover () {
        if (description_popover != null) {
            description_popover.width_request = description_label.get_width ();
            description_popover.popup ();
            return;
        }

        description_textview = new Widgets.HyperTextView (_("Note")) {
            left_margin = 6,
            right_margin = 6,
            top_margin = 6,
            bottom_margin = 6,
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
            hexpand = true,
            vexpand = true
        };
        description_textview.set_text (project.description);
        description_textview.remove_css_class ("view");

        var description_card = new Adw.Bin () {
            child = description_textview,
            css_classes = { "card" }
        };

        description_popover = new Gtk.Popover () {
            has_arrow = false,
            child = description_card,
            position = Gtk.PositionType.BOTTOM,
            width_request = description_label.get_width (),
            height_request = 96
        };

        description_popover.set_parent (description_label);
        description_popover.popup ();

        description_textview.changed.connect (() => {
            project.description = description_textview.get_text ();
            project.update_local ();
        });
    }
}
