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

    private uint save_timer = 0;

    public void save () {
        cancel_save_timeout ();
        save_timeout ();
    }

    private void cancel_save_timeout () {
        lock (save_timer) {
            if (save_timer != 0) {
                Source.remove (save_timer);
                save_timer = 0;
            }
        }
    }

    private void save_timeout () {
        lock (save_timer) {
            cancel_save_timeout ();

            save_timer = Timeout.add (1000, () => {
                new Thread<void*> ("save_timeout", () => {
                    Application.database.update_project (this);
                    cancel_save_timeout ();

                    return null;
                });
                
                return false;
            });
        }
    }
}