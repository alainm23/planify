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

    ~FilterFlowBoxChild () {
        debug ("Destroying - Widgets.FilterFlowBoxChild\n");
    }

    construct {
        add_css_class ("card");

        image = new Gtk.Image ();

        title_label = new Gtk.Label (null) {
            halign = START,
            css_classes = { "title-4", "caption" }
        };

        value_label = new Gtk.Label (null) {
            xalign = 0,
            use_markup = true,
            halign = START,
            css_classes = { "caption" }
        };

        var close_button = new Gtk.Button.from_icon_name ("cross-large-circle-filled-symbolic") {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            css_classes = { "flat" }
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
