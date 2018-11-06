public class Dialogs.SettingsDialog : Gtk.Dialog {
    public weak MainWindow window { get; construct; }
    private Gtk.Stack main_stack;

    public SettingsDialog (MainWindow parent) {
		Object (
			resizable: false,
			transient_for: parent,
			window: parent,
            use_header_bar: 1,
            height_request: 400,
            width_request: 600
		);
	}

    construct {
        var general = new FormatButton ();
        general.icon = new ThemedIcon ("emblem-default");
        general.text = _("General");

        var cloud = new FormatButton ();
        cloud.icon = new ThemedIcon ("emblem-default");
        cloud.text = _("Cloud");

        var calendar = new FormatButton ();
        calendar.icon = new ThemedIcon ("emblem-default");
        calendar.text = _("Calendar");

        var mode_button = new Granite.Widgets.ModeButton ();
        mode_button.hexpand = true;
        mode_button.margin = 6;
        mode_button.halign = Gtk.Align.CENTER;
        mode_button.get_style_context ().add_class ("format-bar");

        mode_button.append (general);
        mode_button.append (cloud);
        mode_button.append (calendar);

        var headerbar = get_header_bar () as Gtk.HeaderBar;
        headerbar.show_close_button = true;
        headerbar.custom_title = mode_button;

        /*
        var headerbar = new Gtk.HeaderBar ();


        //
        set_titlebar (headerbar);

        main_stack = new Gtk.Stack ();
        main_stack.expand = true;

        Gtk.Box content = get_content_area () as Gtk.Box;
        content.pack_start (mode_grid, false, true, 0);
        */
    }
}

public class FormatButton : Gtk.Box {
    public unowned string text {
        set {
            label_widget.label = value;
        }

        get {
            return label_widget.get_label ();
        }
    }

    public unowned GLib.Icon? icon {
        owned get {
            return img.gicon;
        }
        set {
            img.gicon = value;
        }
    }

    private Gtk.Image img;
    private Gtk.Label label_widget;

    construct {
        can_focus = false;

        img = new Gtk.Image ();
        img.halign = Gtk.Align.END;
        img.icon_size = Gtk.IconSize.BUTTON;

        label_widget = new Gtk.Label (null);
        label_widget.halign = Gtk.Align.START;

        pack_start (img, true, true, 0);
        pack_start (label_widget, true, true, 0);
    }
}
