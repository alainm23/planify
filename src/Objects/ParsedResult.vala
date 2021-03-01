public class Objects.ParsedResult : GLib.Object {
    public GLib.DateTime date { get; set; }
    public string text { get; set; default = ""; }
    public string lang { get; set; default = ""; }
    public bool is_recurring { get; set; default = false; }

    public string get_default_date_format () {
        return Planner.utils.get_default_date_format_from_date (date);
    }
}
