public class Widgets.ItemSummary : Gtk.Grid {
    public Objects.Item item { get; construct; }
    public Layouts.ItemRow? itemrow { get; construct; }

    private Gtk.Label due_label;
    private Gtk.Grid due_grid;
    private Gtk.Revealer due_revealer;

    private Gtk.Label subtasks_label;
    private Gtk.Revealer subtasks_revealer;

    private Gtk.Revealer reminder_revealer;

    private Gtk.Revealer summary_revealer;
    private Gtk.FlowBox labels_flowbox;
    private Gtk.Revealer flowbox_revealer;

    private Gtk.Label more_label;
    private Gtk.Grid more_label_grid;
    private Gtk.Revealer more_label_revealer;

    private Gtk.Label description_label;
    private Gtk.Revealer description_label_revealer;
    private Gtk.Revealer description_revealer;

    private Gtk.Revealer revealer;
    Gee.HashMap<string, Widgets.ItemLabelChild> labels;

    public uint labels_flowbox_size {
        get {
            return Util.get_default ().get_children (labels_flowbox).length ();
        }
    }

    public bool reveal_child {
        set {
            revealer.reveal_child = value;
        }
    }

    public ItemSummary (Objects.Item item, Layouts.ItemRow? itemrow = null) {
        Object (
            item: item,
            itemrow: itemrow
        );
    }

    construct {
        labels = new Gee.HashMap<string, Widgets.ItemLabelChild> ();

        due_label = new Gtk.Label (null);
        due_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        
        due_grid = new Gtk.Grid () {
            column_spacing = 3,
            margin_end = 6,
            valign = Gtk.Align.START
        };

        due_grid.attach (due_label, 0, 0);

        due_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        due_revealer.child = due_grid;

        subtasks_label = new Gtk.Label (null) {
            margin_top = 3,
            margin_start = 3,
            margin_end = 3,
            margin_bottom = 3
        };

        subtasks_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var subtasks_grid = new Gtk.Grid () {
            column_spacing = 3,
            margin_end = 6,
            valign = Gtk.Align.START
        };

        subtasks_grid.add_css_class ("schedule-grid");
        subtasks_grid.attach (subtasks_label, 0, 0);

        subtasks_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        subtasks_revealer.child = subtasks_grid;

        var reminder_image = new Widgets.DynamicIcon ();
        reminder_image.size = 19;
        reminder_image.valign = Gtk.Align.CENTER;
        reminder_image.update_icon_name ("planner-bell");
        reminder_image.margin_end = 6;

        reminder_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };

        reminder_revealer.child = reminder_image;

        var description_image = new Widgets.DynamicIcon ();
        description_image.size = 19;
        description_image.valign = Gtk.Align.CENTER;
        description_image.update_icon_name ("planner-note");
        description_image.margin_end = 6;

