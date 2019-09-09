public class Views.Inbox : Gtk.EventBox {
    private Gtk.ListBox listbox;

    construct {
        var HAND_cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), Gdk.CursorType.HAND1);
        var ARROW_cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), Gdk.CursorType.ARROW);
        var window = Gdk.Screen.get_default ().get_root_window ();

        var icon_image = new Gtk.Image ();
        icon_image.valign = Gtk.Align.CENTER;
        icon_image.gicon = new ThemedIcon ("mail-mailbox-symbolic");
        icon_image.get_style_context ().add_class ("inbox");
        icon_image.pixel_size = 24;

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Inbox")));
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        title_label.use_markup = true;

        var settings_button = new Gtk.MenuButton ();
        settings_button.valign = Gtk.Align.CENTER;
        //settings_button.tooltip_text = _("Edit Name and Appearance");
        //settings_button.popover = list_settings_popover;
        settings_button.image = new Gtk.Image.from_icon_name ("view-more-horizontal-symbolic", Gtk.IconSize.MENU);
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_start = 24;
        top_box.margin_end = 24;

        top_box.pack_start (icon_image, false, false, 0);
        top_box.pack_start (title_label, false, false, 6);
        top_box.pack_end (settings_button, false, false, 0);

        listbox = new Gtk.ListBox  ();
        listbox.margin_top = 6;
        //listbox.get_style_context ().add_class ("pane");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        var new_entry = new Gtk.Entry ();
        new_entry.hexpand = true;
        //new_entry.placeholder_text = _("");
        new_entry.get_style_context ().add_class ("new-item-entry");

        var add_button = new Gtk.Button.from_icon_name ("planner-return-symbolic", Gtk.IconSize.MENU); //
        add_button.label = _("Add");
        add_button.always_show_image = true;
        add_button.image_position = Gtk.PositionType.RIGHT;
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        add_button.get_style_context ().add_class ("no-padding-right");

        add_button.clicked.connect (() => {
            //add_task ();
        });

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        cancel_button.clicked.connect (() => {
            //clear ();
        });

        var action_box = new Gtk.Box (Gtk.HORIZONTAL, 0);
        action_box.halign = Gtk.Align.END;
        action_box.pack_start (cancel_button, false, false, 0);
        action_box.pack_start (add_button, false, false, 0);

        var new_box = new Gtk.Grid ();
        new_box.margin_start = 28;
        new_box.margin_top = 6;
        new_box.margin_end = 28;
        new_box.row_spacing = 3;
        new_box.orientation = Gtk.Orientation.VERTICAL;
        new_box.add (new_entry);
        new_box.add (action_box);

        var add_image = new Gtk.Image ();
        add_image.valign = Gtk.Align.CENTER;
        add_image.gicon = new ThemedIcon ("list-add-symbolic");
        add_image.get_style_context ().add_class ("add-project-image");
        add_image.pixel_size = 14;

        var add_label = new Gtk.Label (_("Add task"));
        add_label.get_style_context ().add_class ("pane-item");
        add_label.get_style_context ().add_class ("add-project-label");
        add_label.margin_bottom = 1;
        add_label.use_markup = true;

        var add_grid = new Gtk.Grid ();
        add_grid.margin_bottom = 6;
        add_grid.margin_top = 6;
        add_grid.margin_start = 8;
        add_grid.column_spacing = 6;
        add_grid.add (add_image);
        add_grid.add (add_label);

        var add_eventbox = new Gtk.EventBox ();
        add_eventbox.margin_top = 6;
        add_eventbox.margin_start = 20;
        add_eventbox.valign = Gtk.Align.CENTER;
        add_eventbox.add (add_grid);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (listbox, false, false, 0);
        main_box.pack_start (new_box, false, false, 0);
        main_box.pack_start (add_eventbox, false, false, 0);

        add (main_box);

        add_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                //new_project.reveal = true;
            }

            return false;
        });

        add_eventbox.enter_notify_event.connect ((event) => {
            add_image.get_style_context ().add_class ("active");
            add_label.get_style_context ().add_class ("active");
            
            window.cursor = HAND_cursor;
            return true;
        });

        add_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            window.cursor = ARROW_cursor;
            add_image.get_style_context ().remove_class ("active");
            add_label.get_style_context ().remove_class ("active");

            return true;
        });
    }
}