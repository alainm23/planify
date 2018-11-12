public class Widgets.ProjectsList : Gtk.Grid {
    private Gtk.ListBox listbox;
    private Widgets.ItemRow inbox_item;
    private Widgets.ItemRow today_item;
    private Widgets.ItemRow tomorrow_item;
    private Gtk.Separator separator;

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

        inbox_item = new Widgets.ItemRow (_("Inbox"), "planner-inbox");
        inbox_item.number_label.label = Planner.database.get_inbox_number ();

        today_item = new Widgets.ItemRow (_("Today"), "planner-today-" + new GLib.DateTime.now_local ().get_day_of_month ().to_string ());
        today_item.number_label.label = Planner.database.get_today_number ();

        tomorrow_item = new Widgets.ItemRow (_("Tomorrow"), "planner-tomorrow");
        tomorrow_item.margin_bottom = 6;

        check_number_labels ();

        listbox = new Gtk.ListBox  ();
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.expand = true;

        var add_project_button = new Gtk.ToggleButton ();
        add_project_button.valign = Gtk.Align.CENTER;
        add_project_button.halign = Gtk.Align.CENTER;
        add_project_button.margin = 6;
        add_project_button.width_request = 48;
        add_project_button.get_style_context ().add_class ("button-circular");
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

        main_grid.add (listbox);

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
            listbox.invalidate_headers ();
        });

        listbox.row_selected.connect ((row) => {
            if (row.get_index () == 0 || row.get_index () == 1 || row.get_index () == 2) {
                on_selected_item ("item", row.get_index ());
            } else {
                var project = row as Widgets.ProjectRow;
                on_selected_item ("project", project.project.id);
            }
        });

        Planner.database.add_task_signal.connect (() => {
            inbox_item.number_label.label = Planner.database.get_inbox_number ();
            today_item.number_label.label = Planner.database.get_today_number ();

            check_number_labels ();
        });

        Planner.database.update_task_signal.connect (() => {
            inbox_item.number_label.label = Planner.database.get_inbox_number ();
            today_item.number_label.label = Planner.database.get_today_number ();

            check_number_labels ();
        });
    }

    private void check_number_labels () {
        if (int.parse (inbox_item.number_label.label) <= 0) {
            inbox_item.number_label.visible = false;
            inbox_item.number_label.no_show_all = true;
        } else {
            inbox_item.number_label.visible = true;
            inbox_item.number_label.no_show_all = false;
        }

        if (int.parse (today_item.number_label.label) < 0) {
            today_item.number_label.visible = false;
            today_item.number_label.no_show_all = true;
        } else {
            today_item.number_label.visible = true;
            today_item.number_label.no_show_all = false;
        }
    }

    public void update_project_list () {
        foreach (Gtk.Widget element in listbox.get_children ()) {
            listbox.remove (element);
        }

        var all_projects = new Gee.ArrayList<Objects.Project?> ();
        all_projects = Planner.database.get_all_projects ();

        foreach (var project in all_projects) {
            var row = new Widgets.ProjectRow (project);
            listbox.add (row);
        }

        listbox.insert (inbox_item, 0);
        listbox.insert (today_item, 1);
        listbox.insert (tomorrow_item, 2);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_top = 6;
        separator.margin_bottom = 6;

        var separator_row = new Gtk.ListBoxRow ();
        separator_row.selectable = false;
        separator_row.activatable = false;
        separator_row.add (separator);

        listbox.insert (separator_row, 3);

        listbox.show_all ();
    }
}
