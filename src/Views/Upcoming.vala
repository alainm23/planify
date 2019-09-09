public class Views.Upcoming : Gtk.EventBox {
    construct {
        var icon_image = new Gtk.Image ();
        icon_image.valign = Gtk.Align.CENTER;
        icon_image.gicon = new ThemedIcon ("x-office-calendar-symbolic");
        icon_image.get_style_context ().add_class ("upcoming");
        icon_image.pixel_size = 24;

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Upcoming")));
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        //title_label.get_style_context ().add_class ("upcoming");
        title_label.use_markup = true;

        var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        title_box.hexpand = true;
        title_box.valign = Gtk.Align.START;
        title_box.margin_start = 24;
        title_box.margin_end = 24;

        title_box.pack_start (icon_image, false, false, 0);
        title_box.pack_start (title_label, false, false, 6);

        add (title_box);
    }
}