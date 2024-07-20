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
    private static Today? _instance;
    public static Today get_default () {
        if (_instance == null) {
            _instance = new Today ();
        }

        return _instance;
    }

    int? _today_count = null;
    public int today_count {
        get {
            if (_today_count == null) {
                _today_count = Services.Store.instance ().get_items_by_date (
                    new GLib.DateTime.now_local (), false).size;
            }

            return _today_count;
        }

        set {
            _today_count = value;
        }
    }

    int? _overdeue_count = null;
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

    public signal void today_count_updated ();

    construct {
        name = _("Today");
        keywords = _("today") + ";" + _("filters");
        icon_name = "star-outline-thick-symbolic";
        view_id = FilterType.TODAY.to_string ();

        Services.Store.instance ().item_added.connect (() => {
            _today_count = Services.Store.instance ().get_items_by_date (
                new GLib.DateTime.now_local (), false).size;
            _overdeue_count = Services.Store.instance ().get_items_by_overdeue_view (false).size;
            today_count_updated ();
        });

        Services.Store.instance ().item_deleted.connect (() => {
            _today_count = Services.Store.instance ().get_items_by_date (
                new GLib.DateTime.now_local (), false).size;
            _overdeue_count = Services.Store.instance ().get_items_by_overdeue_view (false).size;
            today_count_updated ();
        });

        Services.Store.instance ().item_archived.connect (() => {
            _today_count = Services.Store.instance ().get_items_by_date (
                new GLib.DateTime.now_local (), false).size;
            _overdeue_count = Services.Store.instance ().get_items_by_overdeue_view (false).size;
            today_count_updated ();
        });

        Services.Store.instance ().item_unarchived.connect (() => {
            _today_count = Services.Store.instance ().get_items_by_date (
                new GLib.DateTime.now_local (), false).size;
            _overdeue_count = Services.Store.instance ().get_items_by_overdeue_view (false).size;
            today_count_updated ();
        });

        Services.Store.instance ().item_updated.connect (() => {
            _today_count = Services.Store.instance ().get_items_by_date (
                new GLib.DateTime.now_local (), false).size;
            _overdeue_count = Services.Store.instance ().get_items_by_overdeue_view (false).size;
            today_count_updated ();
        });
    }
}
