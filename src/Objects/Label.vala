public class Objects.Label : GLib.Object {
    public int64 id { get; set; default = Planner.utils.generate_id (); }
    public int64 item_label_id { get; set; default = 0; }
    
    public string _name = "";
    public string name {
        get { return _name; }
        set { _name = value.replace ("&", " "); }
    }

    public int color { get; set; default = GLib.Random.int_range (39, 50); }
    public int item_order { get; set; default = 0; }
    public int is_deleted { get; set; default = 0; }
    public int is_favorite { get; set; default = 0; }
    public int is_todoist { get; set; default = 0; }
    
    private uint timeout_id = 0;
    
    public void save () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }

        timeout_id = Timeout.add (250, () => {
            new Thread<void*> ("save_timeout", () => {
                Planner.database.update_label (this);
                return null;
            });
            
            Source.remove (timeout_id);
            timeout_id = 0;
            return false;
        });
    }
}