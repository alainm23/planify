public class Dialogs.SettingsDialog : Gtk.Dialog {
    public weak MainWindow parent_window { private get; construct; }
    private Gtk.Stack main_stack;

    public signal void on_close ();
    public SettingsDialog (MainWindow parent) {
		 Object (parent_window: parent);
	}

    construct {
        // Window properties
        title = _("Preferences");
        set_size_request (600, 400);
        resizable = false;
        deletable = true;
        destroy_with_parent = true;
        window_position = Gtk.WindowPosition.CENTER;
        set_transient_for (parent_window);

        Gtk.HeaderBar headerbar = get_header_bar () as Gtk.HeaderBar;
        headerbar.show_close_button = true;

        var general = new FormatButton ();
        general.icon = new ThemedIcon ("planner-settings");
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

        var stack = new Gtk.Stack ();

        var close_button = new Gtk.Button.with_label (_("Close"));
        close_button.clicked.connect (() => {
            on_close ();
            this.destroy ();
        });

        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_box.margin_right = 10;
        button_box.set_layout (Gtk.ButtonBoxStyle.END);
        button_box.pack_end (close_button);

        var content_grid = new Gtk.Grid ();
        content_grid.attach (mode_button, 0, 0, 1, 1);
        content_grid.attach (stack, 0, 1, 1, 1);

        ((Gtk.Container) get_content_area ()).add (content_grid);
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
