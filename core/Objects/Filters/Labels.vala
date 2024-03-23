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

public class Objects.Filters.Labels : Objects.BaseObject {
    private static Labels? _instance;
    public static Labels get_default () {
        if (_instance == null) {
            _instance = new Labels ();
        }

        return _instance;
    }

    string _view_id;
    public string view_id {
        get {
            _view_id = FilterType.LABELS.to_string ();
            return _view_id;
        }
    }

    int? _count = null;
    public int count {
        get {
            if (_count == null) {
                _count = Services.Database.get_default ().get_labels_collection ().size;
            }

            return _count;
        }

        set {
            _count = value;
        }
    }

    public signal void count_updated ();

    construct {
        name = _("Labels");
        keywords = "%s".printf (_("labels"));
        icon_name = "tag-outline-symbolic";

        Services.Database.get_default ().label_added.connect (() => {
            _count = Services.Database.get_default ().get_labels_collection ().size;
            count_updated ();
        });

        Services.Database.get_default ().label_deleted.connect (() => {
            _count = Services.Database.get_default ().get_labels_collection ().size;
            count_updated ();
        });

        Services.Database.get_default ().label_updated.connect (() => {
            _count = Services.Database.get_default ().get_labels_collection ().size;
            count_updated ();
        });
    }
}
