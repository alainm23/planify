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

public class Views.List : Adw.Bin {
    public Objects.Project project { get; construct; }

    private Widgets.IconColorProject icon_project;
    private Gtk.Label title_label;
    private Gtk.Image due_image;
    private Gtk.Label due_label;
    private Gtk.Label days_left_label;
    private Gtk.Revealer due_revealer;
    private Widgets.PinnedItemsBox pinned_items_flowbox;

    private Gtk.ListBox listbox;
    private Layouts.SectionRow inbox_section;
    private Gtk.Stack listbox_placeholder_stack;
    private Widgets.ScrolledWindow scrolled_window;

    public bool has_children {
        get {
            return (Util.get_default ().get_children (listbox).length () - 1) > 0;
        }
    }

    public Gee.HashMap<string, Layouts.SectionRow> sections_map = new Gee.HashMap<string, Layouts.SectionRow> ();
    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();

    public List (Objects.Project project) {
        Object (
            project: project
        );
    }

    ~List () {
        debug ("Destroying - Views.List\n");
    }

    construct {
        icon_project = new Widgets.IconColorProject (24) {
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
            margin_start = 24,
        };

        title_box.append (icon_project);
        title_box.append (title_label);

        var description_widget = new Widgets.EditableTextView (_ ("Note")) {
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

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            selection_mode = Gtk.SelectionMode.NONE,
            hexpand = true,
            vexpand = true,
            css_classes = { "listbox-background" },
            margin_top = 12
        };

        var listbox_placeholder = new Adw.StatusPage () {
            icon_name = "check-round-outline-symbolic",
            title = _ ("Add Some Tasks"),
            description = _ ("Press 'a' to create a new task")
        };

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
            valign = Gtk.Align.BASELINE,
            margin_bottom = 24
        };

        content_box.append (title_box);

        if (!project.is_inbox_project) {
            content_box.append (description_widget);
            content_box.append (due_revealer);
        }

        content_box.append (filters);
        content_box.append (pinned_items_flowbox);
        content_box.append (listbox_placeholder_stack);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 864,
            tightening_threshold = 600,
            margin_bottom = 64,
            child = content_box
        };

        scrolled_window = new Widgets.ScrolledWindow (content_clamp);

        child = scrolled_window;
        update_request ();
        add_sections ();

        Timeout.add (listbox_placeholder_stack.transition_duration, () => {
            check_placeholder ();
            return GLib.Source.REMOVE;
        });

        signal_map[project.section_added.connect ((section) => {
            add_section (section);
        })] = project;

        signal_map[project.section_sort_order_changed.connect (() => {
            listbox.invalidate_sort ();
            listbox.invalidate_filter ();
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

            check_placeholder ();
        })] = Services.Store.instance ();

        signal_map[project.updated.connect (() => {
            update_request ();
        })] = project;

        signal_map[project.count_updated.connect (() => {
            check_placeholder ();
            icon_project.update_request ();
        })] = project;

        listbox.set_sort_func ((row1, row2) => {
            Layouts.SectionRow item1 = ((Layouts.SectionRow) row1);
            Layouts.SectionRow item2 = ((Layouts.SectionRow) row2);

            if (item1.is_inbox_section) {
                return 0;
            }

            return item1.section.section_order - item2.section.section_order;
        });

        listbox.set_filter_func ((child) => {
            Layouts.SectionRow item = ((Layouts.SectionRow) child);

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

            check_placeholder ();
        })] = Services.Store.instance ();

        signal_map[Services.Store.instance ().section_unarchived.connect ((section) => {
            if (project.id == section.project_id) {
                add_section (section);
            }
        })] = Services.Store.instance ();

        signal_map[project.show_completed_changed.connect (() => {
            check_placeholder ();
        })] = project;

        signal_map[scrolled_window.vadjustment.value_changed.connect (() => {
            project.handle_scroll_visibility_change (scrolled_window.vadjustment.value >= Constants.HEADERBAR_TITLE_SCROLL_THRESHOLD);
        })] = scrolled_window.vadjustment;

        signal_map[project.source.sync_finished.connect (() => {
            listbox.invalidate_sort ();
        })] = project.source;

        signal_map[Services.EventBus.get_default ().dim_content.connect ((active, focused_item_id) => {
            title_box.sensitive = !active;
            due_revealer.sensitive = !active;
            filters.sensitive = !active;
            pinned_items_flowbox.sensitive = !active;

            description_widget.sensitive = !active;
            if (active) {
                description_widget.add_css_class ("dimmed");
            } else {
                description_widget.remove_css_class ("dimmed");
            }
        })] = Services.EventBus.get_default ();

        destroy.connect (() => {
            clean_up ();
        });
    }

    private void check_placeholder () {
        int count = project.item_count + sections_map.size;

        if (project.show_completed) {
            count = count + project.items_checked.size;
        }

        listbox_placeholder_stack.visible_child_name = count > 0 ? "listbox" : "placeholder";
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
        if (!sections_map.has_key (section.id) && !section.was_archived ()) {
            sections_map[section.id] = new Layouts.SectionRow (section);
            listbox.append (sections_map[section.id]);
        }

        check_placeholder ();
    }

    public void prepare_new_item (string content = "") {
        var dialog = new Dialogs.QuickAdd ();
        dialog.for_base_object (project);
        dialog.update_content (content);
        dialog.present (Planify._instance.main_window);
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
        icon_project.update_request ();
        title_label.label = project.is_inbox_project ? _("Inbox") : project.name;
        update_duedate ();
    }

    private void update_duedate () {
        due_image.icon_name = "month-symbolic";
        due_image.css_classes = {};
        due_label.css_classes = {};
        due_revealer.reveal_child = false;

        if (project.due_date != "") {
            var datetime = Utils.Datetime.get_date_from_string (project.due_date);

            due_label.label = Utils.Datetime.get_relative_date_from_date (datetime);
            days_left_label.label = Utils.Datetime.days_left (datetime);

            if (Utils.Datetime.is_today (datetime)) {
                due_image.icon_name = "star-outline-thick-symbolic";
                due_image.add_css_class ("today-color");
                due_label.add_css_class ("today-color");
            } else if (Utils.Datetime.is_overdue (datetime)) {
                due_image.icon_name = "month-symbolic";
                due_image.add_css_class ("overdue-color");
                due_label.add_css_class ("overdue-color");
            } else {
                due_image.icon_name = "month-symbolic";
                due_image.css_classes = {};
                due_label.css_classes = {};
            }

            due_revealer.reveal_child = true;
        }
    }

    private Gtk.Revealer build_due_date_widget () {
        due_image = new Gtk.Image.from_icon_name ("month-symbolic");

        due_label = new Gtk.Label (_ ("Schedule")) {
            xalign = 0
        };

        days_left_label = new Gtk.Label (null) {
            xalign = 0,
            yalign = 0.5f
        };
        days_left_label.add_css_class ("dimmed");
        days_left_label.add_css_class ("caption");

        var due_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_start = 3
        };

        due_box.append (due_image);
        due_box.append (due_label);
        due_box.append (days_left_label);

        var due_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 12,
            margin_start = 24
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
            var dialog = new Dialogs.DatePicker (_ ("When?"));

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
        listbox.set_sort_func (null);
        listbox.set_filter_func (null);

        foreach (var row in Util.get_default ().get_children (listbox)) {
            ((Layouts.SectionRow) row).clean_up ();
        }

        if (inbox_section != null) {
            inbox_section.clean_up ();
        }

        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }
}
