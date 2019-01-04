/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Dialogs.ShareDialog : Gtk.Dialog {
    private Gtk.SourceView source_view;

    public int project {
        set {
            var project = Application.database.get_project (value);
            var tasks = Application.database.get_all_tasks_by_project (value);
            source_view.buffer.text = "";

            add_line ("# %s".printf (project.name));
            add_line ("");

            if (project.note != "") {
                add_line ("%s".printf (project.note));
                add_line ("");
            }

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

            add_line ("# %s".printf (_("Inbox")));
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

            add_line ("# %s".printf (_("Today")));
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

            add_line ("# %s".printf (_("Upcoming")));
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

    public int task {
        set {
            var _task = Application.database.get_task (value);
            source_view.buffer.text = "";

            if (_task.when_date_utc == "") {
                add_line ("# %s".printf (_task.content));
            } else {
                add_line ("# [%s] %s".printf (Application.utils.get_default_date_format (_task.when_date_utc), _task.content));
            }

            add_line ("");

            if (_task.note != "") {
                add_line ("%s".printf (_task.note));
                add_line ("");
            }

            string[] checklist_array = _task.checklist.split (";");

            foreach (string str in checklist_array) {
                if (str != "") {
                    string check_name = str.substring (1, -1);

                    if (str.substring (0, 1) == "0") {
                        add_line ("- [ ] %s".printf (check_name));
                    } else {
                        add_line ("- [x] %s".printf (check_name));
                    }
                }
    	    }
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
        source_view.margin = 6;
        //source_view.wrap_mode = Gtk.WrapMode.WORD;
        source_view.monospace = true;
        source_view.expand = true;

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.add (source_view);

        var main_frame = new Gtk.Frame (null);
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (scrolled_window);

        var content_grid = new Gtk.Grid ();
        content_grid.margin_start = 12;
        content_grid.margin_end = 12;
        content_grid.margin_bottom = 6;
        content_grid.orientation = Gtk.Orientation.VERTICAL;
        content_grid.add (main_frame);

        ((Gtk.Container) get_content_area ()).add (content_grid);

        var close_button = new Gtk.Button.with_label (_("Close"));
        close_button.valign = Gtk.Align.END;
        close_button.get_style_context ().add_class ("suggested-action");
        close_button.margin_bottom = 6;
        close_button.margin_end = 6;

        close_button.clicked.connect (() => {
			destroy ();
		});

        var copy_button = new Gtk.Button.with_label (_("Copy to clipboard"));
        copy_button.valign = Gtk.Align.END;
        copy_button.margin_bottom = 6;
        copy_button.margin_end = 6;

        copy_button.clicked.connect (() => {
            Gdk.Display display = Gdk.Display.get_default ();
            Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);

            clipboard.set_text (source_view.buffer.text, -1);

            Application.notification.send_local_notification (
                _("Your project is ready to share"),
                _("Copy to clipboard"),
                "edit-copy",
                4,
                false
            );

            destroy ();
        });

        add_action_widget (copy_button, 0);
        add_action_widget (close_button, 1);
    }

    private void add_line (string text) {
        source_view.buffer.text = source_view.buffer.text + "%s\n".printf (text);
    }
}
