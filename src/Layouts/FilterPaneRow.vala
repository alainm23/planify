
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

public class Layouts.FilterPaneRow : Gtk.FlowBoxChild {
    public FilterType filter_type { get; construct; }

    public string title;
    public string icon_name;

    private Widgets.DynamicIcon title_image;
    private Gtk.Label title_label;
    private Gtk.Label count_label;

    public FilterPaneRow (FilterType filter_type) {
        Object (
            filter_type: filter_type,
            can_focus: false
        );
    }

    construct {
        add_css_class ("card");
        add_css_class ("filter-pane-row-%s".printf (filter_type.to_string ()));

        title_image = new Widgets.DynamicIcon () {
            hexpand = true,
            halign = Gtk.Align.START,
            margin_start = 3
        };
        title_image.size = 16;

        title_label = new Gtk.Label (null) {
            hexpand = true,
            halign = Gtk.Align.START,
            margin_start = 3
        };
        title_label.ellipsize = Pango.EllipsizeMode.END;
        title_label.add_css_class ("font-bold");
        
        count_label = new Gtk.Label (null) {
            hexpand = true,
            halign = Gtk.Align.END,
            margin_end = 3
        };

        count_label.add_css_class ("font-bold");

        var count_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = count_label
        };

        var main_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin_start = 3,
            margin_end = 3,
            margin_top = 3,
            margin_bottom = 3,
            width_request = 100
        };

        main_grid.attach (title_image, 0, 0, 1, 1);
        main_grid.attach (count_revealer, 1, 0, 1, 1);
        main_grid.attach (title_label, 0, 1, 2, 2);

        child = main_grid;
        build_filter_data ();
        Services.Settings.get_default ().settings.bind ("show-tasks-count", count_revealer, "reveal_child", GLib.SettingsBindFlags.DEFAULT);

        var select_gesture = new Gtk.GestureClick ();
        select_gesture.set_button (1);
        add_controller (select_gesture);

        select_gesture.pressed.connect (() => {
            add_css_class ("selected");
            Timeout.add (1000, () => {
                remove_css_class ("selected"); 
                return GLib.Source.REMOVE;
            });

            Services.EventBus.get_default ().pane_selected (PaneType.FILTER, filter_type.to_string ());
        });

        Services.EventBus.get_default ().pane_selected.connect ((pane_type, id) => {
            if (pane_type == PaneType.FILTER && filter_type.to_string () == id) {
                add_css_class (
                    "filter-pane-row-%s-selected".printf (filter_type.to_string ())
                );

                add_css_class ("selected");
                Timeout.add (1000, () => {
                    remove_css_class ("selected"); 
                    return GLib.Source.REMOVE;
                });
            } else {
                remove_css_class (
                    "filter-pane-row-%s-selected".printf (filter_type.to_string ())
                );
                remove_css_class ("selected"); 
            }
        });
    }

    private void build_filter_data () {
        if (filter_type == FilterType.TODAY) {
            title_label.label = _("Today");
            title_image.update_icon_name ("planner-today");
        } else if (filter_type == FilterType.INBOX) {
            title_label.label = _("Inbox");
            title_image.update_icon_name ("planner-inbox");
        } else if (filter_type == FilterType.SCHEDULED) {
            title_label.label = _("Scheduled");
            title_image.update_icon_name ("planner-scheduled");
        } else if (filter_type == FilterType.PINBOARD) {
            title_label.label = _("Pinboard");
            title_image.update_icon_name ("planner-pin-tack");
        } else if (filter_type == FilterType.LABELS) {
            title_label.label = _("Labels");
            title_image.update_icon_name ("planner-tag-icon");
        }
    }

    private void update_count_label (int count) {
        count_label.label = count <= 0 ? "" : count.to_string ();
    }
    
    public void init () {
        if (filter_type == FilterType.TODAY) {
            update_count_label (Objects.Today.get_default ().today_count);
            Objects.Today.get_default ().today_count_updated.connect (() => {
                update_count_label (Objects.Today.get_default ().today_count);
            });
        } else if (filter_type == FilterType.INBOX) {
            init_inbox_count ();            
        } else if (filter_type == FilterType.SCHEDULED) {
            update_count_label (Objects.Scheduled.get_default ().scheduled_count);
            Objects.Scheduled.get_default ().scheduled_count_updated.connect (() => {
                update_count_label (Objects.Scheduled.get_default ().scheduled_count);
            });
        } else if (filter_type == FilterType.PINBOARD) {
            update_count_label (Objects.Pinboard.get_default ().pinboard_count);
            Objects.Pinboard.get_default ().pinboard_count_updated.connect (() => {
                update_count_label (Objects.Pinboard.get_default ().pinboard_count);
            });
        } else if (filter_type == FilterType.LABELS) {
            update_count_label (Objects.Filters.Labels.get_default ().count);
            Objects.Filters.Labels.get_default ().count_updated.connect (() => {
                update_count_label (Objects.Filters.Labels.get_default ().count);
            });
        }
    }
    private void init_inbox_count () {
        Objects.Project inbox_project = Services.Database.get_default ().get_project (Services.Settings.get_default ().settings.get_string ("inbox-project-id"));
        update_count_label (inbox_project.project_count);

        inbox_project.project_count_updated.connect (() => {
            update_count_label (inbox_project.project_count);
        });

        Services.EventBus.get_default ().inbox_project_changed.connect (() => {
            inbox_project = Services.Database.get_default ().get_project (Services.Settings.get_default ().settings.get_string ("inbox-project-id"));
            update_count_label (inbox_project.project_count);
        });
    }

    public int item_order () {
        var views_order = Services.Settings.get_default ().settings.get_strv ("views-order-visible");
        return find_index (views_order, filter_type.to_string ());
    }

    public bool active () {
        var views_order = Services.Settings.get_default ().settings.get_strv ("views-order-visible");

        for (int i = 0; i < views_order.length; i++) {
            if (views_order [i] == filter_type.to_string ()) {
                return true;
            }
        }
    
        return false;
    }

    private int find_index (string[] array, string elemento) {
        for (int i = 0; i < array.length; i++) {
            if (array [i] == elemento) {
                return i;
            }
        }
    
        return -1;
    }
}
