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

public class Objects.Filters.Inbox : Objects.BaseObject {
    private Objects.Project inbox_project;

    private static Inbox ? _instance;
    public static Inbox get_default () {
        if (_instance == null) {
            _instance = new Inbox ();
        }

        return _instance;
    }

    construct {
        name = _("Inbox");
        keywords = _("inbox") + ";" + _("filters");
        icon_name = "mailbox-symbolic";
        view_id = "inbox";
        color = Services.Settings.get_default ().get_boolean ("dark-mode") ? "#99c1f1" : "#3584e4";
    }

    public override string theme_color () {
        return Services.Settings.get_default ().get_boolean ("dark-mode") ? "#99c1f1" : "#3584e4";
    }
}
