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

public class Dialogs.ProjectPicker.ProjectPicker : Hdy.Window {
    private Gtk.ListBox listbox;

    public Gee.HashMap <string, Dialogs.ProjectPicker.ProjectRow> projects_hashmap;

    Objects.Project _project;
    public Objects.Project project {
        get {
            return _project;
        }

        set {
            _project = value;
            Planner.event_bus.project_picker_changed (_project.id, Constants.INACTIVE);
        }
    }

    Objects.Section _section;
    public Objects.Section section {
        get {
            return _section;
        }

        set {
            _section = value;
            Planner.event_bus.project_picker_changed (_section.project_id, _section.id);
        }
    }

    public signal void changed (int64 project_id, int64 section_id);

    public ProjectPicker () {
        Object (
            transient_for: (Gtk.Window) Planner.instance.main_window.get_toplevel (),
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.MOUSE,
            resizable: false
        );
    }

    construct {
        projects_hashmap = new Gee.HashMap <string, Dialogs.ProjectPicker.ProjectRow> ();

        var headerbar = new Hdy.HeaderBar () {
            has_subtitle = false,
            show_close_button = false,
            hexpand = true
        };
        headerbar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        headerbar.get_style_context ().add_class ("default-decoration");

        var done_button = new Gtk.Button.with_label (_("Done")) {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            can_focus = false
        };
        done_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        done_button.get_style_context ().add_class ("primary-color");

        var cancel_button = new Gtk.Button.with_label (_("Cancel")) {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            can_focus = false
        };
        cancel_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var title_label = new Gtk.Label (_("Projects"));
        title_label.get_style_context ().add_class ("h4");

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true
        };
        header_box.pack_start (cancel_button, false, false, 0);
        header_box.set_center_widget (title_label);
        header_box.pack_end (done_button, false, false, 0);

        var search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Type a project"),
            hexpand = true,
            margin_start = 12,
            margin_end = 12,
            margin_top = 3,
            margin_bottom = 6
        };

        unowned Gtk.StyleContext search_entry_context = search_entry.get_style_context ();
        search_entry_context.add_class ("border-radius-6");

        headerbar.set_custom_title (header_box);

        listbox = new Gtk.ListBox () {
            hexpand = true
        };
        
        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("listbox-separator-3");
        listbox_context.add_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin = 6,
            margin_top = 0
        };

        listbox_grid.add (listbox);
        
        var listbox_scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true,
            height_request = 210
        };
        listbox_scrolled.add (listbox_grid);

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            width_request = 225
        };
        main_grid.add (headerbar);
        main_grid.add (search_entry);
        main_grid.add (listbox_scrolled);

        unowned Gtk.StyleContext main_grid_context = main_grid.get_style_context ();
        main_grid_context.add_class ("view");

        add (main_grid);
        add_projects ();

        focus_out_event.connect (() => {
            hide_destroy ();
            return false;
        });

         key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_destroy ();
            }

            return false;
        });

        cancel_button.clicked.connect (() => {
            hide_destroy ();
        });

        done_button.clicked.connect (() => {
            changed (project.id, section.id);
            hide_destroy ();
        });

        Planner.event_bus.project_picker_changed.connect ((project_id, section_id) => {
            _project = Planner.database.get_project (project_id);
            _section = Planner.database.get_section (section_id);
        });
    }

    private void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }

    private void add_projects () {
        foreach (Objects.Project project in Planner.database.projects) {
            projects_hashmap [project.id_string] = new Dialogs.ProjectPicker.ProjectRow (project);
            listbox.add (projects_hashmap [project.id_string]);
        }

        foreach (Objects.Section section in Planner.database.sections) {
            if (projects_hashmap.has_key (section.project_id.to_string ())) {
                projects_hashmap [section.project_id.to_string ()].add_section (section);
            }
        }

        listbox.show_all ();
    }

    public void popup () {
        show_all ();
    }
    