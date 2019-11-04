public class Widgets.MagicButton : Gtk.Revealer {
    public Gtk.Button button;

    public signal void clicked ();

    private const Gtk.TargetEntry[] targetEntries = {
        {"MAGICBUTTON", Gtk.TargetFlags.SAME_APP, 0}
    };
 
    construct {
        tooltip_text = _("Add task");
        transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        reveal_child = true;
        margin_bottom = 12;
        margin_end = 12;
        valign = Gtk.Align.END;
        halign = Gtk.Align.END;

        button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        button.height_request = 32;
        button.width_request = 32;
        button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        button.get_style_context ().add_class ("magic-button");
        
        add (button);

        build_drag_and_drop ();

        button.clicked.connect (() => {
            clicked ();
        });
    }

    private void build_drag_and_drop () {
        Gtk.drag_source_set (button, Gdk.ModifierType.BUTTON1_MASK, targetEntries, Gdk.DragAction.MOVE);
        button.drag_data_get.connect (on_drag_data_get);
        button.drag_begin.connect (on_drag_begin);
        button.drag_end.connect (on_drag_end);
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var magic_button = (Gtk.Button) widget;

        Gtk.Allocation alloc;
        magic_button.get_allocation (out alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr = new Cairo.Context (surface);
        cr.set_source_rgba (255, 255, 255, 0);
        cr.set_line_width (1);

        cr.move_to (0, 0);
        cr.line_to (alloc.width, 0);
        cr.line_to (alloc.width, alloc.height);
        cr.line_to (0, alloc.height);
        cr.line_to (0, 0);
        cr.stroke ();
  
        cr.set_source_rgba (255, 255, 255, 0);
        cr.rectangle (0, 0, alloc.width, alloc.height);
        cr.fill ();

        magic_button.draw (cr);

        Gtk.drag_set_icon_surface (context, surface);
        reveal_child = false;

        Application.utils.drag_magic_button_activated (true);
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context, Gtk.SelectionData selection_data, uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (Gtk.Button))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("MAGICBUTTON"), 32, data
        );
    }

    public void on_drag_end (Gdk.DragContext context) {
        reveal_child = true;
        Application.utils.drag_magic_button_activated (false);
    }
}