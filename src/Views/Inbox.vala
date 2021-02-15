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

public class Views.Inbox : Gtk.EventBox {
    public Objects.Project project { get; construct; }

    private Gtk.Box top_box;

    private Gtk.ModelButton show_completed_button;
    private Gtk.Switch show_completed_switch;
    private Gtk.Stack main_stack;
    private Widgets.BoardView board_view;
    private Widgets.ListView list_view;
    private Gtk.Switch board_switch;
    private Gtk.ModelButton board_button;
    
    private Widgets.Entry section_name_entry;
    private Gtk.ToggleButton section_button;
    private Gtk.Popover new_section_popover = null;
    private Gtk.Menu share_menu = null;
    private Gtk.Popover popover = null;
    private Gtk.ToggleButton settings_button;

    private int64 temp_id_mapping { get; set; default = 0; }
    
    public Inbox (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        var icon_image = new Gtk.Image ();
        icon_image.valign = Gtk.Align.CENTER;
        icon_image.gicon = new ThemedIcon ("mail-mailbox-symbolic");
        icon_image.get_style_context ().add_class ("inbox-icon");
        icon_image.pixel_size = 16;

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Inbox")));
        title_label.get_style_context ().add_class ("title-label");
        title_label.use_markup = true;

        var section_image = new Gtk.Image ();
        section_image.gicon = new ThemedIcon ("section-symbolic");
        section_image.pixel_size = 16;

        section_button = new Gtk.ToggleButton ();
        section_button.valign = Gtk.Align.CENTER;
        section_button.halign = Gtk.Align.CENTER;
        section_button.tooltip_markup = Granite.markup_accel_tooltip ({"s"}, _("Add Section"));
        section_button.can_focus = false;
        section_button.get_style_context ().add_class ("flat");
        section_button.add (section_image);

        var add_person_button = new Gtk.Button.from_icon_name ("contact-new-symbolic", Gtk.IconSize.MENU);
        add_person_button.valign = Gtk.Align.CENTER;
        add_person_button.halign = Gtk.Align.CENTER;
        add_person_button.tooltip_text = _("Invite person");
        add_person_button.can_focus = false;
        add_person_button.margin_start = 6;
        add_person_button.get_style_context ().add_class ("flat");

        var comment_button = new Gtk.Button.from_icon_name ("internet-chat-symbolic", Gtk.IconSize.MENU);
        comment_button.valign = Gtk.Align.CENTER;
        comment_button.halign = Gtk.Align.CENTER;
        comment_button.can_focus = false;
        comment_button.tooltip_text = _("Project comments");
        comment_button.margin_start = 6;
        comment_button.get_style_context ().add_class ("flat");

        var search_button = new Gtk.Button.from_icon_name ("edit-find-symbolic", Gtk.IconSize.MENU);
        search_button.valign = Gtk.Align.CENTER;
        search_button.halign = Gtk.Align.CENTER;
        search_button.can_focus = false;
        search_button.tooltip_text = _("Search task");
        search_button.margin_start = 6;
        search_button.get_style_context ().add_class ("flat");

        var settings_image = new Gtk.Image ();
        settings_image.gicon = new ThemedIcon ("view-more-symbolic");
        settings_image.pixel_size = 14;

        settings_button = new Gtk.ToggleButton ();
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.can_focus = false;
        settings_button.tooltip_text = _("Project Menu");
        settings_button.image = settings_image;
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var label_filter = new Widgets.LabelFilter ();
        label_filter.project = project;
        
        top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_end = 36;
        top_box.margin_start = 42;
        top_box.margin_top = 6;

        top_box.pack_start (icon_image, false, false, 0);
        top_box.pack_start (title_label, false, false, 0);
        top_box.pack_end (settings_button, false, false, 0);
        top_box.pack_end (section_button, false, false, 0);
        top_box.pack_end (label_filter, false, false, 0);

        list_view = new Widgets.ListView ();
        list_view.project = project;

        board_view = new Widgets.BoardView ();
        board_view.project = project;
        
        var placeholder_view = new Widgets.Placeholder (
            _("All clear"),
            _("Looks like everything's organized in the right place."),
            "mail-mailbox-symbolic"
        );
        placeholder_view.reveal_child = true;

        main_stack = new Gtk.Stack ();
        main_stack.expand = true;
        main_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        main_stack.add_named (list_view, "project");
        main_stack.add_named (board_view, "board");
        main_stack.add_named (placeholder_view, "placeholder");

        var magic_button = new Widgets.MagicButton ();

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (main_stack, false, true, 0);

        var overlay = new Gtk.Overlay ();
        overlay.expand = true;
        overlay.add_overlay (magic_button);
        overlay.add (main_box);

        add (overlay);
        show_all ();

        magic_button.clicked.connect (() => {
            if (project.is_kanban == 1) {
                board_view.add_new_item (Planner.settings.get_enum ("new-tasks-position"));
            } else {
                list_view.add_new_item (Planner.settings.get_enum ("new-tasks-position"));
            }
        });

        // Check Placeholder view
        Timeout.add (125, () => {
            Planner.database.get_project_count (project.id);

            if (project.is_kanban == 1) {
                main_stack.visible_child_name = "board";
            }
            
            return GLib.Source.REMOVE;
        });

        settings_button.toggled.connect (() => {
            Planner.event_bus.unselect_all ();
            
            if (settings_button.active) {
                if (popover == null) {
                    create_popover ();
                }

                popover.show_all ();
            }
        });

        section_button.toggled.connect (() => {
            open_new_section ();
        });

        Planner.database.project_id_updated.connect ((current_id, new_id) => {
            Idle.add (() => {
                if (project.id == current_id) {
                    project.id = new_id;
                }

                return false;
            });
        });
    }

