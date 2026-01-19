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

public class Layouts.SidebarSourceRow : Gtk.ListBoxRow {
    public Objects.Source source { get; construct; }

    private Layouts.HeaderItem group;
    private Gtk.Revealer main_revealer;
    public Gee.HashMap<string, Layouts.ProjectRow> projects_hashmap = new Gee.HashMap<string, Layouts.ProjectRow> ();

    public SidebarSourceRow (Objects.Source source) {
        Object (
            source: source
        );
    }

    construct {
        css_classes = { "no-selectable", "no-padding" };

        group = new Layouts.HeaderItem (source.display_name) {
            reveal = true,
            show_separator = true,
            subheader_title = source.subheader_text
        };
        group.placeholder_message = _("No project available. Create one by clicking on the '+' button");
        group.margin_top = 12;

        if (source.source_type == SourceType.TODOIST || source.source_type == SourceType.CALDAV) {
            var sync_button = new Widgets.SyncButton () {
                reveal_child = true
            };
            group.add_widget_end (sync_button);

            sync_button.clicked.connect (() => {
                if (source.source_type == SourceType.TODOIST) {
                    Services.Todoist.get_default ().sync.begin (source);
                } else if (source.source_type == SourceType.CALDAV) {
                    Services.CalDAV.Core.get_default ().sync.begin (source);
                }
            });

            source.sync_started.connect (() => {
                sync_button.sync_started ();
            });

            source.sync_finished.connect (() => {
                sync_button.sync_finished ();
            });

            source.sync_failed.connect ((custom_message) => {
                if (source.source_type == SourceType.TODOIST && source.needs_migration ()) {
                    sync_button.sync_failed ("<b>%s</b>\n%s".printf (
                        _("Account Migration Required"),
                        _("Todoist has updated their API. Please reconnect your account in Settings to continue syncing.")
                    ));
                } else {
                    sync_button.sync_failed ();
                }
            });
        }

        var add_button = new Gtk.Button.from_icon_name ("plus-large-symbolic") {
            valign = Gtk.Align.CENTER,
            css_classes = { "flat", "header-item-button" }
        };

        group.add_widget_end (add_button);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = group
        };

