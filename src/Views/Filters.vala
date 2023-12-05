public class Views.Filters : Gtk.Grid {
    private Layouts.HeaderItem labels_local_header;
    private Layouts.HeaderItem labels_todoist_header;

    public Gee.HashMap <string, Layouts.LabelRow> labels_local_map;
    public Gee.HashMap <string, Layouts.LabelRow> labels_todoist_map;

    construct {
        labels_local_map = new Gee.HashMap <string, Layouts.LabelRow> ();
        labels_todoist_map = new Gee.HashMap <string, Layouts.LabelRow> ();

        var sidebar_image = new Widgets.DynamicIcon ();
        sidebar_image.size = 16;

        if (Services.Settings.get_default ().settings.get_boolean ("slim-mode")) {
            sidebar_image.update_icon_name ("sidebar-left");
        } else {
            sidebar_image.update_icon_name ("sidebar-right");
        }
        
        var sidebar_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER
        };

        sidebar_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        sidebar_button.child = sidebar_image;

        var title_label = new Gtk.Label (_("Labels"));
        title_label.add_css_class ("font-bold");

        // Menu Button
        var menu_image = new Widgets.DynamicIcon ();
        menu_image.size = 16;
        menu_image.update_icon_name ("dots-vertical");
        
        var menu_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER
            // popover = build_context_menu ()
        };

        menu_button.child = menu_image;
        menu_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        // Add Button
        var add_image = new Widgets.DynamicIcon ();
        add_image.size = 16;
        add_image.update_icon_name ("plus");
        
        var add_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            tooltip_text = _("Add To-Do")
        };

        add_button.child = add_image;
        add_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        // add_button.tooltip_markup = Granite.markup_accel_tooltip ({"a"}, _("Add To-Do"));

        // Search Icon
        var search_image = new Widgets.DynamicIcon ();
        search_image.size = 16;
        search_image.update_icon_name ("planner-search");
        
        var search_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER
        };

        search_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        search_button.child = search_image;
        // search_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Control>f"}, _("Quick Find"));
        
        var headerbar = new Adw.HeaderBar () {
            title_widget = new Gtk.Label (null),
            hexpand = true,
            decoration_layout = ":close"
        };

        headerbar.add_css_class ("flat");
        headerbar.pack_start (sidebar_button);
        headerbar.pack_start (title_label);
        headerbar.pack_end (menu_button);
        headerbar.pack_end (search_button);
        
        labels_local_header = new Layouts.HeaderItem (_("Labels: On This Computer"));
        labels_local_header.reveal = true;
        labels_local_header.card = false;
        labels_local_header.show_separator = true;
        labels_local_header.set_sort_func (sort_func);

        labels_todoist_header = new Layouts.HeaderItem (_("Labels: Todoist"));
        labels_todoist_header.reveal = Services.Todoist.get_default ().is_logged_in ();
        labels_todoist_header.card = false;
        labels_todoist_header.show_separator = true;
        labels_todoist_header.set_sort_func (sort_func);

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content.append (labels_local_header);
        content.append (labels_todoist_header);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 1024,
            tightening_threshold = 800,
            margin_start = 24,
            margin_end = 24
        };

        content_clamp.child = content;

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        scrolled_window.child = content_clamp;

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content_box.append (headerbar);
        content_box.append (scrolled_window);

        attach (content_box, 0, 0);
        add_labels ();

        Timeout.add (225, () => {
            labels_local_header.set_sort_func (null);
            labels_todoist_header.set_sort_func (null);
            return GLib.Source.REMOVE;
        });

        labels_local_header.add_activated.connect (() => {
            var dialog = new Dialogs.Label.new (BackendType.LOCAL);
            dialog.show ();
        });

        labels_todoist_header.add_activated.connect (() => {
            var dialog = new Dialogs.Label.new (BackendType.TODOIST);
            dialog.show ();
        });

        sidebar_button.clicked.connect (() => {
            Planner._instance.main_window.show_hide_sidebar ();
        });

        labels_local_header.row_activated.connect ((row) => {
            Services.EventBus.get_default ().pane_selected (PaneType.LABEL, ((Layouts.LabelRow) row).label.id_string);
        });

        labels_todoist_header.row_activated.connect ((row) => {
            Services.EventBus.get_default ().pane_selected (PaneType.LABEL, ((Layouts.LabelRow) row).label.id_string);
        });

        Services.Database.get_default ().label_added.connect ((label) => {
            add_label (label);
        });

        Services.Database.get_default ().label_deleted.connect ((label) => {
            if (labels_local_map.has_key (label.id)) {
                labels_local_map[label.id].hide_destroy ();
                labels_local_map.unset (label.id);
            }

            if (labels_todoist_map.has_key (label.id)) {
                labels_todoist_map[label.id].hide_destroy ();
                labels_todoist_map.unset (label.id);
            }
        });

        Services.Todoist.get_default ().log_in.connect (() => {
            labels_todoist_header.reveal = Services.Todoist.get_default ().is_logged_in ();
        });


        Services.Todoist.get_default ().log_out.connect (() => {
            labels_todoist_header.reveal = Services.Todoist.get_default ().is_logged_in ();
        });
    }

    private void add_labels () {
        foreach (Objects.Label label in Services.Database.get_default ().labels) {
            add_label (label);
        }
    }

    private int sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
        Objects.Label label1 = ((Layouts.LabelRow) lbrow).label;
        Objects.Label label2 = ((Layouts.LabelRow) lbbefore).label;
        return label1.item_order - label2.item_order;
    }

    private void add_label (Objects.Label label) {
        if (label.backend_type == BackendType.LOCAL) {
            if (!labels_local_map.has_key (label.id)) {
                labels_local_map[label.id] = new Layouts.LabelRow (label); 
                labels_local_header.add_child (labels_local_map[label.id]);
            }
        }
        
        if (label.backend_type == BackendType.TODOIST) {
            if (!labels_todoist_map.has_key (label.id)) {
                labels_todoist_map[label.id] = new Layouts.LabelRow (label); 
                labels_todoist_header.add_child (labels_todoist_map[label.id]);
            }
        }
    }
}
