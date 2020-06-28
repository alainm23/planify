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

public enum QuickFindResultType {
    NONE,
    ITEM,
    PROJECT,
    VIEW,
    PRIORITY,
    LABEL
}

public class Dialogs.QuickFind : Gtk.Dialog {
    SearchItem current_item = null;
    public QuickFind () {
        Object (
            transient_for: Planner.instance.main_window,
            deletable: false,
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            // modal: true,
            use_header_bar: 1
        );
    }

    construct {
        get_style_context ().add_class ("quick-find-dialog");
        // if (get_os_info ("PRETTY_NAME") == null || get_os_info ("PRETTY_NAME").index_of ("elementary") == -1) {
            // get_style_context ().add_class ("dialog-patch");
            // width_request = 465;
            // height_request = 255;
        // } else {
            width_request = 575;
            height_request = 455;
        // }

        int window_x, window_y;
        int window_width, width_height;

        Planner.settings.get ("window-position", "(ii)", out window_x, out window_y);
        Planner.settings.get ("window-size", "(ii)", out window_width, out width_height);

        move (window_x + ((window_width - width_request) / 2), window_y + 48);

        var views = new Gee.ArrayList<string> ();
        views.add ("""
            {
                "name": "%s",
                "id": 0
            }
        """.printf (_("Inbox")));

        views.add ("""
            {
                "name": "%s",
                "id": 1
            }
        """.printf (_("Today")));

        views.add ("""
            {
                "name": "%s",
                "id": 2
            }
        """.printf (_("Upcoming")));

        views.add ("""
            {
                "name": "%s",
                "id": 3
            }
        """.printf (_("Completed")));

        var priorities = new Gee.ArrayList<string> ();
        priorities.add ("""
            {
                "name": "%s",
                "keywords": "p1",
                "id": 4
            }
        """.printf (_("Priority 1")));

        priorities.add ("""
            {
                "name": "%s",
                "keywords": "p2",
                "id": 3
            }
        """.printf (_("Priority 2")));

        priorities.add ("""
            {
                "name": "%s",
                "keywords": "p3",
                "id": 2
            }
        """.printf (_("Priority 3")));

        priorities.add ("""
            {
                "name": "%s",
                "keywords": "p4",
                "id": 1
            }
        """.printf (_("Priority 4")));

        get_header_bar ().visible = false;
        get_header_bar ().no_show_all = true;

        var search_label = new Gtk.Label (_("Search"));
        search_label.get_style_context ().add_class ("font-weight-600");
        search_label.get_style_context ().add_class ("welcome");
        search_label.width_request = 90;
        search_label.margin_start = 6;
        search_label.xalign = (float) 0.5;

        var search_revealer = new Gtk.Revealer ();
        search_revealer.reveal_child = false;
        search_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        search_revealer.add (search_label);
        search_revealer.reveal_child = true;

        var search_entry = new Gtk.SearchEntry ();
        search_entry.hexpand = true;
        search_entry.placeholder_text = _("Quick Find");

        var top_grid = new Gtk.Grid ();
        top_grid.column_spacing = 6;
        top_grid.margin_end = 6;
        top_grid.margin_top = 6;
        top_grid.add (search_revealer);
        top_grid.add (search_entry);

        var placeholder_image = new Gtk.Image ();
        placeholder_image.gicon = new ThemedIcon ("folder-saved-search-symbolic");
        placeholder_image.pixel_size = 32;

        var placeholder_label = new Gtk.Label (_("Quickly switch projects and views, find tasks, search by labels."));
        placeholder_label.wrap = true;
        placeholder_label.max_width_chars = 32;
        placeholder_label.justify = Gtk.Justification.CENTER;
        placeholder_label.show ();

        var placeholder_grid = new Gtk.Grid ();
        placeholder_grid.get_style_context ().add_class ("dim-label");
        placeholder_grid.orientation = Gtk.Orientation.VERTICAL;
        placeholder_grid.halign = Gtk.Align.CENTER;
        placeholder_grid.row_spacing = 12;
        placeholder_grid.margin_top = 32;
        placeholder_grid.add (placeholder_image);
        placeholder_grid.add (placeholder_label);
        placeholder_grid.show_all ();

        var listbox = new Gtk.ListBox ();
        listbox.hexpand = true;
        listbox.set_placeholder (placeholder_grid);

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        listbox_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        listbox_scrolled.expand = true;
        listbox_scrolled.add (listbox);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_top = 6;

        var up_label = new Gtk.Label ("<small>%s</small>".printf (_("UP")));
        up_label.get_style_context ().add_class ("keycap");
        up_label.use_markup = true;
        up_label.valign = Gtk.Align.CENTER;

        var down_label = new Gtk.Label ("<small>%s</small>".printf (_("DOWN")));
        down_label.get_style_context ().add_class ("keycap");
        down_label.use_markup = true;
        down_label.valign = Gtk.Align.CENTER;

        var enter_label = new Gtk.Label ("<small>%s</small>".printf (_("ENTER")));
        enter_label.get_style_context ().add_class ("keycap");
        enter_label.use_markup = true;
        enter_label.valign = Gtk.Align.CENTER;

        var esc_label = new Gtk.Label ("<small>%s</small>".printf (_("ESC")));
        esc_label.get_style_context ().add_class ("keycap");
        esc_label.use_markup = true;
        esc_label.valign = Gtk.Align.CENTER;

        var info_grid = new Gtk.Grid ();
        info_grid.halign = Gtk.Align.CENTER;
        info_grid.hexpand = true;
        info_grid.column_spacing = 6;
        info_grid.margin = 6;
        info_grid.add (new Gtk.Label (_("Use")));
        info_grid.add (up_label);
        info_grid.add (down_label);
        info_grid.add (new Gtk.Label (_("to navigate and")));
        info_grid.add (enter_label);
        info_grid.add (new Gtk.Label (_("to select,")));
        info_grid.add (esc_label);
        info_grid.add (new Gtk.Label (_("to close.")));

        var info_revealer = new Gtk.Revealer ();
        info_revealer.reveal_child = false;
        info_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        info_revealer.add (info_grid);
        info_revealer.reveal_child = true;

        var action_bar = new Gtk.ActionBar ();
        action_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        action_bar.add (info_revealer);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_grid, false, false, 0);
        main_box.pack_start (separator, false, false, 0);
        main_box.pack_start (listbox_scrolled, true, true, 0);
        main_box.pack_end (action_bar, false, true, 0);

