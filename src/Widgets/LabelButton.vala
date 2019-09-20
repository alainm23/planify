public class Widgets.LabelButton : Gtk.ToggleButton {
    construct {
        get_style_context ().add_class ("flat");
        get_style_context ().add_class ("item-action-button");
        //get_style_context ().add_class ("dim-label");

        var label_icon = new Gtk.Image ();
        label_icon.valign = Gtk.Align.CENTER;
        label_icon.gicon = new ThemedIcon ("planner-label-symbolic");
        label_icon.pixel_size = 16;

        var label = new Gtk.Label (_("Labels"));
        label.get_style_context ().add_class ("pane-item");
        label.margin_bottom = 1;
        label.use_markup = true;

        var main_grid = new Gtk.Grid ();
        main_grid.valign = Gtk.Align.CENTER;
        main_grid.add (label_icon);

        add (main_grid);
    }
}