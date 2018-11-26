public class Widgets.Popovers.MovePopover : Gtk.Popover {
    private Gtk.ListBox projects_listbox;

    public signal void on_selected_project (bool is_inbox, Objects.Project project);
    public MovePopover (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.TOP
        );
    }

    construct {
        var title_label = new Gtk.Label ("<small>%s</small>".printf (_("Move")));
        title_label.use_markup = true;
        title_label.hexpand = true;
        title_label.halign = Gtk.Align.CENTER;
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        projects_listbox = new Gtk.ListBox  ();
        projects_listbox.activate_on_single_click = true;
        projects_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        projects_listbox.expand = true;
        projects_listbox.set_header_func (update_headers);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.height_request = 200;
        scrolled.add (projects_listbox);

        var main_grid = new Gtk.Grid ();
        main_grid.expand = true;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.width_request = 250;

        main_grid.add (title_label);
        main_grid.add (scrolled);

        add (main_grid);
        update_project_list ();

        projects_listbox.row_activated.connect ((row) => {
            if (row.get_index () <= 0) {
                // To Inbox
                on_selected_project (true, new Objects.Project ());

                hide ();
            } else {
                // To Project
                var project = row as Widgets.ProjectRow;
                on_selected_project (false, project.project);

                hide ();
            }
        });
    }

    public void update_project_list () {
        foreach (Gtk.Widget element in projects_listbox.get_children ()) {
            projects_listbox.remove (element);
        }

        var all_projects = new Gee.ArrayList<Objects.Project?> ();
        all_projects = Application.database.get_all_projects ();

        foreach (var project in all_projects) {
            var row = new Widgets.ProjectRow (project);
            row.margin = 0;
            row.menu_open = true; // To disable the setting button

            projects_listbox.add (row);
        }

        var inbox_icon = new Gtk.Image.from_icon_name ("planner-inbox", Gtk.IconSize.LARGE_TOOLBAR);
        var inbox_label = new Gtk.Label ("<b>%s</b>".printf(_("Inbox")));
        inbox_label.ellipsize = Pango.EllipsizeMode.END;
        inbox_label.valign = Gtk.Align.CENTER;
        inbox_label.halign = Gtk.Align.START;
        inbox_label.use_markup = true;

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.row_spacing = 3;
        grid.margin = 6;

        grid.add (inbox_icon);
        grid.add (inbox_label);

        var inbox_row = new Gtk.ListBoxRow ();
        inbox_row.get_style_context ().add_class ("item-row");
        inbox_row.add (grid);

        projects_listbox.insert (inbox_row, 0);
        projects_listbox.show_all ();

        projects_listbox.invalidate_headers ();
    }

    private void update_headers (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
        if (row == projects_listbox.get_row_at_index (1)) {
            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            separator.margin_top = 6;
            separator.margin_bottom = 6;
            row.set_header (separator);
        }
    }
}
