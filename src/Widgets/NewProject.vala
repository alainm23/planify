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

public class Widgets.NewProject : Gtk.Revealer {
    private Gtk.Entry name_entry;
    private Gtk.ComboBox source_combobox;
    private int color_selected = 30;

    public signal void reveal_activated (bool value);

    public bool reveal {
        set {
            reveal_child = value;

            if (value) {
                name_entry.grab_focus ();
            }

            reveal_activated (value);
        }
        get {
            return reveal_child;
        }
    }

    public NewProject () {
        transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        reveal_child = false;
        valign = Gtk.Align.END;
        halign = Gtk.Align.CENTER;
    }

    construct {
        var name_label = new Granite.HeaderLabel (_("Name:"));
        
        name_entry = new Gtk.Entry ();

        var source_label = new Granite.HeaderLabel (_("Source:"));

        var list_store = new Gtk.ListStore (3, typeof (int), typeof (unowned string), typeof (string));
        source_combobox = new Gtk.ComboBox.with_model (list_store);

        var error_icon = new Gtk.Image ();
        error_icon.gicon = new ThemedIcon ("dialog-error-symbolic");
        error_icon.pixel_size = 14;

        var error_label = new Gtk.Label (null);
        error_label.halign = Gtk.Align.START;
        error_label.get_style_context ().add_class ("error_label");

        var error_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        error_box.margin_top = 12;
        error_box.pack_start (error_icon, false, false, 0);
        error_box.pack_start (error_label, false, false, 3);

        var error_revealer = new Gtk.Revealer ();
        error_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        error_revealer.add (error_box);
        error_revealer.reveal_child = false;

        string local_text = " " + _("Local");        
        Gtk.TreeIter local_iter;
        list_store.append (out local_iter);
        list_store.@set (local_iter, 0, 0, 1, local_text, 2, "go-home");

        var pixbuf_cell = new Gtk.CellRendererPixbuf ();
        source_combobox.pack_start (pixbuf_cell, false);
        source_combobox.add_attribute (pixbuf_cell, "icon-name", 2);

        var text_cell = new Gtk.CellRendererText ();
        source_combobox.pack_start (text_cell, true);
        source_combobox.add_attribute (text_cell, "text", 1);

        source_combobox.set_active_iter (local_iter);

        var source_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        source_box.pack_start (source_label, false, false, 0);
        source_box.pack_start (source_combobox, false, false, 0);

        var source_revealer = new Gtk.Revealer ();
        source_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        source_revealer.add (source_box);

        if (Application.settings.get_boolean ("todoist-account")) {
            source_revealer.reveal_child = true;

            string email_text = " " + Application.settings.get_string ("todoist-user-email");
            Gtk.TreeIter todoist_iter;
            list_store.append (out todoist_iter);
            list_store.@set (todoist_iter, 0, 1, 1, email_text, 2, "preferences-desktop-online-accounts");
        }

        var color_label = new Granite.HeaderLabel (_("Color:"));

        var color_30 = new Gtk.RadioButton (null);
        color_30.valign = Gtk.Align.START;
        color_30.halign = Gtk.Align.START;
        Application.utils.apply_styles ("30", "#b8255f", color_30);

        var color_31 = new Gtk.RadioButton.from_widget (color_30);
        color_31.valign = Gtk.Align.START;
        color_31.halign = Gtk.Align.START;
        Application.utils.apply_styles ("31", "#db4035", color_31);

        var color_32 = new Gtk.RadioButton.from_widget (color_30);
        color_32.valign = Gtk.Align.START;
        color_32.halign = Gtk.Align.START;
        Application.utils.apply_styles ("32", "#ff9933", color_32);

        var color_33 = new Gtk.RadioButton.from_widget (color_30);
        color_33.valign = Gtk.Align.START;
        color_33.halign = Gtk.Align.START;
        Application.utils.apply_styles ("33", "#fad000", color_33);

        var color_34 = new Gtk.RadioButton.from_widget (color_30);
        color_34.valign = Gtk.Align.START;
        color_34.halign = Gtk.Align.START;
        Application.utils.apply_styles ("34", "#afb83b", color_34);

        var color_35 = new Gtk.RadioButton.from_widget (color_30);
        color_35.valign = Gtk.Align.START;
        color_35.halign = Gtk.Align.START;
        Application.utils.apply_styles ("35", "#7ecc49", color_35);

        var color_36 = new Gtk.RadioButton.from_widget (color_30);
        color_36.valign = Gtk.Align.START;
        color_36.halign = Gtk.Align.START;
        Application.utils.apply_styles ("36", "#299438", color_36);

        var color_37 = new Gtk.RadioButton.from_widget (color_30);
        color_37.valign = Gtk.Align.START;
        color_37.halign = Gtk.Align.START;
        Application.utils.apply_styles ("37", "#6accbc", color_37);

        var color_38 = new Gtk.RadioButton.from_widget (color_30);
        color_38.valign = Gtk.Align.START;
        color_38.halign = Gtk.Align.START;
        Application.utils.apply_styles ("38", "#158fad", color_38);

        var color_39 = new Gtk.RadioButton.from_widget (color_30);
        color_39.valign = Gtk.Align.START;
        color_39.halign = Gtk.Align.START;
        Application.utils.apply_styles ("39", "#14aaf5", color_39);

        var color_40 = new Gtk.RadioButton.from_widget (color_30);
        color_40.valign = Gtk.Align.START;
        color_40.halign = Gtk.Align.START;
        Application.utils.apply_styles ("40", "#96c3eb", color_40);

        var color_41 = new Gtk.RadioButton.from_widget (color_30);
        color_41.valign = Gtk.Align.START;
        color_41.halign = Gtk.Align.START;
        Application.utils.apply_styles ("41", "#4073ff", color_41);

        var color_42 = new Gtk.RadioButton.from_widget (color_30);
        color_42.valign = Gtk.Align.START;
        color_42.halign = Gtk.Align.START;
        Application.utils.apply_styles ("42", "#884dff", color_42);

        var color_43 = new Gtk.RadioButton.from_widget (color_30);
        color_43.valign = Gtk.Align.START;
        color_43.halign = Gtk.Align.START;
        Application.utils.apply_styles ("43", "#af38eb", color_43);

        var color_44 = new Gtk.RadioButton.from_widget (color_30);
        color_44.valign = Gtk.Align.START;
        color_44.halign = Gtk.Align.START;
        Application.utils.apply_styles ("44", "#eb96eb", color_44);

        var color_45 = new Gtk.RadioButton.from_widget (color_30);
        color_45.valign = Gtk.Align.START;
        color_45.halign = Gtk.Align.START;
        Application.utils.apply_styles ("45", "#e05194", color_45);
        
        var color_46 = new Gtk.RadioButton.from_widget (color_30);
        color_46.valign = Gtk.Align.START;
        color_46.halign = Gtk.Align.START;
        Application.utils.apply_styles ("46", "#ff8d85", color_46);

        var color_47 = new Gtk.RadioButton.from_widget (color_30);
        color_47.valign = Gtk.Align.START;
        color_47.halign = Gtk.Align.START;
        Application.utils.apply_styles ("47", "#808080", color_47);

        var color_48 = new Gtk.RadioButton.from_widget (color_30);
        color_48.valign = Gtk.Align.START;
        color_48.halign = Gtk.Align.START;
        Application.utils.apply_styles ("48", "#b8b8b8", color_48);

        var color_49 = new Gtk.RadioButton.from_widget (color_30);
        color_49.valign = Gtk.Align.START;
        color_49.halign = Gtk.Align.START;
        Application.utils.apply_styles ("49", "#ccac93", color_49);

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

        var submit_button = new Gtk.Button ();
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var submit_spinner = new Gtk.Spinner ();
        submit_spinner.start ();

        var submit_stack = new Gtk.Stack ();
        submit_stack.expand = true;
        submit_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        
        submit_stack.add_named (new Gtk.Label (_("Create")), "label");
        submit_stack.add_named (submit_spinner, "spinner");

        submit_button.add (submit_stack);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));

        var action_grid = new Gtk.Grid ();
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 9;
        action_grid.margin_top = 12;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.expand = true;
        box.margin = 9;
        box.margin_top = 0;
        box.pack_start (name_label, false, false, 0);
        box.pack_start (name_entry, false, false, 0);
        box.pack_start (source_revealer, false, false, 0);
        box.pack_start (color_label, false, false, 0);
        box.pack_start (color_box, false, false, 0);
        box.pack_start (error_revealer, false, false, 0);
        box.pack_end (action_grid, false, false, 0);
        
        var main_grid = new Gtk.Grid ();
        main_grid.expand = false;
        main_grid.get_style_context ().add_class ("add-project-widget");
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (box);

        add (main_grid); 
        
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

        submit_button.clicked.connect (() => {
            create_project ();
        });

        name_entry.activate.connect (() => {
            create_project ();
        });

        name_entry.changed.connect (() => {
            if (name_entry.text != "") {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }
        });

        cancel_button.clicked.connect (() => {
            reveal = false;
            name_entry.text = "";
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                reveal = false;
                name_entry.text = "";
            }

            return false;
        });

        Application.todoist.project_added_started.connect (() => {
            submit_button.sensitive = false;
            submit_stack.visible_child_name = "spinner";
        }); 

        Application.todoist.project_added_completed.connect (() => {
            submit_button.sensitive = true;
            submit_stack.visible_child_name = "label";

            reveal = false;
            name_entry.text = "";
        });

        Application.todoist.project_added_error.connect ((error_code, error_message) => {
            submit_button.sensitive = true;
            submit_stack.visible_child_name = "label";

            error_label.label = error_message;
            error_revealer.reveal_child = true;

            Timeout.add (2500, () => {
                error_revealer.reveal_child = false;
                return false;
            });
        });

        Application.todoist.first_sync_finished.connect (() => {
            string email_text = " " + Application.settings.get_string ("todoist-user-email");
            Gtk.TreeIter todoist_iter;
            list_store.append (out todoist_iter);
            list_store.@set (todoist_iter, 0, 1, 1, email_text, 2, "preferences-desktop-online-accounts");

            source_revealer.reveal_child = Application.settings.get_boolean ("todoist-account");
        });
    } 

    public void create_project () {
        if (name_entry.text != "") {
            var project = new Objects.Project ();
            project.name = name_entry.text;
            project.color = color_selected;

            if (source_combobox.active == 0) {
                project.id = Application.utils.generate_id ();
                
                if (Application.database.insert_project (project)) {
                    reveal = false;
                    name_entry.text = "";
                }
            } else {
                Application.todoist.add_project (project);
            }
        }
    }
}