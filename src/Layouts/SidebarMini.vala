/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
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
 * Authored by: Goregg
 */

/*
 * Compact sidebar: filters and top-level projects as icons with their
 * task counts. The names are shown as tooltips.
 */
public class Layouts.SidebarMini : Adw.Bin {
    public Gtk.ListBox filters { get; construct; }

    private Gtk.Box sources_box;
    private Gee.HashMap<string, Gtk.Box> sources_hashmap = new Gee.HashMap<string, Gtk.Box> ();
    private Gee.HashMap<string, Gtk.ListBox> listbox_hashmap = new Gee.HashMap<string, Gtk.ListBox> ();
    private Gee.HashMap<string, Layouts.ProjectRow> projects_hashmap = new Gee.HashMap<string, Layouts.ProjectRow> ();

    public SidebarMini (Gtk.ListBox filters) {
        Object (
            filters: filters
        );
    }

    ~SidebarMini () {
        debug ("Destroying Layouts.SidebarMini\n");
    }

    construct {
        sources_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 3,
            margin_end = 3,
            margin_bottom = 12,
            margin_top = 6,
            valign = START
        };

        content_box.append (filters);
        content_box.append (sources_box);

        child = new Widgets.ScrolledWindow (content_box);

        foreach (Objects.Source source in Services.Store.instance ().sources) {
            add_source (source);
        }

        update_projects_sort ();

        Services.Store.instance ().source_added.connect (add_source);
        Services.Store.instance ().source_deleted.connect (remove_source);

        Services.Store.instance ().project_added.connect (add_project);
        Services.Store.instance ().project_unarchived.connect (add_project);
        Services.Store.instance ().project_updated.connect (update_projects_sort);
        Services.Store.instance ().project_deleted.connect (forget_project);
        Services.Store.instance ().project_archived.connect (forget_project);

        // Moved into another project, or dragged back to the top level
        Services.EventBus.get_default ().project_parent_changed.connect (update_project_parent);
        Services.EventBus.get_default ().update_inserted_project_map.connect ((row) => {
            update_project_parent (((Layouts.ProjectRow) row).project);
        });

        Services.Settings.get_default ().settings.changed["projects-sort-by"].connect (update_projects_sort);
        Services.Settings.get_default ().settings.changed["projects-ordered"].connect (update_projects_sort);
    }

    private void add_source (Objects.Source source) {
        if (sources_hashmap.has_key (source.id)) {
            return;
        }

        // Same x position as the header's search button
        var add_button = new Gtk.Button.from_icon_name ("plus-large-symbolic") {
            halign = Gtk.Align.START,
            margin_start = 8,
            css_classes = { "flat", "header-item-button" },
            tooltip_text = "%s · %s".printf (source.display_name, _("New Project"))
        };

        var listbox = new Gtk.ListBox () {
            hexpand = true,
            css_classes = { "bg-transparent" }
        };

        var source_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3) {
            margin_top = 12,
            visible = source.is_visible
        };

        source_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        source_box.append (add_button);
        source_box.append (listbox);

        sources_hashmap[source.id] = source_box;
        listbox_hashmap[source.id] = listbox;
        sources_box.append (source_box);

        add_button.clicked.connect (() => {
            var dialog = new Dialogs.Project.new (source.id);
            dialog.present (Planify._instance.main_window);
        });

        source.updated.connect (() => {
            source_box.visible = source.is_visible;
            add_button.tooltip_text = "%s · %s".printf (source.display_name, _("New Project"));
        });

        foreach (Objects.Project project in Services.Store.instance ().get_projects_by_source (source.id)) {
            add_project (project);
        }

        update_projects_sort ();
    }

    // Like the full sidebar: only the source is removed, its project rows
    // remove themselves when the store deletes the projects.
    private void remove_source (Objects.Source source) {
        if (sources_hashmap.has_key (source.id)) {
            sources_box.remove (sources_hashmap[source.id]);
            sources_hashmap.unset (source.id);
            listbox_hashmap.unset (source.id);
        }
    }

    private void add_project (Objects.Project project) {
        if (project.parent_id != "" || project.is_archived || project.is_inbox_project) {
            return;
        }

        if (projects_hashmap.has_key (project.id) || !listbox_hashmap.has_key (project.source_id)) {
            return;
        }

        projects_hashmap[project.id] = new Layouts.ProjectRow (project, false, false, true);
        listbox_hashmap[project.source_id].append (projects_hashmap[project.id]);
    }

    private void update_project_parent (Objects.Project project) {
        if (project.parent_id == "") {
            add_project (project);
        } else {
            remove_project (project);
        }
    }

    private void remove_project (Objects.Project project) {
        if (projects_hashmap.has_key (project.id)) {
            projects_hashmap[project.id].hide_destroy ();
            projects_hashmap.unset (project.id);
        }
    }

    // A deleted or archived project row removes itself, only forget it here.
    private void forget_project (Objects.Project project) {
        projects_hashmap.unset (project.id);
    }

    // Same order as the full sidebar: by name, or by the order set with drag and drop
    private void update_projects_sort () {
        foreach (Gtk.ListBox listbox in listbox_hashmap.values) {
            if (Services.Settings.get_default ().settings.get_enum ("projects-sort-by") == 1) {
                listbox.set_sort_func (projects_name_sort_func);
            } else {
                listbox.set_sort_func (projects_order_sort_func);
            }
        }
    }

    private int projects_name_sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
        Objects.Project project1 = ((Layouts.ProjectRow) lbrow).project;
        Objects.Project project2 = ((Layouts.ProjectRow) lbbefore).project;
        int ordered = Services.Settings.get_default ().settings.get_enum ("projects-ordered");
        return ordered == 0 ? project2.name.collate (project1.name) : project1.name.collate (project2.name);
    }

    private int projects_order_sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
        return ((Layouts.ProjectRow) lbrow).project.child_order - ((Layouts.ProjectRow) lbbefore).project.child_order;
    }
}
