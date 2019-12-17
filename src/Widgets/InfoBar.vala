public class Widgets.InfoBar : Gtk.EventBox {
    public InfoBar () {}

    construct {
        var image = new Gtk.Image ();
        image.gicon = new ThemedIcon ("emblem-ok-symbolic");
        image.pixel_size = 16;
        image.valign = Gtk.Align.CENTER;

        var label = new Gtk.Label ("lorem xx asc as as casc asc a sc as c");

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.valign = Gtk.Align.CENTER;

        var button = new Gtk.Button.with_label (_("Aceptar"));
        button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        button.get_style_context ().add_class ("info-bar-button");
        button.valign = Gtk.Align.CENTER;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.get_style_context ().add_class ("infor-bar");
        box.hexpand = true;
        box.pack_start (image, false, false, 0);
        box.pack_start (label, false, true, 0);
        box.pack_end (button, false, false, 0);
        //box.pack_end (cancel_button, false, false, 0);
        
        add (box);
    }
}