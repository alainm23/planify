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

        var general_group = new Adw.PreferencesGroup ();
        general_group.title = _("General");

        var sort_projects_model = new Gtk.StringList (null);
        sort_projects_model.append (_("Alphabetically"));
        sort_projects_model.append (_("Custom sort order"));

        var sort_projects_row = new Adw.ComboRow ();
        sort_projects_row.title = _("Sort projects");
        sort_projects_row.model = sort_projects_model;

        general_group.add (sort_projects_row);

        var sort_order_projects_model = new Gtk.StringList (null);
        sort_order_projects_model.append (_("Ascending"));
        sort_order_projects_model.append (_("Descending"));

        var sort_order_projects_row = new Adw.ComboRow ();
        sort_order_projects_row.title = _("Sort by");
        sort_order_projects_row.model = sort_order_projects_model;

        general_group.add (sort_order_projects_row);

        var de_group = new Adw.PreferencesGroup ();
        de_group.title = _("DE Integration");

        var run_background_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER
        };

        var run_background_row = new Adw.ActionRow ();
        run_background_row.title = _("Run in background");

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

        datetime_group.add (clock_format_row);

        var start_week_model = new Gtk.StringList (null);
        start_week_model.append (_("Sunday"));
        start_week_model.append (_("Monday"));

        var start_week_row = new Adw.ComboRow ();
        start_week_row.title = _("Start of the week");
        start_week_row.model = start_week_model;

        datetime_group.add (start_week_row);

        var tasks_group = new Adw.PreferencesGroup ();
        tasks_group.title = _("Task settings");

        var complete_tasks_model = new Gtk.StringList (null);
        complete_tasks_model.append (_("Instantly"));
        complete_tasks_model.append (_("Wait 2500 milliseconds"));

        var complete_tasks_row = new Adw.ComboRow ();
        complete_tasks_row.title = _("Complete task");
        complete_tasks_row.model = complete_tasks_model;

        tasks_group.add (complete_tasks_row);

        var default_priority_model = new Gtk.StringList (null);
        default_priority_model.append (_("Priority 1"));
        default_priority_model.append (_("Priority 2"));
        default_priority_model.append (_("Priority 3"));
        default_priority_model.append (_("None"));

        var default_priority_row = new Adw.ComboRow ();
        default_priority_row.title = _("Default priority");
        default_priority_row.model = default_priority_model;

        tasks_group.add (default_priority_row);

        var description_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER
        };

        var description_row = new Adw.ActionRow ();
        description_row.title = _("Description preview");
        description_row.add_suffix (description_switch);

        tasks_group.add (description_row);

        var underline_completed_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER
        };

        var underline_completed_row = new Adw.ActionRow ();
        underline_completed_row.title = _("Underline completed tasks");
        underline_completed_row.add_suffix (underline_completed_switch);

        tasks_group.add (underline_completed_row);

        page.add (general_group);
        page.add (de_group);
        page.add (datetime_group);
        page.add (tasks_group);

        return page;
    }

    private Adw.PreferencesPage get_calendar_event_page () {
        var page = new Adw.PreferencesPage ();
        page.title = _("Calendar Events");
        page.name = "calendar-events";
        page.icon_name = "x-office-calendar-symbolic";

        return page;
    }
}