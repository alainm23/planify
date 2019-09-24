public class Objects.Area : GLib.Object {
    public string name { get; set; default = ""; }
    public string date_added { get; set; default = new GLib.DateTime.now_local ().to_string (); }
    public int64 id { get; set; default = 0; }
    public int defaul_area { get; set; default = 0; }
    public int reveal { get; set; default = 1; }
    public int child_order { get; set; default = 0; }

    public bool save () {
        return Application.database.update_area (this);    
    }
}