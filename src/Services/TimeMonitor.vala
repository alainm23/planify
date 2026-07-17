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
    private uint midnight_timeout_id = 0;

    public void init_timeout () {
        last_registered_date = new DateTime.now_local ();
        Services.LogService.get_default ().info ("TimeMonitor", "Initialized, tracking date: %s".printf (last_registered_date.format ("%Y-%m-%d")));

        schedule_midnight_check ();
        listen_for_system_resume ();
    }

    private void schedule_midnight_check () {
        if (midnight_timeout_id != 0) {
            GLib.Source.remove (midnight_timeout_id);
            midnight_timeout_id = 0;
        }

        var now = new DateTime.now_local ();
        var tomorrow = now.add_days (1);
        var midnight = new DateTime.local (tomorrow.get_year (), tomorrow.get_month (), tomorrow.get_day_of_month (), 0, 0, 0);
        int seconds = (int) (midnight.difference (now) / TimeSpan.SECOND);

        Services.LogService.get_default ().info ("TimeMonitor", "Next day check scheduled in %d seconds".printf (seconds));

        midnight_timeout_id = Timeout.add_seconds (seconds, () => {
            midnight_timeout_id = 0;
            check_day_change ();
            schedule_midnight_check ();
            return GLib.Source.REMOVE;
        });
    }

    private void listen_for_system_resume () {
        // logind via system bus — only works outside Flatpak
        if (!Util.get_default ().is_flatpak ()) {
            try {
                var system_bus = GLib.Bus.get_sync (GLib.BusType.SYSTEM);
                system_bus.signal_subscribe (
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
                            Services.LogService.get_default ().info ("TimeMonitor", "System resumed from sleep (logind), checking day change");
                            check_day_change ();
                            schedule_midnight_check ();
                        }
                    }
                );
                Services.LogService.get_default ().info ("TimeMonitor", "Subscribed to logind PrepareForSleep signal");
            } catch (Error e) {
                Services.LogService.get_default ().warn ("TimeMonitor", "Could not subscribe to logind: %s".printf (e.message));
            }
        }

        // ScreenSaver WakeUpScreen via session bus — only needed in Flatpak
        if (Util.get_default ().is_flatpak ()) {
            try {
                var session_bus = GLib.Bus.get_sync (GLib.BusType.SESSION);
                session_bus.signal_subscribe (
                    "org.gnome.ScreenSaver",
                    "org.gnome.ScreenSaver",
                    "WakeUpScreen",
                    "/org/gnome/ScreenSaver",
                    null,
                    GLib.DBusSignalFlags.NONE,
                    (conn, sender, path, iface, signal_name, parameters) => {
                        Services.LogService.get_default ().info ("TimeMonitor", "Screen woke up (ScreenSaver), checking day change");
                        check_day_change ();
                        schedule_midnight_check ();
                    }
                );
                Services.LogService.get_default ().info ("TimeMonitor", "Subscribed to ScreenSaver WakeUpScreen signal");
            } catch (Error e) {
                Services.LogService.get_default ().warn ("TimeMonitor", "Could not subscribe to ScreenSaver: %s".printf (e.message));
            }
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
