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

public class Dialogs.Label : Adw.Window {
    public Objects.Label label { get; construct; }

    private Widgets.EntryRow name_entry;
    private Widgets.ColorPickerRow color_picker_row;
    private Widgets.LoadingButton submit_button;

    public bool is_creating {
        get {
            return label.id == Constants.INACTIVE;
        }
    }

    public Label.new (bool todoist = false) {
        var label = new Objects.Label ();
        label.color = "blue";
        label.id = Constants.INACTIVE;
        label.todoist = todoist;

        Object (
            label: label,
            deletable: true,
            resizable: true,
            modal: true,
            title: _("New Label"),
            width_request: 320,
            height_request: 400,
            transient_for: (Gtk.Window) Planner.instance.main_window
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
            transient_for: (Gtk.Window) Planner.instance.main_window
        );
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);

        name_entry = new Widgets.EntryRow ("none");
        name_entry.entry.placeholder_text = _("Give your label a name");
        name_entry.entry.text = label.name;

        var name_emoji_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
            margin_top = 24,
            margin_end = 12,
            margin_start = 12
        };

        name_emoji_box.add_css_class ("card");
        name_emoji_box.add_css_class ("padding-6");

        name_emoji_box.append (name_entry);

        color_picker_row = new Widgets.ColorPickerRow ("none");

        var color_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
            margin_top = 24,
            margin_end = 12,
            margin_start = 12,
            margin_bottom = 3
        };

        color_box.add_css_class ("card");
        color_box.add_css_class ("padding-6");

        color_box.append (color_picker_row);

        submit_button = new Widgets.LoadingButton.with_label (is_creating ? _("Add project") : _("Update project")) {
            vexpand = true,
            hexpand = true,
            margin_bottom = 12,
            margin_end = 12,
            margin_start = 12,
            margin_top = 12,
            valign = Gtk.Align.END
        };

        submit_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        
        content_box.append (headerbar);
        content_box.append (name_emoji_box);
        content_box.append (color_box);
        content_box.append (submit_button);

        content = content_box;

        Timeout.add (225, () => {
            name_entry.grab_focus ();
            color_picker_row.color = label.color;
            return GLib.Source.REMOVE;
        });

        name_entry.entry.activate.connect (add_update_project);
        submit_button.clicked.connect (add_update_project);

        var name_entry_ctrl_key = new Gtk.EventControllerKey ();
        name_entry.entry.add_controller (name_entry_ctrl_key);

        name_entry_ctrl_key.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == 65307) {
                hide_destroy ();
            }

            return false;
        });
    }

    private void add_update_project () {
        if (!Util.get_default ().is_input_valid (name_entry.entry)) {
            hide_destroy ();
            return;
        }

        label.name = name_entry.entry.text;
        label.color = color_picker_row.color;

        if (!is_creating) {
            submit_button.is_loading = true;
            if (label.todoist) {
                Services.Todoist.get_default ().update.begin (label, (obj, res) => {
                    Services.Todoist.get_default ().update.end (res);
                    Services.Database.get_default().update_label (label);
                    submit_button.is_loading = false;
                    hide_destroy ();
                });
            } else {
                Services.Database.get_default().update_label (label);
                hide_destroy ();
            }
        } else {
            if (label.todoist) {
                submit_button.is_loading = true;
                Services.Todoist.get_default ().add.begin (label, (obj, res) => {
                    label.id = Services.Todoist.get_default ().add.end (res);
                    Services.Database.get_default().insert_label (label);
                    hide_destroy ();
                });

            } else {
                label.id = Util.get_default ().generate_id ();
                Services.Database.get_default().insert_label (label);
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
