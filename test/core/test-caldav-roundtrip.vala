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

namespace Planify.Tests.CalDAVRoundtrip {
    private string calendar (string properties) {
        return "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//test//EN\r\n" +
            "BEGIN:VTODO\r\nUID:caldav-roundtrip\r\nSUMMARY:Task\r\n" + properties +
            "END:VTODO\r\nEND:VCALENDAR\r\n";
    }

    private Objects.Item read_item (string data) {
        ScratchDatabase.open ();
        return new Objects.Item.from_vtodo (data, "https://example.invalid/task.ics", "roundtrip-project");
    }

    private ICal.Component saved_calendar (Objects.Item item) {
        item.description = "Edited in Planify";
        return ICal.Parser.parse_string (item.to_vtodo ());
    }

    private void test_preserves_relative_reminders () {
        string alarms = "BEGIN:VALARM\r\nTRIGGER;RELATED=END:PT0S\r\n" +
            "ACTION:DISPLAY\r\nDESCRIPTION:When due\r\nEND:VALARM\r\n" +
            "BEGIN:VALARM\r\nTRIGGER:-PT15M\r\nACTION:DISPLAY\r\n" +
            "DESCRIPTION:Before starting\r\nREPEAT:2\r\nDURATION:PT5M\r\nEND:VALARM\r\n";
        string data = calendar ("DTSTART:20301030T130501Z\r\nDUE:20301030T140501Z\r\n" +
            "RRULE:FREQ=DAILY;INTERVAL=1\r\n" + alarms);
        var original = ICal.Parser.parse_string (data).get_first_component (ICal.ComponentKind.VTODO_COMPONENT);
        var saved = saved_calendar (read_item (data)).get_first_component (ICal.ComponentKind.VTODO_COMPONENT);

        var expected = original.get_first_component (ICal.ComponentKind.VALARM_COMPONENT);
        var actual = saved.get_first_component (ICal.ComponentKind.VALARM_COMPONENT);
        while (expected != null) {
            assert_nonnull (actual);
            assert_cmpstr (actual.as_ical_string (), CompareOperator.EQ, expected.as_ical_string ());
            expected = original.get_next_component (ICal.ComponentKind.VALARM_COMPONENT);
            actual = saved.get_next_component (ICal.ComponentKind.VALARM_COMPONENT);
        }
        assert_null (actual);
        assert_cmpstr (saved.get_dtstart ().as_ical_string (), CompareOperator.EQ, "20301030T130501Z");
        assert_cmpstr (saved.get_first_property (ICal.PropertyKind.RRULE_PROPERTY).as_ical_string (),
            CompareOperator.EQ, original.get_first_property (ICal.PropertyKind.RRULE_PROPERTY).as_ical_string ());
        assert_cmpstr (saved.get_description (), CompareOperator.EQ, "Edited in Planify");
    }

    private void test_preserves_due_timezone () {
        var item = read_item (calendar ("DUE;TZID=America/New_York:20301030T140501\r\n"));
        var saved = saved_calendar (item).get_first_component (ICal.ComponentKind.VTODO_COMPONENT);
        var due = saved.get_first_property (ICal.PropertyKind.DUE_PROPERTY);
        var tzid = due.get_first_parameter (ICal.ParameterKind.TZID_PARAMETER);

        assert_nonnull (tzid);
        assert_cmpstr (tzid.get_tzid (), CompareOperator.EQ, "America/New_York");
        assert_cmpstr (due.get_due ().as_ical_string (), CompareOperator.EQ, "20301030T140501");
    }

    private void test_preserves_utc_due () {
        var item = read_item (calendar ("DUE:20301030T140501Z\r\n"));
        var saved = saved_calendar (item).get_first_component (ICal.ComponentKind.VTODO_COMPONENT);
        assert_cmpstr (saved.get_due ().as_ical_string (), CompareOperator.EQ, "20301030T140501Z");
    }

    private void test_reads_due_as_the_correct_instant () {
        var item = read_item (calendar ("DUE;TZID=America/New_York:20301030T140501\r\n"));
        var expected = new GLib.DateTime.from_iso8601 ("2030-10-30T18:05:01Z", null);
        assert_true (item.due.datetime.to_unix () == expected.to_unix ());
    }

    private void test_edits_due_in_its_original_timezone () {
        var item = read_item (calendar ("DUE;TZID=America/New_York:20301030T140501\r\n"));
        var changed = new GLib.DateTime.from_iso8601 ("2030-12-01T20:05:01Z", null);
        item.due.date = changed.to_local ().to_string ();
        var saved = saved_calendar (item).get_first_component (ICal.ComponentKind.VTODO_COMPONENT);
        var due = saved.get_first_property (ICal.PropertyKind.DUE_PROPERTY);
        assert_cmpstr (due.get_first_parameter (ICal.ParameterKind.TZID_PARAMETER).get_tzid (),
            CompareOperator.EQ, "America/New_York");
        assert_cmpstr (due.get_due ().as_ical_string (), CompareOperator.EQ, "20301201T150501");
        var reloaded = read_item (saved_calendar (item).as_ical_string ());
        assert_true (reloaded.due.datetime.to_unix () == changed.to_unix ());
    }

