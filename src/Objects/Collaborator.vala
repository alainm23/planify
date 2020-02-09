public class Objects.Collaborator : GLib.Object {
    public int64 id { get; set; default = 0; }
    public string email { get; set; default = ""; }
    public string full_name { get; set; default = ""; }
    public string timezone { get; set; default = ""; }
    public string image_id { get; set; default = ""; }

    //private uint timeout_id = 0;

    public void save () {
        /*
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }

        timeout_id = Timeout.add (2500, () => {
            new Thread<void*> ("save_timeout", () => {
                Planner.database.update_area (this);
                return null;
            });

            Source.remove (timeout_id);
            timeout_id = 0;
            return false;
        });
        */
    }
}
