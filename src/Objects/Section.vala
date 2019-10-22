public class Objects.Section : GLib.Object {
    public int64 id { get; set; default = Application.utils.generate_id (); }
    public int64 project_id { get; set; default = 0; }
    public int64 sync_id { get; set; default = 1; }
    public string name { get; set; default = ""; }
    public int item_order { get; set; default = 0; }
    public int collapsed { get; set; default = 1; }
    public int is_todoist { get; set; default = 0; }
    public int is_deleted { get; set; default = 0; }
    public int is_archived { get; set; default = 0; }
    public string date_archived { get; set; default = ""; }
    public string date_added { get; set; default = new GLib.DateTime.now_local ().to_string (); }
    
    private uint timeout_id = 0;

    public void save () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }

        timeout_id = Timeout.add (2500, () => {
            new Thread<void*> ("save_timeout", () => {
                Application.database.update_section (this);
                return null;
            });
            
            Source.remove (timeout_id);
            timeout_id = 0;
            return false;
        });
    }
}