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

public class Services.ProductivityService : Object {
    private static ProductivityService? _instance = null;
    public static ProductivityService instance () {
        if (_instance == null) {
            _instance = new ProductivityService ();
        }
        return _instance;
    }

    public signal void stats_changed ();

    public int completed_today { get; private set; default = 0; }
    public int completed_week { get; private set; default = 0; }
    public int completed_month { get; private set; default = 0; }
    public int daily_goal { get; private set; default = 0; }
    public int weekly_goal { get; private set; default = 0; }
    public bool use_dynamic { get; private set; default = false; }

    public double daily_progress {
        get { return daily_goal > 0 ? (double) completed_today / daily_goal : 0.0; }
    }

    public double weekly_progress {
        get { return weekly_goal > 0 ? (double) completed_week / weekly_goal : 0.0; }
    }

    construct {
        Services.Store.instance ().item_added.connect ((item, _) => { recalculate (); });
        Services.Store.instance ().item_deleted.connect ((item) => { recalculate (); });
        Services.Store.instance ().item_archived.connect ((item) => { recalculate (); });
        Services.Store.instance ().item_unarchived.connect ((item) => { recalculate (); });
        Services.Store.instance ().item_updated.connect ((item, _) => { recalculate (); });
        Services.Store.instance ().project_updated.connect ((project) => { recalculate (); });

        Services.EventBus.get_default ().checked_toggled.connect ((item, _) => { recalculate (); });

        var settings = Services.Settings.get_default ().settings;
        settings.changed["daily-task-goal"].connect (recalculate);
        settings.changed["weekly-task-goal"].connect (recalculate);
        settings.changed["use-dynamic-goal"].connect (recalculate);
        settings.changed["start-week"].connect (recalculate);
    }

    public void recalculate () {
        var now = new GLib.DateTime.now_local ();
        var today = Utils.Datetime.get_date_only (now);

        int start_of_week_day = Services.Settings.get_default ().settings.get_enum ("start-week");
        var week_start = get_week_start (today, start_of_week_day);
        var month_start = new GLib.DateTime.local (now.get_year (), now.get_month (), 1, 0, 0, 0);

        int c_today = 0;
        int c_week = 0;
        int c_month = 0;

        foreach (Objects.Item item in Services.Store.instance ().items) {
            if (!item.checked || item.completed_at == "" || item.was_archived ()) continue;

            var completed_date = Utils.Datetime.get_date_from_string (item.completed_at);
            if (completed_date == null) continue;

            var d = Utils.Datetime.get_date_only (completed_date);

            if (d.compare (today) == 0) c_today++;
            if (d.compare (week_start) >= 0 && d.compare (today) <= 0) c_week++;
            if (d.compare (month_start) >= 0 && d.compare (today) <= 0) c_month++;
        }

        completed_today = c_today;
        completed_week = c_week;
        completed_month = c_month;

        use_dynamic = Services.Settings.get_default ().settings.get_boolean ("use-dynamic-goal");

        if (use_dynamic) {
            daily_goal = Services.Store.instance ().get_items_by_date (today, false).size
                       + Services.Store.instance ().get_items_by_date (today, true).size;
            weekly_goal = Services.Store.instance ().get_items_by_date_range (week_start, today, false).size
                        + Services.Store.instance ().get_items_by_date_range (week_start, today, true).size;
        } else {
            daily_goal = Services.Settings.get_default ().settings.get_int ("daily-task-goal");
            weekly_goal = Services.Settings.get_default ().settings.get_int ("weekly-task-goal");
        }

        stats_changed ();
    }

    public bool has_goals () {
        var settings = Services.Settings.get_default ().settings;
        return settings.get_boolean ("use-dynamic-goal") ||
               settings.get_int ("daily-task-goal") > 0 ||
               settings.get_int ("weekly-task-goal") > 0;
    }

    private GLib.DateTime get_week_start (GLib.DateTime date, int start_day) {
        int current_dow = date.get_day_of_week ();
        int target_dow = start_day == 0 ? 7 : start_day;
        int diff = current_dow - target_dow;
        if (diff < 0) diff += 7;
        return Utils.Datetime.get_date_only (date.add_days (-diff));
    }
}
