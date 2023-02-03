public class Widgets.EditableLabel : Gtk.Grid {
    public string placeholder_text { get; construct; }
    public bool auto_focus { get; construct; }

    public signal void focus_changed (bool active);
    public signal void changed ();

    private Gtk.Label title;
    private Widgets.Entry entry;
    private Gtk.Stack stack;
    private Gtk.Grid grid;

    public string text { get; set; }
    public bool entry_menu_opened { get; set; default = false; }

    public bool is_editing {
        get {
            return stack.visible_child == entry;
        }
    }

    public void editing (bool value, bool grab_focus = false) {
        focus_changed (value);
            
        if (value) {
            entry.text = text;
            stack.set_visible_child (entry);

            if (grab_focus) {
                entry.grab_focus ();
            } else {
                entry.grab_focus_without_selecting ();
                if (entry.cursor_position < entry.text_length) {
                    entry.set_position ((int32) entry.text_length);
                }
            }
        } else {
            if (entry.text.strip () != "" && text != entry.text) {
                text = entry.text;
                changed ();
            }

            stack.set_visible_child (grid);
        }
    }

    public bool editable {
        set {
            entry.editable = value;
        }
    }

    public EditableLabel (string placeholder_text = "", bool auto_focus = true) {
        Object (
            placeholder_text: placeholder_text,
            auto_focus: auto_focus
        );
    }

    construct {
        add_css_class ("editable-label");

        title = new Gtk.Label (null) {
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0
        };

        grid = new Gtk.Grid () {
            valign = Gtk.Align.CENTER,
            column_spacing = 12
        };

        grid.attach (title, 0, 0);

        entry = new Widgets.Entry () {
            placeholder_text = placeholder_text
        };

        stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE,
            hexpand = true
        };

        stack.add_child (grid);
        stack.add_child (entry);

        attach (stack, 0, 0);

        bind_property ("text", title, "label");

        if (auto_focus) {
            var gesture_click = new Gtk.GestureClick ();
            gesture_click.set_button (1);
            add_controller (gesture_click);

            gesture_click.pressed.connect (() => {
                editing (true);
            });
        }

        entry.activate.connect (() => {
            if (stack.visible_child == entry) {
                editing (false);
            }
        });

        var gesture = new Gtk.EventControllerFocus ();
        entry.add_controller (gesture);

        gesture.enter.connect (handle_focus_in);
        gesture.leave.connect (update_on_leave);
        
        gesture.leave.connect (() => {
            if (stack.visible_child == entry && !entry_menu_opened) {
                editing (false);
            }
        });
    }

    public void add_style (string style) {
        stack.add_css_class (style);
    }

    private void handle_focus_in () {
        Planner.event_bus.disconnect_typing_accel ();
    }

    public void update_on_leave () {
        Planner.event_bus.connect_typing_accel ();
    }
}