public class Dialogs.Settings.SettingsContent : Gtk.EventBox {
    public string? title { get; construct; }

    private Gtk.Grid content_grid;
    private Gtk.Revealer add_revealer;

    public bool add_action {
        set {
            add_revealer.reveal_child = value;
        }
    }

    public signal void add_activated ();

    public SettingsContent (string? title) {
        Object (
            title: title,
            margin: 12,
            margin_top: 0
        );
    }

    construct {
        var title_label = new Gtk.Label (title) {
            halign = Gtk.Align.START,
            margin_start = 3
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var add_image = new Widgets.DynamicIcon ();
        add_image.size = 19;
        add_image.update_icon_name ("planner-plus-circle");
        
        var add_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false,
            hexpand = true,
            halign = Gtk.Align.START,
            margin_start = 3
        };

        add_button.add (add_image);

        add_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            reveal_child = false
        };
        add_revealer.add (add_button);

        unowned Gtk.StyleContext add_button_context = add_button.get_style_context ();
        add_button_context.add_class (Gtk.STYLE_CLASS_FLAT);
        add_button_context.add_class ("no-padding");
        add_button_context.add_class ("action-button");

        var header_grid = new Gtk.Grid () {
            hexpand = true
        };
        header_grid.add (title_label);
        header_grid.add (add_revealer);

        content_grid = new Gtk.Grid () {
            row_spacing = 6,
            orientation = Gtk.Orientation.VERTICAL,
            hexpand =  true
        };

        unowned Gtk.StyleContext content_grid_context = content_grid.get_style_context ();
        content_grid_context.add_class ("picker-content");

        var main_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL
        };
        
        if (title != null) {
            main_grid.add (header_grid);
        }
        main_grid.add (content_grid);

        add (main_grid);

        add_button.clicked.connect (() => {
            add_activated ();
        });
    }

    public void add_child (Gtk.Widget child) {
        content_grid.add (child);
        content_grid.show_all ();
    }

    public void attach_child (Gtk.Widget child, int left, int top) {
        content_grid.attach (child, left, top);
        content_grid.show_all ();
    }

    public void add_class (string class_name) {
        unowned Gtk.StyleContext content_grid_context = content_grid.get_style_context ();
        content_grid_context.add_class (class_name);
    }
}
