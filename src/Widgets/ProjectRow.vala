public class Widgets.ProjectRow : Gtk.ListBoxRow {
    private Gtk.Grid main_grid;
    public bool menu_open = false;

    private Gtk.Label name_label;
    private Gtk.Entry name_entry;

    public Objects.Project project { get; construct; }
    public MainWindow window { get; construct; }

    private const Gtk.TargetEntry targetEntriesProjectRow [] = {
		{ "ProjectRow", Gtk.TargetFlags.SAME_APP, 0 }
	};

    public const string COLOR_CSS = """
        .proyect-%i {
            color: %s;
        }
    """;

    public ProjectRow (Objects.Project _objec) {
        Object (
            project: _objec,
            margin_left: 6,
            margin_top: 6,
            margin_right: 6
        );
    }

    construct {
        can_focus = true;
        get_style_context ().add_class ("item-row");

        var label_color = new Gtk.Image ();
        label_color.gicon = new ThemedIcon ("mail-unread-symbolic");
        label_color.get_style_context ().add_class ("proyect-%i".printf (project.id));
        label_color.pixel_size = 24;

        name_label = new Gtk.Label ("<b>%s</b>".printf(project.name));
        name_label.ellipsize = Pango.EllipsizeMode.END;
        name_label.valign = Gtk.Align.CENTER;
        name_label.halign = Gtk.Align.START;
        name_label.use_markup = true;

        name_entry = new Gtk.Entry ();
        name_entry.valign = Gtk.Align.CENTER;
        name_entry.expand = true;
        name_entry.max_length = 50;
        name_entry.text = project.name;
        name_entry.no_show_all = true;
        name_entry.placeholder_text = _("Project name");

        var settings_button = new Gtk.ToggleButton ();
        settings_button.add (new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.MENU));
        settings_button.tooltip_text = _("Settings");
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        settings_button.get_style_context ().add_class ("settings-button");

        var settings_revealer = new Gtk.Revealer ();
        settings_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        settings_revealer.add (settings_button);
        settings_revealer.reveal_child = false;
        settings_revealer.hexpand = true;
        settings_revealer.halign = Gtk.Align.END;

        var menu_popover = new Widgets.Popovers.ProjectMenu (settings_button);

        main_grid = new Gtk.Grid ();
        main_grid.column_spacing = 12;
        main_grid.row_spacing = 3;
        main_grid.margin = 6;

        main_grid.add (label_color);
        main_grid.add (name_label);
        main_grid.add (name_entry);
        main_grid.add (settings_revealer);

        var eventbox = new Gtk.EventBox ();
        eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        eventbox.add (main_grid);

        add (eventbox);
        apply_styles ();
        //build_drag_and_drop ();

        show_all ();

        // Event
        settings_button.toggled.connect (() => {
            if (settings_button.active) {
                menu_open = true;
                menu_popover.show_all ();
            }
        });

        menu_popover.closed.connect (() => {
            menu_open = false;
            settings_button.active = false;
        });

        menu_popover.on_selected_menu.connect((index) => {
            if (index == 2) {
                name_label.visible = false;
                name_entry.visible = true;

                Timeout.add_seconds (200, () => {
				    name_entry.grab_focus ();
				    return false;
			    });
            } else if (index == 4) {
                var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                    _("Are you sure you want to delete this project?"),
                    _("It contains 26 elements that are also deleted, this operation can be undone"),
                    "dialog-warning",
                Gtk.ButtonsType.CANCEL);

                var remove_button = new Gtk.Button.with_label (_("Remove"));
                remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

                message_dialog.show_all ();

                if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                    project.is_deleted = 1;

                    if (Planner.database.update_project (project) == Sqlite.DONE) {
                        Timeout.add (20, () => {
                            this.opacity = this.opacity - 0.1;

                            if (this.opacity <= 0) {
                                hide ();
                                return false;
                            }

                            return true;
                        });
                    }
                }

                message_dialog.destroy ();
            }
        });

        eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                name_label.visible = false;
                name_entry.visible = true;

                Timeout.add (200, () => {
				    name_entry.grab_focus ();
				    return false;
			    });
            }

            return false;
        });

        name_entry.activate.connect (() =>{
            update_project ();
        });

        name_entry.focus_out_event.connect (() => {
            update_project ();
            return false;
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                update_project ();
            }

            return false;
        });

        eventbox.enter_notify_event.connect ((event) => {
            if (menu_open != true) {
                settings_revealer.reveal_child = true;
            }

            return false;
        });

        eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            if (menu_open != true) {
                settings_revealer.reveal_child = false;
            }

            return false;
        });

        Planner.database.update_project_signal.connect ((_project) => {
            if (project.id == _project.id) {
                name_label.label = "<b>%s</b>".printf(_project.name);
                project.color = _project.color;

                apply_styles ();
            }
        });
    }

    private void apply_styles () {
        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (
                project.id,
                project.color
            );

            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }

    private void update_project () {
        if (name_entry.text != "") {
            project.name = name_entry.text;

            if (Planner.database.update_project (project) == Sqlite.DONE) {
                name_label.label = "<b>%s</b>".printf(name_entry.text);

                name_label.visible = true;
                name_entry.visible = false;
            }
        }
    }

    /*
    private void build_drag_and_drop () {
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, targetEntriesProjectRow, Gdk.DragAction.MOVE);

        drag_begin.connect (on_drag_begin);
        //get.Gtk (this, Gtk.DestDefaults.MOTION, targetEntriesProjectRow, Gdk.DragAction.MOVE);
        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = (widget as Widgets.ProjectRow);

        Gtk.Allocation alloc;
		row.get_allocation (out alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr = new Cairo.Context (surface);
		cr.set_source_rgba (0, 0, 0, 0.3);
		cr.set_line_width (1);

        cr.move_to (0, 0);
		cr.line_to (alloc.width, 0);
		cr.line_to (alloc.width, alloc.height);
		cr.line_to (0, alloc.height);
		cr.line_to (0, 0);
		cr.stroke ();

        cr.set_source_rgba (255, 255, 255, 0.5);
		cr.rectangle (0, 0, alloc.width, alloc.height);
		cr.fill ();

        row.main_grid.draw (cr);

		Gtk.drag_set_icon_surface (context, surface);
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        get_style_context ().add_class ("highlight");
        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
		get_style_context ().remove_class ("highlight");
	}
    */
}
