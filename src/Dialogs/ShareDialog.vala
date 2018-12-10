public class Dialogs.ShareDialog : Gtk.Dialog {
    private Gtk.SourceView source_view;

    public int project {
        set {
            var project = Application.database.get_project (value);
            var tasks = Application.database.get_all_tasks_by_project (value);
            source_view.buffer.text = "";

            add_line ("# %s".printf (project.name));
            add_line ("");
            add_line ("%s".printf (project.note));
            add_line ("");

            foreach (var task in tasks) {
                if (task.checked != 1) {
                    if (task.when_date_utc == "") {
                        add_line ("- [ ] %s".printf (task.content));
                    } else {
                        add_line ("- [ ] [%s] %s".printf (Application.utils.get_default_date_format (task.when_date_utc), task.content));
                    }
                }
            }

            show_all ();
        }
    }

    public bool inbox {
        set {
            source_view.buffer.text = "";

            add_line ("# %s".printf (Application.utils.INBOX_STRING));
            add_line ("");

            var tasks = Application.database.get_all_inbox_tasks ();

            foreach (var task in tasks) {
                if (task.checked != 1) {
                    if (task.when_date_utc == "") {
                        add_line ("- [ ] %s".printf (task.content));
                    } else {
                        add_line ("- [ ] [%s] %s".printf (Application.utils.get_default_date_format (task.when_date_utc), task.content));
                    }
                }
            }

            show_all ();
        }
    }

    public bool today {
        set {
            source_view.buffer.text = "";

            add_line ("# %s".printf (Application.utils.TODAY_STRING));
            add_line ("");

            var tasks = Application.database.get_all_today_tasks ();

            foreach (var task in tasks) {
                if (task.checked != 1) {
                    add_line ("- [ ] [%s] %s".printf (Application.utils.get_default_date_format (task.when_date_utc), task.content));
                }
            }

            show_all ();
        }
    }

    public bool upcoming {
        set {
            source_view.buffer.text = "";

            add_line ("# %s".printf (Application.utils.UPCOMING_STRING));
            add_line ("");

            var tasks = Application.database.get_all_upcoming_tasks ();
            tasks.sort ((task_1, task_2) => {
                var date1 = new GLib.DateTime.from_iso8601 (task_1.when_date_utc, new GLib.TimeZone.local ());
                var date2 = new GLib.DateTime.from_iso8601 (task_2.when_date_utc, new GLib.TimeZone.local ());

                return date1.compare (date2);
            });

            foreach (var task in tasks) {
                if (task.checked != 1) {
                    add_line ("- [ ] [%s] %s".printf (Application.utils.get_default_date_format (task.when_date_utc), task.content));
                }
            }

            show_all ();
        }
    }

    public ShareDialog (MainWindow parent) {
        Object (
            transient_for: parent,
            deletable: false,
            resizable: false,
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT
        );
	}

    construct {
        title = _("Share");
        set_size_request (640, 494);

        source_view = new Gtk.SourceView ();
        source_view.get_style_context ().add_class ("share-view");
        source_view.monospace = true;
        source_view.expand = true;

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.add (source_view);

        var content_grid = new Gtk.Grid ();
        content_grid.margin_start = 12;
        content_grid.margin_end = 12;
        content_grid.orientation = Gtk.Orientation.VERTICAL;
        content_grid.add (scrolled_window);

        ((Gtk.Container) get_content_area ()).add (content_grid);

        var close_button = new Gtk.Button.with_label (_("Close"));
        close_button.valign = Gtk.Align.END;
        close_button.get_style_context ().add_class ("suggested-action");
        close_button.margin_bottom = 6;
        close_button.margin_end = 6;

        close_button.clicked.connect (() => {
			destroy ();
		});

        var copy_button = new Gtk.Button.with_label (_("Copy"));
        copy_button.valign = Gtk.Align.END;
        copy_button.margin_bottom = 6;
        copy_button.margin_end = 6;

        copy_button.clicked.connect (() => {
            Gdk.Display display = Gdk.Display.get_default ();
            Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);

            clipboard.set_text (source_view.buffer.text, -1);
        });

        add_action_widget (copy_button, 1);
        add_action_widget (close_button, 0);
    }

    private void add_line (string text) {
        source_view.buffer.text = source_view.buffer.text + "%s\n".printf (text);
    }
}
