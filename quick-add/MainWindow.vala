public class MainWindow : Adw.ApplicationWindow {
    public Objects.Item item { get; set; }

    private Gtk.CheckButton checked_button;
    private Gtk.Entry content_entry;
    private Widgets.LoadingButton submit_button;
    private Widgets.HyperTextView description_textview;
    private Widgets.IconColorProject icon_project;
    private Gtk.Label name_label;
    private Gtk.Image added_image;
    private Gtk.Stack main_stack;

    public MainWindow (QuickAdd application) {
        Object (
            application: application,
            icon_name: "io.github.alainm23.planify",
            title: _("Planify - Quick Add"),
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
        item.project_id = Services.Settings.get_default ().settings.get_string ("inbox-project-id");

        checked_button = new Gtk.CheckButton () {
            valign = Gtk.Align.CENTER
        };

        checked_button.add_css_class ("priority-color");

        content_entry = new Gtk.Entry () {
            hexpand = true,
            placeholder_text = _("To-do name")
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
        quick_add_content.append (action_box);

        submit_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Add To-do"));
        submit_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
        submit_button.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        submit_button.add_css_class ("border-radius-6");
        submit_button.add_css_class ("action-button");

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        cancel_button.add_css_class ("border-radius-6");
        cancel_button.add_css_class ("action-button");

        icon_project = new Widgets.IconColorProject (19);

        name_label = new Gtk.Label (null);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

        var project_box = new Gtk.Box (HORIZONTAL, 6) {
            valign = CENTER
        };
        project_box.append (icon_project);
        project_box.append (name_label);

        var project_picker = new Widgets.ProjectPicker ();

        var project_button = new Gtk.MenuButton () {
            hexpand = true,
            halign = END,
            margin_end = 12,
            margin_bottom = 12,
            popover = project_picker,
            child = project_box
        };

        project_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        var submit_cancel_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_bottom = 12,
            margin_start = 12,
            halign = Gtk.Align.START,
            homogeneous = true
        };
        submit_cancel_grid.append (cancel_button);
        submit_cancel_grid.append (submit_button);
        
        var footer_content = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true
        };

        footer_content.append (submit_cancel_grid);
        footer_content.append (project_button);

        var main_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_content.append (quick_add_content);
        main_content.append (footer_content);

        var warning_image = new Gtk.Image ();
        warning_image.gicon = new ThemedIcon ("dialog-warning");
        warning_image.pixel_size = 32;

        var warning_label = new Gtk.Label (_("I'm sorry, Quick Add can't find any project available, try creating a project from Planify."));
        warning_label.wrap = true;
        warning_label.max_width_chars = 42;
        warning_label.xalign = 0;

        var warning_box = new Gtk.Box (HORIZONTAL, 12) {
            margin_start = 12
        };
        warning_box.halign = Gtk.Align.CENTER;
        warning_box.valign = Gtk.Align.CENTER;
        warning_box.append (warning_image);
        warning_box.append (warning_label);

        main_stack = new Gtk.Stack () {
            hexpand = true,
            vexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        added_image = new Gtk.Image ();
        added_image.gicon = new ThemedIcon ("planner-completed");
        added_image.pixel_size = 64;

        var added_label = new Gtk.Label (_("To-do added"));

        var added_box = new Gtk.Box (VERTICAL, 0);
        added_box.halign = Gtk.Align.CENTER;
        added_box.valign = Gtk.Align.CENTER;
        added_box.append (added_image);
        added_box.append (added_label);

        main_stack.add_named (main_content, "main");
        main_stack.add_named (warning_box, "warning");
        main_stack.add_named (added_box, "added");

        var window = new Gtk.WindowHandle ();
        window.set_child (main_stack);

        set_content (window);
        update_project_request ();

        Timeout.add (225, () => {
            if (Services.Database.get_default ().is_database_empty ()) {
                main_stack.visible_child_name = "warning";
            } else {
                main_stack.visible_child_name = "main";
                content_entry.grab_focus ();
            }

            return GLib.Source.REMOVE;
        });

        var granite_settings = Granite.Settings.get_default ();
        granite_settings.notify["prefers-color-scheme"].connect (() => {
            if (Services.Settings.get_default ().settings.get_boolean ("system-appearance")) {
                Services.Settings.get_default ().settings.set_boolean (
                    "dark-mode",
                    granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
                );
                Util.get_default ().update_theme ();
            }
        });

        Services.Settings.get_default ().settings.changed.connect ((key) => {
            if (key == "system-appearance") {
                Services.Settings.get_default ().settings.set_boolean (
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

        project_picker.selected.connect ((project) => {
            item.project_id = project.id;
            update_project_request ();
        });
    }

    private void add_item () {        
        if (content_entry.buffer.text.length <= 0) {
            hide_destroy ();
            return;
        }

        item.content = content_entry.get_text ();
        item.description = description_textview.get_text ();
        
        if (item.project.backend_type == BackendType.TODOIST) {
            submit_button.is_loading = true;
            Services.Todoist.get_default ().add.begin (item, (obj, res) => {
                string? id = Services.Todoist.get_default ().add.end (res);
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
            main_stack.visible_child_name = "added";
            added_image.add_css_class ("fancy-turn-animation");

            Timeout.add (750, () => {
                hide_destroy ();
                return GLib.Source.REMOVE;
            });
        }  
    }

    private void send_interface_id (string id) {
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

    public void update_project_request () {
        name_label.label = item.project.is_inbox_project ? _("Inbox") : item.project.name;
        icon_project.project = item.project;
        icon_project.update_request ();
    }
}