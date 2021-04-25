public class Objects.Duedate : GLib.Object {
    public GLib.DateTime datetime { get; set; default =  null; }
    public string text { get; set; default = ""; }
    public string lang { get; set; default = ""; }
    public bool is_recurring { get; set; default = false; }

    public string get_default_date_format () {
        return Planner.utils.get_default_date_format_from_date (datetime);
    }

    public string get_relative_date_format () {
        string returned = Planner.utils.get_relative_date_from_date (datetime);

        if (has_time ()) {
            returned += " " + datetime.format (Planner.utils.get_default_time_format ());
        }

        return returned;
    }

    public string get_icon () {
        if (Planner.utils.is_today (datetime)) {
            return "help-about-symbolic";
        }

        return "office-calendar-symbolic";
    }

    public void set_time (DateTime time) {
        datetime = new GLib.DateTime.local (
            datetime.get_year (),
            datetime.get_month (),
            datetime.get_day_of_month (),
            time.get_hour (),
            time.get_minute (),
            time.get_second ()
        );
    }

    public void update_date (DateTime new_date) {
        datetime = new GLib.DateTime.local (
            new_date.get_year (),
            new_date.get_month (),
            new_date.get_day_of_month (),
            datetime.get_hour (),
            datetime.get_minute (),
            datetime.get_second ()
        );
    }

    public void no_time () {
        datetime = new GLib.DateTime.local (
            datetime.get_year (),
            datetime.get_month (),
            datetime.get_day_of_month (),
            0,
            0,
            0
        );
    }
    
    public string get_due_date () {
        return datetime.to_string ();
    }

    public bool is_valid () {
        if (datetime == null) {
            return false;
        }

        return true;
    }

    public bool has_time () {
        return Planner.utils.has_time (datetime);
    }
}
