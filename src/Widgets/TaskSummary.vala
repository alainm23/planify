public class Widgets.TaskSummary : Gtk.Revealer {
    public ECal.Component task { get; construct; }
    public Layouts.TaskRow taskrow { get; construct; }

    private Gtk.Label calendar_label;
    private Gtk.Grid calendar_grid;
    private Gtk.Revealer calendar_revealer;

    private Gtk.Revealer summary_revealer;

    private Gtk.Label description_label;
    private Gtk.Revealer description_label_revealer;

    public TaskSummary (ECal.Component task, Layouts.TaskRow taskrow) {
        Object (
            task: task,
            taskrow: taskrow
        );
    }

    construct {
        calendar_label = new Gtk.Label (null) {
            margin = 3
        };

        calendar_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        calendar_grid = new Gtk.Grid () {
            column_spacing = 3,
            margin_end = 6,
            valign = Gtk.Align.START
        };
        calendar_grid.add (calendar_label);

        calendar_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        calendar_revealer.add (calendar_grid);

        description_label = new Gtk.Label (null) {
            xalign = 0,
            lines = 1,
            ellipsize = Pango.EllipsizeMode.END
        };
        description_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        description_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        description_label_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = false
        };
        description_label_revealer.add (description_label);
        
        var summary_grid = new Gtk.Grid () {
            valign = Gtk.Align.START
        };

        summary_grid.add (calendar_revealer);

        unowned Gtk.StyleContext summary_grid_context = summary_grid.get_style_context ();
        summary_grid_context.add_class ("dim-label");

        summary_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        summary_revealer.add (summary_grid);

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START,
            margin_top = 3
        };

        main_grid.add (description_label_revealer);
        main_grid.add (summary_revealer);

        add (main_grid);

        update_request (task, taskrow);
        check_revealer (task, taskrow);

        Planner.settings.changed.connect ((key) => {
            if (key == "clock-format" || key == "description-preview") {
                update_request (task, taskrow);
            }
        });
    }

    public void update_request (ECal.Component task, Layouts.TaskRow taskrow) {
        update_due_label (task, taskrow);

        if (task.get_icalcomponent ().get_description () != null) {
            description_label.label = Util.get_default ().line_break_to_space (
                task.get_icalcomponent ().get_description ()
            );
        } else {
            description_label.label = Util.get_default ().line_break_to_space ("");
        }

        description_label_revealer.reveal_child = description_label.label.length > 0 && 
            Planner.settings.get_boolean ("description-preview"); 
    }

    public void update_due_label (ECal.Component task, Layouts.TaskRow taskrow) {
        calendar_grid.get_style_context ().remove_class ("overdue-grid");
        calendar_grid.get_style_context ().remove_class ("today-grid");
        calendar_grid.get_style_context ().remove_class ("schedule-grid");
        
        if (task.get_icalcomponent ().get_status () == ICal.PropertyStatus.COMPLETED) {
            GLib.DateTime datetime = CalDAVUtil.ical_to_date_time_local (
                task.get_completed ()
            );

            calendar_label.label = Util.get_default ().get_relative_date_from_date (datetime);
            calendar_grid.get_style_context ().add_class ("completed-grid");
            calendar_revealer.reveal_child = true;
            
            return;
        }

        if (!task.get_icalcomponent ().get_due ().is_null_time ()) {
            GLib.DateTime datetime = CalDAVUtil.ical_to_date_time_local (
                task.get_icalcomponent ().get_due ()
            );

            calendar_label.label = Util.get_default ().get_relative_date_from_date (datetime);
            calendar_revealer.reveal_child = true;

            if (Util.get_default ().is_today (datetime)) {
                calendar_grid.get_style_context ().add_class ("today-grid");
            } else if (Util.get_default ().is_overdue (datetime)) {
                calendar_grid.get_style_context ().add_class ("overdue-grid");
            } else {
                calendar_grid.get_style_context ().add_class ("schedule-grid");
            }
        } else {
            calendar_label.label = "";
            calendar_revealer.reveal_child = false;
        }
    }

    public void check_revealer (ECal.Component task, Layouts.TaskRow taskrow) {
        bool checked = task.get_icalcomponent ().get_status () == ICal.PropertyStatus.COMPLETED;

        summary_revealer.reveal_child = calendar_revealer.reveal_child;
        reveal_child = (description_label_revealer.reveal_child || summary_revealer.reveal_child) &&
            !taskrow.edit && !checked;
    }
}
