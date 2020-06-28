/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alainmh23@gmail.com>
*/

public class MainWindow : Gtk.Window {
    private const string TODAY = _("today");
    private const string TOMORROW = _("tomorrow");

    private Gtk.Stack stack;
    private Gtk.Entry content_entry;

    private DBusClient dbus_client;
    private Gtk.ComboBox project_combobox;
    private Gtk.ListStore list_store;
    private bool entry_menu_opened = false;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            resizable: false,
            width_request: 700,
            window_position: Gtk.WindowPosition.CENTER,
            margin_bottom: 192
        );
    }

    construct {
        dbus_client = DBusClient.get_default ();

        var headerbar = new Gtk.HeaderBar ();
        headerbar.has_subtitle = false;
        headerbar.set_show_close_button (true);
        headerbar.decoration_layout = ":";

        unowned Gtk.StyleContext headerbar_style_context = headerbar.get_style_context ();
        headerbar_style_context.add_class (Gtk.STYLE_CLASS_FLAT);

        var checked_button = new Gtk.CheckButton ();
        checked_button.margin_start = 7;
        checked_button.can_focus = false;
        checked_button.valign = Gtk.Align.CENTER;
        checked_button.halign = Gtk.Align.BASELINE;
        checked_button.get_style_context ().add_class ("checklist-button");

        content_entry = new Gtk.Entry ();
        content_entry.margin_bottom = 1;
        content_entry.placeholder_text = _("Task name");
        content_entry.get_style_context ().add_class ("flat");
        content_entry.get_style_context ().add_class ("content-entry");
        content_entry.hexpand = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
        top_box.get_style_context ().add_class ("check-grid");
        top_box.margin_start = 16;
        top_box.margin_end = 16;
        top_box.hexpand = true;
        top_box.pack_start (checked_button, false, false, 0);
        top_box.pack_start (content_entry, false, true, 0);

        var submit_button = new Gtk.Button ();
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var submit_spinner = new Gtk.Spinner ();
        submit_spinner.start ();

        var submit_stack = new Gtk.Stack ();
        submit_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        submit_stack.add_named (new Gtk.Label (_("Save")), "label");
        submit_stack.add_named (submit_spinner, "spinner");

        submit_button.add (submit_stack);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("view");

        var action_grid = new Gtk.Grid ();
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 6;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        list_store = new Gtk.ListStore (3, typeof (Project), typeof (string), typeof (string));
        project_combobox = new Gtk.ComboBox.with_model (list_store);
        project_combobox.can_focus = false;
        project_combobox.get_style_context ().add_class ("quick-add-combobox");
        project_combobox.valign = Gtk.Align.CENTER;

        Gtk.TreeIter inbox_iter;
        list_store.append (out inbox_iter);

        var inbox_project = PlannerQuickAdd.database.get_project_by_id (PlannerQuickAdd.settings.get_int64 ("inbox-project"));
        list_store.@set (inbox_iter,
            0, inbox_project,
            1, " " + _("Inbox"),
            2, "planner-inbox"
        );

        if (PlannerQuickAdd.settings.get_boolean ("quick-add-save-last-project") == false) {
            project_combobox.set_active_iter (inbox_iter);
        }

        Gtk.TreeIter iter;
        foreach (var project in PlannerQuickAdd.database.get_all_projects ()) {
            list_store.append (out iter);

            list_store.@set (iter,
                0, project,
                1, " " + project.name,
                2, "color-%i".printf (project.color)
            );

            if (PlannerQuickAdd.settings.get_boolean ("quick-add-save-last-project") == true &&
                PlannerQuickAdd.settings.get_int64 ("quick-add-project-selected") == 0) {
                project_combobox.set_active_iter (inbox_iter);
            }

            if (PlannerQuickAdd.settings.get_boolean ("quick-add-save-last-project") == true &&
                PlannerQuickAdd.settings.get_int64 ("quick-add-project-selected") == project.id) {
                project_combobox.set_active_iter (iter);
            }
        }

        var pixbuf_cell = new Gtk.CellRendererPixbuf ();
        project_combobox.pack_start (pixbuf_cell, false);
        project_combobox.add_attribute (pixbuf_cell, "icon-name", 2);

        var text_cell = new Gtk.CellRendererText ();
        project_combobox.pack_start (text_cell, true);
        project_combobox.add_attribute (text_cell, "text", 1);

        project_combobox.changed.connect (() => {
            var project = get_project_selected ();
            if (project != null) {
                PlannerQuickAdd.settings.set_int64 ("quick-add-project-selected", project.id);
            }
        });

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        action_box.margin_start = action_box.margin_end = 16;
        action_box.margin_top = action_box.margin_bottom = 9;
        action_box.hexpand = true;
        action_box.pack_start (action_grid, false, false, 0);
        action_box.pack_end (project_combobox, false, false, 0);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_end (action_box, false, false, 0);

        var warning_image = new Gtk.Image ();
        warning_image.gicon = new ThemedIcon ("dialog-warning");
        warning_image.pixel_size = 32;

        var warning_label = new Gtk.Label (_("I'm sorry, Quick Add can't find any project available, try creating a project from Planner."));
        warning_label.wrap = true;
        warning_label.max_width_chars = 42;
        warning_label.xalign = 0;

        var warning_grid = new Gtk.Grid ();
        warning_grid.margin_top = 9;
        warning_grid.margin_start = 18;
        warning_grid.margin_end = 18;
        warning_grid.halign = Gtk.Align.CENTER;
        warning_grid.column_spacing = 12;
        warning_grid.add (warning_image);
        warning_grid.add (warning_label);

        stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        stack.add_named (main_box, "main_box");
        stack.add_named (warning_grid, "warning_grid");

        add (stack);

        Timeout.add (125, () => {
            if (PlannerQuickAdd.database.is_database_empty ()) {
                stack.visible_child_name = "warning_grid";
            } else {
                stack.visible_child_name = "main_box";
            }
        });

        get_style_context ().add_class ("rounded");
        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        set_titlebar (headerbar);
        skip_taskbar_hint = true;

        cancel_button.clicked.connect (() => {
            hide ();
            /* Retain the window for a short time so that the keybinding
             * listener does not instantiate a new one right after closing
            */
            Timeout.add (500, () => {
                destroy ();
                return false;
            });
        });

        content_entry.changed.connect (() => {
            submit_button.sensitive = content_entry.text != "";
        });

        submit_button.clicked.connect (add_item);
        content_entry.activate.connect (add_item);

        content_entry.populate_popup.connect ((menu) => {
            entry_menu_opened = true;
            menu.hide.connect (() => {
                entry_menu_opened = false;
            });
        });

        PlannerQuickAdd.database.item_added_started.connect (() => {
            sensitive = false;
            submit_stack.visible_child_name = "spinner";
        });

        PlannerQuickAdd.database.item_added_completed.connect (() => {
            sensitive = true;
            submit_stack.visible_child_name = "label";
        });

        PlannerQuickAdd.database.item_added_error.connect ((http_code, error_message) => {

        });

        PlannerQuickAdd.database.item_added.connect ((item) => {
            hide ();

            send_notification (item.content, _("The task was correctly added."));

            content_entry.text = "";
            content_entry.grab_focus ();

            try {
                dbus_client.interface.add_item (item.id);
            } catch (Error e) {
                debug (e.message);
            }

            Timeout.add (500, () => {
                destroy ();
                return false;
            });
        });

        focus_out_event.connect ((event) => {
            if (Posix.isatty (Posix.STDIN_FILENO) == false &&
                project_combobox.popup_shown == false &&
                PlannerQuickAdd.database.is_adding == false &&
                entry_menu_opened == false) {
                hide ();

                Timeout.add (500, () => {
                    destroy ();
                    return false;
                });
            }

            return Gdk.EVENT_STOP;
        });
    }

    private void add_item () {
        if (content_entry.text != "" && get_project_selected () != null) {
            var project = get_project_selected ();

            var item = new Item ();
            item.id = generate_id ();
            item.project_id = project.id;
            item.is_todoist = project.is_todoist;
            parse_item_tags (item, content_entry.text);

            if (project.inbox_project == 1) {
                if (PlannerQuickAdd.database.get_project_by_id (PlannerQuickAdd.settings.get_int64 ("inbox-project")).is_todoist == 1) {
                    PlannerQuickAdd.database.add_todoist_item (item);
                } else {
                    PlannerQuickAdd.database.insert_item (item);
                }
            } else {
                if (project.is_todoist == 0) {
                    PlannerQuickAdd.database.insert_item (item);
                } else {
                    PlannerQuickAdd.database.add_todoist_item (item);
                }
            }
        }
    }

    private void parse_item_tags (Item item, string text) {
        var clean_text = "";
        Regex word_regex = /\S+\s*/;
        MatchInfo match_info;
        
        var match_text = text. strip ();
        for (word_regex.match (match_text, 0, out match_info) ; match_info.matches () ; match_info.next ()) {
            var word = match_info.fetch (0);
            var stripped = word.strip ().down ();

            switch (stripped) {
                case TODAY:
                    item.due_date = new GLib.DateTime.now_local ().to_string ();
                    break;
                case TOMORROW:
                    item.due_date = new GLib.DateTime.now_local ().add_days (1).to_string ();
                    break;
                case "p1":
                    item.priority = 4;
                    break;
                case "p2":
                    item.priority = 3;
                    break;
                case "p3":
                    item.priority = 2;
                    break;
                case "p4":
                    item.priority = 1;
                    break;
                default:
                    clean_text+= word;
                    break;
            }
        }

        item.content = clean_text;
    }

    public Project? get_project_selected () {
        Gtk.TreeIter iter;
        if (!project_combobox.get_active_iter (out iter)) {
            return null;
        }

        Value item;
        list_store.get_value (iter, 0, out item);

        return (Project) item;
    }

    public int64 generate_id (int len=10) {
        string allowed_characters = "0123456789";

        var password_builder = new StringBuilder ();
        for (var i = 0; i < len; i++) {
            var random_index = Random.int_range (0, allowed_characters.length);
            password_builder.append_c (allowed_characters[random_index]);
        }

        if (int64.parse (password_builder.str) <= 0) {
            return generate_id ();
        }

        return int64.parse (password_builder.str);
    }

    private void send_notification (string title, string body) {
        var notification = new Notification (title);
        notification.set_body (body);
        notification.set_icon (new ThemedIcon ("com.github.alainm23.planner"));
        notification.set_priority (GLib.NotificationPriority.LOW);

        application.send_notification ("com.github.alainm23.planner", notification);
    }
}
