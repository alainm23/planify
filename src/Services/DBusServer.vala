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

[DBus (name = "io.github.alainm23.planify")]
public class Services.DBusServer : Object {
    private const string DBUS_NAME = "io.github.alainm23.planify";
    private const string DBUS_PATH = "/io/github/alainm23/planify";
    private const int TASKS_CHANGED_DEBOUNCE_MS = 150;

    private static GLib.Once<DBusServer> instance;
    private bool tasks_changed_pending = false;

    public static unowned DBusServer get_default () {
        return instance.once (() => { return new DBusServer (); });
    }

    public signal void item_added (string id);

    [DBus (name = "TasksChanged")]
    public signal void tasks_changed ();

    construct {
        Bus.own_name (
            BusType.SESSION,
            DBUS_NAME,
            BusNameOwnerFlags.NONE,
            (connection) => on_bus_aquired (connection),
            () => {},
            null
        );

        listen_tasks_changes ();
    }

    public void add_item (string id) throws IOError, DBusError {
        item_added (id);
    }

    /**
     * The due-date side of the Today view as a JSON document: unchecked,
     * non-trashed tasks due today or overdue, plus the number of tasks
     * completed today. Overdue entries come before today's in the current
     * implementation, but ordering inside tasks is unspecified. Not
     * included: notes and deadline-only tasks. Clients re-fetch when
     * TasksChanged fires; version pins the document shape.
     */
    [DBus (name = "GetTasks")]
    public string get_tasks () throws IOError, DBusError {
        return build_tasks_json (collect_today_tasks (), count_done_today ());
    }

    /**
     * Built on the same Store queries as Views.Today:
     * get_items_by_overdue_view () plus get_items_by_date (now, false);
     * tasks only, and trashed rows additionally dropped.
     */
    public static Gee.ArrayList<Objects.Item> collect_today_tasks () {
        var now = new GLib.DateTime.now_local ();

        var tasks = new Gee.ArrayList<Objects.Item> ();
        append_today_tasks (tasks, Services.Store.instance ().get_items_by_overdue_view (false));
        append_today_tasks (tasks, Services.Store.instance ().get_items_by_date (now, false));

        return tasks;
    }

    public static int count_done_today () {
        int count = 0;
        var now = new GLib.DateTime.now_local ();
        var local_time = new GLib.TimeZone.local ();

        foreach (Objects.Item item in Services.Store.instance ().items) {
            if (!item.checked || item.completed_at == null || item.completed_at == "") {
                continue;
            }

            // Todoist completions carry a UTC timestamp; compare on the
            // local day, as the Today view does.
            var completed_at = new GLib.DateTime.from_iso8601 (item.completed_at, local_time);
            if (completed_at != null &&
                !item.is_trash &&
                !item.was_archived () &&
                Utils.Datetime.is_same_day (completed_at.to_timezone (local_time), now)) {
                count++;
            }
        }

        return count;
    }

    public static string build_tasks_json (Gee.ArrayList<Objects.Item> tasks, int done_today) {
        var builder = new Json.Builder ();
        builder.begin_object ();

        builder.set_member_name ("version");
        builder.add_int_value (1);

        builder.set_member_name ("tasks");
        builder.begin_array ();
        foreach (Objects.Item item in tasks) {
            add_task_json (builder, item);
        }
        builder.end_array ();

        builder.set_member_name ("done_today");
        builder.add_int_value (done_today);

        builder.end_object ();
        return Json.to_string (builder.get_root (), false);
    }

    private static void append_today_tasks (Gee.ArrayList<Objects.Item> tasks, Gee.ArrayList<Objects.Item> items) {
        foreach (Objects.Item item in items) {
            if (item.item_type == ItemType.TASK && !item.is_trash) {
                tasks.add (item);
            }
        }
    }

    private static void add_task_json (Json.Builder builder, Objects.Item item) {
        builder.begin_object ();

        builder.set_member_name ("id");
        builder.add_string_value (item.id);

        builder.set_member_name ("content");
        builder.add_string_value (item.content);

        builder.set_member_name ("description");
        builder.add_string_value (item.description);

        builder.set_member_name ("due");
        builder.begin_object ();
        builder.set_member_name ("date");
        builder.add_string_value (item.due.date);
        builder.set_member_name ("is_recurring");
        builder.add_boolean_value (item.due.is_recurring);
        builder.end_object ();

        builder.set_member_name ("priority");
        builder.add_int_value (item.priority);

        builder.set_member_name ("pinned");
        builder.add_boolean_value (item.pinned);

        builder.set_member_name ("parent_id");
        builder.add_string_value (item.parent_id);

        builder.set_member_name ("project");
        if (item.project != null) {
            // Orphaned rows (project deleted outside the app) can exist in
            // restored databases; serialize them as a null project instead
            // of dereferencing.
            builder.begin_object ();
            builder.set_member_name ("id");
            builder.add_string_value (item.project_id);
            builder.set_member_name ("name");
            builder.add_string_value (item.project.name);
            builder.set_member_name ("color");
            builder.add_string_value (item.project.color);
            builder.end_object ();
        } else {
            builder.add_null_value ();
        }

        builder.end_object ();
    }

    private void listen_tasks_changes () {
        var store = Services.Store.instance ();

        store.item_added.connect (() => queue_tasks_changed ());
        store.item_updated.connect (() => queue_tasks_changed ());
        store.item_deleted.connect (() => queue_tasks_changed ());
        store.item_archived.connect (() => queue_tasks_changed ());
        store.item_unarchived.connect (() => queue_tasks_changed ());
        store.item_pin_change.connect (() => queue_tasks_changed ());
        store.item_moved.connect (() => queue_tasks_changed ());
        store.project_updated.connect (() => queue_tasks_changed ());
        store.project_deleted.connect (() => queue_tasks_changed ());
        store.project_archived.connect (() => queue_tasks_changed ());
        store.project_unarchived.connect (() => queue_tasks_changed ());

        // The selection is clock-relative: a day rollover changes the
        // payload without any Store event.
        Services.EventBus.get_default ().day_changed.connect (() => queue_tasks_changed ());
    }

    private void queue_tasks_changed () {
        if (tasks_changed_pending) {
            return;
        }

        tasks_changed_pending = true;
        Timeout.add (TASKS_CHANGED_DEBOUNCE_MS, () => {
            tasks_changed_pending = false;
            tasks_changed ();
            return GLib.Source.REMOVE;
        });
    }

    private void on_bus_aquired (DBusConnection conn) {
        try {
            conn.register_object (DBUS_PATH, get_default ());
        } catch (Error e) {
            error (e.message);
        }
    }
}

[DBus (name = "io.github.alainm23.planify")]
public errordomain DBusServerError {
    SOME_ERROR
}
