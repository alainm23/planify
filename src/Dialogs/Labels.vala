public class Dialogs.Labels : Gtk.Dialog {
    private Gtk.ListBox listbox;
    public Labels () {
        Object (
            transient_for: Application.instance.main_window,
            deletable: false, 
            resizable: true,
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            modal: false
        );
    }
    
    construct { 
        height_request = 525;
        width_request = 475;
        get_style_context ().add_class ("planner-dialog");

        listbox = new Gtk.ListBox ();
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.expand = true;
        listbox.get_style_context ().add_class ("background");
        
        var listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        listbox_scrolled.expand = true;
        listbox_scrolled.add (listbox);

        var add_icon = new Gtk.Image ();
        add_icon.valign = Gtk.Align.CENTER;
        add_icon.gicon = new ThemedIcon ("list-add-symbolic");
        add_icon.pixel_size = 16;

        var add_button = new Gtk.Button ();
        add_button.image = add_icon;
        add_button.valign = Gtk.Align.CENTER;
        add_button.halign = Gtk.Align.START;
        add_button.always_show_image = true;
        add_button.can_focus = false;
        add_button.label = _("Add Label");
        add_button.get_style_context ().add_class ("flat");
        add_button.get_style_context ().add_class ("font-bold");
        add_button.get_style_context ().add_class ("add-button");

        var close_button = new Gtk.Button.with_label (_("Close"));
        close_button.margin_bottom = 6;
        close_button.margin_end = 6;
        close_button.valign = Gtk.Align.CENTER;
        close_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        action_box.pack_start (add_button, false, false, 0);
        action_box.pack_end (close_button, false, false, 0);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.expand = true;
        box.pack_start (listbox_scrolled, true, true, 0);
        box.pack_end (action_box, false, false, 0);

        add_all_labels ();

        get_content_area ().pack_start (box, true, true, 0);
        get_action_area ().visible = false;
        get_action_area ().no_show_all = true;

        add_button.clicked.connect (() => {
            var label = new Objects.Label ();
            Application.database.insert_label (label);
        }); 

        close_button.clicked.connect (() => {
            destroy ();
        }); 

        Application.database.label_added.connect ((label) => {
            var row = new Widgets.LabelRow (label);
            
            listbox.add (row);
            listbox.show_all ();

            row.name_entry.grab_focus ();
        });
    }
    
    public void add_all_labels ()  {           
        foreach (Objects.Label label in Application.database.get_all_labels ()) {
            var row = new Widgets.LabelRow (label);
            listbox.add (row);
        }

        listbox.show_all ();
    }
}