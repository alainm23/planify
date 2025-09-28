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

		Timeout.add_seconds (300, () => {
			check_day_change ();
			return true;
		});
	}

	private void check_day_change () {
		DateTime now = new DateTime.now_local ();

		if (now.get_day_of_month () != last_registered_date.get_day_of_month () ||
		    now.get_month () != last_registered_date.get_month () ||
		    now.get_year () != last_registered_date.get_year ()) {

			Services.EventBus.get_default ().day_changed ();
			Services.Notification.get_default ().regresh ();

			last_registered_date = now;
		}
	}
}
