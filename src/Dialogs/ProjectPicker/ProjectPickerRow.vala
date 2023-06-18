public class Dialogs.ProjectPicker.ProjectPickerRow : Gtk.ListBoxRow {
    public Objects.Project project { get; construct; }
    
    private Gtk.Label name_label;
    private Gtk.Revealer main_revealer;
    private Widgets.IconColorProject icon_project;

    public ProjectPickerRow (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        add_css_class ("selectable-item");
        add_css_class ("transition");

        icon_project = new Widgets.IconColorProject (21);
        icon_project.project = project;

        name_label = new Gtk.Label (null);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

        var selected_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("emblem-ok-symbolic"),
            pixel_size = 16,
            hexpand = true,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END,
            margin_end = 3
        };

        selected_icon.add_css_class ("color-primary");

        var selected_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE
        };

        selected_revealer.child = selected_icon;

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 3,
            margin_start = 3,
            margin_end = 3,
            margin_bottom = 3
        };
        content_box.append (icon_project);        
        content_box.append (name_label);
        content_box.append (selected_revealer);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };

        main_revealer.child = content_box;

        child = main_revealer;
        
        update_request ();

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        var select_gesture = new Gtk.GestureClick ();
        add_controller (select_gesture);

        select_gesture.pressed.connect (() => {
            Services.EventBus.get_default ().project_picker_changed (project.id);
        });

        Services.EventBus.get_default ().project_picker_changed.connect ((id) => {
            selected_revealer.reveal_child = project.id == id;
        });
    }

    public void update_request () {
        name_label.label = project.inbox_project ? _("Inbox") : project.name;
        icon_project.update_request ();
    }
}