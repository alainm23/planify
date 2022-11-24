public class Widgets.HeaderProject : Gtk.Grid {
    public Objects.Project project { get; construct; }

    public HeaderProject (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        var circular_progress_bar = new Widgets.CircularProgressBar (12);
        circular_progress_bar.percentage = 0.64;
        circular_progress_bar.color = project.color;

        var emoji_label = new Gtk.Label (project.emoji) {
            halign = Gtk.Align.CENTER
        };
        emoji_label.get_style_context ().add_class ("header-title");

        var progress_emoji_stack = new Gtk.Stack ();
        progress_emoji_stack.add_named (circular_progress_bar, "progress");
        progress_emoji_stack.add_named (emoji_label, "label");

        var inbox_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("planner-inbox"),
            pixel_size = 24
        };

        var icon_progress_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        icon_progress_stack.add_named (progress_emoji_stack, "color");
        icon_progress_stack.add_named (inbox_icon, "icon");

        var name_editable = new Widgets.EditableLabel () {
            valign = Gtk.Align.CENTER,
            editable = !project.inbox_project
        };

        name_editable.add_style ("header-title");
        name_editable.text = project.inbox_project ? _("Inbox") : project.name;

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            valign = Gtk.Align.START,
            hexpand = true
        };

        content_box.append (icon_progress_stack);
        content_box.append (name_editable);

        attach (content_box, 0, 0);

        Timeout.add (icon_progress_stack.transition_duration, () => {
            icon_progress_stack.visible_child_name = project.inbox_project ? "icon" : "color";
            
            if (project.icon_style == ProjectIconStyle.PROGRESS) {
                progress_emoji_stack.visible_child_name = "progress";
            } else {
                progress_emoji_stack.visible_child_name = "label";
            }

            return GLib.Source.REMOVE;
        });

        name_editable.changed.connect (() => {
            project.name = name_editable.text;
            project.update ();
        });
    }
}