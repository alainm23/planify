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

public class Objects.Filters.Unlabeled : Objects.BaseObject {
    private static Unlabeled? _instance;
    public static Unlabeled get_default () {
        if (_instance == null) {
            _instance = new Unlabeled ();
        }

        return _instance;
    }

    construct {
        name = _("Unlabeled");
        keywords = "%s;%s;%s".printf (_("no label"), _("unlabeled"), _("filters"));
        icon_name = "tag-outline-remove-symbolic";
        view_id = "unlabeled-view";
    }
}
