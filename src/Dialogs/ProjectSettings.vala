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

public class Dialogs.ProjectSettings : Gtk.Dialog {
    public Objects.Project project { get; construct; }
    private Gtk.Entry name_entry;

    private int color_selected;

    public ProjectSettings (Objects.Project project) {
        Object (
            project: project,
            transient_for: Planner.instance.main_window,
            deletable: false,
            resizable: true,
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            modal: false
        );
    }

    construct {
        height_request = 550;
        width_request = 480;
        color_selected = project.color;
        get_style_context ().add_class ("planner-dialog");

        var name_label = new Granite.HeaderLabel (_("Name:"));

        name_entry = new Gtk.Entry ();
        name_entry.text = project.name;

        var due_label = new Granite.HeaderLabel (_("Due:"));
        var due_datepicker = new Granite.Widgets.DatePicker ();

        var color_label = new Granite.HeaderLabel (_("Color:"));

        var color_30 = new Gtk.RadioButton (null);
        color_30.valign = Gtk.Align.START;
        color_30.halign = Gtk.Align.START;
        color_30.tooltip_text = Planner.utils.get_color_name (30);
        Planner.utils.apply_styles ("30", Planner.utils.get_color (30), color_30);
        color_30.get_style_context ().add_class ("color-radio-dialog");

        var color_31 = new Gtk.RadioButton.from_widget (color_30);
        color_31.valign = Gtk.Align.START;
        color_31.halign = Gtk.Align.START;
        color_31.tooltip_text = Planner.utils.get_color_name (31);
        Planner.utils.apply_styles ("31", Planner.utils.get_color (31), color_31);
        color_31.get_style_context ().add_class ("color-radio-dialog");

        var color_32 = new Gtk.RadioButton.from_widget (color_30);
        color_32.valign = Gtk.Align.START;
        color_32.halign = Gtk.Align.START;
        color_32.tooltip_text = Planner.utils.get_color_name (32);
        Planner.utils.apply_styles ("32", Planner.utils.get_color (32), color_32);
        color_32.get_style_context ().add_class ("color-radio-dialog");

        var color_33 = new Gtk.RadioButton.from_widget (color_30);
        color_33.valign = Gtk.Align.START;
        color_33.halign = Gtk.Align.START;
        color_33.tooltip_text = Planner.utils.get_color_name (33);
        Planner.utils.apply_styles ("33", Planner.utils.get_color (33), color_33);
        color_33.get_style_context ().add_class ("color-radio-dialog");

        var color_34 = new Gtk.RadioButton.from_widget (color_30);
        color_34.valign = Gtk.Align.START;
        color_34.halign = Gtk.Align.START;
        color_34.tooltip_text = Planner.utils.get_color_name (34);
        Planner.utils.apply_styles ("34", Planner.utils.get_color (34), color_34);
        color_34.get_style_context ().add_class ("color-radio-dialog");

        var color_35 = new Gtk.RadioButton.from_widget (color_30);
        color_35.valign = Gtk.Align.START;
        color_35.halign = Gtk.Align.START;
        color_35.tooltip_text = Planner.utils.get_color_name (35);
        Planner.utils.apply_styles ("35", Planner.utils.get_color (35), color_35);
        color_35.get_style_context ().add_class ("color-radio-dialog");

        var color_36 = new Gtk.RadioButton.from_widget (color_30);
        color_36.valign = Gtk.Align.START;
        color_36.halign = Gtk.Align.START;
        color_36.tooltip_text = Planner.utils.get_color_name (36);
        Planner.utils.apply_styles ("36", Planner.utils.get_color (36), color_36);
        color_36.get_style_context ().add_class ("color-radio-dialog");

        var color_37 = new Gtk.RadioButton.from_widget (color_30);
        color_37.valign = Gtk.Align.START;
        color_37.halign = Gtk.Align.START;
        color_37.tooltip_text = Planner.utils.get_color_name (37);
        Planner.utils.apply_styles ("37", Planner.utils.get_color (37), color_37);
        color_37.get_style_context ().add_class ("color-radio-dialog");

        var color_38 = new Gtk.RadioButton.from_widget (color_30);
        color_38.valign = Gtk.Align.START;
        color_38.halign = Gtk.Align.START;
        color_38.tooltip_text = Planner.utils.get_color_name (38);
        Planner.utils.apply_styles ("38", Planner.utils.get_color (38), color_38);
        color_38.get_style_context ().add_class ("color-radio-dialog");

        var color_39 = new Gtk.RadioButton.from_widget (color_30);
        color_39.valign = Gtk.Align.START;
        color_39.halign = Gtk.Align.START;
        color_39.tooltip_text = Planner.utils.get_color_name (39);
        Planner.utils.apply_styles ("39", Planner.utils.get_color (39), color_39);
        color_39.get_style_context ().add_class ("color-radio-dialog");

        var color_40 = new Gtk.RadioButton.from_widget (color_30);
        color_40.valign = Gtk.Align.START;
        color_40.halign = Gtk.Align.START;
        color_40.tooltip_text = Planner.utils.get_color_name (40);
        Planner.utils.apply_styles ("40", Planner.utils.get_color (40), color_40);
        color_40.get_style_context ().add_class ("color-radio-dialog");

        var color_41 = new Gtk.RadioButton.from_widget (color_30);
        color_41.valign = Gtk.Align.START;
        color_41.halign = Gtk.Align.START;
        color_41.tooltip_text = Planner.utils.get_color_name (41);
        Planner.utils.apply_styles ("41", Planner.utils.get_color (41), color_41);
        color_41.get_style_context ().add_class ("color-radio-dialog");

        var color_42 = new Gtk.RadioButton.from_widget (color_30);
        color_42.valign = Gtk.Align.START;
        color_42.halign = Gtk.Align.START;
        color_42.tooltip_text = Planner.utils.get_color_name (42);
        Planner.utils.apply_styles ("42", Planner.utils.get_color (42), color_42);
        color_42.get_style_context ().add_class ("color-radio-dialog");

        var color_43 = new Gtk.RadioButton.from_widget (color_30);
        color_43.valign = Gtk.Align.START;
        color_43.halign = Gtk.Align.START;
        color_43.tooltip_text = Planner.utils.get_color_name (43);
        Planner.utils.apply_styles ("43", Planner.utils.get_color (43), color_43);
        color_43.get_style_context ().add_class ("color-radio-dialog");

        var color_44 = new Gtk.RadioButton.from_widget (color_30);
        color_44.valign = Gtk.Align.START;
        color_44.halign = Gtk.Align.START;
        color_44.tooltip_text = Planner.utils.get_color_name (44);
        Planner.utils.apply_styles ("44", Planner.utils.get_color (44), color_44);
        color_44.get_style_context ().add_class ("color-radio-dialog");

        var color_45 = new Gtk.RadioButton.from_widget (color_30);
        color_45.valign = Gtk.Align.START;
        color_45.halign = Gtk.Align.START;
        color_45.tooltip_text = Planner.utils.get_color_name (45);
        Planner.utils.apply_styles ("45", Planner.utils.get_color (45), color_45);
        color_45.get_style_context ().add_class ("color-radio-dialog");

        var color_46 = new Gtk.RadioButton.from_widget (color_30);
        color_46.valign = Gtk.Align.START;
        color_46.halign = Gtk.Align.START;
        color_46.tooltip_text = Planner.utils.get_color_name (46);
        Planner.utils.apply_styles ("46", Planner.utils.get_color (46), color_46);
        color_46.get_style_context ().add_class ("color-radio-dialog");

        var color_47 = new Gtk.RadioButton.from_widget (color_30);
        color_47.valign = Gtk.Align.START;
        color_47.halign = Gtk.Align.START;
        color_47.tooltip_text = Planner.utils.get_color_name (47);
        Planner.utils.apply_styles ("47", Planner.utils.get_color (47), color_47);
        color_47.get_style_context ().add_class ("color-radio-dialog");

        var color_48 = new Gtk.RadioButton.from_widget (color_30);
        color_48.valign = Gtk.Align.START;
        color_48.halign = Gtk.Align.START;
        color_48.tooltip_text = Planner.utils.get_color_name (48);
        Planner.utils.apply_styles ("48", Planner.utils.get_color (48), color_48);
        color_48.get_style_context ().add_class ("color-radio-dialog");

        var color_49 = new Gtk.RadioButton.from_widget (color_30);
        color_49.valign = Gtk.Align.START;
        color_49.halign = Gtk.Align.START;
        color_49.tooltip_text = Planner.utils.get_color_name (49);
        Planner.utils.apply_styles ("49", Planner.utils.get_color (49), color_49);
        color_49.get_style_context ().add_class ("color-radio-dialog");

        var color_box = new Gtk.Grid ();
        color_box.column_homogeneous = true;
        color_box.row_homogeneous = true;
        color_box.row_spacing = 9;
        color_box.column_spacing = 12;

        color_box.attach (color_30, 0, 0, 1, 1);
        color_box.attach (color_31, 1, 0, 1, 1);
        color_box.attach (color_32, 2, 0, 1, 1);
        color_box.attach (color_33, 3, 0, 1, 1);
        color_box.attach (color_34, 4, 0, 1, 1);
        color_box.attach (color_35, 5, 0, 1, 1);
        color_box.attach (color_36, 6, 0, 1, 1);
        color_box.attach (color_37, 0, 1, 1, 1);
        color_box.attach (color_38, 1, 1, 1, 1);
        color_box.attach (color_39, 2, 1, 1, 1);
        color_box.attach (color_40, 3, 1, 1, 1);
        color_box.attach (color_41, 4, 1, 1, 1);
        color_box.attach (color_42, 5, 1, 1, 1);
        color_box.attach (color_43, 6, 1, 1, 1);
        color_box.attach (color_44, 0, 2, 1, 1);
        color_box.attach (color_45, 1, 2, 1, 1);
        color_box.attach (color_46, 2, 2, 1, 1);
        color_box.attach (color_47, 3, 2, 1, 1);
        color_box.attach (color_48, 4, 2, 1, 1);
        color_box.attach (color_49, 5, 2, 1, 1);

        var loading_spinner = new Gtk.Spinner ();
        loading_spinner.start ();

        var loading_label = new Gtk.Label (_("Uploading changes…"));

        var loading_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        loading_box.margin_top = 12;
        loading_box.hexpand = true;
        loading_box.pack_start (loading_spinner, false, false, 0);
        loading_box.pack_start (loading_label, false, false, 6);

        var loading_revealer = new Gtk.Revealer ();
        loading_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        loading_revealer.add (loading_box);

        var grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        grid.margin = 12;
        grid.margin_top = 0;
        grid.expand = true;
        grid.add (name_label);
        grid.add (name_entry);
        //grid.add (due_label);
        //grid.add (due_datepicker);
        grid.add (color_label);
        grid.add (color_box);
        grid.add (loading_revealer);
        grid.show_all ();

        get_content_area ().add (grid);

        add_button (_("Close"), Gtk.ResponseType.CLOSE);

        var save_button = (Gtk.Button) add_button (_("Save"), Gtk.ResponseType.APPLY);
        save_button.has_default = true;
        save_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        switch (project.color) {
            case 30:
                color_30.active = true;
                break;
            case 31:
                color_31.active = true;
                break;
            case 32:
                color_32.active = true;
                break;
            case 33:
                color_33.active = true;
                break;
            case 34:
                color_34.active = true;
                break;
            case 35:
                color_35.active = true;
                break;
            case 36:
                color_36.active = true;
                break;
            case 37:
                color_37.active = true;
                break;
            case 38:
                color_38.active = true;
                break;
            case 39:
                color_39.active = true;
                break;
            case 40:
                color_40.active = true;
                break;
            case 41:
                color_41.active = true;
                break;
            case 42:
                color_42.active = true;
                break;
            case 43:
                color_43.active = true;
                break;
            case 44:
                color_44.active = true;
                break;
            case 45:
                color_45.active = true;
                break;
            case 46:
                color_46.active = true;
                break;
            case 47:
                color_47.active = true;
                break;
            case 48:
                color_48.active = true;
                break;
            case 49:
                color_49.active = true;
                break;
            default:
                break;
        }

        name_entry.changed.connect (() => {
            if (name_entry.text != "") {
                save_button.sensitive = true;
            } else {
                save_button.sensitive = false;
            }
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                destroy ();
            }

            return false;
        });

