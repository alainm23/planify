/*
* Copyright © 2025 Alain M. (https://github.com/alainm23/planify)
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

public class Objects.Release : GLib.Object {
    public string release_type { get; set; }
    public string version { get; set; }
    public int64 timestamp { get; set; }
    public string description { get; set; }

    public Release.from_json (Json.Object object) {
        release_type = object.get_string_member ("type");
        version = object.get_string_member ("version");
        timestamp = int64.parse (object.get_string_member ("timestamp"));
        
        if (object.has_member ("description")) {
            description = object.get_string_member ("description");
        } else {
            description = "";
        }
    }

    public string? get_release_message () {
        if (description == null || description == "") {
            return null;
        }

        int start = description.index_of ("<p>");
        if (start == -1) {
            return null;
        }

        start += 3;
        int end = description.index_of ("</p>", start);
        if (end == -1) {
            return null;
        }

        string message = description.substring (start, end - start).strip ();
        return message != "" ? message : null;
    }
}
