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

public class Utils : GLib.Object {
    private static Utils? _instance;
    public static Utils get_default () {
        if (_instance == null) {
            _instance = new Utils ();
        }

        return _instance;
    }

    public string get_encode_text (string text) {
        return GLib.Uri.escape_string (text, null, false);
    }

     /*
        Icons
    */

    private Gee.HashMap<string, bool>? _dynamic_icons;
    public Gee.HashMap<string, bool> dynamic_icons {
        get {
            if (_dynamic_icons != null) {
                return _dynamic_icons;
            }

            _dynamic_icons = new Gee.HashMap<string, bool> ();
            _dynamic_icons.set ("planner-calendar", true);
            _dynamic_icons.set ("planner-search", true);
            _dynamic_icons.set ("chevron-right", true);
            _dynamic_icons.set ("chevron-down", true);
            _dynamic_icons.set ("planner-refresh", true);
            _dynamic_icons.set ("planner-edit", true);
            _dynamic_icons.set ("planner-trash", true);
            _dynamic_icons.set ("planner-star", true);
            _dynamic_icons.set ("planner-note", true);
            _dynamic_icons.set ("planner-close-circle", true);
            _dynamic_icons.set ("planner-check-circle", true);
            _dynamic_icons.set ("planner-flag", true);
            _dynamic_icons.set ("planner-tag", true);
            _dynamic_icons.set ("planner-pinned", true);
            _dynamic_icons.set ("planner-settings", true);
            _dynamic_icons.set ("planner-bell", true);
            _dynamic_icons.set ("sidebar-left", true);
            _dynamic_icons.set ("sidebar-right", true);
            _dynamic_icons.set ("planner-mail", true);
            _dynamic_icons.set ("planner-note", true);
            _dynamic_icons.set ("planner-settings-sliders", true);
            _dynamic_icons.set ("planner-list", true);
            _dynamic_icons.set ("planner-board", true);
            _dynamic_icons.set ("color-swatch", true);
            _dynamic_icons.set ("emoji-happy", true);
            _dynamic_icons.set ("planner-clipboard", true);
            _dynamic_icons.set ("planner-copy", true);
            _dynamic_icons.set ("planner-rotate", true);
            _dynamic_icons.set ("planner-section", true);
            _dynamic_icons.set ("unordered-list", true);
            _dynamic_icons.set ("ordered-list", true);
            _dynamic_icons.set ("menu", true);
            _dynamic_icons.set ("share", true);
            _dynamic_icons.set ("dropdown", true);
            _dynamic_icons.set ("information", true);
            _dynamic_icons.set ("dots-vertical", true);
            _dynamic_icons.set ("plus", true);

            return _dynamic_icons;
        }
    }

    public bool is_dynamic_icon (string icon_name) {
        return dynamic_icons.has_key (icon_name);
    }
}