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

namespace Chrono {
    public class ENRecurrenceParser : Object {
        private Regex basic_regex;
        private Regex alias_regex;
        private Regex time_of_day_regex;
        private Regex weekday_regex;
        private Regex ordinal_day_regex;
        private Regex specific_date_regex;
        private Regex hour_regex;
        
        public ENRecurrenceParser () {
            try {
                basic_regex = new Regex (@"\\bevery\\s+(?:(\\d+)\\s+)?(day|week|month|year)s?\\b", RegexCompileFlags.CASELESS); // vala-lint=unnecessary-string-template
                alias_regex = new Regex (@"\\b(daily|weekly|monthly|yearly)\\b", RegexCompileFlags.CASELESS); // vala-lint=unnecessary-string-template
                time_of_day_regex = new Regex (@"\\bevery\\s+(morning|afternoon|evening|night)\\b", RegexCompileFlags.CASELESS); // vala-lint=unnecessary-string-template
                weekday_regex = new Regex (@"\\bevery\\s+(weekday|workday|weekend)\\b", RegexCompileFlags.CASELESS); // vala-lint=unnecessary-string-template
                ordinal_day_regex = new Regex (@"\\bevery\\s+(?:(\\d+)(?:st|nd|rd|th)|last\\s+day)\\b", RegexCompileFlags.CASELESS); // vala-lint=unnecessary-string-template
                specific_date_regex = new Regex (@"\\bevery\\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)(?:uary|ruary|ch|il|e|y|ust|tember|ober|ember)?\\s+(\\d+)(?:st|nd|rd|th)?\\b", RegexCompileFlags.CASELESS); // vala-lint=unnecessary-string-template
                hour_regex = new Regex (@"\\bevery\\s+hour\\b", RegexCompileFlags.CASELESS); // vala-lint=unnecessary-string-template
            } catch (Error e) {
                warning ("Error compiling regex: %s", e.message);
            }
        }
        
        public ParseResult? parse (string text, GLib.DateTime reference_date) {
            ParseResult? result = parse_hour (text, reference_date);
            if (result != null) return result;
            
            result = parse_specific_date (text, reference_date);
            if (result != null) return result;
            
            result = parse_ordinal_day (text, reference_date);
            if (result != null) return result;
            
            result = parse_time_of_day (text, reference_date);
            if (result != null) return result;
            
            result = parse_weekday (text, reference_date);
            if (result != null) return result;
            
            result = parse_alias (text, reference_date);
            if (result != null) return result;
            
            result = parse_basic (text, reference_date);
            return result;
        }
        
        private ParseResult? parse_basic (string text, GLib.DateTime reference_date) {
            MatchInfo match_info;
            if (!basic_regex.match (text, 0, out match_info)) return null;
            
            string interval_str = match_info.fetch (1);
            string unit = match_info.fetch (2).down ();
            int interval = (interval_str != null && interval_str.length > 0) ? int.parse (interval_str) : 1;
            
            RecurrenceType type = RecurrenceType.DAILY;
            switch (unit) {
                case "day": type = RecurrenceType.DAILY; break;
                case "week": type = RecurrenceType.WEEKLY; break;
                case "month": type = RecurrenceType.MONTHLY; break;
                case "year": type = RecurrenceType.YEARLY; break;
            }
            
            return create_result (match_info, reference_date, type, interval);
        }
        
        private ParseResult? parse_alias (string text, GLib.DateTime reference_date) {
            MatchInfo match_info;
            if (!alias_regex.match (text, 0, out match_info)) return null;
            
            string alias = match_info.fetch (1).down ();
            RecurrenceType type = RecurrenceType.DAILY;
            switch (alias) {
                case "daily": type = RecurrenceType.DAILY; break;
                case "weekly": type = RecurrenceType.WEEKLY; break;
                case "monthly": type = RecurrenceType.MONTHLY; break;
                case "yearly": type = RecurrenceType.YEARLY; break;
            }
            
            return create_result (match_info, reference_date, type, 1);
        }
        
        private ParseResult? parse_time_of_day (string text, GLib.DateTime reference_date) {
            MatchInfo match_info;
            if (!time_of_day_regex.match (text, 0, out match_info)) return null;
            
            string time = match_info.fetch (1).down ();
            int hour = 9;
            switch (time) {
                case "morning": hour = 9; break;
                case "afternoon": hour = 12; break;
                case "evening": hour = 19; break;
                case "night": hour = 22; break;
            }
            
            var result = create_result (match_info, reference_date, RecurrenceType.DAILY, 1);
            result.recurrence.hour = hour;
            result.date = new DateTime.local (reference_date.get_year (), reference_date.get_month (), reference_date.get_day_of_month (), hour, 0, 0);
            return result;
        }
        
        private ParseResult? parse_weekday (string text, GLib.DateTime reference_date) {
            MatchInfo match_info;
            if (!weekday_regex.match (text, 0, out match_info)) return null;
            
            string type = match_info.fetch (1).down ();
            var result = create_result (match_info, reference_date, RecurrenceType.WEEKLY, 1);
            result.recurrence.days_of_week = new Gee.ArrayList<int> ();
            
            if (type == "weekday" || type == "workday") {
                result.recurrence.days_of_week.add_all_array ({1, 2, 3, 4, 5});
            } else {
                result.recurrence.days_of_week.add (6);
            }
            
            return result;
        }
        
        private ParseResult? parse_ordinal_day (string text, GLib.DateTime reference_date) {
            MatchInfo match_info;
            if (!ordinal_day_regex.match (text, 0, out match_info)) return null;
            
            string day_str = match_info.fetch (1);
            var result = create_result (match_info, reference_date, RecurrenceType.MONTHLY, 1);
            
            if (text.contains ("last day")) {
                result.recurrence.last_day = true;
            } else if (day_str != null && day_str.length > 0) {
                result.recurrence.day_of_month = int.parse (day_str);
            }
            
            return result;
        }
        
        private ParseResult? parse_specific_date (string text, GLib.DateTime reference_date) {
            MatchInfo match_info;
            if (!specific_date_regex.match (text, 0, out match_info)) return null;
            
            string month_str = match_info.fetch (1).down ();
            string day_str = match_info.fetch (2);
            
            int month = 1;
            switch (month_str) {
                case "jan": month = 1; break;
                case "feb": month = 2; break;
                case "mar": month = 3; break;
                case "apr": month = 4; break;
                case "may": month = 5; break;
                case "jun": month = 6; break;
                case "jul": month = 7; break;
                case "aug": month = 8; break;
                case "sep": month = 9; break;
                case "oct": month = 10; break;
                case "nov": month = 11; break;
                case "dec": month = 12; break;
            }
            
            var result = create_result (match_info, reference_date, RecurrenceType.YEARLY, 1);
            result.recurrence.month_of_year = month;
            result.recurrence.day_of_month = int.parse (day_str);
            return result;
        }
        
        private ParseResult? parse_hour (string text, GLib.DateTime reference_date) {
            MatchInfo match_info;
            if (!hour_regex.match (text, 0, out match_info)) return null;
            return create_result (match_info, reference_date, RecurrenceType.DAILY, 1);
        }
        
        private ParseResult create_result (MatchInfo match_info, GLib.DateTime reference_date, RecurrenceType type, int interval) {
            int start, end;
            match_info.fetch_pos (0, out start, out end);
            
            var rule = new RecurrenceRule (type);
            rule.interval = interval;
            
            var result = new ParseResult ();
            result.date = reference_date;
            result.recurrence = rule;
            result.start_index = start;
            result.end_index = end;
            result.matched_text = match_info.fetch (0);
            return result;
        }
    }
}
