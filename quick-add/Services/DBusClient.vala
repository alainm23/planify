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

[DBus (name = "io.github.alainm23.planify")]
public interface DBusClientInterface : Object {
    public abstract void add_item (string id) throws Error;
}

public class DBusClient : Object {
    public DBusClientInterface ? interface = null;

    private static GLib.Once<DBusClient> instance;
    public static unowned DBusClient get_default () {
        return instance.once (() => { return new DBusClient (); });
    }

    construct {
        try {
            interface = Bus.get_proxy_sync (
                BusType.SESSION,
                "io.github.alainm23.planify",
                "/io/github/alainm23/planify");
        } catch (IOError e) {
            error ("Monitor Indicator DBus: %s\n", e.message);
        }
    }
}
