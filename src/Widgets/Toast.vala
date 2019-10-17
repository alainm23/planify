public class Widgets.Toast : Gtk.Revealer {
    private Gtk.Label notification_label;

    private string _title;
    private uint timeout_id;
    
    public string title {
        get {
            return _title;
        }
        construct set {
            if (notification_label != null) {
                notification_label.label = value;
            }

            _title = value;
        }
    }

    construct {
        margin = 3;
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.END;
        transition_type = Gtk.RevealerTransitionType.SLIDE_UP;

        var close_button = new Gtk.Button.from_icon_name ("close-symbolic", Gtk.IconSize.MENU);
        close_button.get_style_context ().add_class ("close-button");

        notification_label = new Gtk.Label (null);

        var default_action_button = new Gtk.Button ();
        default_action_button.valign = Gtk.Align.CENTER;
        default_action_button.label = _("Undo");

        var notification_box = new Gtk.Grid ();
        notification_box.column_spacing = 12;
        notification_box.add (close_button);
        notification_box.add (notification_label);
        notification_box.add (default_action_button);

        var notification_frame = new Gtk.Frame (null);
        notification_frame.get_style_context ().add_class ("app-notification");
        notification_frame.add (notification_box);

        add (notification_frame);

        default_action_button.clicked.connect (() => {
            if (timeout_id != 0) {
                Source.remove (timeout_id);
                timeout_id = 0;
            }

            reveal_child = false;
            
            Application.database.clear_item_to_delete ();
        });

        close_button.clicked.connect (() => {
            reveal_child = false;
        });
    }

    public void send_notification () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }
         
        reveal_child = true;

        uint duration = 4500;

        timeout_id = GLib.Timeout.add (duration, () => {
            reveal_child = false;
            timeout_id = 0;
            title = "";

            print ("Es tiempo de eliminar todas las tareas...\n");
            Application.database.remove_item_to_delete ();

            return false;
        });
    }
}