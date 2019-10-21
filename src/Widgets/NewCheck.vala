public class Widgets.NewCheck : Gtk.EventBox {
    public int64 item_id { get; construct; }
    public int64 project_id { get; construct; }

    private Gtk.Entry name_entry;
    private Gtk.Stack stack;
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

    public NewCheck (int64 item_id, int64 project_id) {
        Object (
            item_id: item_id,
            project_id: project_id
        );
    }

    construct {
        margin_start = 59;

        var checked_button = new Gtk.CheckButton ();
        checked_button.margin_start = 6;
        checked_button.get_style_context ().add_class ("checklist-button");
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
        box.margin_bottom = 6;
        box.get_style_context ().add_class ("check-eventbox");
        box.add (checked_button);
        box.add (name_entry);

        revealer = new Gtk.Revealer ();
        revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        revealer.add (box);

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
                insert_item ();
                reveal_child = false;
                
            } else {
                name_entry.text = "";
                reveal_child = false;
            }

            return false;
        });
    }

    private void insert_item () {
        if (name_entry.text != "") {
            var item = new Objects.Item ();
            item.id = Application.utils.generate_id ();
            item.content = name_entry.text;
            item.parent_id = item_id;
            item.project_id = project_id;

            if (Application.database.insert_item (item)) {
                name_entry.text = "";
            }
        }
    }
}