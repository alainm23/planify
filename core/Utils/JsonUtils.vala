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
 *
 * Authored by: Alain M. <alainmh23@gmail.com>
 */

public class Utils.JsonUtils {
    public static Json.Object get_object (string data) {
        var parser = new Json.Parser ();

        try {
            parser.load_from_data (data, -1);
        } catch (Error e) {
            debug (e.message);
        }

        return parser.get_root ().get_object ();
    }

    public static Json.Object get_object_member (string data, string member) {
        return get_object (data).get_object_member (member);
    }

    public static string get_string (string data, string member) {
        var obj = get_object (data);

        if (obj.has_member (member) && !obj.get_null_member (member)) {
            return obj.get_string_member (member);
        }

        return "";
    }

    public static int64 get_int (string data, string member) {
        var obj = get_object (data);

        if (obj.has_member (member) && !obj.get_null_member (member)) {
            return obj.get_int_member (member);
        }

        return 0;
    }

    public static bool get_bool (string data, string member) {
        var obj = get_object (data);

        if (obj.has_member (member) && !obj.get_null_member (member)) {
            return obj.get_boolean_member (member);
        }

        return false;
    }

    public static bool has_member (string data, string member) {
        return get_object (data).has_member (member);
    }

    public static bool is_null_member (string data, string member) {
        var obj = get_object (data);
        return obj.has_member (member) && obj.get_null_member (member);
    }
}