        get_content_area ().add (main_box);

        // Add Default Filters
        foreach (var label in Planner.database.get_all_labels ()) {
            var row = new SearchItem (
                QuickFindResultType.LABEL,
                label.to_json (),
                search_entry.text
            );

            listbox.add (row);
            listbox.show_all ();
        }

        foreach (var priority in priorities) {
            var row = new SearchItem (
                QuickFindResultType.PRIORITY,
                priority,
                search_entry.text
            );
    
            listbox.add (row);
            listbox.show_all ();
        }
        
        QuickFindResultType result_type = QuickFindResultType.NONE;
        listbox.foreach ((widget) => {
            var row = (SearchItem) widget;

            if (row.result_type != result_type) {
                row.header_label.opacity = 1;
            }

            result_type = row.result_type;
        });

        search_entry.search_changed.connect (() => {
            listbox.foreach ((widget) => {
                widget.destroy ();
            });

            if (search_entry.text.strip () != "") {
                search_revealer.reveal_child = true;
                info_revealer.reveal_child = false;
                if (search_entry.text.down () == _("Labels").down ()) {
                    foreach (var label in Planner.database.get_all_labels ()) {
                        var row = new SearchItem (
                            QuickFindResultType.LABEL,
                            label.to_json (),
                            search_entry.text
                        );
    
                        listbox.add (row);
                        listbox.show_all ();
                    }
                }

                if (search_entry.text.down () == _("Projects").down ()) {
                    foreach (var project in Planner.database.get_all_projects ()) {
                        if (project.inbox_project == 0) {
                            var row = new SearchItem (
                                QuickFindResultType.PROJECT,
                                project.to_json (),
                                search_entry.text
                            );
    
                            listbox.add (row);
                            listbox.show_all ();
                        }
                    }
                }

                foreach (string view in views) {
                    if (search_entry.text.down () in Planner.todoist.get_string_member_by_object (view, "name").down ()) {
                        var row = new SearchItem (
                            QuickFindResultType.VIEW,
                            view,
                            search_entry.text
                        );

                        listbox.add (row);
                        listbox.show_all ();
                    }
                }

                foreach (string priority in priorities) {
                    if (search_entry.text.down () in Planner.todoist.get_string_member_by_object (priority, "name").down () ||
                    search_entry.text.down () in Planner.todoist.get_string_member_by_object (priority, "keywords").down ()) {
                        var row = new SearchItem (
                            QuickFindResultType.PRIORITY,
                            priority,
                            search_entry.text
                        );

                        listbox.add (row);
                        listbox.show_all ();
                    }
                }

                foreach (var project in Planner.database.get_all_projects_by_search (search_entry.text)) {
                    if (project.inbox_project == 0) {
                        var row = new SearchItem (
                            QuickFindResultType.PROJECT,
                            project.to_json (),
                            search_entry.text
                        );

                        listbox.add (row);
                        listbox.show_all ();
                    }
                }

                foreach (var label in Planner.database.get_labels_by_search (search_entry.text)) {
                    var row = new SearchItem (
                        QuickFindResultType.LABEL,
                        label.to_json (),
                        search_entry.text
                    );

                    listbox.add (row);
                    listbox.show_all ();
                }

                foreach (var item in Planner.database.get_items_by_search (search_entry.text)) {
                    var row = new SearchItem (
                        QuickFindResultType.ITEM,
                        item.to_json (),
                        search_entry.text
                    );

                    listbox.add (row);
                    listbox.show_all ();
                }

                result_type = QuickFindResultType.NONE;
                listbox.foreach ((widget) => {
                    var row = (SearchItem) widget;

                    if (row.result_type != result_type) {
                        row.header_label.opacity = 1;
                    }

                    result_type = row.result_type;
                });
            } else {
                search_revealer.reveal_child = false;
            }
        });

