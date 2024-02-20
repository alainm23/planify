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

public class Widgets.LabelPicker.LabelPicker : Gtk.Popover {
    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox listbox;
    private Gtk.Label placeholder_message_label;
    private Gtk.Revealer add_tag_revealer;
    private Gtk.Revealer spinner_revealer;
    
    public Gee.ArrayList<Objects.Label> labels {
        set {
            picked.clear ();

            foreach (Objects.Label label in value) {
                labels_widgets_map [label.id].active = true;
                picked[label.id] = label;
            }
        }
    }

    BackendType _backend_type;
    public BackendType backend_type {
        set {
            _backend_type = value;
            add_all_labels (_backend_type);
        }

        get {
            return _backend_type;
        }
    }
    
    public bool is_loading {
        set {
            spinner_revealer.reveal_child = value;
        }
    }

    public Gee.HashMap <string, Widgets.LabelPicker.LabelRow> labels_widgets_map = new Gee.HashMap <string, Widgets.LabelPicker.LabelRow> ();
    public Gee.HashMap<string, Objects.Label> picked = new Gee.HashMap<string, Objects.Label> ();

    private string PLACEHOLDER_MESSAGE = _("Your list of filters will show up here. Create one by entering the name and pressing the Enter key."); // vala-lint=naming-convention
    private string PLACEHOLDER_CREATE_MESSAGE = _("Create '%s'"); // vala-lint=naming-convention

    public LabelPicker () {
        Object (
            has_arrow: false,
            position: Gtk.PositionType.TOP,
            width_request: 275,
            height_request: 300
        );
    }

    construct {
        css_classes = { "popover-contents" };
        
        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Search or Create"),
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_top = 9,
            margin_start = 9,
            margin_end = 9,
            margin_bottom = 9
        };

        listbox = new Gtk.ListBox () {
            hexpand = true
        };

        listbox.set_placeholder (get_placeholder ());
        listbox.add_css_class ("listbox-separator-3");
        listbox.add_css_class ("listbox-background");

        var listbox_grid = new Adw.Bin () {
            margin_start = 3,
            margin_end = 3,
            margin_bottom = 9,
            child = listbox
        };

        var listbox_scrolled = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        listbox_scrolled.child = listbox_grid;

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (search_entry);
		toolbar_view.content = listbox_scrolled;

        child = toolbar_view;

        var controller_key = new Gtk.EventControllerKey ();
        toolbar_view.add_controller (controller_key);

        controller_key.key_pressed.connect ((keyval, keycode, state) => {
            var key = Gdk.keyval_name (keyval).replace ("KP_", "");
                        
            if (key == "Up" || key == "Down") {
                return false;
            } else if (key == "Enter" || key == "Return" || key == "KP_Enter") {
                return false;
            } else {
                if (!search_entry.has_focus) {
                    search_entry.grab_focus ();
                    if (search_entry.cursor_position < search_entry.text.length) {
                        search_entry.set_position (search_entry.text.length);
                    }
                }

                return false;
            }

            return true;
        });

        search_entry.search_changed.connect (() => {
            int size = 0;
            listbox.set_filter_func ((row) => {
                var label = ((Widgets.LabelPicker.LabelRow) row).label;
                var return_value = search_entry.text.down () in label.name.down ();

                if (return_value) {
                    size++;
                }

                return return_value;
            });

            add_tag_revealer.reveal_child = size <= 0;
            placeholder_message_label.label = size <= 0 ? PLACEHOLDER_CREATE_MESSAGE.printf (search_entry.text) : PLACEHOLDER_MESSAGE;
        });

        search_entry.activate.connect (() => {
            if (search_entry.text.length > 0) {
                Objects.Label label = Services.Database.get_default ().get_label_by_name (search_entry.text, true, backend_type);
                if (label != null) {
                    if (labels_widgets_map.has_key (label.id_string)) {
                        labels_widgets_map [label.id_string].update_checked_toggled ();
                    }
                } else {
                    add_assign_label ();
                }
            }
        });

        Services.Database.get_default ().label_added.connect ((label) => {
            add_label (label);
        });
    }

    private void add_assign_label () {
        var label = new Objects.Label ();
        label.color = Util.get_default ().get_random_color ();
        label.name = search_entry.text;

        if (backend_type == BackendType.LOCAL || backend_type == BackendType.CALDAV) {
            label.id = Util.get_default ().generate_id (label);
            label.backend_type = BackendType.LOCAL;
            Services.Database.get_default ().insert_label (label);
            checked_toggled (label, true);

            search_entry.text = "";
            popdown ();
        } else if (backend_type == BackendType.TODOIST) {
            is_loading = true;
            label.backend_type = BackendType.TODOIST;
            Services.Todoist.get_default ().add.begin (label, (obj, res) => {
                HttpResponse response = Services.Todoist.get_default ().add.end (res);

                if (response.status) {
                    label.id = response.data;
                    Services.Database.get_default ().insert_label (label);
                    checked_toggled (label, true);
                }

                popdown ();
                is_loading = false;
                search_entry.text = "";
            });
        }
    }

    private void add_all_labels (BackendType backend_type) {
        labels_widgets_map.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox) ) {
            listbox.remove (child);
        }

        foreach (Objects.Label label in Services.Database.get_default ().get_labels_by_backend_type (backend_type)) {
            add_label (label);
        }
    }

    private void add_label (Objects.Label label) {
        labels_widgets_map [label.id] = new Widgets.LabelPicker.LabelRow (label);
        labels_widgets_map [label.id].checked_toggled.connect (checked_toggled);
        listbox.append (labels_widgets_map [label.id]);
    }

    private Gtk.Widget get_placeholder () {
        var add_tag_icon = new Widgets.DynamicIcon.from_icon_name ("tag-add") {
            size = 24,
            margin_bottom = 12
        };

        add_tag_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_UP,
            child = add_tag_icon
        };

        placeholder_message_label = new Gtk.Label (PLACEHOLDER_MESSAGE) {
            wrap = true,
            justify = Gtk.Justification.CENTER,
            css_classes = { "dim-label", Granite.STYLE_CLASS_SMALL_LABEL }
        };
        
        var spinner = new Gtk.Spinner () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            height_request = 24,
            width_request = 24,
            margin_top = 12,
            css_classes = { "text-color" },
            spinning = true
        };

        spinner_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_UP,
            child = spinner
        };

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = CENTER,
            margin_start = 12,
            margin_end = 12
        };
        box.append (add_tag_revealer);
        box.append (placeholder_message_label);
        box.append (spinner_revealer);

        return box;
    }

    private void checked_toggled (Objects.Label label, bool active) {
        if (active) {
            if (!picked.has_key (label.id)) {
                picked [label.id] = label;
            }
        } else {
            if (picked.has_key (label.id)) {
                picked.unset (label.id);
            }
        }
    }

    public void reset () {
        foreach (var entry in labels_widgets_map.entries) {
            labels_widgets_map [entry.key].active = false;
        }

        labels_widgets_map.clear ();
    }
}
