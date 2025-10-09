
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

public class Layouts.FilterPaneRow : Gtk.ListBoxRow {
    public Objects.BaseObject filter_type { get; construct; }

    private Gtk.Label count_label;
    private Gtk.Revealer indicator_revealer;
    private Objects.Project? current_inbox_project = null;
    private ulong inbox_count_signal_id = 0;
    private Gee.HashMap<ulong, weak GLib.Object> signals_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public FilterPaneRow (Objects.BaseObject filter_type) {
        Object (
            filter_type: filter_type
        );
    }

    ~FilterPaneRow () {
        debug ("Destroying Layouts.FilterPaneRow\n");
    }

    construct {
        css_classes = { "row", "transition", "no-padding", "filter-pane-row" };

        var title_image = new Gtk.Image.from_icon_name (filter_type.icon_name) {
            pixel_size = 16,
            valign = CENTER,
            halign = CENTER,
            css_classes = { "view-icon" }
        };
        title_image.add_css_class ("view-icon");

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

        count_label = new Gtk.Label (null) {
            hexpand = true,
            margin_end = 12,
            halign = Gtk.Align.CENTER,
            css_classes = { "caption", "dimmed" }
        };

        var count_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = count_label
        };

        var end_box = new Gtk.Box (VERTICAL, 0) {
            hexpand = true,
            halign = END,
            valign = CENTER
        };

        end_box.append (count_revealer);

        var main_box = new Gtk.Box (HORIZONTAL, 6) {
            margin_start = 3,
            margin_end = 3,
            margin_top = 3,
            margin_bottom = 3
        };

        main_box.append (title_image);
        main_box.append (title_label);
        main_box.append (end_box);

        var handle_grid = new Adw.Bin () {
            css_classes = { "transition", "selectable-item" },
            child = main_box
        };

        child = handle_grid;
        Services.Settings.get_default ().settings.bind ("show-tasks-count", count_revealer, "reveal_child", GLib.SettingsBindFlags.DEFAULT);

        Util.get_default ().set_widget_color (filter_type.theme_color (), title_image);
        signals_map[Services.EventBus.get_default ().theme_changed.connect (() => {
            Util.get_default ().set_widget_color (filter_type.theme_color (), title_image);
        })] = Services.EventBus.get_default ();
        
        var select_gesture = new Gtk.GestureClick ();
        add_controller (select_gesture);
        signals_map[select_gesture.pressed.connect (() => {
            Services.EventBus.get_default ().pane_selected (PaneType.FILTER, filter_type.view_id);
        })] = select_gesture;

        signals_map[Services.EventBus.get_default ().pane_selected.connect ((pane_type, id) => {
            if (pane_type == PaneType.FILTER && filter_type.view_id == id) {
                handle_grid.add_css_class ("selected");

                if (!has_css_class ("animation")) {
                    add_css_class ("animation");
                    Timeout.add (700, () => {
                        remove_css_class ("animation");
                        return GLib.Source.REMOVE;
                    });
                }
            } else {
                handle_grid.remove_css_class ("selected");
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

            Services.Settings.get_default ().settings.changed["local-inbox-project-id"].connect (() => {
                init_inbox_count ();
            });
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
            filter_type.count_updated.connect (() => {
                update_count_label (filter_type.item_count);
            });
        }
    }

    private void init_inbox_count () {
        if (current_inbox_project != null && inbox_count_signal_id > 0) {
            current_inbox_project.disconnect (inbox_count_signal_id);
        }

        current_inbox_project = Services.Store.instance ().get_project (
            Services.Settings.get_default ().settings.get_string ("local-inbox-project-id")
        );

        update_count_label (current_inbox_project.item_count);
        inbox_count_signal_id = current_inbox_project.count_updated.connect (() => {
            update_count_label (current_inbox_project.item_count);
        });
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
