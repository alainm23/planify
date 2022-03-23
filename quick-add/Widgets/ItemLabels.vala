public class Widgets.ItemLabels : Gtk.EventBox {
    public Objects.Item item { get; construct; }

    private Gtk.FlowBox flowbox;
    private Gtk.Revealer main_revealer;
    
    public signal void labels_changed (Gee.HashMap <string, Objects.Label> labels);
    public signal void dialog_open (bool value);

    private bool has_items {
        get {
            return flowbox.get_children ().length () > 0;
        }
    }

    public ItemLabels (Objects.Item item) {
        Object (
            item: item
        );
    }

    construct {
        flowbox = new Gtk.FlowBox () {
            column_spacing = 6,
            row_spacing = 6,
            homogeneous = false,
            hexpand = true,
            halign = Gtk.Align.START,
            min_children_per_line = 3,
            max_children_per_line = 20
        };

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.add (flowbox);
        
        add (main_revealer);
        
        add_labels ();

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = has_items;
            return GLib.Source.REMOVE;
        });

        button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                var dialog = new Dialogs.LabelPicker.LabelPicker (item);
                
                dialog.labels_changed.connect ((labels) => {
                    labels_changed (labels);
                });
                
                dialog_open (true);
                dialog.popup ();

                dialog.destroy.connect (() => {
                    dialog_open (false);
                });
            }

            return Gdk.EVENT_PROPAGATE;
        });

        flowbox.add.connect (() => {
            main_revealer.reveal_child = has_items;
        });

        flowbox.remove.connect (() => {
            main_revealer.reveal_child = has_items;
        });
    }

    public void add_labels () {
        foreach (Objects.ItemLabel item_label in item.labels.values) {
            flowbox.add (new Widgets.ItemLabelChild (item_label));
            flowbox.show_all ();
        }
    }

    public void update_labels () {
        foreach (unowned Gtk.Widget child in flowbox.get_children ()) {
            child.destroy ();
        }

        add_labels ();
    }
}
