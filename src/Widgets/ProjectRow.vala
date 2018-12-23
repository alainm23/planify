public class Widgets.ProjectRow : Gtk.ListBoxRow {
    private Gtk.Box main_box;
    public bool menu_open = false;

    private Gtk.Label name_label;
    private Gtk.Entry name_entry;
    private Gtk.Label number_label;
    public Objects.Project project { get; construct; }
    public MainWindow window { get; construct; }
    /*
    private const Gtk.TargetEntry targetEntriesProjectRow [] = {
		{ "ProjectRow", Gtk.TargetFlags.SAME_APP, 0 }
	};
    */
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
        name_label.use_markup = true;

        name_entry = new Gtk.Entry ();
        name_entry.valign = Gtk.Align.CENTER;
        name_entry.expand = true;
        name_entry.max_length = 50;
        name_entry.text = project.name;
        name_entry.no_show_all = true;
        name_entry.placeholder_text = _("Project name");

        var menu_button = new Gtk.ToggleButton ();
        menu_button.can_focus = false;
        menu_button.add (new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.MENU));
        menu_button.tooltip_text = _("Menu");
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        menu_button.get_style_context ().add_class ("settings-button");
        menu_button.get_style_context ().add_class ("menu-button");

        var menu_revealer = new Gtk.Revealer ();
        menu_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        menu_revealer.add (menu_button);
        menu_revealer.reveal_child = false;

        var menu_popover = new Widgets.Popovers.ProjectMenu (menu_button);

        number_label = new Gtk.Label (null);
        number_label.valign = Gtk.Align.CENTER;

        main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        main_box.margin = 6;

        main_box.pack_start (label_color, false, false, 0);
        main_box.pack_start (name_label, false, true, 0);
        main_box.pack_start (name_entry, false, true, 0);
        main_box.pack_end (menu_revealer, false, false, 0);
        main_box.pack_end (number_label, false, false, 0);

        var eventbox = new Gtk.EventBox ();
        eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        eventbox.add (main_box);

        add (eventbox);
        apply_styles ();
        update_tooltip_text ();
        check_number_label ();
        //build_drag_and_drop ();

        show_all ();

        // Signals
        Application.database.update_indicators.connect (() => {
            check_number_label ();
        });

        menu_button.toggled.connect (() => {
            if (menu_button.active) {
                menu_open = true;
                menu_popover.show_all ();
            }
        });

        menu_popover.closed.connect (() => {
            menu_open = false;
            menu_button.active = false;
            menu_revealer.reveal_child = false;
        });

        menu_popover.on_selected_menu.connect((index) => {
            if (index == 0) {
                int tasks_number = Application.database.get_project_no_completed_tasks_number (project.id);

                var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                    _("Are you sure you want to mark as completed this project?"),
                    _("This project contains %i incomplete tasks".printf (tasks_number)),
                    "dialog-warning",
                Gtk.ButtonsType.CANCEL);

                var remove_button = new Gtk.Button.with_label (_("Mark as Completed"));
                remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

                message_dialog.show_all ();

                if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                    var all_tasks = new Gee.ArrayList<Objects.Task?> ();
                    all_tasks = Application.database.get_all_tasks_by_project (project.id);

                    foreach (var task in all_tasks) {
                        task.checked = 1;
                        if (Application.database.update_task (task) == Sqlite.DONE) {
                            Application.database.update_task_signal (task);
                        }
                    }
                }

                message_dialog.destroy ();
            } else if (index == 1) {
                name_label.visible = false;
                name_entry.visible = true;

                Timeout.add_seconds (200, () => {
				    name_entry.grab_focus ();
				    return false;
			    });
            } else if (index == 2) {
                // Share project
                var share_dialog = new Dialogs.ShareDialog (Application.instance.main_window);
                share_dialog.project = project.id;
                share_dialog.destroy.connect (Gtk.main_quit);
                share_dialog.show_all ();
            } else if (index == 3) {
                int tasks_number = Application.database.get_project_tasks_number (project.id);
                // Algoritmo para saber si hay o no tareas y si es plural o singular

                var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                    _("Are you sure you want to delete this project?"),
                    _("It contains %i elements that are also deleted, this operation can be undone".printf (tasks_number)),
                    "dialog-warning",
                Gtk.ButtonsType.CANCEL);

                var remove_button = new Gtk.Button.with_label (_("Delete Project"));
                remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

                message_dialog.show_all ();

                if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                    if (Application.database.remove_project (project.id) == Sqlite.DONE) {
                        GLib.Timeout.add (250, () => {
                            destroy ();
                            return GLib.Source.REMOVE;
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
                menu_revealer.reveal_child = true;
            }

            return false;
        });

        eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            if (menu_open != true) {
                menu_revealer.reveal_child = false;
            }

            return false;
        });

        Application.database.update_project_signal.connect ((_project) => {
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

            if (Application.database.update_project (project) == Sqlite.DONE) {
                name_label.label = "<b>%s</b>".printf(project.name);
                update_tooltip_text ();

                name_label.visible = true;
                name_entry.visible = false;
            }
        }
    }

    private void update_tooltip_text () {
        int all_tasks = Application.database.get_project_tasks_number (project.id);
        int completed_tasks = Application.database.get_project_completed_tasks_number (project.id);

        set_tooltip_text (project.name + " %i/%i".printf (completed_tasks, all_tasks));
        show_all ();
    }

    private void check_number_label () {
        int number = Application.database.get_project_no_completed_tasks_number (project.id);
        number_label.label = number.to_string ();

        update_tooltip_text ();

        if (number <= 0) {
            number_label.visible = false;
            number_label.no_show_all = true;
        } else {
            number_label.visible = true;
            number_label.no_show_all = false;
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
