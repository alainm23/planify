public class Views.Today : Gtk.EventBox {
    public Today () {
        Object (
            expand: true
        );
    }

    construct {
        //get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        get_style_context ().add_class (Granite.STYLE_CLASS_WELCOME);

        var today_icon = new Gtk.Image.from_icon_name ("user-bookmarks", Gtk.IconSize.DND);

        var today_name = new Gtk.Label ("<b>%s</b>".printf (_("Today")));
        today_name.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        today_name.use_markup = true;

        var settings_button = new Gtk.ToggleButton ();
        settings_button.add (new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.BUTTON));
        settings_button.tooltip_text = _("Settings");
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.halign = Gtk.Align.CENTER;
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.hexpand = true;
        top_box.margin = 24;

        top_box.pack_start (today_icon, false, false, 0);
        top_box.pack_start (today_name, false, false, 12);
        top_box.pack_end (settings_button, false, false, 0);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (top_box);

        add (main_grid);
    }
}
