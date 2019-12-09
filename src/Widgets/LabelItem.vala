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
    
        var name_label = new Gtk.Label (label.name);
        name_label.valign = Gtk.Align.CENTER;
        name_label.valign = Gtk.Align.CENTER;

        var color_image = new Gtk.Image ();
        color_image.gicon = new ThemedIcon ("mail-unread-symbolic");
        color_image.get_style_context ().add_class ("label-item-%s".printf (label.id.to_string ()));
        color_image.pixel_size = 16;

        var color_button = new Gtk.Button ();
        color_button.can_focus = false;
        color_button.valign = Gtk.Align.CENTER;
        color_button.halign = Gtk.Align.CENTER; 
        color_button.get_style_context ().add_class ("no-padding");
        color_button.get_style_context ().add_class ("label-item-button");
        color_button.image = color_image;
        color_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var delete_image = new Gtk.Image ();
        delete_image.gicon = new ThemedIcon ("window-close-symbolic");
        delete_image.pixel_size = 16;

        var delete_button = new Gtk.Button ();
        delete_button.can_focus = false;
        delete_button.valign = Gtk.Align.CENTER;
        delete_button.halign = Gtk.Align.CENTER; 
        delete_button.get_style_context ().add_class ("no-padding");
        delete_button.get_style_context ().add_class ("label-item-button");
        delete_button.image = delete_image;
        delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        
        stack.add_named (color_button, "color_button");
        stack.add_named (delete_button, "delete_button");

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        box.get_style_context ().add_class ("label-item");
        box.add (stack);
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
            stack.visible_child_name = "delete_button";
            return true;
        });

        leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            stack.visible_child_name = "color_button";

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