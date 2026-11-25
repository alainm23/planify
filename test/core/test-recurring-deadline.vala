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
 * Recurring Deadline Tests: completing a recurring task moves its deadline to
 * the next occurrence, keeping the same distance in days from the date.
 */

namespace Planify.Tests.RecurringDeadline {
    private const string PROJECT_ID = "recurring-deadline-project";
    private bool database_ready = false;

    private void ensure_database () {
        if (database_ready) {
            return;
        }

        ScratchDatabase.open ();

        var project = new Objects.Project ();
        project.id = PROJECT_ID;
        project.name = "Recurring deadline";
        Services.Store.instance ().insert_project (project);

        database_ready = true;
    }

    private GLib.DateTime local_date (int year, int month, int day, int hour = 0) {
        return new GLib.DateTime.local (year, month, day, hour, 0, 0);
    }

    private Objects.Item make_recurring_item (string id, GLib.DateTime date, RecurrencyType type,
                                              int interval, GLib.DateTime? deadline) {
        ensure_database ();

        var item = new Objects.Item ();
        item.id = id;
        item.content = id;
        item.project_id = PROJECT_ID;
        item.due.date = Utils.Datetime.get_todoist_datetime_format (date);
        item.due.is_recurring = true;
        item.due.recurrency_type = type;
        item.due.recurrency_interval = interval;
        item.deadline_date = deadline == null ? "" : deadline.to_string ();

        Services.Store.instance ().insert_item (item);
        return item;
    }

    // Runs Item.update_next_recurrency (), which is what completing a recurring task does.
    private void complete (Objects.Item item) {
        var loop = new MainLoop ();
        item.update_next_recurrency.begin ((obj, res) => {
            item.update_next_recurrency.end (res);
            loop.quit ();
        });
        loop.run ();
    }

    private string day (GLib.DateTime? datetime) {
        assert_nonnull (datetime);
        return datetime.format ("%Y-%m-%d");
    }

    private void test_monthly_moves_deadline () {
        var item = make_recurring_item ("recurring-deadline-monthly", local_date (2030, 1, 10, 9),
            RecurrencyType.EVERY_MONTH, 1, local_date (2030, 1, 13));

        complete (item);

        assert_cmpstr (day (item.due.datetime), CompareOperator.EQ, "2030-02-10");
        assert_cmpstr (day (item.deadline_datetime), CompareOperator.EQ, "2030-02-13");
    }

    private void test_weekly_moves_deadline () {
        var item = make_recurring_item ("recurring-deadline-weekly", local_date (2030, 1, 10, 9),
            RecurrencyType.EVERY_WEEK, 1, local_date (2030, 1, 12));

        complete (item);

        assert_cmpstr (day (item.due.datetime), CompareOperator.EQ, "2030-01-17");
        assert_cmpstr (day (item.deadline_datetime), CompareOperator.EQ, "2030-01-19");
    }

    private void test_deadline_before_date_keeps_distance () {
        var item = make_recurring_item ("recurring-deadline-before", local_date (2030, 1, 20, 9),
            RecurrencyType.EVERY_DAY, 1, local_date (2030, 1, 18));

        complete (item);

        assert_cmpstr (day (item.due.datetime), CompareOperator.EQ, "2030-01-21");
        assert_cmpstr (day (item.deadline_datetime), CompareOperator.EQ, "2030-01-19");
    }

    private void test_without_deadline_stays_empty () {
        var item = make_recurring_item ("recurring-deadline-none", local_date (2030, 1, 10, 9),
            RecurrencyType.EVERY_DAY, 1, null);

        complete (item);

        assert_cmpstr (day (item.due.datetime), CompareOperator.EQ, "2030-01-11");
        assert_false (item.has_deadline);
    }

    // Weeks around the usual daylight saving changes; counting in days keeps the same weekday.
    private void test_daylight_saving_keeps_day () {
        var autumn = make_recurring_item ("recurring-deadline-dst-autumn", local_date (2030, 10, 22, 9),
            RecurrencyType.EVERY_WEEK, 1, local_date (2030, 10, 24));
        complete (autumn);
        assert_cmpstr (day (autumn.deadline_datetime), CompareOperator.EQ, "2030-10-31");

        var spring = make_recurring_item ("recurring-deadline-dst-spring", local_date (2030, 3, 26, 9),
            RecurrencyType.EVERY_WEEK, 1, local_date (2030, 3, 28));
        complete (spring);
        assert_cmpstr (day (spring.deadline_datetime), CompareOperator.EQ, "2030-04-04");
    }

    private void test_saved_to_database () {
        var item = make_recurring_item ("recurring-deadline-saved", local_date (2030, 1, 10, 9),
            RecurrencyType.EVERY_MONTH, 1, local_date (2030, 1, 13));

        complete (item);

        var stored = Services.Database.get_default ().get_item_by_id (item.id);
        assert_nonnull (stored);
        assert_cmpstr (day (stored.deadline_datetime), CompareOperator.EQ, "2030-02-13");
    }

    public void register_tests () {
        Test.add_func ("/core/recurring_deadline/monthly", test_monthly_moves_deadline);
        Test.add_func ("/core/recurring_deadline/weekly", test_weekly_moves_deadline);
        Test.add_func ("/core/recurring_deadline/before_date", test_deadline_before_date_keeps_distance);
        Test.add_func ("/core/recurring_deadline/without_deadline", test_without_deadline_stays_empty);
        Test.add_func ("/core/recurring_deadline/daylight_saving", test_daylight_saving_keeps_day);
        Test.add_func ("/core/recurring_deadline/saved_to_database", test_saved_to_database);
    }
}
