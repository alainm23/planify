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

public class Objects.Filters.AllItems : Objects.BaseObject {
    private static AllItems ? _instance;
    public static AllItems get_default () {
        if (_instance == null) {
            _instance = new AllItems ();
        }

        return _instance;
    }
    
    construct {
        name = _("All Tasks");
        keywords = "%s;%s".printf (_("all tasks"), _("all"));
        icon_name = "check-round-outline-symbolic";
        view_id = "all-items-view";
        color = Services.Settings.get_default ().settings.get_boolean ("dark-mode") ? "#99c1f1" : "#3584e4";

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
        return Services.Store.instance ().get_items_no_parent (false).size;
    }

    public override void count_update () {
        _item_count = update_count ();
                
        count_updated ();
    }

    public override string theme_color () {
        return Services.Settings.get_default ().get_boolean ("dark-mode") ? "#99c1f1" : "#3584e4";
    }
}
