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

public class Dialogs.LabelPicker : Adw.Window {
    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox listbox;
    private Gtk.Stack placeholder_stack;

    public bool is_loading {
        set {
            placeholder_stack.visible_child_name = value ? "spinner" : "message";
        }
    }

    Gee.HashMap <string, Objects.Label> _labels = new Gee.HashMap <string, Objects.Label> ();
    public Gee.HashMap <string, Objects.Label> labels {
        get {
            return _labels;
        }

        set {
            _labels = value;
            
            foreach (Objects.Label label in Services.Database.get_default ().labels) {
                labels_widgets_map [label.id_string].active = _labels.has_key (label.id_string);
            }
        }
    }

    public Gee.HashMap <string, Widgets.LabelPicker.LabelRow> labels_widgets_map;

    public signal void labels_changed (Gee.HashMap <string, Objects.Label> labels);
    
    public LabelPicker () {
        Object (
            deletable: true,
            resizable: true,
            modal: true,
            title: _("Labels"),
            width_request: 320,
            height_request: 450,
            transient_for: (Gtk.Window) Planify.instance.main_window
        );
    }

    construct {
        labels_widgets_map = new Gee.HashMap <string, Widgets.LabelPicker.LabelRow> ();

        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);

        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Search or Create"),
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_start = 12,
            margin_end = 12
        };

        listbox = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true,
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6
        };

        listbox.set_placeholder (get_placeholder ());
        listbox.set_filter_func (filter_func);
        listbox.add_css_class ("listbox-separator-3");
        listbox.add_css_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin_start = 12,
            margin_end = 12,
            margin_top = 12
        };

        listbox_grid.attach (listbox, 0, 0);
        listbox_grid.add_css_class (Granite.STYLE_CLASS_CARD);

        var listbox_scrolled = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            height_request = 175
        };

        listbox_scrolled.child = listbox_grid;
        
        var submit_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Filter")) {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };
        submit_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            width_request = 225
        };
        
        content_box.append (headerbar);
        content_box.append (search_entry);
        content_box.append (listbox_scrolled);
        content_box.append (submit_button);

        content = content_box;
        add_all_labels ();

        submit_button.clicked.connect (() => {
            labels_changed (_labels);
            hide_destroy ();
        });
    }

    private void add_all_labels () {
        foreach (Objects.Label label in Services.Database.get_default ().labels) {
            add_label (label);
        }
    }

    private void add_label (Objects.Label label) {
        if (!labels_widgets_map.has_key (label.id_string)) {
            var row = new Widgets.LabelPicker.LabelRow (label);
            row.checked_toggled.connect (checked_toggled);

            labels_widgets_map[label.id_string] = row;
            listbox.append (labels_widgets_map[label.id_string]);
        }
    }

    private Gtk.Widget get_placeholder () {
        var message_label = new Gtk.Label (_("Your list of filters will show up here. Create one by entering the name and pressing the Enter key.")) {
            wrap = true,
            justify = Gtk.Justification.CENTER
        };
        
        message_label.add_css_class ("dim-label");
        message_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        
        var spinner = new Gtk.Spinner () {
            valign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            height_request = 32,
            width_request = 32
        };

        spinner.add_css_class ("text-color");
        spinner.start ();

        placeholder_stack = new Gtk.Stack () {
            vexpand = true,
            hexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        placeholder_stack.add_named (message_label, "message");
        placeholder_stack.add_named (spinner, "spinner");

        var grid = new Gtk.Grid () {
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6,
            valign = Gtk.Align.CENTER
        };

        grid.attach (placeholder_stack, 0, 0);

        return grid;
    }

    private void checked_toggled (Objects.Label label, bool active) {
        if (active) {
            if (!_labels.has_key (label.id_string)) {
                _labels [label.id_string] = label;
            }
        } else {
            if (_labels.has_key (label.id_string)) {
                _labels.unset (label.id_string);
            }
        }
    }

    private bool filter_func (Gtk.ListBoxRow row) {
        var label = ((Widgets.LabelPicker.LabelRow) row).label;
        return search_entry.text.down () in label.name.down ();
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}
