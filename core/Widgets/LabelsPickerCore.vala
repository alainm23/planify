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

public class Widgets.LabelsPickerCore : Adw.Bin {
    public LabelPickerType picker_type { get; construct; }

    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox listbox;
    private Gtk.Label placeholder_message_label;
    private Gtk.Revealer add_tag_revealer;
    private Gtk.Revealer spinner_revealer;
    private Gtk.Revealer search_entry_revealer;

    public Gee.ArrayList<Objects.Label> labels {
        set {
            picked.clear ();

            foreach (Objects.Label label in value) {
                labels_widgets_map[label.id].active = true;
                picked[label.id] = label;
            }
        }
    }

    Objects.Source _source;
    public Objects.Source source {
        set {
            _source = value;
            add_labels (_source);
        }

        get {
            return _source;
        }
    }

    public bool is_loading {
        set {
            spinner_revealer.reveal_child = value;
        }
    }

    public Gee.HashMap<string, Widgets.LabelPicker.LabelRow> labels_widgets_map = new Gee.HashMap<string, Widgets.LabelPicker.LabelRow> ();
    public Gee.HashMap<string, Objects.Label> picked = new Gee.HashMap<string, Objects.Label> ();

    private string PLACEHOLDER_MESSAGE = _("Your list of filters will show up here. Create one by entering the name and pressing the Enter key."); // vala-lint=naming-convention
    private string PLACEHOLDER_CREATE_MESSAGE = _("Create '%s'"); // vala-lint=naming-convention

    public signal void close ();

    private Gee.HashMap<ulong, weak GLib.Object> signals_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public LabelsPickerCore (LabelPickerType picker_type) {
        Object (
            picker_type: picker_type
        );
    }

    ~LabelsPickerCore () {
        print ("Destroying - Widgets.LabelsPickerCore\n");
    }

    construct {
        css_classes = { "popover-contents" };

        if (picker_type == LabelPickerType.FILTER_ONLY) {
            PLACEHOLDER_MESSAGE = _("Your list of filters will show up here.");
        }

        search_entry = new Gtk.SearchEntry () {
            placeholder_text = picker_type == LabelPickerType.FILTER_ONLY ? _("Search") : _("Search or Create"),
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };

        search_entry_revealer = new Gtk.Revealer () {
            child = search_entry,
            reveal_child = true
        };

        listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = Gtk.Align.START,
            css_classes = { "listbox-background" }
        };

        listbox.set_placeholder (get_placeholder ());

        listbox.set_sort_func ((row1, row2) => {
            Objects.Label item1 = ((Widgets.LabelPicker.LabelRow) row1).label;
            Objects.Label item2 = ((Widgets.LabelPicker.LabelRow) row2).label;
            return item1.item_order - item2.item_order;
        });

        var listbox_grid = new Adw.Bin () {
            margin_start = 9,
            margin_end = 9,
            margin_bottom = 6,
            child = listbox,
            valign = Gtk.Align.START
        };

        var listbox_scrolled = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        listbox_scrolled.child = listbox_grid;

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (search_entry_revealer);
        toolbar_view.content = listbox_scrolled;

        child = toolbar_view;

        var listbox_controller_key = new Gtk.EventControllerKey ();
        listbox.add_controller (listbox_controller_key);
        signals_map[listbox_controller_key.key_pressed.connect ((keyval, keycode, state) => {
            var key = Gdk.keyval_name (keyval).replace ("KP_", "");

            if (key == "Up" || key == "Down") {
            } else if (key == "Enter" || key == "Return" || key == "KP_Enter") {
            } else {
                if (!search_entry.has_focus) {
                    search_entry.grab_focus ();
                    if (search_entry.cursor_position < search_entry.text.length) {
                        search_entry.set_position (search_entry.text.length);
                    }
                }
            }

            return false;
        })] = listbox_controller_key;

        signals_map[search_entry.search_changed.connect (() => {
            int size = 0;
            listbox.set_filter_func ((row) => {
                var label = ((Widgets.LabelPicker.LabelRow) row).label;
                var return_value = search_entry.text.down () in label.name.down ();

                if (return_value) {
                    size++;
                }

                return return_value;
            });

            if (picker_type == LabelPickerType.FILTER_AND_CREATE) {
                add_tag_revealer.reveal_child = size <= 0;
                placeholder_message_label.label = size <= 0 ? PLACEHOLDER_CREATE_MESSAGE.printf (search_entry.text) : PLACEHOLDER_MESSAGE;
            }
        })] = search_entry;

