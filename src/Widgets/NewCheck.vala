public class Widgets.NewCheck : Gtk.EventBox {
    public int64 item_id { get; construct; }

    private Gtk.Entry name_entry;
    private Gtk.Stack stack;
    
    public NewCheck (int64 item_id) {
        Object (
            item_id: item_id
        );
    }

    construct {
        var HAND_cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), Gdk.CursorType.HAND1);
        var ARROW_cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), Gdk.CursorType.ARROW);
        var window = Gdk.Screen.get_default ().get_root_window ();

        var checked_button = new Gtk.CheckButton ();
        checked_button.get_style_context ().add_class ("checked_button");
        checked_button.valign = Gtk.Align.CENTER;

        name_entry = new Gtk.Entry ();
        name_entry.hexpand = true;
        name_entry.margin_start = 6;
        name_entry.margin_bottom = 1;
        name_entry.placeholder_text = _("Add a new subtask");
        name_entry.get_style_context ().add_class ("welcome");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("check-entry");

        var box = new Gtk.Grid ();
        //box.margin_start = 65;
        box.add (checked_button);
        box.add (name_entry);

        /*
            Item 2
        */

        var add_image = new Gtk.Image ();
        add_image.valign = Gtk.Align.CENTER;
        add_image.gicon = new ThemedIcon ("list-add-symbolic");
        add_image.get_style_context ().add_class ("add-project-image");
        add_image.get_style_context ().add_class ("text-color");
        add_image.pixel_size = 14;

        var add_label = new Gtk.Label (_("Add subtask"));
        add_label.margin_bottom = 1;
        add_label.get_style_context ().add_class ("pane-item");
        add_label.get_style_context ().add_class ("text-color");
        add_label.get_style_context ().add_class ("add-project-label");
        add_label.use_markup = true;

        var add_grid = new Gtk.Grid ();
        add_grid.column_spacing = 9;
        add_grid.add (add_image);
        add_grid.add (add_label);

        var add_eventbox = new Gtk.EventBox ();
        add_eventbox.valign = Gtk.Align.CENTER;
        add_eventbox.add (add_grid);

        stack = new Gtk.Stack ();
        stack.margin_end = 30;
        stack.hexpand = true;
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        stack.add_named (add_eventbox, "1_box");
        stack.add_named (box, "2_box");

        add (stack);

        name_entry.activate.connect (() => {
            insert_item ();
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                name_entry.text = "";
                stack.visible_child_name = "1_box";
            }

            return false;
        });
        
        name_entry.focus_out_event.connect (() => {
            if (name_entry.text != "") {
                insert_item ();
                stack.visible_child_name = "1_box";
            } else {
                stack.visible_child_name = "1_box";
            }

            return false;
        });

        add_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                stack.visible_child_name = "2_box";
                name_entry.grab_focus ();
            }

            return false;
        });

        add_eventbox.enter_notify_event.connect ((event) => {
            add_image.get_style_context ().add_class ("active");
            add_label.get_style_context ().add_class ("active");
            
            window.cursor = HAND_cursor;
            return true;
        });

        add_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            window.cursor = ARROW_cursor;
            add_image.get_style_context ().remove_class ("active");
            add_label.get_style_context ().remove_class ("active");

            return true;
        });
    }

    private void insert_item () {
        if (name_entry.text != "") {
            var check = new Objects.Check ();
            check.content = name_entry.text;
            check.id = Application.utils.generate_id ();
            check.item_id = item_id;

            if (Application.database.insert_check (check)) {
                name_entry.text = "";
            }
        }
    }
}