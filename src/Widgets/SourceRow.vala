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

public class Widgets.SourceRow : Gtk.ListBoxRow {
    public E.Source source { get; construct; }

    public Gtk.Revealer main_revealer;
    private Gtk.EventBox handle;
    private Widgets.ProjectProgress project_progress;
    private Gtk.Label name_label;
    private Gtk.Label count_label;
    private Gtk.Revealer count_revealer;
    private Gtk.Button menu_button;
    private Gtk.Revealer menu_revealer;
    private Gtk.Menu menu = null;
    private Gtk.Stack status_stack;
    private Gtk.Image status_image;

    public Gee.HashMap<string, ECal.Component> items_added;
    public SourceRow (E.Source source) {
        Object (
            source: source
        );
    }

    construct {
        items_added = new Gee.HashMap<string, ECal.Component> ();
        var task_list = (E.SourceTaskList?) source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);

        margin_start = margin_end = 6;
        margin_top = 2;
        get_style_context ().add_class ("pane-row");
        get_style_context ().add_class ("project-row");

        project_progress = new Widgets.ProjectProgress (10);
        project_progress.margin = 2;
        project_progress.valign = Gtk.Align.CENTER;
        project_progress.halign = Gtk.Align.CENTER;
        project_progress.progress_fill_color = task_list.dup_color ();

        var progress_grid = new Gtk.Grid ();
        progress_grid.get_style_context ().add_class ("project-progress-%s".printf (
            source.uid
        ));
        progress_grid.add (project_progress);
        progress_grid.valign = Gtk.Align.CENTER;
        progress_grid.halign = Gtk.Align.CENTER;

        name_label = new Gtk.Label (source.display_name);
        name_label.tooltip_text = source.display_name;
        name_label.get_style_context ().add_class ("pane-item");
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        name_label.margin_start = 9;

        count_label = new Gtk.Label (null);
        count_label.valign = Gtk.Align.CENTER;
        count_label.opacity = 0.7;
        count_label.use_markup = true;
        count_label.width_chars = 3;

        count_revealer = new Gtk.Revealer ();
        count_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        count_revealer.add (count_label);

        var menu_icon = new Gtk.Image ();
        menu_icon.gicon = new ThemedIcon ("view-more-symbolic");
        menu_icon.pixel_size = 14;

        menu_button = new Gtk.Button ();
        menu_button.valign = Gtk.Align.CENTER;
        menu_button.halign = Gtk.Align.CENTER;
        menu_button.can_focus = false;
        menu_button.image = menu_icon;
        menu_button.tooltip_text = _("Project Menu");
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        menu_button.get_style_context ().add_class ("dim-label");
        menu_button.get_style_context ().add_class ("menu-button");

        var menu_stack = new Gtk.Stack ();
        menu_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        menu_stack.add_named (count_revealer, "count_revealer");
        menu_stack.add_named (menu_button, "menu_button");

        menu_revealer = new Gtk.Revealer ();
        menu_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        menu_revealer.reveal_child = true;
        menu_revealer.add (menu_stack);

        status_image = new Gtk.Image ();
        status_image.pixel_size = 14;
        status_image.margin_start = 6;

        var spinner = new Gtk.Spinner ();
        spinner.active = true;
        spinner.tooltip_text = _("Connecting…");

        status_stack = new Gtk.Stack ();
        status_stack.add_named (status_image, "image");
        status_stack.add_named (spinner, "spinner");

        var status_revealer = new Gtk.Revealer ();
        status_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        status_revealer.add (status_stack);

        var handle_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        handle_box.hexpand = true;
        handle_box.margin_start = 5;
        handle_box.margin_end = 3;
        handle_box.margin_top = handle_box.margin_bottom = 3;
        handle_box.pack_start (progress_grid, false, false, 0);
        handle_box.pack_start (name_label, false, false, 0);
        handle_box.pack_start (status_revealer, false, false, 0);
        handle_box.pack_end (menu_revealer, false, false, 0);

        handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.expand = true;
        handle.above_child = false;
        handle.add (handle_box);