        signals_map[search_entry.activate.connect (() => {
            if (source != null && search_entry.text.length > 0) {
                Objects.Label label = Services.Store.instance ().get_label_by_name (search_entry.text, true, source.id);
                if (label != null) {
                    if (labels_widgets_map.has_key (label.id_string)) {
                        labels_widgets_map[label.id_string].update_checked_toggled ();
                    }
                } else {
                    add_assign_label ();
                }
            }
        })] = search_entry;

        var search_entry_ctrl_key = new Gtk.EventControllerKey ();
        search_entry.add_controller (search_entry_ctrl_key);
        signals_map[search_entry_ctrl_key.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == 65307) {
                close ();
            }

            return false;
        })] = search_entry_ctrl_key;

        signals_map[Services.Store.instance ().label_added.connect ((label) => {
            add_label (label);
        })] = Services.Store.instance ();
    }

    private void add_assign_label () {
        var label = new Objects.Label ();
        label.color = Util.get_default ().get_random_color ();
        label.name = search_entry.text;
        label.source_id = source.id;

        if (source.source_type == SourceType.LOCAL || source.source_type == SourceType.CALDAV) {
            label.id = Util.get_default ().generate_id (label);
            Services.Store.instance ().insert_label (label);
            checked_toggled (label, true);

            search_entry.text = "";
            close ();
        } else if (source.source_type == SourceType.TODOIST) {
            is_loading = true;
            Services.Todoist.get_default ().add.begin (label, (obj, res) => {
                HttpResponse response = Services.Todoist.get_default ().add.end (res);

                if (response.status) {
                    label.id = response.data;
                    Services.Store.instance ().insert_label (label);
                    checked_toggled (label, true);
                }

                close ();
                is_loading = false;
                search_entry.text = "";
            });
        }
    }

    private void add_labels (Objects.Source source) {
        labels_widgets_map.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox)) {
            listbox.remove (child);
        }

        foreach (Objects.Label label in Services.Store.instance ().get_labels_by_source (source.id)) {
            add_label (label);
        }
    }

    private void add_label (Objects.Label label) {
        labels_widgets_map[label.id] = new Widgets.LabelPicker.LabelRow (label);
        signals_map[labels_widgets_map[label.id].checked_toggled.connect (checked_toggled)] = labels_widgets_map[label.id];
        listbox.append (labels_widgets_map[label.id]);
    }

    private Gtk.Widget get_placeholder () {
        var add_tag_icon = new Gtk.Image.from_icon_name ("tag-outline-add-symbolic") {
            pixel_size = 24,
            margin_bottom = 12
        };

        add_tag_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_UP,
            child = add_tag_icon
        };

        placeholder_message_label = new Gtk.Label (PLACEHOLDER_MESSAGE) {
            wrap = true,
            justify = Gtk.Justification.CENTER,
            css_classes = { "dimmed", "caption" }
        };

        var spinner = new Adw.Spinner () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            height_request = 24,
            width_request = 24,
            margin_top = 12,
            css_classes = { "text-color" }
        };

        spinner_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_UP,
            child = spinner
        };

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = CENTER,
            margin_start = 24,
            margin_end = 24,
            margin_top = 24
        };
        box.append (add_tag_revealer);
        box.append (placeholder_message_label);
        box.append (spinner_revealer);

        return box;
    }

    private void checked_toggled (Objects.Label label, bool active) {
        if (active) {
            if (!picked.has_key (label.id)) {
                picked[label.id] = label;
            }
        } else {
            if (picked.has_key (label.id)) {
                picked.unset (label.id);
            }
        }
    }

    public void reset () {
        foreach (var entry in labels_widgets_map.entries) {
            labels_widgets_map[entry.key].active = false;
        }

        labels_widgets_map.clear ();
    }

    public void add_labels_list (Gee.ArrayList<Objects.Label> labels_list) {
        labels_widgets_map.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox)) {
            listbox.remove (child);
        }

        foreach (Objects.Label label in labels_list) {
            add_label (label);
        }
    }

    public void clean_up () {
        listbox.set_sort_func (null);
        listbox.set_filter_func (null);

        foreach (var entry in labels_widgets_map.entries) {
            labels_widgets_map[entry.key].clean_up ();
        }

        foreach (var entry in signals_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signals_map.clear ();
    }
}
