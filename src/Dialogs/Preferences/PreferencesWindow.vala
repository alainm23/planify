public class Dialogs.Preferences.PreferencesWindow : Adw.PreferencesWindow {
    
    public PreferencesWindow () {
        Object (
            transient_for: (Gtk.Window) Planner.instance.main_window,
            deletable: true,
            destroy_with_parent: true,
            modal: true,
            height_request: 500,
            width_request: 360
        );
    }

    construct {
        add (get_general_page ());
        add (get_calendar_event_page ());
    }

    private Adw.PreferencesPage get_general_page () {
        var page = new Adw.PreferencesPage ();
        page.title = _("General");
        page.name = "general";
        page.icon_name = "applications-system-symbolic";

        build_appearance (page);

        var general_group = new Adw.PreferencesGroup ();
        general_group.title = _("General");

        var sort_projects_model = new Gtk.StringList (null);
        sort_projects_model.append (_("Alphabetically"));
        sort_projects_model.append (_("Custom sort order"));

        var sort_projects_row = new Adw.ComboRow ();
        sort_projects_row.title = _("Sort projects");
        sort_projects_row.model = sort_projects_model;
        sort_projects_row.selected = Planner.settings.get_enum ("projects-sort-by");

        general_group.add (sort_projects_row);

        var sort_order_projects_model = new Gtk.StringList (null);
        sort_order_projects_model.append (_("Ascending"));
        sort_order_projects_model.append (_("Descending"));

        var sort_order_projects_row = new Adw.ComboRow ();
        sort_order_projects_row.title = _("Sort by");
        sort_order_projects_row.model = sort_order_projects_model;
        sort_order_projects_row.selected = Planner.settings.get_enum ("projects-ordered");

        general_group.add (sort_order_projects_row);

        var de_group = new Adw.PreferencesGroup ();
        de_group.title = _("DE Integration");

        var run_background_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER,
            active = Planner.settings.get_boolean ("run-in-background")
        };

        var run_background_row = new Adw.ActionRow ();
        run_background_row.title = _("Run in background");
        run_background_row.set_activatable_widget (run_background_switch);
        run_background_row.add_suffix (run_background_switch);

        de_group.add (run_background_row);

        var datetime_group = new Adw.PreferencesGroup ();
        datetime_group.title = _("Date and Time");

        var clock_format_model = new Gtk.StringList (null);
        clock_format_model.append (_("24h"));
        clock_format_model.append (_("12h"));

        var clock_format_row = new Adw.ComboRow ();
        clock_format_row.title = _("Clock Format");
        clock_format_row.model = clock_format_model;
        clock_format_row.selected = Planner.settings.get_enum ("clock-format");

        datetime_group.add (clock_format_row);

        var start_week_model = new Gtk.StringList (null);
        start_week_model.append (_("Sunday"));
        start_week_model.append (_("Monday"));

        var start_week_row = new Adw.ComboRow ();
        start_week_row.title = _("Start of the week");
        start_week_row.model = start_week_model;
        start_week_row.selected = Planner.settings.get_enum ("start-week");

        datetime_group.add (start_week_row);

        var tasks_group = new Adw.PreferencesGroup ();
        tasks_group.title = _("Task settings");

        var complete_tasks_model = new Gtk.StringList (null);
        complete_tasks_model.append (_("Instantly"));
        complete_tasks_model.append (_("Wait 2500 milliseconds"));

        var complete_tasks_row = new Adw.ComboRow ();
        complete_tasks_row.title = _("Complete task");
        complete_tasks_row.model = complete_tasks_model;
        complete_tasks_row.selected = Planner.settings.get_enum ("complete-task");

        tasks_group.add (complete_tasks_row);

        var default_priority_model = new Gtk.StringList (null);
        default_priority_model.append (_("Priority 1"));
        default_priority_model.append (_("Priority 2"));
        default_priority_model.append (_("Priority 3"));
        default_priority_model.append (_("None"));

        var default_priority_row = new Adw.ComboRow ();
        default_priority_row.title = _("Default priority");
        default_priority_row.model = default_priority_model;
        default_priority_row.selected = Planner.settings.get_enum ("default-priority");

        tasks_group.add (default_priority_row);

        var description_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER,
            active = Planner.settings.get_boolean ("description-preview")
        };

        var description_row = new Adw.ActionRow ();
        description_row.title = _("Description preview");
        description_row.set_activatable_widget (description_switch);
        description_row.add_suffix (description_switch);

        tasks_group.add (description_row);

        var underline_completed_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER,
            active = Planner.settings.get_boolean ("underline-completed-tasks")
        };

        var underline_completed_row = new Adw.ActionRow ();
        underline_completed_row.title = _("Underline completed tasks");
        underline_completed_row.set_activatable_widget (underline_completed_switch);
        underline_completed_row.add_suffix (underline_completed_switch);

        tasks_group.add (underline_completed_row);

        page.add (general_group);
        page.add (de_group);
        page.add (datetime_group);
        page.add (tasks_group);

        sort_projects_row.notify["selected"].connect (() => {
            Planner.settings.set_enum ("projects-sort-by", (int) sort_projects_row.selected);
        });

        sort_order_projects_row.notify["selected"].connect (() => {
            Planner.settings.set_enum ("projects-ordered", (int) sort_order_projects_row.selected);
        });

        run_background_switch.notify["active"].connect (() => {
            Planner.settings.set_boolean ("run-in-background", run_background_switch.active);
        });

        clock_format_row.notify["selected"].connect (() => {
            Planner.settings.set_enum ("clock-format", (int) clock_format_row.selected);
        });
        
        start_week_row.notify["selected"].connect (() => {
            Planner.settings.set_enum ("start-week", (int) start_week_row.selected);
        });
        
        complete_tasks_row.notify["selected"].connect (() => {
            Planner.settings.set_enum ("complete-task", (int) complete_tasks_row.selected);
        });

        default_priority_row.notify["selected"].connect (() => {
            Planner.settings.set_enum ("default-priority", (int) default_priority_row.selected);
        });
        
        description_switch.notify["active"].connect (() => {
            Planner.settings.set_boolean ("description-preview", description_switch.active);
        });
        
        underline_completed_switch.notify["active"].connect (() => {
            Planner.settings.set_boolean ("underline-completed-tasks", underline_completed_switch.active);
        });

        return page;
    }

    private void build_appearance (Adw.PreferencesPage page) {
        var appearance_group = new Adw.PreferencesGroup ();
        appearance_group.title = _("Appearance");

        var system_appearance_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER,
            active = Planner.settings.get_boolean ("system-appearance")
        };

        var system_appearance_row = new Adw.ActionRow ();
        system_appearance_row.title = _("Use system settings");
        system_appearance_row.set_activatable_widget (system_appearance_switch);
        system_appearance_row.add_suffix (system_appearance_switch);

        appearance_group.add (system_appearance_row);

        var dark_mode_group = new Adw.PreferencesGroup () {
            visible = !Planner.settings.get_boolean ("system-appearance")
        };

        var dark_mode_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER,
            active = Planner.settings.get_boolean ("dark-mode")
        };

        var dark_mode_row = new Adw.ActionRow ();
        dark_mode_row.title = _("Dark mode");
        dark_mode_row.set_activatable_widget (dark_mode_switch);
        dark_mode_row.add_suffix (dark_mode_switch);

        dark_mode_group.add (dark_mode_row);

        var light_check = new Gtk.CheckButton ();

        var dark_check = new Gtk.CheckButton ();
        dark_check.set_group (light_check);

        var dark_item_row = new Adw.ActionRow ();
        dark_item_row.title = _("Dark");
        dark_item_row.set_activatable_widget (dark_check);
        dark_item_row.add_suffix (dark_check);

        var dark_blue_check = new Gtk.CheckButton ();
        dark_blue_check.set_group (light_check);

        var dark_blue_item_row = new Adw.ActionRow ();
        dark_blue_item_row.title = _("Dark Blue");
        dark_blue_item_row.set_activatable_widget (dark_blue_check);
        dark_blue_item_row.add_suffix (dark_blue_check);

        bool dark_mode = Planner.settings.get_boolean ("dark-mode");
        if (Planner.settings.get_boolean ("system-appearance")) {
            dark_mode = Granite.Settings.get_default ().prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        }

        var dark_modes_group = new Adw.PreferencesGroup () {
            visible = dark_mode
        };

        dark_modes_group.add (dark_item_row);
        dark_modes_group.add (dark_blue_item_row);

        int appearance = Planner.settings.get_enum ("appearance");
        if (appearance == 0) {
            light_check.active = true;
        } else if (appearance == 1) {
            dark_check.active = true;
        } else if (appearance == 2) {
            dark_blue_check.active = true;
        }

        system_appearance_switch.notify["active"].connect (() => {
            Planner.settings.set_boolean ("system-appearance", system_appearance_switch.active);
        });

        dark_mode_switch.notify["active"].connect (() => {
            Planner.settings.set_boolean ("dark-mode", dark_mode_switch.active);
        });
        
        dark_check.toggled.connect (() => {
            Planner.settings.set_enum ("appearance", 1);
        });
        
        dark_blue_check.toggled.connect (() => {
            Planner.settings.set_enum ("appearance", 2);
        });

        dark_item_row.activated.connect (() => {
            dark_check.active = true;
        });

        dark_blue_item_row.activated.connect (() => {
            dark_blue_check.active = true;
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "system-appearance") {
                system_appearance_switch.active = Planner.settings.get_boolean ("system-appearance");
                dark_mode_group.visible = !Planner.settings.get_boolean ("system-appearance");

                dark_mode = Planner.settings.get_boolean ("dark-mode");
                if (Planner.settings.get_boolean ("system-appearance")) {
                    dark_mode = Granite.Settings.get_default ().prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
                }
                
                dark_modes_group.visible = dark_mode;
            } else if (key == "dark-mode") {
                dark_mode_switch.active = Planner.settings.get_boolean ("dark-mode");
                
                dark_mode = Planner.settings.get_boolean ("dark-mode");
                if (Planner.settings.get_boolean ("system-appearance")) {
                    dark_mode = Granite.Settings.get_default ().prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
                }

                dark_modes_group.visible = dark_mode;
            }
        });

        page.add (appearance_group);
        page.add (dark_mode_group);
        page.add (dark_modes_group);
    }

    private Adw.PreferencesPage get_calendar_event_page () {
        var page = new Adw.PreferencesPage ();
        page.title = _("Calendar Events");
        page.name = "calendar-events";
        page.icon_name = "x-office-calendar-symbolic";

        return page;
    }
}
