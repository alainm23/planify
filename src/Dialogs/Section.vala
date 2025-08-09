/*
 * Copyright © 2024 Alain M. (https://github.com/alainm23/planify)
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

public class Dialogs.Section : Adw.Dialog {
    public Objects.Section section { get; construct; }

    private Adw.EntryRow name_entry;
    private Widgets.ColorPickerRow color_picker_row;
    private Widgets.LoadingButton submit_button;
    private Adw.EntryRow description_entry;

    public bool is_creating {
        get {
            return section.id == "";
        }
    }

    public Section.new (Objects.Project project) {
        var section = new Objects.Section ();
        section.project_id = project.id;
        section.color = "blue";
        section.id = "";

        Object (
            section: section,
            title: _("New Section")
        );
    }

    public Section (Objects.Section section) {
        Object (
            section: section,
            title: _("Edit Section")
        );
    }

    ~Section () {
        print ("Destroying Dialogs.Section\n");
    }

    construct {
        var headerbar = new Adw.HeaderBar () {
            css_classes = { "flat" }
        };

        name_entry = new Adw.EntryRow ();
        name_entry.title = _("Section Name");
        name_entry.text = section.name;

        var name_group = new Adw.PreferencesGroup () {
            margin_end = 12,
            margin_start = 12,
            margin_top = 24
        };

        name_group.add (name_entry);

        color_picker_row = new Widgets.ColorPickerRow ();

        var color_group = new Adw.Bin () {
            margin_end = 12,
            margin_start = 12,
            margin_top = 24,
            margin_bottom = 1,
            valign = Gtk.Align.START,
            css_classes = { "card" },
            child = color_picker_row
        };

        description_entry = new Adw.EntryRow ();
        description_entry.title = _("Description");
        description_entry.text = section.description;

        var description_group = new Adw.PreferencesGroup () {
            margin_end = 12,
            margin_start = 12,
            margin_top = 24
        };

        description_group.add (description_entry);

        submit_button = new Widgets.LoadingButton.with_label (is_creating ? _("Add Section") : _("Update Section")) {
            vexpand = true,
            hexpand = true,
            margin_bottom = 12,
            margin_end = 12,
            margin_start = 12,
            margin_top = 24,
            valign = Gtk.Align.END
        };

        submit_button.add_css_class ("suggested-action");

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.append (name_group);
        content_box.append (color_group);
        content_box.append (description_group);
        content_box.append (submit_button);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 600,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };

        content_clamp.child = content_box;

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (headerbar);
        toolbar_view.content = content_clamp;

        child = toolbar_view;
        Services.EventBus.get_default ().disconnect_typing_accel ();

        Timeout.add (225, () => {
            color_picker_row.color = section.color;

            if (is_creating) {
                name_entry.grab_focus ();
            }

            return GLib.Source.REMOVE;
        });

        name_entry.entry_activated.connect (add_update_section);
        submit_button.clicked.connect (add_update_section);

        closed.connect (() => {
            Services.EventBus.get_default ().connect_typing_accel ();
        });
    }

    private void add_update_section () {
        if (name_entry.text.length <= 0) {
            hide_destroy ();
            return;
        }

        string _name = section.name;
        string _description = section.description;
        string _color = section.color;

        section.name = name_entry.text;
        section.description = description_entry.text;
        section.color = color_picker_row.color;

        if (!is_creating) {
            update_section (_name, _description, _color);
        } else {
            add_section ();
        }
    }

    private void update_section (string _name, string _description, string _color) {
        if (section.project.source_type == SourceType.LOCAL) {
            Services.Store.instance ().update_section (section);
            hide_destroy ();
            return;
        }


        if (section.project.source_type == SourceType.TODOIST) {
            submit_button.is_loading = true;
            Services.Todoist.get_default ().update.begin (section, (obj, res) => {
                submit_button.is_loading = false;
                HttpResponse response = Services.Todoist.get_default ().update.end (res);

                if (response.status) {
                    Services.Store.instance ().update_section (section);
                    hide_destroy ();
                } else {
                    section.name = _name;
                    section.description = _description;
                    section.color = _color;

                    Services.EventBus.get_default ().send_error_toast (response.error_code, response.error);
                    close ();
                }
            });
        }
    }

    private void add_section () {
        if (section.project.source_type == SourceType.LOCAL) {
            section.id = Util.get_default ().generate_id (section);
            section.project.add_section_if_not_exists (section);
            send_toast (_("Section added"));
            hide_destroy ();
            return;
        }

        if (section.project.source_type == SourceType.TODOIST) {
            submit_button.is_loading = true;
            Services.Todoist.get_default ().add.begin (section, (obj, res) => {
                submit_button.is_loading = false;
                HttpResponse response = Services.Todoist.get_default ().add.end (res);

                if (response.status) {
                    section.id = response.data;
                    section.project.add_section_if_not_exists (section);
                    send_toast (_("Section added"));
                    hide_destroy ();
                } else {
                    Services.EventBus.get_default ().send_error_toast (response.error_code, response.error);
                    close ();
                }
            });
        }
    }

    private void send_toast (string message) {
        var toast = new Adw.Toast (message);
        Services.EventBus.get_default ().send_toast (toast);
    }

    public void hide_destroy () {
        close ();
    }
}
