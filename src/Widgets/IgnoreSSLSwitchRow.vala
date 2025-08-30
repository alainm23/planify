/*
 * Copyright © 2025 Alain M. (https://github.com/alainm23/planify)
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

public class Widgets.IgnoreSSLSwitchRow : Adw.ActionRow {
    private Gtk.Switch toggle;

    public bool active {
        get { return toggle.active; }
        set { toggle.active = value; }
    }

    public IgnoreSSLSwitchRow () {
        title = _("Disable SSL certificate validation");
        subtitle = _("Not recommended – exposes you to security risks");

        toggle = new Gtk.Switch () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END
        };

        add_suffix (toggle);
        activatable_widget = toggle;

        toggle.state_set.connect ((state) => {
            if (state) {
                var dialog = new Adw.AlertDialog (
                    _("Warning"),
                    _("This will disable SSL validation and exposes you to attacks.\nProceed at your own risk")
                );
                dialog.add_response ("cancel", _("Cancel"));
                dialog.add_response ("accept", _("Continue Anyway"));
                dialog.set_response_appearance ("accept", Adw.ResponseAppearance.DESTRUCTIVE);

                dialog.response.connect ((response) => {
                    if (response == "accept") {
                            toggle.state = true;
                            toggle.active = true;
                        } else {
                            toggle.state = false;
                            toggle.active = false;
                        }
                });

                dialog.present (Planify._instance.main_window);
                return true; // prevent immediate state change
            }
            return false;
        });

    }
}

