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

public class Dialogs.ProductivityReport.StatCard : Adw.Bin {
    private Gtk.Label _value_label;
    private Gtk.Label _description_label;

    public string stat_value {
        get { return _value_label.label; }
        set { _value_label.label = value; }
    }

    public string stat_label { get; construct; }

    public StatCard (string stat_value, string stat_label) {
        Object (
            stat_label: stat_label
        );

        this.stat_value = stat_value;
    }

    construct {
        _value_label = new Gtk.Label ("0") {
            css_classes = { "font-bold", "title-1" },
            halign = CENTER
        };

        _description_label = new Gtk.Label (stat_label) {
            css_classes = { "caption", "dimmed" },
            halign = CENTER
        };

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 4) {
            halign = FILL,
            valign = CENTER,
            margin_top = 16,
            margin_bottom = 16,
            margin_start = 8,
            margin_end = 8
        };

        box.append (_value_label);
        box.append (_description_label);

        css_classes = { "card" };
        child = box;
    }

    public void animate_to (int target, uint duration = 600) {
        var animation_target = new Adw.CallbackAnimationTarget ((val) => {
            _value_label.label = ((int) Math.round (val)).to_string ();
        });

        var animation = new Adw.TimedAnimation (
            this, 0, target, duration,
            animation_target
        ) {
            easing = Adw.Easing.EASE_OUT_CUBIC
        };

        animation.play ();
    }
}
