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

public class Dialogs.ProductivityReport.SummarySection : Adw.Bin {
    public signal void see_more_clicked ();

    private Dialogs.ProductivityReport.StatCard total_card;
    private Dialogs.ProductivityReport.StatCard pending_card;
    private Dialogs.ProductivityReport.StatCard completed_card;
    private Dialogs.ProductivityReport.StatCard overdue_card;
    private Gtk.Label progress_value_label;
    private Gtk.LevelBar progress_bar;

    construct {
        var title_label = new Gtk.Label (_("Summary")) {
            halign = START,
            css_classes = { "font-bold" }
        };

        var see_more_button = new Gtk.Button.with_label (_("See More")) {
            halign = END,
            valign = CENTER,
            hexpand = true,
            visible = false,
            css_classes = { "flat", "caption" }
        };

        see_more_button.clicked.connect (() => {
            see_more_clicked ();
        });

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true
        };
        header_box.append (title_label);
        header_box.append (see_more_button);

        total_card = new Dialogs.ProductivityReport.StatCard ("0", _("Total"));
        pending_card = new Dialogs.ProductivityReport.StatCard ("0", _("Pending"));
        completed_card = new Dialogs.ProductivityReport.StatCard ("0", _("Completed"));
        overdue_card = new Dialogs.ProductivityReport.StatCard ("0", _("Overdue"));

        var cards_grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 12,
            column_homogeneous = true,
            hexpand = true
        };

        cards_grid.attach (total_card, 0, 0);
        cards_grid.attach (pending_card, 1, 0);
        cards_grid.attach (completed_card, 2, 0);
        cards_grid.attach (overdue_card, 3, 0);

        var progress_label = new Gtk.Label (_("Progress")) {
            halign = START,
            css_classes = { "caption" }
        };

        progress_value_label = new Gtk.Label ("0%") {
            halign = END,
            hexpand = true,
            css_classes = { "caption", "dimmed" }
        };

        var progress_header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        progress_header.append (progress_label);
        progress_header.append (progress_value_label);

        progress_bar = new Gtk.LevelBar () {
            min_value = 0.0,
            max_value = 1.0,
            value = 0.0
        };

        var progress_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12
        };
        progress_content.append (progress_header);
        progress_content.append (progress_bar);

        var progress_card = new Adw.Bin () {
            css_classes = { "card" },
            child = progress_content
        };

        var section_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
        section_box.append (header_box);
        section_box.append (cards_grid);
        section_box.append (progress_card);

        child = section_box;

        map.connect (() => {
            Timeout.add (200, () => {
                load_stats ();
                return GLib.Source.REMOVE;
            });
        });
    }

    private void load_stats () {
        int total = 0;
        int pending = 0;
        int completed = 0;

        foreach (Objects.Item item in Services.Store.instance ().items) {
            if (item.was_archived ()) {
                continue;
            }

            total++;
            if (item.checked) {
                completed++;
            } else {
                pending++;
            }
        }

        int overdue = Services.Store.instance ().get_items_by_overdue_view (false).size;
        double progress = total > 0 ? (double) completed / (double) total : 0.0;

        total_card.animate_to (total);
        pending_card.animate_to (pending);
        completed_card.animate_to (completed);
        overdue_card.animate_to (overdue);

        var progress_target = new Adw.CallbackAnimationTarget ((val) => {
            progress_bar.value = val;
            progress_value_label.label = "%d%%".printf ((int) Math.round (val * 100));
        });

        var progress_animation = new Adw.TimedAnimation (
            progress_bar, 0, progress, 800,
            progress_target
        ) {
            easing = Adw.Easing.EASE_OUT_CUBIC
        };

        progress_animation.play ();
    }
}
