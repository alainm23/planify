public class Widgets.LabelsHeader : Gtk.Grid {
    public Gee.HashMap <string, Gtk.Grid> labels_widgets_map;

    private Gtk.Box labels_box;
    private Gtk.Stack stack;
    private Layouts.HeaderItem labels_content;
    private Gtk.Popover popover = null;

    public bool has_labels {
        get {
            return labels_widgets_map.size > 0;
        }
    }

    public LabelsHeader () {
        Object (
            opacity: 0.75
        );
    }

    construct {
        labels_widgets_map = new Gee.HashMap <string, Gtk.Grid> ();

        var placeholder_button = new Gtk.Button.with_label (_("No label available, click to add one…")) {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER
        };

        placeholder_button.add_css_class ("button-outline");
        placeholder_button.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        labels_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);

        var labels_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER
        };

        labels_button.add_css_class ("button-labels-box");
        labels_button.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        labels_button.child = labels_box;

        stack = new Gtk.Stack () {
            vexpand = true,
            hexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        stack.add_named (placeholder_button, "placeholder");
        stack.add_named (labels_button, "labels");

        labels_content = new Layouts.HeaderItem (_("Labels"));
        labels_content.add_tooltip = _("Add label");
        labels_content.placeholder_message = _("Your list of filters will show up here. Create one by clicking on the '+' button");
        labels_content.card = false;

        labels_content.row_activated.connect ((row) => {
            if (popover != null) {
                popover.popdown ();
            }

            Planner.event_bus.pane_selected (PaneType.LABEL, ((Layouts.LabelRow) row).label.id_string);
        });

        attach (stack, 0, 0);

        placeholder_button.clicked.connect (() => {
            var dialog = new Dialogs.Label.new (true);
            dialog.show ();
        });

        labels_content.add_activated.connect (() => {
            if (popover != null) {
                popover.popdown ();
            }

            var dialog = new Dialogs.Label.new (true);
            dialog.show ();
        });

        labels_button.clicked.connect (open_labels_popover);
        Planner.event_bus.open_labels.connect (open_labels_popover);

        Planner.event_bus.close_labels.connect (() => {
            if (popover != null) {
                popover.popdown ();
            }
        });

        Services.Database.get_default ().label_added.connect (add_label);
        Services.Database.get_default ().label_deleted.connect (remove_label);
        Services.Database.get_default ().label_updated .connect (update_label);
    }

    public void init () {
        foreach (Objects.Label label in Services.Database.get_default ().labels) {
            add_label (label);
        }
    }

    private void add_label (Objects.Label label) {
        if (!labels_widgets_map.has_key (label.id_string)) {
            if (labels_widgets_map.size < 10) {
                var grid = new Gtk.Grid () {
                    height_request = 6,
                    width_request = 21,
                    tooltip_text = label.name,
                    valign = Gtk.Align.CENTER,
                    halign = Gtk.Align.CENTER
                };
    
                grid.add_css_class ("color-label-widget");
                Util.get_default ().set_widget_color (Util.get_default ().get_color (label.color), grid);
                labels_box.append (grid);
                labels_widgets_map.set (label.id_string, grid);
            }
            
            var row = new Layouts.LabelRow (label);
            labels_content.add_child (row);
        }

        stack.visible_child_name = has_labels ? "labels" : "placeholder";
    }

    private void remove_label (Objects.Label label) {
        if (labels_widgets_map.has_key (label.id_string)) {
            labels_box.remove (labels_widgets_map[label.id_string]);
            labels_widgets_map.unset (label.id_string);
        }

        stack.visible_child_name = has_labels ? "labels" : "placeholder";
    }

    private void update_label (Objects.Label label) {
        if (labels_widgets_map.has_key (label.id_string)) {
            labels_widgets_map[label.id_string].tooltip_text = label.name;
            Util.get_default ().set_widget_color (Util.get_default ().get_color (label.color), labels_widgets_map[label.id_string]);
        }
    }

    private void open_labels_popover () {
        if (popover != null) {
            popover.popup ();
            return;
        }

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
    }
}
