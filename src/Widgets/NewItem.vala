public class Widgets.NewItem : Gtk.ListBoxRow {
    public int64 project_id { get; set; }
    public int64 section_id { get; set; }
    public int is_todoist { get; set; }
    public int index { get; set; default = 0; }
    public bool has_index { get; set; default = false; }
    public string due { get; set; default = ""; }
    
    public int64 temp_id_mapping {get; set; default = 0; }
    public bool shift_pressed { get; private set; default = false; }
    public bool shift_activated { get; private set; default = false; }

    private uint timeout_id = 0;
    
    private Gtk.Entry content_entry;

    public signal void new_item_hide ();

    public NewItem (int64 project_id, int64 section_id, int is_todoist) {
        Object (
            project_id: project_id,
            section_id: section_id,
            is_todoist: is_todoist
        );
    }

    construct {
        can_focus = false;
        activatable = false;
        selectable = false;
        get_style_context ().add_class ("item-row");
        margin_end = 35;
        margin_top = 3;
        margin_bottom = 3;

        var loading_spinner = new Gtk.Spinner ();
        loading_spinner.start ();

        var loading_revealer = new Gtk.Revealer ();
        loading_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        loading_revealer.add (loading_spinner);

        var checked_button = new Gtk.CheckButton ();
        checked_button.margin_start = 6;
        checked_button.get_style_context ().add_class ("checklist-button");
        checked_button.valign = Gtk.Align.CENTER;

        content_entry = new Gtk.Entry ();
        content_entry.hexpand = true;
        content_entry.margin_start = 3;
        content_entry.margin_bottom = 1;
        content_entry.placeholder_text = _("Add a new subtask");
        content_entry.get_style_context ().add_class ("welcome");
        content_entry.get_style_context ().add_class ("flat");
        content_entry.get_style_context ().add_class ("new-entry");
        content_entry.get_style_context ().add_class ("no-padding-right");
        content_entry.get_style_context ().add_class ("label");
 
        var content_grid = new Gtk.Grid ();
        content_grid.get_style_context ().add_class ("check-eventbox");
        content_grid.add (checked_button);
        content_grid.add (content_entry);
        
        var grid = new Gtk.Grid ();
        grid.margin_start = 14;
        grid.column_spacing = 6;
        grid.add (loading_revealer);
        grid.add (content_grid);

        var submit_button = new Gtk.Button.with_label (_("Add"));
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        submit_button.get_style_context ().add_class ("new-item-action-button");

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("new-item-action-button");

        var action_grid = new Gtk.Grid ();
        action_grid.halign = Gtk.Align.START;
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 6;
        action_grid.margin_start = 36;
        action_grid.margin_bottom = 6;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.row_spacing = 9;
        main_grid.add (grid);
        main_grid.add (action_grid);

        add (main_grid);

        timeout_id = Timeout.add (150, () => {
            content_entry.grab_focus ();

            Source.remove (timeout_id);

            return false;
        });

        content_entry.key_press_event.connect ((event) => {
            if (event.keyval == Gdk.Key.Shift_L) {
                shift_pressed = true;
            } else if (event.keyval == Gdk.Key.Return) {
                insert_item ();
            } else if (event.keyval == 65307) {
                if (due == "") {
                    destroy ();
                } else {
                    loading_revealer.reveal_child = false;
                    sensitive = true;

                    content_entry.text = "";
                    new_item_hide ();
                }

                due = "";
            }
            
            return false;
        });

        content_entry.key_release_event.connect ((event) => {
            if (event.keyval == Gdk.Key.Shift_L) {
                shift_pressed = false;
            }

            return true;
        });

        submit_button.clicked.connect (insert_item);

        content_entry.changed.connect (() => {  
            if (content_entry.text != "") {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }
        });

        cancel_button.clicked.connect (() => {
            if (due == "") {
                destroy ();
            } else {
                new_item_hide ();
            }
        });

        Application.todoist.item_added_started.connect ((id) => {
            if (temp_id_mapping == id) {
                loading_revealer.reveal_child = true;
                sensitive = false;
            }
        });

        Application.todoist.item_added_completed.connect ((id) => {
            if (temp_id_mapping == id) {
                if (shift_activated) {
                    bool last = true;
                    if (has_index) {
                        last = false;
                    }

                    Application.utils.magic_button_activated (
                        project_id,
                        section_id,
                        is_todoist,
                        last,
                        index + 1
                    );
                }

                if (due == "") {
                    destroy ();
                } else {
                    new_item_hide ();
                }
                
                due = "";
            }
        });

        Application.todoist.item_added_error.connect ((id) => {
            if (temp_id_mapping == id) {

            }
        });
    }
    
    public void entry_grab_focus () {
        content_entry.grab_focus ();
    }

    private void insert_item () {
        if (content_entry.text != "") {
            var item = new Objects.Item ();
            item.content = content_entry.text;
            item.project_id = project_id;
            item.section_id = section_id;
            item.is_todoist = is_todoist;
            item.due = due;

            temp_id_mapping = Application.utils.generate_id ();
            shift_activated = shift_pressed;

            print ("Se creo la tarea con %s\n".printf (shift_activated.to_string ()));

            if (is_todoist == 1) {
                Application.todoist.add_item (item, index, has_index, temp_id_mapping);
            } else {
                item.id = Application.utils.generate_id ();

                if (Application.database.insert_item (item, index, has_index)) {
                    content_entry.text = "";

                    if (shift_activated) {
                        bool last = true;
                        if (has_index) {
                            last = false;
                        }

                        Application.utils.magic_button_activated (
                            project_id,
                            section_id,
                            is_todoist,
                            last,
                            index + 1
                        );
                    }

                    if (due == "") {
                        destroy ();
                    } else {
                        new_item_hide ();
                    }
                    
                    due = "";
                } 
            }
        }
    }
}