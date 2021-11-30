public class Objects.DueDate : GLib.Object {
    public string date { get; set; default = ""; }
    public string timezone { get; set; default = ""; }
    public string text { get; set; default = ""; }
    public string lang { get; set; default = ""; }
    public bool is_recurring { get; set; default = false; }

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
        if (!object.get_null_member ("date")) {
            date = object.get_string_member ("date");
        }
        
        if (!object.get_null_member ("timezone")) {
            timezone = object.get_string_member ("timezone");
        }
        
        if (!object.get_null_member ("string")) {
            text = object.get_string_member ("string");
        }

        if (!object.get_null_member ("lang")) {
            lang = object.get_string_member ("lang");
        }

        if (!object.get_null_member ("is_recurring")) {
            is_recurring = object.get_boolean_member ("is_recurring");
        }
    }

    public void reset () {
        date = "";
        timezone = "";
        text = "";
        lang = "";
        is_recurring = false;
    }

    public string to_string () {
        var builder = new Json.Builder ();
        builder.begin_object ();

        builder.set_member_name ("date");
        builder.add_string_value (date);

        builder.set_member_name ("timezone");
        builder.add_string_value (timezone);

        builder.set_member_name ("string");
        builder.add_string_value (text);

        builder.set_member_name ("lang");
        builder.add_string_value (lang);

        builder.set_member_name ("is_recurring");
        builder.add_boolean_value (is_recurring);

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }
}