        main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = true;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (handle);

        add (main_revealer);
        apply_color (task_list.dup_color ());
        create_task_list_view ();
        update_request ();

        Planner.task_store.task_list_modified.connect ((s) => {
            if (source.uid == s.uid) {
                update_request ();
            }
        });

        button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                activate_menu ();
                return true;
            }

            return false;
        });

        handle.enter_notify_event.connect ((event) => {
            menu_stack.visible_child_name = "menu_button";
            status_revealer.reveal_child = true;

            return true;
        });

        handle.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            menu_stack.visible_child_name = "count_revealer";
            status_revealer.reveal_child = false;

            return true;
        });

        menu_button.clicked.connect (() => {
            activate_menu ();
        });
    }

    private void create_task_list_view () {
        Planner.task_store.create_task_list_view (
            source,
            "(contains? 'any' '')",
            on_tasks_added,
            on_tasks_modified,
            on_tasks_removed
        );
    }

    private double get_percentage (int a, int b) {
        return (double) a / (double) b;
    }

    private void on_tasks_added (Gee.Collection<ECal.Component> tasks) {
        int task_completed = 0;
        foreach (ECal.Component task in tasks) {
            if (!items_added.has_key (task.get_icalcomponent ().get_uid ())) {
                unowned ICal.Component ical_task = task.get_icalcomponent ();
                if (ical_task.get_status () == ICal.PropertyStatus.COMPLETED) {
                    task_completed++;
                }
                items_added.set (task.get_icalcomponent ().get_uid (), task);
            }
        }

        project_progress.percentage = get_percentage (task_completed, items_added.size);
        count_label.label = "%i".printf (items_added.size - task_completed);
        count_revealer.reveal_child = (items_added.size - task_completed) > 0;
    }

    private void on_tasks_modified (Gee.Collection<ECal.Component> tasks) {
        foreach (ECal.Component task in tasks) {
            items_added.set (task.get_icalcomponent ().get_uid (), task);
        }

        int task_completed = 0;
        foreach (var task in items_added.values) {
            unowned ICal.Component ical_task = task.get_icalcomponent ();
            if (ical_task.get_status () == ICal.PropertyStatus.COMPLETED) {
                task_completed++;
            }
        }

        project_progress.percentage = get_percentage (task_completed, items_added.size);
        count_label.label = "%i".printf (items_added.size - task_completed);
        count_revealer.reveal_child = (items_added.size - task_completed) > 0;
    }

    private void on_tasks_removed (SList<ECal.ComponentId?> cids) {
        foreach (unowned ECal.ComponentId cid in cids) {
            if (cid == null) {
                continue;
            } else {
                items_added.unset (cid.get_uid ());
            }
        }

        int task_completed = 0;
        foreach (var task in items_added.values) {
            unowned ICal.Component ical_task = task.get_icalcomponent ();
            if (ical_task.get_status () == ICal.PropertyStatus.COMPLETED) {
                task_completed++;
            }
        }

        project_progress.percentage = get_percentage (task_completed, items_added.size);
        count_label.label = "%i".printf (items_added.size - task_completed);
        count_revealer.reveal_child = (items_added.size - task_completed) > 0;
    }

    private void activate_menu () {
        if (menu == null) {
            build_context_menu ();
        }

        get_style_context ().add_class ("highlight");
        menu.popup_at_pointer (null);
    }

    private void build_context_menu () {
        menu = new Gtk.Menu ();
        menu.width_request = 200;

        menu.hide.connect (() => {
            get_style_context ().remove_class ("highlight");
        });

        // var open_menu = new Widgets.ImageMenuItem (_("Open New Window"), "window-new-symbolic");
        // var edit_menu = new Widgets.ImageMenuItem (_("Edit Project"), "edit-symbolic");
        // move_area_menu = new Widgets.ImageMenuItem (_("Move"), "move-project-symbolic");
        //  areas_menu = new Gtk.Menu ();
        //  move_area_menu.set_submenu (areas_menu);

        var share_menu = new Widgets.ImageMenuItem (_("Share"), "emblem-shared-symbolic");
        var share_list_menu = new Gtk.Menu ();
        share_menu.set_submenu (share_list_menu);

        var share_mail = new Widgets.ImageMenuItem (_("Send by e-mail"), "internet-mail-symbolic");
        var share_markdown_menu = new Widgets.ImageMenuItem (_("Markdown"), "planner-markdown-symbolic");

        share_list_menu.add (share_markdown_menu);
        share_list_menu.add (share_mail);
        share_list_menu.show_all ();

        // var duplicate_menu = new Widgets.ImageMenuItem (_("Duplicate"), "edit-copy-symbolic");

        var delete_menu = new Widgets.ImageMenuItem (_("Delete"), "user-trash-symbolic");
        delete_menu.get_style_context ().add_class ("menu-danger");

        // menu.add (open_menu);
        // menu.add (new Gtk.SeparatorMenuItem ());
        // menu.add (edit_menu);
        // menu.add (new Gtk.SeparatorMenuItem ());
        // menu.add (move_area_menu);
        menu.add (share_menu);
        // menu.add (duplicate_menu);
        if (source.removable) {
            menu.add (new Gtk.SeparatorMenuItem ());
            menu.add (delete_menu);
        }

        menu.show_all ();

        //  open_menu.activate.connect (() => {
        //      var dialog = new Dialogs.Project (project);
        //      dialog.destroy.connect (Gtk.main_quit);
        //      dialog.show_all ();
        //  });

        //  edit_menu.activate.connect (() => {
        //      var dialog = new Dialogs.ProjectSettings (project);
        //      dialog.destroy.connect (Gtk.main_quit);
        //      dialog.show_all ();
        //  });

        delete_menu.activate.connect (() => {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Delete project"),
                _("Are you sure you want to delete <b>%s</b>?".printf (Planner.utils.get_dialog_text (source.display_name))),
                "user-trash-full",
            Gtk.ButtonsType.CANCEL);

            var remove_button = new Gtk.Button.with_label (_("Delete"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                if (source.removable) {
                    source.remove.begin (null);
                } else {
                    Gdk.beep ();
                }
            }

            message_dialog.destroy ();
        });

        share_mail.activate.connect (() => {
            // project.share_mail ();
        });

        share_markdown_menu.activate.connect (() => {
            // project.share_markdown ();
        });
    }

    private void apply_color (string color) {
        string _css = """
            .project-progress-%s {
                border-radius: 50%;
                border: 1.5px solid %s;
            }
        """;

        var provider = new Gtk.CssProvider ();

        try {
            var css = _css.printf (
                source.uid,
                color
            );

            provider.load_from_data (css, css.length);
            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (), provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } catch (GLib.Error e) {
            return;
        }
    }

    public void update_request () {
        var task_list = (E.SourceTaskList?) source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);
        name_label.label = source.display_name;
        apply_color (task_list.dup_color ());
        project_progress.progress_fill_color = task_list.dup_color ();
        
        if (source.connection_status == E.SourceConnectionStatus.CONNECTING) {
            status_stack.visible_child_name = "spinner";
        } else {
            status_stack.visible_child_name = "image";

            switch (source.connection_status) {
                case E.SourceConnectionStatus.AWAITING_CREDENTIALS:
                    status_image.icon_name = "dialog-password-symbolic";
                    status_image.tooltip_text = _("Waiting for login credentials");
                    break;
                case E.SourceConnectionStatus.DISCONNECTED:
                    status_image.icon_name = "network-offline-symbolic";
                    status_image.tooltip_text = _("Currently disconnected from the (possibly remote) data store");
                    break;
                case E.SourceConnectionStatus.SSL_FAILED:
                    status_image.icon_name = "security-low-symbolic";
                    status_image.tooltip_text = _("SSL certificate trust was rejected for the connection");
                    break;
                default:
                    status_image.gicon = null;
                    status_image.tooltip_text = null;
                    break;
            }
        }
    }

    public void remove_request () {
        main_revealer.reveal_child = false;
        GLib.Timeout.add (main_revealer.transition_duration, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}
