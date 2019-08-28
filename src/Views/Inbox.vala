public class Views.Inbox : Gtk.EventBox {
    construct {
        var icon_image = new Gtk.Image ();
        icon_image.valign = Gtk.Align.CENTER;
        icon_image.gicon = new ThemedIcon ("mail-mailbox-symbolic");
        icon_image.get_style_context ().add_class ("inbox");
        icon_image.pixel_size = 32;

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Inbox")));
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        title_label.get_style_context ().add_class ("inbox");
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
        top_box.pack_end (settings_button, false, false, 6);

        add (top_box);
    }
}