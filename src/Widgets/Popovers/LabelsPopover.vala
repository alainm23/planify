/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Widgets.Popovers.LabelsPopover : Gtk.Popover {
    private Gtk.Stack main_stack;
    private Granite.Widgets.ModeButton mode_button;

    public Gtk.ListBox labels_listbox;
    private Gtk.Button submit_button;
    private Gtk.Entry label_entry;
    private Gtk.Entry color_hex_entry;

    private Objects.Label label;

    private bool edit;
    public bool filter {
        set {
            if (value) {
                mode_button.visible = false;
                mode_button.no_show_all = true;
                main_stack.margin_top = 12;
            }
        }
        get {
            return mode_button.no_show_all;
        }
    }

    private int label_update_id;
    public const string COLOR_CSS = """
        .label-preview {
            background-image:
                linear-gradient(
                    to bottom,
                    shade (
                    %s,
                        1.3
                    ),
                    %s
                );
            border: 1px solid shade (%s, 0.9);
            border-radius: 3px;
            box-shadow:
                inset 0 0 0 1px alpha (#fff, 0.05),
                inset 0 1px 0 0 alpha (#fff, 0.25),
                inset 0 -1px 0 0 alpha (#fff, 0.1),
                0 1px 2px alpha (#000, 0.3);
            color: %s;
            padding: 1 6px;
            font-size: 11px;
            font-weight: 700;
            margin: 2px;
            min-width: 18px;
            min-height: 18px;
            text-shadow: 0 1px 1px alpha (#000, 0.3);
        }
    """;
    public signal void on_selected_label (Objects.Label label);
    public LabelsPopover (Gtk.Widget relative, bool filter) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.RIGHT,
            filter: filter
        );
    }

    construct {
        label = new Objects.Label ();
        edit = false;

        mode_button = new Granite.Widgets.ModeButton ();
        mode_button.hexpand = true;
        mode_button.margin = 6;
        mode_button.valign = Gtk.Align.CENTER;

        mode_button.append_icon ("tag-symbolic", Gtk.IconSize.MENU);
        mode_button.append_icon ("list-add-symbolic", Gtk.IconSize.MENU);

        mode_button.selected = 0;

        main_stack = new Gtk.Stack ();
        main_stack.expand = true;
        main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        main_stack.add_named (get_all_labels_widget (), "labels_view");
        main_stack.add_named (get_new_label_widget (), "add_label_view");

        var main_grid = new Gtk.Grid ();
        main_grid.expand = true;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.width_request = 250;

        main_grid.add (mode_button);
        main_grid.add (main_stack);

        add (main_grid);
        update_label_list ();

        mode_button.mode_changed.connect ((widget) => {
            if (mode_button.selected == 0) {
                main_stack.visible_child_name = "labels_view";

                label_entry.text = "";
                color_hex_entry.text = "";

                label.name = "";
                label.color = "";
                edit = false;
                label_update_id = 0;
            } else {
                main_stack.visible_child_name = "add_label_view";

                submit_button.label = _("Add");
            }
        });

        labels_listbox.row_activated.connect ((item_row) => {
            var row = item_row as Widgets.LabelRow;
            on_selected_label (row.label);
        });
    }

    public void update_label_list () {
        foreach (Gtk.Widget element in labels_listbox.get_children ()) {
            labels_listbox.remove (element);
        }

        var all_labels = new Gee.ArrayList<Objects.Label?> ();
        all_labels = Application.database.get_all_labels ();

        foreach (var label in all_labels) {
            var row = new Widgets.LabelRow (label, filter);

            labels_listbox.add (row);

            row.on_signal_edit.connect ((_label) => {
                mode_button.selected = 1;
                main_stack.visible_child_name = "add_label_view";
                edit = true;

                submit_button.label = _("Update");
                label_entry.text = _label.name;
                color_hex_entry.text = _label.color;

                label_update_id = _label.id;
            });
        }
    }

    private void add_styles (string color_hex) {
        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (
                color_hex,                  // Background Color
                color_hex,
                color_hex,
                Application.utils.convert_invert (color_hex)  // Text Color
            );
            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }

    private Gtk.Widget get_new_label_widget () {
        var label_preview = new Gtk.Label ("Label name");
        label_preview.valign = Gtk.Align.CENTER;
        label_preview.get_style_context ().add_class ("label-preview");

        label_entry = new Gtk.Entry ();
        label_entry.hexpand = true;
        label_entry.placeholder_text = _("Priority: Low");

        var random_button = new Gtk.Button.from_icon_name ("system-reboot-symbolic", Gtk.IconSize.MENU);
        random_button.can_focus = false;

        color_hex_entry = new Gtk.Entry ();
        color_hex_entry.hexpand = true;
        color_hex_entry.placeholder_text = "#7239b3";
        color_hex_entry.max_length = 7;

        var color_button = new Gtk.ColorButton ();
        color_button.can_focus = false;

        var color_grid = new Gtk.Grid ();
        color_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        color_grid.add (color_hex_entry);
        color_grid.add (random_button);
        color_grid.add (color_button);

        submit_button = new Gtk.Button.with_label (_("Add"));
        submit_button.margin_top = 12;
        submit_button.sensitive = false;
        submit_button.valign = Gtk.Align.END;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        submit_button.tooltip_text = _("Add new label");

        var grid = new Gtk.Grid ();
        grid.margin = 6;
        grid.margin_top = 0;
        grid.expand = true;
        grid.row_spacing = 3;
        grid.orientation = Gtk.Orientation.VERTICAL;

        grid.add (new Granite.HeaderLabel (_("Preview")));
        grid.add (label_preview);
        grid.add (new Granite.HeaderLabel (_("Name")));
        grid.add (label_entry);
        grid.add (new Granite.HeaderLabel (_("Color")));
        grid.add (color_grid);
        grid.add (submit_button);

        label_entry.changed.connect (() => {
            if (label_entry.text == "") {
                submit_button.sensitive = false;
                label_preview.label = "";
            } else {
                submit_button.sensitive = true;
                label_preview.label = label_entry.text;
            }
        });

        color_hex_entry.changed.connect (() => {
            var rgba = Gdk.RGBA ();
            if (rgba.parse (color_hex_entry.text)) {
                color_button.rgba = rgba;
                add_styles (Application.utils.rgb_to_hex_string (color_button.rgba));
            }
        });

        random_button.clicked.connect (() => {
            string random_color = "rgb(%i, %i, %i)".printf (
                GLib.Random.int_range (0, 255), 
                GLib.Random.int_range (0, 255), 
                GLib.Random.int_range (0, 255)
            );

            var rgba = Gdk.RGBA ();
            rgba.parse (random_color);

            color_button.rgba = rgba;
            color_hex_entry.text = Application.utils.rgb_to_hex_string (color_button.rgba);

            add_styles (Application.utils.rgb_to_hex_string (rgba));
        });

        color_button.color_set.connect (() => {
            color_hex_entry.text = Application.utils.rgb_to_hex_string (color_button.rgba);
            add_styles (Application.utils.rgb_to_hex_string (color_button.rgba));
        });

        submit_button.clicked.connect (() => {
            label.name = label_entry.text;
            label.color = Application.utils.rgb_to_hex_string (color_button.rgba);

            if (edit) {
                label.id = label_update_id;
                if (Application.database.update_label (label) == Sqlite.DONE) {
                    label_entry.text = "";
                    color_hex_entry.text = "";

                    main_stack.visible_child_name = "labels_view";
                    mode_button.selected = 0;

                    update_label_list ();
                    show_all ();

                    label.name = "";
                    label.color = "";
                    edit = false;
                    label_update_id = 0;
                }
            } else {
                if (Application.database.add_label (label) == Sqlite.DONE) {
                    label_entry.text = "";
                    color_hex_entry.text = "";

                    main_stack.visible_child_name = "labels_view";
                    mode_button.selected = 0;

                    update_label_list ();
                    show_all ();

                    label.name = "";
                    label.color = "";
                    edit = false;
                    label_update_id = 0;
                }
            }
        });

        add_styles ("#333");
        return grid;
    }

    private Gtk.Widget get_all_labels_widget () {
        labels_listbox = new Gtk.ListBox  ();
        labels_listbox.activate_on_single_click = true;
        labels_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        labels_listbox.expand = true;

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.add (labels_listbox);

        var grid = new Gtk.Grid ();;
        grid.expand = true;
        grid.orientation = Gtk.Orientation.VERTICAL;
        
        grid.add (scrolled_window);

        return grid;
    }
}
