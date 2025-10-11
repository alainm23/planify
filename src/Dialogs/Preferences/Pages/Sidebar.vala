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

public class Dialogs.Preferences.Pages.Sidebar : Dialogs.Preferences.Pages.BasePage {
    private Layouts.HeaderItem views_group;

    public Sidebar (Adw.PreferencesDialog preferences_dialog) {
        Object (
            preferences_dialog: preferences_dialog,
            title: _("Sidebar")
        );
    }

    ~Sidebar () {
        debug ("Destroying - Dialogs.Preferences.Pages.Sidebar\n");
    }

    construct {
        views_group = new Layouts.HeaderItem (_("Show in Sidebar")) {
            card = true,
            reveal = true,
            margin_top = 12
        };

        views_group.add_child (new SidebarRow (Objects.Filters.Inbox.get_default ()));
        views_group.add_child (new SidebarRow (Objects.Filters.Today.get_default ()));
        views_group.add_child (new SidebarRow (Objects.Filters.Scheduled.get_default ()));
        views_group.add_child (new SidebarRow (Objects.Filters.Pinboard.get_default ()));
        views_group.add_child (new SidebarRow (Objects.Filters.Labels.get_default ()));
        views_group.add_child (new SidebarRow (Objects.Filters.Completed.get_default ()));
        views_group.add_child (new SidebarRow (Objects.Filters.Tomorrow.get_default ()));
        views_group.add_child (new SidebarRow (Objects.Filters.Anytime.get_default ()));
        views_group.add_child (new SidebarRow (Objects.Filters.Repeating.get_default ()));
        views_group.add_child (new SidebarRow (Objects.Filters.Unlabeled.get_default ()));
        views_group.add_child (new SidebarRow (Objects.Filters.AllItems.get_default ()));

        var show_count_row = new Adw.SwitchRow () {
            title = _("Show Task Count")
        };

        var sidebar_width_row = new Adw.SpinRow.with_range (300, 400, 1) {
            valign = Gtk.Align.CENTER,
            title = _("Sidebar Width"),
            value = Services.Settings.get_default ().settings.get_int ("pane-position")
        };

        var list_view_filters_row = new Adw.SwitchRow () {
            title = _("List View for Filters"),
            subtitle = _("Show filters in a simple list instead of a grid")
        };

        var count_group = new Adw.PreferencesGroup () {
            margin_start = 3,
            margin_end = 3,
            margin_top = 12
        };

        count_group.add (show_count_row);
        count_group.add (sidebar_width_row);
        count_group.add (list_view_filters_row);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.append (count_group);
        content_box.append (views_group);
        content_box.append (new Gtk.Label (_("You can sort your views by dragging and dropping")) {
            css_classes = { "caption", "dimmed" },
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
        toolbar_view.add_top_bar (new Adw.HeaderBar ());

        child = toolbar_view;
        Services.Settings.get_default ().settings.bind ("show-tasks-count", show_count_row, "active", GLib.SettingsBindFlags.DEFAULT);
        Services.Settings.get_default ().settings.bind ("filters-list-view", list_view_filters_row, "active", GLib.SettingsBindFlags.DEFAULT);

        views_group.set_sort_func ((child1, child2) => {
            SidebarRow item1 = ((SidebarRow) child1);
            SidebarRow item2 = ((SidebarRow) child2);

            if (item1.visible) {
                return -1;
            }

            return item1.item_order () - item2.item_order ();
        });
        views_group.set_sort_func (null);

        signal_map[sidebar_width_row.output.connect (() => {
            Services.Settings.get_default ().settings.set_int ("pane-position", (int) sidebar_width_row.value);
        })] = sidebar_width_row;

        destroy.connect (() => {
            clean_up ();
        });
    }

    public override void clean_up () {
        views_group.set_sort_func (null);
        foreach (var row in views_group.get_children ()) {
            ((SidebarRow) row).clean_up ();
        }

        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }

    public class SidebarRow : Gtk.ListBoxRow {
        public Objects.BaseObject base_object { get; construct; }
        public string icon { get; construct; }
        public string title { get; construct; }

        private Widgets.ReorderChild reorder;
        private Gtk.Switch check_button;
        private Gtk.GestureClick select_gesture;
        private Gtk.Revealer main_revealer;
        private Adw.ActionRow action_row;

        public bool active {
            get {
                return check_button.active;
            }
        }

        public Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

        public SidebarRow (Objects.BaseObject base_object) {
            Object (
                base_object: base_object
            );
        }

        ~SidebarRow () {
            debug ("Destroying SidebarRow\n");
        }

        construct {
            add_css_class ("sidebar-row");
            add_css_class ("transition");
            add_css_class ("no-padding");

            check_button = new Gtk.Switch () {
                valign = CENTER,
                halign = END,
                hexpand = true,
                css_classes = { "flat" },
                active = check_active ()
            };

            action_row = new Adw.ActionRow () {
                title = base_object.name,
                activatable = true
            };
            action_row.add_prefix (new Gtk.Image.from_icon_name (base_object.icon_name));
            action_row.add_suffix (check_button);

            reorder = new Widgets.ReorderChild (action_row, this);

            main_revealer = new Gtk.Revealer () {
                transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
                child = reorder
            };

            child = main_revealer;
            reorder.build_drag_and_drop ();

            Timeout.add (main_revealer.transition_duration, () => {
                main_revealer.reveal_child = true;
                return GLib.Source.REMOVE;
            });

            signal_map[check_button.notify["active"].connect (() => {
                updateView (
                    get_views_array (),
                    base_object.view_id,
                    check_button.active
                );
            })] = check_button;

            signal_map[reorder.on_drop_end.connect ((listbox) => {
                update_views_order (listbox);
            })] = reorder;

            signal_map[main_revealer.notify["child-revealed"].connect (() => {
                reorder.draw_motion_widgets ();
            })] = main_revealer;

            select_gesture = new Gtk.GestureClick ();
            action_row.add_controller (select_gesture);
            signal_map[select_gesture.released.connect (() => {
                check_button.active = !check_button.active;
            })] = select_gesture;

            destroy.connect (() => {
                clean_up ();
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
            unowned SidebarRow ? row = null;
            var row_index = 0;

            do {
                row = (SidebarRow) listbox.get_row_at_index (row_index);

                if (row != null && row.active) {
                    list.append_val (row.base_object.view_id);
                }

                row_index++;
            } while (row != null);

            Services.Settings.get_default ().settings.set_strv ("views-order-visible", list.data);
        }

        public int item_order () {
            var views_order = Services.Settings.get_default ().settings.get_strv ("views-order-visible");
            return find_index (views_order, base_object.view_id);
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
            return find_view (views_order, base_object.view_id);
        }

        private bool find_view (string[] array, string elemento) {
            for (int i = 0; i < array.length; i++) {
                if (array[i] == elemento) {
                    return true;
                }
            }

            return false;
        }

        public void clean_up () {
            if (reorder != null) {
                reorder.clean_up ();
                reorder = null;
            }

            foreach (var entry in signal_map.entries) {
                entry.value.disconnect (entry.key);
            }
            signal_map.clear ();

            if (select_gesture != null && action_row != null) {
                action_row.remove_controller (select_gesture);
                select_gesture = null;
            }
            
            check_button = null;
            main_revealer = null;
            action_row = null;
        }
    }
}
