public class Views.Scheduled.Scheduled : Gtk.EventBox {
    private Gtk.Label date_label;

    private GLib.DateTime date;
    private Views.Date date_view;
    private Hdy.Carousel carousel;
    private Views.Scheduled.ScheduledHeader grid_center;
    private Views.Scheduled.ScheduledHeader grid_left;
    private Views.Scheduled.ScheduledHeader grid_right;
    private uint position;
    private int rel_postion;

    construct {
        var scheduled_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("planner-scheduled"),
            pixel_size = 24
        };

        var title_label = new Gtk.Label (_("Scheduled"));
        title_label.get_style_context ().add_class ("header-title");

        date_label = new Gtk.Label (null) {
            margin_top = 2
        };

        var today_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        today_box.pack_start (scheduled_icon, false, false, 0);
        today_box.pack_start (title_label, false, false, 6);
        today_box.pack_start (date_label, false, false, 0);

        var today_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };
        today_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        today_button.add (today_box);

        var chevron_left_image = new Widgets.DynamicIcon ();
        chevron_left_image.size = 19;
        chevron_left_image.update_icon_name ("chevron-left");
        
        var chevron_left_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        chevron_left_button.add (chevron_left_image);
        chevron_left_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var calendar_image = new Widgets.DynamicIcon ();
        calendar_image.size = 19;
        calendar_image.update_icon_name ("planner-calendar");
        
        var calendar_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        calendar_button.add (calendar_image);
        calendar_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var chevron_right_image = new Widgets.DynamicIcon ();
        chevron_right_image.size = 19;
        chevron_right_image.update_icon_name ("chevron-right");
        
        var chevron_right_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        chevron_right_button.add (chevron_right_image);
        chevron_right_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var nav_grid = new Gtk.Grid () {
            valign = Gtk.Align.CENTER
        };
        nav_grid.add (chevron_left_button);
        nav_grid.add (calendar_button);
        nav_grid.add (chevron_right_button);

        var menu_image = new Widgets.DynamicIcon ();
        menu_image.size = 19;
        menu_image.update_icon_name ("dots-horizontal");
        
        var menu_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        menu_button.add (menu_image);
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var search_image = new Widgets.DynamicIcon ();
        search_image.size = 19;
        search_image.update_icon_name ("planner-search");
        
        var search_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };
        search_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        search_button.add (search_image);
        search_button.clicked.connect (Util.get_default ().open_quick_find);

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 2,
            margin_end = 6
        };

        header_box.pack_start (today_button, false, true, 0);
        // header_box.pack_end (menu_button, false, false, 0);
        header_box.pack_end (search_button, false, false, 0);
        header_box.pack_end (nav_grid, false, false, 12);

        var magic_button = new Widgets.MagicButton ();

        carousel = new Hdy.Carousel () {
            interactive = true,
            spacing = 12,
            margin_top = 12
        };

        show_today ();

        date_view = new Views.Date () {
            margin_top = 12,
            expand = true
        };

        date_view.date = new GLib.DateTime.now_local ().add_days (1);

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            expand = true,
            margin_start = 36,
            margin_end = 36,
            margin_bottom = 36,
            margin_top = 6
        };
        content.pack_start (header_box, false, false, 0);
        content.pack_start (carousel, false, false, 0);
        content.pack_start (date_view, true, true, 0);

        var content_clamp = new Hdy.Clamp () {
            maximum_size = 720
        };

        content_clamp.add (content);

        var scrolled_window = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        scrolled_window.add (content_clamp);

        var overlay = new Gtk.Overlay () {
            expand = true
        };
        overlay.add_overlay (magic_button);
        overlay.add (scrolled_window);

        add (overlay);
        show_all ();
        update_date_label ();

        Timeout.add (250, () => {
            carousel.expand = false;
            return GLib.Source.REMOVE;
        });

        carousel.page_changed.connect ((index) => {
            if (position > index) {
                rel_postion--;
                position--;
                date = date.add_days (-7);
            } else if (position < index) {
                rel_postion++;
                position++;
                date = date.add_days (7);
            }

            if (index + 1 == (int) carousel.get_n_pages ()) {
                var grid = new Views.Scheduled.ScheduledHeader (date.add_days (7));
                grid.date_selected.connect (date_selected);
                carousel.add (grid);
            } else if (index == 0) {
                var grid = new Views.Scheduled.ScheduledHeader (date.add_days (-7));
                grid.date_selected.connect (date_selected);
                carousel.prepend (grid);
                position++;
            }

            update_date_label ();
        });

        chevron_left_button.clicked.connect (() => {
            carousel.switch_child ((int) carousel.get_position () - 1, carousel.get_animation_duration ());
        });

        chevron_right_button.clicked.connect (() => {
            carousel.switch_child ((int) carousel.get_position () + 1, carousel.get_animation_duration ());
        });

        calendar_button.clicked.connect (() => {
            var menu = new Dialogs.ContextMenu.Menu ();

            var calendar = new Widgets.Calendar.Calendar () {
                expand = true
            };

            menu.add_item (calendar);

            menu.popup ();

            calendar.selection_changed.connect ((date) => {
                menu.hide_destroy ();
                date_selected (date);
            });
        });

        today_button.clicked.connect (() => {
            show_today ();
        });

        magic_button.clicked.connect (() => {
            date_view.prepare_new_item ();
        });
    }

    private void update_date_label () {
        int day_of_week = date.get_day_of_week ();
        GLib.DateTime _date = date.add_days (-1 * (day_of_week - 1));
        date_label.label = _date.format ("%B");
        if (_date.get_year () != new GLib.DateTime.now_local ().get_year ()) {
            date_label.label = date_label.label + " %s".printf (_date.format ("%Y"));
        }
    }

    private void date_selected (GLib.DateTime date) {
        date_view.date = date;
    }

    private void show_today () {
        date = new GLib.DateTime.now_local ();
        carousel.no_show_all = true;
        
        foreach (unowned Gtk.Widget grid in carousel.get_children ()) {
            carousel.remove (grid);
        }

        grid_center = new Views.Scheduled.ScheduledHeader (date);
        grid_center.date_selected.connect (date_selected);
        
        date = date.add_days (-7);
        grid_left = new Views.Scheduled.ScheduledHeader (date);
        grid_left.date_selected.connect (date_selected);

        date = date.add_days (14);
        grid_right = new Views.Scheduled.ScheduledHeader (date);
        grid_right.date_selected.connect (date_selected);

        carousel.add (grid_left);
        carousel.add (grid_center);
        carousel.add (grid_right);

        carousel.scroll_to (grid_center);

        position = 1;
        rel_postion = 0;
        date = date.add_days (-7);

        carousel.no_show_all = false;
    }
}