        name_entry.activate.connect (() => {
            save_and_exit ();
        });

        color_30.toggled.connect (() => {
            color_selected = 30;
        });

        color_31.toggled.connect (() => {
            color_selected = 31;
        });

        color_32.toggled.connect (() => {
            color_selected = 32;
        });

        color_33.toggled.connect (() => {
            color_selected = 33;
        });

        color_34.toggled.connect (() => {
            color_selected = 34;
        });

        color_35.toggled.connect (() => {
            color_selected = 35;
        });

        color_36.toggled.connect (() => {
            color_selected = 36;
        });

        color_37.toggled.connect (() => {
            color_selected = 37;
        });

        color_38.toggled.connect (() => {
            color_selected = 38;
        });

        color_39.toggled.connect (() => {
            color_selected = 39;
        });

        color_40.toggled.connect (() => {
            color_selected = 40;
        });

        color_41.toggled.connect (() => {
            color_selected = 41;
        });

        color_42.toggled.connect (() => {
            color_selected = 42;
        });

        color_43.toggled.connect (() => {
            color_selected = 43;
        });

        color_44.toggled.connect (() => {
            color_selected = 44;
        });

        color_45.toggled.connect (() => {
            color_selected = 45;
        });

        color_46.toggled.connect (() => {
            color_selected = 46;
        });

        color_47.toggled.connect (() => {
            color_selected = 47;
        });

        color_48.toggled.connect (() => {
            color_selected = 48;
        });

        color_49.toggled.connect (() => {
            color_selected = 49;
        });

        response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.APPLY) {
                save_and_exit ();
            } else {
                destroy ();
            }
        });

        Planner.todoist.project_updated_started.connect ((id) => {
            if (project.id == id) {
                loading_revealer.reveal_child = true;
            }
        });

        Planner.todoist.project_updated_completed.connect ((id) => {
            if (project.id == id) {
                destroy ();
            }
        });

        Planner.todoist.project_updated_error.connect ((id, error_code, error_message) => {
            if (project.id == id) {
                print ("Error: %s\n".printf (error_message));
            }
        });
    }

    private void save_and_exit () {
        if (name_entry.text != "") {
            project.name = name_entry.text;
            project.color = color_selected;

            project.save ();

            destroy ();
        }
    }
}
