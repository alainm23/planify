public class Widgets.WhenButton : Gtk.ToggleButton {
    const string when_text = _("When");

    public bool has_duedate = false;
    public bool has_reminder = false;

    public GLib.DateTime reminder_datetime;
    public GLib.DateTime when_datetime;

    private Gtk.Box reminder_box;
    private Gtk.Label duedate_label;
    private Gtk.Label reminder_label;

    public signal void on_signal_selected ();
    public WhenButton () {
        Object (
            margin_start: 6,
            margin_bottom: 6
        );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        get_style_context ().add_class ("planner-button-no-focus");

        var duedate_icon = new Gtk.Image.from_icon_name ("office-calendar-symbolic", Gtk.IconSize.MENU);
        duedate_label = new Gtk.Label (when_text);
        duedate_label.margin_bottom = 1;

        var reminder_icon = new Gtk.Image.from_icon_name ("preferences-system-notifications-symbolic", Gtk.IconSize.MENU);
        reminder_label = new Gtk.Label ("");

        reminder_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        reminder_box.no_show_all = true;
        reminder_box.pack_start (reminder_icon, false, false, 0);
        reminder_box.pack_start (reminder_label, false, false, 0);

        var when_popover = new Widgets.Popovers.WhenPopover (this);

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.pack_start (duedate_icon, false, false, 0);
        main_box.pack_start (duedate_label, false, false, 0);
        main_box.pack_start (reminder_box, false, false, 0);

        add (main_box);

        this.toggled.connect (() => {
          if (this.active) {
            when_popover.show_all ();
            if (has_duedate) {
                when_popover.remove_button.visible = true;
            }
          }
        });

        when_popover.closed.connect (() => {
            this.active = false;
        });

        when_popover.on_selected_remove.connect (() => {
            clear ();
        });

        when_popover.on_selected_date.connect ((date, _has_reminder, _reminder_datetime) => {
            set_date (date, _has_reminder, _reminder_datetime);
            on_signal_selected ();
        });
    }

    private bool is_tomorrow (GLib.DateTime duedate) {
        var datetime_tomorrow = new GLib.DateTime.now_local ().add_days (1);
        if (datetime_tomorrow.get_year () == duedate.get_year ()) {
            if (datetime_tomorrow.get_month () == duedate.get_month ()) {
                if (datetime_tomorrow.get_day_of_month () == duedate.get_day_of_month ()) {
                    return true;
                } else {
                    return false;
                }
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    public void clear () {
        duedate_label.label = when_text;
        reminder_box.no_show_all = true;
        reminder_box.visible = false;

        has_duedate = false;
        has_reminder = false;
    }

    public void set_date (GLib.DateTime date, bool _has_reminder, GLib.DateTime _reminder_datetime) {
        reminder_box.no_show_all = !_has_reminder;
        reminder_box.visible = _has_reminder;
        reminder_label.label = "%i: %i".printf (_reminder_datetime.get_hour (), _reminder_datetime.get_minute ());

        when_datetime = date;
        reminder_datetime = _reminder_datetime;
        has_reminder = _has_reminder;
        has_duedate = true;

        if (Granite.DateTime.is_same_day (new GLib.DateTime.now_local (), date)) {
            duedate_label.label = _("Today");
            has_duedate = true;
        } else if (is_tomorrow (date)) {
            duedate_label.label = _("Tomorrow");
            has_duedate = true;
        } else {
            int day = date.get_day_of_month ();
            string month = Planner.utils.get_month_name (date.get_month ());
            duedate_label.label = "%i %s".printf (day, month);
            has_duedate = true;
        }

        show_all ();
    }
}
