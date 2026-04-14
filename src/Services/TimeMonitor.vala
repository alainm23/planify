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

public class Services.TimeMonitor : Object {
    private static TimeMonitor? _instance;
    public static TimeMonitor get_default () {
        if (_instance == null) {
            _instance = new TimeMonitor ();
        }

        return _instance;
    }

    private DateTime last_registered_date;

    public void init_timeout () {
        last_registered_date = new DateTime.now_local ();
        Services.LogService.get_default ().info ("TimeMonitor", "Initialized, tracking date: %s".printf (last_registered_date.format ("%Y-%m-%d")));

        // Periodic check every 5 minutes as fallback
        Timeout.add_seconds (300, () => {
            check_day_change ();
            return true;
        });

        // Listen for system resume from suspend via logind
        listen_for_system_resume ();
    }

    private void listen_for_system_resume () {
        try {
            var connection = GLib.Bus.get_sync (GLib.BusType.SYSTEM);
            connection.signal_subscribe (
                "org.freedesktop.login1",
                "org.freedesktop.login1.Manager",
                "PrepareForSleep",
                "/org/freedesktop/login1",
                null,
                GLib.DBusSignalFlags.NONE,
                (conn, sender, path, iface, signal_name, parameters) => {
                    bool going_to_sleep;
                    parameters.get ("(b)", out going_to_sleep);

                    if (going_to_sleep) {
                        Services.LogService.get_default ().info ("TimeMonitor", "System going to sleep");
                    } else {
                        Services.LogService.get_default ().info ("TimeMonitor", "System resumed from sleep, checking day change");
                        check_day_change ();
                    }
                }
            );
            Services.LogService.get_default ().info ("TimeMonitor", "Subscribed to logind PrepareForSleep signal");
        } catch (Error e) {
            Services.LogService.get_default ().warn ("TimeMonitor", "Could not subscribe to logind PrepareForSleep: %s".printf (e.message));
        }
    }

    private void check_day_change () {
        DateTime now = new DateTime.now_local ();
        Services.LogService.get_default ().debug ("TimeMonitor", "Checking day change: last=%s now=%s".printf (last_registered_date.format ("%Y-%m-%d"), now.format ("%Y-%m-%d")));

        if (now.get_day_of_month () != last_registered_date.get_day_of_month () ||
            now.get_month () != last_registered_date.get_month () ||
            now.get_year () != last_registered_date.get_year ()) {

            Services.LogService.get_default ().info ("TimeMonitor", "Day changed from %s to %s".printf (last_registered_date.format ("%Y-%m-%d"), now.format ("%Y-%m-%d")));
            Services.EventBus.get_default ().day_changed ();
            Services.Notification.get_default ().regresh ();

            last_registered_date = now;
        }
    }
}
