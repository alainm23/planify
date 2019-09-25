public class Objects.Item : GLib.Object {
    public string content { get; set; default = ""; }
    public string note { get; set; default = ""; }
    public string due { get; set; default = ""; }
    public string date_added { get; set; default = new GLib.DateTime.now_local ().to_string (); }
    public string date_completed { get; set; default = ""; }
    public string date_updated { get; set; default = new GLib.DateTime.now_local ().to_string (); }

    public int is_deleted { get; set; default = 0; }
    public int checked { get; set; default = 0; }
    public int item_order { get; set; default = 0; }
    public int64 project_id { get; set; default = 0; }
    public int64 header_id { get; set; default = 0; }
    public int64 id { get; set; default = 0; }

    private uint timeout_id = 0;

    public void save () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }

        timeout_id = Timeout.add (1000, () => {
            this.date_updated = new GLib.DateTime.now_local ().to_string ();

            new Thread<void*> ("save_timeout", () => {
                Application.database.update_item (this);
                return null;
            });
            
            Source.remove (timeout_id);
            timeout_id = 0;
            return false;
        });
    }
}