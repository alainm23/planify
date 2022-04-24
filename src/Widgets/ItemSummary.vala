public class Widgets.ItemSummary : Gtk.Revealer {
    public Objects.Item item { get; construct; }
    public Layouts.ItemRow itemrow { get; construct; }

    private Gtk.Label calendar_label;
    private Gtk.Grid calendar_grid;
    private Gtk.Revealer calendar_revealer;

    private Gtk.Label subtasks_label;
    private Gtk.Revealer subtasks_revealer;

    private Gtk.Revealer summary_revealer;
    private Gtk.FlowBox labels_flowbox;
    private Gtk.Revealer flowbox_revealer;

    private Gtk.Label description_label;
    private Gtk.Revealer description_label_revealer;

    Gee.HashMap<string, Widgets.ItemLabelChild> labels;

    public ItemSummary (Objects.Item item, Layouts.ItemRow itemrow) {
        Object (
            item: item,
            itemrow: itemrow
        );
    }

    construct {
        labels = new Gee.HashMap<string, Widgets.ItemLabelChild> ();

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

        subtasks_label = new Gtk.Label (null) {
            margin = 3
        };

        subtasks_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var subtasks_grid = new Gtk.Grid () {
            column_spacing = 3,
            margin_end = 6,
            valign = Gtk.Align.START
        };

        subtasks_grid.get_style_context ().add_class ("schedule-grid");
        subtasks_grid.add (subtasks_label);

        subtasks_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        subtasks_revealer.add (subtasks_grid);

        labels_flowbox = new Gtk.FlowBox () {
            column_spacing = 6,
            row_spacing = 6,
            homogeneous = false,
            hexpand = true,
            halign = Gtk.Align.START,
            valign = Gtk.Align.START,
            min_children_per_line = 3,
            max_children_per_line = 20
        };

        flowbox_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        flowbox_revealer.add (labels_flowbox);

        description_label = new Gtk.Label (null) {
            xalign = 0,
            lines = 1,
            ellipsize = Pango.EllipsizeMode.END,
            margin_start = 3
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
        summary_grid.add (subtasks_revealer);
        summary_grid.add (flowbox_revealer);

        unowned Gtk.StyleContext summary_grid_context = summary_grid.get_style_context ();
        summary_grid_context.add_class ("dim-label");

        summary_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        summary_revealer.add (summary_grid);

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START,
            row_spacing = 3
        };

        main_grid.add (description_label_revealer);
        main_grid.add (summary_revealer);

        add (main_grid);

        update_request ();
        check_revealer ();

        labels_flowbox.remove.connect ((widget) => {
            flowbox_revealer.reveal_child = labels_flowbox.get_children ().length () > 0;
            check_revealer ();
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "clock-format" || key == "description-preview") {
                update_request ();
            }
        });
    }

    public void update_request () {
        update_due_label ();
        update_subtasks ();
        update_labels ();

        description_label.label = Util.get_default ().line_break_to_space (item.description);
        description_label_revealer.reveal_child = description_label.label.length > 0 && 
            Planner.settings.get_boolean ("description-preview"); 
    }

    public void update_due_label () {
        calendar_grid.get_style_context ().remove_class ("overdue-grid");
        calendar_grid.get_style_context ().remove_class ("today-grid");
        calendar_grid.get_style_context ().remove_class ("schedule-grid");

        if (item.completed) {
            calendar_label.label = Util.get_default ().get_relative_date_from_date (
                Util.get_default ().get_date_from_string (item.completed_at)
            );
            calendar_grid.get_style_context ().add_class ("completed-grid");
            calendar_revealer.reveal_child = true;
            return;
        }

        if (item.has_due) {
            calendar_label.label = Util.get_default ().get_relative_date_from_date (item.due.datetime);
            calendar_revealer.reveal_child = true;

            if (Util.get_default ().is_today (item.due.datetime)) {
                calendar_grid.get_style_context ().add_class ("today-grid");
            } else if (Util.get_default ().is_overdue (item.due.datetime)) {
                calendar_grid.get_style_context ().add_class ("overdue-grid");
            } else {
                calendar_grid.get_style_context ().add_class ("schedule-grid");
            }
        } else {
            calendar_label.label = "";
            calendar_revealer.reveal_child = false;
        }
    }

    public void check_revealer () {
        summary_revealer.reveal_child = calendar_revealer.reveal_child ||
            flowbox_revealer.reveal_child || subtasks_revealer.reveal_child;
        reveal_child = (description_label_revealer.reveal_child || summary_revealer.reveal_child) && !itemrow.edit && !item.checked;
    }

    private void update_labels () {
        foreach (Objects.ItemLabel item_label in item.labels.values) {
            if (!labels.has_key (item_label.id_string)) {
                labels[item_label.id_string] = new Widgets.ItemLabelChild (item_label);
                labels_flowbox.add (labels[item_label.id_string]);
                labels_flowbox.show_all ();
            }
        }

        flowbox_revealer.reveal_child = labels_flowbox.get_children ().length () > 0;
    }

    private void update_subtasks () {
        int completed = 0;
        foreach (Objects.Item item in item.items) {
            if (item.checked) {
                completed++;
            }
        }

        subtasks_label.label = "%d/%d".printf (completed, item.items.size);
        subtasks_revealer.reveal_child = item.items.size > 0;
    }
}
