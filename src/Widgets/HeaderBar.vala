public class Widgets.HeaderBar : Gtk.HeaderBar {
    public weak MainWindow window { get; construct; }
    public Dialogs.SettingsDialog settings_dialog;

    public HeaderBar (MainWindow parent) {
        Object (
            window: parent,
            show_close_button: true
        );
    }

    construct {
        get_style_context ().add_class ("compact");

        var username = GLib.Environment.get_user_name ();
        var iconfile = @"/var/lib/AccountsService/icons/$username";

        var avatar = new Granite.Widgets.Avatar.from_file (iconfile, 32);

        var username_label = new Gtk.Label ("<b>%s</b>".printf (GLib.Environment.get_real_name ()));
        username_label.valign = Gtk.Align.END;
        username_label.halign = Gtk.Align.START;
        username_label.use_markup = true;

        var overview_levelbar = new Gtk.LevelBar.for_interval (0.0, 1.0);
        overview_levelbar.valign = Gtk.Align.START;
        overview_levelbar.width_request = 200;
        overview_levelbar.value = 0.5;

        var overview_grid = new Gtk.Grid ();
        overview_grid.column_spacing = 6;
        overview_grid.attach (avatar, 0, 0, 1, 2);
        overview_grid.attach (username_label, 1, 0, 1, 1);
        overview_grid.attach (overview_levelbar, 1, 1, 1, 1);

        var search_entry = new Gtk.SearchEntry ();
        search_entry.width_request = 200;
        search_entry.valign = Gtk.Align.CENTER;
        search_entry.placeholder_text = _("Quick search");

        var mode_switch = new Granite.ModeSwitch.from_icon_name ("display-brightness-symbolic", "weather-clear-night-symbolic");
        mode_switch.margin_start = 12;
        mode_switch.primary_icon_tooltip_text = ("Light background");
        mode_switch.secondary_icon_tooltip_text = ("Dark background");
        mode_switch.valign = Gtk.Align.CENTER;

        var gtk_settings = Gtk.Settings.get_default ();

        mode_switch.bind_property ("active", gtk_settings, "gtk_application_prefer_dark_theme");
        Planner.settings.bind ("prefer-dark-style", mode_switch, "active", GLib.SettingsBindFlags.DEFAULT);

        var settings_menuitem = new Gtk.ModelButton ();
        settings_menuitem.text = _("Settings");

        var menu_grid = new Gtk.Grid ();
        menu_grid.margin_bottom = 3;
        menu_grid.orientation = Gtk.Orientation.VERTICAL;
        menu_grid.width_request = 200;

        menu_grid.add (settings_menuitem);

        menu_grid.show_all ();

        var menu = new Gtk.Popover (null);
        menu.add (menu_grid);

        var app_menu = new Gtk.MenuButton ();
        app_menu.border_width = 4;
        app_menu.image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
        app_menu.tooltip_text = _("Menu");
        app_menu.popover = menu;

        settings_dialog = new Dialogs.SettingsDialog (window);
        settings_dialog.destroy.connect (Gtk.main_quit);

        pack_end (app_menu);
        pack_end (mode_switch);
        pack_end (search_entry);

        settings_menuitem.clicked.connect (() => {
            settings_dialog.show_all ();
        });
    }
}
