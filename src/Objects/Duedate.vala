public class Objects.Duedate : GLib.Object {
    public GLib.DateTime date { get; set; default =  null; }
    public string text { get; set; default = ""; }
    public string lang { get; set; default = ""; }
    public bool is_recurring { get; set; default = false; }

    public string get_default_date_format () {
        return Planner.utils.get_default_date_format_from_date (date);
    }

    public void set_time (DateTime time) {
        date = new GLib.DateTime.local (
            date.get_year (),
            date.get_month (),
            date.get_day_of_month (),
            time.get_hour (),
            time.get_minute (),
            time.get_second ()
        );
    }

    public void update_date (DateTime new_date) {
        date = new GLib.DateTime.local (
            new_date.get_year (),
            new_date.get_month (),
            new_date.get_day_of_month (),
            date.get_hour (),
            date.get_minute (),
            date.get_second ()
        );
    }

    public void no_time () {
        date = new GLib.DateTime.local (
            date.get_year (),
            date.get_month (),
            date.get_day_of_month (),
            0,
            0,
            0
        );
    }
    
    public string get_due_date () {
        return date.to_string ();
    }

    public bool is_valid () {
        if (date == null) {
            return false;
        }

        return true;
    }
}
