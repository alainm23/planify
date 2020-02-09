public class Widgets.Placeholder : Gtk.Revealer {
    public Placeholder () {
        transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        expand = true;
    }

    construct {
        var icon = new Gtk.Image ();
        icon.gicon = new ThemedIcon ("mail-mailbox-symbolic");
        icon.pixel_size = 64;
        icon.get_style_context ().add_class ("dim-label");

        var title_label = new Gtk.Label (_("All clear"));
        title_label.margin_top = 6;
        title_label.get_style_context ().add_class ("h2");

        var subtitle_label = new Gtk.Label (_("Looks like everything's organized in the right place."));
        subtitle_label.margin_top = 6;
        subtitle_label.get_style_context ().add_class ("dim-label");
        //subtitle_label.get_style_context ().add_class ("welcome");

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.margin_bottom = 128;
        box.pack_start (icon, false, false, 0);
        box.pack_start (title_label, false, false, 0);
        box.pack_start (subtitle_label, false, false, 0);

        add (box);
    }
}
