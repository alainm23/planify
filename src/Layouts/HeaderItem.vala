

public class Layouts.HeaderItem : Gtk.Grid {
    public PaneType pane_type { get; construct; }
    public string pane_title { get; construct; }

    public string _header_title;
    public string header_title {
        get {
            return _header_title;
        }

        set {
            _header_title = value;
            name_label.label = _header_title;
        }
    }

    public string _add_tooltip;
    public string add_tooltip {
        get {
            return _add_tooltip;
        }

        set {
            _add_tooltip = value;
            add_button.tooltip_text = value;
        }
    }
    
    public string _placeholder_message;
    public string placeholder_message {
        get {
            return _placeholder_message;
        }

        set {
            _placeholder_message = value;
            placeholder_label.label = _placeholder_message;
        }
    }

    private Gtk.Label name_label;
    private Gtk.Label placeholder_label;
    private Gtk.ListBox listbox;
    private Gtk.Button add_button;
    private Gtk.Stack action_stack;
    private Gtk.Revealer action_revealer;
    private Gtk.Revealer content_revealer;

    public signal void row_selected (Gtk.ListBoxRow row);
    public signal void add_activated ();

    private bool has_children {
        get {
            return false; // listbox.get_children ().length () > 0;
        }
    }

    public bool is_loading {
        set {
            action_stack.visible_child_name = value ? "spinner" : "button";
        }
    }

    public bool show_action {
        set {
            action_revealer.reveal_child = value;
        }
    }
    
    public HeaderItem (PaneType pane_type, string pane_title = "") {
        Object (
            pane_type: pane_type,
            pane_title: pane_title
        );
    }

    construct {
        name_label = new Gtk.Label (null) {
            halign = Gtk.Align.START
        };

        name_label.add_css_class (Granite.STYLE_CLASS_H4_LABEL);
        name_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var content_grid = new Gtk.Grid ();

        listbox = new Gtk.ListBox () {
            hexpand = true
        };
        
        listbox.set_placeholder (get_placeholder ());
        
        listbox.add_css_class(Granite.STYLE_CLASS_CARD);
        listbox.add_css_class("padding-3");

        content_grid.attach (listbox, 0, 0, 1, 1);

        var add_image = new Widgets.DynamicIcon () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
        };
        add_image.size = 21;
        add_image.update_icon_name ("planner-plus-circle");

        add_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        add_button.child = add_image;

        add_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        add_button.add_css_class ("no-padding");
        add_button.add_css_class ("action-button");

        // Loading
        var spinner_loading = new Gtk.Spinner () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            spinning = true
        };
        
        spinner_loading.start ();

        action_stack = new Gtk.Stack () {
            halign = Gtk.Align.END,
            hexpand = true,
            valign = Gtk.Align.CENTER,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        action_stack.add_named (add_button, "button");
        action_stack.add_named (spinner_loading, "spinner");

        action_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            reveal_child = true
        };

        action_revealer.child = action_stack;

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            margin_start = 6,
            margin_end = 3
        };

        header_box.append (name_label);
        header_box.append (action_revealer);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            margin_start = 3,
            margin_end = 3,
            margin_top = 3,
            margin_bottom = 3
        };

        content_box.append (header_box);
        content_box.append (content_grid);

        content_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = pane_type != PaneType.FAVORITE
        };

        content_revealer.child = content_box;

        attach(content_revealer, 0, 0);
        update_labels ();

        add_button.clicked.connect (() => {
            add_activated ();
        });

        listbox.row_selected.connect ((row) => {
            if (row != null) {
                row_selected (row);
            }
        });
    }

    private void update_labels () {
        if (pane_type == PaneType.PROJECT) {
            header_title = "Local Projects";
            add_tooltip = _("Add Project");
            placeholder_message = _("No project available. Create one by clicking on the '+' button");
        } else if (pane_type == PaneType.LABEL) {
            header_title = _("Labels");
            add_tooltip = _("Add label");
            placeholder_message = _("Your list of filters will show up here. Create one by clicking on the '+' button");
        } else if (pane_type == PaneType.FAVORITE) {
            header_title = _("Favorites");
            placeholder_message = _("No favorites available. Create one by clicking on the '+' button");
        } else if (pane_type == PaneType.TASKLIST) {
            header_title = pane_title;
            add_tooltip = _("Add tasklist");
            placeholder_message = _("No tasklist available. Create one by clicking on the '+' button");
        }
    }

    private Gtk.Widget get_placeholder () {
        placeholder_label = new Gtk.Label (null) {
            wrap = true,
            justify = Gtk.Justification.CENTER
        };
        
        placeholder_label.add_css_class ("dim-label");
        placeholder_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12,
        };

        content_box.append (placeholder_label);
        content_box.show ();

        return content_box;
    }


    public void add_child (Gtk.Widget widget) {
        listbox.append (widget);
        listbox.show ();
    }
}