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
    private Gtk.Image project_icon;
    private Gtk.Label project_name;
    private Gtk.Entry project_entry;
    private Gtk.Label archived_label;
    private Gtk.Image is_favorite_image;

    public Objects.Project project { get; construct; }
    
    public const string COLOR_CSS = """
        .project-%i {
            color: %s;
            background-color: #fff;
            padding: 3px;
            border: 1px solid shade (%s, 0.9);
            border-radius: 50px;
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

        project_icon = new Gtk.Image ();
        project_icon.valign = Gtk.Align.CENTER;
        project_icon.gicon = new ThemedIcon (project.icon);
        project_icon.pixel_size = 10;
        project_icon.get_style_context ().add_class ("project-%i".printf ((int32) project.id));

        project_name = new Gtk.Label ("<b>" + project.name + "</b>");
        project_name.valign = Gtk.Align.CENTER;
        project_name.ellipsize = Pango.EllipsizeMode.END;
        project_name.use_markup = true;

        project_entry = new Gtk.Entry ();
        project_entry.valign = Gtk.Align.CENTER;
        project_entry.expand = true;
        project_entry.max_length = 50;
        project_entry.text = project.name;
        project_entry.no_show_all = true;
        project_entry.get_style_context ().add_class ("entry-project");
        project_entry.placeholder_text = _("Project name");

        is_favorite_image = new Gtk.Image ();
        is_favorite_image.gicon = new ThemedIcon ("emblem-favorite");
        is_favorite_image.pixel_size = 16;

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
        menu_icon.gicon = new ThemedIcon ("view-more-symbolic");
        menu_icon.pixel_size = 13;

        var menu_button = new Gtk.ToggleButton ();
        menu_button.margin_start = 6;
        menu_button.valign = Gtk.Align.CENTER;
        menu_button.can_focus = false;
        menu_button.add (menu_icon);
        menu_button.tooltip_text = _("Menu");
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        menu_button.get_style_context ().add_class ("menu-button");

        var menu_revealer = new Gtk.Revealer ();
        menu_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        menu_revealer.valign = Gtk.Align.CENTER;
        menu_revealer.add (menu_button);
        menu_revealer.reveal_child = false;

        var menu_popover = new Widgets.Popovers.MenuProject (menu_button);

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.margin = 6;

        main_box.pack_start (project_icon, false, false, 0);
        main_box.pack_start (project_name, false, false, 9);
        main_box.pack_start (archived_label, false, false, 0);
        main_box.pack_start (project_entry, false, true, 9);
        main_box.pack_end (menu_revealer, false, false, 0);
        main_box.pack_end (is_favorite_image, false, false, 0);
        
        var eventbox = new Gtk.EventBox ();
        eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        eventbox.add (main_box);

        add (eventbox);
        apply_styles (project.color);

        eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                project_name.visible = false;
                project_entry.visible = true;

                if (project.is_archived == 1) {
                    archived_label.visible = false;
                }

                if (project.is_favorite == 1) {
                    is_favorite_image.visible = false;
                }
                
                Timeout.add (200, () => {
				    project_entry.grab_focus ();
				    return false;
			    });
            }

            return false;
        });

        project_entry.activate.connect (() =>{
            update_project ();
        });

        project_entry.focus_out_event.connect (() => {
            update_project ();
            return false;
        });

        project_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                update_project ();
            }

            return false;
        });

        eventbox.enter_notify_event.connect ((event) => {
            if (menu_open != true) {
                menu_revealer.reveal_child = true;
            }

            return false;
        });

        eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            if (menu_open != true) {
                menu_revealer.reveal_child = false;
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
            menu_revealer.reveal_child = false;
        });
        
        menu_popover.closed.connect (() => {
            menu_open = false;
            menu_button.active = false;
            menu_revealer.reveal_child = false;
        });

        menu_popover.on_selected_menu.connect ((type) => {
            if (type == "edit") {
                project_name.visible = false;
                project_entry.visible = true;

                Timeout.add (200, () => {
				    project_entry.grab_focus ();
				    return false;
			    });
            } else if (type == "favorite") {
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
            } else if (type == "archived") {
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
            }
            /*
            if (type == "finalize") {
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
            } else if (type == "edit") {
                name_label.visible = false;
                name_entry.visible = true;

                Timeout.add (200, () => {
				    name_entry.grab_focus ();
				    return false;
			    });
            } else if (type == "share") {
                // Share project
                var share_dialog = new Dialogs.ShareDialog (Application.instance.main_window);
                share_dialog.project = project.id;
                share_dialog.destroy.connect (Gtk.main_quit);
                share_dialog.show_all ();
            } else if (type == "remove") {
                int tasks_number = Application.database.get_project_tasks_number (project.id);
                // Algoritmo para saber si hay o no tareas y si es plural o singular

                var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                    _("Are you sure you want to delete this project?"),
                    _("It contains %i elements that are also deleted, this operation can't be undone".printf (tasks_number)),
                    "dialog-warning",
                Gtk.ButtonsType.CANCEL);

                var remove_button = new Gtk.Button.with_label (_("Delete Project"));
                remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

                message_dialog.show_all ();

                if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                    if (Application.database.remove_project (project.id) == Sqlite.DONE) {
                        Application.database.on_signal_remove_project (project);

                        GLib.Timeout.add (250, () => {
                            destroy ();
                            return GLib.Source.REMOVE;
                        });
                    }
                }

                message_dialog.destroy ();
            } else if (type == "export") {
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
            */
        });
    }

    private void apply_styles (string color) {
        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (
                (int32) project.id,
                color,
                color
            );

            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }

    private void update_project () {
        if (project_entry.text != "") {
            project.name = project_entry.text;

            if (Application.database.update_project (project) == Sqlite.DONE) {
                project_name.label = "<b>%s</b>".printf(project.name);
                tooltip_text = project.name;
                
                project_name.visible = true;
                project_entry.visible = false;

                if (project.is_archived == 1) {
                    archived_label.visible = true;
                }

                if (project.is_favorite == 1) {
                    is_favorite_image.visible = true;
                }

                project_updated (project);
            }
        } else {

        }
    }
}