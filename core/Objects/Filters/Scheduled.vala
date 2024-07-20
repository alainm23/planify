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

public class Objects.Filters.Scheduled : Objects.BaseObject {
    private static Scheduled? _instance;
    public static Scheduled get_default () {
        if (_instance == null) {
            _instance = new Scheduled ();
        }

        return _instance;
    }

    int? _scheduled_count = null;
    public int scheduled_count {
        get {
            if (_scheduled_count == null) {
                _scheduled_count = Services.Store.instance ().get_items_by_scheduled (false).size;
            }

            return _scheduled_count;
        }

        set {
            _scheduled_count = value;
        }
    }

    public signal void scheduled_count_updated ();

    construct {
        name = _("Scheduled");
        keywords = "%s;%s;%s".printf (_("scheduled"), _("upcoming"), _("filters"));
        icon_name = "month-symbolic";
        view_id = FilterType.SCHEDULED.to_string ();

        Services.Store.instance ().item_added.connect (() => {
            _scheduled_count = Services.Store.instance ().get_items_by_scheduled (false).size;
            scheduled_count_updated ();
        });

        Services.Store.instance ().item_deleted.connect (() => {
            _scheduled_count = Services.Store.instance ().get_items_by_scheduled (false).size;
            scheduled_count_updated ();
        });

        Services.Store.instance ().item_updated.connect (() => {
            _scheduled_count = Services.Store.instance ().get_items_by_scheduled (false).size;
            scheduled_count_updated ();
        });

        Services.Store.instance ().item_archived.connect (() => {
            _scheduled_count = Services.Store.instance ().get_items_by_scheduled (false).size;
            scheduled_count_updated ();
        });

        Services.Store.instance ().item_unarchived.connect (() => {
            _scheduled_count = Services.Store.instance ().get_items_by_scheduled (false).size;
            scheduled_count_updated ();
        });
    }
}
