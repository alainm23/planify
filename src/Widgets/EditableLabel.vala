public class Widgets.EditableLabel : Gtk.EventBox {
    public string title_style { get; construct; }
    public signal void changed ();

    private Gtk.Label title;
    private Gtk.Entry entry;
    private Gtk.Stack stack;
    private Gtk.Grid grid;

    public string text { get; set; }
    public bool entry_menu_opened { get; set; default = false; }

    public bool editing {
        get {
            return stack.visible_child == entry;
        }
        set {
            if (value) {
                entry.text = text;
                stack.set_visible_child (entry);

                entry.grab_focus_without_selecting ();
                if (entry.cursor_position < entry.text_length) {
                    entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) entry.text_length, false);
                }
            } else {
                if (entry.text.strip () != "" && text != entry.text) {
                    text = entry.text;
                    changed ();
                }

                stack.set_visible_child (grid);
            }
        }
    }

    public bool editable {
        set {
            entry.editable = value;
        }
    }

    public EditableLabel (string title_style) {
        Object (title_style: title_style);
    }

    construct {
        unowned Gtk.StyleContext style_context = get_style_context ();
        style_context.add_class ("editable-label");

        valign = Gtk.Align.CENTER;
        events |= Gdk.EventMask.ENTER_NOTIFY_MASK;
        events |= Gdk.EventMask.LEAVE_NOTIFY_MASK;
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;

        title = new Gtk.Label ("") {
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0
        };

        grid = new Gtk.Grid () {
            valign = Gtk.Align.CENTER,
            column_spacing = 12
        };
        grid.add (title);

        entry = new Gtk.Entry () {
            hexpand = true
        };

        stack = new Gtk.Stack () {
            homogeneous = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };
        stack.add (grid);
        stack.add (entry);

        unowned Gtk.StyleContext stack_context = stack.get_style_context ();
        stack_context.add_class (title_style);

        var submit_button = new Gtk.Button () {
            width_request = 64
        };
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var submit_spinner = new Gtk.Spinner ();
        submit_spinner.start ();

        var submit_stack = new Gtk.Stack () {
            expand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        submit_stack.add_named (new Gtk.Label (_("Save")), "label");
        submit_stack.add_named (submit_spinner, "spinner");

        submit_button.add (submit_stack);

        var cancel_button = new Gtk.Button.with_label (_("Cancel")) {
            width_request = 64
        };

        var buttons_grid = new Gtk.Grid () {
            halign = Gtk.Align.START,
            column_homogeneous = true,
            column_spacing = 6,
            margin_top = 6
        };
        buttons_grid.add (cancel_button);
        buttons_grid.add (submit_button);

        unowned Gtk.StyleContext buttons_grid_context = buttons_grid.get_style_context ();
        buttons_grid_context.add_class ("editable-buttons");
        buttons_grid_context.add_class ("small-label");

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };
        main_grid.add (stack);

        add (main_grid);

        bind_property ("text", title, "label");

        button_press_event.connect ((event) => {
            editing = true;
            return Gdk.EVENT_PROPAGATE;
        });

        entry.activate.connect (() => {
            if (stack.visible_child == entry) {
                editing = false;
            }
        });

        grab_focus.connect (() => {
            editing = true;
        });

        entry.focus_out_event.connect ((event) => {
            if (stack.visible_child == entry && !entry_menu_opened) {
                editing = false;
            }
            return Gdk.EVENT_PROPAGATE;
        });

        entry.populate_popup.connect ((menu) => {
            entry_menu_opened = true;
            menu.hide.connect (() => {
                entry_menu_opened = false;
            });
        });

        cancel_button.clicked.connect (() => {
            entry.text = text;
            if (stack.visible_child == entry) {
                editing = false;
            }
        });

        submit_button.clicked.connect (() => {
            if (stack.visible_child == entry) {
                editing = false;
            }
        });
    }
}