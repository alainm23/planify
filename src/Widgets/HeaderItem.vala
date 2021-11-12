public class Widgets.HeaderItem : Gtk.EventBox {
    public PaneType pane_type { get; construct; }
    public string item_name { get; set; }
    public string add_tooltip { get; set; }
    public string placeholder_message { get; set; }

    private Gtk.Label name_label;
    private Gtk.ListBox listbox;
    private Gtk.Stack action_stack;

    public signal void add_activated ();

    public bool is_loading {
        set {
            action_stack.visible_child_name = value ? "spinner" : "button";
        }
    }

    public HeaderItem (PaneType pane_type) {
        Object (
            pane_type: pane_type
        );
    }

    construct {
        update_labels ();

        name_label = new Gtk.Label (item_name) {
            margin_start = 12,
            halign = Gtk.Align.START
        };
        name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        listbox = new Gtk.ListBox () {
            hexpand = true
        };
        listbox.set_placeholder (get_placeholder ());
        listbox.get_style_context ().add_class ("pane-listbox");

        var listbox_grid = new Gtk.Grid () {
            margin = 9,
            margin_top = 0
        };
        listbox_grid.add (listbox);

        var add_image = new Widgets.DynamicIcon ();
        add_image.size = 19;
        add_image.icon_name = "planner-plus-circle";
        
        var add_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false,
            tooltip_text = add_tooltip
        };

        add_button.add (add_image);

        unowned Gtk.StyleContext add_button_context = add_button.get_style_context ();
        add_button_context.add_class (Gtk.STYLE_CLASS_FLAT);
        add_button_context.add_class ("no-padding");
        add_button_context.add_class ("action-button");

        // Loading
        var spinner_loading = new Gtk.Spinner () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            active = true
        };
        spinner_loading.start ();
        
        action_stack = new Gtk.Stack () {
            halign = Gtk.Align.END,
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_end = 15,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        action_stack.add_named (add_button, "button");
        action_stack.add_named (spinner_loading, "spinner");

        var header_grid = new Gtk.Grid () {
            hexpand = true
        };
        header_grid.add (name_label);
        header_grid.add (action_stack);
        
        var main_grid = new Gtk.Grid () {
            hexpand = true,
            orientation = Gtk.Orientation.VERTICAL
        };
        main_grid.add (header_grid);
        main_grid.add (listbox_grid);

        add (main_grid);

        add_button.clicked.connect (() => {
            add_activated ();
        });
    }

    private void update_labels () {
        if (pane_type == PaneType.PROJECT) {
            item_name = _("Projects");
            add_tooltip = _("Add project");
            placeholder_message = _("No project available. Create one by clicking on the '+' button");
        } else if (pane_type == PaneType.LABEL) {
            item_name = _("Labels");
            add_tooltip = _("Add label");
            placeholder_message = _("Your list of filters will show up here. Create one by clicking on the '+' button");
        }
    }

    private Gtk.Widget get_placeholder () {
        var message_label = new Gtk.Label (placeholder_message) {
            wrap = true,
            justify = Gtk.Justification.CENTER
        };
        
        unowned Gtk.StyleContext message_label_context = message_label.get_style_context ();
        message_label_context.add_class ("dim-label");
        message_label_context.add_class ("small-label");

        var grid = new Gtk.Grid () {
            margin = 6
        };
        grid.add (message_label);
        grid.show_all ();

        return grid;
    }

    public void add_child (Gtk.Widget widget) {
        listbox.add (widget);
        listbox.show_all ();
    }
}
