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
    Objects.BaseObject _base_object = null;
    public Objects.BaseObject base_object {
        set {
            _base_object = value;

            signals_map[_base_object.filter_added.connect ((filter) => {
                add_filter (filter);
            })] = _base_object;

            signals_map[_base_object.filter_removed.connect ((filter) => {
                remove_filter (filter);
            })] = _base_object;

            signals_map[_base_object.filter_updated.connect ((filter) => {
                update_filter (filter);
            })] = _base_object;

            add_filters ();
        }

        get {
            return _base_object;
        }
    }

    public Gtk.FlowBox flowbox;
    private Gtk.Revealer main_revealer;
    private Gee.HashMap<string, Widgets.FilterFlowBoxChild> filters_map = new Gee.HashMap<string, Widgets.FilterFlowBoxChild> ();
    private Gee.HashMap<ulong, weak GLib.Object> signals_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public signal void filter_removed (Objects.Filters.FilterItem filter);

    ~FilterFlowBox () {
        debug ("Destroying - Widgets.FilterFlowBox\n");
    }

    construct {
        flowbox = new Gtk.FlowBox () {
            column_spacing = 12,
            row_spacing = 12,
            halign = Gtk.Align.START,
            orientation = Gtk.Orientation.VERTICAL,
            homogeneous = false
        };

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = flowbox
        };

        child = main_revealer;

        destroy.connect (() => {
            foreach (var entry in signals_map.entries) {
                entry.value.disconnect (entry.key);
            }

            signals_map.clear ();
        });
    }

    private void add_filters () {
        foreach (Objects.Filters.FilterItem filter in _base_object.filters.values) {
            add_filter (filter);
        }
    }

    public void add_filter (Objects.Filters.FilterItem filter) {
        if (!filters_map.has_key (filter.id)) {
            filters_map[filter.id] = new Widgets.FilterFlowBoxChild (filter);

            signals_map[filters_map[filter.id].remove_filter.connect ((_filter) => {
                if (_base_object != null) {
                    _base_object.remove_filter (_filter);
                } else {
                    remove_filter (_filter);
                }
            })] = filters_map[filter.id];

            flowbox.append (filters_map[filter.id]);
        }

        main_revealer.reveal_child = filters_map.size > 0;
    }

    public void remove_filter (Objects.Filters.FilterItem filter) {
        if (filters_map.has_key (filter.id)) {
            filters_map[filter.id].hide_destroy ();
            filters_map.unset (filter.id);
            filter_removed (filter);
        }

        main_revealer.reveal_child = filters_map.size > 0;
    }

    public void update_filter (Objects.Filters.FilterItem filter) {
        if (filters_map.has_key (filter.id)) {
            filters_map[filter.id].update_request ();
        }

        main_revealer.reveal_child = filters_map.size > 0;
    }

    public Objects.Filters.FilterItem ? get_filter (string id) {
        if (filters_map.has_key (id)) {
            return filters_map.get (id).filter;
        }

        return null;
    }
}
