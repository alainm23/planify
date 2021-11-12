public class Widgets.ProjectHeader : Hdy.HeaderBar {
    public Objects.Project project { get; set; }
    
    private Gtk.SearchEntry search_entry;

    construct {
        var sidebar_image = new Gtk.Image () {
            gicon = new ThemedIcon ("view-sidebar-start-symbolic"),
            pixel_size = 16
        };
        
        var sidebar_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        sidebar_button.add (sidebar_image);

        unowned Gtk.StyleContext sidebar_button_context = sidebar_button.get_style_context ();
        sidebar_button_context.add_class (Gtk.STYLE_CLASS_FLAT);

        var project_progress = new Widgets.ProjectProgress (16);
        project_progress.enable_subprojects = true;
        project_progress.valign = Gtk.Align.CENTER;
        project_progress.halign = Gtk.Align.CENTER;
        
        var name_label = new Gtk.Label (null);
        name_label.valign = Gtk.Align.CENTER;

        unowned Gtk.StyleContext name_label_context = name_label.get_style_context ();
        name_label_context.add_class ("h4");
        name_label_context.add_class ("opacity-1");

        var project_grid = new Gtk.Grid () {
            column_spacing = 6,
            valign = Gtk.Align.CENTER
        };
        project_grid.add (project_progress);
        project_grid.add (name_label);

        var start_grid = new Gtk.Grid () {
            column_spacing = 6
        };

        start_grid.add (sidebar_button);
        // start_grid.add (project_grid);

        search_entry = new Gtk.SearchEntry ();

        unowned Gtk.StyleContext search_entry_context = search_entry.get_style_context ();
        search_entry_context.add_class ("border-radius-6");

        var end_grid = new Gtk.Grid () {
            column_spacing = 6
        };

        end_grid.add (search_entry);

        pack_start (start_grid);
        // custom_title = project_grid;
        // pack_end (end_grid);

        notify["project"].connect (() => {
            project_progress.progress_fill_color = Util.get_default ().get_color (project.color);
            name_label.label = project.name;
        });

        sidebar_button.clicked.connect (() => {
            Planner.settings.set_boolean ("slim-mode", !Planner.settings.get_boolean ("slim-mode"));
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "slim-mode") {
                if (Planner.settings.get_boolean ("slim-mode")) {
                    sidebar_image.gicon = new ThemedIcon ("view-sidebar-end-symbolic");
                } else {
                    sidebar_image.gicon = new ThemedIcon ("view-sidebar-start-symbolic");
                }   
            }
        });
    }
}