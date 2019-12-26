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

public class Widgets.New : Gtk.Revealer {
    private Gtk.Entry name_entry;
    private Gtk.Button project_button;
    private Gtk.Button area_button;

    private Gtk.Stack stack;

    private Gtk.ComboBox source_combobox;   
    private int color_selected = 30;
    
    private uint timeout_id = 0;

    public New () {
        transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        reveal_child = false;
        valign = Gtk.Align.END;
        halign = Gtk.Align.CENTER;
    }

    construct {
        var name_label = new Granite.HeaderLabel (_("Name:"));
        
        name_entry = new Gtk.Entry ();

        var source_label = new Granite.HeaderLabel (_("Source:"));

        var list_store = new Gtk.ListStore (3, typeof (int64), typeof (unowned string), typeof (string));
        source_combobox = new Gtk.ComboBox.with_model (list_store);
        
        string local_text = " " + _("On this computer"); 	
        Gtk.TreeIter local_iter;	
        list_store.append (out local_iter);
        list_store.@set (local_iter, 0, 0, 1, local_text, 2, "planner-offline-symbolic");

        source_combobox.set_active_iter (local_iter);

        var pixbuf_cell = new Gtk.CellRendererPixbuf ();
        source_combobox.pack_start (pixbuf_cell, false);
        source_combobox.add_attribute (pixbuf_cell, "icon-name", 2);

        var text_cell = new Gtk.CellRendererText ();
        source_combobox.pack_start (text_cell, true);
        source_combobox.add_attribute (text_cell, "text", 1);

        var source_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        source_box.pack_start (source_label, false, false, 0);
        source_box.pack_start (source_combobox, false, false, 0);

        var source_revealer = new Gtk.Revealer ();
        source_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        source_revealer.add (source_box);
        source_revealer.reveal_child = true;

        if (Planner.settings.get_boolean ("todoist-account")) {
            source_revealer.reveal_child = true;

            string email_text = " " + Planner.settings.get_string ("todoist-user-email");
            Gtk.TreeIter todoist_iter;
            list_store.append (out todoist_iter);
            list_store.@set (todoist_iter, 0, 1, 1, email_text, 2, "planner-online-symbolic");

            if (Planner.settings.get_int ("source-selected") == 1) {
                source_combobox.set_active_iter (todoist_iter);
            }
        }

        var color_label = new Granite.HeaderLabel (_("Color:"));

        var color_30 = new Gtk.RadioButton (null);
        color_30.valign = Gtk.Align.START;
        color_30.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("30", Planner.utils.get_color (30), color_30);

        var color_31 = new Gtk.RadioButton.from_widget (color_30);
        color_31.valign = Gtk.Align.START;
        color_31.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("31", Planner.utils.get_color (31), color_31);

        var color_32 = new Gtk.RadioButton.from_widget (color_30);
        color_32.valign = Gtk.Align.START;
        color_32.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("32", Planner.utils.get_color (32), color_32);

        var color_33 = new Gtk.RadioButton.from_widget (color_30);
        color_33.valign = Gtk.Align.START;
        color_33.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("33", Planner.utils.get_color (33), color_33);

        var color_34 = new Gtk.RadioButton.from_widget (color_30);
        color_34.valign = Gtk.Align.START;
        color_34.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("34", Planner.utils.get_color (34), color_34);

        var color_35 = new Gtk.RadioButton.from_widget (color_30);
        color_35.valign = Gtk.Align.START;
        color_35.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("35", Planner.utils.get_color (35), color_35);

        var color_36 = new Gtk.RadioButton.from_widget (color_30);
        color_36.valign = Gtk.Align.START;
        color_36.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("36", Planner.utils.get_color (36), color_36);

        var color_37 = new Gtk.RadioButton.from_widget (color_30);
        color_37.valign = Gtk.Align.START;
        color_37.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("37", Planner.utils.get_color (37), color_37);

        var color_38 = new Gtk.RadioButton.from_widget (color_30);
        color_38.valign = Gtk.Align.START;
        color_38.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("38", Planner.utils.get_color (38), color_38);

        var color_39 = new Gtk.RadioButton.from_widget (color_30);
        color_39.valign = Gtk.Align.START;
        color_39.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("39", Planner.utils.get_color (39), color_39);

        var color_40 = new Gtk.RadioButton.from_widget (color_30);
        color_40.valign = Gtk.Align.START;
        color_40.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("40", Planner.utils.get_color (40), color_40);

        var color_41 = new Gtk.RadioButton.from_widget (color_30);
        color_41.valign = Gtk.Align.START;
        color_41.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("41", Planner.utils.get_color (41), color_41);

        var color_42 = new Gtk.RadioButton.from_widget (color_30);
        color_42.valign = Gtk.Align.START;
        color_42.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("42", Planner.utils.get_color (42), color_42);

        var color_43 = new Gtk.RadioButton.from_widget (color_30);
        color_43.valign = Gtk.Align.START;
        color_43.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("43", Planner.utils.get_color (43), color_43);

        var color_44 = new Gtk.RadioButton.from_widget (color_30);
        color_44.valign = Gtk.Align.START;
        color_44.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("44", Planner.utils.get_color (44), color_44);

        var color_45 = new Gtk.RadioButton.from_widget (color_30);
        color_45.valign = Gtk.Align.START;
        color_45.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("45", Planner.utils.get_color (45), color_45);
        
        var color_46 = new Gtk.RadioButton.from_widget (color_30);
        color_46.valign = Gtk.Align.START;
        color_46.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("46", Planner.utils.get_color (46), color_46);

        var color_47 = new Gtk.RadioButton.from_widget (color_30);
        color_47.valign = Gtk.Align.START;
        color_47.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("47", Planner.utils.get_color (47), color_47);

        var color_48 = new Gtk.RadioButton.from_widget (color_30);
        color_48.valign = Gtk.Align.START;
        color_48.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("48", Planner.utils.get_color (48), color_48);

        var color_49 = new Gtk.RadioButton.from_widget (color_30);
        color_49.valign = Gtk.Align.START;
        color_49.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("49", Planner.utils.get_color (49), color_49);

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
        
        stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        stack.add_named (create_chooser_widget (), "chooser");
        stack.add_named (box, "box");

        var main_grid = new Gtk.Grid ();
        main_grid.expand = false; 
        main_grid.get_style_context ().add_class ("add-project-widget");
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (stack);

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

        source_combobox.changed.connect (() => {
            Planner.settings.set_int ("source-selected", source_combobox.active);
        });

        cancel_button.clicked.connect (cancel);

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                cancel ();
            }

