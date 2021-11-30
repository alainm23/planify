public class Widgets.LoadingButton : Gtk.Button {
    public string text { get; construct; }
    bool _is_loading;

    private Gtk.Stack submit_stack;

    [Description (nick = "Show loading", blurb = "Show loading")]
    public bool is_loading {
        get {
            return _is_loading;
        }

        set {
            if (value) {
                submit_stack.visible_child_name = "spinner";
            } else {
                submit_stack.visible_child_name = "label";
            }

            _is_loading = value;
        }
    }

    public LoadingButton (string text) {
        Object (text: text);
    }

    construct {
        var submit_spinner = new Gtk.Spinner ();
        submit_spinner.get_style_context ().add_class ("submit-spinner");
        submit_spinner.start ();

        submit_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        submit_stack.add_named (new Gtk.Label (text), "label");
        submit_stack.add_named (submit_spinner, "spinner");

        add (submit_stack);
    }
}