        this.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                popdown ();
            }

            return false;
        });

        this.focus_out_event.connect (() => {
            popdown ();

            return false;
        });

        this.key_press_event.connect ((event) => {
            var key = Gdk.keyval_name (event.keyval).replace ("KP_", "");

            if (key == "Up" || key == "Down") {
                return false;
            } else if (key == "Enter" || key == "Return" || key == "KP_Enter") {
                row_activated (listbox.get_selected_row ());
                return false;
            } else {
                if (!search_entry.has_focus) {
                    search_entry.grab_focus ();
                    search_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, 0, false);
                }

                return false;
            }

            return true;
        });

        listbox.row_activated.connect ((row) => {
            row_activated (row);
        });

        listbox.row_selected.connect ((row) => {
            if (row != null) {
                info_revealer.reveal_child = false;
                
                var item = (SearchItem) row;
                item.shortcut_revealer.reveal_child = true;
                if (current_item != null) {
                    current_item.shortcut_revealer.reveal_child = false;
                }
                current_item = item;
            }
        });
    }

    private void row_activated (Gtk.ListBoxRow row) {
        var item = (SearchItem) row;

        if (item.result_type == QuickFindResultType.PROJECT) {
            Planner.instance.main_window.go_project (
                Planner.todoist.get_int_member_by_object (item.object, "id")
            );
        } else if (item.result_type == QuickFindResultType.VIEW) {
            Planner.instance.main_window.go_view (
                (int32) Planner.todoist.get_int_member_by_object (item.object, "id")
            );
        } else if (item.result_type == QuickFindResultType.ITEM) {
            Planner.instance.main_window.go_item (
                Planner.todoist.get_int_member_by_object (item.object, "id")
            );
        } else if (item.result_type == QuickFindResultType.LABEL) {
            Planner.instance.main_window.go_label (
                Planner.todoist.get_int_member_by_object (item.object, "id")
            );
        } else if (item.result_type == QuickFindResultType.PRIORITY) {
            Planner.instance.main_window.go_priority (
                (int32) Planner.todoist.get_int_member_by_object (item.object, "id")
            );
        }

        popdown ();
    }

    private void popdown () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return false;
        });
    }
}

public class SearchItem : Gtk.ListBoxRow {
    public QuickFindResultType result_type { get; construct set; }

    public Gtk.Label header_label;
    public Gtk.Revealer shortcut_revealer;
    public string object { get; construct; }
    public string search_term { get; construct; }

