public class Widgets.NewCheck : Gtk.EventBox {
    public int64 item_id { get; construct; }
    public int64 project_id { get; construct; }
    public int is_todoist { get; construct; }
    public int64 temp_id_mapping {get; set; default = 0; }

    private Gtk.Entry name_entry;
    private Gtk.Revealer revealer;
    
    public bool reveal_child {
        set {
            revealer.reveal_child = value;

            if (value) {
                name_entry.grab_focus ();
            }
        }
        get {
            return revealer.reveal_child;
        }
    }

    public NewCheck (int64 item_id, int64 project_id, int is_todoist=0) {
        Object (
            item_id: item_id,
            project_id: project_id,
            is_todoist: is_todoist
        );
    }

    construct {
        margin_start = 31;

        var loading_spinner = new Gtk.Spinner ();
        loading_spinner.start ();

        var loading_revealer = new Gtk.Revealer ();
        loading_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        loading_revealer.add (loading_spinner);

        var checked_button = new Gtk.CheckButton ();
        checked_button.margin_start = 6;
        checked_button.get_style_context ().add_class ("checklist-button");
        checked_button.get_style_context ().add_class ("checklist-check");
        checked_button.valign = Gtk.Align.CENTER;

        name_entry = new Gtk.Entry ();
        name_entry.hexpand = true;
        name_entry.margin_start = 3;
        name_entry.margin_bottom = 1;
        name_entry.placeholder_text = _("Add a new subtask");
        //name_entry.get_style_context ().add_class ("welcome");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("check-entry");

        var box = new Gtk.Grid ();
        box.get_style_context ().add_class ("check-eventbox");
        box.add (checked_button);
        box.add (name_entry);

        var main_box = new Gtk.Grid ();
        main_box.column_spacing = 12;
        main_box.margin_bottom = 6;
        main_box.add (loading_revealer);
        main_box.add (box);

        revealer = new Gtk.Revealer ();
        revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        revealer.add (main_box);

        add (revealer);

        name_entry.activate.connect (() => {
            insert_item ();
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                name_entry.text = "";
                reveal_child = false;
            }

            return false;
        });

        name_entry.focus_out_event.connect (() => {
            if (name_entry.text != "") {
                //insert_item ();
                //reveal_child = false;
                
            } else {
                name_entry.text = "";
                reveal_child = false;
            }

            return false;
        });

        Planner.todoist.item_added_started.connect ((id) => {
            if (temp_id_mapping == id) {
                loading_revealer.reveal_child = true;
                sensitive = false;
            }
        });

        Planner.todoist.item_added_completed.connect ((id) => {
            if (temp_id_mapping == id) {
                loading_revealer.reveal_child = false;
                sensitive = true;

                name_entry.text = "";
                name_entry.grab_focus ();
            }
        });

        Planner.todoist.item_added_error.connect ((id) => {
            if (temp_id_mapping == id) {

            }
        });
    }

    private void insert_item () {
        if (name_entry.text != "") {
            var item = new Objects.Item ();
            item.content = name_entry.text;
            item.parent_id = item_id;
            item.project_id = project_id;
            item.is_todoist = is_todoist;

            temp_id_mapping = Planner.utils.generate_id ();

            if (is_todoist == 0) {
                item.id = Planner.utils.generate_id ();

                if (Planner.database.insert_item (item)) {
                    name_entry.text = "";
                }
            } else {
                Planner.todoist.add_item (item, 0, false, temp_id_mapping);
            }
        }
    }
}