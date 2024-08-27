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

public class Dialogs.Label : Adw.Dialog {
    public Objects.Label label { get; construct; }

    private Adw.EntryRow name_entry;
    private Widgets.ColorPickerRow color_picker_row;
    private Widgets.LoadingButton submit_button;

    public bool is_creating {
        get {
            return label.id == "";
        }
    }

    public Label.new (Objects.Source source) {
        var label = new Objects.Label ();
        label.color = "blue";
        label.id = "";
        label.source_id = source.id;

        Object (
            label: label,
            title: _("New Label")
        );
    }

    public Label (Objects.Label label) {
        Object (
            label: label,
            title: _("Edit Label")
        );
    }

    ~Label() {
        print ("Destroying Dialogs.Label\n");
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class ("flat");

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

        color_group.add_css_class ("card");
        color_group.attach (color_picker_row, 0, 0);
        
        submit_button = new Widgets.LoadingButton.with_label (is_creating ? _("Add Label") : _("Update Label")) {
            vexpand = true,
            hexpand = true,
            margin_bottom = 12,
            margin_end = 12,
            margin_start = 12,
            margin_top = 12,
            valign = Gtk.Align.END
        };

        submit_button.sensitive = !is_creating;
        submit_button.add_css_class ("suggested-action");

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        
        content_box.append (name_group);
        content_box.append (color_group);
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
            name_entry.grab_focus ();
            color_picker_row.color = label.color;
            return GLib.Source.REMOVE;
        });

        name_entry.entry_activated.connect (add_update_label);
        submit_button.clicked.connect (add_update_label);

        name_entry.changed.connect (() => {
            if (is_creating) {
                submit_button.sensitive = !is_duplicate (name_entry.text);
            }
        });

        closed.connect (() => {
            Services.EventBus.get_default ().connect_typing_accel ();
        });
    }

    private bool is_duplicate (string text) {
        Objects.Label label = Services.Store.instance ().get_label_by_name (text, true, label.source_id);
        return label != null;
    }

    private void add_update_label () {
        if (name_entry.text.length <= 0) {
            close ();
            return;
        }

        if (is_creating && is_duplicate (name_entry.text)) {
            close ();
            return; 
        }

        string _name = label.name;
        string _color = label.color;

        label.name = name_entry.text;
        label.color = color_picker_row.color;

        if (!is_creating) {
            update_label (_name, _color);
        } else {
            add_label ();
        }
    }

    private void update_label (string _name, string _color) {
        if (label.source_type == SourceType.LOCAL || label.source_type == SourceType.CALDAV) {
            Services.Store.instance ().update_label (label);
            close ();
            return;
        }
        
        if (label.source_type == SourceType.TODOIST) {
            submit_button.is_loading = true;
            Services.Todoist.get_default ().update.begin (label, (obj, res) => {
                submit_button.is_loading = false;
                HttpResponse response = Services.Todoist.get_default ().update.end (res);

                if (response.status) {
                    Services.Store.instance ().update_label (label);
                    close ();
                } else {
                    label.name = _name;
                    label.color = _color;

                    Services.EventBus.get_default ().send_error_toast (response.error_code, response.error);
                    close ();
                }
            });
        }
    }

    private void add_label () {
        label.item_order = Services.Store.instance ().get_labels_by_source (label.source_id).size;

        if (label.source_type == SourceType.LOCAL || label.source_type == SourceType.CALDAV) {
            label.id = Util.get_default ().generate_id (label);
            Services.Store.instance ().insert_label (label);
            close ();
            return;
        }
        
        if (label.source_type == SourceType.TODOIST) {
            submit_button.is_loading = true;
            Services.Todoist.get_default ().add.begin (label, (obj, res) => {
                submit_button.is_loading = false;
                HttpResponse response = Services.Todoist.get_default ().add.end (res);
                
                if (response.status) {
                    label.id = response.data;
                    Services.Store.instance ().insert_label (label);
                    close ();
                } else {
                    Services.EventBus.get_default ().send_error_toast (response.error_code, response.error);
                    close ();
                }
            });
        }
    }
}
