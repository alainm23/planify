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

public class Dialogs.ProductivityReport.HeatMap : Adw.Bin {
    private Gtk.Grid grid;

    private const int CELL_SIZE = 22;
    private const int CELL_SPACING = 4;
    private const int WEEKS = 8;

    construct {
        var day_labels_grid = new Gtk.Grid () {
            row_spacing = CELL_SPACING
        };

        string[] day_names = { _("M"), _("T"), _("W"), _("T"), _("F"), _("S"), _("S") };
        for (int i = 0; i < 7; i++) {
            var label = new Gtk.Label (day_names[i]) {
                css_classes = { "caption", "dimmed" },
                width_request = 14,
                halign = END,
                valign = CENTER,
                height_request = CELL_SIZE
            };
            day_labels_grid.attach (label, 0, i);
        }

        grid = new Gtk.Grid () {
            column_spacing = CELL_SPACING,
            row_spacing = CELL_SPACING
        };

        var heatmap_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8) {
            halign = CENTER
        };
        heatmap_box.append (day_labels_grid);
        heatmap_box.append (grid);

        var title_label = new Gtk.Label (_("Last 8 weeks")) {
            halign = START,
            css_classes = { "caption", "dimmed" },
            margin_bottom = 6
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12
        };
        content_box.append (title_label);
        content_box.append (heatmap_box);

        css_classes = { "card" };
        child = content_box;

        build_cells ();
    }

    private void build_cells () {
        var today = Utils.Datetime.get_date_only (new GLib.DateTime.now_local ());

        int today_dow = today.get_day_of_week (); // 1=Mon, 7=Sun
        var grid_start = today.add_days (- (today_dow - 1) - 49); // Monday 8 weeks ago

        var counts = new Gee.HashMap<string, int> ();
        foreach (Objects.Item item in Services.Store.instance ().items) {
            if (!item.checked || item.completed_at == "" || item.was_archived ()) continue;
            var d = Utils.Datetime.get_date_from_string (item.completed_at);
            if (d == null) continue;
            var key = Utils.Datetime.get_date_only (d).format ("%Y-%m-%d");
            counts[key] = (counts.has_key (key) ? counts[key] : 0) + 1;
        }

        int max_count = 1;
        foreach (var val in counts.values) {
            if (val > max_count) max_count = val;
        }

        for (int col = 0; col < WEEKS; col++) {
            for (int row = 0; row < 7; row++) {
                var cell_date = grid_start.add_days (col * 7 + row);
                var key = cell_date.format ("%Y-%m-%d");
                int count = counts.has_key (key) ? counts[key] : 0;
                bool is_today = cell_date.compare (today) == 0;
                bool is_future = cell_date.compare (today) > 0;

                int level = 0;
                if (!is_future && count > 0) {
                    double intensity = (double) count / max_count;
                    level = (int) Math.ceil (intensity * 4);
                    if (level < 1) level = 1;
                    if (level > 4) level = 4;
                }

                var cell = new Adw.Bin () {
                    width_request = CELL_SIZE,
                    height_request = CELL_SIZE,
                    tooltip_text = "%s — %s".printf (
                        cell_date.format ("%a, %b %d"),
                        ngettext ("%d task", "%d tasks", count).printf (count)
                    )
                };

                cell.add_css_class ("heatmap-cell-%d".printf (level));
                if (is_today) cell.add_css_class ("heatmap-cell-today");

                grid.attach (cell, col, row);
            }
        }
    }

    public void refresh () {
        var child = grid.get_first_child ();
        while (child != null) {
            var next = child.get_next_sibling ();
            grid.remove (child);
            child = next;
        }
        build_cells ();
    }
}
