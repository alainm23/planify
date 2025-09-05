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

public class Objects.Filters.Today : Objects.BaseObject {
    private static Today ? _instance;
    public static Today get_default () {
        if (_instance == null) {
            _instance = new Today ();
        }

        return _instance;
    }

    int ? _overdeue_count = null;
    public int overdeue_count {
        get {
            if (_overdeue_count == null) {
                _overdeue_count = Services.Store.instance ().get_items_by_overdeue_view (false).size;
            }

            return _overdeue_count;
        }

        set {
            _overdeue_count = value;
        }
    }


    construct {
        name = _("Today");
        keywords = _("today") + ";" + _("filters");
        icon_name = "star-outline-thick-symbolic";
        view_id = "today";
        color = "#33d17a";

        Services.Store.instance ().item_added.connect (() => {
            count_update ();
        });

        Services.Store.instance ().item_deleted.connect (() => {
            count_update ();
        });

        Services.Store.instance ().item_archived.connect (() => {
            count_update ();
        });

        Services.Store.instance ().item_unarchived.connect (() => {
            count_update ();
        });

        Services.Store.instance ().item_updated.connect (() => {
            count_update ();
        });
    }

    public override int update_count () {
        return Services.Store.instance ().get_items_by_date (
            new GLib.DateTime.now_local (), false
        ).size;
    }

    public override void count_update () {
        _item_count = update_count ();
        _overdeue_count = Services.Store.instance ().get_items_by_overdeue_view (false).size;
        
        count_updated ();
    }
}
