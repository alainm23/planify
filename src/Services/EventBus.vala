/*/
*- Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Services.EventBus : Object {
    // Shortcuts
    public signal void disconnect_typing_accel ();
    public signal void connect_typing_accel ();

    // Magic Button
    public signal void magic_button_visible (bool active);
    public signal void drag_magic_button_activated (bool active);
    public signal void magic_button_activated (
        int64 project_id,
        int64 section_id,
        int is_todoist,
        int index,
        string view="project",
        string due_date=""
    );

    // Multi Select
    public signal void ctrl_press ();
    public signal void ctrl_release ();
    public bool ctrl_pressed { get; set; default = false; }
    public signal void select_item (Widgets.ItemRow row);
    public signal void valid_select_item (Widgets.ItemRow row);
    
    public void test (string caller_id) {
        debug (@"Test from EventBus called by $(caller_id)");
    }
}
