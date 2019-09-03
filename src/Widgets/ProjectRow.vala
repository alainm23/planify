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

public class Widgets.ProjectRow : Gtk.ListBoxRow { 
    public Objects.Project project { get; construct; }

    private Gtk.Grid grid_color;
    private Gtk.Label name_label;
    private Gtk.Label count_label;

    public const string COLOR_CSS = """
        .project-%i {
            background-color: %s;
            border-radius: 50%;
            box-shadow:
                inset 0 1px 0 0 alpha (@inset_dark_color, 0.7),
                inset 0 0 0 1px alpha (@inset_dark_color, 0.3),
                0 1px 0 0 alpha (@bg_highlight_color, 0.3);
        }
    """;

    public ProjectRow (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        tooltip_text = project.name;
        get_style_context ().add_class ("project-row");

        grid_color = new Gtk.Grid ();
		grid_color.get_style_context ().add_class ("project-%i".printf ((int32) project.id));
        grid_color.set_size_request (13, 13);
        grid_color.valign = Gtk.Align.CENTER;
        grid_color.halign = Gtk.Align.CENTER;

        name_label = new Gtk.Label (project.name);
        name_label.get_style_context ().add_class ("pane-item");
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        name_label.use_markup = true;

        count_label = new Gtk.Label ("4");
        count_label.get_style_context ().add_class ("dim-label");
        count_label.valign = Gtk.Align.CENTER;
        count_label.halign = Gtk.Align.CENTER;

        var menu_button = new Gtk.Button.from_icon_name ("view-more-horizontal-symbolic", Gtk.IconSize.MENU);
        menu_button.valign = Gtk.Align.CENTER;
        menu_button.can_focus = false;
        menu_button.tooltip_text = _("Menu");
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var right_stack = new Gtk.Stack ();
        right_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        right_stack.add_named (count_label, "count");
        right_stack.add_named (menu_button, "menu");
        
        var source_icon = new Gtk.Image ();
        source_icon.get_style_context ().add_class ("dim-label");
        source_icon.pixel_size = 16;

        if (project.is_todoist == 0) {
            source_icon.icon_name = "network-offline-symbolic";
        } else {
            source_icon.icon_name = "planner-online-symbolic";
        }

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.margin = 3;
        main_box.margin_end = 0;
        main_box.margin_start = 8;
        main_box.pack_start (grid_color, false, false, 0);
        main_box.pack_start (name_label, false, false, 7);
        main_box.pack_end (right_stack, false, false, 3);
        //main_box.pack_end (source_icon, false, false, 0);
        
        var eventbox = new Gtk.EventBox ();
        eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        eventbox.add (main_box);

        add (eventbox);
        apply_styles (Application.utils.get_color (project.color));

        /*
        eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                color_button.visible = true;
                name_entry.visible = true;

                grid_color.visible = false;
                name_label.visible = false;
                menu_button.visible = false;
    
                if (project.is_archived == 1) {
                    archived_label.visible = false;
                }
                
                Timeout.add (200, () => {
				    name_entry.grab_focus ();
				    return false;
			    });
            }

            return false;
        });

        color_button.toggled.connect (() => {
            if (color_button.active) {
                icon_picker.show_all ();
            }
        });
  
        icon_picker.closed.connect (() => {
            color_button.active = false;
        });

        icon_picker.color_selected.connect ((color) => {
            project.color = color;
            apply_styles (Application.utils.get_color (color));
        });

        name_entry.activate.connect (() =>{
            update_project ();
        });

        name_entry.focus_out_event.connect (() => {
            if (color_button.active == false) {
                update_project ();
            }
            
            return false;
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                update_project ();
            }

            return false;
        });

        

        menu_button.toggled.connect (() => {
            if (menu_button.active) {
                menu_open = true;
                menu_popover.show_all ();
            }
        });
        
        menu_popover.closed.connect (() => {
            menu_open = false;
            menu_button.active = false;
        });

        menu_popover.on_selected_menu.connect ((type) => {
            if (type == "edit") {
                color_button.visible = true;
                name_entry.visible = true;

                grid_color.visible = false;
                name_label.visible = false;
                menu_button.visible = false;
    
                if (project.is_archived == 1) {
                    archived_label.visible = false;
                }
                
                Timeout.add (200, () => {
				    name_entry.grab_focus ();
				    return false;
			    });
            } else if (type == "favorite") {
                if (project.is_favorite == 1) {
                    project.is_favorite = 0;
                } else {
                    project.is_favorite = 1;
                }

                if (Application.database.update_project (project)) {
                    project_updated (project);
                }
            } else if (type == "archived") {
                /*
                var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                    "This is a primary text",
                    "This is a secondary, multiline, long text. This text usually extends the primary text and prints e.g: the details of an error.",
                    "applications-development",
                    Gtk.ButtonsType.CLOSE
                );

                var archived_button = new Gtk.Button.with_label (_("Archived project"));
                archived_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                message_dialog.add_action_widget (archived_button, Gtk.ResponseType.ACCEPT);

                message_dialog.show_all ();

                if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                    if (project.is_archived == 0) {
                        project.is_archived = 1;
    
                        archived_label.no_show_all = false;
                        archived_label.visible = true;
                    } else {
                        project.is_archived = 0;
    
                        archived_label.no_show_all = true;
                        archived_label.visible = false;
                    }

                    if (Application.database.update_project (project) == Sqlite.DONE) {
                        project_updated (project);
                    }  
                }

                message_dialog.destroy ();
            } else if (type == "finalize") {
                /*
                int tasks_number = Application.database.get_project_no_completed_tasks_number (project.id);

                var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                    _("Are you sure you want to mark as completed this project?"),
                    _("This project contains %i incomplete tasks".printf (tasks_number)),
                    "dialog-warning",
                Gtk.ButtonsType.CANCEL);

                var remove_button = new Gtk.Button.with_label (_("Mark as Completed"));
                remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

                message_dialog.show_all ();

                if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                    var all_tasks = new Gee.ArrayList<Objects.Task?> ();
                    all_tasks = Application.database.get_all_tasks_by_project (project.id);

                    foreach (var task in all_tasks) {
                        task.checked = 1;
                        if (Application.database.update_task (task) == Sqlite.DONE) {
                            Application.database.update_task_signal (task);
                        }
                    }
                }

                message_dialog.destroy ();
            } else if (type == "share") {
                /*
                // Share project
                var share_dialog = new Dialogs.ShareDialog (Application.instance.main_window);
                share_dialog.project = project.id;
                share_dialog.destroy.connect (Gtk.main_quit);
                share_dialog.show_all ();
            } else if (type == "remove") {
                var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                    _("Are you sure you want to delete %s".printf (project.name)),
                    "",
                    "edit-delete",
                Gtk.ButtonsType.CANCEL);

                var remove_button = new Gtk.Button.with_label (_("Delete Project"));
                remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

                message_dialog.show_all ();

                if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                    if (project.is_todoist) {
                        main_box.sensitive = false;
                        Application.todoist.delete_project (project);
                    } else {
                        if (Application.database.delete_project (project.id)) {
                            GLib.Timeout.add (250, () => {
                                destroy ();
                                return GLib.Source.REMOVE;
                            });
                        }
                    }
                }

                message_dialog.destroy ();
            } else if (type == "export") {
                /*
                var chooser = new Gtk.FileChooserDialog (_("Export project"), null, Gtk.FileChooserAction.SAVE);
                chooser.add_button ("_Cancel", Gtk.ResponseType.CANCEL);
                chooser.add_button ("_Save", Gtk.ResponseType.ACCEPT);
                chooser.set_do_overwrite_confirmation (true);

                var filter = new Gtk.FileFilter ();
                filter.set_filter_name (_("Planner files"));
                filter.add_pattern ("*.planner");
                chooser.add_filter (filter);

                if (chooser.run () == Gtk.ResponseType.ACCEPT) {
                    var file = chooser.get_file ();

                    if (!file.get_basename ().down ().has_suffix (".planner")) {
                        Application.share.exort_project (project.id,file.get_path () + ".planner");
                    }
                }

                chooser.destroy();
            }
        });

        Application.database.project_updated.connect ((_project) => {
            if (_project.id == project.id) {
                name_label.label = "<b>%s</b>".printf(_project.name);
                name_entry.text = _project.name;
                tooltip_text = _project.name;

                apply_styles (Application.utils.get_color (_project.color));
            }
        });

        Application.database.project_deleted.connect ((project_id) => {
            if (project_id == project.id) {
                GLib.Timeout.add (250, () => {
                    destroy ();
                    return GLib.Source.REMOVE;
                });
            }
        });
        */
        eventbox.enter_notify_event.connect ((event) => {
            right_stack.visible_child_name = "menu";

            return false;
        });

        eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            right_stack.visible_child_name = "count";

            return false;
        });
    }

    private void apply_styles (string color) {
        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (
                (int32) project.id,
                color
            );

            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }

    /*
    private void update_project () {
        if (name_entry.text != "") {
            project.name = name_entry.text;

            if (Application.database.update_project (project)) {
                name_label.label = "<b>%s</b>".printf(project.name);
                tooltip_text = project.name;
                    
                name_label.visible = true;
                grid_color.visible =true;
                menu_button.visible = true;

                name_entry.visible = false;
                color_button.visible = false;
                
                if (project.is_todoist) {
                    Application.todoist.update_project (project);
                } else {
                    project_updated (project);
                }
            }
        }
    }
    */
}