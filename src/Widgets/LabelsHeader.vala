public class Widgets.LabelsHeader : Gtk.Grid {
    public Gee.ArrayList<Gtk.Overlay> labels_widgets;

    private Gtk.Box labels_box;
    private Gtk.Stack stack;
    private Gtk.Popover popover = null;

    public bool has_labels {
        get {
            return labels_widgets.size > 0;
        }
    }

    public LabelsHeader () {
        Object (
            tooltip_text: _("Filter by Labels")
        );
    }

    construct {
        labels_widgets = new Gee.ArrayList<Gtk.Overlay> ();

        var placeholder_button = new Gtk.Button.with_label (_("No label available, click to add one")) {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER
        };

        placeholder_button.add_css_class ("button-outline");
        placeholder_button.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        labels_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);

        stack = new Gtk.Stack () {
            vexpand = true,
            hexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE,
            vhomogeneous = false,
            hhomogeneous = false
        };

        stack.add_named (placeholder_button, "placeholder");
        stack.add_named (labels_box, "labels");

        attach (stack, 0, 0);

        placeholder_button.clicked.connect (() => {
            var dialog = new Dialogs.Label.new (BackendType.LOCAL);
            dialog.show ();
        });

        Services.EventBus.get_default ().open_labels.connect (open_labels_popover);

        Services.EventBus.get_default ().close_labels.connect (() => {
            if (popover != null) {
                popover.popdown ();
            }
        });

        Services.Database.get_default ().label_added.connect (init);
        Services.Database.get_default ().label_deleted.connect (remove_label);
        Services.Database.get_default ().label_updated .connect (update_label);

        var click_gesture = new Gtk.GestureClick ();
        click_gesture.set_button (1);
        labels_box.add_controller (click_gesture);

        click_gesture.pressed.connect (() => {
            open_labels_popover ();
        });
    }

    public void init () {
        if (labels_widgets.size > 0) {
            labels_box.remove (labels_widgets[0]);
        }

        labels_widgets.clear ();

        foreach (Objects.Label label in Services.Database.get_default ().labels) {
            add_preview_label (label);
        }
    }

    private void add_preview_label (Objects.Label label) {
        if (labels_widgets.size < 10) {
            var grid = new Gtk.Grid () {
                height_request = 16,
                width_request = 16,
                valign = Gtk.Align.CENTER,
                halign = Gtk.Align.CENTER
            };

            grid.add_css_class ("color-label-widget");
            Util.get_default ().set_widget_color (Util.get_default ().get_color (label.color), grid);
            
            Gtk.Overlay grid_overlay = new Gtk.Overlay ();
            grid_overlay.child = grid;
            
            if (labels_widgets.size <= 0) {
                labels_box.append (grid_overlay);
            } else {
                grid.margin_start = labels_widgets.size * 8;
                Gtk.Overlay preview_overlay = labels_widgets [labels_widgets.size - 1];
                preview_overlay.add_overlay (grid_overlay);
            }

            labels_widgets.add (grid_overlay);
            labels_box.margin_end = labels_widgets.size * 7;
        }

        stack.visible_child_name = has_labels ? "labels" : "placeholder";
    }

    private void remove_label (Objects.Label label) {
        init ();
        stack.visible_child_name = has_labels ? "labels" : "placeholder";
    }

    private void update_label (Objects.Label label) {
        init ();
    }

    private void open_labels_popover () {
        if (popover != null) {
            popover.popup ();
            return;
        }

        var labels_content = new Layouts.HeaderItem (_("Labels"));
        labels_content.add_tooltip = _("Add label");
        labels_content.placeholder_message = _("Your list of filters will show up here. Create one by clicking on the '+' button");
        labels_content.card = false;

        labels_content.row_activated.connect ((row) => {
            if (popover != null) {
                popover.popdown ();
            }

            Services.EventBus.get_default ().pane_selected (PaneType.LABEL, ((Layouts.LabelRow) row).label.id_string);
        });
        
        labels_content.add_activated.connect (() => {
            if (popover != null) {
                popover.popdown ();
            }

            var dialog = new Dialogs.Label.new (BackendType.LOCAL);
            dialog.show ();
        });

        Services.Database.get_default ().label_added.connect ((label) => {
            var row = new Layouts.LabelRow (label);
            labels_content.add_child (row);
        });

        var popover_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        popover_box.width_request = 275;
        popover_box.append (labels_content);

        popover = new Gtk.Popover () {
            has_arrow = false,
            child = popover_box,
            position = Gtk.PositionType.BOTTOM
        };

        popover.set_parent (this);
        popover.popup ();

        foreach (Objects.Label label in Services.Database.get_default ().labels) {    
            var row = new Layouts.LabelRow (label);
            labels_content.add_child (row);
        }
    }
}
