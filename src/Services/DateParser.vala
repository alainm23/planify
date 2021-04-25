public class Services.DateParser : Object {
    /*--- UTILS */
    private GLib.Regex ONLY_NUMBERS = /\d+(?=\W|$)/;

    /*---- EN ----*/
    private GLib.Regex PARSING_CONTEXT_EN = /(now|today|tomorrow|tmr|yesterday)(?=\W|$)/;
    private GLib.Regex EVERY_DAY_REGEX_EN = /(every (day|days))(?=\W|$)/;
    private GLib.Regex EVERY_N_DAYS_REGEX_EN = /(every \d+ (day|days))(?=\W|$)/;
    private GLib.Regex NEXT_MONTH_EN = /(next month(s)?)(?=\W|$)/;
    private GLib.Regex DATE_FORMAT_01_EN = /(jan(.)?(uary)?|feb(.)?(ruary)?|mar(.)?(ch)?|apr(.)?(il)?|may(.)?|jun(.)?(e)?|jul(.)?(y)?|aug(.)?(ust)?|sep(.)?(tember)?|oct(.)?(ober)?|nov(.)?(ember)?|dec(.)?(ember)?)\s+\d{1,2}(th)?(?=\W|$)/;
    private GLib.Regex DATE_FORMAT_02_EN = /\d{1,2}(th)?\s+(jan(.)?(uary)?|feb(.)?(ruary)?|mar(.)?(ch)?|apr(.)?(il)?|may(.)?|jun(.)?(e)?|jul(.)?(y)?|aug(.)?(ust)?|sep(.)?(tember)?|oct(.)?(ober)?|nov(.)?(ember)?|dec(.)?(ember)?)(?=\W|$)/;
    private GLib.Regex DATE_FORMAT_03_EN = /(\d{1,2})[\/](\d{1,2})(?=\W|$)/;
    private GLib.Regex DATE_FORMAT_04_EN = /(jan(.)?(uary)?|feb(.)?(ruary)?|mar(.)?(ch)?|apr(.)?(il)?|may(.)?|jun(.)?(e)?|jul(.)?(y)?|aug(.)?(ust)?|sep(.)?(tember)?|oct(.)?(ober)?|nov(.)?(ember)?|dec(.)?(ember)?)\s+\d{1,2}(,)?(th)?\s(\d{1,4})?(?=\W|$)/;
    private GLib.Regex DATE_FORMAT_05_EN = /(\d{1,4})\s(jan(.)?(uary)?|feb(.)?(ruary)?|mar(.)?(ch)?|apr(.)?(il)?|may(.)?|jun(.)?(e)?|jul(.)?(y)?|aug(.)?(ust)?|sep(.)?(tember)?|oct(.)?(ober)?|nov(.)?(ember)?|dec(.)?(ember)?)\s+\d{1,2}(th)?(?=\W|$)/;
    private GLib.Regex DATE_FORMAT_06_EN = /\d{1,4}(th)?(?=\W|$)/;
    private GLib.Regex MID_MONTH_EN = /(mid)\s(jan(.)?(uary)?|feb(.)?(ruary)?|mar(.)?(ch)?|apr(.)?(il)?|may(.)?|jun(.)?(e)?|jul(.)?(y)?|aug(.)?(ust)?|sep(.)?(tember)?|oct(.)?(ober)?|nov(.)?(ember)?|dec(.)?(ember)?)(?=\W|$)/;
    private GLib.Regex END_OF_MONTH_EN = /last\sday(\sof(\sthe)?\smonth)?(?=\W|$)/;

    /*---- ES ----*/
    // private GLib.Regex EVERY_N_DAYS_REGEX_ES = /(cada \d+ (dia|dias))(?=\W|$)/;

    private Gee.HashMap<string, GLib.Array<GLib.Regex>> regex_map;

    construct {
        regex_map = new Gee.HashMap<string, GLib.Array<GLib.Regex>> ();

        var array = new GLib.Array<GLib.Regex> ();
        array.append_val (PARSING_CONTEXT_EN);
        array.append_val (EVERY_DAY_REGEX_EN);
        array.append_val (EVERY_N_DAYS_REGEX_EN);
        array.append_val (NEXT_MONTH_EN);
        array.append_val (DATE_FORMAT_01_EN);
        array.append_val (DATE_FORMAT_02_EN);
        array.append_val (DATE_FORMAT_03_EN);
        array.append_val (DATE_FORMAT_04_EN);
        array.append_val (DATE_FORMAT_05_EN);
        array.append_val (DATE_FORMAT_06_EN);
        array.append_val (MID_MONTH_EN);
        array.append_val (END_OF_MONTH_EN);

        regex_map ["en"] = array;
    }

    private bool check_regex (GLib.Regex regex, string expression) {
        MatchInfo info;
        var returned = false;
        try {
            if (regex.match_all (expression, 0, out info)) {
                if (info.fetch_all ().length > 0) {
                    returned = expression == info.fetch_all () [0];
                }                   
            }    
        } catch (GLib.RegexError ex) {
            returned = false;
        }

        return returned;
    }

    public Objects.Duedate? parse (string expression, string lang="en") {
        if (regex_map.has_key (lang)) {
            for (int i = 0; i < regex_map [lang].length ; i++) {
                var regex = regex_map [lang].index (i);
                if (check_regex (regex, expression)) {
                    return get_regex (regex, expression, lang);
                }
            }
        }

        return null;
    }

    private Objects.Duedate? get_regex (GLib.Regex regex, string expression, string lang) {
        if (regex == PARSING_CONTEXT_EN) {
            return get_parsing_context_date (expression, lang);
        } else if (regex == EVERY_N_DAYS_REGEX_EN || regex == EVERY_DAY_REGEX_EN) {
            return get_every_n_days_date (expression, lang);
        } else if (regex == NEXT_MONTH_EN) {
            return get_next_month (lang);
        } else if (regex == DATE_FORMAT_01_EN) {
            return get_date_format_01 (expression, lang);
        } else if (regex == DATE_FORMAT_02_EN) {
            return get_date_format_02 (expression, lang);
        } else if (regex == DATE_FORMAT_03_EN) {
            return get_date_format_03 (expression, lang);
        } else if (regex == DATE_FORMAT_04_EN) {
            return get_date_format_04 (expression, lang);
        } else if (regex == DATE_FORMAT_05_EN) {
            return get_date_format_05 (expression, lang);
        } else if (regex == DATE_FORMAT_06_EN) {
            return get_date_format_06 (expression, lang);
        } else if (regex == MID_MONTH_EN) {
            return get_mid_month (expression, lang);
        } else if (regex == END_OF_MONTH_EN) {
            return get_end_of_month (expression, lang);
        }

        return null;
    }

    private Objects.Duedate? get_parsing_context_date (string expression, string lang) {
        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = lang;

        if (expression == "now" || expression == "today") {
            parsed_result.date = Planner.utils.get_format_date (new GLib.DateTime.now_local ());
        } else if (expression == "tomorrow" || expression == "tmr") {
            parsed_result.date = Planner.utils.get_format_date (new GLib.DateTime.now_local ().add_days (1));
        } else if (expression == "yesterday") {
            parsed_result.date = Planner.utils.get_format_date (new GLib.DateTime.now_local ().add_days (-1));
        }

        return parsed_result;
    }

    private Objects.Duedate? get_every_n_days_date (string expression, string lang) {
        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = lang;
        parsed_result.is_recurring = true;
        parsed_result.text = expression;
        parsed_result.date = Planner.utils.get_format_date (new GLib.DateTime.now_local ());

        return parsed_result;
    }

    private Objects.Duedate? get_next_month (string lang) {
        var now = new GLib.DateTime.now_local ();

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = lang;
        parsed_result.text = "";
        parsed_result.date = new GLib.DateTime.local (
            now.get_year (),
            now.get_month () + 1,
            1,
            0,
            0,
            0
        );

        return parsed_result;
    }

    private Objects.Duedate? get_date_format_01 (string expression, string lang) {
        var month = Planner.utils.get_month_number_by_query (expression.split (" ") [0]);
        var day_string = expression.split (" ") [1];

        int day = 0;
        if (check_regex (ONLY_NUMBERS, day_string)) {
            day = int.parse (day_string);
        } else {
            day = int.parse (day_string.slice (0, -2));
        }

        if (month == 0 || day <= 0 || day > Planner.utils.get_days_of_month (month, new GLib.DateTime.now_local ().get_year ())) {
            return null;
        }

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = lang;

        parsed_result.date = new GLib.DateTime.local (
            new GLib.DateTime.now_local ().get_year (),
            month,
            day,
            0,
            0,
            0
        );

        return parsed_result;
    }

    private Objects.Duedate? get_date_format_02 (string expression, string lang) {
        var day_string = expression.split (" ") [0];
        var month = Planner.utils.get_month_number_by_query (expression.split (" ") [1]);

        int day = 0;
        if (check_regex (ONLY_NUMBERS, day_string)) {
            day = int.parse (day_string);
        } else {
            day = int.parse (day_string.slice (0, -2));
        }

        if (month == 0 || day <= 0 || day > Planner.utils.get_days_of_month (month, new GLib.DateTime.now_local ().get_year ())) {
            return null;
        }

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = lang;
        
        parsed_result.date = new GLib.DateTime.local (
            new GLib.DateTime.now_local ().get_year (),
            month,
            day,
            0,
            0,
            0
        );

        return parsed_result;
    }

    private Objects.Duedate? get_date_format_03 (string expression, string lang) {
        var day = int.parse (expression.split ("/") [0]);
        var month = int.parse (expression.split ("/") [1]);

        if (month <= 0 || month > 12) {
            return null;
        }

        if (day <= 0 || day > Planner.utils.get_days_of_month (month, new GLib.DateTime.now_local ().get_year ())) {
            return null;
        }

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = lang;
        
        parsed_result.date = new GLib.DateTime.local (
            new GLib.DateTime.now_local ().get_year (),
            month,
            day,
            0,
            0,
            0
        );

        return parsed_result;
    }

    private Objects.Duedate? get_date_format_04 (string expression, string lang) {
        var month_string = expression.split (" ") [0];
        var day_string = expression.split (" ") [1];
        var year_string = expression.split (" ") [2];

        int day = 0;
        int month = Planner.utils.get_month_number_by_query (month_string);
        int year = int.parse (year_string);

        if (check_regex (ONLY_NUMBERS, day_string)) {
            day = int.parse (day_string);
        } else {
            if (day_string.index_of ("th") > 0)  {
                day = int.parse (day_string.slice (0, -2));
            } else {
                day = int.parse (day_string.slice (0, -1));
            }
        }

        if (year < 1900 || year > 2200 || day == 0 || month == 0 || day <= 0 || day > Planner.utils.get_days_of_month (month, year)) {
            return null;
        }

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = lang;

        parsed_result.date = new GLib.DateTime.local (
            year,
            month,
            day,
            0,
            0,
            0
        );

        return parsed_result;
    }

    private Objects.Duedate? get_date_format_05 (string expression, string lang) {
        var year_string = expression.split (" ") [0];
        var month_string = expression.split (" ") [1];
        var day_string = expression.split (" ") [2];

        int day = 0;
        int month = Planner.utils.get_month_number_by_query (month_string);
        int year = int.parse (year_string);

        if (check_regex (ONLY_NUMBERS, day_string)) {
            day = int.parse (day_string);
        } else {
            if (day_string.index_of ("th") > 0)  {
                day = int.parse (day_string.slice (0, -2));
            } else {
                day = int.parse (day_string.slice (0, -1));
            }
        }

        if (year < 1900 || year > 2200 || day == 0 || month == 0 || day <= 0 || day > Planner.utils.get_days_of_month (month, year)) {
            return null;
        }

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = lang;

        parsed_result.date = new GLib.DateTime.local (
            year,
            month,
            day,
            0,
            0,
            0
        );

        return parsed_result;
    }

    private Objects.Duedate? get_date_format_06 (string expression, string lang) {
        var date_now = new GLib.DateTime.now_local ();

        int day = 0;
        if (check_regex (ONLY_NUMBERS, expression)) {
            day = int.parse (expression);
        } else {
            day = int.parse (expression.slice (0, -2));
        }

        if (day <= 0 || day > Planner.utils.get_days_of_month (date_now.get_month (), date_now.get_year ())) {
            return null;
        }

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = lang;
        parsed_result.date = new GLib.DateTime.local (
            date_now.get_year (),
            date_now.get_month (),
            day,
            0,
            0,
            0
        );

        return parsed_result;
    }

    private Objects.Duedate? get_mid_month (string expression, string lang) {
        var date_now = new GLib.DateTime.now_local ();
        var month = Planner.utils.get_month_number_by_query (expression.split (" ") [1]);

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = lang;
        parsed_result.date = new GLib.DateTime.local (
            date_now.get_year (),
            date_now.get_month (),
            15,
            0,
            0,
            0
        );

        return parsed_result;
    }

    private Objects.Duedate? get_end_of_month (string expression, string lang) {
        var date_now = new GLib.DateTime.now_local ();

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = lang;
        parsed_result.date = new GLib.DateTime.local (
            date_now.get_year (),
            date_now.get_month (),
            Planner.utils.get_days_of_month (date_now.get_month (), date_now.get_year ()),
            0,
            0,
            0
        );

        return parsed_result;
    }
}
