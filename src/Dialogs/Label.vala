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

public class Dialogs.Label : Hdy.Window {
    public Objects.Label label { get; construct; }

    private Gtk.Grid widget_color;
    private Widgets.Entry name_entry;
    private Widgets.LoadingButton submit_button;

    public bool is_creating {
        get {
            return label.id == Constants.INACTIVE;
        }
    }

    public string color_selected { get; set; }
    
    public Label.new () {
        var label = new Objects.Label ();
        label.color = Util.get_default ().get_random_color ();
        label.id = Constants.INACTIVE;

        Object (
            label: label,
            deletable: true,
            resizable: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            modal: true
        );
    }

    public Label (Objects.Label label) {
        Object (
            label: label,
            deletable: true,
            resizable: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            modal: true
        );
    }

    construct {
        unowned Gtk.StyleContext dialog_context = get_style_context ();
        dialog_context.add_class (Gtk.STYLE_CLASS_VIEW);
        dialog_context.add_class ("planner-dialog");
        dialog_context.remove_class ("background");

        transient_for = Planner.instance.main_window;

        var headerbar = new Hdy.HeaderBar ();
        headerbar.has_subtitle = false;
        headerbar.show_close_button = false;
        headerbar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        widget_color = new Gtk.Grid () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            hexpand = true,
            height_request = 48,
            width_request = 48
        };

        unowned Gtk.StyleContext widget_color_context = widget_color.get_style_context ();
        widget_color_context.add_class ("label-color");

        name_entry = new Widgets.Entry () {
            margin = 12,
            margin_top = 24,
            placeholder_text = _("Label name")
        };
        name_entry.text = label.name;
        name_entry.get_style_context ().add_class ("border-radius-6");
        name_entry.get_style_context ().add_class ("dialog-entry");

        var radio = new Gtk.RadioButton (null);
        var colors_hashmap = new Gee.HashMap <string, Gtk.RadioButton> ();

        var flowbox = new Gtk.FlowBox () {
            column_spacing = 12,
            row_spacing = 12,
            border_width = 6,
            max_children_per_line = 10,
            min_children_per_line = 8,
            expand = true,
            valign = Gtk.Align.START
        };

        unowned Gtk.StyleContext flowbox_context = flowbox.get_style_context ();
        flowbox_context.add_class ("flowbox-color");

        foreach (var entry in Util.get_default ().get_colors ().entries) {
            if (!entry.key.has_prefix ("#")) {
                Gtk.RadioButton color_radio = new Gtk.RadioButton (radio.get_group ());
                color_radio.valign = Gtk.Align.CENTER;
                color_radio.halign = Gtk.Align.CENTER;
                color_radio.tooltip_text = Util.get_default ().get_color_name (entry.key);
                color_radio.get_style_context ().add_class ("color-radio");
                Util.get_default ().set_widget_color (Util.get_default ().get_color (entry.key), color_radio);
                colors_hashmap [entry.key] = color_radio;
                flowbox.add (colors_hashmap [entry.key]);

                color_radio.toggled.connect (() => {
                    color_selected = entry.key;
                    Util.get_default ().set_widget_color (
                        Util.get_default ().get_color (color_selected), widget_color
                    );
                });
            }
        }

        color_selected = label.color;
        if (colors_hashmap.has_key (color_selected)) {
            colors_hashmap [color_selected].active = true;
        }

        var flowbox_grid = new Gtk.Grid () {
            margin = 12,
            margin_top = 0,
            valign = Gtk.Align.START,
            vexpand = false
        };
        flowbox_grid.add (flowbox);

        unowned Gtk.StyleContext flowbox_grid_context = flowbox_grid.get_style_context ();
        flowbox_grid_context.add_class ("picker-content");

        submit_button = new Widgets.LoadingButton (
            LoadingButtonType.LABEL,
            is_creating ? _("Add label") : _("Update label")) {
            sensitive = !is_creating
        };
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        submit_button.get_style_context ().add_class ("border-radius-6");

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("border-radius-6");

        var submit_cancel_grid = new Gtk.Grid () {
            column_spacing = 12,
            column_homogeneous = true,
            margin = 12,
            vexpand = true,
            valign = Gtk.Align.END
        };
        submit_cancel_grid.add (cancel_button);
        submit_cancel_grid.add (submit_button);

        var content_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        content_grid.add (headerbar);
        content_grid.add (widget_color);
        content_grid.add (name_entry);
        content_grid.add (flowbox_grid);
        content_grid.add (submit_cancel_grid);

        add (content_grid);
        name_entry.grab_focus ();
        
        name_entry.changed.connect (() => {
            submit_button.sensitive = Util.get_default ().is_input_valid (name_entry);
        });

        name_entry.activate.connect (add_label);
        submit_button.clicked.connect (add_label);

        cancel_button.clicked.connect (() => {
            hide_destroy ();
        });
    }

    private void add_label () {
        if (!Util.get_default ().is_input_valid (name_entry)) {
            return;
        }

        if (!is_creating) {
            label.name = name_entry.text;
            label.color = color_selected;

            submit_button.is_loading = true;
            Planner.database.update_label (label);
            if (label.todoist) {
                Planner.todoist.update.begin (label, (obj, res) => {
                    if (Planner.todoist.update.end (res)) {
                        submit_button.is_loading = false;
                        hide_destroy ();
                    }
                });
            } else {
                hide_destroy ();
            }
        } else {
            BackendType backend_type = (BackendType) Planner.settings.get_enum ("backend-type");

            label.color = color_selected;
            label.name = name_entry.text;

            if (backend_type == BackendType.TODOIST) {
                label.todoist = true;
                submit_button.is_loading = true;
                Planner.todoist.add.begin (label, (obj, res) => {
                    label.id = Planner.todoist.add.end (res);
                    Planner.database.insert_label (label);
                    Planner.event_bus.pane_selected (PaneType.LABEL, label.id_string);
                    hide_destroy ();
                });
            } else if (backend_type == BackendType.LOCAL) {
                label.id = Util.get_default ().generate_id ();
                Planner.database.insert_label (label);
                Planner.event_bus.pane_selected (PaneType.LABEL, label.id_string);
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
