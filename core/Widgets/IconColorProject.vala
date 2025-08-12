public class Widgets.IconColorProject : Adw.Bin {
    public Objects.Project project { get; set; }
    public int pixel_size { get; construct; }

    private Widgets.CircularProgressBar circular_progress_bar;
    public Gtk.Image inbox_icon;
    private Gtk.Label emoji_label;
    private Gtk.Stack color_emoji_stack;
    private Gtk.Stack stack;

    public IconColorProject (int pixel_size) {
        Object (
            pixel_size: pixel_size
        );
    }

    ~IconColorProject () {
        print ("Destroying Widgets.IconColorProject\n");
    }

    construct {
        circular_progress_bar = new Widgets.CircularProgressBar (pixel_size);

        emoji_label = new Gtk.Label (null) {
            halign = CENTER
        };

        color_emoji_stack = new Gtk.Stack () {
            transition_type = CROSSFADE
        };

        color_emoji_stack.add_named (circular_progress_bar, "color");
        color_emoji_stack.add_named (emoji_label, "emoji");

        inbox_icon = new Gtk.Image.from_icon_name ("mailbox-symbolic") {
            pixel_size = 16,
            valign = CENTER,
            halign = CENTER,
        };

        stack = new Gtk.Stack () {
            transition_type = CROSSFADE,
            vhomogeneous = false,
            hhomogeneous = false
        };

        stack.add_named (color_emoji_stack, "color-emoji");
        stack.add_named (inbox_icon, "inbox");

        child = stack;

        ulong signal_id = notify["project"].connect (() => {
            update_request ();
        });

        destroy.connect (() => {
            disconnect (signal_id);
        });
    }

    public void update_request () {
        stack.visible_child_name = project.is_inbox_project ? "inbox" : "color-emoji";
        color_emoji_stack.visible_child_name = project.icon_style == ProjectIconStyle.PROGRESS ? "color" : "emoji";
        circular_progress_bar.color = project.color;
        circular_progress_bar.percentage = project.percentage;
        emoji_label.label = project.emoji;
    }
}
