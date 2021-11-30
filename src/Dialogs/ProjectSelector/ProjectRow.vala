public class Dialogs.ProjectSelector.ProjectRow : Gtk.ListBoxRow {
    public Objects.Project project { get; construct; }
    public bool sections { get; construct; }
    
    private Gtk.Label name_label;
    private Gtk.Revealer main_revealer;
    private Gtk.ListBox listbox;
    private Widgets.IconColorProject icon_project;

    public ProjectRow (Objects.Project project, bool sections = true) {
        Object (
            project: project,
            sections: sections
        );
    }

    construct {
        unowned Gtk.StyleContext style_context = get_style_context ();
        style_context.add_class ("no-selected");

        icon_project = new Widgets.IconColorProject (project, 16);

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
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
        };
        selected_revealer.add (selected_icon);

        var projectrow_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin = 6
        };

        projectrow_grid.add (icon_project);        
        projectrow_grid.add (name_label);
        projectrow_grid.add (selected_revealer);

        var projectrow_eventbox = new Gtk.EventBox ();
        projectrow_eventbox.get_style_context ().add_class ("transition");
        projectrow_eventbox.add (projectrow_grid);

        listbox = new Gtk.ListBox () {
            hexpand = true
        };
        
        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("listbox-separator-3");
        listbox_context.add_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin_start = 12
        };

        listbox_grid.add (listbox);

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };
        main_grid.add (projectrow_eventbox);
        main_grid.add (listbox_grid);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.add (main_grid);

        add (main_revealer);

        update_request ();

        if (sections) {
            add_items ();
        }

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        projectrow_eventbox.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                Planner.event_bus.project_selector_selected (project.id);
            }

            return Gdk.EVENT_PROPAGATE;
        });

        Planner.event_bus.project_selector_selected.connect ((id) => {
            selected_revealer.reveal_child = project.id == id;
        });
    }

    public void update_request () {
        name_label.label = project.inbox_project ? _("Inbox") : project.name;
        icon_project.update_request ();
    }

    private void add_items () {
        foreach (Objects.Section section in project.sections) {
            var row = new Dialogs.ProjectSelector.SectionRow (section);
            listbox.add (row);
            listbox.show_all ();
        }
    }
}