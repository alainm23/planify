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

public class Objects.Collaborator : GLib.Object {
    public int64 id { get; set; default = 0; }
    public string email { get; set; default = ""; }
    public string full_name { get; set; default = ""; }
    public string timezone { get; set; default = ""; }
    public string image_id { get; set; default = ""; }

    //private uint timeout_id = 0;

    public void save () {
        /*
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }

        timeout_id = Timeout.add (2500, () => {
            new Thread<void*> ("save_timeout", () => {
                Planner.database.update_area (this);
                return null;
            });

            Source.remove (timeout_id);
            timeout_id = 0;
            return false;
        });
        */
    }
}
