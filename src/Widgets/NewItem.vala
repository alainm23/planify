public class Widgets.NewItem : Gtk.EventBox {
    public int64 project_id { get; set; }
    public bool is_todoist { get; set; }

    private Gtk.Entry name_entry;
    private Gtk.Stack stack;

    public NewItem (int64 project_id, bool is_todoist = false) {
        Object (
            project_id: project_id,
            is_todoist: is_todoist
        );
    }

    construct {
        var HAND_cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), Gdk.CursorType.HAND1);
        var ARROW_cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), Gdk.CursorType.ARROW);
        var window = Gdk.Screen.get_default ().get_root_window ();

        /*
            Item 1
        */

        var cancel_add_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.MENU);
        cancel_add_button.can_focus = false;
        cancel_add_button.get_style_context ().add_class ("cancel-add-button");
        cancel_add_button.get_style_context ().add_class ("flat");
        cancel_add_button.get_style_context ().add_class ("dim-label");
        cancel_add_button.get_style_context ().add_class ("hidden-button");
        cancel_add_button.tooltip_text = _("Cancel");

        var submit_spinner = new Gtk.Spinner ();
        submit_spinner.start ();

        var submit_stack = new Gtk.Stack ();
        submit_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        
        submit_stack.add_named (cancel_add_button, "button");
        submit_stack.add_named (submit_spinner, "spinner");

        var checked_button = new Gtk.CheckButton ();
        checked_button.get_style_context ().add_class ("checked-preview");
        checked_button.valign = Gtk.Align.CENTER;

        name_entry = new Gtk.Entry ();
        name_entry.margin_start = 6;
        name_entry.margin_bottom = 1;
        name_entry.hexpand = true;
        name_entry.placeholder_text = _("Task name");
        name_entry.get_style_context ().add_class ("new-item-entry");
        name_entry.get_style_context ().add_class ("welcome");
        name_entry.get_style_context ().add_class ("flat");
        //name_entry.get_style_context ().add_class ("content-entry");

        var 1_box = new Gtk.Grid ();
        1_box.margin_start = 4;
        1_box.add (submit_stack);
        1_box.add (checked_button);
        1_box.add (name_entry);

        /*
            Item 2
        */

        var add_image = new Gtk.Image ();
        add_image.valign = Gtk.Align.CENTER;
        add_image.gicon = new ThemedIcon ("list-add-symbolic");
        add_image.get_style_context ().add_class ("add-project-image");
        add_image.get_style_context ().add_class ("text-color");
        add_image.pixel_size = 14;

        var add_label = new Gtk.Label (_("Add task"));
        add_label.margin_bottom = 1;
        add_label.get_style_context ().add_class ("pane-item");
        add_label.get_style_context ().add_class ("text-color");
        add_label.get_style_context ().add_class ("add-project-label");
        add_label.use_markup = true;

        var add_grid = new Gtk.Grid ();
        add_grid.margin_start = 34;
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
        stack.add_named (1_box, "2_box");

        add (stack);

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

        name_entry.activate.connect (() => {
            insert_item ();
        });
 
        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                stack.visible_child_name = "1_box";
                name_entry.text = "";
            }

            return false;
        });

        name_entry.changed.connect (() => {
            if (name_entry.text == "") {
                cancel_add_button.tooltip_text = _("Cancel");
                cancel_add_button.get_style_context ().remove_class ("active");
            } else {
                cancel_add_button.tooltip_text = _("Add task");
                cancel_add_button.get_style_context ().add_class ("active");
            }
        }); 

        name_entry.focus_out_event.connect (() => {
            if (name_entry.text == "") {
                stack.visible_child_name = "1_box";
                name_entry.text = "";
            }

            return false;
        });

        cancel_add_button.clicked.connect (() => {
            if (name_entry.text == "") {
                stack.visible_child_name = "1_box";
                name_entry.text = "";   
            } else {
                insert_item ();
            }
        });

        Application.todoist.item_added_started.connect ((id) => {
            if (project_id == id) {
                submit_stack.visible_child_name = "spinner";
                name_entry.sensitive = false;
            }
        });

        Application.todoist.item_added_completed.connect ((id) => {
            if (project_id == id) {
                stack.visible_child_name = "1_box";
                submit_stack.visible_child_name = "button";

                name_entry.text = "";  
                name_entry.sensitive = true;    
            }
        });

        Application.todoist.item_added_error.connect ((id, error_code, error_message) => {
            if (project_id == id) {
                print ("Message: %s\n".printf (error_message));
                print ("Code: %i\n".printf (error_code));

                stack.visible_child_name = "1_box";
                submit_stack.visible_child_name = "button";

                name_entry.text = "";  
                name_entry.sensitive = true; 
            }
        });
    }

    private void insert_item () {
        if (name_entry.text != "") {
            var item = new Objects.Item ();
            item.id = Application.utils.generate_id ();
            item.content = name_entry.text;
            item.project_id = project_id;

            if (is_todoist) {
                if (Application.utils.check_connection ()) {
                    Application.todoist.add_item (item);
                } else {

                }
            } else {
                if (Application.database.insert_item (item)) {
                    stack.visible_child_name = "1_box";
                    name_entry.text = "";
                }
            }
        }
    }
}