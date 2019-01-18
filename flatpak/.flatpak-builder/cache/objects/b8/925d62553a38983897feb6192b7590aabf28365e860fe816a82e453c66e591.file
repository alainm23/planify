// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2015 elementary LLC
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Mario Guerriero <marioguerriero33@gmail.com>
 *              pantor
 */

namespace Maya.Services {

public class ParsedEvent : GLib.Object {

    public string title;
    public string location;
    public string participants;
    public DateTime from;
    public DateTime to;
    public bool all_day;

    public ParsedEvent (string _title = "", DateTime? _from = null, DateTime? _to = null, string _location = "", bool _all_day = false, string _participants = "") {
        this.title = _title;
        this.location = _location;
        this.participants = _participants;
        this.from = _from;
        this.to = _to;
        this.all_day = _all_day;
    }

    public void set_length_to_minutes (int minutes) {
        this.to = this.from.add_minutes (minutes);
    }

    public void set_length_to_hours (int hours) {
        this.to = this.from.add_hours (hours);
    }

    public void set_length_to_days (int days) {
        this.to = this.from.add_days (days);
    }

    public void set_length_to_weeks (int weeks) {
        this.to = this.from.add_days (7 * weeks);
    }

    public void from_set_second (int second) {
        this.from = this.from.add_seconds (second - this.from.get_second ());
    }

    public void to_set_second (int second) {
        this.to = this.to.add_seconds (second - this.to.get_second ());
    }

    public void from_set_minute (int minute) {
        this.from = this.from.add_minutes (minute - this.from.get_minute ());
    }

    public void to_set_minute (int minute) {
        this.to = this.to.add_minutes (minute - this.to.get_minute ());
    }

    private int hour_from_half (int hour, string half) {
        if (hour > 12) {
            return hour;
        }

        if (half == "pm") {
            return hour + 12;
        }

        if (half == "p") {
            return hour + 12;
        }

        if (half == "") {
            if (hour < 8) {
                hour += 12;
            }
        }

        return hour;
    }

    public void from_set_hour (int hour, string half = "") {
        hour = hour_from_half (hour, half);
        this.from = this.from.add_hours (hour - this.from.get_hour ());
    }

    public void to_set_hour (int hour, string half = "") {
        hour = hour_from_half (hour, half);
        this.to = this.to.add_hours (hour - this.to.get_hour ());
    }

    public void from_set_day (int day) {
        if (day > 0) {
            this.from = this.from.add_days (day - this.from.get_day_of_month ());
        }
    }

    public void to_set_day (int day) {
        if (day > 0) {
            this.to = this.to.add_days (day - this.to.get_day_of_month ());
        }
    }

    public void from_set_month (int month) {
        if (month > 0) {
            this.from = this.from.add_months (month - this.from.get_month ());
        }
    }

    public void to_set_month (int month) {
        if (month > 0) {
            this.to = this.to.add_months (month - this.to.get_month ());
        }
    }

    public void from_set_year (int year) {
        if (year > 0) {
            this.from = this.from.add_years (year - this.from.get_year ());
        }
    }

    public void to_set_year (int year) {
        if (year > 0) {
            this.to = this.to.add_years (year - this.to.get_year ());
        }
    }

    public void set_all_day () {
        this.from = this.from.add_hours (-this.from.get_hour () ).add_minutes (-this.from.get_minute ());
        this.to = this.to.add_hours (-this.to.get_hour ()).add_minutes (-this.to.get_minute ());
        this.all_day = true;
    }

    public void unset_all_day () {
        this.set_length_to_hours (1);
        this.all_day = false;
    }

    public void set_one_entire_day () {
        this.from = this.from.add_hours (-this.from.get_hour ()).add_minutes (-this.from.get_minute ());
        this.to = this.from;
        this.all_day = true;
    }

    public void if_elapsed_delay_to_next_day (DateTime simulated_dt) {
        if (this.from.compare (simulated_dt) < 0) {
            this.from = this.from.add_days (1);
            this.to = this.to.add_days (1);
        }
    }

    public void if_elapsed_delay_to_next_week (DateTime simulated_dt) {
        if (this.from.compare (simulated_dt) < 0) {
            this.from = this. from.add_days (7);
            this.to = this.to.add_days (7);
        }
    }

    public void if_elapsed_delay_to_next_month (DateTime simulated_dt) {
        if (this.from.compare (simulated_dt) < 0) {
            this.from = this.from.add_months (1);
            this.to = this.to.add_months (1);
        }
    }

    public void if_elapsed_delay_to_next_year (DateTime simulated_dt) {
        if (this.from.compare (simulated_dt) < 0) {
            this.from = this.from.add_years (1);
            this.to = this.to.add_years (1);
        }
    }
}

}
