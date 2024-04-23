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

public class Widgets.FilterFlowBox : Adw.Bin {
    public Objects.Project project { get; construct; }

    public Gtk.FlowBox flowbox;
    private Gee.HashMap<string, Widgets.FilterFlowBoxChild> filters_map;

    public FilterFlowBox (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        filters_map = new Gee.HashMap<string, Widgets.FilterFlowBoxChild> ();

        flowbox = new Gtk.FlowBox () {
            column_spacing = 12,
            row_spacing = 12,
            halign = Gtk.Align.FILL,
            orientation = Gtk.Orientation.HORIZONTAL,
            homogeneous = true
        };

        var revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = flowbox
        };

        child = revealer;
        add_filters ();

        project.filter_added.connect ((filter) => {
			add_filter (filter);
            revealer.reveal_child = project.filters.size > 0;
		});

		project.filter_removed.connect ((filter) => {
			remove_filter (filter);
            revealer.reveal_child = project.filters.size > 0;
		});

        project.filter_updated.connect ((filter) => {
			update_filter (filter);
            revealer.reveal_child = project.filters.size > 0;
		});
    }

    private void add_filters () {
        foreach (Objects.Filters.FilterItem filter in project.filters.values) {
            add_filter (filter);
		}
    }

    public void add_filter (Objects.Filters.FilterItem filter) {
        if (!filters_map.has_key (filter.id)) {
            filters_map[filter.id] = new Widgets.FilterFlowBoxChild (filter);

            filters_map[filter.id].remove_filter.connect ((_filter) => {
                project.remove_filter (_filter);
            });

            flowbox.append (filters_map[filter.id]);
        }
    }

    public void remove_filter (Objects.Filters.FilterItem filter) {
        if (filters_map.has_key (filter.id)) {
            filters_map[filter.id].hide_destroy ();
            filters_map.unset (filter.id);
        }
    }

    public void update_filter (Objects.Filters.FilterItem filter) {
        if (filters_map.has_key (filter.id)) {
            filters_map[filter.id].update_request ();
        }
    }
}

public class Widgets.FilterFlowBoxChild : Gtk.FlowBoxChild {
    public Objects.Filters.FilterItem filter { get; construct; }
    
    private Gtk.Image image;
    private Gtk.Label title_label;
    private Gtk.Label value_label;
    private Gtk.Revealer main_revealer;

    public signal void remove_filter (Objects.Filters.FilterItem filter);

    public FilterFlowBoxChild (Objects.Filters.FilterItem filter) {
        Object (
            filter: filter,
            valign: Gtk.Align.START,
            halign: Gtk.Align.START
        );
    }

    construct {
        add_css_class ("card");

        image = new Gtk.Image ();

        title_label = new Gtk.Label (null) {
            halign = START,
            css_classes = { "title-4", "small-label" }
        };

        value_label = new Gtk.Label (null) {
            xalign = 0,
            use_markup = true,
            halign = START,
            css_classes = { "small-label" }
        };

        var close_button = new Gtk.Button.from_icon_name ("cross-large-circle-filled-symbolic") {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            css_classes = { "flat"}
        };

        var close_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            child = close_button,
            reveal_child = true
        };
        
        var card_grid = new Gtk.Grid () {
            column_spacing = 12,
            margin_start = 12,
            margin_top = 3,
            margin_bottom = 3,
            vexpand = true,
            hexpand = true
        };

        card_grid.attach (image, 0, 0, 1, 2);
        card_grid.attach (title_label, 1, 0, 1, 1);
        card_grid.attach (value_label, 1, 1, 1, 1);
        card_grid.attach (close_revealer, 2, 0, 1, 2);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            child = card_grid
        };

        child = main_revealer;
        update_request ();
        
        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });
        
        var motion_gesture = new Gtk.EventControllerMotion ();
        add_controller (motion_gesture);

        motion_gesture.enter.connect (() => {
            //  close_revealer.reveal_child = true;
        });

        motion_gesture.leave.connect (() => {
            //  close_revealer.reveal_child = false;
        });

        close_button.clicked.connect (() => {
            remove_filter (filter);
        });
    }

    public void update_request () {
        image.icon_name = filter.filter_type.get_icon ();
        title_label.label = filter.filter_type.get_title ();
        value_label.label = filter.name;
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.FlowBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }
}