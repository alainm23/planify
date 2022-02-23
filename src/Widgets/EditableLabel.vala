public class Widgets.EditableLabel : Gtk.EventBox {
    public string title_style { get; construct; }
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
                    entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) entry.text_length, false);
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

    public EditableLabel (string title_style, string placeholder_text = "", bool auto_focus = true) {
        Object (
            title_style: title_style,
            placeholder_text: placeholder_text,
            auto_focus: auto_focus
        );
    }

    construct {
        unowned Gtk.StyleContext style_context = get_style_context ();
        style_context.add_class ("editable-label");

        valign = Gtk.Align.CENTER;
        events |= Gdk.EventMask.ENTER_NOTIFY_MASK;
        events |= Gdk.EventMask.LEAVE_NOTIFY_MASK;
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;

        title = new Gtk.Label (null) {
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0
        };

        grid = new Gtk.Grid () {
            valign = Gtk.Align.CENTER,
            column_spacing = 12
        };
        grid.add (title);

        entry = new Widgets.Entry () {
            placeholder_text = placeholder_text
        };

        stack = new Gtk.Stack () {
            homogeneous = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };
        stack.add (grid);
        stack.add (entry);

        unowned Gtk.StyleContext stack_context = stack.get_style_context ();
        stack_context.add_class (title_style);


        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };
        main_grid.add (stack);

        add (main_grid);

        bind_property ("text", title, "label");

        if (auto_focus) {
            button_press_event.connect ((event) => {
                editing (true);
                return Gdk.EVENT_PROPAGATE;
            });

            grab_focus.connect (() => {
                editing (true);
            });
        }

        entry.activate.connect (() => {
            if (stack.visible_child == entry) {
                editing (false);
            }
        });

        entry.focus_out_event.connect ((event) => {
            if (stack.visible_child == entry && !entry_menu_opened) {
                editing (false);
            }
            return Gdk.EVENT_PROPAGATE;
        });

        entry.populate_popup.connect ((menu) => {
            entry_menu_opened = true;
            menu.hide.connect (() => {
                entry_menu_opened = false;
            });
        });

        entry.focus_in_event.connect (handle_focus_in);
        entry.focus_out_event.connect (update_on_leave);
    }

    private bool handle_focus_in (Gdk.EventFocus event) {
        Planner.event_bus.disconnect_typing_accel ();
        return false;
    }

    public bool update_on_leave () {
        Planner.event_bus.connect_typing_accel ();
        return false;
    }
}
