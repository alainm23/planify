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

public class Views.Scheduled.Scheduled : Adw.Bin {
    private Gtk.Revealer indicator_revealer;
    Widgets.ContextMenu.MenuCheckPicker priority_filter;
    private Gtk.ListBox listbox;
    private Gtk.ScrolledWindow scrolled_window;

    public Gee.HashMap<string, Layouts.ItemRow> items;

    construct {
        items = new Gee.HashMap<string, Layouts.ItemRow> ();

        var indicator_grid = new Gtk.Grid () {
            width_request = 9,
            height_request = 9,
            margin_top = 6,
            margin_end = 6,
            css_classes = { "indicator" }
        };

        indicator_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = indicator_grid,
            halign = END,
            valign = START,
            sensitive = false,
        };

        var view_setting_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            margin_end = 12,
            popover = build_view_setting_popover (),
            icon_name = "view-sort-descending-rtl-symbolic",
            css_classes = { "flat" },
            tooltip_text = _("View Option Menu")
        };

        var view_setting_overlay = new Gtk.Overlay ();
        view_setting_overlay.child = view_setting_button;
        view_setting_overlay.add_overlay (indicator_revealer);

        var headerbar = new Layouts.HeaderBar ();
        headerbar.title = _("Scheduled");

        headerbar.pack_end (view_setting_overlay);

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.NONE,
            hexpand = true
        };

        listbox.add_css_class ("listbox-background");

        var listbox_content = new Adw.Bin () {
            margin_top = 12,
            child = listbox
        };

        var filters = new Widgets.FilterFlowBox () {
            valign = Gtk.Align.START,
            vexpand = false,
            vexpand_set = true,
            base_object = Objects.Filters.Scheduled.get_default ()
        };

        filters.flowbox.margin_start = 24;
        filters.flowbox.margin_top = 12;
        filters.flowbox.margin_end = 12;
        filters.flowbox.margin_bottom = 3;

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content.append (filters);
        content.append (listbox_content);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 1024,
            tightening_threshold = 800,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 64,
        };

        content_clamp.child = content;

        scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        scrolled_window.child = content_clamp;

        var magic_button = new Widgets.MagicButton ();

        var content_overlay = new Gtk.Overlay () {
            hexpand = true,
            vexpand = true
        };

        content_overlay.child = scrolled_window;
        content_overlay.add_overlay (magic_button);

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (headerbar);
        toolbar_view.content = content_overlay;

        child = toolbar_view;
        add_days ();

        magic_button.clicked.connect (() => {
            prepare_new_item ();
        });
    }

    private void add_days () {
        var date = new GLib.DateTime.now_local ();
        var month_days = Utils.Datetime.get_days_of_month (date.get_month (), date.get_year ());
        var remaining_days = month_days - date.add_days (7).get_day_of_month ();
        var days_to_iterate = 7;

        if (remaining_days >= 1 && remaining_days <= 3) {
            days_to_iterate += remaining_days;
        }

        for (int i = 0; i < days_to_iterate; i++) {
            date = date.add_days (1);

            var row = new Views.Scheduled.ScheduledDay (date);
            listbox.append (row);
        }

        month_days = Utils.Datetime.get_days_of_month (date.get_month (), date.get_year ());
        remaining_days = month_days - date.get_day_of_month ();

        if (remaining_days > 3) {
            var row = new Views.Scheduled.ScheduledRange (date.add_days (1), date.add_days (remaining_days));
            listbox.append (row);
        }

        for (int i = 0; i < 4; i++) {
            date = date.add_months (1);
            var row = new Views.Scheduled.ScheduledMonth (date);
            listbox.append (row);
        }
    }

    public void prepare_new_item (string content = "") {
        var inbox_project = Services.Store.instance ().get_project (
            Services.Settings.get_default ().settings.get_string ("local-inbox-project-id")
        );

        var dialog = new Dialogs.QuickAdd ();
        dialog.update_content (content);
        dialog.set_project (inbox_project);
        dialog.set_due (Utils.Datetime.get_date_only (new GLib.DateTime.now_local ().add_days (1)));
        dialog.present (Planify._instance.main_window);
    }

    private Gtk.Popover build_view_setting_popover () {
        var order_by_model = new Gee.ArrayList<string> ();
        order_by_model.add (_("Due Date"));
        order_by_model.add (_("Alphabetically"));
        order_by_model.add (_("Date Added"));
        order_by_model.add (_("Priority"));

        var order_by_item = new Widgets.ContextMenu.MenuPicker (_("Order by"), "view-list-ordered-symbolic", order_by_model);
        order_by_item.selected = Services.Settings.get_default ().settings.get_int ("scheduled-sort-order");

        // Filters
        var priority_items = new Gee.ArrayList<Objects.Filters.FilterItem> ();

        priority_items.add (new Objects.Filters.FilterItem () {
            filter_type = FilterItemType.PRIORITY,
            name = _("P1"),
            value = Constants.PRIORITY_1.to_string ()
        });

        priority_items.add (new Objects.Filters.FilterItem () {
            filter_type = FilterItemType.PRIORITY,
            name = _("P2"),
            value = Constants.PRIORITY_2.to_string ()
        });

        priority_items.add (new Objects.Filters.FilterItem () {
            filter_type = FilterItemType.PRIORITY,
            name = _("P3"),
            value = Constants.PRIORITY_3.to_string ()
        });

        priority_items.add (new Objects.Filters.FilterItem () {
            filter_type = FilterItemType.PRIORITY,
            name = _("P4"),
            value = Constants.PRIORITY_4.to_string ()
        });

        priority_filter = new Widgets.ContextMenu.MenuCheckPicker (_("Priority"), "flag-outline-thick-symbolic");
        priority_filter.set_items (priority_items);

        var labels_filter = new Widgets.ContextMenu.MenuItem (_("Filter by Labels"), "tag-outline-symbolic") {
            arrow = true
        };

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (order_by_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (new Gtk.Label (_("Filter By")) {
            css_classes = { "heading", "h4" },
            margin_start = 6,
            margin_top = 6,
            margin_bottom = 6,
            halign = Gtk.Align.START
        });
        menu_box.append (priority_filter);
        menu_box.append (labels_filter);

        var popover = new Gtk.Popover () {
            has_arrow = false,
            position = Gtk.PositionType.BOTTOM,
            child = menu_box,
            width_request = 250
        };

        order_by_item.notify["selected"].connect (() => {
            Services.Settings.get_default ().settings.set_int ("scheduled-sort-order", order_by_item.selected);
        });

        priority_filter.filter_change.connect ((filter, active) => {
            if (active) {
                Objects.Filters.Scheduled.get_default ().add_filter (filter);
            } else {
                Objects.Filters.Scheduled.get_default ().remove_filter (filter);
            }
        });

        labels_filter.activate_item.connect (() => {
            Gee.ArrayList<Objects.Label> _labels = new Gee.ArrayList<Objects.Label> ();
            foreach (Objects.Filters.FilterItem filter in Objects.Filters.Scheduled.get_default ().filters.values) {
                if (filter.filter_type == FilterItemType.LABEL) {
                    _labels.add (Services.Store.instance ().get_label (filter.value));
                }
            }

            var dialog = new Dialogs.LabelPicker ();
            // TODO: dialog.add_labels (SourceType.ALL);
            dialog.labels = _labels;
            dialog.present (Planify._instance.main_window);

            dialog.labels_changed.connect ((labels) => {
                foreach (Objects.Label label in labels.values) {
                    var filter = new Objects.Filters.FilterItem ();
                    filter.filter_type = FilterItemType.LABEL;
                    filter.name = label.name;
                    filter.value = label.id;

                    Objects.Filters.Scheduled.get_default ().add_filter (filter);
                }

                Gee.ArrayList<Objects.Filters.FilterItem> to_remove = new Gee.ArrayList<Objects.Filters.FilterItem> ();
                foreach (Objects.Filters.FilterItem filter in Objects.Filters.Scheduled.get_default ().filters.values) {
                    if (filter.filter_type == FilterItemType.LABEL) {
                        if (!labels.has_key (filter.value)) {
                            to_remove.add (filter);
                        }
                    }
                }

                foreach (Objects.Filters.FilterItem filter in to_remove) {
                    Objects.Filters.Scheduled.get_default ().remove_filter (filter);
                }
            });
        });

        return popover;
    }
}
