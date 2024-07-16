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

public class Layouts.Sidebar : Adw.Bin {
    private Gtk.FlowBox filters_flow;

    private Layouts.FilterPaneRow inbox_filter;
    private Layouts.FilterPaneRow today_filter;
    private Layouts.FilterPaneRow scheduled_filter;
    private Layouts.FilterPaneRow labels_filter;
    private Layouts.FilterPaneRow pinboard_filter;
    private Layouts.FilterPaneRow completed_filter;

    private Gtk.ListBox sources_listbox;
    
    private Layouts.HeaderItem favorites_header;
    public Gee.HashMap <string, Layouts.ProjectRow> favorites_hashmap = new Gee.HashMap <string, Layouts.ProjectRow> ();
    public Gee.HashMap <string, Layouts.SidebarSourceRow> sources_hashmap = new Gee.HashMap <string, Layouts.SidebarSourceRow> ();

    public Sidebar () {
        Object ();
    }

    construct { 
        filters_flow = new Gtk.FlowBox () {
            homogeneous = true,
            row_spacing = 9,
            column_spacing = 9,
            margin_start = 3,
            margin_end = 3,
            min_children_per_line = 2
        };

        inbox_filter = new Layouts.FilterPaneRow (FilterType.INBOX) {
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Go to Inbox"), "Ctrl+I")
        };
        
        today_filter = new Layouts.FilterPaneRow (FilterType.TODAY) {
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Go to Today"), "Ctrl+T")
        };
        
        scheduled_filter = new Layouts.FilterPaneRow (FilterType.SCHEDULED) {
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Go to Scheduled"), "Ctrl+U")
        };
        
        labels_filter = new Layouts.FilterPaneRow (FilterType.LABELS) {
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Go to Labels"), "Ctrl+L")
        };

        pinboard_filter = new Layouts.FilterPaneRow (FilterType.PINBOARD) {
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Go to Pinboard"), "Ctrl+P")
        };

        completed_filter = new Layouts.FilterPaneRow (FilterType.COMPLETED) {
            //  tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Go to Completed"), "Ctrl+P")
        };

        filters_flow.append (inbox_filter);
        filters_flow.append (today_filter);
        filters_flow.append (scheduled_filter);
        filters_flow.append (labels_filter);
        filters_flow.append (pinboard_filter);
        filters_flow.append (completed_filter);

        favorites_header = new Layouts.HeaderItem (_("Favorites"));
        favorites_header.placeholder_message = _("No favorites available. Create one by clicking on the '+' button");
        favorites_header.margin_top = 6;

        sources_listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = Gtk.Align.START,
            css_classes = { "listbox-background" }
        };

        var whats_new_icon = new Gtk.Image.from_icon_name ("star-outline-thick-symbolic") {
            css_classes = { "gift-animation" }
        };
        
        var whats_new_label = new Gtk.Label (_("What’s new in Planify")) {
            css_classes = { "underline" }
        };

        var close_button = new Gtk.Button.from_icon_name ("window-close") {
            css_classes = { "flat", "no-padding" },
            hexpand = true,
            halign = END,
            margin_end = 3
        };

        var whats_new_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            css_classes = { "card", "padding-9" },
            vexpand = true,
            valign = END,
            margin_start = 3,
            margin_end = 3,
            margin_top = 9,
            margin_bottom = 3
        };

        whats_new_box.append (whats_new_icon);
        whats_new_box.append (whats_new_label);
        whats_new_box.append (close_button);

        var whats_new_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SWING_UP,
            child = whats_new_box,
            reveal_child = verify_new_version ()
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_top = 6
        };

        content_box.append (filters_flow);
        content_box.append (favorites_header);
        content_box.append (sources_listbox);

        if (Constants.SHOW_WHATSNEW) {
            content_box.append (whats_new_revealer);
        }

        var scrolled_window = new Widgets.ScrolledWindow (content_box);

        child = scrolled_window;

        Services.Settings.get_default ().settings.changed.connect ((key) => {
            if (key == "views-order-visible") {
                filters_flow.invalidate_sort ();
                filters_flow.invalidate_filter ();
            }
        });


        filters_flow.set_sort_func ((child1, child2) => {
            int item1 = ((Layouts.FilterPaneRow) child1).item_order ();
            int item2 = ((Layouts.FilterPaneRow) child2).item_order ();

            return item1 - item2;
        });

        filters_flow.set_filter_func ((child) => {
            var row = ((Layouts.FilterPaneRow) child);
            return row.active ();
        });

        var whats_new_gesture = new Gtk.GestureClick ();
        whats_new_box.add_controller (whats_new_gesture);

        whats_new_gesture.pressed.connect (() => {
			var dialog = new Dialogs.WhatsNew ();
			dialog.present (Planify._instance.main_window);

            update_version ();
            whats_new_revealer.reveal_child = verify_new_version ();
        });

        var close_gesture = new Gtk.GestureClick ();
        close_button.add_controller (close_gesture);
        close_gesture.pressed.connect (() => {
            close_gesture.set_state (Gtk.EventSequenceState.CLAIMED);

            update_version ();
            whats_new_revealer.reveal_child = verify_new_version ();
        });
    }

    public void update_version () {
        Services.Settings.get_default ().settings.set_string ("version", Build.VERSION);
    }

    public bool verify_new_version () {
        return Services.Settings.get_default ().settings.get_string ("version") != Build.VERSION;
    }

    public void select_project (Objects.Project project) {
        Services.EventBus.get_default ().pane_selected (PaneType.PROJECT, project.id);
    }

    public void select_filter (FilterType filter_type) {
        Services.EventBus.get_default ().pane_selected (PaneType.FILTER, filter_type.to_string ());
    }

    public void init () {
        Services.Database.get_default ().source_added.connect (add_source_row);

        Services.Database.get_default ().source_deleted.connect ((source) => {
            if (sources_hashmap.has_key (source.id)) {
                sources_hashmap.get (source.id).hide_destroy ();
            }
        });

        Services.EventBus.get_default ().favorite_toggled.connect ((project) => {
            if (favorites_hashmap.has_key (project.id)) {
                favorites_hashmap [project.id].hide_destroy ();
                favorites_hashmap.unset (project.id);
            } else {
                add_row_favorite (project);
            }

            favorites_header.reveal = favorites_hashmap.size > 0;
        });
        
        inbox_filter.init ();
        today_filter.init ();
        scheduled_filter.init ();
        labels_filter.init ();
        pinboard_filter.init ();
        completed_filter.init ();

        add_all_favorites ();

        foreach (Objects.Source source in Services.Database.get_default ().sources) {
			add_source_row (source);
		}
    }

    private void add_source_row (Objects.Source source) {
        if (!sources_hashmap.has_key (source.id)) {
            sources_hashmap[source.id] = new Layouts.SidebarSourceRow (source);
            sources_listbox.append (sources_hashmap[source.id]);
        }
    }

    private void add_all_favorites () {
        foreach (Objects.Project project in Services.Database.get_default ().projects) {
            add_row_favorite (project);
        }

        favorites_header.reveal = favorites_hashmap.size > 0;
    }

    private void add_row_favorite (Objects.Project project) {
        if (!project.is_favorite) {
            return;
        }

        if (favorites_hashmap.has_key (project.id)) {
            return;
        }

        favorites_hashmap [project.id] = new Layouts.ProjectRow (project, false, false);
        favorites_header.add_child (favorites_hashmap [project.id]);
    }
}
