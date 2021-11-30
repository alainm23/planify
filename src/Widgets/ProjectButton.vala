public class Widgets.ProjectButton : Gtk.ToggleButton {
    public Objects.Item item { get; construct; }

    private Gtk.Label name_label;
    private Widgets.IconColorProject icon_project;
    
    public ProjectButton (Objects.Item item) {
        Object (
            item: item
        );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        get_style_context ().add_class ("small-label");

        icon_project = new Widgets.IconColorProject (item.project, 13);
        name_label = new Gtk.Label (null);

        var arrow_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("pan-end-symbolic"),
            pixel_size = 13
        };

        var projectbutton_grid = new Gtk.Grid () {
            column_spacing = 6
        };
        projectbutton_grid.add (icon_project);
        projectbutton_grid.add (name_label);
        projectbutton_grid.add (arrow_icon);

        add (projectbutton_grid);
        update_request ();

        item.project.updated.connect (() => {
            update_request ();
        });

        clicked.connect (() => {
            var dialog = new Dialogs.ProjectSelector.ProjectSelector (item);
            dialog.popup ();
        });
    }

    public void update_request () {
        name_label.label = item.project.name;
        icon_project.update_request ();
    }
}