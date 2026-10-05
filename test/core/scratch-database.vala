/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
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
 */

/**
 * The throwaway database the core tests share, under the XDG_DATA_HOME that test/meson.build
 * sets. Whichever test calls open () first creates it empty, so no test depends on another.
 */
namespace Planify.Tests.ScratchDatabase {
    private bool opened = false;

    public void open () {
        if (opened) {
            return;
        }

        // GLib caches the user data dir on first use, so refuse to run rather than open the
        // real database.
        string data_home = Environment.get_variable ("XDG_DATA_HOME");
        if (data_home == null || Environment.get_user_data_dir () != data_home ||
            !data_home.has_suffix ("/test-core-data")) {
            error ("XDG_DATA_HOME must point at the test-core-data scratch dir");
        }

        string app_dir = data_home + "/io.github.alainm23.planify";
        DirUtils.create_with_parents (app_dir, 0700);
        FileUtils.remove (app_dir + "/database.db");
        Services.Database.get_default ().init_database ();

        // Load the Store's collections now, as app startup does; loaded lazily after an insert,
        // they would hold a second copy of that row.
        assert_cmpint (Services.Store.instance ().projects.size, CompareOperator.EQ, 0);
        assert_cmpint (Services.Store.instance ().items.size, CompareOperator.EQ, 0);

        opened = true;
    }

    public string path () {
        return Environment.get_user_data_dir () + "/io.github.alainm23.planify/database.db";
    }
}