    public SearchItem (QuickFindResultType result_type, string object, string search_term) {
        Object (
            result_type: result_type,
            object: object,
            search_term: search_term
        );
    }

    construct {
        get_style_context ().add_class ("searchitem-row");
        var shortcut_label = new Gtk.Label ("<small>%s</small>".printf (_("Enter")));
        shortcut_label.get_style_context ().add_class ("keycap");
        shortcut_label.use_markup = true;
        shortcut_label.valign = Gtk.Align.CENTER;

        shortcut_revealer = new Gtk.Revealer ();
        shortcut_revealer.reveal_child = false;
        shortcut_revealer.halign = Gtk.Align.END;
        shortcut_revealer.hexpand = true;
        shortcut_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        shortcut_revealer.add (shortcut_label);
        shortcut_revealer.reveal_child = false;

        if (result_type == QuickFindResultType.ITEM) {
            header_label = new Gtk.Label (_("Tasks"));
            header_label.get_style_context ().add_class ("welcome");
            header_label.get_style_context ().add_class ("font-weight-600");
            header_label.width_request = 73;
            header_label.xalign = 1;
            header_label.margin_end = 29;
            header_label.opacity = 0;

            var checked_button = new Gtk.CheckButton ();
            checked_button.valign = Gtk.Align.CENTER;
            checked_button.get_style_context ().add_class ("checklist-button");

            var content_label = new Gtk.Label (
                markup_string_with_search (
                    Planner.todoist.get_string_member_by_object (object, "content"),
                    search_term
                )
            );
            content_label.ellipsize = Pango.EllipsizeMode.END;
            content_label.xalign = 0;
            content_label.use_markup = true;
            content_label.tooltip_text = Planner.todoist.get_string_member_by_object (object, "content");

            var grid = new Gtk.Grid ();
            grid.margin = 3;
            grid.margin_start = 6;
            grid.margin_end = 6;
            grid.column_spacing = 6;
            grid.add (checked_button);
            grid.add (content_label);
            grid.add (shortcut_revealer);

            var main_grid = new Gtk.Grid ();
            main_grid.attach (header_label, 0, 0, 1, 1);
            main_grid.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 1, 0, 1, 1);
            main_grid.attach (grid, 2, 0, 1, 1);

            add (main_grid);
        } else if (result_type == QuickFindResultType.PROJECT) {
            header_label = new Gtk.Label (_("Projects"));
            header_label.get_style_context ().add_class ("welcome");
            header_label.get_style_context ().add_class ("font-weight-600");
            header_label.width_request = 73;
            header_label.xalign = 1;
            header_label.margin_end = 29;
            header_label.opacity = 0;

            var project_progress = new Widgets.ProjectProgress (10);
            project_progress.margin = 1;
            project_progress.line_width = 0;
            project_progress.valign = Gtk.Align.CENTER;
            project_progress.halign = Gtk.Align.CENTER;
            project_progress.progress_fill_color = Planner.utils.get_color (
                (int32) Planner.todoist.get_int_member_by_object (object, "color")
            );
            project_progress.percentage = get_percentage (
                Planner.database.get_count_checked_items_by_project (Planner.todoist.get_int_member_by_object (object, "id")),
                Planner.database.get_all_count_items_by_project (Planner.todoist.get_int_member_by_object (object, "id"))
            );


            var progress_grid = new Gtk.Grid ();
            progress_grid.get_style_context ().add_class ("project-progress-%s".printf (
                Planner.todoist.get_int_member_by_object (object, "id").to_string ()
            ));
            progress_grid.add (project_progress);
            progress_grid.valign = Gtk.Align.CENTER;
            progress_grid.halign = Gtk.Align.CENTER;

            var content_label = new Gtk.Label (
                markup_string_with_search (
                    Planner.todoist.get_string_member_by_object (object, "name"),
                    search_term
                )
            );
            content_label.ellipsize = Pango.EllipsizeMode.END;
            content_label.xalign = 0;
            content_label.use_markup = true;
            content_label.tooltip_text = Planner.todoist.get_string_member_by_object (object, "name");

            var grid = new Gtk.Grid ();
            grid.margin = 3;
            grid.margin_start = 6;
            grid.margin_end = 6;
            grid.column_spacing = 6;
            grid.add (progress_grid);
            grid.add (content_label);
            grid.add (shortcut_revealer);

            var main_grid = new Gtk.Grid ();
            main_grid.attach (header_label, 0, 0, 1, 1);
            main_grid.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 1, 0, 1, 1);
            main_grid.attach (grid, 2, 0, 1, 1);

