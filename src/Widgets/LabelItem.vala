public class Widgets.LabelItem : Gtk.EventBox {
    public int64 id { get; construct; }
    public int64 item_id { get; construct; }
    public Objects.Label label { get; construct; }

    public LabelItem (int64 id, int64 item_id, Objects.Label label) {
        Object (
            id: id,
            item_id: item_id,
            label: label
        );
    }

    construct {
        add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);

        var delete_image = new Gtk.Image ();
        delete_image.gicon = new ThemedIcon ("window-close-symbolic");
        delete_image.pixel_size = 13;

        var delete_button = new Gtk.Button ();
        delete_button.can_focus = false;
        delete_button.valign = Gtk.Align.CENTER;
        delete_button.halign = Gtk.Align.CENTER; 
        delete_button.get_style_context ().add_class ("no-padding");
        delete_button.get_style_context ().add_class ("label-item-button");
        delete_button.image = delete_image;
        delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var delete_revealer = new Gtk.Revealer ();
        delete_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        delete_revealer.add (delete_button);

        var name_label = new Gtk.Label (label.name);
        name_label.margin_end = 3;
        name_label.margin_top = 1;
        name_label.valign = Gtk.Align.CENTER;
        name_label.valign = Gtk.Align.CENTER;
        
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        box.valign = Gtk.Align.CENTER;
        box.get_style_context ().add_class ("label-preview-%s".printf (label.id.to_string ()));
        box.add (delete_revealer);
        box.add (name_label);

        add (box);

        Planner.database.label_updated.connect ((l) => {
            Idle.add (() => {
                if (label.id == l.id) {
                    name_label.label = l.name;
                }

                return false;
            });
        });

        enter_notify_event.connect ((event) => {
            delete_revealer.reveal_child = true;
            return true;
        });

        leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            delete_revealer.reveal_child = false;

            return true;
        });

        delete_button.clicked.connect (() => {
            if (Planner.database.delete_item_label (id, item_id, label)) {

            }   
        });

        Planner.database.item_label_deleted.connect ((i, item_id, label) => {
            if (id == i) {
                destroy ();
            }
        });

        Planner.database.label_deleted.connect ((l) => {
            if (label.id == l.id) {
                destroy ();
            }
        });
    }
}