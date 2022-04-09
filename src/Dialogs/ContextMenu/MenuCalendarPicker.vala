public class Dialogs.ContextMenu.MenuCalendarPicker : Gtk.EventBox {
    public string title { get; construct; }
    
    public signal void selection_changed (GLib.DateTime date);

    public MenuCalendarPicker (string title) {
        Object (
            title: title,
            hexpand: true,
            can_focus: false
        );
    }

    construct {
        var menu_icon = new Widgets.DynamicIcon ();
        menu_icon.size = 19;
        menu_icon.update_icon_name ("planner-scheduled");

        var menu_title = new Gtk.Label (title);

        var arrow_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("pan-end-symbolic"),
            pixel_size = 14
        };

        var arrow_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END,
            hexpand = true,
            can_focus = false,
            image = arrow_icon,
            margin_end = 6
        };

        unowned Gtk.StyleContext arrow_button_context = arrow_button.get_style_context ();
        arrow_button_context.add_class (Gtk.STYLE_CLASS_FLAT);
        arrow_button_context.add_class ("no-padding");
        arrow_button_context.add_class ("hidden-button");
        arrow_button_context.add_class ("dim-label");

        var menu_grid = new Gtk.Grid () {
            column_spacing = 6,
            hexpand = true
        };

        menu_grid.add (menu_icon);
        menu_grid.add (menu_title);
        menu_grid.add (arrow_button);

        var menu_button = new Gtk.Button () {
            can_focus = false
        };
        menu_button.add (menu_grid);

        unowned Gtk.StyleContext menu_button_context = menu_button.get_style_context ();
        menu_button_context.add_class ("menu-item");
        menu_button_context.add_class (Gtk.STYLE_CLASS_FLAT);
        menu_button_context.add_class ("transition");

        var calendar = new Widgets.Calendar.Calendar (false);

        var content_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };

        content_revealer.add (calendar);

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            hexpand = true
        };

        main_grid.add (menu_button);
        main_grid.add (content_revealer);

        add (main_grid);

        menu_button.clicked.connect (() => {
            content_revealer.reveal_child = !content_revealer.reveal_child;
            if (content_revealer.reveal_child) {
                arrow_button.get_style_context ().add_class ("opened");
            } else {
                arrow_button.get_style_context ().remove_class ("opened");
            }
        });

        calendar.selection_changed.connect ((date) => {
            selection_changed (date);
        });
    }
}
