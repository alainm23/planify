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

[DBus (name = "com.github.alainm23.planner")]
public class Services.DBusServer : Object {
    private const string DBUS_NAME = "com.github.alainm23.planner";
    private const string DBUS_PATH = "/com/github/alainm23/planner";

    private static GLib.Once<DBusServer> instance;

    public static unowned DBusServer get_default () {
        return instance.once (() => { return new DBusServer (); });
    }

    public signal void item_added (int64 id);

    construct {
        Bus.own_name (
            BusType.SESSION,
            DBUS_NAME,
            BusNameOwnerFlags.NONE,
            (connection) => on_bus_aquired (connection),
            () => { },
            null
        );
    }

    public void add_item (int64 id) throws IOError, DBusError {
        item_added (id);
    }

    public bool settings_get_boolean (string key) throws IOError, DBusError {
        return Planner.settings.get_boolean (key);
    }
    
    private void on_bus_aquired (DBusConnection conn) {
        try {
            conn.register_object (DBUS_PATH, get_default ());
        } catch (Error e) {
            error (e.message);
        }
    }
}

[DBus (name = "com.github.alainm23.planner")]
public errordomain DBusServerError {
    SOME_ERROR
}
