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

            source.sync_failed.connect (() => {
                sync_button.sync_failed ();
            });
        }

        var add_button = new Gtk.Button.from_icon_name ("plus-large-symbolic") {
            valign = Gtk.Align.CENTER,
            css_classes = { "flat", "header-item-button", "dimmed" }
        };

        group.add_widget_end (add_button);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = group
        };

        child = main_revealer;

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
        if (project.source_id == source.id && !project.is_inbox_project && project.parent_id == "" && !project.is_archived) {
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
}