            add (main_grid);
        } else if (result_type == QuickFindResultType.VIEW) {
            header_label = new Gtk.Label (_("Views"));
            header_label.get_style_context ().add_class ("welcome");
            header_label.get_style_context ().add_class ("font-weight-600");
            header_label.width_request = 73;
            header_label.xalign = 1;
            header_label.margin_end = 29;
            header_label.opacity = 0;

            var icon = new Gtk.Image ();
            icon.halign = Gtk.Align.CENTER;
            icon.valign = Gtk.Align.CENTER;
            icon.pixel_size = 12;

            if (Planner.todoist.get_int_member_by_object (object, "id") == 0) {
                icon.gicon = new ThemedIcon ("mail-mailbox-symbolic");
                icon.get_style_context ().add_class ("inbox-icon");
            } else if (Planner.todoist.get_int_member_by_object (object, "id") == 1) {
                icon.gicon = new ThemedIcon ("help-about-symbolic");
                icon.get_style_context ().add_class ("today-icon");
            } else if (Planner.todoist.get_int_member_by_object (object, "id") == 2) {
                icon.gicon = new ThemedIcon ("x-office-calendar-symbolic");
                icon.get_style_context ().add_class ("upcoming-icon");
                icon.margin_start = 1;
            } else if (Planner.todoist.get_int_member_by_object (object, "id") == 3) {
                icon.gicon = new ThemedIcon ("emblem-default-symbolic");
                icon.get_style_context ().add_class ("completed-icon");
            }

            var content_label = new Gtk.Label (
                markup_string_with_search (
                    Planner.todoist.get_string_member_by_object (object, "name"),
                    search_term
                )
            );
            content_label.ellipsize = Pango.EllipsizeMode.END;
            content_label.xalign = 0;
            content_label.use_markup = true;

            var grid = new Gtk.Grid ();
            grid.margin = 3;
            grid.margin_start = 5;
            grid.column_spacing = 5;
            grid.add (icon);
            grid.add (content_label);
            grid.add (shortcut_revealer);
            
            var main_grid = new Gtk.Grid ();
            main_grid.attach (header_label, 0, 0, 1, 1);
            main_grid.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 1, 0, 1, 1);
            main_grid.attach (grid, 2, 0, 1, 1);

            add (main_grid);
        } else if (result_type == QuickFindResultType.LABEL) {
            header_label = new Gtk.Label (_("Labels"));
            header_label.get_style_context ().add_class ("welcome");
            header_label.get_style_context ().add_class ("font-weight-600");
            header_label.width_request = 73;
            header_label.xalign = 1;
            header_label.margin_end = 29;
            header_label.opacity = 0;

            var icon = new Gtk.Image ();
            icon.halign = Gtk.Align.CENTER;
            icon.valign = Gtk.Align.CENTER;
            icon.pixel_size = 14;
            icon.gicon = new ThemedIcon ("tag-symbolic");
            icon.get_style_context ().add_class ("label-color-%s".printf (
                Planner.todoist.get_int_member_by_object (object, "color").to_string ()
            ));

            var content_label = new Gtk.Label (
                markup_string_with_search (
                    Planner.todoist.get_string_member_by_object (object, "name"),
                    search_term
                )
            );
            content_label.ellipsize = Pango.EllipsizeMode.END;
            content_label.xalign = 0;
            content_label.use_markup = true;
            content_label.margin_bottom = 1;
            content_label.tooltip_text = Planner.todoist.get_string_member_by_object (object, "name");

            var grid = new Gtk.Grid ();
            grid.margin = 3;
            grid.margin_start = 6;
            grid.margin_end = 6;
            grid.column_spacing = 6;
            grid.add (icon);
            grid.add (content_label);
            grid.add (shortcut_revealer);

            var main_grid = new Gtk.Grid ();
            main_grid.attach (header_label, 0, 0, 1, 1);
            main_grid.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 1, 0, 1, 1);
            main_grid.attach (grid, 2, 0, 1, 1);

            add (main_grid);
        } else if (result_type == QuickFindResultType.PRIORITY) {
            header_label = new Gtk.Label (_("Priorities"));
            header_label.get_style_context ().add_class ("welcome");
            header_label.get_style_context ().add_class ("font-weight-600");
            header_label.width_request = 73;
            header_label.xalign = 1;
            header_label.margin_end = 29;
            header_label.opacity = 0;

            var icon = new Gtk.Image ();
            icon.halign = Gtk.Align.CENTER;
            icon.valign = Gtk.Align.CENTER;
            icon.pixel_size = 16;

            if (Planner.todoist.get_int_member_by_object (object, "id") == 1) {
                if (Planner.settings.get_enum ("appearance") == 0) {
                    icon.gicon = new ThemedIcon ("flag-outline-light");
                } else {
                    icon.gicon = new ThemedIcon ("flag-outline-dark");
                }
            } else if (Planner.todoist.get_int_member_by_object (object, "id") == 2) {
                icon.gicon = new ThemedIcon ("priority-2");
            } else if (Planner.todoist.get_int_member_by_object (object, "id") == 3) {
                icon.gicon = new ThemedIcon ("priority-3");
            } else if (Planner.todoist.get_int_member_by_object (object, "id") == 4) {
                icon.gicon = new ThemedIcon ("priority-4");
            }

            var content_label = new Gtk.Label (
                markup_string_with_search (
                    Planner.todoist.get_string_member_by_object (object, "name"),
                    search_term
                )
            );
            content_label.ellipsize = Pango.EllipsizeMode.END;
            content_label.xalign = 0;
            content_label.use_markup = true;

            var grid = new Gtk.Grid ();
            grid.margin = 3;
            grid.margin_start = 5;
            grid.margin_end = 6;
            grid.column_spacing = 5;
            grid.add (icon);
            grid.add (content_label);
            grid.add (shortcut_revealer);

            var main_grid = new Gtk.Grid ();
            main_grid.attach (header_label, 0, 0, 1, 1);
            main_grid.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 1, 0, 1, 1);
            main_grid.attach (grid, 2, 0, 1, 1);

            add (main_grid);
        }
    }

    private static string markup_string_with_search (string text, string pattern) {
        const string MARKUP = "%s";

        if (pattern == "") {
            return MARKUP.printf (Markup.escape_text (text));
        }

        // if no text found, use pattern
        if (text == "") {
            return MARKUP.printf (Markup.escape_text (pattern));
        }

        var matchers = Synapse.Query.get_matchers_for_query (
            pattern,
            0,
            RegexCompileFlags.OPTIMIZE | RegexCompileFlags.CASELESS
        );

        string? highlighted = null;
        foreach (var matcher in matchers) {
            MatchInfo mi;
            if (matcher.key.match (text, 0, out mi)) {
                int start_pos;
                int end_pos;
                int last_pos = 0;
                int cnt = mi.get_match_count ();
                StringBuilder res = new StringBuilder ();
                for (int i = 1; i < cnt; i++) {
                    mi.fetch_pos (i, out start_pos, out end_pos);
                    warn_if_fail (start_pos >= 0 && end_pos >= 0);
                    res.append (Markup.escape_text (text.substring (last_pos, start_pos - last_pos)));
                    last_pos = end_pos;
                    res.append (Markup.printf_escaped ("<b>%s</b>", mi.fetch (i)));
                    if (i == cnt - 1) {
                        res.append (Markup.escape_text (text.substring (last_pos)));
                    }
                }
                highlighted = res.str;
                break;
            }
        }

        if (highlighted != null) {
            return MARKUP.printf (highlighted);
        } else {
            return MARKUP.printf (Markup.escape_text (text));
        }
    }

    private double get_percentage (int a, int b) {
        return (double) a / (double) b;
    }
}

