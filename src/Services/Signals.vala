public class Services.Signals : GLib.Object {
    public signal void on_signal_show_quick_find ();

    public signal void on_signal_show_events ();

    public signal void go_action_page (int index);
    public signal void go_project_page (int project_id);
    public signal void go_task_page (int task_id, int project_id);

    public Signals () {

    }
}
