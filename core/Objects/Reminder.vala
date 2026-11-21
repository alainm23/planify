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

public class Objects.Reminder : Objects.BaseObject {
    public int64 notify_uid { get; set; default = 0; }
    public string item_id { get; set; default = ""; }
    public string service { get; set; default = ""; }
    public Objects.DueDate due { get; set; default = new Objects.DueDate (); }
    public int mm_offset { get; set; default = 0; }
    public int is_deleted { get; set; default = 0; }
    public ReminderType reminder_type { get; set; default = ReminderType.ABSOLUTE; }
    // Time of the occurrence that already fired (only kept for recurring tasks).
    public string fired_at { get; set; default = ""; }

    Objects.Item ? _item;
    public Objects.Item item {
        get {
            _item = Services.Store.instance ().get_item (item_id);
            return _item;
        }

        set {
            _item = value;
        }
    }

    GLib.DateTime _datetime;
    public GLib.DateTime datetime {
        get {
            if (reminder_type == ReminderType.ABSOLUTE) {
                _datetime = due.datetime;
            } else {
                _datetime = item.due.datetime.add_minutes (mm_offset * -1);
            }

            return _datetime;
        }
    }


    /*
     * True when the reminder belongs to a recurring task and its time already
     * passed: it stays to remind again once the task moves to its next occurrence.
     */
    public bool waiting_next_occurrence {
        get {
            var task = item;
            if (task == null || !task.has_due || !task.due.is_recurring || task.due.is_recurrency_end) {
                return false;
            }

            var dt = datetime;
            return has_fired || (dt != null && dt.compare (new GLib.DateTime.now_local ()) <= 0);
        }
    }

    // Already fired at its current time. Moving the reminder (or its task) to
    // another time makes it pending again.
    public bool has_fired {
        get {
            var dt = datetime;
            return fired_at != "" && dt != null && fired_at == dt.to_string ();
        }
    }

    // Text for the UI: a passed reminder of a recurring task shows only its time,
    // since the date belongs to the occurrence that already went by.
    public string display_text {
        owned get {
            if (!waiting_next_occurrence || reminder_type != ReminderType.ABSOLUTE) {
                return relative_text;
            }

            // TRANSLATORS: %s is a time, e.g. "9:00 · Next occurrence"
            return _("%s · Next occurrence").printf (
                due.datetime.format (Utils.Datetime.get_default_time_format ())
            );
        }
    }

    string _relative_text;
    public string relative_text {
        get {
            _relative_text = "";

            if (reminder_type == ReminderType.ABSOLUTE) {
                _relative_text = Utils.Datetime.get_relative_date_from_date (due.datetime);
            } else {
                _relative_text = Util.get_reminders_mm_offset_text (mm_offset);
            }

            return _relative_text;
        }
    }

    public Reminder.from_json (Json.Node node) {
        id = node.get_object ().get_string_member ("id");
        item_id = node.get_object ().get_string_member ("item_id");
        reminder_type = node.get_object ().get_string_member ("type") == "absolute" ? ReminderType.ABSOLUTE : ReminderType.RELATIVE;
        mm_offset = (int32) node.get_object ().get_int_member ("item_id");

        if (reminder_type == ReminderType.ABSOLUTE) {
            due.update_from_todoist_json (node.get_object ().get_object_member ("due"));
        }
    }

    construct {
        deleted.connect (() => {
            Services.Store.instance ().reminder_deleted (this);
        });
    }

    public override string get_add_json (string temp_id, string uuid) {
        return get_update_json (uuid, temp_id);
    }

    public override string get_update_json (string uuid, string ? temp_id = null) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("commands");

        builder.begin_array ();
        builder.begin_object ();

        // Set type
        builder.set_member_name ("type");
        builder.add_string_value (temp_id == null ? "reminder_update" : "reminder_add");

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        if (temp_id != null) {
            builder.set_member_name ("temp_id");
            builder.add_string_value (temp_id);
        }

        builder.set_member_name ("args");
        builder.begin_object ();

        if (temp_id == null) {
            builder.set_member_name ("id");
            builder.add_string_value (id);
        }

        builder.set_member_name ("item_id");
        builder.add_string_value (item_id);

        builder.set_member_name ("type");
        builder.add_string_value (reminder_type.to_string ());

        builder.set_member_name ("minute_offset");
        builder.add_int_value (mm_offset);

        if (reminder_type == ReminderType.ABSOLUTE) {
            builder.set_member_name ("due");
            builder.begin_object ();
            builder.set_member_name ("date");
            builder.add_string_value (due.date);
            builder.end_object ();
        }

        builder.end_object ();
        builder.end_object ();
        builder.end_array ();
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public void delete () {
        if (item.project.source_type == SourceType.TODOIST) {
            loading = true;
            Services.Todoist.get_default ().delete.begin (this, (obj, res) => {
                if (Services.Todoist.get_default ().delete.end (res).status) {
                    Services.Store.instance ().delete_reminder (this);
                    loading = false;
                }
            });
        } else {
            Services.Store.instance ().delete_reminder (this);
            loading = false;
        }
    }

    public Objects.Reminder duplicate () {
        var new_reminder = new Objects.Reminder ();
        new_reminder.notify_uid = notify_uid;
        new_reminder.service = service;
        new_reminder.due = due;
        new_reminder.mm_offset = mm_offset;
        new_reminder.mm_offset = mm_offset;

        return new_reminder;
    }
}
