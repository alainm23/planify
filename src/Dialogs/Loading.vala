public class Dialogs.Loading : Gtk.Dialog {
    public Loading (MainWindow parent) {
        Object (
            transient_for: parent,
            deletable: false,
            resizable: false,
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            modal: true
        );
    }

    construct {
        var spinner = new Gtk.Spinner ();
        spinner.height_request = 32;
        spinner.width_request = 32;
        spinner.active = true;
        spinner.start ();
        
        var message_label = new Gtk.Label (_("Loading ..."));
        message_label.get_style_context ().add_class ("h2");

        var main_grid = new Gtk.Grid ();
        main_grid.margin_top = 6;
        main_grid.margin_bottom = 12;
        main_grid.margin_start = 24;
        main_grid.margin_end = 24;
        main_grid.column_spacing = 24;
        main_grid.add (spinner);
        main_grid.add (message_label);

        ((Gtk.Container) get_content_area ()).add (main_grid);
    }
}