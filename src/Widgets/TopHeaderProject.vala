public class Widgets.TopHeaderProject : Gtk.EventBox {
    public Objects.Project project { get; construct; }

    public TopHeaderProject (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        var project_progress = new Widgets.ProjectProgress (18) {
            enable_subprojects = true,
            valign = Gtk.Align.START,
            halign = Gtk.Align.CENTER,
            progress_fill_color = Util.get_default ().get_color (project.color)
        };

        var name_editable = new Widgets.EditableLabel ("title");
        name_editable.text = project.name;
        name_editable.valign = Gtk.Align.CENTER;

        name_editable.changed.connect (() => {
            project.name = name_editable.text;
            project.update ();
        });

        var projectrow_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin_start = 24,
            margin_top = 6,
            valign = Gtk.Align.START
        };
        projectrow_grid.add (project_progress);
        projectrow_grid.add (name_editable);

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            expand = true
        };
        main_grid.add (projectrow_grid);

        add (main_grid);
    }
}