    private void test_edits_utc_due () {
        var item = read_item (calendar ("DUE:20301030T140501Z\r\n"));
        var changed = new GLib.DateTime.from_iso8601 ("2030-12-01T20:05:01Z", null);
        item.due.date = changed.to_local ().to_string ();
        var saved = saved_calendar (item).get_first_component (ICal.ComponentKind.VTODO_COMPONENT);
        var due = saved.get_first_property (ICal.PropertyKind.DUE_PROPERTY);
        assert_null (due.get_first_parameter (ICal.ParameterKind.TZID_PARAMETER));
        assert_cmpstr (due.get_due ().as_ical_string (), CompareOperator.EQ, "20301201T200501Z");
    }

    private void test_converts_timed_due_to_date_only () {
        var item = read_item (calendar ("DUE;TZID=America/New_York:20301030T140501\r\n"));
        item.due.date = new GLib.DateTime.local (2030, 12, 1, 0, 0, 0).to_string ();
        var saved = saved_calendar (item).get_first_component (ICal.ComponentKind.VTODO_COMPONENT);
        var due = saved.get_first_property (ICal.PropertyKind.DUE_PROPERTY);
        assert_cmpstr (due.as_ical_string ().strip (), CompareOperator.EQ, "DUE;VALUE=DATE:20301201");
    }

    private void test_preserves_custom_timezone_definition () {
        string timezone = "BEGIN:VTIMEZONE\r\nTZID:Custom/Office\r\nBEGIN:STANDARD\r\n" +
            "DTSTART:19700101T000000\r\nTZOFFSETFROM:+0230\r\nTZOFFSETTO:+0230\r\n" +
            "END:STANDARD\r\nEND:VTIMEZONE\r\n";
        string data = calendar ("DUE;TZID=Custom/Office:20301030T140501\r\n").replace (
            "BEGIN:VTODO", timezone + "BEGIN:VTODO");
        var item = read_item (data);
        var expected = new GLib.DateTime.from_iso8601 ("2030-10-30T11:35:01Z", null);
        assert_true (item.due.datetime.to_unix () == expected.to_unix ());
        var saved = saved_calendar (item);
        var zone = saved.get_first_component (ICal.ComponentKind.VTIMEZONE_COMPONENT);
        assert_nonnull (zone);
        var original_zone = ICal.Parser.parse_string (data).get_first_component (ICal.ComponentKind.VTIMEZONE_COMPONENT);
        assert_cmpstr (zone.as_ical_string (), CompareOperator.EQ, original_zone.as_ical_string ());
        var due = saved.get_first_component (ICal.ComponentKind.VTODO_COMPONENT).get_first_property (ICal.PropertyKind.DUE_PROPERTY);
        assert_cmpstr (due.get_first_parameter (ICal.ParameterKind.TZID_PARAMETER).get_tzid (), CompareOperator.EQ, "Custom/Office");

        var changed = new GLib.DateTime.from_iso8601 ("2030-12-01T20:05:01Z", null);
        item.due.date = changed.to_local ().to_string ();
        saved = saved_calendar (item);
        due = saved.get_first_component (ICal.ComponentKind.VTODO_COMPONENT).get_first_property (ICal.PropertyKind.DUE_PROPERTY);
        assert_cmpstr (due.as_ical_string ().strip (), CompareOperator.EQ, "DUE;TZID=Custom/Office:20301201T223501");
        var reloaded = read_item (saved.as_ical_string ());
        assert_true (reloaded.due.datetime.to_unix () == changed.to_unix ());
    }

    private void test_preserves_date_only_and_floating_due () {
        string[] properties = {
            "DUE;VALUE=DATE:20301030", "DUE:20301030T140501", "DUE:20301030T000000Z",
            "DUE;TZID=Unknown/Zone:20301030T140501"
        };
        foreach (var property in properties) {
            var item = read_item (calendar (property + "\r\n"));
            var saved = saved_calendar (item).get_first_component (ICal.ComponentKind.VTODO_COMPONENT);
            var due = saved.get_first_property (ICal.PropertyKind.DUE_PROPERTY);
            assert_cmpstr (due.as_ical_string ().strip (), CompareOperator.EQ, property);
        }
    }

    private void test_clearing_due_does_not_restore_it () {
        var item = read_item (calendar ("DUE;TZID=America/New_York:20301030T140501\r\n"));
        item.due.reset ();
        var saved = saved_calendar (item).get_first_component (ICal.ComponentKind.VTODO_COMPONENT);
        assert_null (saved.get_first_property (ICal.PropertyKind.DUE_PROPERTY));
    }

