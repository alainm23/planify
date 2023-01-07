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
    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox inbox_listbox;
    private Gtk.ListBox listbox;

    public Gee.HashMap <string, Dialogs.ProjectPicker.ProjectPickerRow> projects_hashmap;

    Objects.Project _project;
    public Objects.Project project {
        get {
            return _project;
        }

        set {
            _project = value;
            Planner.event_bus.project_picker_changed (_project.id);
        }
    }

    public signal void changed (int64 project_id);

    public ProjectPicker () {
        Object (
            deletable: true,
            resizable: true,
            modal: true,
            title: _("Move"),
            width_request: 320,
            height_request: 450,
            transient_for: (Gtk.Window) Planner.instance.main_window
        );
    }

    construct {
        projects_hashmap = new Gee.HashMap <string, Dialogs.ProjectPicker.ProjectPickerRow> ();

        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);

        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Type a project"),
            hexpand = true,
            margin_start = 12,
            margin_end = 12
        };

        search_entry.add_css_class ("border-radius-9");

        inbox_listbox = new Gtk.ListBox () {
            hexpand = true,
            margin_top = 6,
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 6
        };

        inbox_listbox.add_css_class ("listbox-background");
        inbox_listbox.add_css_class ("listbox-separator-3");

        var inbox_listbox_grid = new Gtk.Grid () {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12
        };
        
        inbox_listbox_grid.attach (inbox_listbox, 0, 0);
        inbox_listbox_grid.add_css_class (Granite.STYLE_CLASS_CARD);

        listbox = new Gtk.ListBox () {
            hexpand = true,
            margin_top = 6,
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 6
        };
        
        listbox.set_filter_func (filter_func);
        listbox.add_css_class ("listbox-background");
        listbox.add_css_class ("listbox-separator-3");

        var listbox_scrolled = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };

        listbox_scrolled.child = listbox;

        var listbox_grid = new Gtk.Grid () {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12
        };

        listbox_grid.attach (listbox_scrolled, 0, 0);
        listbox_grid.add_css_class (Granite.STYLE_CLASS_CARD);

        var submit_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Move")) {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };
        submit_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
        submit_button.add_css_class ("no-padding");
        submit_button.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        
        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.append (headerbar);
        content_box.append (search_entry);
        content_box.append (inbox_listbox_grid);
        content_box.append (listbox_grid);
        content_box.append (submit_button);

        content = content_box;
        add_projects ();

        search_entry.search_changed.connect (() => {
            listbox.invalidate_filter ();
        });

        Planner.event_bus.project_picker_changed.connect ((project_id) => {
            _project = Services.Database.get_default ().get_project (project_id);
        });

        submit_button.clicked.connect (() => {
            changed (project.id);
            hide_destroy ();
        });
    }

    private void add_projects () {
        foreach (Objects.Project project in Services.Database.get_default ().projects) {
            projects_hashmap [project.id_string] = new Dialogs.ProjectPicker.ProjectPickerRow (project);
            
            if (project.inbox_project) {
                inbox_listbox.append (projects_hashmap [project.id_string]);
            } else {
                listbox.append (projects_hashmap [project.id_string]);
            }
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