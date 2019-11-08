class Planner.DateTime : Object {
    private GLib.DateTime datetime;
    private bool _valid = false;
    
    public DateTime () {
        datetime = new GLib.DateTime.now_local ();
    }

    public DateTime.from_string (string dateStr) {
        datetime = new GLib.DateTime.now_local ();
        parse(dateStr);
    }
    
    public bool parse (string dateStr) {
        if (dateStr.index_of (":") > -1) {
            //-- This is a time
            var parts = dateStr.split (":");
            var part = parts[0];
            var partsDate = part.split (" ");
            var parseDateStrArr = new string[partsDate.length - 1];
            for (var i = 0; i < partsDate.length - 1; i++) {
                parseDateStrArr[i] = partsDate[i];
            }
            var parseDateStr = string.joinv (" ", parseDateStrArr);
            var r = /([0-9]{2})\:([0-9]{2})\:([0-9\.]{2,6})/;
            var timeParts = r.split (dateStr);
            var hour = "00";
            var minute = "00";
            var second = "00";
            for (var i = 1; i < timeParts.length - 1; i++) {
                if (i == 1) {
                    hour = timeParts[i];
                }
                else if (i == 2) {
                    minute = timeParts[i];
                }
                else if (i == 3) {
                    second = timeParts[i];
                }
            }
            parse_date (parseDateStr);

            if (_valid) {
                datetime = new GLib.DateTime.local (
                    datetime.get_year(), get_month (), get_day_of_month (),
                    int.parse (hour), int.parse (minute), int.parse (second)
                );
            }

            return _valid;
        } else {
            return parse_date (dateStr);
        }
        
        return _valid;
    }
    
    public bool parse_date (string dateStr) {
        var parsed_date = Date ();
        parsed_date.set_parse (dateStr);
        
        if (parsed_date.valid ()) {
            var time = Time();
            parsed_date.to_time (out time);
            datetime = new GLib.DateTime.local (
                time.year, time.month, time.day,
                time.hour, time.minute, time.second
            );
            var output = new char[100];
            var format = "%c";
            var success = parsed_date.strftime (output, format);

            if (success == 0) {
                _valid = false;
                warning ("Failed to formart date.");
            } else {
                var formatted_output = ((string) output).chomp ();
                //message ("Parsed Date: '" + formatted_output + "'\n");
                _valid  = true;
            }
        } else {
            _valid = false;
            warning ("Failed to parse date.");
        }
        
        return _valid;
    }
    
    public string format(string format) {
        var result = format;
        string[] formats_types = {
            "a", "A", "b", "B", "c", "C", "d", "D", "e", "F", "g", "G", "h",
            "H", "I", "j", "k", "l", "m", "M", "p", "P", "r", "R", "s", "S",
            "t", "T", "u", "V", "w", "x", "X", "y", "Y", "z", "Z"
        };
        foreach (var format_type in formats_types) {
            var type = @"%$format_type";
            if (result.index_of (type) == -1) {
                continue;
            }
            if (type == "%Y") {
                result = result.replace(type, get_year ().to_string ());
            } else {
                result = result.replace(type, get_datetime ().format (type));
            }
        }
        
        return result;
    }

    public bool valid () {
        return _valid;
    }

    public GLib.DateTime get_datetime () {
        return datetime;
    }

    public int get_year () {
        return get_datetime ().get_year () + 1900;
    }

    public int get_month () {
        return get_datetime ().get_month ();
    }

    public int get_day_of_month () {
        return get_datetime ().get_day_of_month ();
    }

    public int get_hour () {
        return get_datetime ().get_hour ();
    }

    public int get_minute () {
        return get_datetime ().get_minute ();
    }

    public int get_second () {
        return get_datetime ().get_second ();
    }

    public int get_microsecond () {
        return get_datetime ().get_microsecond ();
    }

    public string to_string () {
        return datetime.to_string ();
    }
}