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

    private Widgets.IconColorProject icon_project;
    private Gtk.Label title_label;
    private Gtk.Image due_image;
    private Gtk.Label due_label;
    private Gtk.Label days_left_label;
    private Gtk.Revealer due_revealer;

    private Layouts.SectionBoard inbox_board;
    private Gtk.FlowBox flowbox;
    private Widgets.PinnedItemsBox pinned_items_flowbox;

    public Gee.HashMap<string, Layouts.SectionBoard> sections_map = new Gee.HashMap<string, Layouts.SectionBoard> ();
    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public Board (Objects.Project project) {
        Object (
            project: project
        );
    }

    ~Board () {
        debug ("Destroying - Views.Board\n");
    }

    construct {
        icon_project = new Widgets.IconColorProject (22) {
            project = project
        };
        icon_project.add_css_class ("title-2");
        icon_project.inbox_icon.add_css_class ("view-icon");
        Util.get_default ().set_widget_color (Objects.Filters.Inbox.get_default ().color, icon_project.inbox_icon);
        signal_map[Services.EventBus.get_default ().theme_changed.connect (() => {
            Util.get_default ().set_widget_color (Objects.Filters.Inbox.get_default ().color, icon_project.inbox_icon);
        })] = Services.EventBus.get_default ();

        title_label = new Gtk.Label (null) {
            css_classes = { "font-bold", "title-2" },
            ellipsize = Pango.EllipsizeMode.END,
            halign = START
        };

        var title_box = new Gtk.Box (HORIZONTAL, 6) {
            valign = CENTER,
            margin_start = 22,
        };

        title_box.append (icon_project);
        title_box.append (title_label);

        var description_widget = new Widgets.EditableTextView (_("Note")) {
            text = project.description,
            margin_top = 12,
            margin_start = 24,
            margin_end = 24
        };

        due_revealer = build_due_date_widget ();

        var filters = new Widgets.FilterFlowBox () {
            valign = Gtk.Align.START,
            vexpand = false,
            vexpand_set = true,
            base_object = project
        };

        filters.flowbox.margin_start = 24;
        filters.flowbox.margin_top = 12;
        filters.flowbox.margin_end = 12;
        filters.flowbox.margin_bottom = 3;

        pinned_items_flowbox = new Widgets.PinnedItemsBox (project);

        flowbox = new Gtk.FlowBox () {
            vexpand = true,
            max_children_per_line = 1,
            orientation = Gtk.Orientation.VERTICAL,
            halign = Gtk.Align.START,
            selection_mode = NONE
        };

        var flowbox_grid = new Adw.Bin () {
            vexpand = true,
            margin_top = 12,
            margin_start = 19,
            margin_end = 19,
            halign = Gtk.Align.START,
            child = flowbox
        };

        var flowbox_scrolled = new Widgets.ScrolledWindow (flowbox_grid, Gtk.Orientation.HORIZONTAL);
        flowbox_scrolled.margin = 100;

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content_box.append (title_box);

        if (!project.is_inbox_project) {
            content_box.append (description_widget);
            content_box.append (due_revealer);
        }

        content_box.append (filters);
        content_box.append (pinned_items_flowbox);
        content_box.append (flowbox_scrolled);

        child = content_box;
        update_request ();
        add_sections ();

        signal_map[project.section_added.connect ((section) => {
            add_section (section);
        })] = project;

        signal_map[project.section_sort_order_changed.connect (() => {
            flowbox.invalidate_sort ();
            flowbox.invalidate_filter ();
        })] = project;

        signal_map[Services.Store.instance ().section_moved.connect ((section, old_project_id) => {
            if (project.id == old_project_id && sections_map.has_key (section.id)) {
                sections_map[section.id].hide_destroy ();
                sections_map.unset (section.id);
            }

            if (project.id == section.project_id &&
                !sections_map.has_key (section.id)) {
                add_section (section);
            }
        })] = Services.Store.instance ();

        signal_map[Services.Store.instance ().section_deleted.connect ((section) => {
            if (sections_map.has_key (section.id)) {
                sections_map[section.id].hide_destroy ();
                sections_map.unset (section.id);
            }
        })] = Services.Store.instance ();

        signal_map[project.updated.connect (() => {
            update_request ();
        })] = project;

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

        signal_map[description_widget.changed.connect (() => {
            project.description = description_widget.text;
            project.update_local ();
        })] = description_widget;

        signal_map[Services.Store.instance ().section_archived.connect ((section) => {
            if (sections_map.has_key (section.id)) {
                sections_map[section.id].hide_destroy ();
                sections_map.unset (section.id);
            }
        })] = Services.Store.instance ();

        signal_map[Services.Store.instance ().section_unarchived.connect ((section) => {
            if (project.id == section.project_id) {
                add_section (section);
            }
        })] = Services.Store.instance ();

        signal_map[project.count_updated.connect (() => {
            icon_project.update_request ();
        })] = project;

        signal_map[project.source.sync_finished.connect (() => {
            flowbox.invalidate_sort ();
        })] = project.source;
    }

    public void update_request () {
        icon_project.update_request ();
        title_label.label = project.is_inbox_project ? _("Inbox") : project.name;
        update_duedate ();
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
        if (!sections_map.has_key (section.id) && !section.was_archived ()) {
            sections_map[section.id] = new Layouts.SectionBoard (section);
            flowbox.append (sections_map[section.id]);
        }
    }

    public void prepare_new_item (string content = "") {
        inbox_board.prepare_new_item (content);
    }

    private void update_duedate () {
        due_image.icon_name = "delay-long-small-symbolic";
        due_image.css_classes = {};
        due_label.css_classes = {};
        due_revealer.reveal_child = false;

        if (project.due_date != "") {
            var datetime = Utils.Datetime.get_date_from_string (project.due_date);

            due_label.label = Utils.Datetime.get_short_date_format_from_date (datetime);
            days_left_label.label = Utils.Datetime.get_relative_time_from_date (datetime);

            if (Utils.Datetime.is_today (datetime) || Utils.Datetime.is_overdue (datetime)) {
                due_image.add_css_class ("error");
                due_label.add_css_class ("error");
            } else {
                due_image.css_classes = {};
                due_label.css_classes = {};
            }

            due_revealer.reveal_child = true;
        }
    }

    private Gtk.Revealer build_due_date_widget () {
        due_image = new Gtk.Image.from_icon_name ("month-symbolic");

        due_label = new Gtk.Label (_("Schedule")) {
            xalign = 0,
            use_markup = true
        };

        days_left_label = new Gtk.Label (null) {
            xalign = 0,
            yalign = 0.5f
        };
        days_left_label.add_css_class ("dimmed");

        var due_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_start = 3,
            margin_top = 3,
            margin_bottom = 3
        };

        due_box.append (due_image);
        due_box.append (due_label);
        due_box.append (days_left_label);

        var due_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 12,
            margin_start = 24,
            margin_end = 24
        };
        due_content.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        due_content.append (due_box);
        due_content.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        var due_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = due_content
        };

        var gesture = new Gtk.GestureClick ();
        due_box.add_controller (gesture);
        signal_map[gesture.pressed.connect ((n_press, x, y) => {
            var dialog = new Dialogs.DatePicker (_("When?"));

            if (project.due_date != "") {
                dialog.datetime = Utils.Datetime.get_date_from_string (project.due_date);
                dialog.clear = true;
            }

            signal_map[dialog.date_changed.connect (() => {
                if (dialog.datetime == null) {
                    project.due_date = "";
                } else {
                    project.due_date = dialog.datetime.to_string ();
                }

                project.update_local ();
            })] = dialog;

            dialog.present (Planify._instance.main_window);
        })] = gesture;

        return due_revealer;
    }

    public void clean_up () {
        flowbox.set_sort_func (null);
        flowbox.set_filter_func (null);

        foreach (unowned Gtk.Widget child in Util.get_default ().get_flowbox_children (flowbox)) {
            ((Layouts.SectionBoard) child).clean_up ();
        }

        if (inbox_board != null) {
            inbox_board.clean_up ();
        }

        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }

    public override void dispose () {
        clean_up ();
        base.dispose ();
    }
}
