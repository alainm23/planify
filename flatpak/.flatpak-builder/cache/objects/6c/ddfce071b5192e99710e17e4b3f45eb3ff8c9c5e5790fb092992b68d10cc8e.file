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

public class ParserDe : GLib.Object, EventParser {

    public DateTime simulated_dt;

    public string source;
    private string remaining_source;

    string[,] months = {
        {"januar", "1"},
        {"februar", "2"},
        {"märz", "3"},
        {"april", "4"},
        {"mai", "5"},
        {"juni", "6"},
        {"juli", "7"},
        {"august", "8"},
        {"september", "9"},
        {"oktober", "10"},
        {"november", "11"},
        {"dezember", "12"}
    };

    string[,] weekdays = {
        {"montag", "1"},
        {"dienstag", "2"},
        {"mittwoch", "3"},
        {"donnerstag", "4"},
        {"freitag", "5"},
        {"samstag", "6"},
        {"sonntag", "7"}
    };

    string months_regex;
    string weekdays_regex;

    struct String_event { bool matched; string matched_string; int pos; int length; Array<string> p; }

    delegate void transcribe_analysis (String_event data);

    public ParserDe (DateTime _simulated_dt = new DateTime.now_local ()) {
        this.simulated_dt = _simulated_dt;

        this.source = "";
        this.remaining_source = "";

        this.months_regex = "";
        for (int i = 0; i < 12; i++) {
            this.months_regex += months[i, 0] + "|";
        }

        this.months_regex = this.months_regex[0:-1];

        this.weekdays_regex = "";
        for (int i = 0; i < 7; i++) {
            this.weekdays_regex += weekdays[i, 0] + "|";
        }

        this.weekdays_regex = this.weekdays_regex[0:-1];
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
            for (var i = 0; i < 4; i++) {
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

    void analyze_pattern (string pattern, transcribe_analysis del) {
        String_event data = complete_string ("\\b" + pattern + "\\b");
        if (data.matched) {
            this.remaining_source = this.remaining_source.splice (data.pos, data.pos + data.length);
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

        analyze_pattern ("vorgestern", (data) => {
            event.from = event.from.add_days (-2);
            event.set_one_entire_day ();
        });

        analyze_pattern ("gestern", (data) => {
            event.from = event.from.add_days (-1);
            event.set_one_entire_day ();
        });

        analyze_pattern ("(ab )?morgen", (data) => {
            event.from = event.from.add_days(1);
            event.set_one_entire_day();
        });

        analyze_pattern ("(ab )?übermorgen", (data) => {
            event.from = event.from.add_days (2);
            event.set_one_entire_day ();
        });

        analyze_pattern ("(den ganzen tag|ganztägig)", (data) => {
            event.set_one_entire_day ();
        });

        analyze_pattern ("vor (?<p1>\\d+) tagen", (data) => {
            int days = int.parse ( data.p.index(0) );
            event.from = event.from.add_days (-days);
            event.set_one_entire_day ();
        });

        analyze_pattern ("in (?<p1>\\d+) tagen", (data) => {
            int days = int.parse (data.p.index(0));
            event.from = event.from.add_days (days);
            event.set_one_entire_day();
        });

        analyze_pattern (@"diesen (?<p1>$weekdays_regex)", (data) => {
            int weekday = get_number_of_weekday (data.p.index (0));
            int add_days = (weekday - this.simulated_dt.get_day_of_week () + 7 ) % 7;
            event.from = event.from.add_days (add_days);

            event.set_one_entire_day ();
        });

        analyze_pattern (@"nächsten (?<p1>$weekdays_regex)", (data) => {
            int weekday = get_number_of_weekday (data.p.index (0));
            int add_days = (weekday - this.simulated_dt.get_day_of_week () + 7 ) % 7;
            event.from = event.from.add_days (add_days);

            event.set_one_entire_day ();
        });

        analyze_pattern (@"übernächsten (?<p1>$weekdays_regex)", (data) => {
            int weekday = get_number_of_weekday (data.p.index(0));
            int add_days = (weekday - this.simulated_dt.get_day_of_week () + 7 ) % 7;
            event.from = event.from.add_weeks (1);
            event.from = event.from.add_days (add_days);

            event.set_one_entire_day ();
        });

        analyze_pattern ("am (?<p1>\\d+).(?<p2>\\d+)(.(?<p3>\\d+))?", (data) => {
            int day = int.parse (data.p.index (0));
            int month = int.parse (data.p.index(1));

            event.from_set_day (day);
            event.set_one_entire_day ();

            event.from_set_month (month);
            event.to_set_month (month);

            if (data.p.index (2) != null ) {
                int year = int.parse (data.p.index (2));
                event.from_set_year (year);

                event.if_elapsed_delay_to_next_year (this.simulated_dt);
            }

            event.if_elapsed_delay_to_next_month (this.simulated_dt);
        });

        analyze_pattern (@"vom (?<p1>\\d+). bis (?<p2>\\d+). ((?<p3>$months_regex))?", (data) => {
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

        analyze_pattern (@"am (?<p1>\\d+)(.)?( (?<p2>$months_regex))?", (data) => {
            int day = int.parse (data.p.index (0));
            int month = get_number_of_month (data.p.index (1));

            event.from_set_day (day);
            event.from_set_month (month);
            event.set_one_entire_day ();

            event.if_elapsed_delay_to_next_year (this.simulated_dt);
        });

        analyze_pattern ("heiligabend", (data) => {
            event.from_set_month (12);
            event.from_set_day (24);
            event.set_one_entire_day ();

            event.if_elapsed_delay_to_next_year (this.simulated_dt);
        });

        // --- Time ---

        analyze_pattern ("früh", (data) => {
            event.from_set_hour (9);
            event.set_length_to_hours (1);
            event.all_day = false;
        });

        analyze_pattern ("vormittags", (data) => {
            event.from_set_hour (11);
            event.set_length_to_hours (1);
            event.all_day = false;
        });

        analyze_pattern ("mittag(s?)", (data) => {
            event.from_set_hour (12);
            event.set_length_to_hours (1);
            event.all_day = false;
        });

        analyze_pattern ("nachmittags", (data) => {
            event.from_set_hour (15);
            event.set_length_to_hours (1);
            event.all_day = false;
        });

        analyze_pattern ("abends", (data) => {
            event.from_set_hour (18);
            event.set_length_to_hours (1);
            event.all_day = false;
        });

        analyze_pattern ("spät", (data) => {
            event.from_set_hour (19);
            event.set_length_to_hours (3);
            event.all_day = false;
        });

        analyze_pattern ("(um|ab) (?<p1>\\d+)(:(?<p2>\\d+))?( (uhr|h))?", (data) => {
            int hour = int.parse (data.p.index (0));
            event.from_set_hour (hour);

            if (data.p.index (1) != null) {
                int minute_1 = int.parse (data.p.index (1));
                event.from_set_minute (minute_1);
            }

            event.set_length_to_hours (1);
            event.all_day = false;
        });

        analyze_pattern ("von (?<p1>\\d+)(:(?<p3>\\d+))? bis (?<p2>\\d+)(:(?<p4>\\d+))?( uhr)?", (data) => {
            int hour_1 = int.parse (data.p.index (0));
            int hour_2 = int.parse (data.p.index (1));

            event.from_set_hour (hour_1);
            event.to_set_hour (hour_2);

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

        analyze_pattern ("(?<p1>\\d+)(:(?<p2>\\d+))? (uhr|h)", (data) => {
            int hour = int.parse (data.p.index (0));
            event.from_set_hour (hour);

            if (data.p.index(1) != null) {
                int minute_1 = int.parse (data.p.index (1));
                event.from_set_minute (minute_1);
            }

            event.set_length_to_hours (1);
            event.all_day = false;
        });

        analyze_pattern ("für (?<p1>\\d+)(\\s?min| Minuten)", (data) => {
            int minutes = int.parse (data.p.index (0));
            event.set_length_to_minutes (minutes);
        });

        analyze_pattern ("für (?<p1>\\d+)(\\s?h| Stunden)", (data) => {
            int hours = int.parse (data.p.index (0));
            event.set_length_to_hours (hours);
        });

        analyze_pattern ("für (?<p1>\\d+)(\\s?d| Tage)", (data) => {
            int days = int.parse (data.p.index (0));
            event.set_length_to_days (days);
        });

        analyze_pattern ("für (?<p1>\\d+) Wochen", (data) => {
            int weeks = int.parse (data.p.index (0));
            event.set_length_to_weeks (weeks);
        });

        // --- Repetition ---

        // --- Persons ---

        // --- Location ----
        analyze_pattern ("(im|in dem) (?<p1>(\\w\\s?)+)", (data) => {
            event.location = data.p.index (0);
        });

        analyze_pattern ("in( der)? (?<p1>[a-z]+)", (data) => {
            event.location = data.p.index (0);
        });

        // --- Name ---

        event.title = this.remaining_source.strip ();

        return event;
    }

    public string get_language () {
        return "de";
    }
}

}
