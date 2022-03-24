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

public class Layouts.TasklistRow : Gtk.ListBoxRow {
    public E.Source source { get; construct; }

    private Gtk.Label name_label;
    private Gtk.Revealer main_revealer;
    private Widgets.ProjectProgress project_progress;
    private Gtk.Grid handle_grid;
    private Gtk.EventBox tasklistrow_eventbox;
    private Gtk.Label count_label;
    private Gtk.Revealer count_revealer;
    private Gtk.Revealer top_motion_revealer;
    private Gtk.Revealer bottom_motion_revealer;
    
    public TasklistRow (E.Source source) {
        Object (
            source: source
        );
    }

    construct {
        get_style_context ().add_class ("selectable-item");
        var task_list = (E.SourceTaskList?) source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);

        project_progress = new Widgets.ProjectProgress (18);
        project_progress.enable_subprojects = true;
        project_progress.valign = Gtk.Align.CENTER;
        project_progress.halign = Gtk.Align.CENTER;
        project_progress.progress_fill_color = task_list.dup_color ();

        name_label = new Gtk.Label (source.display_name);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        
        count_label = new Gtk.Label (null) {
            hexpand = true,
            halign = Gtk.Align.END,
            margin_end = 3
        };
        count_label.get_style_context ().add_class ("dim-label");
        count_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        count_revealer = new Gtk.Revealer () {
            reveal_child = int.parse (count_label.label) > 0
        };
        count_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        count_revealer.add (count_label);

        var projectrow_grid = new Gtk.Grid () {
            column_spacing = 6,
            margin = 3
        };
        projectrow_grid.add (project_progress);
        projectrow_grid.add (name_label);

        handle_grid = new Gtk.Grid ();
        handle_grid.add (projectrow_grid);

        tasklistrow_eventbox = new Gtk.EventBox () {
            hexpand = true
        };
        tasklistrow_eventbox.get_style_context ().add_class ("transition");
        tasklistrow_eventbox.add (handle_grid);

        var top_motion_grid = new Gtk.Grid ();
        top_motion_grid.get_style_context ().add_class ("grid-motion");
        top_motion_grid.height_request = 16;

        top_motion_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        top_motion_revealer.add (top_motion_grid);

        var bottom_motion_grid = new Gtk.Grid ();
        bottom_motion_grid.get_style_context ().add_class ("grid-motion");
        bottom_motion_grid.height_request = 16;

        bottom_motion_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        bottom_motion_revealer.add (bottom_motion_grid);

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };
        main_grid.add (top_motion_revealer);
        main_grid.add (tasklistrow_eventbox);
        main_grid.add (bottom_motion_revealer);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.add (main_grid);

        add (main_revealer);
        update_request ();

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        tasklistrow_eventbox.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                Timeout.add (Constants.DRAG_TIMEOUT, () => {
                    if (main_revealer.reveal_child) {
                        Planner.event_bus.pane_selected (PaneType.TASKLIST, source.dup_uid ());
                    }
                    return GLib.Source.REMOVE;
                });
            } else if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                build_content_menu ();
            }

            return Gdk.EVENT_PROPAGATE;
        });

        Planner.event_bus.pane_selected.connect ((pane_type, id) => {
            if (pane_type == PaneType.TASKLIST && source.dup_uid () == id) {
                tasklistrow_eventbox.get_style_context ().add_class ("selectable-item-selected");
            } else {
                tasklistrow_eventbox.get_style_context ().remove_class ("selectable-item-selected");
            }
        });
    }

    public void update_request () {
        var task_list = (E.SourceTaskList?) source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);

        name_label.label = source.display_name;
        project_progress.progress_fill_color = task_list.dup_color ();
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }

    private void build_content_menu () {
        var menu = new Dialogs.ContextMenu.Menu ();

        var edit_item = new Dialogs.ContextMenu.MenuItem (("Edit tasklist"), "planner-edit");

        var share_item = new Dialogs.ContextMenu.MenuItemSelector (_("Share"));
        var delete_item = new Dialogs.ContextMenu.MenuItem (_("Delete tasklist"), "planner-trash");
        
        var delete_item_context = delete_item.get_style_context ();
        delete_item_context.add_class ("menu-item-danger");

        var share_markdown = new Dialogs.ContextMenu.MenuItem (_("Markdown"), "planner-trash");
        var email_markdown = new Dialogs.ContextMenu.MenuItem (_("Email"), "planner-trash");

        share_item.add_item (share_markdown);
        share_item.add_item (email_markdown);

        menu.add_item (edit_item);
        menu.add_item (new Dialogs.ContextMenu.MenuSeparator ());
        // menu.add_item (move_item);
        // menu.add_item (share_item);
        menu.add_item (new Dialogs.ContextMenu.MenuSeparator ());
        menu.add_item (delete_item);

        menu.popup ();

        delete_item.activate_item.connect (() => {
            menu.hide_destroy ();
        });

        edit_item.clicked.connect (() => {
            menu.hide_destroy ();
            //  var dialog = new Dialogs.Project (project);
            //  dialog.show_all ();
        });
    }
}
