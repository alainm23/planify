public class Objects.DueDate : GLib.Object {
    public string date { get; set; default = ""; }
    public string timezone { get; set; default = ""; }
    public bool is_recurring { get; set; default = false; }
    public RecurrencyType recurrency_type { get; set; default = RecurrencyType.NONE; }
    public int recurrency_interval { get; set; default = 0; }

    GLib.DateTime? _datetime = null;
    public GLib.DateTime? datetime {
        get {
            if (_datetime == null) {
                _datetime = Util.get_default ().get_todoist_datetime (date);
            }

            return _datetime;
        }
    }

    public DueDate.from_json (Json.Object object) {
        update_from_json (object);
    }

    construct {
        notify["date"].connect (() => {
            _datetime = null;
        });
    }

    public void update_from_json (Json.Object object) {
        if (object.has_member ("date")) {
            date = object.get_string_member ("date");
        }
        
        if (object.has_member ("timezone")) {
            timezone = object.get_string_member ("timezone");
        }

        if (object.has_member ("is_recurring")) {
            is_recurring = object.get_boolean_member ("is_recurring");
        }

        if (object.has_member ("recurrency_type")) {
            recurrency_type = (RecurrencyType) int.parse (object.get_string_member ("recurrency_type"));
        }

        if (object.has_member ("recurrency_interval")) {
            recurrency_interval = int.parse (object.get_string_member ("recurrency_interval"));
        }
    }

    public void reset () {
        date = "";
        timezone = "";
        recurrency_type = RecurrencyType.NONE;
        recurrency_interval = 0;
        is_recurring = false;
    }

    public string to_string () {
        var builder = new Json.Builder ();
        builder.begin_object ();

        builder.set_member_name ("date");
        builder.add_string_value (date);

        builder.set_member_name ("timezone");
        builder.add_string_value (timezone);

        builder.set_member_name ("is_recurring");
        builder.add_boolean_value (is_recurring);

        builder.set_member_name ("recurrency_type");
        builder.add_string_value (((int)recurrency_type).to_string ());

        builder.set_member_name ("recurrency_interval");
        builder.add_string_value (recurrency_interval.to_string ());

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public bool is_recurrency_equal (Objects.DueDate duedate) {
        return ((int) recurrency_type == (int) duedate.recurrency_type &&
        recurrency_interval == duedate.recurrency_interval &&
        is_recurring == duedate.is_recurring);
    }

    public string to_friendly_string () {
        return recurrency_type.to_friendly_string (recurrency_interval);
    }
}