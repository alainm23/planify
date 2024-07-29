/*
* Copyright © 2024 Alain M. (https://github.com/alainm23/planify)
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

public class Services.NetworkMonitor : GLib.Object {
    static GLib.Once<Services.NetworkMonitor> _instance;
    public static unowned Services.NetworkMonitor instance () {
        return _instance.once (() => {
            return new Services.NetworkMonitor ();
        });
    }

    bool? _network_available = null;
    public bool network_available {
        get {
            if (_network_available == null) {
                _network_available = !is_disconnected ();
            }

            return _network_available;
        }
    }

    public signal void network_changed ();

    construct {
        var network_monitor = GLib.NetworkMonitor.get_default ();
		network_monitor.network_changed.connect (() => {
            _network_available = !is_disconnected ();
            network_changed ();
		});
    }

    public bool is_disconnected () {
        var host = "www.google.com";

        try {
            var resolver = GLib.Resolver.get_default ();
            var addresses = resolver.lookup_by_name (host, null);
            var address = addresses.nth_data (0);
            if (address == null) {
                return false;
            }
        } catch (Error e) {
            debug ("%s\n", e.message);
            return true;
        }

        return false;
    }
}