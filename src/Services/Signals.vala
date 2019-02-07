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

public class Services.Signals : GLib.Object {
    public signal void on_signal_show_quick_find ();

    public signal void on_signal_show_events ();

    public signal void go_action_page (int index);
    public signal void go_project_page (int project_id);
    public signal void go_task_page (int task_id, int project_id);

    public signal void check_project_import (int project_id);

    public signal void start_loading_project (int project_id);
    public signal void stop_loading_project (int project_id);

    public signal void start_loading_item (string type);
    public signal void stop_loading_item (string type);

    public Signals () {}
}
