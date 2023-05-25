

public class Layouts.HeaderItem : Gtk.Grid {
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

    public bool reveal {
        get {
            return content_revealer.reveal_child;
        }

        set {
            content_revealer.reveal_child = value;
        }
    }

    public Gtk.ListBox items {
        get {
            return listbox;
        }
    }

    private Gtk.Label name_label;
    private Gtk.Label placeholder_label;
    private Gtk.ListBox listbox;
    private Gtk.Button add_button;
    private Gtk.Stack action_stack;
    private Gtk.Grid content_grid;
    private Gtk.Revealer action_revealer;
    private Gtk.Revealer content_revealer;
    private Gtk.Revealer separator_revealer;

    public signal void add_activated ();
    public signal void row_activated (Gtk.Widget widget);

    private bool has_children {
        get {
            return Util.get_default ().get_children (listbox).length () > 0;
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

    public bool show_separator {
        set {
            separator_revealer.reveal_child = value;
        }
    }

    public bool reveal_child {
        set {
            content_revealer.reveal_child = value;
        }
    }

    public bool card {
        set {
            if (value) {
                content_grid.add_css_class (Granite.STYLE_CLASS_CARD);
            } else {
                content_grid.remove_css_class (Granite.STYLE_CLASS_CARD);
                // content_grid.remove_css_class ("pane-content");
            }
        }
    }

    public bool separator_space {
        set {
            if (value) {
                listbox.add_css_class ("listbox-separator-3");
            }
        }
    }
    
    public HeaderItem (string? header_title) {
        Object (
            header_title: header_title
        );
    }

    construct {
        name_label = new Gtk.Label (null) {
            halign = Gtk.Align.START
        };

        name_label.add_css_class (Granite.STYLE_CLASS_H4_LABEL);
        name_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        listbox = new Gtk.ListBox () {
            hexpand = true
        };
        
        listbox.set_placeholder (get_placeholder ());
        listbox.add_css_class ("bg-transparent");

        content_grid = new Gtk.Grid () {
            margin_end = 1
        };

        content_grid.add_css_class (Granite.STYLE_CLASS_CARD);
        content_grid.add_css_class ("padding-3");
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
        add_button.add_css_class ("p3");

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

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3,
            margin_start = 3,
            margin_bottom = 3
        };

        separator_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };

        separator_revealer.child = separator;

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            margin_start = 3,
            margin_top = 3,
            margin_bottom = 3
        };

        content_box.append (header_box);
        content_box.append (separator_revealer);
        content_box.append (content_grid);

        content_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };

        content_revealer.child = content_box;

        attach(content_revealer, 0, 0);

        add_button.clicked.connect (() => {
            add_activated ();
        });

        listbox.row_activated.connect ((row) => {
            row_activated (row);
        });
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

        return content_box;
    }


    public void add_child (Gtk.Widget widget) {
        listbox.append (widget);
    }

    public void remove_child (Gtk.Widget widget) {
        listbox.remove (widget);
    }

    public void check_visibility (int size) {
        content_revealer.reveal_child = size > 0;
    }

    public void set_sort_func (Gtk.ListBoxSortFunc? sort_func) {
        listbox.set_sort_func (sort_func);
    }

    public void set_filter_func (Gtk.ListBoxFilterFunc? filter_func) {
        listbox.set_filter_func (filter_func);
    }

    public void invalidate_filter () {
        listbox.invalidate_filter ();
    }
}