    private void test_relative_reminders_survive_repeated_saves () {
        string data = calendar ("DUE:20301030T140501Z\r\n" +
            "BEGIN:VALARM\r\nTRIGGER;RELATED=END:-PT10M\r\nACTION:DISPLAY\r\n" +
            "DESCRIPTION:Before due\r\nEND:VALARM\r\n");
        var item = read_item (data);
        var first = saved_calendar (item);
        item.extra_data = Util.generate_extra_data (item.ical_url, "", first.as_ical_string ());
        var second = saved_calendar (item).get_first_component (ICal.ComponentKind.VTODO_COMPONENT);
        assert_nonnull (second.get_first_component (ICal.ComponentKind.VALARM_COMPONENT));
        assert_null (second.get_next_component (ICal.ComponentKind.VALARM_COMPONENT));
    }

    private void test_absolute_reminder_edits_preserve_relative_reminders () {
        string data = calendar ("DUE:20301030T140501Z\r\n" +
            "BEGIN:VALARM\r\nTRIGGER;RELATED=END:-PT10M\r\n" +
            "ACTION:DISPLAY\r\nDESCRIPTION:Relative\r\nEND:VALARM\r\n" +
            "BEGIN:VALARM\r\nTRIGGER;VALUE=DATE-TIME:20301030T130501Z\r\n" +
            "ACTION:DISPLAY\r\nDESCRIPTION:Absolute\r\nEND:VALARM\r\n");
        var item = read_item (data);
        var store = Services.Store.instance ();
        var project = new Objects.Project ();
        project.id = item.project_id;
        store.insert_project (project);
        store.insert_item (item);
        assert_cmpint (item.reminders.size, CompareOperator.EQ, 0);
        item.sync_reminders_from_vtodo (ICal.Parser.parse_string (data).get_first_component (ICal.ComponentKind.VTODO_COMPONENT));
        assert_cmpint (item.reminders.size, CompareOperator.EQ, 1);
        var saved = saved_calendar (item).get_first_component (ICal.ComponentKind.VTODO_COMPONENT);
        var relative = saved.get_first_component (ICal.ComponentKind.VALARM_COMPONENT);
        assert_nonnull (relative);
        assert_nonnull (saved.get_next_component (ICal.ComponentKind.VALARM_COMPONENT));
        assert_null (saved.get_next_component (ICal.ComponentKind.VALARM_COMPONENT));

        store.delete_reminder (item.reminders[0]);
        assert_cmpint (item.reminders.size, CompareOperator.EQ, 0);
        var reminder = new Objects.Reminder ();
        reminder.id = "caldav-roundtrip-new-reminder";
        reminder.item_id = item.id;
        reminder.due.date = new GLib.DateTime.from_iso8601 ("2030-10-30T12:05:01Z", null).to_local ().to_string ();
        store.insert_reminder (reminder);

        saved = saved_calendar (item).get_first_component (ICal.ComponentKind.VTODO_COMPONENT);
        var alarm = saved.get_first_component (ICal.ComponentKind.VALARM_COMPONENT);
        assert_cmpstr (alarm.as_ical_string (), CompareOperator.EQ, relative.as_ical_string ());
        alarm = saved.get_next_component (ICal.ComponentKind.VALARM_COMPONENT);
        assert_nonnull (alarm);
        assert_cmpstr (alarm.get_first_property (ICal.PropertyKind.TRIGGER_PROPERTY).get_value_as_string (),
            CompareOperator.EQ, "20301030T120501Z");
        assert_null (saved.get_next_component (ICal.ComponentKind.VALARM_COMPONENT));
        store.delete_reminder (reminder);
    }

    public void register_tests () {
        Test.add_func ("/core/caldav_roundtrip/preserves_relative_reminders", test_preserves_relative_reminders);
        Test.add_func ("/core/caldav_roundtrip/preserves_due_timezone", test_preserves_due_timezone);
        Test.add_func ("/core/caldav_roundtrip/preserves_utc_due", test_preserves_utc_due);
        Test.add_func ("/core/caldav_roundtrip/reads_due_as_the_correct_instant", test_reads_due_as_the_correct_instant);
        Test.add_func ("/core/caldav_roundtrip/edits_due_in_its_original_timezone", test_edits_due_in_its_original_timezone);
        Test.add_func ("/core/caldav_roundtrip/edits_utc_due", test_edits_utc_due);
        Test.add_func ("/core/caldav_roundtrip/converts_timed_due_to_date_only", test_converts_timed_due_to_date_only);
        Test.add_func ("/core/caldav_roundtrip/preserves_custom_timezone_definition", test_preserves_custom_timezone_definition);
        Test.add_func ("/core/caldav_roundtrip/preserves_date_only_and_floating_due", test_preserves_date_only_and_floating_due);
        Test.add_func ("/core/caldav_roundtrip/clearing_due_does_not_restore_it", test_clearing_due_does_not_restore_it);
        Test.add_func ("/core/caldav_roundtrip/relative_reminders_survive_repeated_saves", test_relative_reminders_survive_repeated_saves);
        Test.add_func ("/core/caldav_roundtrip/absolute_reminder_edits_preserve_relative_reminders",
            test_absolute_reminder_edits_preserve_relative_reminders);
    }
}
