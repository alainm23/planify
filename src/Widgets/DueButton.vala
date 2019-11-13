public class Widgets.DueButton : Gtk.ToggleButton {
    public Objects.Item item { get; set; }

    private Gtk.Label due_label; 
    private Gtk.Image due_image;
    private Gtk.Revealer label_revealer;

    private Gtk.Popover popover = null;

    private Widgets.ModelButton today_button;
    private Widgets.ModelButton tomorrow_button;
    private Widgets.ModelButton undated_button;
    private Widgets.Calendar.Calendar calendar;

    construct {
        tooltip_text = _("Due Date");
        
        get_style_context ().add_class ("flat");
        get_style_context ().add_class ("item-action-button");
        get_style_context ().add_class ("due-no-date");
        
        due_image = new Gtk.Image ();
        due_image.valign = Gtk.Align.CENTER;
        due_image.gicon = new ThemedIcon ("office-calendar-symbolic");
        due_image.pixel_size = 16;

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

        notify["item"].connect (() => {
            update_date_text (item.due_date);
        });

    }

    public void update_date_text (string due) {
        if (due != "") {
            var date = new GLib.DateTime.from_iso8601 (due, new GLib.TimeZone.local ());

            due_label.label = Application.utils.get_relative_date_from_date (date);
            get_style_context ().remove_class ("due-no-date");
            due_image.get_style_context ().add_class ("upcoming");
            label_revealer.reveal_child = true;
        } else {
            due_label.label = "";
            get_style_context ().add_class ("due-no-date");
            due_image.get_style_context ().remove_class ("upcoming");
            label_revealer.reveal_child = false;
        }
    }

    private void create_popover () {
        popover = new Gtk.Popover (this);
        popover.position = Gtk.PositionType.RIGHT;

        string today_icon = "planner-today-day-symbolic";
        var hour = new GLib.DateTime.now_local ().get_hour ();
        if (hour >= 18 || hour <= 6) {
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

        var popover_grid = new Gtk.Grid ();
        popover_grid.width_request = 235;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.margin_top = 6;
        popover_grid.margin_bottom = 6;
        popover_grid.add (today_button);
        popover_grid.add (tomorrow_button);
        popover_grid.add (undated_button);
        popover_grid.add (calendar);
        popover_grid.show_all ();

        popover.add (popover_grid);

        popover.closed.connect (() => {
            this.active = false;
        });

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
    }
    
    private void set_due (GLib.DateTime? date) {
        bool new_date = false;
        if (date != null) {
            update_date_text (date.to_string ());

            if (item.due_date == "") {
                new_date = true;
            }

            item.due_date = date.to_string ();
        } else {
            update_date_text ("");
            item.due_date = "";
        }

        if (Application.database.set_due_item (item, new_date)) {
            popover.popdown ();
        }

        if (item.is_todoist == 1) {
            Application.todoist.update_item (item);
        }
    }
}