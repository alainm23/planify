// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2015 elementary LLC
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Mario Guerriero <marioguerriero33@gmail.com>
 *              pantor
 */

namespace Maya.Services {

public class ParserEn : GLib.Object, EventParser {

    public DateTime simulated_dt;

    public string source;
    private string remaining_source;

    string[,] months = {
        {"january", "1"},
        {"february", "2"},
        {"march", "3"},
        {"april", "4"},
        {"may", "5"},
        {"june", "6"},
        {"july", "7"},
        {"august", "8"},
        {"september", "9"},
        {"october", "10"},
        {"november", "11"},
        {"december", "12"}
    };

    string[,] weekdays = {
        {"monday", "1"},
        {"tuesday", "2"},
        {"wednesday", "3"},
        {"thursday", "4"},
        {"thu", "4"},
        {"friday", "5"},
        {"saturday", "6"},
        {"sunday", "7"}
    };

    string[,] number_words = {
        {"one", "1"},
        {"two", "2"},
        {"three", "3"},
        {"four", "4"},
        {"five", "5"},
        {"six", "6"},
        {"seven", "7"},
        {"eight", "8"},
        {"nine", "9"},
        {"ten", "10"},
        {"eleven", "11"},
        {"twelve", "12"}
    };

    string months_regex;
    string weekdays_regex;
    string number_words_regex;

    struct String_event { bool matched; string matched_string; int pos; int length; Array<string> p; }

    delegate void transcribe_analysis (String_event data);

    public ParserEn (DateTime _simulated_dt = new DateTime.now_local ()) {
        this.simulated_dt = _simulated_dt;

        this.source = "";
        this.remaining_source = "";

        this.months_regex = "(";
        for (int i = 0; i < 12; i++) {
            this.months_regex += months[i, 0] + "|";
        }

        this.months_regex = this.months_regex[0:-1] + ")";

        this.weekdays_regex = "(";
        for (int i = 0; i < 7; i++) {
            this.weekdays_regex += weekdays[i, 0] + "|";
        }

        this.weekdays_regex = this.weekdays_regex[0:-1] + ")";

        this.number_words_regex = "(";
        for (int i = 0; i < 7; i++) {
            this.number_words_regex += number_words[i, 0] + "|";
        }

        this.number_words_regex = this.number_words_regex[0:-1] + ")";
    }

    int get_number_of_month (string entry) {
        for (int i = 0; i < 12; i++) {
            if (entry.down () == months[i, 0]) {
                return int.parse (months[i, 1]);
            }
        }
        return -1;
    }

    int get_number_of_weekday (string entry) {
        for (int i = 0; i < 12; i++) {
            if (entry.down () == weekdays[i, 0]) {
                return int.parse (weekdays[i, 1]);
            }
        }
        return -1;
    }

    /*int get_number_of_word (string entry) {
        for (int i = 0; i < 12; i++) {
            if (entry.down () == number_words[i, 0])
                return int.parse (number_words[i, 1]);
        }
        return -1;
    }*/

    // finds regex "pattern" in string source
    String_event complete_string (string pattern) {
        Regex regex;
        MatchInfo match_info;
        try {
            regex = new Regex (pattern, RegexCompileFlags.CASELESS);
            var is_matched = regex.match (this.remaining_source, 0, out match_info);
            if (!is_matched) {
                return String_event () { matched = false };
            }
        } catch {
            return String_event () { matched = false };
        }

        var matched_string = match_info.fetch (0);
        var pos = this.remaining_source.index_of (matched_string);
        var length = matched_string.length;

        var p = new Array<string> ();

        while (match_info.matches ()) {
            for (var i = 0; i < 6; i++) {
                p.append_val (match_info.fetch_named (@"p$(i + 1)"));
            }

            try {
                match_info.next ();
            } catch (GLib.RegexError exc) {
                // TODO
            }
        }

        return String_event () { matched = true, pos = pos, length = length, matched_string = matched_string, p = p };
    }

    void analyze_pattern (string pattern, transcribe_analysis del, bool delete = true) {
        String_event data = complete_string ("\\b" + pattern + "\\b");
        if (data.matched) {
            if (delete) {
                this.remaining_source = this.remaining_source.splice (data.pos, data.pos + data.length);
            }

            del (data);
        }
    }

