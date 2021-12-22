public class Layouts.HeaderItem : Gtk.EventBox {
    public PaneType pane_type { get; construct; }
    public ContainerType container_shape { get; construct; }
    public Gtk.SelectionMode selection_mode { get; construct; }
    public string item_name { get; set; }
    public string add_tooltip { get; set; }
    public string placeholder_message { get; set; }

    private Gtk.Label name_label;
    private Gtk.ListBox listbox;
    private Gtk.FlowBox flowbox;
    private Gtk.Stack action_stack;
    private Gtk.Revealer action_revealer;
    private Gtk.Revealer main_revealer;

    public signal void add_activated ();

    private bool has_children {
        get {
            return listbox.get_children ().length () > 0;
        }
    }

    public bool is_loading {
        set {
            action_stack.visible_child_name = value ? "spinner" : "button";
        }
    }

    public HeaderItem (PaneType pane_type,
        ContainerType container_shape=ContainerType.LISTBOX,
        Gtk.SelectionMode selection_mode=Gtk.SelectionMode.SINGLE) {
        Object (
            pane_type: pane_type,
            container_shape: container_shape,
            selection_mode: selection_mode
        );
    }

    construct {
        update_labels ();

        name_label = new Gtk.Label (item_name) {
            margin_start = 12,
            halign = Gtk.Align.START
        };
        name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        var arrow_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("pan-end-symbolic"),
            pixel_size = 13
        };
        
        var arrow_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            hexpand = true,
            halign = Gtk.Align.END,
            can_focus = false,
            image = arrow_icon,
            margin_end = 15
        };
        arrow_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        arrow_button.get_style_context ().add_class ("dim-label");
        arrow_button.get_style_context ().add_class ("transparent");
        arrow_button.get_style_context ().add_class ("hidden-button");
        arrow_button.get_style_context ().add_class ("no-padding");

        var content_grid = new Gtk.Grid () {
            margin = 9,
            margin_top = 0
        };

        if (container_shape == ContainerType.LISTBOX) {
            listbox = new Gtk.ListBox () {
                hexpand = true,
                selection_mode = selection_mode
            };
            listbox.set_placeholder (get_placeholder ());
            
            unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
            listbox_context.add_class ("pane-content");
            listbox_context.add_class ("listbox-separator-3");

            content_grid.add (listbox);
        } else {
            flowbox = new Gtk.FlowBox () {
                selection_mode = selection_mode,
                column_spacing = 6,
                row_spacing = 6,
                hexpand = true,
                min_children_per_line = 2
            }; 
            
            // flowbox.set_placeholder (get_placeholder ());

            unowned Gtk.StyleContext flowbox_context = flowbox.get_style_context ();
            flowbox_context.add_class ("pane-content");
            
            content_grid.add (flowbox);
        }

        var add_image = new Widgets.DynamicIcon ();
        add_image.size = 16;
        add_image.icon_name = "planner-plus-circle";
        
        var add_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false,
            tooltip_text = add_tooltip,
            margin_top = 1
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
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            margin_start = 3,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        action_stack.add_named (add_button, "button");
        action_stack.add_named (spinner_loading, "spinner");

        action_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            reveal_child = pane_type != PaneType.FAVORITE
        };
        action_revealer.add (action_stack);

        var header_grid = new Gtk.Grid () {
            hexpand = true
        };
        header_grid.add (name_label);
        header_grid.add (action_revealer);
        header_grid.add (arrow_button);
        
        
        var main_grid = new Gtk.Grid () {
            hexpand = true,
            orientation = Gtk.Orientation.VERTICAL
        };
        main_grid.add (header_grid);
        main_grid.add (content_grid);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = pane_type != PaneType.FAVORITE
        };
        main_revealer.add (main_grid);

        add (main_revealer);

        add_button.clicked.connect (() => {
            add_activated ();
        });

        if (pane_type == PaneType.FAVORITE) {
            listbox.add.connect (() => {
                main_revealer.reveal_child = has_children;
            });

            listbox.remove.connect (() => {
                main_revealer.reveal_child = has_children;
            });
        }
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
        } else if (pane_type == PaneType.FAVORITE) {
            item_name = _("Favorites");
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
        if (container_shape == ContainerType.LISTBOX) {
            listbox.add (widget);
            listbox.show_all ();
        } else {
            flowbox.add (widget);
            flowbox.show_all ();
        }
    }
}
