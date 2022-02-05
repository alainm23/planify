public class Widgets.IconColorProject : Gtk.EventBox {
    public Objects.Project project { get; set; }
    public int pixel_size { get; construct; }

    private Gtk.Grid widget_color;
    private Gtk.Stack stack;

    public IconColorProject (int pixel_size) {
        Object (
            pixel_size: pixel_size
        );
    }

    construct {
        var inbox_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("planner-inbox"),
            pixel_size = pixel_size,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER
        };

        widget_color = new Gtk.Grid () {
            height_request = pixel_size - 3,
            width_request = pixel_size - 3,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER
        };

        unowned Gtk.StyleContext widget_color_context = widget_color.get_style_context ();
        widget_color_context.add_class ("label-color");

        stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        stack.add_named (inbox_icon, "icon");
        stack.add_named (widget_color, "color");

        add (stack);

        notify["project"].connect (() => {
            update_request ();
        });
    }

    public void update_request () {
        Util.get_default ().set_widget_color (Util.get_default ().get_color (project.color), widget_color);
        Timeout.add (stack.transition_duration, () => {
            stack.visible_child_name = project.inbox_project ? "icon" : "color";
            return GLib.Source.REMOVE;
        });
    }
}