namespace Synapse {
    [Flags]
    public enum QueryFlags {
        /* HowTo create categories (32bit).
        * Authored by Alberto Aldegheri <albyrock87+dev@gmail.com>
        * Categories are "stored" in 3 Levels:
        *  Super-Category
        *  -> Category
        *  ----> Sub-Category
        * ------------------------------------
        * if (Super-Category does NOT have childs):
        *    SUPER = 1 << FreeBitPosition
        * else:
        *    if (Category does NOT have childs)
        *      CATEGORY = 1 << FreeBitPosition
        *    else
        *      SUB = 1 << FreeBitPosition
        *      CATEGORY = OR ([subcategories, ...]);
        *
        *    SUPER = OR ([categories, ...]);
        *
        *
        * Remember:
        *   if you add or remove a category,
        *   change labels in UIInterface.CategoryConfig.init_labels
        *
        */
        INCLUDE_REMOTE = 1 << 0,
        UNCATEGORIZED = 1 << 1,

        APPLICATIONS = 1 << 2,

        ACTIONS = 1 << 3,

        AUDIO = 1 << 4,
        VIDEO = 1 << 5,
        DOCUMENTS = 1 << 6,
        IMAGES = 1 << 7,
        FILES = AUDIO | VIDEO | DOCUMENTS | IMAGES,

