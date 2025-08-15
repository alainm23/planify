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

public class Dialogs.CompletedTasks : Adw.Dialog {
    public Objects.Project project { get; construct; }

    private Adw.NavigationView navigation_view;
    private Gtk.ListBox listbox;
    private Gtk.SearchEntry search_entry;
    private Widgets.FilterFlowBox filters_flowbox;
    private Gtk.Button remove_all;

    private string ? filter_section_id = null;

    public Gee.HashMap<string, Widgets.CompletedTaskRow> items_checked = new Gee.HashMap<string, Widgets.CompletedTaskRow> ();
    private Gee.HashMap<ulong, weak GLib.Object> signals_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public CompletedTasks (Objects.Project project) {
        Object (
            project: project,
            title: _ ("Completed Tasks"),
            content_width: 450,
            content_height: 500
        );
    }

    ~CompletedTasks () {
        print ("Destroying Dialogs.CompletedTasks\n");
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class ("flat");

        var filter_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            popover = build_view_setting_popover (),
            icon_name = "funnel-outline-symbolic",
            css_classes = { "flat" },
            tooltip_text = _ ("View Filter Menu")
        };

        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _ ("Search"),
            hexpand = true,
            css_classes = { "border-radius-9" }
        };

        var search_entry_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };
        search_entry_box.append (search_entry);
        search_entry_box.append (filter_button);

        filters_flowbox = new Widgets.FilterFlowBox () {
            valign = Gtk.Align.START,
            vexpand = false,
            vexpand_set = true,
        };
        filters_flowbox.flowbox.margin_start = 12;
        filters_flowbox.flowbox.margin_bottom = 12;

        listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = START,
            css_classes = { "listbox-background", "listbox-separator-6" },
            margin_start = 12,
            margin_end = 12
        };

        listbox.set_sort_func (sort_completed_function);
        listbox.set_header_func (header_completed_function);
        listbox.set_filter_func (filter_function);
        listbox.set_placeholder (new Gtk.Label (_ ("No completed tasks yet.")) {
            css_classes = { "dimmed" },
            margin_top = 48,
            margin_start = 24,
            margin_end = 24,
            wrap = true,
            justify = Gtk.Justification.CENTER
        });

        var listbox_scrolled = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = listbox
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.append (search_entry_box);
        content_box.append (filters_flowbox);
        content_box.append (listbox_scrolled);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 600,
            margin_bottom = 12,
            child = content_box
        };

        remove_all = new Gtk.Button.with_label (_ ("Delete All Completed Tasks")) {
            css_classes = { "flat" },
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (headerbar);
        toolbar_view.add_bottom_bar (remove_all);
        toolbar_view.content = content_clamp;

        var main_page = new Adw.NavigationPage (toolbar_view, _ ("Completed Tasks"));

        navigation_view = new Adw.NavigationView ();
        navigation_view.add (main_page);

        child = navigation_view;
        add_items ();
        Services.EventBus.get_default ().disconnect_typing_accel ();

        signals_map[filters_flowbox.filter_removed.connect (() => {
            filter_section_id = null;
            clear_items ();
            add_items ();
        })] = filters_flowbox;

        signals_map[search_entry.search_changed.connect (() => {
            if (search_entry.text == "") {
                clear_items ();
                add_items ();
            }

            filter_section_id = null;
            listbox.invalidate_filter ();
        })] = search_entry;

        signals_map[remove_all.clicked.connect (() => {
            var items = Services.Store.instance ().get_items_checked_by_project (project);

            var dialog = new Adw.AlertDialog (
                _ ("Delete All Completed Tasks"),
                _ ("This will delete %d completed tasks and their subtasks from project %s".printf (items.size, project.name))
            );

            dialog.body_use_markup = true;
            dialog.add_response ("cancel", _ ("Cancel"));
            dialog.add_response ("delete", _ ("Delete"));
            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.present (Planify._instance.main_window);

            dialog.response.connect ((response) => {
                if (response == "delete") {
                    delete_all_action (items);
                }
            });
        })] = remove_all;

        signals_map[listbox.row_activated.connect ((row) => {
            view_item (((Widgets.CompletedTaskRow) row).item);
        })] = listbox;

        signals_map[Services.EventBus.get_default ().checked_toggled.connect ((item, old_checked) => {
            if (item.project_id != project.id) {
                return;
            }

            if (!old_checked) {
                if (!items_checked.has_key (item.id)) {
                    items_checked[item.id] = new Widgets.CompletedTaskRow (item);
                    listbox.insert (items_checked[item.id], 0);
                }
            } else {
                if (items_checked.has_key (item.id)) {
                    items_checked[item.id].hide_destroy ();
                    items_checked.unset (item.id);
                }
            }
        })] = Services.EventBus.get_default ();

        signals_map[Services.Store.instance ().item_deleted.connect ((item) => {
            if (items_checked.has_key (item.id)) {
                items_checked[item.id].hide_destroy ();
                items_checked.unset (item.id);
            }
        })] = Services.Store.instance ();

        closed.connect (() => {
            listbox.set_sort_func (null);
            listbox.set_header_func (null);
            listbox.set_filter_func (null);

            foreach (var entry in signals_map.entries) {
                entry.value.disconnect (entry.key);
            }

            signals_map.clear ();

            Services.EventBus.get_default ().connect_typing_accel ();
        });
    }

    private void view_item (Objects.Item item) {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class ("flat");

        Widgets.ItemDetailCompleted item_detail = new Widgets.ItemDetailCompleted (item);
        signals_map[item_detail.view_item.connect (view_item)] = item_detail;

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (headerbar);
        toolbar_view.content = item_detail;

        var item_page = new Adw.NavigationPage (toolbar_view, _ ("Task Detail"));
        navigation_view.push (item_page);
    }

    private void add_items () {
        foreach (Objects.Item item in project.items_checked) {
            if (item.has_parent) {
                continue;
            }

            if (!items_checked.has_key (item.id)) {
                items_checked[item.id] = new Widgets.CompletedTaskRow (item);
                listbox.append (items_checked[item.id]);
            }
        }

        remove_all.sensitive = items_checked.size > 0;
    }

    private void header_completed_function (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow ? lbbefore) {
        var row = (Widgets.CompletedTaskRow) lbrow;
        if (row.item.completed_at == "") {
            return;
        }

        if (lbbefore != null) {
            var before = (Widgets.CompletedTaskRow) lbbefore;
            var comp_before = Utils.Datetime.get_date_only (Utils.Datetime.get_date_from_string (before.item.completed_at));
            var comp_after = Utils.Datetime.get_date_only (Utils.Datetime.get_date_from_string (row.item.completed_at));
            if (comp_before.compare (comp_after) == 0) {
                return;
            }
        }

        row.set_header (
            get_header_box (
                Utils.Datetime.get_relative_date_from_date (
                    Utils.Datetime.get_date_only (Utils.Datetime.get_date_from_string (row.item.completed_at))
                )
            )
        );
    }

    private int sort_completed_function (Gtk.ListBoxRow row1, Gtk.ListBoxRow ? row2) {
        var completed_a = Utils.Datetime.get_date_only (
            Utils.Datetime.get_date_from_string (((Widgets.CompletedTaskRow) row1).item.completed_at)
        );
        var completed_b = Utils.Datetime.get_date_only (
            Utils.Datetime.get_date_from_string (((Widgets.CompletedTaskRow) row2).item.completed_at)
        );
        return completed_b.compare (completed_a);
    }

    private bool filter_function (Gtk.ListBoxRow row) {
        Objects.Item item = ((Widgets.CompletedTaskRow) row).item;

        if (filter_section_id != null) {
            return item.section_id == filter_section_id;
        } else {
            return item.content.down ().contains (search_entry.text.down ());
        }
    }

    private Gtk.Widget get_header_box (string title) {
        var header_label = new Gtk.Label (title) {
            css_classes = { "caption", "font-bold" },
            halign = START
        };

        var header_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_start = 3,
            margin_bottom = 6
        };

        header_box.append (header_label);

        return header_box;
    }

    private void clear_items () {
        foreach (Widgets.CompletedTaskRow item in items_checked.values) {
            item.hide_destroy ();
        }

        items_checked.clear ();
    }

    private Gtk.Popover build_view_setting_popover () {
        var section_model = new Gee.ArrayList<string> ();
        foreach (Objects.Section section in project.sections) {
            section_model.add (section.name);
        }

        var section_item = new Widgets.ContextMenu.MenuPicker (_ ("Section"), "arrow3-right-symbolic", section_model);

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (new Gtk.Label (_ ("Filter By")) {
            css_classes = { "caption", "font-bold" },
            margin_start = 6,
            margin_top = 6,
            margin_bottom = 6,
            halign = Gtk.Align.START
        });
        menu_box.append (section_item);

        var popover = new Gtk.Popover () {
            has_arrow = false,
            position = Gtk.PositionType.BOTTOM,
            child = menu_box,
            width_request = 250
        };

        section_item.notify["selected"].connect (() => {
            Objects.Section section = project.sections[section_item.selected];
            add_update_filter (section);
        });

        return popover;
    }

    public void add_update_filter (Objects.Section section) {
        Objects.Filters.FilterItem filter = filters_flowbox.get_filter (FilterItemType.SECTION.to_string ());
        bool insert = false;

        if (filter == null) {
            filter = new Objects.Filters.FilterItem ();
            filter.filter_type = FilterItemType.SECTION;
            insert = true;
        }

        filter.name = section.name;
        filter.value = section.id;

        if (insert) {
            filters_flowbox.add_filter (filter);
        } else {
            filters_flowbox.update_filter (filter);
        }

        filter_section_id = section.id;
        listbox.invalidate_filter ();
    }

    public void delete_all_action (Gee.ArrayList<Objects.Item> items) {
        foreach (Objects.Item item in items) {
            item.delete_item ();
        }
    }
}
