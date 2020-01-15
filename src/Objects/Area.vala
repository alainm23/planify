public class Objects.Area : GLib.Object {
    public int64 id { get; set; default = Planner.utils.generate_id (); }
    public string name { get; set; default = ""; }
    public string date_added { get; set; default = new GLib.DateTime.now_local ().to_string (); }
    public int collapsed { get; set; default = 1; }
    public int item_order { get; set; default = 0; }

    private uint timeout_id = 0;

    public void save () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }

        timeout_id = Timeout.add (500, () => {
            new Thread<void*> ("save_timeout", () => {
                Planner.database.update_area (this);
                return null;
            });
            
            Source.remove (timeout_id);
            timeout_id = 0;
            return false;
        });
    }
}