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

public class Dialogs.Preferences.Pages.Sidebar : Adw.Bin {
    public signal void pop_subpage ();
    public signal void popup_toast (string message);

    ~Sidebar () {
        print ("Destroying Dialogs.Preferences.Pages.Sidebar\n");
    }

    construct {
        var settings_header = new Dialogs.Preferences.SettingsHeader (_("Sidebar"));

        var views_group = new Layouts.HeaderItem (_("Show in Sidebar")) {
            card = true,
            reveal = true,
            margin_top = 12
        };

        var inbox_row = new Widgets.SidebarRow (FilterType.INBOX, _("Inbox"), "mailbox-symbolic");
        var today_row = new Widgets.SidebarRow (FilterType.TODAY, _("Today"), "star-outline-thick-symbolic");
        var scheduled_row = new Widgets.SidebarRow (FilterType.SCHEDULED, _("Scheduled"), "month-symbolic");
        var pinboard_row = new Widgets.SidebarRow (FilterType.PINBOARD, _("Pinboard"), "pin-symbolic");
        var labels_row = new Widgets.SidebarRow (FilterType.LABELS, _("Labels"), "tag-outline-symbolic");
        var completed_row = new Widgets.SidebarRow (FilterType.COMPLETED, _("Completed"), "check-round-outline-symbolic");

        views_group.add_child (inbox_row);
        views_group.add_child (today_row);
        views_group.add_child (scheduled_row);
        views_group.add_child (pinboard_row);
        views_group.add_child (labels_row);
        views_group.add_child (completed_row);

        var show_count_row = new Adw.SwitchRow ();
        show_count_row.title = _("Show Task Count");

        var sidebar_width_row = new Adw.SpinRow.with_range (300, 400, 1) {
            valign = Gtk.Align.CENTER,
            title = _("Sidebar Width"),
            value = Services.Settings.get_default ().settings.get_int ("pane-position")
        };

        var count_group = new Adw.PreferencesGroup () {
            margin_start = 3,
            margin_end = 3,
            margin_top = 12
        };

        count_group.add (show_count_row);
        count_group.add (sidebar_width_row);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.append (count_group);
        content_box.append (views_group);
        content_box.append (new Gtk.Label (_("You can sort your views by dragging and dropping")) {
            css_classes = { "caption", "dim-label" },
            halign = START,
            margin_start = 12,
            margin_top = 3
        });

        var content_clamp = new Adw.Clamp () {
            maximum_size = 600,
            margin_start = 24,
            margin_end = 24,
            margin_bottom = 24,
            child = content_box
        };

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = content_clamp
        };

        var toolbar_view = new Adw.ToolbarView () {
            content = scrolled_window
        };
        toolbar_view.add_top_bar (settings_header);

        child = toolbar_view;
        Services.Settings.get_default ().settings.bind ("show-tasks-count", show_count_row, "active", GLib.SettingsBindFlags.DEFAULT);

        views_group.set_sort_func ((child1, child2) => {
            Widgets.SidebarRow item1 = ((Widgets.SidebarRow) child1);
            Widgets.SidebarRow item2 = ((Widgets.SidebarRow) child2);

            if (item1.visible) {
                return -1;
            }

            return item1.item_order () - item2.item_order ();
        });
        views_group.set_sort_func (null);

        settings_header.back_activated.connect (() => {
            pop_subpage ();
        });

        sidebar_width_row.output.connect (() => {
            Services.Settings.get_default ().settings.set_int ("pane-position", (int) sidebar_width_row.value);
        });
    }
}

public class Widgets.SidebarRow : Gtk.ListBoxRow {
    public FilterType filter_type { get; construct; }
    public string icon { get; construct; }
    public string title { get; construct; }

    private Gtk.Box handle_grid;
    private Gtk.CheckButton check_button;

    public bool active {
        get {
            return check_button.active;
        }
    }

    public SidebarRow (FilterType filter_type, string title, string icon) {
        Object (
            filter_type: filter_type,
            title: title,
            icon: icon
        );
    }

    construct {
        add_css_class ("sidebar-row");
        add_css_class ("transition");

        var name_label = new Gtk.Label (title);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

        check_button = new Gtk.CheckButton () {
            valign = CENTER,
            halign = END,
            hexpand = true,
            css_classes = { "flat" },
            active = check_active ()
        };

        handle_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 9) {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };

        handle_grid.append (new Gtk.Image.from_icon_name (icon));
        handle_grid.append (name_label);
        handle_grid.append (check_button);

        var reorder = new Widgets.ReorderChild (handle_grid, this);

        var main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = reorder
        };

        child = main_revealer;
        reorder.build_drag_and_drop ();

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        check_button.toggled.connect (() => {
            updateView (
                get_views_array (),
                filter_type.to_string (),
                check_button.active
            );
        });

        reorder.on_drop_end.connect ((listbox) => {
            update_views_order (listbox);
        });
    }

    private void updateView (Array<string> views, string view, bool active) { // vala-lint=naming-convention
        if (active) {
            if (!find_view (views.data, view)) {
                views.append_val (view);
            }
        } else {
            int index = find_index (views.data, view);
            if (index != -1) {
                views.remove_index (index);
            }
        }

        Services.Settings.get_default ().settings.set_strv ("views-order-visible", views.data);
        update_views_order ((Gtk.ListBox) parent);
    }

    private Array<string> get_views_array () {
        string[] list = Services.Settings.get_default ().settings.get_strv ("views-order-visible");
        Array<string> array = new Array<string> ();

        foreach (string view in list) {
            array.append_val (view);
        }

        return array;
    }

    private void update_views_order (Gtk.ListBox listbox) {
        Array<string> list = new Array<string> ();
        unowned Widgets.SidebarRow ? row = null;
        var row_index = 0;

        do {
            row = (Widgets.SidebarRow) listbox.get_row_at_index (row_index);

            if (row != null && row.active) {
                list.append_val (row.filter_type.to_string ());
            }

            row_index++;
        } while (row != null);

        Services.Settings.get_default ().settings.set_strv ("views-order-visible", list.data);
    }

    public int item_order () {
        var views_order = Services.Settings.get_default ().settings.get_strv ("views-order-visible");
        return find_index (views_order, filter_type.to_string ());
    }

    int find_index (string[] array, string elemento) {
        for (int i = 0; i < array.length; i++) {
            if (array[i] == elemento) {
                return i;
            }
        }

        return -1;
    }

    private bool check_active () {
        var views_order = Services.Settings.get_default ().settings.get_strv ("views-order-visible");
        return find_view (views_order, filter_type.to_string ());
    }

    private bool find_view (string[] array, string elemento) {
        for (int i = 0; i < array.length; i++) {
            if (array[i] == elemento) {
                return true;
            }
        }

        return false;
    }
}
