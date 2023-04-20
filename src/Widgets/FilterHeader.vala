public class Widgets.FilterHeader : Gtk.Grid {
    public Objects.BaseObject view { get; construct; }

    private Gtk.Label date_label;
    private Gtk.Revealer date_label_revealer;

    public signal void prepare_new_item ();

    public FilterHeader (Objects.BaseObject view) {
        Object (
            view: view
        );
    }

    construct {
        var sidebar_image = new Widgets.DynamicIcon ();
        sidebar_image.size = 19;

        if (Planner.settings.get_boolean ("slim-mode")) {
            sidebar_image.update_icon_name ("sidebar-left");
        } else {
            sidebar_image.update_icon_name ("sidebar-right");
        }
        
        var sidebar_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER
        };

        sidebar_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        sidebar_button.child = sidebar_image;

        var view_icon = new Gtk.Image () {
            pixel_size = 24,
            valign = Gtk.Align.CENTER
        };

        var title_label = new Gtk.Label (null);
        title_label.add_css_class ("font-bold");

        date_label = new Gtk.Label (null);
        date_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        date_label_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = date_label
        };

        if (view is Objects.Today) {
            title_label.label = _("Today");
            view_icon.gicon = new ThemedIcon ("planner-today");
        } else if (view is Objects.Scheduled) {
            title_label.label = _("Scheduled");
            view_icon.gicon = new ThemedIcon ("planner-scheduled");
        } else if (view is Objects.Pinboard) {
            title_label.label = _("Pinboard");
            view_icon.gicon = new ThemedIcon ("planner-pin-tack");
        } else if (view is Objects.Label) {
            title_label.label = ((Objects.Label) view).name;
        }

        // Menu Button
        var menu_image = new Widgets.DynamicIcon ();
        menu_image.size = 21;
        menu_image.update_icon_name ("dots-horizontal");
        
        var menu_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER
            // popover = build_context_menu ()
        };

        menu_button.child = menu_image;
        menu_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        // Add Button
        var add_image = new Widgets.DynamicIcon ();
        add_image.size = 21;
        add_image.update_icon_name ("planner-plus-circle");
        
        var add_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            tooltip_text = _("Add Tasks")
        };

        add_button.child = add_image;
        add_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        // Search Icon
        var search_image = new Widgets.DynamicIcon ();
        search_image.size = 19;
        search_image.update_icon_name ("planner-search");
        
        var search_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER
        };

        search_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        search_button.child = search_image;

        var headerbar = new Adw.HeaderBar () {
            title_widget = new Gtk.Label (null),
            hexpand = true
        };

        headerbar.add_css_class ("flat");
        headerbar.pack_start (sidebar_button);
        headerbar.pack_start (view_icon);
        headerbar.pack_start (title_label);
        headerbar.pack_start (date_label_revealer);
        headerbar.pack_end (menu_button);
        headerbar.pack_end (search_button);
        headerbar.pack_end (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_start = 3,
            margin_end = 3,
            opacity = 0
        });
        headerbar.pack_end (add_button);
        headerbar.pack_end (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_start = 3,
            margin_end = 3,
            opacity = 0
        });

        attach(headerbar, 0, 0);

        add_button.clicked.connect (() => {
            prepare_new_item ();
        });

        search_button.clicked.connect (() => {
            var dialog = new Dialogs.QuickFind.QuickFind ();
            dialog.show ();
        });

        sidebar_button.clicked.connect (() => {
            Planner._instance.main_window.show_hide_sidebar ();
        });
    }

    public void update_today_label () {
        var date = new GLib.DateTime.now_local ();
        date_label.label = "%s %s".printf (date.format ("%a"),
            date.format (
            Granite.DateTime.get_default_date_format (false, true, false)
        ));
        date_label_revealer.reveal_child = true;
    }
}