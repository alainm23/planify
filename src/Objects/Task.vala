/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Objects.Task {
    public int id;
    public int checked;
    public int project_id;
    public int list_id;
    public int task_order;
    public int is_inbox;
    public int has_reminder;
    public int sidebar_width;
    public int was_notified;
    public string content;
    public string note;
    public string when_date_utc;
    public string reminder_time;
    public string labels;
    public string checklist;
    public string date_added;

    public Task (int id = 0,
                 int checked = 0,
                 int project_id = 0,
                 int list_id = 0,
                 int task_order = 0,
                 int is_inbox = 0,
                 int has_reminder = 0,
                 int sidebar_width = 0,
                 int was_notified = 0,
                 string content = "",
                 string note = "",
                 string when_date_utc = "",
                 string reminder_time = "",
                 string labels = "",
                 string date_added = new GLib.DateTime.now_local ().to_string (),
                 string checklist = "") {
        this.id = id;
        this.checked = checked;
        this.project_id = project_id;
        this.list_id = list_id;
        this.task_order = task_order;
        this.is_inbox = is_inbox;
        this.has_reminder = has_reminder;
        this.sidebar_width = sidebar_width;
        this.was_notified = was_notified;
        this.content = content;
        this.note = note;
        this.when_date_utc = when_date_utc;
        this.reminder_time = reminder_time;
        this.labels = labels;
        this.checklist = checklist;
        this.date_added = date_added;
    }
}
