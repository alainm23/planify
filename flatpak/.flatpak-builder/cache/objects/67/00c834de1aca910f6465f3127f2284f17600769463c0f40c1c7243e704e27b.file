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
    public enum WindowState {
        NORMAL = 0,
        MAXIMIZED = 1
    }

    public class SavedState : Granite.Services.Settings {
        private static Settings.SavedState? saved_state = null;

        public static SavedState get_default () {
            if (saved_state == null)
                saved_state = new SavedState ();
            return saved_state;
        }

        public int window_width { get; set; }
        public int window_height { get; set; }
        public WindowState window_state { get; set; }
        public bool show_weeks { get; set; }
        public int hpaned_position { get; set; }
        public string month_page { get; set; }
        public string selected_day { get; set; }

        private SavedState () {
            base ("io.elementary.calendar.savedstate");
        }

        public DateTime get_page () {
            if (month_page == null)
                return new DateTime.now_local ();
            if (month_page == "")
                return new DateTime.now_local ();
            var numbers = month_page.split ("-", 2);
            var dt = new DateTime.local (int.parse (numbers[0]), 1, 1, 0, 0, 0);
            dt = dt.add_months (int.parse (numbers[1])-1);
            return dt;
        }

        public DateTime get_selected () {
            if (selected_day == null)
                return new DateTime.now_local ();
            if (selected_day == "")
                return new DateTime.now_local ();
            var numbers = selected_day.split ("-", 2);
            var dt = new DateTime.local (int.parse (numbers[0]), 1, 1, 0, 0, 0);
            dt = dt.add_days (int.parse (numbers[1])-1);
            return dt;
        }
    }
}