        PLACES = 1 << 8,

        INTERNET = 1 << 9,

        TEXT = 1 << 10,

        CONTACTS = 1 << 11,

        ALL = 0xFFFFFFFF,
        LOCAL_CONTENT = ALL ^ QueryFlags.INCLUDE_REMOTE
    }

    [Flags]
    public enum MatcherFlags {
        NO_REVERSED = 1 << 0,
        NO_SUBSTRING = 1 << 1,
        NO_PARTIAL = 1 << 2,
        NO_FUZZY = 1 << 3
    }

    public struct Query {
        string query_string;
        string query_string_folded;
        Cancellable cancellable;
        QueryFlags query_type;
        uint max_results;
        uint query_id;

        public Query (
            uint query_id,
            string query,
            QueryFlags flags = QueryFlags.LOCAL_CONTENT,
            uint num_results = 96
        ) {
            this.query_id = query_id;
            this.query_string = query;
            this.query_string_folded = query.casefold ();
            this.query_type = flags;
            this.max_results = num_results;
        }

        public bool is_cancelled () {
            return cancellable.is_cancelled ();
        }

        public static Gee.List<Gee.Map.Entry<Regex, int>> get_matchers_for_query (
            string query,
            MatcherFlags match_flags = 0,
            RegexCompileFlags flags = GLib.RegexCompileFlags.OPTIMIZE
        ) {
            /* create a couple of regexes and try to help with matching
            * match with these regular expressions (with descending score):
            * 1) ^query$
            * 2) ^query
            * 3) \bquery
            * 4) split to words and seach \bword1.+\bword2 (if there are 2+ words)
            * 5) query
            * 6) split to characters and search \bq.+\bu.+\be.+\br.+\by
            * 7) split to characters and search \bq.*u.*e.*r.*y
            *
            * The set of returned regular expressions depends on MatcherFlags.
            */

            var results = new Gee.HashMap<Regex, int> ();
            Regex re;

            try {
                re = new Regex ("^(%s)$".printf (Regex.escape_string (query)), flags);
                results[re] = Match.Score.HIGHEST;
            } catch (RegexError err) { }

            try {
                re = new Regex ("^(%s)".printf (Regex.escape_string (query)), flags);
                results[re] = Match.Score.EXCELLENT;
            } catch (RegexError err) { }

            try {
                re = new Regex ("\\b(%s)".printf (Regex.escape_string (query)), flags);
                results[re] = Match.Score.VERY_GOOD;
            } catch (RegexError err) { }

            // split to individual chars
            string[] individual_words = Regex.split_simple ("\\s+", query.strip ());
            if (individual_words.length >= 2) {
                string[] escaped_words = {};
                foreach (unowned string word in individual_words) {
                    escaped_words += Regex.escape_string (word);
                }
                string pattern = "\\b(%s)".printf (string.joinv (").+\\b(", escaped_words));

                try {
                    re = new Regex (pattern, flags);
                    results[re] = Match.Score.GOOD;
                } catch (RegexError err) { }

                if (!(MatcherFlags.NO_REVERSED in match_flags)) {
                    if (escaped_words.length == 2) {
                        var reversed = "\\b(%s)".printf (
                            string.join (").+\\b(", escaped_words[1], escaped_words[0], null)
                        );
                        try {
                            re = new Regex (reversed, flags);
                            results[re] = Match.Score.GOOD - Match.Score.INCREMENT_MINOR;
                        } catch (RegexError err) { }
                    } else {
                        // not too nice, but is quite fast to compute
                        var orred = "\\b((?:%s))".printf (string.joinv (")|(?:", escaped_words));
                        var any_order = "";
                        for (int i = 0; i < escaped_words.length; i++) {
                            bool is_last = i == escaped_words.length - 1;
                            any_order += orred;
                            if (!is_last) {
                                any_order += ".+";
                            }
                        }
                        try {
                            re = new Regex (any_order, flags);
                            results[re] = Match.Score.AVERAGE + Match.Score.INCREMENT_MINOR;
                        } catch (RegexError err) { }
                    }
                }
            }

            if (!(MatcherFlags.NO_SUBSTRING in match_flags)) {
                try {
                    re = new Regex ("(%s)".printf (Regex.escape_string (query)), flags);
                    results[re] = Match.Score.BELOW_AVERAGE;
                } catch (RegexError err) { }
            }

            // split to individual characters
            string[] individual_chars = Regex.split_simple ("\\s*", query);
            string[] escaped_chars = {};
            foreach (unowned string word in individual_chars) {
                escaped_chars += Regex.escape_string (word);
            }

            // make  "aj" match "Activity Journal"
            if (
                !(MatcherFlags.NO_PARTIAL in match_flags)
                && individual_words.length == 1
                && individual_chars.length <= 5
            ) {
                string pattern = "\\b(%s)".printf (string.joinv (").+\\b(", escaped_chars));

                try {
                    re = new Regex (pattern, flags);
                    results[re] = Match.Score.ABOVE_AVERAGE;
                } catch (RegexError err) { }
            }

            if (!(MatcherFlags.NO_FUZZY in match_flags) && escaped_chars.length > 0) {
                string pattern = "\\b(%s)".printf (string.joinv (").*(", escaped_chars));

                try {
                    re = new Regex (pattern, flags);
                    results[re] = Match.Score.POOR;
                } catch (RegexError err) { }
            }

            var sorted_results = new Gee.ArrayList<Gee.Map.Entry<Regex, int>> ();
            var entries = results.entries;

            sorted_results.set_data ("entries-ref", entries);
            sorted_results.add_all (entries);
            sorted_results.sort ((a, b) => {
                unowned Gee.Map.Entry<Regex, int> e1 = (Gee.Map.Entry<Regex, int>) a;
                unowned Gee.Map.Entry<Regex, int> e2 = (Gee.Map.Entry<Regex, int>) b;
                return e2.value - e1.value;
            });

            return sorted_results;
        }
    }
}

