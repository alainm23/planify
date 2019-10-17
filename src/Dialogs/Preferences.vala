public class Dialogs.Preferences : Gtk.Dialog {
    public Preferences () {
        Object (
            transient_for: Application.instance.main_window,
            deletable: true, 
            resizable: true,
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            modal: true
        );
    }
    
    construct { 
        height_request = 700;
        width_request = 600;
        //get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);

        
    }
}