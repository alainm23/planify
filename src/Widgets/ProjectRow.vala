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
    private Gtk.ToggleButton color_button;
    private Gtk.ToggleButton menu_button;
    private Gtk.Grid grid_color;
    private Gtk.Label name_label;
    private Gtk.Entry name_entry;
    private Gtk.Label archived_label;
    private Gtk.Image is_favorite_image;

    private Gtk.Box main_box;

    public Objects.Project project { get; construct; }
    
    public const string COLOR_CSS = """
        .project-%i {
            background-color: %s;
            border-radius: 50px;
            box-shadow: inset 0px 0px 0px 1px rgba(0, 0, 0, 0.2);
        }
    """;
    public bool menu_open = false;
    public signal void project_updated (Objects.Project project);
    public ProjectRow (Objects.Project _project) {
        Object (
            project: _project,
            margin_left: 0,
            margin_top: 3,
            margin_right: 0
        );
    }

    construct {
        tooltip_text = project.name;
        get_style_context ().add_class ("item-row");

        color_button = new Gtk.ToggleButton ();
        color_button.width_request = 16;
        color_button.height_request = 16;
        color_button.can_focus = false;
        color_button.valign = Gtk.Align.CENTER;
        color_button.halign = Gtk.Align.CENTER;
        color_button.get_style_context ().add_class ("button-circular");
        color_button.tooltip_text = _("Select an Icon and Color");
        color_button.get_style_context ().add_class ("project-%i".printf ((int32) project.id));
        color_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        color_button.no_show_all = true;

        var icon_picker = new Widgets.Popovers.ColorPicker (color_button);

        grid_color = new Gtk.Grid ();
		grid_color.get_style_context ().add_class ("project-%i".printf ((int32) project.id));
        grid_color.set_size_request (14, 14);
        grid_color.valign = Gtk.Align.CENTER;
        grid_color.halign = Gtk.Align.CENTER;
        
        name_label = new Gtk.Label ("<b>" + project.name + "</b>");
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        name_label.use_markup = true;

        name_entry = new Gtk.Entry ();
        name_entry.valign = Gtk.Align.CENTER;
        name_entry.expand = true;
        name_entry.max_length = 50;
        name_entry.text = project.name;
        name_entry.no_show_all = true;
        name_entry.placeholder_text = _("Project name");
        name_entry.no_show_all = true;

        is_favorite_image = new Gtk.Image ();
        is_favorite_image.gicon = new ThemedIcon ("emblem-favorite-symbolic");
        is_favorite_image.pixel_size = 16;
        is_favorite_image.margin_start = 6;

        if (project.is_favorite == 0) {
            is_favorite_image.no_show_all = true;
            is_favorite_image.visible = false;
        }

        archived_label = new Gtk.Label ("<small>%s</small>".printf (_("archived")));
        archived_label.use_markup = true;
        archived_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        if (project.is_archived == 0) {
            archived_label.no_show_all = true;
            archived_label.visible = false;
        }

        var menu_icon = new Gtk.Image ();
        menu_icon.pixel_size = 16;

        if (project.is_todoist) {
            menu_icon.icon_name = "planner-todoist";
        } else {
            menu_icon.icon_name = "computer-symbolic";
        }

        menu_button = new Gtk.ToggleButton ();
        menu_button.margin_start = 6;
        menu_button.valign = Gtk.Align.CENTER;
        menu_button.can_focus = false;
        menu_button.add (menu_icon);
        menu_button.tooltip_text = _("Menu");
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        menu_button.get_style_context ().add_class ("menu-button");
        menu_button.get_style_context ().remove_class ("button");

        var menu_popover = new Widgets.Popovers.MenuProject (menu_button);

        main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.margin = 6;

        main_box.pack_start (grid_color, false, false, 0);
        main_box.pack_start (color_button, false, false, 0);
        main_box.pack_start (name_label, false, false, 12);
        main_box.pack_start (name_entry, false, true, 12);
        main_box.pack_end (menu_button, false, false, 1);
        main_box.pack_end (is_favorite_image, false, false, 0);
        
        var eventbox = new Gtk.EventBox ();
        eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        eventbox.add (main_box);

        add (eventbox);
        apply_styles (Application.utils.get_color (project.color));

        eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                color_button.visible = true;
                name_entry.visible = true;

                grid_color.visible = false;
                name_label.visible = false;
                menu_button.visible = false;
                is_favorite_image.visible = false;
    
                if (project.is_archived == 1) {
                    archived_label.visible = false;
                }

                if (project.is_favorite == 1) {
                    is_favorite_image.visible = false;
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

        eventbox.enter_notify_event.connect ((event) => {
            if (menu_open != true) {
                menu_icon.icon_name = "view-more-horizontal-symbolic";
            }

            return false;
        });

        eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            if (menu_open != true) {
                if (project.is_todoist) {
                    menu_icon.icon_name = "planner-todoist";
                } else {
                    menu_icon.icon_name = "computer-symbolic";
                }
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
                is_favorite_image.visible = false;
    
                if (project.is_archived == 1) {
                    archived_label.visible = false;
                }

                if (project.is_favorite == 1) {
                    is_favorite_image.visible = false;
                }
                
                Timeout.add (200, () => {
				    name_entry.grab_focus ();
				    return false;
			    });
            } else if (type == "favorite") {
                /*
                if (project.is_favorite == 0) {
                    project.is_favorite = 1;

                    is_favorite_image.no_show_all = false;
                    is_favorite_image.visible = true;
                } else {
                    project.is_favorite = 0;

                    is_favorite_image.no_show_all = true;
                    is_favorite_image.visible = false;
                }

                if (Application.database.update_project (project) == Sqlite.DONE) {
                    project_updated (project);
                }
                */
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
                */
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
                */
            } else if (type == "share") {
                /*
                // Share project
                var share_dialog = new Dialogs.ShareDialog (Application.instance.main_window);
                share_dialog.project = project.id;
                share_dialog.destroy.connect (Gtk.main_quit);
                share_dialog.show_all ();
                */
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
                        if (Application.database_v2.delete_project (project.id)) {
                            GLib.Timeout.add (250, () => {
                                destroy ();
                                return GLib.Source.REMOVE;
                            });
                        }
                    }
                    /*
                    if (Application.database.remove_project (project.id) == Sqlite.DONE) {
                        Application.database.on_signal_remove_project (project);

                        GLib.Timeout.add (250, () => {
                            destroy ();
                            return GLib.Source.REMOVE;
                        });
                    }
                    */
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
                */
            }
        });

        Application.todoist.project_updated.connect ((_project) => {
            if (_project.id == project.id) {
                main_box.sensitive = true;

                name_label.label = "<b>%s</b>".printf(_project.name);
                tooltip_text = _project.name;
                 
                name_label.visible = true;
                grid_color.visible =true;
                menu_button.visible = true;

                name_entry.visible = false;
                color_button.visible = false;
    
                if (_project.is_archived == 1) {
                    archived_label.visible = true;
                }
    
                if (_project.is_favorite == 1) {
                    is_favorite_image.visible = true;
                }
    
                project_updated (_project);
            }
        });

        Application.todoist.project_deleted.connect ((project_id) => {
            if (project_id == project.id) {
                GLib.Timeout.add (250, () => {
                    destroy ();
                    return GLib.Source.REMOVE;
                });
            }
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

    private void update_project () {
        if (name_entry.text != "") {
            project.name = name_entry.text;

            if (project.is_todoist) {
                main_box.sensitive = false;
                Application.todoist.update_project (project);
            } else {
                if (Application.database_v2.update_project (project)) {
                    name_label.label = "<b>%s</b>".printf(project.name);
                    tooltip_text = project.name;
                    
                    name_label.visible = true;
                    grid_color.visible =true;
                    menu_button.visible = true;

                    name_entry.visible = false;
                    color_button.visible = false;
    
                    if (project.is_archived == 1) {
                        archived_label.visible = true;
                    }
    
                    if (project.is_favorite == 1) {
                        is_favorite_image.visible = true;
                    }
    
                    project_updated (project);
                }
            }
        }
    }
}