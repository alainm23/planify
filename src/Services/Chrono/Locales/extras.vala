public class Services.Chrono.extras : GLib.Object {
    static extras _instance = null;
    public static extras instance {
        get {
            if (_instance == null) {
                _instance = new extras ();
            }
            return _instance;
        }
    }

    // dd/mm/yyyy, dd-mm-yyyy or dd.mm.yyyy
    private GLib.Regex DATE_01 = /^[0-3]?[0-9].[0-3]?[0-9].(?:[0-9]{2})?[0-9]{2}$/;

    private GLib.Array<GLib.Regex> regex_list;

    construct {
        regex_list = new GLib.Array<GLib.Regex> ();
        regex_list.append_val (DATE_01);
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
        if (regex == DATE_01) {
            return get_date_01 (expression);
        }

        return null;
    }

    private Objects.Duedate? get_date_01 (string expression) {
        int year = 0;
        int month = 0;
        int day = 0;

        if (expression.split ("/").length == 3) {
            day = int.parse (expression.split ("/") [0]);
            month = int.parse (expression.split ("/") [1]);
            year = Planner.utils.find_most_likely_ad_year (
                int.parse (expression.split ("/") [2])
            );
        } else if (expression.split (".").length == 3) {
            day = int.parse (expression.split (".") [0]);
            month = int.parse (expression.split (".") [1]);
            year = Planner.utils.find_most_likely_ad_year (
                int.parse (expression.split (".") [2])
            );
        } else if (expression.split ("-").length == 3) {
            day = int.parse (expression.split ("-") [0]);
            month = int.parse (expression.split ("-") [1]);
            year = Planner.utils.find_most_likely_ad_year (
                int.parse (expression.split ("-") [2])
            );
        } else {
            return null;
        }

        var parsed_result = new Objects.Duedate ();
        parsed_result.lang = "en";
        parsed_result.datetime = new GLib.DateTime.local (
            year,
            month,
            day,
            0,
            0,
            0
        );

        return parsed_result;
    }
}