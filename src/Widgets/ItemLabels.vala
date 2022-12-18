public class Widgets.ItemLabels : Gtk.Grid {
    public Objects.Item item { get; construct; }

    private Gtk.FlowBox flowbox;
    private Gtk.Revealer main_revealer;
    
    public signal void labels_changed (Gee.HashMap <string, Objects.Label> labels);
    public signal void dialog_open (bool value);

    private bool has_items {
        get {
            return Util.get_default ().get_children (flowbox).length () > 0;
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
        main_revealer.child = flowbox;
        
        attach (main_revealer, 0, 0);
        add_labels ();

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;//has_items;
            return GLib.Source.REMOVE;
        });

        //  button_press_event.connect ((sender, evt) => {
        //      if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
        //          var dialog = new Dialogs.LabelPicker.LabelPicker ();
        //          dialog.item = item;
                
        //          dialog.labels_changed.connect ((labels) => {
        //              labels_changed (labels);
        //          });
                
        //          dialog_open (true);
        //          dialog.popup ();

        //          dialog.destroy.connect (() => {
        //              dialog_open (false);
        //          });
        //      }

        //      return Gdk.EVENT_PROPAGATE;
        //  });

        item.item_label_added.connect ((item_label) => {
            // flowbox.append (new Widgets.ItemLabelChild (item_label));
        });

        //  flowbox.add.connect (() => {
        //      main_revealer.reveal_child = has_items;
        //  });

        //  flowbox.remove.connect (() => {
        //      main_revealer.reveal_child = has_items;
        //  });
    }

    public void add_labels () {
        print ("----------------------------\n");
        foreach (Objects.ItemLabel item_label in item.labels.values) {
            // flowbox.append (new Widgets.ItemLabelChild (item_label));
            print ("Label: %s\n".printf (item_label.label.name));
        }
    }

    public void update_labels () {
        //  for (Gtk.Widget child = flowbox.get_first_child (); child != null; child = flowbox.get_next_sibling ()) {
        //      flowbox.remove (child);
        //  }

        // add_labels ();
    }
}