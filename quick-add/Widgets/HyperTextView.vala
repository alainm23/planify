public class Widgets.HyperTextView : Granite.HyperTextView {
    public string placeholder_text { get; construct; }

    private uint changed_timeout_id { get; set; default = 0; }

    public signal void updated ();

    public bool is_valid {
        get {
            return buffer_get_text () != "";
        }
    }

    public HyperTextView (string placeholder_text) {
        Object (
            placeholder_text: placeholder_text
        );
    }
 
    construct {
        buffer.changed.connect (changed_timeout);

        var gesture = new Gtk.EventControllerFocus ();
        add_controller (gesture);

        gesture.enter.connect (() => {
            if (buffer_get_text () == placeholder_text) {
                buffer.text = "";
                opacity = 1;
            }
        });

        gesture.leave.connect (() => {
            if (buffer_get_text () == "") {
                buffer.text = placeholder_text;
                opacity = 0.7;
            }
        });

        set_text ("");
    }

    private string buffer_get_text () {
        Gtk.TextIter start;
        Gtk.TextIter end;

        buffer.get_start_iter (out start);
        buffer.get_end_iter (out end);

        return buffer.get_text (start, end, true);
    }

    public void set_text (string text) {
        buffer.text = text;
        if (buffer_get_text () == "") {
            buffer.text = placeholder_text;
            opacity = 0.7;
        } else {
            opacity = 1;
        }
    }

    public string get_text () {
        return buffer_get_text () == placeholder_text ? "" : buffer_get_text ();
    }

    private void changed_timeout () {
        if (changed_timeout_id != 0) {
            Source.remove (changed_timeout_id);
        }

        changed_timeout_id = Timeout.add (Constants.UPDATE_TIMEOUT, () => {
            changed_timeout_id = 0;
            updated ();
            return GLib.Source.REMOVE;
        });
    }
}