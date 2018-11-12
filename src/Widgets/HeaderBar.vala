public class Widgets.HeaderBar : Gtk.HeaderBar {
    public weak MainWindow window { get; construct; }
    public Dialogs.SettingsDialog settings_dialog;

    public const string CSS = """
        @define-color headerbar_color %s;
    """;

    public HeaderBar (MainWindow parent) {
        Object (
            window: parent,
            show_close_button: true
        );
    }

    construct {
        get_style_context ().add_class ("compact");

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

        var notification_button = new Gtk.Button.from_icon_name ("preferences-system-notifications", Gtk.IconSize.LARGE_TOOLBAR);

        var label = new Gtk.Label (_("Night Mode"));
        label.margin_start = 6;

        var night_mode_menuitem = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        night_mode_menuitem.get_style_context ().add_class ("menuitem");
        night_mode_menuitem.pack_start (label, false, false, 0);
        night_mode_menuitem.pack_end (mode_switch, false, false, 0);

        var preferences_menuitem = new Gtk.ModelButton ();
        preferences_menuitem.text = _("Preferences");

        var menu_grid = new Gtk.Grid ();
        menu_grid.margin_bottom = 3;
        menu_grid.orientation = Gtk.Orientation.VERTICAL;
        menu_grid.width_request = 250;

        menu_grid.add (get_overview ());
        menu_grid.add (night_mode_menuitem);
        menu_grid.add (preferences_menuitem);
        menu_grid.show_all ();

        var menu = new Gtk.Popover (null);
        menu.add (menu_grid);

        var app_menu = new Gtk.MenuButton ();
        app_menu.border_width = 4;
        app_menu.image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
        app_menu.tooltip_text = _("Menu");
        app_menu.popover = menu;

        pack_end (app_menu);
        //pack_end (mode_switch);
        pack_end (notification_button);
        pack_end (search_entry);

        mode_switch.notify["active"].connect (() => {
            var provider = new Gtk.CssProvider ();
            var colored_css = "";

            if (mode_switch.active) {
                colored_css = CSS.printf ("@base_color");
            } else {
                colored_css = CSS.printf ("#ffe16b");
            }

            try {
                provider.load_from_data (colored_css, colored_css.length);

                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (GLib.Error e) {
                return;
            }
        });

        preferences_menuitem.clicked.connect (() => {
            settings_dialog = new Dialogs.SettingsDialog (window);
            settings_dialog.destroy.connect (Gtk.main_quit);
            settings_dialog.show_all ();
        });
    }

    private Gtk.Grid get_overview () {
        var username = GLib.Environment.get_user_name ();
        var iconfile = @"/var/lib/AccountsService/icons/$username";

        var avatar = new Granite.Widgets.Avatar.from_file (iconfile, 44);

        var username_label = new Gtk.Label ("<b>%s</b>".printf (GLib.Environment.get_real_name ()));
        username_label.margin_top = 6;
        username_label.halign = Gtk.Align.CENTER;
        username_label.use_markup = true;

        var overview_levelbar = new Gtk.LevelBar.for_interval (0.0, 1.0);
        overview_levelbar.margin_top = 12;
        overview_levelbar.valign = Gtk.Align.CENTER;
        overview_levelbar.hexpand = true;
        overview_levelbar.width_request = 200;
        overview_levelbar.value = 0.5;

        var completed_task_label = new Gtk.Label (_("Completed tasks"));
        completed_task_label.max_width_chars = 1;
        completed_task_label.valign = Gtk.Align.CENTER;
        completed_task_label.wrap = true;
        completed_task_label.use_markup = true;
        completed_task_label.justify = Gtk.Justification.CENTER;

        var completed_task_number = new Gtk.Label ("12");
        completed_task_number.get_style_context ().add_class ("h3");
        completed_task_number.get_style_context ().add_class ("h4");

        var completed_task_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        completed_task_box.pack_start (completed_task_number, false, false, 0);
        completed_task_box.pack_start (completed_task_label, false, false, 0);

        var todo_task_label = new Gtk.Label (_("To do tasks"));
        todo_task_label.max_width_chars = 1;
        todo_task_label.valign = Gtk.Align.CENTER;
        todo_task_label.wrap = true;
        todo_task_label.use_markup = true;
        todo_task_label.justify = Gtk.Justification.CENTER;

        var todo_task_number = new Gtk.Label ("22");
        todo_task_number.get_style_context ().add_class ("h3");
        todo_task_number.get_style_context ().add_class ("h4");

        var todo_task_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        todo_task_box.pack_start (todo_task_number, false, false, 0);
        todo_task_box.pack_start (todo_task_label, false, false, 0);

        var all_task_label = new Gtk.Label (_("All tasks"));
        all_task_label.max_width_chars = 1;
        all_task_label.valign = Gtk.Align.CENTER;
        all_task_label.wrap = true;
        all_task_label.use_markup = true;
        all_task_label.justify = Gtk.Justification.CENTER;

        var all_task_number = new Gtk.Label ("69");
        all_task_number.get_style_context ().add_class ("h3");
        all_task_number.get_style_context ().add_class ("h4");

        var all_task_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        all_task_box.pack_start (all_task_number, false, false, 0);
        all_task_box.pack_start (all_task_label, false, false, 0);

        var grid = new Gtk.Grid ();
        grid.margin_top = 12;
        grid.column_homogeneous = true;
        grid.add (completed_task_box);
        grid.add (todo_task_box);
        grid.add (all_task_box);

        var overview_grid = new Gtk.Grid ();
        overview_grid.orientation = Gtk.Orientation.VERTICAL;
        overview_grid.margin = 12;
        overview_grid.add (avatar);
        overview_grid.add (username_label);
        overview_grid.add (overview_levelbar);
        overview_grid.add (grid);

        return overview_grid;
    }
}
