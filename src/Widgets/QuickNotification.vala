public class Widgets.QuickNotification : Gtk.Revealer {
    construct {
        var image = new Gtk.Image ();
        image.gicon = new ThemedIcon ("align-horizontal-right");
        image.pixel_size = 32;

        var title_label = new Gtk.Label (null);
        title_label.halign = Gtk.Align.START;
        title_label.use_markup = true;
        //title_label.max_width_chars = 40;
        title_label.wrap = true;
        //title_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        //title_label.xalign = 0;

        description_label = new Gtk.Label (null);
        description_label.halign = Gtk.Align.START;
        description_label.use_markup = true;
    }
}