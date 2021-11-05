public class Widgets.HeaderItem : Gtk.EventBox {
    public string item_name { get; construct; }
    public string add_tooltip { get; construct; }
    public string placeholder_message { get; construct; }

    private Gtk.Label name_label;
    private Gtk.ListBox listbox;

    public HeaderItem (string item_name, string add_tooltip, string placeholder_message) {
        Object (
            item_name: item_name,
            add_tooltip: add_tooltip,
            placeholder_message: placeholder_message
        );
    }

    construct {
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

        var arrow_image = new Widgets.DynamicIcon ();
        arrow_image.size = 16;
        arrow_image.dark = false;
        arrow_image.icon_name = "pan-end-symbolic";
        
        var arrow_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        arrow_button.add (arrow_image);

        unowned Gtk.StyleContext arrow_button_context = arrow_button.get_style_context ();
        arrow_button_context.add_class (Gtk.STYLE_CLASS_FLAT);

        var action_grid = new Gtk.Grid () {
            halign = Gtk.Align.END,
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_end = 15
        };
        action_grid.add (add_button);
        // action_grid.add (arrow_button);

        var header_grid = new Gtk.Grid () {
            hexpand = true
        };
        header_grid.add (name_label);
        header_grid.add (action_grid);
        
        var main_grid = new Gtk.Grid () {
            hexpand = true,
            orientation = Gtk.Orientation.VERTICAL
        };
        main_grid.add (header_grid);
        main_grid.add (listbox_grid);

        add (main_grid);
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
