public class Widgets.IconColorProject : Gtk.EventBox {
    public Objects.Project project { get; construct; }
    public int pixel_size { get; construct; }

    private Gtk.Grid widget_color;

    public IconColorProject (Objects.Project project, int pixel_size) {
        Object (
            project: project,
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

        var stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        stack.add_named (inbox_icon, "icon");
        stack.add_named (widget_color, "color");

        add (stack);
        update_request ();

        Timeout.add (stack.transition_duration, () => {
            stack.visible_child_name = project.inbox_project ? "icon" : "color";
            return GLib.Source.REMOVE;
        });
    }

    public void update_request () {
        Util.get_default ().set_widget_color (Util.get_default ().get_color (project.color), widget_color);
    }
}