            return false;
        });

        Planner.todoist.project_added_started.connect (() => {
            submit_button.sensitive = false;
            submit_stack.visible_child_name = "spinner";
        }); 

        Planner.todoist.project_added_completed.connect (() => {
            submit_button.sensitive = true;
            submit_stack.visible_child_name = "label";

            cancel ();
        });

        Planner.todoist.project_added_error.connect ((error_code, error_message) => {
            submit_button.sensitive = true;
            submit_stack.visible_child_name = "label";

            error_label.label = error_message;
            error_revealer.reveal_child = true;

            timeout_id = Timeout.add (2500, () => {
                error_revealer.reveal_child = false;

                Source.remove (timeout_id);
                
                return false;
            });
        });

        Planner.todoist.first_sync_finished.connect (() => {
            string email_text = " " + Planner.settings.get_string ("todoist-user-email");
            Gtk.TreeIter todoist_iter;
            list_store.append (out todoist_iter);
            list_store.@set (todoist_iter, 0, 1, 1, email_text, 2, "planner-online-symbolic");

            source_revealer.reveal_child = Planner.settings.get_boolean ("todoist-account");
        });
    } 

    private Gtk.Box create_chooser_widget () {
        var project_image = new Gtk.Image ();
        project_image.halign = Gtk.Align.START;
        project_image.valign = Gtk.Align.CENTER;
        project_image.gicon = new ThemedIcon ("planner-project-symbolic");
        project_image.pixel_size = 14;
        project_image.get_style_context ().add_class ("project-icon");

        var project_label = new Gtk.Label (_("Project"));
        project_label.get_style_context ().add_class ("welcome");
        project_label.get_style_context ().add_class ("h3");
        project_label.get_style_context ().add_class ("font-bold");
        project_label.halign = Gtk.Align.START;

        var project_detail_label = new Gtk.Label (_("Start a new project, create a to do list, organize your notes."));
        project_detail_label.wrap = true;
        project_detail_label.justify = Gtk.Justification.FILL;

        var project_grid = new Gtk.Grid ();
        project_grid.margin_start = 6;
        project_grid.column_spacing = 3;
        project_grid.attach (project_image, 0, 0, 1, 1);
        project_grid.attach (project_label, 1, 0, 1, 1);
        project_grid.attach (project_detail_label, 1, 1, 1, 1);

        project_button = new Gtk.Button ();
        project_button.margin_top = 6;
        project_button.add (project_grid);
        project_button.get_style_context ().remove_class ("button");
        project_button.get_style_context ().add_class ("flat");
        project_button.get_style_context ().add_class ("menuitem");

        var area_image = new Gtk.Image ();
        area_image.halign = Gtk.Align.START;
        area_image.valign = Gtk.Align.CENTER;
        area_image.gicon = new ThemedIcon ("planner-work-area-symbolic");
        area_image.pixel_size = 14;
        area_image.get_style_context ().add_class ("area-icon");

        var source_label = new Gtk.Label (_("Area"));
        source_label.get_style_context ().add_class ("h3");
        source_label.get_style_context ().add_class ("welcome");
        source_label.get_style_context ().add_class ("font-bold");
        source_label.halign = Gtk.Align.START;

        var area_detail_label = new Gtk.Label (_("Organize your projects in groups and keep your panel clean."));
        area_detail_label.wrap = true;
        area_detail_label.justify = Gtk.Justification.FILL;

        var area_grid = new Gtk.Grid ();
        area_grid.margin_start = 6;
        area_grid.column_spacing = 3;
        area_grid.attach (area_image, 0, 0, 1, 1);
        area_grid.attach (source_label, 1, 0, 1, 1);
        area_grid.attach (area_detail_label, 1, 1, 1, 1);

        area_button = new Gtk.Button ();
        area_button.add (area_grid);
        area_button.get_style_context ().remove_class ("button");
        area_button.get_style_context ().add_class ("flat");
        area_button.get_style_context ().add_class ("menuitem");

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.margin = 6;

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.add (project_button);
        box.pack_start (project_button, false, false, 0);
        box.pack_start (area_button, false, false, 0);
        box.pack_end (cancel_button, false, false, 0);

        cancel_button.clicked.connect (cancel);

        project_button.clicked.connect (() => {
            stack.visible_child_name = "box";
            name_entry.grab_focus ();
        });

        area_button.clicked.connect (create_area);

        return box;
    }

    private void cancel () {
        reveal_child = false;
        name_entry.text = "";
        stack.visible_child_name = "chooser";
    }

    private void create_project () {
        if (name_entry.text != "") {
            var project = new Objects.Project ();
            project.name = name_entry.text;
            project.color = color_selected;

            if (source_combobox.active == 0) {
                project.id = Planner.utils.generate_id ();
                if (Planner.database.insert_project (project)) {
                    cancel ();
                }
            } else { 
                project.is_todoist = 1;
                Planner.todoist.add_project (project);
                /*
                if (Planner.utils.check_connection ()) {
                    
                } else {
                    
                }
                */
            }
        }
    }

    private void create_area () {
        var area = new Objects.Area ();
        area.name = _("New area");
        
        if (Planner.database.insert_area (area)) {
            cancel ();
        }
    }
}