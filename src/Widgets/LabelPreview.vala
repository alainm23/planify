public class Widgets.LabelPreview : Gtk.EventBox {
    public int64 id { get; construct; }
    public int64 item_id { get; construct; }
    public Objects.Label label { get; construct; }

    public LabelPreview (int64 id, int64 item_id, Objects.Label label) {
        Object (
            id: id,
            item_id: item_id,
            label: label
        );
    }

    construct {
        valign = Gtk.Align.CENTER;

        var color_image = new Gtk.Image ();
        color_image.valign = Gtk.Align.CENTER;
        color_image.gicon = new ThemedIcon ("mail-unread-symbolic");
        color_image.pixel_size = 13;

        var name_label = new Gtk.Label (label.name);
        name_label.valign = Gtk.Align.CENTER;
        name_label.valign = Gtk.Align.CENTER;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        box.get_style_context ().add_class ("label-preview-%s".printf (label.id.to_string ()));
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

        Planner.database.item_label_deleted.connect ((i) => {
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