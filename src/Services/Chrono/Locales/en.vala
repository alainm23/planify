public class Services.Chrono.en : GLib.Object {
    static en _instance = null;
    public static en instance {
        get {
            if (_instance == null) {
                _instance = new en ();
            }
            return _instance;
        }
    }

    // CONSTANTS
    private string MONTHS_CONSTANT = "(?:jan((?:.)|(?:uary))?|feb((?:.)?|(?:ruary)?)|mar((?:.)?|(?:ch)?)|apr((?:.)?|(?:il)?)|may|jun((?:.)?|(?:e)?)|jul((?:.)?|(?:y)?)|aug((?:.)?|(?:ust)?)|sep((?:.)?|(?:tember)?)|oct((?:.)?|(?:ober)?)|nov((?:.)?|(?:ember)?)|dec((?:.)?|(?:ember)?))";
    private string WEEK_CONSTANT = "(?:sun((?:.)|(?:day))?|mon((?:.)?|(?:day)?)|tue((?:.)?|(?:sday)?)|wed((?:.)?|(?:nesday)?)|thu((?:.)?|(?:rsday)?)|fri((?:.)?|(?:day)?)|sat((?:.)?|(?:urday)?))";
    private string DAY_TH_CONSTANT = "(0[1-9]|[12]\\d|3[01])(th)";
    private string DAY_CONSTANT = "(0[1-9]|[12]\\d|3[01])";
    private string YEAR_CONSTANT = "(?:(?:19|20)[0-9]{2})"; // 1900 to 2099:
    private string PARSING_CONTEXT_CONSTANT = "(\\W|^)(today|tomorrow|tmr|yesterday|next\\sweek|next\\syear|(next\\smonth(s)?))";

    // 12:00 pm, 6pm, 6 pm, 6:00 pm, 3:00pm, 5:15am, 06:30 pm, 06:30pm, 06:30 pm
    private string TIME_VALID = "\\d{1,2}([:.]?\\d{1,2})?([ ]?[a|p]m)?";

    // UTILS
    private GLib.Regex ONLY_NUMBERS = /\d+(?=\W|$)/;

    // DATE
    private GLib.Regex PARSING_CONTEXT_REGEX;
    private GLib.Regex PARSING_CONTEXT_TIME_REGEX;
    private GLib.Regex MID_MONTH_REGEX;
    private GLib.Regex LAST_DAY_OF_THE_MONTH_REGEX;
    private GLib.Regex END_OF_MONTH_REGEX;
    private GLib.Regex DAY_REGEX;
    private GLib.Regex MONTH_REGEX;
    private GLib.Regex WEEK_REGEX;
    private GLib.Regex WEEK_REGEX_TIME_REGEX;
    private GLib.Regex MM_DD_TH_REGEX;
    private GLib.Regex MM_DD_REGEX;
    private GLib.Regex DD_TH_MM;
    private GLib.Regex DD_MM_REGEX;
    private GLib.Regex MM_DD_HH_MM_REGEX;
    private GLib.Regex MM_DD_TH_HH_MM_REGEX;
    private GLib.Regex MM_YYYY;
    private GLib.Regex YYYY_MM;

    private GLib.Regex MM_DD_TH_YYYY;
    private GLib.Regex MM_DD_YYYY;
    private GLib.Regex DD_TH_MM_YYYY;
    private GLib.Regex DD_MM_YYYY;
    private GLib.Regex MM_DD_TH_YYYY_TIME;
    private GLib.Regex MM_DD_YYYY_TIME;
    private GLib.Regex MM_DD_TH_YYYY_AT_TIME;

    // TIME
    private GLib.Regex TIME_REGEX;

    private GLib.Array<GLib.Regex> regex_list;

    construct {
        // DAY
        PARSING_CONTEXT_REGEX = new GLib.Regex (PARSING_CONTEXT_CONSTANT + "(?=\\W|$)");
        MID_MONTH_REGEX = new GLib.Regex ("(mid)\\s" + MONTHS_CONSTANT + "(?=\\W|$)");
        LAST_DAY_OF_THE_MONTH_REGEX = new GLib.Regex ("last\\sday(\\sof(\\sthe)?\\smonth)?(?=\\W|$)");
        END_OF_MONTH_REGEX = new GLib.Regex ("end\\sof\\smonth(?:s)?(?=\\W|$)");
        DAY_REGEX = new GLib.Regex (DAY_TH_CONSTANT + "(?=\\W|$)");
        MONTH_REGEX = new GLib.Regex (MONTHS_CONSTANT + "(?=\\W|$)");
        WEEK_REGEX = new GLib.Regex (WEEK_CONSTANT + "(?=\\W|$)");

        // MONTH DAY, DAY MONTH
        MM_DD_TH_REGEX = new GLib.Regex (MONTHS_CONSTANT + "\\s" + DAY_TH_CONSTANT + "(?=\\W|$)");
        MM_DD_REGEX = new GLib.Regex (MONTHS_CONSTANT + "\\s" + DAY_CONSTANT + "(?=\\W|$)");
        DD_TH_MM = new GLib.Regex (DAY_TH_CONSTANT + "\\s" + MONTHS_CONSTANT + "(?=\\W|$)");
        DD_MM_REGEX = new GLib.Regex (DAY_CONSTANT + "\\s" + MONTHS_CONSTANT + "(?=\\W|$)");
        PARSING_CONTEXT_TIME_REGEX = new GLib.Regex (PARSING_CONTEXT_CONSTANT + "\\s(at|@)\\s" + TIME_VALID + "(?=\\W|$)");
        WEEK_REGEX_TIME_REGEX = new GLib.Regex (WEEK_CONSTANT + "\\s(at|@)\\s" + TIME_VALID + "(?=\\W|$)");

        MM_YYYY = new GLib.Regex (MONTHS_CONSTANT + "\\s" + YEAR_CONSTANT + "(?=\\W|$)");
        YYYY_MM = new GLib.Regex (YEAR_CONSTANT + "\\s" + MONTHS_CONSTANT + "(?=\\W|$)");
        MM_DD_TH_YYYY = new GLib.Regex (MONTHS_CONSTANT + "\\s" + DAY_TH_CONSTANT + "\\s" + YEAR_CONSTANT + "(?=\\W|$)");
        MM_DD_YYYY = new GLib.Regex (MONTHS_CONSTANT + "\\s" + DAY_CONSTANT + "\\s" + YEAR_CONSTANT + "(?=\\W|$)");
        DD_TH_MM_YYYY = new GLib.Regex (DAY_TH_CONSTANT + "\\s" + MONTHS_CONSTANT + "\\s" + YEAR_CONSTANT + "(?=\\W|$)");
        DD_MM_YYYY = new GLib.Regex (DAY_CONSTANT + "\\s" + MONTHS_CONSTANT + "\\s" + YEAR_CONSTANT + "(?=\\W|$)");
        MM_DD_TH_YYYY_TIME = new GLib.Regex (MONTHS_CONSTANT + "\\s" + DAY_TH_CONSTANT + "\\s" + YEAR_CONSTANT + "\\s" + TIME_VALID + "(?=\\W|$)");
        MM_DD_YYYY_TIME = new GLib.Regex (MONTHS_CONSTANT + "\\s" + DAY_CONSTANT + "\\s" + YEAR_CONSTANT + "\\s" + TIME_VALID + "(?=\\W|$)");
        MM_DD_TH_YYYY_AT_TIME = new GLib.Regex (MONTHS_CONSTANT + "\\s" + DAY_TH_CONSTANT + "\\s" + YEAR_CONSTANT + "\\s(at|@)\\s" + TIME_VALID + "(?=\\W|$)");
        

        // April 23th 1pm, Jul 28 1pm 
        MM_DD_HH_MM_REGEX = new GLib.Regex (MONTHS_CONSTANT + "\\s" + DAY_CONSTANT + "\\s" + TIME_VALID + "(?=\\W|$)");
        MM_DD_TH_HH_MM_REGEX = new GLib.Regex (MONTHS_CONSTANT + "\\s" + DAY_TH_CONSTANT + "\\s" + TIME_VALID + "(?=\\W|$)");

        TIME_REGEX = new GLib.Regex (TIME_VALID + "(?=\\W|$)");

        regex_list = new GLib.Array<GLib.Regex> ();
        regex_list.append_val (MM_DD_TH_YYYY_TIME);
        regex_list.append_val (MM_DD_YYYY_TIME);
        regex_list.append_val (MM_DD_TH_YYYY_AT_TIME);
        regex_list.append_val (PARSING_CONTEXT_REGEX);
        regex_list.append_val (PARSING_CONTEXT_TIME_REGEX);
        regex_list.append_val (MID_MONTH_REGEX);
        regex_list.append_val (LAST_DAY_OF_THE_MONTH_REGEX);
        regex_list.append_val (END_OF_MONTH_REGEX);
        regex_list.append_val (DAY_REGEX);
        regex_list.append_val (MONTH_REGEX);
        regex_list.append_val (WEEK_REGEX);
        regex_list.append_val (MM_DD_TH_REGEX);
        regex_list.append_val (MM_DD_REGEX);
        regex_list.append_val (DD_TH_MM);
        regex_list.append_val (DD_MM_REGEX);
        regex_list.append_val (MM_DD_TH_YYYY);
        regex_list.append_val (MM_DD_YYYY);
        regex_list.append_val (DD_TH_MM_YYYY);
        regex_list.append_val (DD_MM_YYYY);
        regex_list.append_val (MM_DD_HH_MM_REGEX);
        regex_list.append_val (MM_DD_TH_HH_MM_REGEX);
        regex_list.append_val (WEEK_REGEX_TIME_REGEX);
        regex_list.append_val (TIME_REGEX);
        regex_list.append_val (MM_YYYY);
        regex_list.append_val (YYYY_MM);
    }
    
    public Objects.Duedate? parse (string expression) {
        for (int i = 0; i < regex_list.length ; i++) {
            var regex = regex_list.index (i);
            if (Planner.utils.check_regex (regex, expression)) {
                return get_regex (regex, expression);
            }
        }

        return null;
    }

    private Objects.Duedate? get_regex (GLib.Regex regex, string expression) {
        if (regex == PARSING_CONTEXT_REGEX) {
            return get_parsing_context (expression);
        } else if (regex == MID_MONTH_REGEX) {
            return get_mid_month_regex (expression);
        } else if (regex == LAST_DAY_OF_THE_MONTH_REGEX || regex == END_OF_MONTH_REGEX) {
            return get_end_of_month_refex ();
        } else if (regex == DAY_REGEX) {
            return get_day_current_month (expression);
        } else if (regex == MONTH_REGEX) {
            return get_current_month (expression);
        } else if (regex == WEEK_REGEX) {
            return get_week (expression);
        } else if (regex == MM_DD_TH_REGEX || regex == MM_DD_REGEX) {
            return get_mm_dd (expression, 0, 1);
        } else if (regex == DD_TH_MM || regex == DD_MM_REGEX) {
            return get_mm_dd (expression, 1, 0);
        } else if (regex == TIME_REGEX) {
            return get_time (expression);
        } else if (regex == MM_DD_TH_HH_MM_REGEX || regex == MM_DD_HH_MM_REGEX) {
            return get_mm_dd_hh_mm (expression, 0, 1);
        } else if (regex == PARSING_CONTEXT_TIME_REGEX) {
            return get_parsing_context_time_date (expression);
        } else if (regex == WEEK_REGEX_TIME_REGEX) {
            return get_week_time (expression);
        } else if (regex == MM_YYYY) {
            return get_month_year (expression, 0, 1);
        } else if (regex == YYYY_MM) {
            return get_month_year (expression, 1, 0);
        } else if (regex == MM_DD_TH_YYYY || regex == MM_DD_YYYY) {
            return get_month_dd_year (expression, 0, 1);
        } else if (regex == DD_TH_MM_YYYY || regex == DD_MM_YYYY) {
            return get_month_dd_year (expression, 1, 0);
        } else if (regex == MM_DD_TH_YYYY_TIME || regex == MM_DD_YYYY_TIME) {
            return get_month_dd_year_time (expression);
        } else if (regex == MM_DD_TH_YYYY_AT_TIME) {
            return get_month_dd_year_at_time (expression);
        }

        return null;
    }

    private Objects.Duedate? get_parsing_context (string expression) {
        var now = new GLib.DateTime.now_local ();

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = "en";
        parsed_result.datetime = get_parsing_context_date (expression);

        return parsed_result;
    }

    private GLib.DateTime? get_parsing_context_date (string expression) {
        GLib.DateTime? returned = null;
        var now = new GLib.DateTime.now_local ();

        if (expression == "today") {
            returned = Planner.utils.get_format_date (new GLib.DateTime.now_local ());
        } else if (expression == "tomorrow" || expression == "tmr") {
            returned = Planner.utils.get_format_date (new GLib.DateTime.now_local ().add_days (1));
        } else if (expression == "yesterday") {
            returned = Planner.utils.get_format_date (new GLib.DateTime.now_local ().add_days (-1));
        } else if (expression == "next week") {
            returned = Planner.utils.get_format_date (new GLib.DateTime.now_local ().add_days (7));
        } else if (expression == "next year") {
            returned = new GLib.DateTime.local (
                now.get_year () + 1, 1, 1, 0, 0, 0
            );
        } else if (expression == "next month" || expression == "next months") {
            returned = new GLib.DateTime.local (
                now.get_year (),
                now.get_month () + 1,
                1, 0, 0, 0
            );
        }

        return returned;
    }

    private Objects.Duedate? get_mid_month_regex (string expression) {
        if (get_month_number_by_query (expression.split (" ") [1]) <= 0) {
            return null;
        }

        var month = get_month_number_by_query (expression.split (" ") [1]);

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = "en";
        parsed_result.datetime = new GLib.DateTime.local (
            new GLib.DateTime.now_local ().get_year (),
            month,
            15,
            0,
            0,
            0
        );

        return parsed_result;
    }

    private Objects.Duedate? get_end_of_month_refex () {
        var date_now = new GLib.DateTime.now_local ();

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = "en";
        parsed_result.datetime = new GLib.DateTime.local (
            date_now.get_year (),
            date_now.get_month (),
            Planner.utils.get_days_of_month (date_now.get_month (), date_now.get_year ()),
            0,
            0,
            0
        );

        return parsed_result;
    }

    private Objects.Duedate? get_day_current_month (string expression) {
        int day = int.parse (expression.slice (0, -2));

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = "en";
        parsed_result.datetime = new GLib.DateTime.local (
            new GLib.DateTime.now_local ().get_year (),
            new GLib.DateTime.now_local ().get_month (),
            day,
            0,
            0,
            0
        );

        return parsed_result;
    }

    private Objects.Duedate? get_current_month (string expression) {
        if (get_month_number_by_query (expression) <= 0) {
            return null;
        }

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = "en";
        parsed_result.datetime = new GLib.DateTime.local (
            new GLib.DateTime.now_local ().get_year (),
            get_month_number_by_query (expression),
            1,
            0,
            0,
            0
        );

        return parsed_result;
    }

    private GLib.DateTime? get_date_by_week (string expression) {
        if (get_week_number_by_query (expression) <= 0) {
            return null;
        }

        var now = new GLib.DateTime.now_local ();
        var current_day = now.get_day_of_week ();
        int day = get_week_number_by_query (expression);

        if (day > current_day) {
            now = now.add_days (day - current_day);
        } else {
            now = now.add_days (7 - current_day + day);
        }

        return now;
    }

    private Objects.Duedate? get_week (string expression) {
        if (get_date_by_week (expression) == null) {
            return null;
        }

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = "en";
        parsed_result.datetime = get_date_by_week (expression);

        return parsed_result;
    }

    private Objects.Duedate? get_week_time (string expression) {
        var date = get_date_by_week (expression.split (" ") [0]);
        if (date == null) {
            return null;
        }

        var time = parse_time (expression.split (" ") [2].dup ());

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = "en";
        parsed_result.datetime = new GLib.DateTime.local (
            date.get_year (),
            date.get_month (),
            date.get_day_of_month (),
            time.get_hour (),
            time.get_minute (),
            0
        );

        return parsed_result;
    }

    private Objects.Duedate? get_mm_dd (string expression, int y, int d) {
        if (get_month_number_by_query (expression.split (" ") [y]) <= 0) {
            return null;
        }

        int month = get_month_number_by_query (expression.split (" ") [y]);
        var day_string = expression.split (" ") [d];

        int day = 0;
        if (Planner.utils.check_regex (ONLY_NUMBERS, day_string)) {
            day = int.parse (day_string);
        } else {
            day = int.parse (day_string.slice (0, -2));
        }

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = "en";
        parsed_result.datetime = new GLib.DateTime.local (
            new GLib.DateTime.now_local ().get_year (),
            month,
            day,
            0,
            0,
            0
        );

        return parsed_result;
    }

    private Objects.Duedate? get_time (string expression) {
        var date = parse_time (expression.dup ());

        if (date.compare (new GLib.DateTime.now_local ()) <= 0) {
            date = date.add_days (1);
        }

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = "en";
        parsed_result.datetime = date;

        return parsed_result;
    }

    private Objects.Duedate? get_mm_dd_hh_mm (string expression, int m, int d) {
        if (get_month_number_by_query (expression.split (" ") [m]) <= 0) {
            return null;
        }

        int month = get_month_number_by_query (expression.split (" ") [m]);
        var day_string = expression.split (" ") [d];

        int day = 0;
        if (Planner.utils.check_regex (ONLY_NUMBERS, day_string)) {
            day = int.parse (day_string);
        } else {
            day = int.parse (day_string.slice (0, -2));
        }

        var time = parse_time (expression.split (" ") [2].dup ());

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = "en";
        parsed_result.datetime = new GLib.DateTime.local (
            new GLib.DateTime.now_local ().get_year (),
            month,
            day,
            time.get_hour (),
            time.get_minute (),
            0
        );

        return parsed_result;
    }

    private Objects.Duedate? get_parsing_context_time_date (string expression) {
        GLib.DateTime? date;
        GLib.DateTime? time;

        if (expression.split (" ").length <= 3) {
            date = get_parsing_context_date (expression.split (" ") [0]);
            time = parse_time (expression.split (" ") [2].dup ());
        } else {
            date = get_parsing_context_date (
                "%s %s".printf (expression.split (" ") [0], expression.split (" ") [1])
            );
            time = parse_time (expression.split (" ") [3].dup ());
        }

        if (date == null || time == null) {
            return null;
        }

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = "en";
        parsed_result.datetime = new GLib.DateTime.local (
            date.get_year (),
            date.get_month (),
            date.get_day_of_month (),
            time.get_hour (),
            time.get_minute (),
            0
        );

        return parsed_result;
    }

    private Objects.Duedate? get_month_year (string expression, int m, int y) {
        if (get_month_number_by_query (expression.split (" ") [m]) <= 0) {
            return null;
        }

        var month = get_month_number_by_query (expression.split (" ") [m]);
        var year = int.parse (expression.split (" ") [y]);

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = "en";
        parsed_result.datetime = new GLib.DateTime.local (
            year,
            month,
            1, 0, 0, 0
        );

        return parsed_result;
    }

    private Objects.Duedate? get_month_dd_year (string expression, int m, int d) {
        if (get_month_number_by_query (expression.split (" ") [m]) <= 0) {
            return null;
        }

        int month = get_month_number_by_query (expression.split (" ") [m]);
        var day_string = expression.split (" ") [d];
        var year = int.parse (expression.split (" ") [2]);

        int day = 0;
        if (Planner.utils.check_regex (ONLY_NUMBERS, day_string)) {
            day = int.parse (day_string);
        } else {
            day = int.parse (day_string.slice (0, -2));
        }

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = "en";
        parsed_result.datetime = new GLib.DateTime.local (
            year,
            month,
            day, 0, 0, 0
        );

        return parsed_result;
    }

    private Objects.Duedate? get_month_dd_year_time (string expression) {
        if (get_month_number_by_query (expression.split (" ") [0]) <= 0) {
            return null;
        }

        int month = get_month_number_by_query (expression.split (" ") [0]);
        var day_string = expression.split (" ") [1];
        var year = int.parse (expression.split (" ") [2]);
        var time = parse_time (expression.split (" ") [3].dup ());

        int day = 0;
        if (Planner.utils.check_regex (ONLY_NUMBERS, day_string)) {
            day = int.parse (day_string);
        } else {
            day = int.parse (day_string.slice (0, -2));
        }

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = "en";
        parsed_result.datetime = new GLib.DateTime.local (
            year,
            month,
            day,
            time.get_hour (),
            time.get_minute (),
            0
        );

        return parsed_result;
    }

    private Objects.Duedate? get_month_dd_year_at_time (string expression) {
        print ("Exp: %s\n".printf (expression));
        if (get_month_number_by_query (expression.split (" ") [0]) <= 0) {
            return null;
        }

        int month = get_month_number_by_query (expression.split (" ") [0]);
        var day_string = expression.split (" ") [1];
        var year = int.parse (expression.split (" ") [2]);
        var time = parse_time (expression.split (" ") [4].dup ());

        int day = 0;
        if (Planner.utils.check_regex (ONLY_NUMBERS, day_string)) {
            day = int.parse (day_string);
        } else {
            day = int.parse (day_string.slice (0, -2));
        }

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = "en";
        parsed_result.datetime = new GLib.DateTime.local (
            year,
            month,
            day,
            time.get_hour (),
            time.get_minute (),
            0
        );

        return parsed_result;
    }

    private GLib.DateTime parse_time (string timestr) {
        var time = new GLib.DateTime.now_local ();
        string current = "";
        bool is_hours = true;
        bool is_suffix = false;
        bool has_suffix = false;

        int? hour = null;
        int? minute = null;
        foreach (var c in timestr.down ().to_utf8 ()) {
            if (c.isdigit ()) {
                current = "%s%c".printf (current, c);
            } else {
                if (!is_suffix) {
                    if (current != "") {
                        if (is_hours) {
                            is_hours = false;
                            hour = int.parse (current);
                            current = "";
                        } else {
                            minute = int.parse (current);
                            current = "";
                        }
                    }

                    if (c.to_string ().contains ("a") || c.to_string ().contains ("p")) {
                        is_suffix = true;
                        current = "%s%c".printf (current, c);
                    }
                }

                if (c.to_string ().contains ("m") && is_suffix) {
                    if (hour == null) {
                        return time;
                    } else if (minute == null) {
                        minute = 0;
                    }

                    // We can imagine that some will try to set it to "19:00 am"
                    if (current.contains ("a") || hour >= 12) {
                        time = time.add_hours (hour - time.get_hour ());
                    } else {
                        time = time.add_hours (hour + 12 - time.get_hour ());
                    }

                    if (current.contains ("a") && hour == 12) {
                        time = time.add_hours (-12);
                    }

                    time = time.add_minutes (minute - time.get_minute ());
                    has_suffix = true;
                }
            }
        }

        if (is_hours == false && is_suffix == false && current != "") {
            minute = int.parse (current);
        }

        if (hour == null) {
            if (current.length < 3) {
                hour = int.parse (current);
                minute = 0;
            } else if (current.length == 4) {
                hour = int.parse (current.slice (0, 2));
                minute = int.parse (current.slice (2, 4));
                if (hour > 23 || minute > 59) {
                    hour = null;
                    minute = null;
                }
            }
        }

        if (hour == null || minute == null) {
            return time;
        }

        if (has_suffix == false) {
            time = time.add_hours (hour - time.get_hour ());
            time = time.add_minutes (minute - time.get_minute ());
        }

        return time;
    }

    private int get_month_number_by_query (string name) {
        int returned = 0;

        if (FULL_MONTH_NAME_DICTIONARY ().has_key (name)) {
            returned = FULL_MONTH_NAME_DICTIONARY ().get (name);
        } else if (MONTH_DICTIONARY ().has_key (name)) {
            returned = MONTH_DICTIONARY ().get (name);
        }

        return returned;
    }

    private int get_week_number_by_query (string name) {
        int returned = 0;

        if (WEEK_DICTIONARY ().has_key (name)) {
            returned = WEEK_DICTIONARY ().get (name);
        }

        return returned;
    }

    private Gee.HashMap<string, int> FULL_MONTH_NAME_DICTIONARY () {
        var map = new Gee.HashMap<string, int> ();
        
        map.set ("january", 1);
        map.set ("february", 2);
        map.set ("march", 3);
        map.set ("april", 4);
        map.set ("may", 5);
        map.set ("june", 6);
        map.set ("july", 7);
        map.set ("august", 8);
        map.set ("september", 9);
        map.set ("october", 10);
        map.set ("november", 11);
        map.set ("december", 12);
        
        return map;
    }

    private Gee.HashMap<string, int> MONTH_DICTIONARY () {
        var map = new Gee.HashMap<string, int> ();
        
        map.set ("jan", 1);
        map.set ("jan.", 1);
        
        map.set ("feb", 2);
        map.set ("feb.", 2);
        
        map.set ("mar", 3);
        map.set ("mar.", 3);
        
        map.set ("apr", 4);
        map.set ("apr.", 4);
        
        map.set ("may", 5);
        map.set ("may.", 5);
        
        map.set ("jun", 6);
        map.set ("jun.", 6);
        
        map.set ("jul", 7);
        map.set ("jul.", 7);
        
        map.set ("aug", 8);
        map.set ("aug.", 8);
        
        map.set ("sep", 9);
        map.set ("sep.", 9);
        
        map.set ("oct", 10);
        map.set ("oct.", 10);
        
        map.set ("nov", 11);
        map.set ("nov.", 11);
        
        map.set ("dec", 12);
        map.set ("dec.", 12);

        return map;
    }

    private Gee.HashMap<string, int> WEEK_DICTIONARY () {
        var map = new Gee.HashMap<string, int> ();
        
        map.set ("monday", 1);
        map.set ("mon.", 1);
        map.set ("mon", 1);
        
        map.set ("tuesday", 2);
        map.set ("tue.", 2);
        map.set ("tue", 2);
        
        map.set ("wednesday", 3);
        map.set ("wed.", 3);
        map.set ("wed", 3);
        
        map.set ("thursday", 4);
        map.set ("thu.", 4);
        map.set ("thu", 4);
        
        map.set ("friday", 5);
        map.set ("fri.", 5);
        map.set ("fri", 5);
        
        map.set ("saturday", 6);
        map.set ("sat.", 6);
        map.set ("sat", 6);

        map.set ("sunday", 6);
        map.set ("sun.", 6);
        map.set ("sun", 6);

        return map;
    }
}