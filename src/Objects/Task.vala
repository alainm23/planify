/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Objects.Task : Objects.BaseObject {
    public ECal.Component task { get; construct set; }
    public E.Source source { get; construct set; }

    public string summary {
        get {
            return task.get_icalcomponent ().get_summary () == null ? "" : task.get_icalcomponent ().get_summary ();
        }
    }

    public int priority {
        get {
            return CalDAVUtil.caldav_priority_to_planner (task);
        }
    }

    public string tasklist_name {
        get {
            return source.get_display_name ();
        }
    }

    public bool completed {
        get {
            return task.get_icalcomponent ().get_status () == ICal.PropertyStatus.COMPLETED;
        }
    }

    public Task (ECal.Component task, E.Source source) {
        Object (
            task: task,
            source: source
        );
    }
}
