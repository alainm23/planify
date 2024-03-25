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

public class Objects.Filters.Completed : Objects.BaseObject {
    private static Completed? _instance;
    public static Completed get_default () {
        if (_instance == null) {
            _instance = new Completed ();
        }

        return _instance;
    }

    string _view_id;
    public string view_id {
        get {
            _view_id = FilterType.COMPLETED.to_string ();
            return _view_id;
        }
    }

    int? _count = null;
    public int count {
        get {
            if (_count == null) {
                _count = Services.Database.get_default ().get_items_completed ().size;
            }

            return _count;
        }

        set {
            _count = value;
        }
    }

    public signal void count_updated ();

    construct {
        name = _("Completed");
        keywords = "%s;%s;%s".printf (_("completed"), _("filter"), _("logbook"));
        icon_name = "check-round-outline-symbolic";

        Services.Database.get_default ().item_added.connect (() => {
            _count = Services.Database.get_default ().get_items_completed ().size;
            count_updated ();
        });

        Services.Database.get_default ().item_deleted.connect (() => {
            _count = Services.Database.get_default ().get_items_completed ().size;
            count_updated ();
        });

        Services.Database.get_default ().item_updated.connect (() => {
            _count = Services.Database.get_default ().get_items_completed ().size;
            count_updated ();
        });
    }
}
