public class Widgets.NewCheck : Gtk.EventBox {
    public int64 item_id { get; construct; }

    private Gtk.Entry name_entry;
    
    public NewCheck (int64 item_id) {
        Object (
            item_id: item_id
        );
    }

    construct {
        var cancel_add_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.MENU);
        cancel_add_button.can_focus = false;
        cancel_add_button.get_style_context ().add_class ("cancel-add-button");
        cancel_add_button.get_style_context ().add_class ("flat");
        cancel_add_button.get_style_context ().add_class ("dim-label");
        cancel_add_button.tooltip_text = _("Cancel");

        var checked_button = new Gtk.CheckButton ();
        checked_button.get_style_context ().add_class ("checked_button");
        checked_button.valign = Gtk.Align.CENTER;

        name_entry = new Gtk.Entry ();
        name_entry.margin_start = 6;
        name_entry.margin_bottom = 1;
        name_entry.hexpand = true;
        name_entry.placeholder_text = _("Add a new subtask");
        name_entry.get_style_context ().add_class ("welcome");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("content-entry");

        var box = new Gtk.Grid ();
        box.margin_start = 65;
        box.add (checked_button);
        box.add (name_entry);

        add (box);

        name_entry.activate.connect (() => {
            insert_item ();
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                name_entry.text = "";
            }

            return false;
        });


        name_entry.focus_out_event.connect (() => {
            if (name_entry.text != "") {
                insert_item ();
            }

            return false;
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