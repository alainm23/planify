public class Queue : GLib.Object {
    public string uuid { get; set; default = ""; }
    public int64 object_id { get; set; default = 0; }
    public string temp_id { get; set; default = ""; }
    public string query { get; set; default = ""; }
    public string args { get; set; default = ""; }
    public string date_added { get; set; default = new GLib.DateTime.now_local ().to_string (); }
}
