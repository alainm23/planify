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
    public weak Planner app { get; construct; }
    public Gee.HashMap <string, bool> projects_loaded;

    private Widgets.Pane pane;
    private Gtk.HeaderBar sidebar_header;
    private Gtk.HeaderBar projectview_header;
    private Gtk.Stack stack;
    private Views.Inbox inbox_view = null;
    private Views.Today today_view = null;
    private Views.Upcoming upcoming_view = null;
    private Views.Completed completed_view = null;
    private Views.Label label_view = null;
    private Views.Priority priority_view = null;

    private Widgets.MagicButton magic_button;
    // private Widgets.Toast notification_toast;
    private Services.DBusServer dbus_server;
    public Services.ActionManager action_manager;

    private uint timeout_id = 0;
    private uint configure_id = 0;

    public MainWindow (Planner application) {
        Object (
            application: application,
            app: application,
            icon_name: "com.github.alainm23.planner",
            title: _("Planner"),
            height_request: 400,
            width_request: 400
        );
    }

    construct {
        action_manager = new Services.ActionManager (app, this);

        dbus_server = Services.DBusServer.get_default ();
        dbus_server.item_added.connect ((id) => {
            Planner.database.item_added (Planner.database.get_item_by_id (id), -1);
        });

        projects_loaded = new Gee.HashMap <string, bool> ();

        var header_revealer = new Gtk.Revealer ();
        header_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;

        sidebar_header = new Gtk.HeaderBar ();
        sidebar_header.has_subtitle = false;
        sidebar_header.show_close_button = true;
        sidebar_header.custom_title = header_revealer;
        sidebar_header.get_style_context ().add_class ("sidebar-header");
        sidebar_header.get_style_context ().add_class ("titlebar");
        sidebar_header.get_style_context ().add_class ("default-decoration");
        sidebar_header.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        projectview_header = new Gtk.HeaderBar ();
        projectview_header.has_subtitle = false;
        projectview_header.show_close_button = true;
        projectview_header.get_style_context ().add_class ("projectview-header");
        projectview_header.get_style_context ().add_class ("titlebar");
        projectview_header.get_style_context ().add_class ("default-decoration");
        projectview_header.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        check_button_layout ();

        var header_paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        header_paned.wide_handle = true;
        header_paned.pack1 (sidebar_header, false, false);
        header_paned.pack2 (projectview_header, true, false);

        pane = new Widgets.Pane ();

        var welcome_view = new Views.Welcome ();

        stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.NONE;

        stack.add_named (welcome_view, "welcome-view");

        var notifications_grid = new Gtk.Grid ();
        notifications_grid.orientation = Gtk.Orientation.VERTICAL;
        notifications_grid.margin_bottom = 12;
        notifications_grid.halign = Gtk.Align.CENTER;
        notifications_grid.valign = Gtk.Align.END;

        magic_button = new Widgets.MagicButton ();

        var slim_mode_icon = new Gtk.Image ();
        slim_mode_icon.gicon = new ThemedIcon ("pane-show-symbolic");
        slim_mode_icon.pixel_size = 13;

        var slim_mode_button = new Gtk.Button ();
        slim_mode_button.image = slim_mode_icon;
        slim_mode_button.get_style_context ().add_class ("dim-label");
        slim_mode_button.valign = Gtk.Align.CENTER;

        var slim_mode_revealer = new Gtk.Revealer ();
        slim_mode_revealer.valign = Gtk.Align.CENTER;
        slim_mode_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        slim_mode_revealer.add (slim_mode_button);
        slim_mode_revealer.reveal_child = false;

        sidebar_header.pack_end (slim_mode_revealer);

        //  var slim_mode_handle = new Gtk.EventBox ();
        //  slim_mode_handle.margin_bottom = 32;
        //  slim_mode_handle.height_request = 164;
        //  slim_mode_handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        //  slim_mode_handle.halign = Gtk.Align.START;
        //  slim_mode_handle.valign = Gtk.Align.CENTER;
        //  slim_mode_handle.above_child = false;
        //  slim_mode_handle.add (slim_mode_revealer);

        var projectview_overlay = new Gtk.Overlay ();
        projectview_overlay.expand = true;
        projectview_overlay.add_overlay (magic_button);
        projectview_overlay.add_overlay (notifications_grid);
        /// projectview_overlay.add_overlay (slim_mode_handle);
        projectview_overlay.add (stack);

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned.wide_handle = true;
        paned.pack1 (pane, false, false);
        paned.pack2 (projectview_overlay, true, false);
        
        set_titlebar (header_paned);
        add (paned);

        // This must come after setting header_paned as the titlebar
        header_paned.get_style_context ().remove_class ("titlebar");
        get_style_context ().add_class ("rounded");
        Planner.settings.bind ("pane-position", header_paned, "position", GLib.SettingsBindFlags.DEFAULT);
        Planner.settings.bind ("pane-position", paned, "position", GLib.SettingsBindFlags.DEFAULT);

        Planner.notifications.send_notification.connect ((message) => {
            var notification = new Widgets.Toast (message);
            notifications_grid.add (notification);
            notifications_grid.show_all ();

            notification.send_notification ();
        });

        Planner.notifications.send_undo_notification.connect ((message, query) => {
            var notification = new Widgets.Toast (message, query);
            notifications_grid.add (notification);
            notifications_grid.show_all ();

            notification.send_notification ();
        });

        Planner.database.opened.connect (() => {
            if (Planner.database.is_database_empty ()) {
                stack.visible_child_name = "welcome-view";
                pane.sensitive_ui = false;
                magic_button.reveal_child = false;
            } else {
                // Set the homepage view
                if (Planner.settings.get_boolean ("homepage-project")) {
                    int64 project_id = Planner.settings.get_int64 ("homepage-project-id");
                    if (Planner.database.project_exists (project_id)) {
                        projects_loaded.set (project_id.to_string (), true);
                        var project_view = new Views.Project (Planner.database.get_project_by_id (project_id));
                        stack.add_named (project_view, "project-view-%s".printf (project_id.to_string ()));
                        stack.visible_child_name = "project-view-%s".printf (project_id.to_string ());
                    } else {
                        go_view (0);
                    }
                } else {
                    go_view (Planner.settings.get_int ("homepage-item"));
                    pane.select_item (Planner.settings.get_int ("homepage-item"));
                }

                // Run Reminder server
                Planner.notifications.init_server ();

                // Run Todoisr Sync server
                Planner.todoist.run_server ();

                // Add all projects and areas
                pane.add_all_projects ();
                pane.add_all_areas ();

                // Init Progress Server
                init_badge_count ();
                init_progress_controller ();

                pane.sensitive_ui = true;
                magic_button.reveal_child = true;
            }
        });

        Planner.database.reset.connect (() => {
            stack.visible_child_name = "welcome-view";
        });

        //  slim_mode_handle.enter_notify_event.connect ((event) => {
        //      slim_mode_revealer.reveal_child = true;

        //      return true;
        //  });

        //  slim_mode_handle.leave_notify_event.connect ((event) => {
        //      if (event.detail == Gdk.NotifyType.INFERIOR) {
        //          return false;
        //      }

        //      slim_mode_revealer.reveal_child = false;

        //      return true;
        //  });

        welcome_view.activated.connect ((index) => {
            if (index == 0) {
                // Save user name
                Planner.settings.set_string ("user-name", GLib.Environment.get_real_name ());

                // To do: Create a tutorial project
                Planner.utils.pane_project_selected (Planner.utils.create_tutorial_project ().id, 0);

                // Create Inbox Project
                var inbox_project = Planner.database.create_inbox_project ();

                // Cretae Default Labels
                Planner.utils.create_default_labels ();

                // Set settings
                Planner.settings.set_int64 ("inbox-project", inbox_project.id);

                stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
                stack.visible_child_name = "inbox-view";

                pane.sensitive_ui = true;
                magic_button.reveal_child = true;

                stack.transition_type = Gtk.StackTransitionType.NONE;

                // Init Progress Server
                init_badge_count ();
                init_progress_controller ();
            } else {
                var todoist_oauth = new Dialogs.TodoistOAuth ();
                todoist_oauth.show_all ();
            }
        });

        pane.activated.connect ((id) => {
            go_view (id);
        });

        pane.show_quick_find.connect (show_quick_find);

        Planner.utils.pane_project_selected.connect ((project_id, area_id) => {
            go_project (project_id);
        });

        Planner.todoist.first_sync_finished.connect (() => {
            stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

            // Create The New Inbox Project
            inbox_view = null;
            go_view (0);

            // Enable UI
            pane.sensitive_ui = true;
            magic_button.reveal_child = true;
            stack.transition_type = Gtk.StackTransitionType.NONE;

            // Init Progress Server
            init_badge_count ();
            init_progress_controller ();
        });

        Planner.database.project_deleted.connect ((id) => {
            if ("project-view-%s".printf (id.to_string ()) == stack.visible_child_name) {
                stack.visible_child.destroy ();
                stack.visible_child_name = "inbox-view";

                pane.select_item (0);
            }
        });

        magic_button.clicked.connect (() => {
            if (stack.visible_child_name == "inbox-view") {
                inbox_view.add_new_item (-1);
            } else if (stack.visible_child_name == "today-view") {
                today_view.add_new_item (-1);
            } else if (stack.visible_child_name == "upcoming-view") {
                Planner.utils.magic_button_clicked ("upcoming");
            } else {
                var project = ((Views.Project) stack.get_child_by_name (stack.visible_child_name));
                project.add_new_item (-1);
            }
        });

        // Label Controller
        var labels_controller = new Services.LabelsController ();

        Planner.database.label_added.connect_after ((label) => {
            Idle.add (() => {
                labels_controller.add_label (label);

                return false;
            });
        });

        Planner.database.label_updated.connect ((label) => {
            Idle.add (() => {
                labels_controller.update_label (label);

                return false;
            });
        });

        delete_event.connect (() => {
            if (Planner.settings.get_boolean ("run-in-background")) {
                return hide_on_delete ();
            } else {
                return false;
            }
        });

        Planner.instance.go_view.connect ((type, id, id2) => {
            if (type == "project") {
                if (projects_loaded.has_key (id.to_string ())) {
                    stack.visible_child_name = "project-view-%s".printf (id.to_string ());
                } else {
                    projects_loaded.set (id.to_string (), true);
                    var project_view = new Views.Project (Planner.database.get_project_by_id (id));
                    stack.add_named (project_view, "project-view-%s".printf (id.to_string ()));
                    stack.visible_child_name = "project-view-%s".printf (id.to_string ());
                }
            } else if (type == "item") {
                if (projects_loaded.has_key (id2.to_string ())) {
                    stack.visible_child_name = "project-view-%s".printf (id2.to_string ());
                } else {
                    projects_loaded.set (id2.to_string (), true);
                    var project_view = new Views.Project (Planner.database.get_project_by_id (id2));
                    stack.add_named (project_view, "project-view-%s".printf (id2.to_string ()));
                    stack.visible_child_name = "project-view-%s".printf (id2.to_string ());
                }
            }
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "appearance") {
                Planner.utils.apply_theme_changed ();
            } else if (key == "badge-count") {
                set_badge_visible ();
            } else if (key == "todoist-sync-token") {
                Planner.settings.set_string (
                    "todoist-last-sync",
                    new GLib.DateTime.now_local ().to_string ()
                );
            } else if (key == "button-layout") {
                check_button_layout ();
            }
        });

        key_press_event.connect ((event) => {
            if (event.keyval == 65507) {
                Planner.event_bus.ctrl_pressed = true;
                Planner.event_bus.ctrl_press ();
            }

            return false;
        });
        
        key_release_event.connect ((event) => {
            if (event.keyval == 65507) {
                Planner.event_bus.ctrl_pressed = false;
                Planner.event_bus.ctrl_release ();
            }
            
            return false;
        });
    }

    public void init_progress_controller () {
        Planner.database.item_added.connect ((item) => {
            Planner.database.check_project_count (item.project_id);
        });

        //  Planner.database.item_added_with_index.connect ((item, index) => {
        //      Planner.database.check_project_count (item.project_id);
        //  });

        Planner.database.item_updated.connect ((item) => {
            Planner.database.check_project_count (item.project_id);
        });

        Planner.database.item_moved.connect ((item, project_id, old_project_id) => {
            Planner.database.check_project_count (project_id);
            Planner.database.check_project_count (old_project_id);
        });

        Planner.database.item_deleted.connect ((item) => {
            Planner.database.check_project_count (item.project_id);
        });

        Planner.database.item_completed.connect ((item) => {
            Planner.database.check_project_count (item.project_id);
        });

        Planner.database.item_uncompleted.connect ((item) => {
            Planner.database.check_project_count (item.project_id);
        });

        Planner.database.subtract_task_counter.connect ((id) => {
            Idle.add (() => {
                Planner.database.check_project_count (id);
                return false;
            });
        });

        Planner.database.update_project_count.connect ((id, items_0, items_1) => {
            Planner.database.check_project_count (id);
        });

        /*
        *   Sections Event
        */
        Planner.database.section_added.connect ((section) => {
            Idle.add (() => {
                Planner.database.check_project_count (section.project_id);
                return false;
            });
        });

        Planner.database.section_deleted.connect ((section) => {
            Planner.database.check_project_count (section.project_id);
        });

        Planner.database.section_moved.connect ((section, id, old_project_id) => {
            Idle.add (() => {
                Planner.database.check_project_count (id);
                Planner.database.check_project_count (old_project_id);
                return false;
            });
        });

        Planner.database.update_all_bage ();
    }

    public void show_quick_find () {
        var dialog = new Dialogs.QuickFind ();
        dialog.destroy.connect (Gtk.main_quit);
        dialog.show_all ();
    }

    public void new_project () {
        if (pane.new_project.reveal) {
            pane.new_project.reveal = false;
        } else {
            pane.new_project.reveal = true;
            pane.new_project.stack.visible_child_name = "box";
            pane.new_project.name_entry.grab_focus ();
        }
    }

    public void go_view (int id) {
        if (id == 0) {
            if (inbox_view == null) {
                inbox_view = new Views.Inbox (
                    Planner.database.get_project_by_id (Planner.settings.get_int64 ("inbox-project"))
                );
                stack.add_named (inbox_view, "inbox-view");
            }

            magic_button.reveal_child = true;
            stack.visible_child_name = "inbox-view";
        } else if (id == 1) {
            if (today_view == null) {
                today_view = new Views.Today ();
                stack.add_named (today_view, "today-view");
            }

            magic_button.reveal_child = true;
            stack.visible_child_name = "today-view";
        } else if (id == 2) {
            if (upcoming_view == null) {
                upcoming_view = new Views.Upcoming ();
                stack.add_named (upcoming_view, "upcoming-view");
            }

            magic_button.reveal_child = true;
            stack.visible_child_name = "upcoming-view";
        } else if (id == 3) {
            if (completed_view == null) {
                completed_view = new Views.Completed ();
                stack.add_named (completed_view, "completed-view");
            }

            completed_view.add_all_items ();
            magic_button.reveal_child = true;
            stack.visible_child_name = "completed-view";
        }

        pane.select_item (id);
    }

    public void go_project (int64 project_id) {
        var project = Planner.database.get_project_by_id (project_id);

        if (projects_loaded.has_key (project.id.to_string ())) {
            stack.visible_child_name = "project-view-%s".printf (project.id.to_string ());
        } else {
            projects_loaded.set (project.id.to_string (), true);
            var project_view = new Views.Project (Planner.database.get_project_by_id (project.id));
            stack.add_named (project_view, "project-view-%s".printf (project.id.to_string ()));
            stack.visible_child_name = "project-view-%s".printf (project.id.to_string ());
        }

        // Planner.utils.pane_project_selected (project.id, project.area_id);
        // Planner.utils.select_pane_project (project.id);

        magic_button.reveal_child = true;
    }

    public void go_item (int64 item_id) {
        var item = Planner.database.get_item_by_id (item_id);
        go_project (item.project_id);
        Planner.utils.highlight_item (item_id);
    }

    public void go_label (int64 label_id) {
        if (label_view == null) {
            label_view = new Views.Label ();
            stack.add_named (label_view, "label-view");
        }

        magic_button.reveal_child = false;
        label_view.label = Planner.database.get_label_by_id (label_id);
        stack.visible_child_name = "label-view";
    }

    public void go_priority (int priority) {
        if (priority_view == null) {
            priority_view = new Views.Priority ();
            stack.add_named (priority_view, "priority-view");
        }

        magic_button.reveal_child = false;
        priority_view.priority = priority;
        stack.visible_child_name = "priority-view";
    }

    private void init_badge_count () {
        set_badge_visible ();

        Planner.database.item_added.connect ((item) => {
            set_badge_visible ();
        });

        //  Planner.database.item_added_with_index.connect (() => {
        //      set_badge_visible ();
        //  });

        Planner.database.item_deleted.connect ((item) => {
            set_badge_visible ();
        });

        Planner.database.item_completed.connect ((item) => {
            set_badge_visible ();
        });

        Planner.database.add_due_item.connect (() => {
            set_badge_visible ();
        });

        Planner.database.update_due_item.connect (() => {
            set_badge_visible ();
        });

        Planner.database.remove_due_item.connect (() => {
            set_badge_visible ();
        });

        Planner.database.item_moved.connect (() => {
            Idle.add (() => {
                set_badge_visible ();

                return false;
            });
        });

        Planner.database.subtract_task_counter.connect ((id) => {
            Idle.add (() => {
                set_badge_visible ();

                return false;
            });
        });
    }

    private void set_badge_visible () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
        }

        timeout_id = Timeout.add (300, () => {
            timeout_id = 0;
            
            Granite.Services.Application.set_badge_visible.begin (
                Planner.settings.get_enum ("badge-count") != 0, (obj, res) => {
                try {
                    Granite.Services.Application.set_badge_visible.end (res);
                    update_badge_count ();
                } catch (GLib.Error e) {
                    critical (e.message);
                }
            });

            return false;
        });
    }

    private void update_badge_count () {
        int badge_count = Planner.settings.get_enum ("badge-count");
        int count = 0;

        if (badge_count == 1) {
            count = Planner.database.get_project_count (Planner.settings.get_int64 ("inbox-project"));
        } else if (badge_count == 2) {
            count = Planner.database.get_today_count () + Planner.database.get_past_count ();
        } else if (badge_count == 3) {
            count = (Planner.database.get_project_count (
                Planner.settings.get_int64 ("inbox-project")) +
                Planner.database.get_past_count () +
                Planner.database.get_today_count ()) -
                Planner.database.get_today_project_count (Planner.settings.get_int64 ("inbox-project")
            );
        }

        bool badge_visible = false;
        if (count > 0) {
            badge_visible = true;
        }

        Granite.Services.Application.set_badge.begin (count, (obj, res) => {
            try {
                Granite.Services.Application.set_badge.end (res);

                if (badge_visible == false) {
                    Granite.Services.Application.set_badge_visible.begin (badge_visible, (obj, res) => {
                        try {
                            Granite.Services.Application.set_badge_visible.end (res);
                        } catch (GLib.Error e) {
                            critical (e.message);
                        }
                    });
                }
            } catch (GLib.Error e) {
                critical (e.message);
            }
        });
    }

    public void add_task_action (int index) {
        if (stack.visible_child_name == "inbox-view") {
            inbox_view.add_new_item (index);
        } else if (stack.visible_child_name == "today-view") {
            today_view.add_new_item (index);
        } else if (stack.visible_child_name == "upcoming-view") {
            var inbox_project = Planner.database.get_project_by_id (Planner.settings.get_int64 ("inbox-project"));
            
            Planner.event_bus.magic_button_activated (
                inbox_project.id,
                0,
                inbox_project.is_todoist,
                index,
                "upcoming",
                new DateTime.now_local ().add_days (1).to_string ()
            );
        } else {
            var project = ((Views.Project) stack.visible_child).project;
            Planner.event_bus.magic_button_activated (
                project.id,
                0,
                project.is_todoist,
                index,
                "project",
                ""
            );
        }
    }

    public void add_task_clipboard_action (string text) {
        var item = new Objects.Item ();
        item.content = text;       
        item.section_id = 0;

        var inbox_project = Planner.database.get_project_by_id (Planner.settings.get_int64 ("inbox-project"));

        if (stack.visible_child_name == "inbox-view") {
            item.project_id = inbox_project.id;
            item.is_todoist = inbox_project.is_todoist;

            if (item.is_todoist == 1) {
                Planner.todoist.add_item (item, -1, Planner.utils.generate_id ());
            } else {
                item.id = Planner.utils.generate_id ();
                Planner.database.insert_item (item, -1);
            }
        } else if (stack.visible_child_name == "today-view") {
            item.project_id = inbox_project.id;
            item.is_todoist = inbox_project.is_todoist;
            item.due_date = new GLib.DateTime.now_local ().to_string ();

            if (item.is_todoist == 1) {
                Planner.todoist.add_item (item, -1, Planner.utils.generate_id ());
            } else {
                item.id = Planner.utils.generate_id ();
                Planner.database.insert_item (item, -1);
            }
        } else if (stack.visible_child_name == "upcoming-view") {
            item.project_id = inbox_project.id;
            item.is_todoist = inbox_project.is_todoist;
            item.due_date = new GLib.DateTime.now_local ().add_days (1).to_string ();

            if (item.is_todoist == 1) {
                Planner.todoist.add_item (item, -1, Planner.utils.generate_id ());
            } else {
                item.id = Planner.utils.generate_id ();
                Planner.database.insert_item (item, -1);
            }
        } else {
            var project = ((Views.Project) stack.visible_child).project;
            item.project_id = project.id;
            item.is_todoist = project.is_todoist;

            if (item.is_todoist == 1) {
                Planner.todoist.add_item (item, -1, Planner.utils.generate_id ());
            } else {
                item.id = Planner.utils.generate_id ();
                Planner.database.insert_item (item, -1);
            }
        }
    }

    public void new_section_action () {
        if (stack.visible_child_name == "inbox-view") {
            inbox_view.open_new_section ();
        } else if (stack.visible_child_name == "today-view") {

        } else if (stack.visible_child_name == "upcoming-view") {

        } else {
            var project_view = (Views.Project) stack.visible_child;
            project_view.open_new_section ();
        }
    }

    public void hide_item () {
        if (pane.visible_new_widget ()) {
            pane.set_visible_new_widget (false);
        } else {
            if (stack.visible_child_name == "inbox-view") {
                //inbox_view.hide_last_item ();
            } else if (stack.visible_child_name == "today-view") {
                //today_view.hide_last_item ();
            } else if (stack.visible_child_name == "upcoming-view") {
                //upcoming_view.hide_last_item ();
            } else {
                //var project_view = (Views.Project) stack.visible_child;
                //project_view.hide_last_item ();
            }
        }
    }

    private void check_button_layout () {
        int button_layout = Planner.settings.get_enum ("button-layout");

        if (button_layout == 0) { // elementary
            sidebar_header.decoration_layout = "close:";
            projectview_header.decoration_layout = ":maximize";
        } else if (button_layout == 1) { // Ubuntu
            sidebar_header.decoration_layout = "close,maximize,minimize:";
            projectview_header.decoration_layout = ":";
        } else if (button_layout == 2) { // Windows
            sidebar_header.decoration_layout = ":";
            projectview_header.decoration_layout = ":minimize,maximize,close";
        } else if (button_layout == 3) { // macOS
            sidebar_header.decoration_layout = "close,minimize,maximize";
            projectview_header.decoration_layout = ":";
        } else if (button_layout == 4) { // Minimize Left
            sidebar_header.decoration_layout = "close,minimize:";
            projectview_header.decoration_layout = ":maximize";
        } else if (button_layout == 5) { // Minimize Right
            sidebar_header.decoration_layout = "close:";
            projectview_header.decoration_layout = ":minimize,maximize";
        } else if (button_layout == 6) { // Close Only Left
            sidebar_header.decoration_layout = "close:";
            projectview_header.decoration_layout = ":";
        } else if (button_layout == 7) { // Close Only Right
            sidebar_header.decoration_layout = ":";
            projectview_header.decoration_layout = ":close";
        }
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        if (configure_id != 0) {
            GLib.Source.remove (configure_id);
        }

        configure_id = Timeout.add (100, () => {
            configure_id = 0;

            if (is_maximized) {
                Planner.settings.set_boolean ("window-maximized", true);
            } else {
                Planner.settings.set_boolean ("window-maximized", false);

                Gdk.Rectangle rect;
                get_allocation (out rect);
                Planner.settings.set ("window-size", "(ii)", rect.width, rect.height);

                int root_x, root_y;
                get_position (out root_x, out root_y);
                Planner.settings.set ("window-position", "(ii)", root_x, root_y);
            }

            return false;
        });

        return base.configure_event (event);
    }
}
