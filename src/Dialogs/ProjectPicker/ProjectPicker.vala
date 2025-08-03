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

public class Dialogs.ProjectPicker.ProjectPicker : Adw.Dialog {
    public PickerType picker_type { get; construct; }
    public Objects.Source ? source { get; construct; }
    public bool all_sources { get; construct; }

    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox sections_listbox;

    private Layouts.HeaderItem inbox_group;

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

    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();

    public ProjectPicker.for_project (Objects.Source source) {
        Object (
            picker_type : PickerType.PROJECTS,
            source: source,
            all_sources: false,
            title: _("Move"),
            content_width: 400,
            content_height: 550
        );
    }

    public ProjectPicker.for_projects () {
        Object (
            picker_type: PickerType.PROJECTS,
            source: null,
            all_sources: true,
            title: _("Move"),
            content_width: 400,
            content_height: 550
        );
    }

    public ProjectPicker.for_sections (Objects.Source source) {
        Object (
            picker_type: PickerType.SECTIONS,
            source: source,
            all_sources: false,
            title: _("Move"),
            content_width: 400,
            content_height: 550
        );
    }

    ~ProjectPicker () {
        print ("Destroying Dialogs.ProjectPicker.ProjectPicker\n");
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class ("flat");

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
            margin_bottom = 12,
            css_classes = { "suggested-action" }
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.append (headerbar);
        // content_box.append (search_entry);
        content_box.append (main_stack);
        content_box.append (submit_button);

        child = content_box;
        Services.EventBus.get_default ().disconnect_typing_accel ();

        // search_entry.search_changed.connect (() => {
        // local_group.invalidate_filter ();
        // todoist_group.invalidate_filter ();
        // caldav_group.invalidate_filter ();
        // });

        signal_map[Services.EventBus.get_default ().project_picker_changed.connect ((id) => {
            _project = Services.Store.instance ().get_project (id);
        })] = Services.EventBus.get_default ();

        signal_map[Services.EventBus.get_default ().section_picker_changed.connect ((id) => {
            _section = Services.Store.instance ().get_section (id);
        })] = Services.EventBus.get_default ();

        signal_map[submit_button.clicked.connect (() => {
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
        })] = submit_button;

        var destroy_controller = new Gtk.EventControllerKey ();
        add_controller ((Gtk.ShortcutController) destroy_controller);
        signal_map[destroy_controller.key_released.connect ((keyval, keycode, state) => {
            if (keyval == 65307) {
                hide_destroy ();
            }
        })] = destroy_controller;

        closed.connect (() => {
            foreach (var entry in signal_map.entries) {
                entry.value.disconnect (entry.key);
            }

            signal_map.clear ();

            Services.EventBus.get_default ().connect_typing_accel ();
        });
    }

    private Gtk.Widget build_projects_view () {
        inbox_group = new Layouts.HeaderItem (null) {
            margin_top = 12,
            card = true,
            reveal = true
        };

        inbox_group.add_child (
            new Dialogs.ProjectPicker.ProjectPickerRow (Services.Store.instance ().get_inbox_project ())
        );

        var scrolled_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_start = 12,
            margin_end = 12
        };
        scrolled_box.append (inbox_group);

        if (all_sources) {
            foreach (Objects.Source source in Services.Store.instance ().sources) {
                scrolled_box.append (new Dialogs.ProjectPicker.ProjectPickerSourceRow (source));
            }
        } else {
            scrolled_box.append (new Dialogs.ProjectPicker.ProjectPickerSourceRow (source));
        }

        var scrolled = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = scrolled_box
        };

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
        sections_listbox_grid.add_css_class ("card");

        var scrolled = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };

        scrolled.child = sections_listbox_grid;

        return scrolled;
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

    public void hide_destroy () {
        close ();
    }
}