        description_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };

        description_revealer.child = description_image;

        labels_flowbox = new Gtk.FlowBox () {
            column_spacing = 6,
            row_spacing = 6,
            homogeneous = false,
            hexpand = false,
            halign = Gtk.Align.START,
            valign = Gtk.Align.START,
            min_children_per_line = itemrow == null ? 1 : 3,
            max_children_per_line = 20,
            margin_end = 6,
        };

        flowbox_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };

        flowbox_revealer.child = labels_flowbox;

        more_label = new Gtk.Label (null);

        more_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        
        more_label_grid = new Gtk.Grid () {
            column_spacing = 3,
            margin_end = 6,
            valign = Gtk.Align.START
        };
        more_label_grid.attach (more_label, 0, 0);
        more_label_grid.add_css_class ("item-label-child");

        more_label_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        more_label_revealer.child = more_label_grid;

        description_label = new Gtk.Label (null) {
            xalign = 0,
            lines = 1,
            ellipsize = Pango.EllipsizeMode.END,
            margin_start = 3,
            margin_bottom = 3
        };
        description_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        description_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        description_label_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = false
        };
        description_label_revealer.child = description_label;
        
        var summary_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            valign = Gtk.Align.START
        };

        summary_grid.append (due_revealer);
        summary_grid.append (subtasks_revealer);
        summary_grid.append (reminder_revealer);
        summary_grid.append (description_revealer);
        summary_grid.append (flowbox_revealer);
        summary_grid.append (more_label_revealer);

        summary_grid.add_css_class ("dim-label");

        summary_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        summary_revealer.child = summary_grid;

        var main_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.START
        };

        main_grid.append (description_label_revealer);
        main_grid.append (summary_revealer);

        if (itemrow == null) {
            //  main_grid.margin_top = 3;
            main_grid.margin_bottom = 6;
        }

        revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };

        revealer.child = main_grid;

        attach (revealer, 0, 0);

        update_request ();
        check_revealer ();

        Planner.settings.changed.connect ((key) => {
            if (key == "clock-format" || key == "description-preview") {
                update_request ();
                check_revealer ();
            }
        });

        item.item_added.connect (() => {
            update_request ();
        });

        item.item_label_deleted.connect ((item_label) => {
            remove_item_label (item_label);
        });
    }

    public void update_request () {
        update_due_label ();
        update_reminders ();
        // update_subtasks ();
        update_labels ();

        description_label.label = Util.get_default ().line_break_to_space (item.description);
        description_revealer.reveal_child = item.description.length > 0 && Planner.settings.get_boolean ("description-preview") == false; 
        description_label_revealer.reveal_child = description_label.label.length > 0 && 
            Planner.settings.get_boolean ("description-preview"); 
    }

    public void update_due_label () {
        due_grid.remove_css_class ("overdue-grid");
        due_grid.remove_css_class ("today-grid");
        due_grid.remove_css_class ("upcoming-grid");

        if (item.completed) {
            due_label.label = Util.get_default ().get_relative_date_from_date (
                Util.get_default ().get_date_from_string (item.completed_at)
            );
            due_grid.add_css_class ("completed-grid");
            due_revealer.reveal_child = true;
            return;
        }

        if (item.has_due) {
            due_label.label = Util.get_default ().get_relative_date_from_date (item.due.datetime);
            due_revealer.reveal_child = true;

            if (Util.get_default ().is_today (item.due.datetime)) {
                due_grid.add_css_class ("today-grid");
            } else if (Util.get_default ().is_overdue (item.due.datetime)) {
                due_grid.add_css_class ("overdue-grid");
            } else {
                due_grid.add_css_class ("upcoming-grid");
            }
        } else {
            due_label.label = "";
            due_revealer.reveal_child = false;
        }
    }

    public void check_revealer () {
        if (itemrow != null) {
            summary_revealer.reveal_child = due_revealer.reveal_child ||
            flowbox_revealer.reveal_child || // subtasks_revealer.reveal_child ||
            reminder_revealer.reveal_child || description_revealer.reveal_child;
            revealer.reveal_child = (description_label_revealer.reveal_child || summary_revealer.reveal_child) &&
            !itemrow.edit;
        } else {
            summary_revealer.reveal_child = due_revealer.reveal_child ||
            flowbox_revealer.reveal_child || // subtasks_revealer.reveal_child ||
            reminder_revealer.reveal_child || description_revealer.reveal_child;
            revealer.reveal_child = (description_label_revealer.reveal_child || summary_revealer.reveal_child);
        }
    }

    private void update_labels () {
        int more = 0;
        int count = 0;
        string tooltip_text = "";
        more_label_revealer.reveal_child = false;

        foreach (Objects.ItemLabel item_label in item.labels.values) {
            if (!labels.has_key (item_label.id_string)) {
                if (itemrow == null && labels.size >= 1) {
                    more++;
                    more_label.label = "+%d".printf (more);
                    tooltip_text += "- %s%s".printf (
                        item_label.label.name,
                        more + 1 >= item.labels.values.size ? "" : "\n"
                    );
                    more_label_grid.tooltip_text = tooltip_text;
                    more_label_revealer.reveal_child = true;
                } else {
                    Util.get_default ().set_widget_color (
                        Util.get_default ().get_color (item_label.label.color),
                        more_label_grid
                    );

                    labels[item_label.id_string] = new Widgets.ItemLabelChild (item_label);
                    labels_flowbox.append (labels[item_label.id_string]);
                }

                count++;
            }
        }

        flowbox_revealer.reveal_child = labels.size > 0;
    }

    public void remove_item_label (Objects.ItemLabel item_label) {
        if (labels.has_key (item_label.id_string)) {
            labels_flowbox.remove (labels[item_label.id_string]);
            labels.unset (item_label.id_string);
        }

        flowbox_revealer.reveal_child = labels.size > 0;
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

    private void update_reminders () {
        reminder_revealer.reveal_child = item.reminders.size > 0;
    }
}