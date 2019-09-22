public class Objects.Project : GLib.Object {
    public string name { get; set; default = ""; }
    public string note { get; set; default = ""; }
    public string due { get; set; default = ""; }

    public int color { get; set; default = 0; }
    public int is_todoist { get; set; default = 0; }
    public int inbox_project { get; set; default = 0; }
    public int team_inbox { get; set; default = 0; }
    public int child_order { get; set; default = 0; }
    public int is_deleted { get; set; default = 0; }
    public int is_archived { get; set; default = 0; }
    public int is_favorite { get; set; default = 0; }
    public int is_sync { get; set; default = 0; }
    public int64 id { get; set; default = 0; }

    private uint timeout_id = 0;

    public void save () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }

        timeout_id = Timeout.add (1000, () => {
            new Thread<void*> ("save_timeout", () => {
                Application.database.update_project (this);
                return null;
            });
            
            return false;
        });
    }
}