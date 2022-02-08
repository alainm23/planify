/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Services.Badge : GLib.Object {
    private static Badge? _instance;
    public static Badge get_default () {
        if (_instance == null) {
            _instance = new Badge ();
        }

        return _instance;
    }

    int? _badge_count = null;
    public int badge_count {
        get {
            if (_badge_count == null) {
                _badge_count = get_badge_count_size ();
            }

            return _badge_count;
        }

        set {
            _badge_count = value;
        }
    }

    public void init () {
        update_badge ();
    }

    public void update_badge () {
        if (badge_visible ()) {
            update_badge_count ();
        }
     }

    private bool badge_visible (bool visible = Planner.settings.get_enum ("badge-count") != 0) {
        Granite.Services.Application.set_badge_visible.begin (visible, (obj, res) => {
            try {
                Granite.Services.Application.set_badge_visible.end (res);
            } catch (GLib.Error e) {
                critical (e.message);
            }
        });

        return visible;
    }

    private void update_badge_count () {
        Granite.Services.Application.set_badge.begin (badge_count, (obj, res) => {
            try {
                if (Granite.Services.Application.set_badge.end (res)) {
                    badge_visible (badge_count > 0);
                }
            } catch (GLib.Error e) {
                critical (e.message);
            }
        });
    }

    private int get_badge_count_size () {
        int count = 0;
        int badge_count = Planner.settings.get_enum ("badge-count");
        if (badge_count == 1) {
            count = Planner.database.get_project (Planner.settings.get_int64 ("inbox-project-id"))
                .project_count;
        } else if (badge_count == 2) {
            count = Planner.database.get_items_by_date (new GLib.DateTime.now_local (), false).size;
        } else if (badge_count == 3) {
            
        }

        return count;
    }
}