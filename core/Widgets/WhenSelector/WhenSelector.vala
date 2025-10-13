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

public class Widgets.WhenSelector : Adw.Bin {
    public bool is_board { get; construct; }
    public string label { get; construct; }

    public WhenSelector (string label = _("When")) {
        Object (
            is_board: false,
            valign: Gtk.Align.CENTER,
            tooltip_text: label,
            label: label
        );
    }

    public WhenSelector.for_board (string label = _("When")) {
        Object (
            is_board: true,
            tooltip_text: label,
            label: label
        );
    }

    ~WhenSelector () {
        debug ("Destroying - Widgets.WhenSelector\n");
    }

    construct {
        var due_image = new Gtk.Image.from_icon_name ("month-symbolic");

        var due_label = new Gtk.Label (label) {
            xalign = 0,
            use_markup = true,
            ellipsize = Pango.EllipsizeMode.END
        };

        var container_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        container_box.append (due_image);
        container_box.append (due_label);

        var datetime_popover = build_popover ();

        var button = new Gtk.MenuButton () {
            child = container_box,
            popover = datetime_popover,
            css_classes = { "flat" }
        };

        child = button;
    }

    private Gtk.Popover build_popover () {
        var chrono = new Chrono.Chrono ();
        var search_entry = new Gtk.SearchEntry ();

        var suggested_date_box = new Adw.WrapBox () {
            child_spacing = 6
        };

        var popover_box = new Gtk.Box (VERTICAL, 12) {
            margin_top = 3,
            margin_bottom = 3
        };

        popover_box.append (search_entry);
        popover_box.append (suggested_date_box);

        var popover = new Gtk.Popover () {
            has_arrow = false,
            child = popover_box
        };

        suggested_date_box.append (new SuggestedDate (_("Today")));
        suggested_date_box.append (new SuggestedDate (_("Tomorrow")));
        suggested_date_box.append (new SuggestedDate (_("Next week")));

        search_entry.search_changed.connect (() => {
            var text = search_entry.text.strip ();
            if (text.length == 0) {
                return;
            }

            var result = chrono.parse (text);
            if (result != null && result.date != null) {
                while (suggested_date_box.get_first_child () != null) {
                    suggested_date_box.remove (suggested_date_box.get_first_child ());
                }
                suggested_date_box.append (new SuggestedDate (result.date.format ("%Y-%m-%d %H:%M")));
            }
        });

        return popover;
    }

    public class SuggestedDate : Adw.Bin {
        public string label { get; construct; }

        public SuggestedDate (string label) {
            Object (
                label: label
            );
        }

        construct {
            child = new Gtk.Label (label);
            add_css_class ("upcoming-grid");
        }
    }
}