    public ParsedEvent parse_source (string _source) {
        this.source = _source;
        this.remaining_source = this.source;

        var event = new ParsedEvent ();
        event.from = this.simulated_dt.add_hours (1);
        event.from_set_minute (0);
        event.from_set_second (0);
        event.set_length_to_hours (1);

        // --- Date ---

        analyze_pattern ("two days ago", (data) => {
            event.from = event.from.add_days (-2);
            event.set_one_entire_day ();
        });

        analyze_pattern ("yesterday", (data) => {
            event.from = event.from.add_days (-1);
            event.set_one_entire_day ();
        });

        analyze_pattern ("today", (data) => {
            event.set_one_entire_day ();
        });

        analyze_pattern ("tomorrow", (data) => {
            event.from = event.from.add_days (1);
            event.set_one_entire_day ();
        });

        analyze_pattern ("this weekend", (data) => {
            int add_days = (6 - this.simulated_dt.get_day_of_week () + 7) % 7;
            event.from = event.from.add_days (add_days);
            event.to = event.from.add_days (1);
            event.set_all_day ();
        });

        analyze_pattern ("all day", (data) => {
            event.set_one_entire_day ();
        });

        analyze_pattern ("the whole day", (data) => {
            event.set_one_entire_day ();
        });

        analyze_pattern ("next week", (data) => {
            event.from = event.from.add_days (7);
            event.set_all_day ();
        });

        analyze_pattern ("next month", (data) => {
            event.from = event.from.add_months (1);
            event.set_all_day ();
        });

        analyze_pattern ("(?<p1>\\d+) days ago", (data) => {
            int days = int.parse(data.p.index (0));
            event.from = event.from.add_days (-days);
            event.set_one_entire_day ();
        });

        analyze_pattern ("in (?<p1>\\d+) days", (data) => {
            int days = int.parse (data.p.index (0));
            event.from = event.from.add_days (days);
            event.set_one_entire_day ();
        });

        analyze_pattern ("in (?<p1>\\d+) weeks", (data) => {
            int weeks = int.parse (data.p.index (0));
            event.from = event.from.add_weeks (weeks);
            event.set_one_entire_day ();
        });

        analyze_pattern (@"(next|on) (?<p1>$weekdays_regex)", (data) => {
            int weekday = get_number_of_weekday (data.p.index (0));
            int add_days = (weekday - this.simulated_dt.get_day_of_week () + 7) % 7;
            event.from = event.from.add_days (add_days);

            event.set_one_entire_day ();
        });

        analyze_pattern (@"(this )?(?<p1>$weekdays_regex)( to (?<p2>$weekdays_regex))?", (data) => {
            int weekday_1 = get_number_of_weekday (data.p.index (0));
            int add_days_1 = (weekday_1 - this.simulated_dt.get_day_of_week () + 7) % 7;

            event.from = event.from.add_days (add_days_1);
            event.set_all_day ();

            if (data.p.index (1) != null) {
                int weekday_2 = get_number_of_weekday (data.p.index (1));
                int add_days_2 = (weekday_2 - weekday_1 + 7) % 7;

                event.to = event.from.add_days (add_days_2);
            }
        });

        analyze_pattern (@"on ((?<p1>\\d{2,4})/)?(?<p2>\\d{1,2})/(?<p3>\\d{1,2})(st|nd|rd|th)?", (data) => {
            int day = int.parse (data.p.index (2));
            int month = int.parse (data.p.index (1));

            event.from_set_day (day);
            event.from_set_month (month);
            event.set_one_entire_day ();

            event.if_elapsed_delay_to_next_year (this.simulated_dt);

            if (data.p.index (0) != null) {
                int year = int.parse (data.p.index (0));
                event.from_set_year (year);
            }
        });

        analyze_pattern (@"on (?<p1>\\d{1,2})(st|nd|rd|th)? (?<p2>$months_regex)( (?<p3>\\d{2,4}))?", (data) => {
            int day = int.parse (data.p.index (0));
            int month = get_number_of_month (data.p.index (1));

            event.from_set_day (day);
            event.from_set_month (month);
            event.set_one_entire_day ();

            event.if_elapsed_delay_to_next_year (this.simulated_dt);

            if (data.p.index (2) != null) {
                int year = int.parse (data.p.index (2));
                event.from_set_year (year);
            }
        });

        analyze_pattern (@"on (?<p1>$months_regex)(,)? (?<p2>\\d{1,2})(st|nd|rd|th)?( (?<p3>\\d{2,4}))?", (data) => {
            int day = int.parse (data.p.index (1));
            int month = get_number_of_month (data.p.index (0));

            event.from_set_day (day);
            event.from_set_month (month);
            event.set_one_entire_day ();

            if (data.p.index (2) != null) {
                int year = int.parse (data.p.index (2));
                event.from_set_year (year);
            }

            event.if_elapsed_delay_to_next_year (this.simulated_dt);
        });

        analyze_pattern (@"from (?<p1>\\d{1,2})(.)? to (?<p2>\\d{1,2}). ((?<p3>$months_regex))?", (data) => {
            int day_1 = int.parse (data.p.index (0));
            int day_2 = int.parse (data.p.index (1));

            event.from_set_day (day_1);
            event.to_set_day (day_2);
            event.set_all_day ();

            if (data.p.index (2) != null) {
                int month = get_number_of_month (data.p.index (2));
                event.from_set_month (month);
                event.to_set_month (month);

                event.if_elapsed_delay_to_next_year (this.simulated_dt);
            }

            event.if_elapsed_delay_to_next_month (this.simulated_dt);
        });

        analyze_pattern (@"from (?<p1>\\d{1,2})/(?<p2>\\d{1,2}) - ((?<p3>\\d{1,2})/)?(?<p4>\\d{1,2})", (data) => {
            int day_1 = int.parse (data.p.index (1));
            int day_2 = int.parse (data.p.index (3));
            int month_1 = int.parse (data.p.index (0));
            int month_2 = int.parse (data.p.index (2));

            if (month_2 == 0) {
                month_2 = month_1;
            }

            event.from_set_day (day_1);
            event.to_set_day( day_2);
            event.from_set_month (month_1);
            event.to_set_month (month_2);
            event.set_all_day ();

            event.if_elapsed_delay_to_next_year (this.simulated_dt);
        });

        analyze_pattern (@"from (?<p1>$months_regex) (?<p2>\\d{1,2})(st|nd|rd|th)? - (?<p3>\\d{1,2})(st|nd|rd|th)?", (data) => {
            int day_1 = int.parse (data.p.index (1));
            int day_2 = int.parse (data.p.index (2));
            int month_1 = get_number_of_month (data.p.index (0));

            event.from_set_day (day_1);
            event.to_set_day (day_2);
            event.from_set_month (month_1);
            event.to_set_month (month_1);

            event.set_all_day ();

            event.if_elapsed_delay_to_next_year (this.simulated_dt);
        });

        analyze_pattern ("in a month", (data) => {
            event.from = event.from.add_months (1);
            event.set_one_entire_day ();
        });

        analyze_pattern ("christmas eve", (data) => {
            event.from_set_month (12);
            event.from_set_day (24);
            event.set_one_entire_day ();

            event.if_elapsed_delay_to_next_year (this.simulated_dt);
        });

        // --- Time ---

        analyze_pattern ("breakfast", (data) => {
            event.from_set_hour (8);
            event.set_length_to_hours (1);
            event.all_day = false;
        }, false);

        analyze_pattern ("lunch", (data) => {
            event.from_set_hour (13);
            event.set_length_to_hours (1);
            event.all_day = false;
        }, false);

        analyze_pattern ("dinner", (data) => {
            event.from_set_hour (19);
            event.set_length_to_hours (1);
            event.all_day = false;
        }, false);

        analyze_pattern ("early", (data) => {
            event.from_set_hour (9);
            event.set_length_to_hours (1);
            event.all_day = false;
        });

        analyze_pattern ("(this )?morning", (data) => {
            event.from_set_hour (11);
            event.set_length_to_hours (1);
            event.all_day = false;
        });

        analyze_pattern ("(at |this )?noon", (data) => {
            event.from_set_hour (12);
            event.set_length_to_hours (1);
            event.all_day = false;
        });

        analyze_pattern ("(this )?afternoon", (data) => {
            event.from_set_hour (15);
            event.set_length_to_hours (1);
            event.all_day = false;
        });

        analyze_pattern ("(this )?evening", (data) => {
            event.from_set_hour (18);
            event.set_length_to_hours (1);
            event.all_day = false;
        });

        analyze_pattern ("late", (data) => {
            event.from_set_hour (19);
            event.set_length_to_hours (3);
            event.all_day = false;
        });

        analyze_pattern ("(?<p1>\\d{1,2})?(?<p2>(am|pm|p))?(to |-| - )(?<p3>\\d{1,2})?(?<p4>(am|pm|p))?", (data) => {
            int hour_1 = int.parse (data.p.index (0));
            int hour_2 = int.parse (data.p.index (2));

            string half_1 = "";
            if (data.p.index (1) != null) {
                half_1 = data.p.index (1);
            }

            string half_2 = "";
            if (data.p.index (3) != null) {
                half_2 = data.p.index (3);
            }

            event.from_set_hour (hour_1, half_1);
            event.to_set_hour (hour_2, half_2);

            event.all_day = false;
        });

        analyze_pattern ("(at |@ ?)(?<p1>\\d{1,2})(:(?<p2>\\d{1,2}))?(?<p3>(am|pm|p))?", (data) => {
            int hour = int.parse (data.p.index(0));

            if (data.p.index (1) != null) {
                int minute_1 = int.parse(data.p.index (1));
                event.from_set_minute (minute_1);
            }

            string half = "";
            if (data.p.index (2) != null) {
                half = data.p.index (2);
            }

            event.from_set_hour (hour, half);

            event.set_length_to_hours (1);
            event.all_day = false;
        });

        analyze_pattern ("(at |@)(?<p1>\\d{4})", (data) => {
            int hour = int.parse (data.p.index (0));

            if (data.p.index (1) != null) {
                int minute_1 = int.parse (data.p.index (1));
                event.from_set_minute (minute_1);
            }

            string half = "";
            if (data.p.index (2) != null) {
                half = data.p.index (2);
            }

            event.from_set_hour (hour, half);

            event.set_length_to_hours (1);
            event.all_day = false;
        });

        analyze_pattern ("from (?<p1>\\d{1,2})(:(?<p3>\\d{1,2}))?(?<p5>(am|pm|p)?) to (?<p2>\\d{1,2})(:(?<p4>\\d{1,2}))?(?<p6>(am|pm|p)?)", (data) => {
            int hour_1 = int.parse (data.p.index (0));
            int hour_2 = int.parse (data.p.index (1));

            string half_1 = "";
            if (data.p.index (4) != null) {
                half_1 = data.p.index (4);
            }

            event.from_set_hour (hour_1, half_1);

            string half_2 = "";
            if (data.p.index (5) != null) {
                half_2 = data.p.index (5);
            }

            event.to_set_hour (hour_2, half_2);

            if (data.p.index (2) != null) {
                int minute_1 = int.parse (data.p.index (2));
                event.from_set_minute (minute_1);
            }

            if (data.p.index (3) != null) {
                int minute_2 = int.parse (data.p.index (3));
                event.to_set_minute (minute_2);
            }

            event.all_day = false;
        });

        analyze_pattern ("(?<p1>\\d{1,2})(:(?<p2>\\d{1,2}))? (o'clock|h)", (data) => {
            int hour = int.parse (data.p.index (0));
            event.from_set_hour (hour);

            if (data.p.index (1) != null) {
                int minute_1 = int.parse (data.p.index (1));
                event.from_set_minute (minute_1);
            }

            event.set_length_to_hours (1);
            event.all_day = false;
        });

        analyze_pattern ("for (?<p1>\\d+)(\\s?min| minutes)", (data) => {
            int minutes = int.parse (data.p.index (0));
            event.set_length_to_minutes (minutes);
        });

        analyze_pattern ("for (?<p1>\\d+)(\\s?h| hours)", (data) => {
            int hours = int.parse (data.p.index(0));
            event.set_length_to_hours (hours);
        });

        analyze_pattern ("for (?<p1>\\d+)(\\s?d| days)", (data) => {
            int days = int.parse (data.p.index (0));
            event.set_length_to_days (days);
        });

        analyze_pattern ("for (?<p1>\\d+) weeks", (data) => {
            int weeks = int.parse (data.p.index (0));
            event.set_length_to_weeks(weeks);
        });

        // --- Repetition ---

        // --- Persons ---
        analyze_pattern ("(with)( the)? (?<p1>(\\w\\s?)+)", (data) => {
            for (int i = 0; i < data.p.length ; i++)
                event.participants += data.p.index (i);
        });

        // --- Location ----
        analyze_pattern ("(at|in)(the)? (?<p1>(\\w\\s?)+)", (data) => {
            event.location = data.p.index (0);
        });

        // --- Name ---
        event.title = this.remaining_source.strip ();
        // event.title = event.title.strip();
        // Strip ,.: from title

        return event;
    }

    public string get_language () {
        return EventParserHandler.FALLBACK_LANG;
    }
}

}
