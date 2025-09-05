
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

public class Layouts.FilterPaneChild : Gtk.FlowBoxChild {
    public Objects.BaseObject filter_type { get; construct; }

    private Gtk.Label count_label;
    private Gtk.Revealer indicator_revealer;
    private Gee.HashMap<ulong, weak GLib.Object> signals_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public FilterPaneChild (Objects.BaseObject filter_type) {
        Object (
            filter_type: filter_type
        );
    }

    ~FilterPaneChild () {
        print ("Destroying Layouts.FilterPaneChild\n");
    }

    construct {
        add_css_class ("card");
        add_css_class ("filter-pane-child");

        var title_image = new Gtk.Image.from_icon_name (filter_type.icon_name) {
            margin_start = 3
        };

        var title_label = new Gtk.Label (filter_type.name) {
            margin_start = 3,
            ellipsize = Pango.EllipsizeMode.END
        };

        var indicator_widget = new Adw.Bin () {
            width_request = 9,
            height_request = 9,
            margin_end = 3,
            margin_top = 3,
            valign = END,
            css_classes = { "indicator", "bg-danger" }
        };

        indicator_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = indicator_widget,
            hexpand = true,
            halign = END
        };

        var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        title_box.append (title_label);
        title_box.append (indicator_revealer);

        count_label = new Gtk.Label (null) {
            hexpand = true,
            halign = Gtk.Align.END,
            margin_end = 3,
            css_classes = { "font-bold" }
        };

        var count_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = count_label
        };

        var main_grid = new Gtk.Grid () {
            column_spacing = 6,
            row_spacing = 6,
            margin_start = 3,
            margin_end = 3,
            margin_top = 3,
            margin_bottom = 3,
            width_request = 100
        };

        main_grid.attach (title_image, 0, 0, 1, 1);
        main_grid.attach (count_revealer, 1, 0, 1, 1);
        main_grid.attach (title_box, 0, 1, 2, 2);

        child = main_grid;
        Services.Settings.get_default ().settings.bind ("show-tasks-count", count_revealer, "reveal_child", GLib.SettingsBindFlags.DEFAULT);

        Util.get_default ().set_widget_color (filter_type.theme_color (), this);
        signals_map[Services.EventBus.get_default ().theme_changed.connect (() => {
            Util.get_default ().set_widget_color (filter_type.theme_color (), this);
        })] = Services.EventBus.get_default ();

        var select_gesture = new Gtk.GestureClick ();
        add_controller (select_gesture);
        signals_map[select_gesture.pressed.connect (() => {
            Services.EventBus.get_default ().pane_selected (PaneType.FILTER, filter_type.view_id);
        })] = select_gesture;

        signals_map[Services.EventBus.get_default ().pane_selected.connect ((pane_type, id) => {
            if (pane_type == PaneType.FILTER && filter_type.view_id == id) {
                add_css_class ("selected");

                if (!has_css_class ("animation")) {
                    add_css_class ("animation");
                    Timeout.add (700, () => {
                        remove_css_class ("animation");
                        return GLib.Source.REMOVE;
                    });
                }
            } else {
                remove_css_class ("selected");
            }
        })] = Services.EventBus.get_default ();

        if (Services.Database.get_default ().is_opened) {
            init_badge_count ();
        }
        
        signals_map[Services.Database.get_default ().opened.connect (() => {
            init_badge_count ();
        })] = Services.Database.get_default ();
    }

    private void update_count_label (int count) {
        count_label.label = count <= 0 ? "" : count.to_string ();
    }

    public void init_badge_count () {
        if (filter_type is Objects.Filters.Inbox) {
            init_inbox_count ();
        } else if (filter_type is Objects.Filters.Today) {
            var today_filter = filter_type as Objects.Filters.Today;
            update_count_label (today_filter.item_count + today_filter.overdeue_count);
            indicator_revealer.reveal_child = today_filter.overdeue_count > 0;
                signals_map[Objects.Filters.Today.get_default ().count_updated.connect (() => {
                    update_count_label (today_filter.item_count + today_filter.overdeue_count);
                    indicator_revealer.reveal_child = today_filter.overdeue_count > 0;
                })] = Objects.Filters.Today.get_default ();
        } else {
            update_count_label (filter_type.item_count);
            signals_map[filter_type.count_updated.connect (() => {
                update_count_label (filter_type.item_count);
            })] = filter_type;
        }
    }

    private void init_inbox_count () {
        Objects.Project inbox_project = Services.Store.instance ().get_project (
            Services.Settings.get_default ().settings.get_string ("local-inbox-project-id")
        );

        update_count_label (inbox_project.item_count);
        signals_map[inbox_project.count_updated.connect (() => {
            update_count_label (inbox_project.item_count);
        })] = inbox_project;
    }

    public int item_order () {
        return find_index (Services.Settings.get_default ().settings.get_strv ("views-order-visible"), filter_type.view_id);
    }

    public bool active () {
        var views_order = Services.Settings.get_default ().settings.get_strv ("views-order-visible");

        for (int i = 0; i < views_order.length; i++) {
            if (views_order[i] == filter_type.view_id) {
                return true;
            }
        }

        return false;
    }

    private int find_index (string[] array, string elemento) {
        for (int i = 0; i < array.length; i++) {
            if (array[i] == elemento) {
                return i;
            }
        }

        return -1;
    }

    public void clean_up () {
        foreach (var entry in signals_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signals_map.clear ();
    }
}
