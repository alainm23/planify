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

public class Views.List : Gtk.Grid {
    public Objects.Project project { get; construct; }

    private Gtk.Label description_label;
    private Widgets.HyperTextView description_textview;
    private Gtk.Popover description_popover = null;

    private Widgets.DynamicIcon due_image;
    private Gtk.Label due_label;
    private Gtk.Revealer due_revealer;

    private Gtk.ListBox listbox;
    private Layouts.SectionRow inbox_section;
    private Gtk.Stack listbox_placeholder_stack;
    private Widgets.ScrolledWindow scrolled_window;
    
    public bool has_children {
        get {
            return (Util.get_default ().get_children (listbox).length () - 1) > 0;
        }
    }

    public Gee.HashMap <string, Layouts.SectionRow> sections_map;

    public List (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        sections_map = new Gee.HashMap <string, Layouts.SectionRow> ();

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

        due_revealer = build_due_date_widget ();

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            selection_mode = Gtk.SelectionMode.NONE,
            hexpand = true,
            vexpand = true
        };

        listbox.add_css_class ("listbox-background");

        listbox.set_sort_func ((row1, row2) => {
            Layouts.SectionRow item1 = ((Layouts.SectionRow) row1);
            Layouts.SectionRow item2 = ((Layouts.SectionRow) row2);

            if (item1.is_inbox_section) {
                return 0;
            }

            return item1.section.section_order - item2.section.section_order;
        });

        listbox.set_filter_func ((child) => {
            Layouts.SectionBoard item = ((Layouts.SectionBoard) child);

            if (item.is_inbox_section) {
                return true;
            }

            return !item.section.hidded;
        });

        var listbox_placeholder = new Adw.StatusPage ();
        listbox_placeholder.title = _("No tasks found");
        listbox_placeholder.description = _("Press 'a' or tap the plus button to create a new to-do");

        listbox_placeholder_stack = new Gtk.Stack () {
            vexpand = true,
            hexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        listbox_placeholder_stack.add_named (listbox, "listbox");
        listbox_placeholder_stack.add_named (listbox_placeholder, "placeholder");

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true,
            margin_bottom = 24
        };

        if (!project.is_inbox_project) {
            content_box.append (due_revealer);
            content_box.append (description_label);
        }

        content_box.append (listbox_placeholder_stack);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 1024,
            tightening_threshold = 800,
            margin_start = 24,
            margin_end = 48,
            margin_bottom = 64,
            child = content_box
        };

        scrolled_window = new Widgets.ScrolledWindow (content_clamp);

        attach (scrolled_window, 0, 0);
        update_request ();
        add_sections ();

        Timeout.add (listbox_placeholder_stack.transition_duration, () => {
            check_placeholder ();
            return GLib.Source.REMOVE;
        });

        project.section_added.connect ((section) => {
            add_section (section);
            if (section.activate_name_editable) {
                Timeout.add (listbox_placeholder_stack.transition_duration, () => {
                    scrolled_window.vadjustment.set_value (
                        scrolled_window.vadjustment.get_upper () - scrolled_window.vadjustment.get_page_size ()
                    );
                    return GLib.Source.REMOVE;
                });
            }
        });

        project.section_sort_order_changed.connect (() => {
            listbox.invalidate_sort ();
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

            check_placeholder ();
        });

        Services.EventBus.get_default ().paste_action.connect ((project_id, content) => {
            if (project.id == project_id) {
                prepare_new_item (content);
            }
        });

        project.updated.connect (() => {
            update_request ();
        });

        project.project_count_updated.connect (() => {
            check_placeholder ();
        });

        Services.EventBus.get_default ().new_item_deleted.connect ((project_id) => {
            if (project.id == project_id) {
                check_placeholder ();
            }
        });

        project.show_completed_changed.connect (() => {
            check_placeholder ();
        });
    }

    private void check_placeholder () {
        int count = project.project_count + sections_map.size;
        if (project.show_completed) {
            count = count + project.items_checked.size;
        }

        if (count > 0) {
            listbox_placeholder_stack.visible_child_name = "listbox";
        } else {
            listbox_placeholder_stack.visible_child_name = "placeholder";
        }
    }

    private void add_sections () {
        add_inbox_section ();
        foreach (Objects.Section section in project.sections) {
            add_section (section);
        }
    }

    private void add_inbox_section () {
        inbox_section = new Layouts.SectionRow.for_project (project);
        listbox.append (inbox_section);
    }

    private void add_section (Objects.Section section) {
        if (!sections_map.has_key (section.id)) {
            sections_map [section.id] = new Layouts.SectionRow (section);
            listbox.append (sections_map [section.id]);
        }

        check_placeholder ();
    }

    public void prepare_new_item (string content = "") {
        var dialog = new Dialogs.QuickAdd ();
        dialog.for_base_object (project);
        dialog.update_content (content);
        dialog.show ();
    }

    public bool validate_children () {
        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox)) {
            if (((Layouts.SectionRow) child).has_children) {
                return true;
            }
        }

        return has_children;
    }

    public void update_request () {
        description_label.label = project.description;
        if (description_label.label.length <= 0) {
            description_label.label = _("Note");
            description_label.add_css_class ("dim-label");
        }

        update_duedate ();
    }

    private void update_duedate () {
        due_image.update_icon_name ("planner-calendar");
        due_revealer.reveal_child = false;

        if (project.due_date != "") {
            var datetime = Util.get_default ().get_date_from_string (project.due_date);
            due_label.label = Util.get_default ().get_relative_date_from_date (datetime);

            if (Util.get_default ().is_today (datetime)) {
                due_image.update_icon_name ("planner-today");
            } else {
                due_image.update_icon_name ("planner-calendar");
            }

            due_revealer.reveal_child = true;
        }
    }

    private Gtk.Revealer build_due_date_widget () {
        due_image = new Widgets.DynamicIcon ();
        due_image.update_icon_name ("planner-calendar");
        due_image.size = 16;        

        due_label = new Gtk.Label (_("Schedule")) {
            xalign = 0
        };

        var due_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3) {
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 3
        };
        due_box.append (due_image);
        due_box.append (due_label);

        var due_date_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 21
        };
        
        due_date_box.append (due_box);

        var due_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        due_revealer.child = due_date_box;

        var gesture = new Gtk.GestureClick ();
        gesture.set_button (1);
        due_date_box.add_controller (gesture);

        gesture.pressed.connect ((n_press, x, y) => {
            var dialog = new Dialogs.DatePicker (_("When?"));

            if (project.due_date != "") {
                dialog.datetime = Util.get_default ().get_date_from_string (project.due_date);
                dialog.clear = true;
            }

            dialog.show ();

            dialog.date_changed.connect (() => {
                if (dialog.datetime == null) {
                    project.due_date = "";
                } else {
                    project.due_date = dialog.datetime.to_string ();
                }
                
                project.update_local ();
            });
        });

        return due_revealer;
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
