public class Layouts.ViewHeader : Hdy.HeaderBar {
    public Objects.BaseObject view { get; set; }

    private Gtk.Label title_label;
    private Gtk.Revealer title_revealer;
    private Gtk.Revealer end_revealer;

    private Gtk.Button view_button;
    private Gtk.Button menu_button;

    construct {
        var sidebar_image = new Widgets.DynamicIcon ();
        sidebar_image.size = 19;
        sidebar_image.update_icon_name ("sidebar-left");
        
        var sidebar_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        sidebar_button.add (sidebar_image);

        unowned Gtk.StyleContext sidebar_button_context = sidebar_button.get_style_context ();
        sidebar_button_context.add_class (Gtk.STYLE_CLASS_FLAT);

        var start_grid = new Gtk.Grid () {
            column_spacing = 6
        };

        start_grid.add (sidebar_button);

        title_label = new Gtk.Label (null);
        title_label.valign = Gtk.Align.CENTER;

        unowned Gtk.StyleContext title_label_context = title_label.get_style_context ();
        title_label_context.add_class ("h4");
        title_label_context.add_class ("opacity-1");

        title_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE
        };
        title_revealer.add (title_label);

        var menu_image = new Widgets.DynamicIcon ();
        menu_image.size = 19;
        menu_image.update_icon_name ("dots-horizontal");
        
        menu_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        menu_button.add (menu_image);
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var view_image = new Widgets.DynamicIcon ();
        view_image.size = 19;
        view_image.update_icon_name ("planner-settings-sliders");
        
        view_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        view_button.add (view_image);
        view_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

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

        var end_grid = new Gtk.Grid () {
            column_spacing = 0,
            margin_end = 0
        };

        end_grid.add (search_button);
        end_grid.add (view_button);
        end_grid.add (menu_button);

        end_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE
        };
        end_revealer.add (end_grid);

        pack_start (start_grid);
        custom_title = title_revealer;
        pack_end (end_revealer);

        notify["view"].connect (() => {
            title_revealer.reveal_child = false;
            end_revealer.reveal_child = false;

            menu_button.clicked.disconnect (((Objects.Project) view).build_content_menu);
            view_button.clicked.disconnect (((Objects.Project) view).build_view_menu);

            if (view is Objects.Project) {
                title_label.label = ((Objects.Project) view).name;
                menu_button.clicked.connect (((Objects.Project) view).build_content_menu);
                view_button.clicked.connect (((Objects.Project) view).build_view_menu);
            } else if (view is Objects.Today) {
                title_label.label = _("Today");
            } else if (view is Objects.Scheduled) {
                title_label.label = _("Scheduled");
            } else if (view is Objects.Pinboard) {
                title_label.label = _("Pinboard");
            } else if (view is Objects.Label) {
                title_label.label = ((Objects.Label) view).name;
            }
        });

        sidebar_button.clicked.connect (() => {
            Planner.instance.main_window.show_hide_sidebar ();
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "slim-mode") {
                if (Planner.settings.get_boolean ("slim-mode")) {
                    sidebar_image.update_icon_name ("sidebar-left");
                } else {
                    sidebar_image.update_icon_name ("sidebar-right");
                }   
            }
        });

        Planner.event_bus.view_header.connect ((reveal_child) => {
            title_revealer.reveal_child = reveal_child;
            end_revealer.reveal_child = reveal_child;

            if (view is Objects.Project) {
                view_button.visible = true;
                menu_button.visible = true;

                view_button.show_all ();
                menu_button.show_all ();
            } else {
                view_button.visible = false;
                menu_button.visible = false;
            }
        });
    }
}
