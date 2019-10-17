public class Widgets.Popovers.ProjectSettings : Gtk.Popover {
    public Objects.Project project { get; set; }

    construct {
        var finalize_menu = new Widgets.ModelButton ("Mark as Completed", "emblem-default-symbolic");    
        var edit_menu = new Widgets.ModelButton ("Edit project", "edit-symbolic");    
        var export_menu = new Widgets.ModelButton ("Export", "document-export-symbolic");      
        var share_menu = new Widgets.ModelButton ("Share project", "emblem-shared-symbolic");    
        var delete_menu = new Widgets.ModelButton ("Delete project", "edit-delete-symbolic");

        var separator_01 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator_01.margin_top = 3;
        separator_01.margin_bottom = 3;

        var separator_02 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator_02.margin_top = 3;
        separator_02.margin_bottom = 3;

        var main_grid = new Gtk.Grid ();
        main_grid.width_request = 200;
        main_grid.margin_top = 3;
        main_grid.margin_bottom = 3;
        main_grid.expand = true;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (finalize_menu);
        main_grid.add (edit_menu);
        main_grid.add (separator_01);
        main_grid.add (export_menu);
        main_grid.add (share_menu);
        main_grid.add (separator_02);
        main_grid.add (delete_menu);
        main_grid.show_all ();

        add (main_grid);

        notify["project"].connect (() => {
            if (project != null) {

            }
        });
    }
}