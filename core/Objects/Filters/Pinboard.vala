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

public class Objects.Filters.Pinboard : Objects.BaseObject {
    private static Pinboard? _instance;
    public static Pinboard get_default () {
        if (_instance == null) {
            _instance = new Pinboard ();
        }

        return _instance;
    }

    int? _pinboard_count = null;
    public int pinboard_count {
        get {
            if (_pinboard_count == null) {
                _pinboard_count = Services.Store.instance ().get_items_pinned (false).size;
            }

            return _pinboard_count;
        }

        set {
            _pinboard_count = value;
        }
    }

    public signal void pinboard_count_updated ();

    construct {
        name = ("Pinboard");
        keywords = _("Pinboard") + ";" + _("filters");
        icon_name = "pin-symbolic";
        view_id = FilterType.PINBOARD.to_string ();

        Services.Store.instance ().item_added.connect (() => {
            _pinboard_count = Services.Store.instance ().get_items_pinned (false).size;
            pinboard_count_updated ();
        });

        Services.Store.instance ().item_deleted.connect (() => {
            _pinboard_count = Services.Store.instance ().get_items_pinned (false).size;
            pinboard_count_updated ();
        });

        Services.Store.instance ().item_updated.connect (() => {
            _pinboard_count = Services.Store.instance ().get_items_pinned (false).size;
            pinboard_count_updated ();
        });
        
        Services.Store.instance ().item_archived.connect (() => {
            _pinboard_count = Services.Store.instance ().get_items_pinned (false).size;
            pinboard_count_updated ();
        });

        Services.Store.instance ().item_unarchived.connect (() => {
            _pinboard_count = Services.Store.instance ().get_items_pinned (false).size;
            pinboard_count_updated ();
        });
    }
}