        child = main_revealer;
        build_last_drag_and_drop ();

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = source.is_visible;
            return GLib.Source.REMOVE;
        });

        add_all_projects ();
        update_projects_sort ();

        source.updated.connect (() => {
            group.header_title = source.display_name;
            main_revealer.reveal_child = source.is_visible;
        });

        add_button.clicked.connect (() => {
            prepare_new_project (source.id);
        });

        Services.Store.instance ().project_added.connect (add_row_project);
        Services.Store.instance ().project_updated.connect (update_projects_sort);
        Services.Store.instance ().project_unarchived.connect (add_row_project);

        Services.Store.instance ().project_deleted.connect ((project) => {
            if (projects_hashmap.has_key (project.id)) {
                projects_hashmap.unset (project.id);
            }
        });

        Services.Store.instance ().project_archived.connect ((project) => {
            if (projects_hashmap.has_key (project.id)) {
                projects_hashmap.unset (project.id);
            }
        });


        Services.EventBus.get_default ().project_parent_changed.connect ((project, old_parent_id) => {
            if (old_parent_id == "") {
                if (projects_hashmap.has_key (project.id)) {
                    projects_hashmap[project.id].hide_destroy ();
                    projects_hashmap.unset (project.id);
                }
            }

            if (project.parent_id == "") {
                add_row_project (project);
            }
        });

        Services.EventBus.get_default ().update_inserted_project_map.connect ((_row, old_parent_id) => {
            var row = (Layouts.ProjectRow) _row;

            if (old_parent_id == "") {
                if (projects_hashmap.has_key (row.project.id)) {
                    projects_hashmap.unset (row.project.id);
                }
            }

            if (!row.project.is_inbox_project && row.project.parent_id == "") {
                if (row.project.source_id == source.id) {
                    if (!projects_hashmap.has_key (row.project.id)) {
                        projects_hashmap[row.project.id] = row;
                    }
                }
            }
        });

        Services.Settings.get_default ().settings.changed["projects-sort-by"].connect (update_projects_sort);
        Services.Settings.get_default ().settings.changed["projects-ordered"].connect (update_projects_sort);

        Services.EventBus.get_default ().projects_drag_begin.connect ((source_id) => {
            if (source_id == source.id) {
                group.drop_target_end_revealer.reveal_child = true;
            }
        });

        Services.EventBus.get_default ().projects_drag_end.connect ((source_id) => {
            if (source_id == source.id) {
                group.drop_target_end_revealer.reveal_child = false;
            }
        });
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }

    private void prepare_new_project (string id) {
        var dialog = new Dialogs.Project.new (id);
        dialog.present (Planify._instance.main_window);
    }

    private void add_all_projects () {
        foreach (Objects.Project project in Services.Store.instance ().get_projects_by_source (source.id)) {
            add_row_project (project);
        }
    }

    private void add_row_project (Objects.Project project) {
        if (project.source_id == source.id && project.parent_id == "" && !project.is_archived) {
            if (!projects_hashmap.has_key (project.id)) {
                projects_hashmap[project.id] = new Layouts.ProjectRow (project);
                group.add_child (projects_hashmap[project.id]);
            }
        }
    }

    private void update_projects_sort () {
        if (Services.Settings.get_default ().settings.get_enum ("projects-sort-by") == 1) {
            group.set_sort_func (projects_sort_func);
        } else {
            group.set_sort_func (null);
        }
    }

    private int projects_sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
        Objects.Project project1 = ((Layouts.ProjectRow) lbrow).project;
        Objects.Project project2 = ((Layouts.ProjectRow) lbbefore).project;
        int ordered = Services.Settings.get_default ().settings.get_enum ("projects-ordered");
        return ordered == 0 ? project2.name.collate (project1.name) : project1.name.collate (project2.name);
    }

    private void build_last_drag_and_drop () {
        var drop_order_target = new Gtk.DropTarget (typeof (Layouts.ProjectRow), Gdk.DragAction.MOVE);
        group.drop_target_end.add_controller (drop_order_target);

        drop_order_target.drop.connect ((value, x, y) => {
            var picked_widget = (Layouts.ProjectRow) value;
            var picked_project = picked_widget.project;

            var projects_sort = Services.Settings.get_default ().settings.get_enum ("projects-sort-by");
            if (projects_sort != 0) {
                Services.Settings.get_default ().settings.set_enum ("projects-sort-by", 0);
                Services.EventBus.get_default ().send_toast (
                    Util.get_default ().create_toast (_("Projects sort changed to 'Custom sort order'"))
                );
            }

            var source_list = (Gtk.ListBox) picked_widget.parent;
            var target_list = (Gtk.ListBox) group.listbox;

            string old_parent_id = picked_project.parent_id;

            if (picked_project.parent_id != "") {
                picked_project.parent_id = "";
                if (picked_project.source_type == SourceType.TODOIST) {
                    Services.Todoist.get_default ().move_project_section.begin (picked_project, "", (obj, res) => {
                        if (Services.Todoist.get_default ().move_project_section.end (res).status) {
                            Services.Store.instance ().update_project (picked_project);
                            Services.EventBus.get_default ().update_inserted_project_map (picked_widget, old_parent_id);
                        }
                    });
                } else {
                    Services.Store.instance ().update_project (picked_project);
                    Services.EventBus.get_default ().update_inserted_project_map (picked_widget, old_parent_id);
                }
            }


            source_list.remove (picked_widget);

            var children_count = (int) Util.get_default ().get_children (target_list).length ();
            target_list.insert (picked_widget, children_count);
            update_projects_child_order (target_list);

            return true;
        });
    }

    private void update_projects_child_order (Gtk.ListBox listbox) {
        unowned Layouts.ProjectRow ? project_row = null;
        var row_index = 0;

        do {
            project_row = (Layouts.ProjectRow) listbox.get_row_at_index (row_index);

            if (project_row != null) {
                project_row.project.child_order = row_index;
                Services.Store.instance ().update_project (project_row.project);
            }

            row_index++;
        } while (project_row != null);
    }
}
