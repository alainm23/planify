public class Objects.Check : GLib.Object {
    public string content { get; set; default = ""; }
    public string date_added { get; set; default = new GLib.DateTime.now_local ().to_string (); }
    public string date_completed { get; set; default = ""; }
    public string date_updated { get; set; default = new GLib.DateTime.now_local ().to_string (); }

    public int checked { get; set; default = 0; }
    public int item_order { get; set; default = 0; }
    public int64 item_id { get; set; default = 0; }
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
                this.date_updated = new GLib.DateTime.now_local ().to_string ();

                new Thread<void*> ("save_timeout", () => {
                    Application.database.update_check (this);
                    cancel_save_timeout ();

                    return null;
                });
                
                return false;
            });
        }
    }
}