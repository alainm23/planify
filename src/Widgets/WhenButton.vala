public class Widgets.WhenButton : Gtk.ToggleButton {
    private Widgets.Popovers.WhenPopover when_popover;
    const string when_text = _("When");

    public bool has_when = false;
    public bool has_reminder = false;

    public GLib.DateTime reminder_datetime;
    public GLib.DateTime when_datetime;

    private Gtk.Box reminder_box;
    private Gtk.Label when_label;
    private Gtk.Label reminder_label;

    public signal void on_signal_selected ();
    public WhenButton () {
        Object (
            valign: Gtk.Align.CENTER
        );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var when_icon = new Gtk.Image.from_icon_name ("office-calendar-symbolic", Gtk.IconSize.MENU);

        when_label = new Gtk.Label (when_text);
        when_label.margin_bottom = 1;

        var reminder_icon = new Gtk.Image.from_icon_name ("notification-new-symbolic", Gtk.IconSize.MENU);
        reminder_label = new Gtk.Label ("");

        reminder_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        reminder_box.no_show_all = true;
        reminder_box.pack_start (reminder_icon, false, false, 0);
        reminder_box.pack_start (reminder_label, false, false, 0);

        when_popover = new Widgets.Popovers.WhenPopover (this);

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.pack_start (when_icon, false, false, 0);
        main_box.pack_start (when_label, false, false, 0);
        main_box.pack_start (reminder_box, false, false, 0);

        add (main_box);

        this.toggled.connect (() => {
          if (this.active) {
            when_popover.show_all ();
            if (has_when) {
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

    public void clear () {
        when_label.label = when_text;
        reminder_box.no_show_all = true;
        reminder_box.visible = false;

        has_when = false;
        has_reminder = false;
    }

    public void set_date (GLib.DateTime date, bool _has_reminder, GLib.DateTime _reminder_datetime) {
        reminder_box.no_show_all = !_has_reminder;
        reminder_box.visible = _has_reminder;
        when_popover.reminder_switch.active = _has_reminder;
        when_popover.reminder_timepicker.time = _reminder_datetime;

        string time_format = Granite.DateTime.get_default_time_format (true, false);
        reminder_label.label = _reminder_datetime.format (time_format);

        when_datetime = date;
        reminder_datetime = _reminder_datetime;
        has_reminder = _has_reminder;
        has_when = true;

        if (Application.utils.is_today (date)) {
            when_label.label = Application.utils.TODAY_STRING;
            has_when = true;
        } else if (Application.utils.is_tomorrow (date)) {
            when_label.label = Application.utils.TOMORROW_STRING;
            has_when = true;
        } else {
            string date_format = Granite.DateTime.get_default_date_format (false, true, false);
            when_label.label = date.format (date_format);
            has_when = true;
        }

        show_all ();
    }
}