public enum Synapse.MatchType {
    UNKNOWN = 0,
    TEXT,
    APPLICATION,
    GENERIC_URI,
    ACTION,
    SEARCH,
    CONTACT
}

public abstract class Synapse.Match: GLib.Object {
    public enum Score {
        INCREMENT_MINOR = 2000,
        INCREMENT_SMALL = 5000,
        INCREMENT_MEDIUM = 10000,
        INCREMENT_LARGE = 20000,
        URI_PENALTY = 15000,

        POOR = 50000,
        BELOW_AVERAGE = 60000,
        AVERAGE = 70000,
        ABOVE_AVERAGE = 75000,
        GOOD = 80000,
        VERY_GOOD = 85000,
        EXCELLENT = 90000,

        HIGHEST = 100000
    }

    // properties
    public string title { get; construct set; default = ""; }
    public string description { get; set; default = ""; }
    public string? icon_name { get; construct set; default = null; }
    public bool has_thumbnail { get; construct set; default = false; }
    public string? thumbnail_path { get; construct set; default = null; }
    public Synapse.MatchType match_type { get; construct set; default = Synapse.MatchType.UNKNOWN; }

    public virtual void execute (Synapse.Match? match) {
        critical ("execute () is not implemented");
    }

    public virtual void execute_with_target (Synapse.Match? source, Synapse.Match? target = null) {
        if (target == null) {
            execute (source);
        } else {
            critical ("execute () is not implemented");
        }
    }

    public virtual bool needs_target () {
        return false;
    }

    public virtual Synapse.QueryFlags target_flags () {
        return Synapse.QueryFlags.ALL;
    }

    public signal void executed ();
}
