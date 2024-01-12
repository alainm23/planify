/*
* Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
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

public class Layouts.Sidebar : Adw.Bin {
    private Gtk.FlowBox filters_flow;

    private Layouts.FilterPaneRow inbox_filter;
    private Layouts.FilterPaneRow today_filter;
    private Layouts.FilterPaneRow scheduled_filter;
    private Layouts.FilterPaneRow labels_filter;
    private Layouts.FilterPaneRow pinboard_filter;
    
    private Layouts.HeaderItem favorites_header;
    private Layouts.HeaderItem local_projects_header;
    private Layouts.HeaderItem todoist_projects_header;
    private Layouts.HeaderItem caldav_projects_header;
    private Layouts.HeaderItem google_projects_header;

    public Gee.HashMap <string, Layouts.ProjectRow> local_hashmap = new Gee.HashMap <string, Layouts.ProjectRow> ();
    public Gee.HashMap <string, Layouts.ProjectRow> todoist_hashmap = new Gee.HashMap <string, Layouts.ProjectRow> ();
    public Gee.HashMap <string, Layouts.ProjectRow> google_hashmap = new Gee.HashMap <string, Layouts.ProjectRow> ();
    public Gee.HashMap <string, Layouts.ProjectRow> caldav_hashmap = new Gee.HashMap <string, Layouts.ProjectRow> ();
    public Gee.HashMap <string, Layouts.ProjectRow> favorites_hashmap = new Gee.HashMap <string, Layouts.ProjectRow> ();

    public Sidebar () {
        Object ();
    }

    construct { 
        filters_flow = new Gtk.FlowBox () {
            homogeneous = true,
            row_spacing = 9,
            column_spacing = 9,
            margin_start = 3,
            margin_end = 3,
            min_children_per_line = 2
        };

        filters_flow.set_sort_func ((child1, child2) => {
            int item1 = ((Layouts.FilterPaneRow) child1).item_order ();
            int item2 = ((Layouts.FilterPaneRow) child2).item_order ();

            return item1 - item2;
        });

        filters_flow.set_filter_func ((child) => {
            var row = ((Layouts.FilterPaneRow) child);
            return row.active ();
        });

        inbox_filter = new Layouts.FilterPaneRow (FilterType.INBOX);
        today_filter = new Layouts.FilterPaneRow (FilterType.TODAY);
        scheduled_filter = new Layouts.FilterPaneRow (FilterType.SCHEDULED);
        labels_filter = new Layouts.FilterPaneRow (FilterType.LABELS);
        pinboard_filter = new Layouts.FilterPaneRow (FilterType.PINBOARD);

        filters_flow.append (inbox_filter);
        filters_flow.append (today_filter);
        filters_flow.append (scheduled_filter);
        filters_flow.append (labels_filter);
        filters_flow.append (pinboard_filter);

        favorites_header = new Layouts.HeaderItem (_("Favorites"));
        favorites_header.placeholder_message = _("No favorites available. Create one by clicking on the '+' button");
        favorites_header.margin_top = 6;

        local_projects_header = new Layouts.HeaderItem (_("On This Computer"));
        local_projects_header.placeholder_message = _("No project available. Create one by clicking on the '+' button");
        local_projects_header.margin_top = 6;

        todoist_projects_header = new Layouts.HeaderItem (_("Todoist"));
        todoist_projects_header.margin_top = 6;

        caldav_projects_header = new Layouts.HeaderItem (_("Nextcloud"));
        caldav_projects_header.margin_top = 6;

        google_projects_header = new Layouts.HeaderItem ();
        google_projects_header.margin_top = 6;

        var whats_new_icon = new Widgets.DynamicIcon.from_icon_name ("gift") {
            css_classes = { "gift-animation" }
        };
        
        var whats_new_label = new Gtk.Label (_("What’s new in Planify")) {
            css_classes = { "underline" }
        };

        var close_button = new Gtk.Button () {
            child = new Widgets.DynamicIcon.from_icon_name ("window-close"),
            css_classes = { "flat", "no-padding" },
            hexpand = true,
            halign = END,
            margin_end = 3
        };

        var whats_new_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            css_classes = { "card", "padding-9" },
            vexpand = true,
            valign = END,
            margin_start = 3,
            margin_end = 3,
            margin_top = 9,
            margin_bottom = 3
        };

        whats_new_box.append (whats_new_icon);
        whats_new_box.append (whats_new_label);
        whats_new_box.append (close_button);

        var whats_new_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SWING_UP,
            child = whats_new_box,
            reveal_child = verify_new_version ()
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_top = 3
        };

        content_box.append (filters_flow);
        content_box.append (favorites_header);
        content_box.append (local_projects_header);
        content_box.append (todoist_projects_header);
        content_box.append (caldav_projects_header);
        content_box.append (whats_new_revealer);

        var scrolled_window = new Widgets.ScrolledWindow (content_box);

        child = scrolled_window;
        update_projects_sort ();

        var add_local_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false,
            child = new Widgets.DynamicIcon.from_icon_name ("plus") {
                valign = Gtk.Align.CENTER,
                halign = Gtk.Align.CENTER,
            },
            css_classes = { Granite.STYLE_CLASS_FLAT, "header-item-button" }
        };

        local_projects_header.add_widget_end (add_local_button);
        add_local_button.clicked.connect (() => {
            prepare_new_project (BackendType.LOCAL);
        });

        var todoist_sync_button = new Widgets.SyncButton () {
            reveal_child = Services.Todoist.get_default ().is_logged_in ()
        };
        todoist_projects_header.add_widget_end (todoist_sync_button);
        
        var add_todoist_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false,
            child = new Widgets.DynamicIcon.from_icon_name ("plus") {
                valign = Gtk.Align.CENTER,
                halign = Gtk.Align.CENTER,
            },
            css_classes = { Granite.STYLE_CLASS_FLAT, "header-item-button" }
        };

        todoist_projects_header.add_widget_end (add_todoist_button);
        add_todoist_button.clicked.connect (() => {
            bool is_logged_in = Services.Todoist.get_default ().is_logged_in ();
            
            if (is_logged_in) {
                prepare_new_project (BackendType.TODOIST);
            }
        });

        var caldav_sync_button = new Widgets.SyncButton () {
            reveal_child = Services.CalDAV.get_default ().is_logged_in ()
        };
        caldav_projects_header.add_widget_end (caldav_sync_button);

        var add_caldav_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false,
            child = new Widgets.DynamicIcon.from_icon_name ("plus") {
                valign = Gtk.Align.CENTER,
                halign = Gtk.Align.CENTER,
            },
            css_classes = { Granite.STYLE_CLASS_FLAT, "header-item-button" }
        };

        caldav_projects_header.add_widget_end (add_caldav_button);
        add_caldav_button.clicked.connect (() => {
            bool is_logged_in = Services.CalDAV.get_default ().is_logged_in ();
            
            if (is_logged_in) {
                prepare_new_project (BackendType.CALDAV);
            }
        });

        Services.Settings.get_default ().settings.changed.connect ((key) => {
            if (key == "projects-sort-by" || key == "projects-ordered") {
                update_projects_sort ();
            } else if (key == "views-order-visible") {
                filters_flow.invalidate_sort ();
                filters_flow.invalidate_filter ();
            }
        });

        Services.EventBus.get_default ().inbox_project_changed.connect (() => {
            add_all_projects ();
            add_all_favorites ();

            var default_inbox = (DefaultInboxProject) Services.Settings.get_default ().settings.get_enum ("default-inbox");
            if (default_inbox == DefaultInboxProject.LOCAL) {
                string id = Services.Settings.get_default ().settings.get_string ("local-inbox-project-id");
                if (local_hashmap.has_key (id)) {
                    local_hashmap [id].hide_destroy ();
                    local_hashmap.unset (id);
                }
            } else if (default_inbox == DefaultInboxProject.TODOIST) {
                string id = Services.Settings.get_default ().settings.get_string ("todoist-inbox-project-id");
                if (todoist_hashmap.has_key (id)) {
                    todoist_hashmap [id].hide_destroy ();
                    todoist_hashmap.unset (id);
                }
            }
        });

        Services.Todoist.get_default ().log_in.connect (() => {
            todoist_projects_header.reveal = true;
            todoist_sync_button.reveal_child = true;
        });

        Services.Todoist.get_default ().log_out.connect (() => {
            todoist_projects_header.reveal = false;
            todoist_sync_button.reveal_child = false;
        });

        Services.CalDAV.get_default ().log_in.connect (() => {
            caldav_projects_header.reveal = true;
            caldav_sync_button.reveal_child = true;
        });

        Services.CalDAV.get_default ().log_out.connect (() => {
            caldav_projects_header.reveal = false;
            caldav_sync_button.reveal_child = false;
        });

        Services.Database.get_default ().project_deleted.connect ((project) => {
            if (favorites_hashmap.has_key (project.id)) {
                favorites_hashmap.unset (project.id);
            }

            if (local_hashmap.has_key (project.id)) {
                local_hashmap.unset (project.id);
            }

            if (todoist_hashmap.has_key (project.id)) {
                todoist_hashmap.unset (project.id);
            }

            if (caldav_hashmap.has_key (project.id)) {
                caldav_hashmap.unset (project.id);
            }
        });

        var whats_new_gesture = new Gtk.GestureClick ();
        whats_new_gesture.set_button (1);
        whats_new_box.add_controller (whats_new_gesture);

        whats_new_gesture.pressed.connect (() => {
			var dialog = new Dialogs.WhatsNew ();
			dialog.show ();

            update_version ();
            whats_new_revealer.reveal_child = verify_new_version ();
        });

        var close_gesture = new Gtk.GestureClick ();
        close_button.add_controller (close_gesture);
        close_gesture.pressed.connect (() => {
            close_gesture.set_state (Gtk.EventSequenceState.CLAIMED);

            update_version ();
            whats_new_revealer.reveal_child = verify_new_version ();
        });

        todoist_sync_button.clicked.connect (() => {
            Services.Todoist.get_default ().sync_async ();
        });

        Services.Todoist.get_default ().sync_started.connect (() => {
            todoist_sync_button.sync_started ();
        });
        
        Services.Todoist.get_default ().sync_finished.connect (() => {
            todoist_sync_button.sync_finished ();
        });

        caldav_sync_button.clicked.connect (() => {
            Services.CalDAV.get_default ().sync_async ();
        });

        Services.CalDAV.get_default ().sync_started.connect (() => {
            caldav_sync_button.sync_started ();
        });
        
        Services.CalDAV.get_default ().sync_finished.connect (() => {
            caldav_sync_button.sync_finished ();
        });
    }

    public void update_version () {
        Services.Settings.get_default ().settings.set_string ("version", Build.VERSION);
    }

    public bool verify_new_version () {
        return Services.Settings.get_default ().settings.get_string ("version") != Build.VERSION;
    }

    public void verify_todoist_account () {
        bool is_logged_in = Services.Todoist.get_default ().is_logged_in ();
        
        if (is_logged_in) {
            todoist_projects_header.reveal = true;
            todoist_projects_header.placeholder_message = _("No project available. Create one by clicking on the '+' button");
        } else {
            todoist_projects_header.placeholder_message = _("No account available, Sync one by clicking the '+' button");
        }
    }

    public void verify_google_account () {
        bool is_logged_in = Services.GoogleTasks.get_default ().is_logged_in ();
        
        if (is_logged_in) {
            google_projects_header.reveal = true;
            google_projects_header.placeholder_message = _("No project available. Create one by clicking on the '+' button");
        } else {
            google_projects_header.placeholder_message = _("No account available, Sync one by clicking the '+' button");
        }
    }

    public void verify_caldav_account () {
        bool is_logged_in = Services.CalDAV.get_default ().is_logged_in ();
        
        if (is_logged_in) {
            caldav_projects_header.reveal = true;
            caldav_projects_header.placeholder_message = _("No project available. Create one by clicking on the '+' button");
        } else {
            caldav_projects_header.placeholder_message = _("No account available, Sync one by clicking the '+' button");
        }
    }

    public void select_project (Objects.Project project) {
        Services.EventBus.get_default ().pane_selected (PaneType.PROJECT, project.id_string);
    }

    public void select_filter (FilterType filter_type) {
        Services.EventBus.get_default ().pane_selected (PaneType.FILTER, filter_type.to_string ());
    }

    public void init () {
        Services.Database.get_default ().project_added.connect (add_row_project);
        Services.Database.get_default ().project_updated.connect (update_projects_sort);

        Services.EventBus.get_default ().project_parent_changed.connect ((project, old_parent_id) => {
            if (old_parent_id == "") {
                if (local_hashmap.has_key (project.id_string)) {
                    local_hashmap [project.id_string].hide_destroy ();
                    local_hashmap.unset (project.id_string);
                }

                if (todoist_hashmap.has_key (project.id_string)) {
                    todoist_hashmap [project.id_string].hide_destroy ();
                    todoist_hashmap.unset (project.id_string);
                }
            }

            if (project.parent_id == "") {
                add_row_project (project);
            }
        });

        Services.EventBus.get_default ().favorite_toggled.connect ((project) => {
            if (favorites_hashmap.has_key (project.id_string)) {
                favorites_hashmap [project.id_string].hide_destroy ();
                favorites_hashmap.unset (project.id_string);
            } else {
                add_row_favorite (project);
            }

            favorites_header.reveal = favorites_hashmap.size > 0;
        });

        inbox_filter.init ();
        today_filter.init ();
        scheduled_filter.init ();
        labels_filter.init ();
        pinboard_filter.init ();
        
        local_projects_header.reveal = true;

        add_all_projects ();
        add_all_favorites ();

        verify_todoist_account ();
        verify_google_account ();
        verify_caldav_account ();
    }

    private void add_all_projects () {
        foreach (Objects.Project project in Services.Database.get_default ().projects) {
            add_row_project (project);
        }
    }

    private void add_all_favorites () {
        foreach (Objects.Project project in Services.Database.get_default ().projects) {
            add_row_favorite (project);
        }

        favorites_header.reveal = favorites_hashmap.size > 0;
    }

    private void add_row_favorite (Objects.Project project) {
        if (project.is_favorite) {
            if (!favorites_hashmap.has_key (project.id_string)) {
                favorites_hashmap [project.id_string] = new Layouts.ProjectRow (project, false, false);
                favorites_header.add_child (favorites_hashmap [project.id_string]);
            }
        }
    }

    private void add_row_project (Objects.Project project) {
        if (!project.is_inbox_project && project.parent_id == "") {
            if (project.backend_type == BackendType.TODOIST) {
                if (!todoist_hashmap.has_key (project.id_string)) {
                    todoist_hashmap [project.id_string] = new Layouts.ProjectRow (project);
                    todoist_projects_header.add_child (todoist_hashmap [project.id_string]);
                }
            } else if (project.backend_type == BackendType.GOOGLE_TASKS) {
                if (!google_hashmap.has_key (project.id_string)) {
                    google_hashmap [project.id_string] = new Layouts.ProjectRow (project);
                    google_projects_header.add_child (google_hashmap [project.id_string]);
                }
            } else if (project.backend_type == BackendType.LOCAL) {
                if (!local_hashmap.has_key (project.id_string)) {
                    local_hashmap [project.id_string] = new Layouts.ProjectRow (project);
                    local_projects_header.add_child (local_hashmap [project.id_string]);
                }
            } else if (project.backend_type == BackendType.CALDAV) {
                if (!caldav_hashmap.has_key (project.id_string)) {
                    caldav_hashmap [project.id_string] = new Layouts.ProjectRow (project);
                    caldav_projects_header.add_child (caldav_hashmap [project.id_string]);
                }
            }
        }
    }

    private void prepare_new_project (BackendType backend_type) {
        var dialog = new Dialogs.Project.new (backend_type);
        dialog.show ();
    }

    private void update_projects_sort () {
        if (Services.Settings.get_default ().settings.get_enum ("projects-sort-by") == 1) {
            local_projects_header.set_sort_func (projects_sort_func);
            todoist_projects_header.set_sort_func (projects_sort_func);
        } else {
            local_projects_header.set_sort_func (null);
            todoist_projects_header.set_sort_func (null);
        }
    }

    private int projects_sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
        Objects.Project project1 = ((Layouts.ProjectRow) lbrow).project;
        Objects.Project project2 = ((Layouts.ProjectRow) lbbefore).project;
        int ordered = Services.Settings.get_default ().settings.get_enum ("projects-ordered");
        return ordered == 0 ? project2.name.collate (project1.name) : project1.name.collate (project2.name);
    }
}
