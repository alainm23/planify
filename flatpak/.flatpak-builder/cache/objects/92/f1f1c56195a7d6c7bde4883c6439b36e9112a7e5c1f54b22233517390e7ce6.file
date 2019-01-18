//
//  Copyright (C) 2011-2012 Maxwell Barvian
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Maya.Settings {

    public string DateFormat () {
        return _("%B %e, %Y");
    }

    public string DateFormat_Complete () {
        return _("%A, %b %d");
    }

    public string TimeFormat () {
        // If AM/PM doesn't exist, use 24h.
        if (Posix.nl_langinfo (Posix.NLItem.AM_STR) == null || Posix.nl_langinfo (Posix.NLItem.AM_STR) == "") {
            return Granite.DateTime.get_default_time_format (false);
        }

        // If AM/PM exists, assume it is the default time format and check for format override.
        var setting = new GLib.Settings ("org.gnome.desktop.interface");
        var clockformat = setting.get_user_value ("clock-format");
        if (clockformat == null)
            return Granite.DateTime.get_default_time_format (true);

        if (clockformat.get_string ().contains ("12h")) {
            return Granite.DateTime.get_default_time_format (true);
        } else {
            return Granite.DateTime.get_default_time_format (false);
        }
    }

}
