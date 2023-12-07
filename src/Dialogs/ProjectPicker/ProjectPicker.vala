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

public class Dialogs.ProjectPicker.ProjectPicker : Adw.Window {
    public BackendType backend_type { get; construct; }
    public PickerType picker_type { get; construct; }

    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox sections_listbox;

    private Layouts.HeaderItem inbox_group;
    private Layouts.HeaderItem local_group;
    private Layouts.HeaderItem todoist_group;

    public Gee.HashMap <string, Dialogs.ProjectPicker.ProjectPickerRow> projects_hashmap;

    Objects.Project _project;
    public Objects.Project project {
        get {
            return _project;
        }

        set {
            _project = value;
            Services.EventBus.get_default ().project_picker_changed (_project.id);
        }
    }

    Objects.Section _section;
    public Objects.Section section {
        get {
            return _section;
        }

        set {
            _section = value;
            string _id = "";
            if (section != null) {
                _id = _section.id;
            }

            Services.EventBus.get_default ().section_picker_changed (_id);
        }
    }

    public signal void changed (string type, string id);

    public ProjectPicker (PickerType picker_type = PickerType.PROJECTS, BackendType backend_type = BackendType.ALL) {
        Object (
            picker_type: picker_type,
            backend_type: backend_type,
            deletable: true,
            resizable: true,
            modal: true,
            title: _("Move"),
            width_request: 400,
            height_request: 600,
            transient_for: (Gtk.Window) Planify.instance.main_window
        );
    }

    construct {
        projects_hashmap = new Gee.HashMap <string, Dialogs.ProjectPicker.ProjectPickerRow> ();

        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);

        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Type a search"),
            hexpand = true,
            margin_start = 16,
            margin_end = 16
        };

        search_entry.add_css_class ("border-radius-9");

        var main_stack = new Gtk.Stack () {
            hexpand = true,
            vexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        main_stack.add_named (build_projects_view (), "projects");
        main_stack.add_named (build_sections_view (), "sections");
        main_stack.visible_child_name = picker_type.to_string ();

        var submit_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Move")) {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };
        submit_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.append (headerbar);
        content_box.append (search_entry);
        content_box.append (main_stack);
        content_box.append (submit_button);

        content = content_box;
        add_projects ();

        Timeout.add (Constants.DRAG_TIMEOUT, () => {
            // main_stack.visible_child_name = picker_type.to_string ();
            return GLib.Source.REMOVE;
        });

        search_entry.search_changed.connect (() => {
            local_group.invalidate_filter ();
            todoist_group.invalidate_filter ();
        });

        Services.EventBus.get_default ().project_picker_changed.connect ((id) => {
            _project = Services.Database.get_default ().get_project (id);
        });

        Services.EventBus.get_default ().section_picker_changed.connect ((id) => {
            _section = Services.Database.get_default ().get_section (id);
        });

        submit_button.clicked.connect (() => {
            if (main_stack.visible_child_name == "projects") {
                changed ("project", project.id);
            } else {
                string id = "";
                if (section != null) {
                    id = section.id;
                }

                changed ("section", id);
            }

            hide_destroy ();
        });
    }

    private Gtk.Widget build_projects_view () {
        inbox_group = new Layouts.HeaderItem (null);
        inbox_group.show_action = false;

        local_group = new Layouts.HeaderItem (_("On this Computer"));
        local_group.show_action = false;

        todoist_group = new Layouts.HeaderItem (_("Todoist"));
        todoist_group.show_action = false;

        if (backend_type == BackendType.ALL) {
            inbox_group.reveal = true;
            local_group.reveal = true;
            todoist_group.reveal = true;
        } else if (backend_type == BackendType.LOCAL) {
            local_group.reveal = true;
        } else if (backend_type == BackendType.TODOIST) {
            todoist_group.reveal = true;
        }

        local_group.set_filter_func (filter_func);
        todoist_group.set_filter_func (filter_func);
        
        var scrolled_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 12,
            margin_end = 12
        };
        scrolled_box.append (inbox_group);
        scrolled_box.append (local_group);
        scrolled_box.append (todoist_group);

        var scrolled = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };

        scrolled.child = scrolled_box;

        return scrolled;
    }

    private Gtk.Widget build_sections_view () {
        sections_listbox = new Gtk.ListBox () {
            hexpand = true,
            margin_top = 6,
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 6
        };

        sections_listbox.add_css_class ("listbox-background");
        sections_listbox.add_css_class ("listbox-separator-3");

        var sections_listbox_grid = new Gtk.Grid () {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12
        };
        
        sections_listbox_grid.attach (sections_listbox, 0, 0);
        sections_listbox_grid.add_css_class (Granite.STYLE_CLASS_CARD);

        var scrolled = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };

        scrolled.child = sections_listbox_grid;

        return scrolled;
    }

    private void add_projects () {
        foreach (Objects.Project project in Services.Database.get_default ().projects) {
            projects_hashmap [project.id_string] = new Dialogs.ProjectPicker.ProjectPickerRow (project);
            
            if (project.is_inbox_project) {
                inbox_group.add_child (projects_hashmap [project.id_string]);
            } else {
                if (project.backend_type == BackendType.LOCAL) {
                    local_group.add_child (projects_hashmap [project.id_string]);
                } else if (project.backend_type == BackendType.TODOIST) {
                    todoist_group.add_child (projects_hashmap [project.id_string]);
                }
            }
        }
    }

    public void add_sections (Gee.ArrayList<Objects.Section> sections) {
        var no_section = new Objects.Section ();
        no_section.name = _("No Section");
        no_section.id = "";

        sections_listbox.append (new Dialogs.ProjectPicker.SectionPickerRow (no_section));

        foreach (Objects.Section section in sections) {
            sections_listbox.append (new Dialogs.ProjectPicker.SectionPickerRow (section));
        }
    }

    private bool filter_func (Gtk.ListBoxRow row) {
        var project = ((Dialogs.ProjectPicker.ProjectPickerRow) row).project;
        return search_entry.text.down () in project.name.down ();
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}