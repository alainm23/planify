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

public class Widgets.ProductivityMiniWidget : Gtk.Button {
    private Gtk.Label title_label;
    private Gtk.Label subtitle_label;
    private Widgets.CircularProgressBar progress_circle;

    construct {
        css_classes = { "flat", "menu-item" };
        hexpand = true;

        title_label = new Gtk.Label (_("Daily Goal")) {
            halign = START,
            css_classes = { "caption", "font-bold" }
        };

        subtitle_label = new Gtk.Label (null) {
            halign = START,
            css_classes = { "caption", "dimmed" }
        };

        var text_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 1) {
            valign = CENTER,
            hexpand = true
        };
        text_box.append (title_label);
        text_box.append (subtitle_label);

        progress_circle = new Widgets.CircularProgressBar (32) {
            thick_style = true,
            valign = CENTER
        };

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 6
        };
        box.append (text_box);
        box.append (progress_circle);

        child = box;

        map.connect (() => {
            Services.ProductivityService.instance ().recalculate ();
        });

        Services.ProductivityService.instance ().stats_changed.connect (refresh);
    }

    public void refresh () {
        var svc = Services.ProductivityService.instance ();

        if (svc.daily_goal <= 0 && !svc.use_dynamic) return;

        if (svc.use_dynamic) {
            subtitle_label.label = svc.daily_goal <= 0
                ? _("No tasks scheduled")
                : "%d / %d %s".printf (svc.completed_today, svc.daily_goal, _("(scheduled)"));
        } else {
            subtitle_label.label = "%d / %d tasks".printf (svc.completed_today, svc.daily_goal);
        }

        progress_circle.percentage = double.min (1.0, svc.daily_progress);
    }
}
