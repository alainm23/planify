public class Objects.Item : GLib.Object {
    public int64 id { get; set; default = 0; }
    public int64 project_id { get; set; default = 0; }
    public int64 section_id { get; set; default = 0; }
    public int64 user_id { get; set; default = 0; }
    public int64 assigned_by_uid { get; set; default = 0; }
    public int64 responsible_uid { get; set; default = 0; }
    public int64 sync_id { get; set; default = 0; }
    public int64 parent_id { get; set; default = 0; } 
    public int priority { get; set; default = 0; }
    public int item_order { get; set; default = 0; }
    public int checked { get; set; default = 0; }
    public int is_deleted { get; set; default = 0; }
    public int is_todoist { get; set; default = 0; }
    public string content { get; set; default = ""; }
    public string note { get; set; default = ""; }
    public string due { get; set; default = ""; }
    public string date_added { get; set; default = new GLib.DateTime.now_local ().to_string (); }
    public string date_completed { get; set; default = ""; }
    public string date_updated { get; set; default = new GLib.DateTime.now_local ().to_string (); }

    private uint timeout_id = 0;

    public void save () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }

        timeout_id = Timeout.add (2500, () => {
            this.date_updated = new GLib.DateTime.now_local ().to_string ();

            new Thread<void*> ("save_timeout", () => {
                if (this.is_todoist == 0) {
                    Application.database.update_item (this);
                } else {
                    Application.todoist.update_item (this);
                }

                return null;
            });
            
            Source.remove (timeout_id);
            timeout_id = 0;
            return false;
        });
    }
}