    private void save (bool todoist=true) {
        if (project != null) {
            project.save (todoist);
        }
    }

    private void create_popover () {
        popover = new Gtk.Popover (settings_button);
        popover.get_style_context ().add_class ("popover-background");
        popover.position = Gtk.PositionType.BOTTOM;

        var open_menu = new Widgets.ModelButton (_("Open New Window"), "window-new-symbolic", "");
        var edit_menu = new Widgets.ModelButton (_("Edit Project"), "edit-symbolic", "");
        var sort_date_menu = new Widgets.ModelButton (_("Sort by date"), "x-office-calendar-symbolic", "");
        var sort_priority_menu = new Widgets.ModelButton (_("Sort by priority"), "edit-flag-symbolic", "");
        var sort_name_menu = new Widgets.ModelButton (_("Sort by name"), "font-x-generic-symbolic", "");
        //var archive_menu = new Widgets.ModelButton (_("Archive project"), "planner-archive-symbolic");
        var share_item = new Widgets.ModelButton (_("Utilities"), "applications-utilities-symbolic", "", true);

        var delete_menu = new Widgets.ModelButton (_("Delete"), "user-trash-symbolic");
        delete_menu.get_style_context ().add_class ("menu-danger");

        // Show Complete
        var show_completed_image = new Gtk.Image ();
        show_completed_image.gicon = new ThemedIcon ("emblem-default-symbolic");
        show_completed_image.valign = Gtk.Align.START;
        show_completed_image.pixel_size = 16;

        var show_completed_label = new Gtk.Label (_("Show Completed"));
        show_completed_label.hexpand = true;
        show_completed_label.valign = Gtk.Align.START;
        show_completed_label.xalign = 0;
        show_completed_label.margin_start = 9;

        show_completed_switch = new Gtk.Switch ();
        show_completed_switch.margin_start = 12;
        show_completed_switch.get_style_context ().add_class ("planner-switch");
        if (project.show_completed == 1) {
            show_completed_switch.active = true;
        }

        var show_completed_grid = new Gtk.Grid ();
        show_completed_grid.add (show_completed_image);
        show_completed_grid.add (show_completed_label);
        show_completed_grid.add (show_completed_switch);

        show_completed_button = new Gtk.ModelButton ();
        show_completed_button.get_style_context ().add_class ("popover-model-button");
        show_completed_button.get_child ().destroy ();
        show_completed_button.add (show_completed_grid);

        // Board iew
        var board_image = new Gtk.Image ();
        board_image.gicon = new ThemedIcon ("align-vertical-top-symbolic");
        board_image.valign = Gtk.Align.START;
        board_image.pixel_size = 16;

        var board_label = new Gtk.Label (_("View as board"));
        board_label.hexpand = true;
        board_label.valign = Gtk.Align.START;
        board_label.xalign = 0;
        board_label.margin_start = 9;

        board_switch = new Gtk.Switch ();
        board_switch.margin_start = 12;
        board_switch.get_style_context ().add_class ("planner-switch");
        if (project.is_kanban == 1) {
           board_switch.active = true;
        }

        var board_grid = new Gtk.Grid ();
        board_grid.add (board_image);
        board_grid.add (board_label);
        board_grid.add (board_switch);

        board_button = new Gtk.ModelButton ();
        board_button.get_style_context ().add_class ("popover-model-button");
        board_button.get_child ().destroy ();
        board_button.add (board_grid);

        var popover_grid = new Gtk.Grid ();
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.margin_top = 3;
        popover_grid.margin_bottom = 3;
        popover_grid.add (board_button);
        popover_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3
        });
        popover_grid.add (sort_date_menu);
        popover_grid.add (sort_priority_menu);
        popover_grid.add (sort_name_menu);
        popover_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3
        });
        popover_grid.add (share_item);
        popover_grid.add (show_completed_button);

        popover.add (popover_grid);

        popover.closed.connect (() => {
            settings_button.active = false;
        });

        edit_menu.clicked.connect (() => {
            var dialog = new Dialogs.ProjectSettings (project);
            dialog.destroy.connect (Gtk.main_quit);
            dialog.show_all ();

            popover.popdown ();
        });

        open_menu.clicked.connect (() => {
            var dialog = new Dialogs.Project (project);
            dialog.destroy.connect (Gtk.main_quit);
            
            int window_x, window_y;
            var rect = Gtk.Allocation ();
            
            Planner.settings.get ("project-dialog-position", "(ii)", out window_x, out window_y);
            Planner.settings.get ("project-dialog-size", "(ii)", out rect.width, out rect.height);

            dialog.set_allocation (rect);
            dialog.move (window_x, window_y);
            dialog.show_all ();

            popover.popdown ();
        });

        delete_menu.clicked.connect (() => {
            popover.popdown ();

            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Delete project"),
                _("Are you sure you want to delete <b>%s</b>?".printf (Planner.utils.get_dialog_text (project.name))),
                "user-trash-full",
            Gtk.ButtonsType.CANCEL);

            var remove_button = new Gtk.Button.with_label (_("Delete"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                Planner.database.delete_project (project.id);
                if (project.is_todoist == 1) {
                    Planner.todoist.delete_project (project);
                }
            }

            message_dialog.destroy ();
        });

        show_completed_button.button_release_event.connect (() => {
            show_completed_switch.activate ();

            if (show_completed_switch.active) {
                project.show_completed = 0;
            } else {
                project.show_completed = 1;
            }

            Planner.database.project_show_completed (project);
            save (false);
            
            return Gdk.EVENT_STOP;
        });

        sort_date_menu.clicked.connect (() => {
            Planner.database.update_sort_order_project (project.id, 1);
            popover.popdown ();
        });

        sort_priority_menu.clicked.connect (() => {
            Planner.database.update_sort_order_project (project.id, 2);
            popover.popdown ();
        });

        sort_name_menu.clicked.connect (() => {
            Planner.database.update_sort_order_project (project.id, 3);
            popover.popdown ();
        });

        share_item.clicked.connect (() => {
            if (share_menu == null) {
                share_menu = new Gtk.Menu ();

                var share_mail = new Widgets.ImageMenuItem (_("Send by e-mail"), "internet-mail-symbolic");
                var share_markdown_menu = new Widgets.ImageMenuItem (_("Share on Markdown"), "planner-markdown-symbolic");
                var hide_items_menu = new Widgets.ImageMenuItem (_("Hide all tasks details"), "view-restore-symbolic");

                share_menu.add (share_mail);
                share_menu.add (share_markdown_menu);
                share_menu.add (hide_items_menu);
                share_menu.show_all ();

                share_mail.activate.connect (() => {
                    project.share_mail ();
                });
        
                share_markdown_menu.activate.connect (() => {
                    project.share_markdown ();
                });

                hide_items_menu.activate.connect (() => {
                    Planner.event_bus.hide_items_project (project.id);
                    popover.popdown ();
                });
            }

            share_menu.popup_at_pointer (null);
        });

        board_button.button_release_event.connect (() => {
            board_switch.activate ();

            if (board_switch.active) {
                project.is_kanban = 0;
                main_stack.visible_child_name = "project";
                list_view.add_sections ();
            } else {
                project.is_kanban = 1;
                main_stack.visible_child_name = "board";
                board_view.add_boards ();
            }
            
            save (false);
            return Gdk.EVENT_STOP;
        });
    }

    public void open_new_section () {
        Planner.event_bus.unselect_all ();

        if (new_section_popover == null) {
            build_new_section_popover ();
        }

        new_section_popover.show_all ();
        section_name_entry.grab_focus ();
    }

    private void build_new_section_popover () {
        new_section_popover = new Gtk.Popover (section_button);
        new_section_popover.get_style_context ().add_class ("popover-background");
        new_section_popover.position = Gtk.PositionType.BOTTOM;

        var name_label = new Granite.HeaderLabel (_("Name:"));

        section_name_entry = new Widgets.Entry ();
        section_name_entry.hexpand = true;

        var submit_button = new Gtk.Button ();
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var submit_spinner = new Gtk.Spinner ();
        submit_spinner.start ();

        var submit_stack = new Gtk.Stack ();
        submit_stack.expand = true;
        submit_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        submit_stack.add_named (new Gtk.Label (_("Add")), "label");
        submit_stack.add_named (submit_spinner, "spinner");

        submit_button.add (submit_stack);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("planner-button");

        var action_grid = new Gtk.Grid ();
        action_grid.expand = false;
        action_grid.halign = Gtk.Align.START;
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 6;
        action_grid.margin_top = 12;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        var popover_grid = new Gtk.Grid ();
        popover_grid.width_request = 250;
        popover_grid.margin = 6;
        popover_grid.margin_top = 0;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (name_label);
        popover_grid.add (section_name_entry);
        popover_grid.add (action_grid);

        new_section_popover.add (popover_grid);

        new_section_popover.closed.connect (() => {
            section_button.active = false;
        });

        submit_button.clicked.connect (insert_section);

        section_name_entry.activate.connect (() => {
            insert_section ();
        });

        section_name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                section_name_entry.text = "";
                new_section_popover.popdown ();
            }

            return false;
        });

        section_name_entry.changed.connect (() => {
            if (section_name_entry.text != "") {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }
        });

        cancel_button.clicked.connect (() => {
            section_name_entry.text = "";
            new_section_popover.popdown ();
        });

        Planner.todoist.section_added_started.connect ((id) => {
            if (temp_id_mapping == id) {
                submit_stack.visible_child_name = "spinner";
                popover_grid.sensitive = false;
            }
        });

        Planner.todoist.section_added_completed.connect ((id) => {
            if (temp_id_mapping == id) {
                submit_stack.visible_child_name = "label";
                temp_id_mapping = 0;

                popover_grid.sensitive = true;

                section_name_entry.text = "";
                new_section_popover.popdown ();
            }
        });

        Planner.todoist.section_added_error.connect ((id) => {
            if (temp_id_mapping == id) {
                submit_stack.visible_child_name = "label";
                temp_id_mapping = 0;

                popover_grid.sensitive = true;

                section_name_entry.text = "";
                new_section_popover.popdown ();
            }
        });
    }

    private void insert_section () {
        if (section_name_entry.text != "") {
            var section = new Objects.Section ();
            section.name = section_name_entry.text;
            section.project_id = project.id;
            section.is_todoist = project.is_todoist;

            if (project.is_todoist == 0) {
                section.id = Planner.utils.generate_id ();
                Planner.database.insert_section (section);

                section_name_entry.text = "";
                new_section_popover.popdown ();
            } else {
                var cancellable = new Cancellable ();
                temp_id_mapping = Planner.utils.generate_id ();
                section.is_todoist = 1;

                Planner.todoist.add_section.begin (section, cancellable, temp_id_mapping);
            }
        }
    }

    public void add_new_item (int index) {
        if (project.is_kanban == 1) {
            board_view.add_new_item (Planner.settings.get_enum ("new-tasks-position"));
        } else {
            list_view.add_new_item (Planner.settings.get_enum ("new-tasks-position"));
        }
    }
}
