public class Objects.Queue : GLib.Object {
    public int key { get; set; default = 0; }
    public int64 id { get; set; default = 0; }
    public string temp_id { get; set; default = ""; }
    public string _type { get; set; default = ""; }
    public string args { get; set; default = ""; }
    public string uuid { get; set; default = ""; }
}