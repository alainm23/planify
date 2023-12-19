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

public class Dialogs.Label : Adw.Window {
    public Objects.Label label { get; construct; }

    private Adw.EntryRow name_entry;
    private Widgets.ColorPickerRow color_picker_row;
    private Widgets.LoadingButton submit_button;

    public bool is_creating {
        get {
            return label.id == "";
        }
    }

    public Label.new (BackendType backend_type = BackendType.LOCAL) {
        var label = new Objects.Label ();
        label.color = "blue";
        label.id = "";
        label.backend_type = backend_type;

        Object (
            label: label,
            deletable: true,
            resizable: true,
            modal: true,
            title: _("New Label"),
            width_request: 320,
            height_request: 400,
            transient_for: (Gtk.Window) Planify.instance.main_window
        );
    }

    public Label (Objects.Label label) {
        Object (
            label: label,
            deletable: true,
            resizable: true,
            modal: true,
            title: _("Edit Label"),
            width_request: 320,
            height_request: 400,
            transient_for: (Gtk.Window) Planify.instance.main_window
        );
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);

        name_entry = new Adw.EntryRow ();
        name_entry.title = _("Give your label a name");
        name_entry.text = label.name;

        var name_group = new Adw.PreferencesGroup () {
            margin_end = 12,
            margin_start = 12,
            margin_top = 12
        };

        name_group.add (name_entry);

        color_picker_row = new Widgets.ColorPickerRow ();

        var color_group = new Gtk.Grid () {
            margin_end = 12,
            margin_start = 12,
            margin_top = 24,
            margin_bottom = 1,
            valign = Gtk.Align.START
        };

        color_group.add_css_class (Granite.STYLE_CLASS_CARD);
        color_group.attach (color_picker_row, 0, 0);
        
        submit_button = new Widgets.LoadingButton.with_label (is_creating ? _("Add label") : _("Update label")) {
            vexpand = true,
            hexpand = true,
            margin_bottom = 12,
            margin_end = 12,
            margin_start = 12,
            margin_top = 12,
            valign = Gtk.Align.END
        };

        submit_button.sensitive = !is_creating;
        submit_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        
        content_box.append (headerbar);
        content_box.append (name_group);
        content_box.append (color_group);
        content_box.append (submit_button);

        content = content_box;

        Timeout.add (225, () => {
            name_entry.grab_focus ();
            color_picker_row.color = label.color;
            return GLib.Source.REMOVE;
        });

        name_entry.entry_activated.connect (add_update_project);
        submit_button.clicked.connect (add_update_project);

        var name_entry_ctrl_key = new Gtk.EventControllerKey ();
        name_entry.add_controller (name_entry_ctrl_key);

        name_entry_ctrl_key.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == 65307) {
                hide_destroy ();
            }

            return false;
        });

        name_entry.changed.connect (() => {
            if (is_creating) {
                submit_button.sensitive = !is_duplicate (name_entry.text);
            }
        });
    }

    private bool is_duplicate (string text) {
        Objects.Label label = Services.Database.get_default ().get_label_by_name (text, true);
        return label != null;
    }

    private void add_update_project () {
        if (name_entry.text.length <= 0) {
            hide_destroy ();
            return;
        }

        if (is_creating && is_duplicate (name_entry.text)) {
            hide_destroy ();
            return; 
        }

        label.name = name_entry.text;
        label.color = color_picker_row.color;

        if (!is_creating) {
            submit_button.is_loading = true;
            if (label.backend_type == BackendType.TODOIST) { 
                Services.Todoist.get_default ().update.begin (label, (obj, res) => {
                    Services.Todoist.get_default ().update.end (res);
                    Services.Database.get_default ().update_label (label);
                    submit_button.is_loading = false;
                    hide_destroy ();
                });
            } else if (label.backend_type == BackendType.LOCAL) {
                Services.Database.get_default ().update_label (label);
                hide_destroy ();
            }
        } else {
            label.item_order = Services.Database.get_default ().get_labels_by_backend_type (label.backend_type).size;
            if (label.backend_type == BackendType.TODOIST) {
                submit_button.is_loading = true;
                Services.Todoist.get_default ().add.begin (label, (obj, res) => {
                    TodoistResponse response = Services.Todoist.get_default ().add.end (res);

                    if (response.status) {
                        label.id = response.data;
                        Services.Database.get_default ().insert_label (label);
                        hide_destroy ();
                    } else {

                    }
                });

            } else if (label.backend_type == BackendType.LOCAL) {
                label.id = Util.get_default ().generate_id (label);
                Services.Database.get_default ().insert_label (label);
                hide_destroy ();
            }
        }
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}
