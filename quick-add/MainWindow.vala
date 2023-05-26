public class MainWindow : Adw.ApplicationWindow {
    public Objects.Item item { get; set; }

    private Gtk.CheckButton checked_button;
    private Gtk.Entry content_entry;
    private Widgets.LoadingButton submit_button;
    private Widgets.HyperTextView description_textview;

    private Widgets.ScheduleButton schedule_button;

    public MainWindow (Planner application) {
        Object (
            application: application,
            icon_name: "io.github.alainm23.planify",
            title: _("Task Planner - Quick Add"),
            width_request: 500,
            resizable: false
        );
    }

    static construct {
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_for_display (Gdk.Display.get_default ());
        default_theme.add_resource_path ("/io/github/alainm23/planify");
    }

    construct {
        item = new Objects.Item ();
        
        checked_button = new Gtk.CheckButton () {
            valign = Gtk.Align.CENTER
        };

        checked_button.add_css_class ("priority-color");

        content_entry = new Gtk.Entry () {
            hexpand = true,
            placeholder_text = _("Task name")
        };

        content_entry.add_css_class (Granite.STYLE_CLASS_FLAT);

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_top = 12,
            margin_start = 12,
            margin_end = 12
        };
        content_box.append (checked_button);
        content_box.append (content_entry);

        description_textview = new Widgets.HyperTextView (_("Add a description…")) {
            height_request = 64,
            left_margin = 39,
            right_margin = 6,
            top_margin = 6,
            bottom_margin = 12,
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
            hexpand = true
        };

        description_textview.remove_css_class ("view");

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            margin_start = 31,
            margin_top = 6,
            margin_bottom = 6,
            hexpand = true
        };

        schedule_button = new Widgets.ScheduleButton ();

        action_box.append (schedule_button);

        var quick_add_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12,
            vexpand = true
        };
        quick_add_content.add_css_class (Granite.STYLE_CLASS_CARD);
        quick_add_content.append (content_box);
        quick_add_content.append (description_textview);
        // quick_add_content.add (item_labels);
        quick_add_content.append (action_box);

        submit_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Add Task"));
        submit_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
        submit_button.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        submit_button.add_css_class ("border-radius-6");
        submit_button.add_css_class ("action-button");

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        cancel_button.add_css_class ("border-radius-6");
        cancel_button.add_css_class ("action-button");
        
        var submit_cancel_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_bottom = 12,
            margin_start = 12,
            halign = Gtk.Align.START,
            homogeneous = true
        };
        submit_cancel_grid.append (cancel_button);
        submit_cancel_grid.append (submit_button);

        var main_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_content.append (quick_add_content);
        main_content.append (submit_cancel_grid);

        var window = new Gtk.WindowHandle ();
        window.set_child (main_content);

        set_content (window);

        var granite_settings = Granite.Settings.get_default ();
        granite_settings.notify["prefers-color-scheme"].connect (() => {
            if (Planner.settings.get_boolean ("system-appearance")) {
                Planner.settings.set_boolean (
                    "dark-mode",
                    granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
                );
                Util.get_default ().update_theme ();
            }
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "system-appearance") {
                Planner.settings.set_boolean (
                    "dark-mode",
                    granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
                );
                Util.get_default ().update_theme ();
            } else if (key == "appearance" || key == "dark-mode") {
                Util.get_default ().update_theme ();
            }
        });

        content_entry.activate.connect (add_item);
        submit_button.clicked.connect (add_item);
        cancel_button.clicked.connect (hide_destroy);

        schedule_button.date_changed.connect ((datetime) => {
            update_due (datetime);
        });
    }

    public void update_due (GLib.DateTime? datetime) {
        item.due.date = datetime == null ? "" : Util.get_default ().get_todoist_datetime_format (datetime);

        if (item.due.date == "") {
            item.due.reset ();
        }

        schedule_button.update_from_item (item);
    }

    private void add_item () {        
        if (content_entry.buffer.text.length <= 0) {
            hide_destroy ();
            return;
        }

        item.content = content_entry.get_text ();
        item.description = description_textview.get_text ();
        item.project_id = Planner.settings.get_int64 ("inbox-project-id");
        
        if (item.project.backend_type == BackendType.TODOIST) {
            submit_button.is_loading = true;
            Services.Todoist.get_default ().add.begin (item, (obj, res) => {
                int64? id = Services.Todoist.get_default ().add.end (res);
                if (id != null) {
                    item.id = id;
                    add_item_db (item);
                }
            });
        } else if (item.project.backend_type == BackendType.LOCAL) {
             item.id = Util.get_default ().generate_id ();
             add_item_db (item);
        }
    }
    
    private void add_item_db (Objects.Item item) {
        if (Services.Database.get_default ().insert_item (item)) {
            send_interface_id (item.id);
            hide_destroy ();
        }  
    }

    private void send_interface_id (int64 id) {
        try {
            DBusClient.get_default ().interface.add_item (id);
        } catch (Error e) {
            debug (e.message);
        }
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}