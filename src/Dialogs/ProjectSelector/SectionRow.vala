public class Dialogs.ProjectSelector.SectionRow : Gtk.ListBoxRow {
    public Objects.Section section { get; construct; }

    private Gtk.Label name_label;
    private Gtk.Revealer main_revealer;

    public SectionRow (Objects.Section section) {
        Object (
            section: section
        );
    }

    construct {
        unowned Gtk.StyleContext style_context = get_style_context ();
        style_context.add_class ("no-selected");

        var arrow_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("pan-end-symbolic"),
            pixel_size = 16
        };

        unowned Gtk.StyleContext arrow_icon_context = arrow_icon.get_style_context ();
        arrow_icon_context.add_class ("dim-label");

        name_label = new Gtk.Label (null);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

        var selected_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("emblem-ok-symbolic"),
            pixel_size = 16,
            hexpand = true,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END
        };

        unowned Gtk.StyleContext selected_icon_context = selected_icon.get_style_context ();
        selected_icon_context.add_class ("primary-color");

        var selected_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE
        };
        selected_revealer.add (selected_icon);

        var sectionrow_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin = 6
        };
        sectionrow_grid.add (arrow_icon);
        sectionrow_grid.add (name_label);
        sectionrow_grid.add (selected_revealer);

        var sectionrow_eventbox = new Gtk.EventBox ();
        sectionrow_eventbox.get_style_context ().add_class ("transition");
        sectionrow_eventbox.add (sectionrow_grid);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.add (sectionrow_eventbox);

        add (main_revealer);

        update_request ();

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        sectionrow_eventbox.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                Planner.event_bus.project_selector_selected (section.id);
            }

            return Gdk.EVENT_PROPAGATE;
        });

        Planner.event_bus.project_selector_selected.connect ((id) => {
            selected_revealer.reveal_child = section.id == id;
        });
    }

    public void update_request () {
        name_label.label = section.name;
    }
}