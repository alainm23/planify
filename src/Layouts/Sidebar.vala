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
    private Gtk.Revealer filters_revealer;
    private Gtk.ListBox sources_listbox;

    private Layouts.HeaderItem favorites_header;
    public Gee.HashMap<string, Layouts.ProjectRow> favorites_hashmap = new Gee.HashMap<string, Layouts.ProjectRow> ();
    public Gee.HashMap<string, Layouts.SidebarSourceRow> sources_hashmap = new Gee.HashMap<string, Layouts.SidebarSourceRow> ();
    
    construct {
        filters_revealer = new Gtk.Revealer () {
            hexpand = true,
            vexpand = true,
            transition_type = Gtk.RevealerTransitionType.CROSSFADE
        };

        favorites_header = new Layouts.HeaderItem (_("Favorites")) {
            margin_top = 6,
            placeholder_message = _("No favorites available. Create one by clicking on the '+' button")
        };

        sources_listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = Gtk.Align.START,
            css_classes = { "listbox-background" }
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_top = 6,
            valign = START
        };

        content_box.append (filters_revealer);
        content_box.append (favorites_header);
        content_box.append (sources_listbox);

        var scrolled_window = new Widgets.ScrolledWindow (content_box);

        child = scrolled_window;
        update_filter_view ();

        sources_listbox.set_sort_func ((child1, child2) => {
            int item1 = ((Layouts.SidebarSourceRow) child1).source.child_order;
            int item2 = ((Layouts.SidebarSourceRow) child2).source.child_order;
            return item1 - item2;
        });

        Services.Settings.get_default ().settings.changed["views-order-visible"].connect (() => {
            if (filters_revealer.child is Gtk.FlowBox) {
                ((Gtk.FlowBox) filters_revealer.child).invalidate_sort ();
                ((Gtk.FlowBox) filters_revealer.child).invalidate_filter ();
            } else if (filters_revealer.child is Gtk.ListBox) {
                ((Gtk.ListBox) filters_revealer.child).invalidate_sort ();
                ((Gtk.ListBox) filters_revealer.child).invalidate_filter ();
            }
        });

        Services.EventBus.get_default ().update_sources_position.connect (() => {
            sources_listbox.invalidate_sort ();
        });

        Services.Settings.get_default ().settings.changed["filters-list-view"].connect (update_filter_view);
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

    public void init () {
        Services.Store.instance ().source_added.connect (add_source_row);

        Services.Store.instance ().source_deleted.connect ((source) => {
            if (sources_hashmap.has_key (source.id)) {
                sources_hashmap.get (source.id).hide_destroy ();
            }
        });

        Services.EventBus.get_default ().favorite_toggled.connect ((project) => {
            if (favorites_hashmap.has_key (project.id)) {
                favorites_hashmap[project.id].hide_destroy ();
                favorites_hashmap.unset (project.id);
            } else {
                add_row_favorite (project);
            }

            favorites_header.reveal = favorites_hashmap.size > 0;
        });

        Services.Store.instance ().project_added.connect ((project) => {
            add_row_favorite (project);
        });

        add_all_favorites ();

        foreach (Objects.Source source in Services.Store.instance ().sources) {
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
        foreach (Objects.Project project in Services.Store.instance ().projects) {
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

        favorites_hashmap[project.id] = new Layouts.ProjectRow (project, false, false);
        favorites_header.add_child (favorites_hashmap[project.id]);
    }

    private void update_filter_view () {
        filters_revealer.reveal_child = false;

        Timeout.add (filters_revealer.transition_duration, () => {
            destroy_current_filter_view ();

            if (Services.Settings.get_default ().settings.get_boolean ("filters-list-view")) {
                filters_revealer.child = build_filters_listbox ();
            } else {
                filters_revealer.child = build_filters_flowbox ();
            }

            filters_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });
    }

    private void destroy_current_filter_view () {
        if (filters_revealer.child is Gtk.FlowBox) {
            Gtk.FlowBox ? filters_flowbox = (Gtk.FlowBox) filters_revealer.child;
            if (filters_flowbox != null) {
                // filters_flowbox.clean_up ();
            }
        } else if (filters_revealer.child is Gtk.ListBox) {
            Gtk.ListBox ? filters_listbox = (Gtk.ListBox) filters_revealer.child;
            if (filters_listbox != null) {
                foreach (Gtk.ListBoxRow row in Util.get_default ().get_children (filters_listbox)) {
                    ((Layouts.FilterPaneRow) row).clean_up ();
                }
            }
        }

        filters_revealer.child = null;
    }

    private Gtk.Widget build_filters_flowbox () {
        var flowbox = new Gtk.FlowBox () {
            homogeneous = true,
            row_spacing = 9,
            column_spacing = 9,
            margin_start = 3,
            margin_end = 3,
            margin_top = 3,
            margin_bottom = 3,
            min_children_per_line = 2
        };

        flowbox.append (new Layouts.FilterPaneChild (Objects.Filters.Inbox.get_default ()));

        flowbox.append (new Layouts.FilterPaneChild (Objects.Filters.Today.get_default ()) {
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Go to Today"), "Ctrl+T")
        });

        flowbox.append (new Layouts.FilterPaneChild (Objects.Filters.Scheduled.get_default ()) {
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Go to Scheduled"), "Ctrl+U")
        });
        
        flowbox.append (new Layouts.FilterPaneChild (Objects.Filters.Labels.get_default ()) {
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Go to Labels"), "Ctrl+L")
        });
        
        flowbox.append (new Layouts.FilterPaneChild (Objects.Filters.Pinboard.get_default ()) {
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Go to Pinboard"), "Ctrl+P")
        });
        
        flowbox.append (new Layouts.FilterPaneChild (Objects.Filters.Completed.get_default ()));
        flowbox.append (new Layouts.FilterPaneChild (Objects.Filters.Tomorrow.get_default ()));
        flowbox.append (new Layouts.FilterPaneChild (Objects.Filters.Anytime.get_default ()));
        flowbox.append (new Layouts.FilterPaneChild (Objects.Filters.Repeating.get_default ()));
        flowbox.append (new Layouts.FilterPaneChild (Objects.Filters.Unlabeled.get_default ()));
        flowbox.append (new Layouts.FilterPaneChild (Objects.Filters.AllItems.get_default ()));

        flowbox.child_activated.connect ((child) => {
            var filter = (Layouts.FilterPaneChild) child;
            Services.EventBus.get_default ().pane_selected (PaneType.FILTER, filter.filter_type.view_id);
        });

        flowbox.set_sort_func ((child1, child2) => {
            int item1 = ((Layouts.FilterPaneChild) child1).item_order ();
            int item2 = ((Layouts.FilterPaneChild) child2).item_order ();

            return item1 - item2;
        });

        flowbox.set_filter_func ((child) => {
            return ((Layouts.FilterPaneChild) child).active ();
        });

        return flowbox;
    }

    private Gtk.Widget build_filters_listbox () {
        var listbox = new Gtk.ListBox () {
            margin_top = 3,
            margin_bottom = 3
        };
        listbox.add_css_class ("bg-transparent");
        listbox.add_css_class ("listbox-separator-3");

        listbox.append (new Layouts.FilterPaneRow (Objects.Filters.Inbox.get_default ()));

        listbox.append (new Layouts.FilterPaneRow (Objects.Filters.Today.get_default ()) {
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Go to Today"), "Ctrl+T")
        });

        listbox.append (new Layouts.FilterPaneRow (Objects.Filters.Scheduled.get_default ()) {
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Go to Scheduled"), "Ctrl+U")
        });
        
        listbox.append (new Layouts.FilterPaneRow (Objects.Filters.Labels.get_default ()) {
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Go to Labels"), "Ctrl+L")
        });
        
        listbox.append (new Layouts.FilterPaneRow (Objects.Filters.Pinboard.get_default ()) {
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Go to Pinboard"), "Ctrl+P")
        });
        
        listbox.append (new Layouts.FilterPaneRow (Objects.Filters.Completed.get_default ()));
        listbox.append (new Layouts.FilterPaneRow (Objects.Filters.Tomorrow.get_default ()));
        listbox.append (new Layouts.FilterPaneRow (Objects.Filters.Anytime.get_default ()));
        listbox.append (new Layouts.FilterPaneRow (Objects.Filters.Repeating.get_default ()));
        listbox.append (new Layouts.FilterPaneRow (Objects.Filters.Unlabeled.get_default ()));
        listbox.append (new Layouts.FilterPaneRow (Objects.Filters.AllItems.get_default ()));

        listbox.row_activated.connect ((row) => {
            var filter = (Layouts.FilterPaneRow) row;
            Services.EventBus.get_default ().pane_selected (PaneType.FILTER, filter.filter_type.view_id);
        });

        listbox.set_sort_func ((row1, row2) => {
            int item1 = ((Layouts.FilterPaneRow) row1).item_order ();
            int item2 = ((Layouts.FilterPaneRow) row2).item_order ();

            return item1 - item2;
        });

        listbox.set_filter_func ((row) => {
            return ((Layouts.FilterPaneRow) row).active ();
        });

        return listbox;
    }
}
