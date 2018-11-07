public class Widgets.ProjectsList : Gtk.Grid {
    private Gtk.ListBox items_listbox;
    private Gtk.ListBox projects_listbox;

    public signal void on_selected_item (string type, int index);

    public ProjectsList () {
        Object (
            expand: true
        );
    }

    construct {
        get_style_context ().add_class ("welcome");
        get_style_context ().add_class ("view");
        orientation = Gtk.Orientation.VERTICAL;

        items_listbox = new Gtk.ListBox  ();
        items_listbox.activate_on_single_click = true;
        items_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        items_listbox.hexpand = true;

        var inbox_item = new Widgets.ItemRow (_("Inbox"), "planner-inbox");
        inbox_item.number_label.label = Planner.database.get_inbox_number ();

        var today_item = new Widgets.ItemRow (_("Today"), "planner-today-" + new GLib.DateTime.now_local ().get_day_of_month ().to_string ());
        var tomorrow_item = new Widgets.ItemRow (_("Tomorrow"), "planner-tomorrow");

        items_listbox.add (inbox_item);
        items_listbox.add (today_item);
        items_listbox.add (tomorrow_item);
        items_listbox.select_row (inbox_item);

        var separator_1 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator_1.margin_top = 6;
        separator_1.margin_bottom = 6;

        var separator_2 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator_2.margin_top = 12;
        separator_2.margin_bottom = 6;

        projects_listbox = new Gtk.ListBox  ();
        projects_listbox.activate_on_single_click = true;
        projects_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        projects_listbox.expand = true;

        var add_project_button = new Gtk.ToggleButton ();
        add_project_button.valign = Gtk.Align.CENTER;
        add_project_button.halign = Gtk.Align.CENTER;
        add_project_button.margin = 6;
        add_project_button.width_request = 48;
        add_project_button.get_style_context ().add_class ("button-circular");
        //add_project_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        add_project_button.tooltip_text = _("Add new project");
        add_project_button.add (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR));

        var settings_button = new Gtk.ToggleButton ();
        settings_button.add (new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.MENU));
        settings_button.tooltip_text = _("Settings");
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.halign = Gtk.Align.CENTER;
        settings_button.margin_end = 12;
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        settings_button.get_style_context ().add_class ("settings-button");

        var action_bar = new Gtk.ActionBar ();
        action_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        action_bar.get_style_context ().add_class ("planner-button-no-focus");
        action_bar.set_center_widget (add_project_button);
        action_bar.pack_end (settings_button);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.valign = Gtk.Align.START;
        main_grid.expand = true;

        main_grid.add (items_listbox);
        main_grid.add (separator_2);
        main_grid.add (projects_listbox);

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.add (main_grid);

        add (scrolled_window);
        add (action_bar);

        add_project_button.grab_focus ();

        update_project_list ();

        // Events
        var add_popover = new Widgets.Popovers.AddProject (add_project_button);

        add_project_button.toggled.connect (() => {
          if (add_project_button.active) {
            add_popover.show_all ();
          }
        });

        add_popover.closed.connect (() => {
            add_project_button.active = false;
        });

        add_popover.on_add_project_signal.connect (() => {
            update_project_list ();
        });

        var item_row = new Gtk.ListBoxRow ();
        var project_row = new Gtk.ListBoxRow ();

        items_listbox.row_selected.connect ((item_row) => {
            on_selected_item ("item", item_row.get_index ());

            projects_listbox.unselect_all ();
            items_listbox.select_row (item_row);
        });

        projects_listbox.row_selected.connect ((project_row) => {
            //on_selected_item ("project", project_row.get_index ());
            items_listbox.unselect_all ();
            projects_listbox.select_row (project_row);
        });

        Planner.database.add_inbox_task_signal.connect (() => {
            inbox_item.number_label.label = Planner.database.get_inbox_number ();
        });

        Planner.database.update_inbox_task_signal.connect (() => {
            inbox_item.number_label.label = Planner.database.get_inbox_number ();
        });
    }

    public void update_project_list () {
        foreach (Gtk.Widget element in projects_listbox.get_children ()) {
            projects_listbox.remove (element);
        }

        var all_projects = new Gee.ArrayList<Objects.Project?> ();
        all_projects = Planner.database.get_all_projects ();

        foreach (var project in all_projects) {
            var row = new Widgets.ProjectRow (project);
            projects_listbox.add (row);
        }

        show_all ();
    }
}
