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

public class Layouts.ProjectRow : Gtk.ListBoxRow {
    public Objects.Project project { get; construct; }
    public bool show_subprojects { get; construct; }
    
    private Widgets.CircularProgressBar circular_progress_bar;
    private Gtk.Label emoji_label;
    private Gtk.Label name_label;
    private Gtk.Stack progress_emoji_stack;
    private Gtk.Revealer content_revealer;

    private Gtk.Popover menu_popover = null;

    public ProjectRow (Objects.Project project, bool show_subprojects = true) {
        Object (
            project: project,
            show_subprojects: show_subprojects
        );
    }

    construct {
        add_css_class ("selectable-item");

        circular_progress_bar = new Widgets.CircularProgressBar (10);
        circular_progress_bar.percentage = 0.64;
        circular_progress_bar.color = project.color;

        emoji_label = new Gtk.Label (project.emoji) {
            halign = Gtk.Align.CENTER
        };

        progress_emoji_stack = new Gtk.Stack ();
        progress_emoji_stack.add_named (circular_progress_bar, "progress");
        progress_emoji_stack.add_named (emoji_label, "emoji");

        name_label = new Gtk.Label (project.name);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 3,
            margin_start = 3,
            margin_end = 3,
            margin_bottom = 3,
        };
        
        content_box.append (progress_emoji_stack);
        content_box.append (name_label);

        content_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        content_revealer.child = content_box;

        child = content_revealer;
        update_request ();

        Timeout.add (progress_emoji_stack.transition_duration, () => {
            if (project.icon_style == ProjectIconStyle.PROGRESS) {
                progress_emoji_stack.visible_child_name = "progress";
            } else {
                progress_emoji_stack.visible_child_name = "emoji";
            }
            
            return GLib.Source.REMOVE;
        });

        Timeout.add (content_revealer.transition_duration, () => {
            content_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        var menu_gesture = new Gtk.GestureClick ();
        menu_gesture.set_button (3);
        add_controller (menu_gesture);

        var select_gesture = new Gtk.GestureClick ();
        select_gesture.set_button (1);
        add_controller (select_gesture);

        menu_gesture.pressed.connect (() => {
            build_context_menu();
        });

        //  select_gesture.pressed.connect (() => {
        //      Timeout.add (Constants.DRAG_TIMEOUT, () => {
        //          if (content_revealer.reveal_child) {
        //              Planner.event_bus.pane_selected (PaneType.PROJECT, project.id_string);
        //          }
                
        //          return GLib.Source.REMOVE;
        //      });
        //  });

        //  activate.connect (() => {
        //      if (content_revealer.reveal_child) {
        //          Planner.event_bus.pane_selected (PaneType.PROJECT, project.id_string);
        //      }
        //  });

        //  Planner.event_bus.pane_selected.connect ((pane_type, id) => {
        //      if (pane_type == PaneType.PROJECT && project.id_string == id) {
        //          add_css_class ("selectable-item-selected");
        //      } else {
        //          remove_css_class ("selectable-item-selected");
        //      }
        //  });

        project.updated.connect (update_request);
    }

    private void build_context_menu () {
        if (menu_popover != null) {
            menu_popover.popup();
            return;
        }
        
        var favorite_item = new Dialogs.ContextMenu.MenuItem (project.is_favorite ? ("Remove from favorites") : ("Add to favorites"), "planner-star");
        var edit_item = new Dialogs.ContextMenu.MenuItem (("Edit project"), "planner-edit");
        var move_item = new Dialogs.ContextMenu.MenuItem (_("Move to project"), "chevron-right");
        var delete_item = new Dialogs.ContextMenu.MenuItem (_("Delete project"), "planner-trash");
        delete_item.add_css_class ("menu-item-danger");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (favorite_item);
        menu_box.append (edit_item);
        menu_box.append (move_item);
        menu_box.append (new Dialogs.ContextMenu.MenuSeparator ());
        menu_box.append (delete_item);

        menu_popover = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            position = Gtk.PositionType.RIGHT
        };

        menu_popover.set_parent (this);

        menu_popover.popup();

        edit_item.clicked.connect (() => {
            menu_popover.popdown ();

            var dialog = new Dialogs.Project (project);
            dialog.show ();
        });
    }

    public void update_request () {
        if (project.icon_style == ProjectIconStyle.PROGRESS) {
            progress_emoji_stack.visible_child_name = "progress";
        } else {
            progress_emoji_stack.visible_child_name = "emoji";
        }
        
        circular_progress_bar.color = project.color;
        emoji_label.label = project.emoji;
        name_label.label = project.name;
    }
}