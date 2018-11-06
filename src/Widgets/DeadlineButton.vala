public class Widgets.DeadlineButton : Gtk.ToggleButton {
    private Widgets.Popovers.DeadlinePopover deadline_popover;
    public GLib.DateTime deadline_datetime;
    public bool has_deadline;

    public DeadlineButton () {
        Object (
            margin_start: 6,
            margin_bottom: 6
        );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        get_style_context ().add_class ("planner-button-no-focus");

        var deadline_icon = new Gtk.Image.from_icon_name ("planner-deadline-symbolic", Gtk.IconSize.MENU);

        string deadline_text = _("Deadline");
        var deadline_label = new Gtk.Label (deadline_text);
        deadline_label.margin_bottom = 1;

        deadline_popover = new Widgets.Popovers.DeadlinePopover (this);

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.pack_start (deadline_icon, false, false, 0);
        main_box.pack_start (deadline_label, false, false, 0);

        add (main_box);

        this.toggled.connect (() => {
          if (this.active) {
            deadline_popover.show_all ();
          }
        });

        deadline_popover.closed.connect (() => {
            this.active = false;
        });

        deadline_popover.on_selected_date.connect ((deadline) => {
            deadline_label.label = Granite.DateTime.get_relative_datetime (deadline);

            has_deadline = true;
            deadline_datetime = deadline;
        });

        deadline_popover.on_selected_remove.connect (() => {
            deadline_label.label = deadline_text;

            has_deadline = false;
        });
    }
}
