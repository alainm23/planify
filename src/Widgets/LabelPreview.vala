public class Widgets.LabelPreview : Gtk.Grid {
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
        get_style_context ().add_class ("label-preview-%s".printf (label.id.to_string ()));
        height_request = 3;
        width_request = 24;

        Application.database.item_label_deleted.connect ((i) => {
            if (id == i) {
                destroy ();
            }
        });

        Application.database.label_deleted.connect ((l) => {
            if (label.id == l.id) {
                destroy ();
            }
        });
    }
}