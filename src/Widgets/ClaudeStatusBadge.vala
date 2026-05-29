/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

public class Widgets.ClaudeStatusBadge : Adw.Bin {
    private Gtk.Image dot;

    ~ClaudeStatusBadge () {
        debug ("Destroying Widgets.ClaudeStatusBadge\n");
    }

    construct {
        dot = new Gtk.Image () {
            pixel_size = 16,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER
        };
        child = dot;

        update_from_status (Services.AI.Claude.get_default ().status);

        Services.AI.Claude.get_default ().status_changed.connect (() => {
            update_from_status (Services.AI.Claude.get_default ().status);
        });
    }

    private void update_from_status (Services.AI.Claude.Status status) {
        dot.remove_css_class ("success");
        dot.remove_css_class ("warning");
        dot.remove_css_class ("error");

        switch (status) {
            case Services.AI.Claude.Status.CONFIGURED:
                dot.icon_name = "emblem-ok-symbolic";
                dot.add_css_class ("success");
                dot.tooltip_text = _("Claude is ready");
                break;
            case Services.AI.Claude.Status.NOT_CONFIGURED:
                dot.icon_name = "dialog-warning-symbolic";
                dot.add_css_class ("warning");
                dot.tooltip_text = _("Claude not configured — add API key in Preferences");
                break;
            case Services.AI.Claude.Status.ERROR:
                dot.icon_name = "dialog-error-symbolic";
                dot.add_css_class ("error");
                dot.tooltip_text = Services.AI.Claude.get_default ().last_error;
                break;
            default:
                break;
        }
    }
}
