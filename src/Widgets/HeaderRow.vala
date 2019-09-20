public class Widgets.HeaderRow : Gtk.ListBoxRow {
    private Gtk.Button hidden_button;
    private Gtk.Label name_label;
    private Gtk.Entry name_entry;
    private Gtk.Stack name_stack;

    private Gtk.ListBox listbox;
    construct {
        can_focus = false;
        get_style_context ().add_class ("header-row");

        hidden_button = new Gtk.Button.from_icon_name ("pan-down-symbolic", Gtk.IconSize.MENU);
        hidden_button.can_focus = false;
        hidden_button.margin_start = 7;
        hidden_button.get_style_context ().remove_class ("button");
        hidden_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hidden_button.get_style_context ().add_class ("hidden-button");

        name_label =  new Gtk.Label ("Diseño");
        name_label.halign = Gtk.Align.START;
        name_label.valign = Gtk.Align.CENTER;
        name_label.get_style_context ().add_class ("h3");
        name_label.get_style_context ().add_class ("font-bold");
        name_label.set_ellipsize (Pango.EllipsizeMode.END);

        name_entry = new Gtk.Entry ();
        name_entry.text = "Diseño";
        name_entry.valign = Gtk.Align.CENTER;
        name_entry.placeholder_text = _("Header name");
        name_entry.get_style_context ().add_class ("h3");
        name_entry.get_style_context ().add_class ("font-bold");
        name_entry.get_style_context ().add_class ("new-item-entry");
        name_entry.get_style_context ().add_class ("welcome");
        name_entry.get_style_context ().add_class ("flat");

        name_stack = new Gtk.Stack ();
        name_stack.valign = Gtk.Align.CENTER;
        name_stack.transition_type = Gtk.StackTransitionType.NONE;
        name_stack.add_named (name_label, "name_label");
        name_stack.add_named (name_entry, "name_entry");
        
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.pack_start (hidden_button, false, false, 0);
        box.pack_start (name_stack, false, false, 0);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_start = 36;

        listbox = new Gtk.ListBox  ();
        listbox.valign = Gtk.Align.START;
        listbox.get_style_context ().add_class ("welcome");
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        var new_item_widget = new Widgets.NewItem ((int64) 848494984999);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        //main_box.margin_start = 4;
        main_box.margin_end = 24;
        main_box.margin_top = 12;
        main_box.hexpand = true;
        main_box.pack_start (box, false, false, 0);
        main_box.pack_start (separator, false, false, 0);
        main_box.pack_start (listbox, false, false, 0);
        main_box.pack_start (new_item_widget, false, false, 0);

        add (main_box);
    }
}