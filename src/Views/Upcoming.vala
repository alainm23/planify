public class Views.Upcoming : Gtk.EventBox {
    public GLib.DateTime date { get; set; default = new GLib.DateTime.now_local (); }
    private Gtk.ListBox listbox;

    construct {
        var icon_image = new Gtk.Image ();
        icon_image.valign = Gtk.Align.CENTER;
        icon_image.gicon = new ThemedIcon ("x-office-calendar-symbolic");
        icon_image.get_style_context ().add_class ("upcoming-icon");
        icon_image.pixel_size = 21;

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Upcoming")));
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        title_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_start = 41;
        top_box.margin_end = 24;

        top_box.pack_start (icon_image, false, false, 0);
        top_box.pack_start (title_label, false, false, 6);

        listbox = new Gtk.ListBox  ();
        listbox.margin_top = 18;
        listbox.valign = Gtk.Align.START;
        listbox.get_style_context ().add_class ("welcome");
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        var left_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        left_separator.hexpand = true;
        left_separator.valign = Gtk.Align.CENTER;

        var load_label = new Gtk.Label (_("Load the next 7 days"));
        load_label.margin_start = 12;
        load_label.margin_end = 12;
        load_label.get_style_context ().add_class ("font-bold");
        load_label.get_style_context ().add_class ("primary-label");

        var right_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        right_separator.hexpand = true;
        right_separator.valign = Gtk.Align.CENTER;
    
        var load_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        load_box.pack_start (left_separator, false, true, 0);
        load_box.set_center_widget (load_label);
        load_box.pack_end (right_separator, false, true, 0);

        var load_button = new Gtk.Button ();
        load_button.margin_start = 34;
        load_button.margin_end = 25;
        load_button.can_focus = false;
        load_button.get_style_context ().add_class ("flat");
        load_button.add (load_box);

        var load_revealer = new Gtk.Revealer ();
        load_revealer.transition_duration = 500;
        load_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        load_revealer.add (load_button);

        var load_eventbox = new Gtk.EventBox ();
        load_eventbox.margin_bottom = 18;
        load_eventbox.height_request = 44;
        load_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        load_eventbox.hexpand = true;
        load_eventbox.add (load_revealer);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (listbox, false, false, 0);
        main_box.pack_start (load_eventbox, false, true, 0);

        var main_scrolled = new Gtk.ScrolledWindow (null, null);
        main_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        main_scrolled.expand = true;
        main_scrolled.add (main_box);

        add (main_scrolled);
        add_dates ();

        show_all ();
        
        load_button.clicked.connect (()=> {
            add_dates ();
        });

        load_eventbox.enter_notify_event.connect ((event) => {
            load_revealer.reveal_child = true;

            return true;
        });

        load_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            load_revealer.reveal_child = false;

            return true;
        });
    }

    private void add_dates () {
        for (int i = 0; i < 7; i++) {
            if (date.add_days (1).get_month () > date.get_month ()) {
                Application.calendar_model.change_month (1);
            }

            date = date.add_days (1);

            var row = new Widgets.UpcomingRow (date);

            listbox.add (row);
            listbox.show_all ();
        }
    }
}