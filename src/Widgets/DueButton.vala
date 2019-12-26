public class Widgets.DueButton : Gtk.ToggleButton {
    public Objects.Item item { get; construct; }

    private Gtk.Label due_label; 
    private Gtk.Image due_image;
    private Gtk.Revealer label_revealer;

    private Gtk.Popover popover = null;

    private Widgets.ModelButton today_button;
    private Widgets.ModelButton tomorrow_button;
    private Widgets.ModelButton undated_button;
    private Widgets.Calendar.Calendar calendar;

    public DueButton (Objects.Item item) {
        Object (
            item: item
        );
    }

    construct {
        tooltip_text = _("Due Date");
        
        get_style_context ().add_class ("flat");
        get_style_context ().add_class ("item-action-button");
        
        due_image = new Gtk.Image ();
        due_image.valign = Gtk.Align.CENTER;
        due_image.gicon = new ThemedIcon ("x-office-calendar-symbolic");
        due_image.pixel_size = 18;

        due_label = new Gtk.Label (null);
        due_label.get_style_context ().add_class ("pane-item");
        due_label.margin_bottom = 1;
        due_label.use_markup = true;

        label_revealer = new Gtk.Revealer ();
        label_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        label_revealer.add (due_label);

        var main_grid = new Gtk.Grid ();
        main_grid.halign = Gtk.Align.CENTER;
        main_grid.valign = Gtk.Align.CENTER;
        main_grid.add (due_image);
        main_grid.add (label_revealer);

        add (main_grid);

        this.toggled.connect (() => {
            if (this.active) {
                if (popover == null) {
                    create_popover ();
                }

                popover.popup ();
            }
        });

        update_date_text (item.due_date);
    }

    public void update_date_text (string due) {
        if (due != "") {
            var date = new GLib.DateTime.from_iso8601 (due, new GLib.TimeZone.local ());

            due_label.label = Planner.utils.get_relative_date_from_date (date);
            due_image.get_style_context ().add_class ("upcoming");
            label_revealer.reveal_child = true;
        } else {
            due_label.label = "";
            due_image.get_style_context ().remove_class ("upcoming");
            label_revealer.reveal_child = false;
        }
    }

    private void create_popover () {
        popover = new Gtk.Popover (this);
        popover.position = Gtk.PositionType.BOTTOM;

        var mode_button = new Granite.Widgets.ModeButton ();
        mode_button.hexpand = true;
        mode_button.margin = 6;
        mode_button.valign = Gtk.Align.CENTER;

        mode_button.append_icon ("office-calendar-symbolic", Gtk.IconSize.MENU);
        mode_button.append_icon ("view-refresh-symbolic", Gtk.IconSize.MENU);

        mode_button.selected = 0;

        var stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        stack.add_named (get_calendar_widget (), "duedate");
        //stack.add_named (get_repeat_widget (), "repeat");

        var popover_grid = new Gtk.Grid ();
        popover_grid.margin_top = 6;
        popover_grid.width_request = 235;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        //popover_grid.add (mode_button);
        popover_grid.add (stack);
        popover_grid.show_all ();

        popover.add (popover_grid);

        popover.closed.connect (() => {
            this.active = false;
        });

        mode_button.mode_changed.connect ((widget) => {
            if (mode_button.selected == 0) {
                stack.visible_child_name = "duedate";
            } else {
                stack.visible_child_name = "repeat";
            }
        });
    }

    private Gtk.Widget get_calendar_widget () {
        string today_icon = "planner-today-day-symbolic";
        var hour = new GLib.DateTime.now_local ().get_hour ();
        if (hour >= 18 || hour <= 5) {
            today_icon = "planner-today-night-symbolic";
        }

        today_button = new Widgets.ModelButton (_("Today"), today_icon, "");
        today_button.color = 0;
        today_button.due_label = true;

        tomorrow_button = new Widgets.ModelButton (_("Tomorrow"), "x-office-calendar-symbolic", "");
        tomorrow_button.color = 1;
        tomorrow_button.due_label = true;

        undated_button = new Widgets.ModelButton (_("Undated"), "window-close-symbolic", "");
        undated_button.color = 2;
        undated_button.due_label = true;

        calendar = new Widgets.Calendar.Calendar (true);
        calendar.hexpand = true;

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (today_button);
        grid.add (tomorrow_button);
        grid.add (undated_button);
        grid.add (calendar);
        grid.show_all ();

        today_button.clicked.connect (() => {
            set_due (new GLib.DateTime.now_local ());
        });

        tomorrow_button.clicked.connect (() => {
            set_due (new GLib.DateTime.now_local ().add_days (1));
        });

        undated_button.clicked.connect (() => {
            set_due (null);
        });

        calendar.selection_changed.connect ((date) => {
            set_due (date);
        });

        return grid;
    }

    /*
    private Gtk.Widget get_repeat_widget () {
        var enabled_label = new Gtk.Label (_("Enabled"));
        enabled_label.get_style_context ().add_class ("font-weight-600");

        var enabled_switch = new Gtk.Switch ();
        enabled_switch.valign = Gtk.Align.CENTER;
        enabled_switch.get_style_context ().add_class ("active-switch");

        var enabled_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        enabled_box.hexpand = true;
        enabled_box.pack_start (enabled_label, false, true, 0);
        enabled_box.pack_end (enabled_switch, false, true, 0);

        // Combobox
        var combobox = new Gtk.ComboBoxText ();
        combobox.margin_top = 12;
        combobox.append_text (_("Every day"));
        combobox.append_text (_("Every week"));
        combobox.append_text (_("Every month"));
        combobox.append_text (_("Every year"));
        combobox.append_text (_("Custom"));

        var grid = new Gtk.Grid ();
        grid.margin_start = 9;
        grid.margin_end = 9;
        grid.margin_top = 6;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (enabled_box);
        grid.add (combobox);
        grid.show_all ();

        return grid;
    }
    */

    private void set_due (GLib.DateTime? date) {
        bool new_date = false;
        if (date != null) {
            if (item.due_date == "") {
                new_date = true;
            }

            item.due_date = date.to_string ();
        } else {
            item.due_date = "";
        }

        if (Planner.database.set_due_item (item, new_date)) {
            popover.popdown ();
        }

        if (item.is_todoist == 1) {
            Planner.todoist.update_item (item);
        }
    }
}