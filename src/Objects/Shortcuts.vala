public class Objects.Shortcuts : GLib.Object {
    public string name { get; set; }
    public string[] accels { get; set; }

    public Shortcuts (string name, string[] accels) {
        this.name = name;
        this.accels = accels;
    }
}
