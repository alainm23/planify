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
    private static TimeMonitor ? _instance;
    public static TimeMonitor get_default () {
        if (_instance == null) {
            _instance = new TimeMonitor ();
        }

        return _instance;
    }

    private DateTime last_registered_date;
    private uint timeout_id = 0;

    public void init_timeout () {
        last_registered_date = new DateTime.now_local ();
        schedule_next_check ();
    }

    private void schedule_next_check () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
        }

        uint interval = calculate_seconds_until_midnight ();
        timeout_id = Timeout.add_seconds (interval, on_timeout);
    }

    private bool on_timeout () {
        DateTime now = new DateTime.now_local ();

        if (now.get_day_of_month () != last_registered_date.get_day_of_month () ||
            now.get_month () != last_registered_date.get_month () ||
            now.get_year () != last_registered_date.get_year ()) {

            Services.EventBus.get_default ().day_changed ();
            Services.Notification.get_default ().regresh ();

            last_registered_date = now;
        }

        schedule_next_check ();
        return false;
    }

    private uint calculate_seconds_until_midnight () {
        DateTime now = new DateTime.now_local ();

        uint value = (24 * 60 * 60) -
                     (now.get_hour () * 60 * 60 + now.get_minute () * 60 + now.get_second ());

        return value;
    }
}
