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

public class Widgets.Entry : Gtk.Entry {
    construct {
        focus_in_event.connect (handle_focus_in);
        focus_out_event.connect (update_on_leave);
    }

    private bool handle_focus_in (Gdk.EventFocus event) {
        Planner.event_bus.disconnect_typing_accel ();
        return false;
    }

    public bool update_on_leave () {
        Planner.event_bus.connect_typing_accel ();
        return false;
    }
}
