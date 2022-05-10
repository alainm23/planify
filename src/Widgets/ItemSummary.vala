public class Widgets.ItemSummary : Gtk.Revealer {
    public Objects.Item item { get; construct; }
    public Layouts.ItemRow? itemrow { get; construct; }

    private Gtk.Label due_label;
    private Widgets.DynamicIcon today_image;
    private Gtk.Stack due_stack;
    private Gtk.Grid due_grid;
    private Gtk.Revealer due_revealer;

    private Gtk.Label subtasks_label;
    private Gtk.Revealer subtasks_revealer;

    private Gtk.Revealer summary_revealer;
    private Gtk.FlowBox labels_flowbox;
    private Gtk.Revealer flowbox_revealer;

    private Gtk.Label more_label;
    private Gtk.Grid more_label_grid;
    private Gtk.Revealer more_label_revealer;

    private Gtk.Label description_label;
    private Gtk.Revealer description_label_revealer;

    Gee.HashMap<string, Widgets.ItemLabelChild> labels;

    public uint labels_flowbox_size {
        get {
            return labels_flowbox.get_children ().length ();
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

        due_label = new Gtk.Label (null) {
            margin = 3
        };

        due_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);
        
        today_image = new Widgets.DynamicIcon ();
        today_image.update_icon_name ("planner-today");
        today_image.size = 19; 

        due_stack = new Gtk.Stack ();
        due_stack.add_named (due_label, "due_label");
        due_stack.add_named (today_image, "today_image");

        due_grid = new Gtk.Grid () {
            column_spacing = 3,
            margin_end = 6,
            valign = Gtk.Align.START
        };
        due_grid.add (due_stack);

        due_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        due_revealer.add (due_grid);

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

        flowbox_revealer.add (labels_flowbox);

        more_label = new Gtk.Label (null) {
            margin = 3
        };

        more_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);
        
        more_label_grid = new Gtk.Grid () {
            column_spacing = 3,
            margin_end = 6,
            valign = Gtk.Align.START
        };
        more_label_grid.add (more_label);
        more_label_grid.get_style_context ().add_class ("item-label-child");

        more_label_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        more_label_revealer.add (more_label_grid);

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

        summary_grid.add (due_revealer);
        summary_grid.add (subtasks_revealer);
        summary_grid.add (flowbox_revealer);
        summary_grid.add (more_label_revealer);

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

        if (itemrow == null) {
            main_grid.margin_top = 3;
            main_grid.margin_bottom = 3;
        }

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
                check_revealer ();
            }
        });

        item.item_added.connect (() => {
            update_request ();
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
        due_grid.get_style_context ().remove_class ("overdue-grid");
        due_grid.get_style_context ().remove_class ("today-grid");
        due_grid.get_style_context ().remove_class ("schedule-grid");

        if (item.completed) {
            due_label.label = Util.get_default ().get_relative_date_from_date (
                Util.get_default ().get_date_from_string (item.completed_at)
            );
            due_grid.get_style_context ().add_class ("completed-grid");
            due_revealer.reveal_child = true;
            return;
        }

        if (item.has_due) {
            due_label.label = Util.get_default ().get_relative_date_from_date (item.due.datetime);
            due_revealer.reveal_child = true;

            if (Util.get_default ().is_today (item.due.datetime)) {
                due_grid.get_style_context ().add_class ("today-grid");
                due_stack.visible_child_name = "today_image";
            } else if (Util.get_default ().is_overdue (item.due.datetime)) {
                due_grid.get_style_context ().add_class ("overdue-grid");
                due_stack.visible_child_name = "due_label";
            } else {
                due_grid.get_style_context ().add_class ("schedule-grid");
                due_stack.visible_child_name = "due_label";
            }

            due_stack.show_all ();
        } else {
            due_label.label = "";
            due_revealer.reveal_child = false;
        }
    }

    public void check_revealer () {
        if (itemrow != null) {
            summary_revealer.reveal_child = due_revealer.reveal_child ||
            flowbox_revealer.reveal_child || subtasks_revealer.reveal_child;
            reveal_child = (description_label_revealer.reveal_child || summary_revealer.reveal_child) &&
            !itemrow.edit && !item.checked;
        } else {
            summary_revealer.reveal_child = due_revealer.reveal_child ||
            flowbox_revealer.reveal_child || subtasks_revealer.reveal_child;
            reveal_child = (description_label_revealer.reveal_child || summary_revealer.reveal_child) && !item.checked;
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

                    var item_label_child = new Widgets.ItemLabelChild (item_label);

                    item_label_child.delete_request.connect (() => {
                        labels.unset (item_label_child.item_label.id_string);
                        item_label_child.hide_destroy ();
                    });

                    labels[item_label.id_string] = item_label_child;
                    labels_flowbox.add (labels[item_label.id_string]);
                    labels_flowbox.show_all ();
                }

                count++;
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
