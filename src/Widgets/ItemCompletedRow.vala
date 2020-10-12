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

public class Widgets.ItemCompletedRow : Gtk.ListBoxRow {
    public Objects.Item item { get; construct; }
    private Gtk.Menu menu = null;
    private Gtk.Box main_box;
    public string view { get; construct; }
    private uint timeout_id = 0;
    private Gtk.Revealer main_revealer;

    public ItemCompletedRow (Objects.Item item, string view="project") {
        Object (
            item: item,
            view: view
        );
    }

    construct {
        can_focus = false;
        get_style_context ().add_class ("item-row");

        string tooltip_string = "<b>%s</b>:\n%s".printf (_("Content"), Planner.utils.get_markup_format (item.content));
        if (item.note != "") {
            tooltip_string += "\n\n" + "<b>%s</b>:\n%s".printf (_("Note"), Planner.utils.get_markup_format (item.note));
        }

        if (item.due_date != "") {
            tooltip_string += "\n\n" + "<b>%s</b>:\n%s".printf (_("Due date"), Planner.utils.get_relative_date_from_string (item.due_date));
        }

        tooltip_string += "\n\n" + "<b>%s</b>:\n%s".printf (_("Date completed"), Planner.utils.get_relative_date_from_string (item.date_completed));
        tooltip_markup = tooltip_string;

        var checked_button = new Gtk.CheckButton ();
        checked_button.can_focus = false;
        checked_button.valign = Gtk.Align.START;
        checked_button.halign = Gtk.Align.START;
        checked_button.get_style_context ().add_class ("checklist-completed");
        checked_button.active = true;
        checked_button.margin_top = 2;

        var content_label = new Gtk.Label (Planner.utils.get_markup_format (item.content));
        content_label.margin_start = 8;
        content_label.margin_end = 5;
        content_label.halign = Gtk.Align.START;
        content_label.valign = Gtk.Align.CENTER;
        content_label.xalign = 0;
        content_label.wrap = true;
        content_label.use_markup = true;

        var bottom_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 9);
        bottom_box.hexpand = true;
        bottom_box.margin_start = 28;
        bottom_box.margin_bottom = 3;

        if (view != "completed") {
            var completed_label = new Gtk.Label ("<small>%s</small>".printf (Planner.utils.get_relative_date_from_string (item.date_completed)));
            completed_label.halign = Gtk.Align.START;
            completed_label.valign = Gtk.Align.CENTER;
            completed_label.use_markup = true;
            completed_label.get_style_context ().add_class ("completed-label");
            completed_label.get_style_context ().add_class ("font-bold");

            bottom_box.pack_start (completed_label, false, false, 0);
        }

        if (view == "completed") {
            var project = Planner.database.get_project_by_id (item.project_id);

            var project_preview_image = new Gtk.Image ();
            project_preview_image.pixel_size = 9;
            project_preview_image.margin_top = 1;
            if (project.inbox_project == 1) {
                project_preview_image.gicon = new ThemedIcon ("color-41");
            } else {
                project_preview_image.gicon = new ThemedIcon ("color-%i".printf (project.color));
            }

            var project_preview_label = new Gtk.Label (
                "<small>%s</small>".printf (Planner.utils.get_dialog_text (project.name))
            );
            project_preview_label.get_style_context ().add_class ("pane-item");
            project_preview_label.use_markup = true;

            var project_preview_grid = new Gtk.Grid ();
            project_preview_grid.column_spacing = 3;
            project_preview_grid.halign = Gtk.Align.CENTER;
            project_preview_grid.valign = Gtk.Align.CENTER;
            project_preview_grid.add (project_preview_image);
            project_preview_grid.add (project_preview_label);
            bottom_box.pack_start (project_preview_grid, false, false, 0);
        }

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.margin = 3;
        box.margin_start = 6;
        box.pack_start (checked_button, false, false, 0);
        box.pack_start (content_label, false, false, 0);

        main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.margin_top = 6;
        main_box.margin_start = 6;
        main_box.pack_start (box, false, true, 0);
        main_box.pack_start (bottom_box, false, false, 0);

        var handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.expand = true;
        handle.above_child = false;
        handle.add (main_box);

        main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = false;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (handle);

        add (main_revealer);

        timeout_id = Timeout.add (150, () => {
            timeout_id = 0;
            main_revealer.reveal_child = true;
            return false;
        });

        checked_button.toggled.connect (() => {
            if (checked_button.active == false) {
                item.checked = 0;
                item.date_completed = "";

                Planner.database.update_item_completed (item);
                if (item.is_todoist == 1) {
                    Planner.todoist.item_uncomplete (item);
                }
            }
        });

        Planner.database.item_uncompleted.connect ((i) => {
            Idle.add (() => {
                if (item.id == i.id) {
                    hide_destroy ();
                }

                return false;
            });
        });

        button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                activate_menu ();
                return true;
            }

            return false;
        });

        Planner.database.item_deleted.connect ((i) => {
            Idle.add (() => {
                if (item.id == i.id) {
                    destroy ();
                }

                return false;
            });
        });
    }

    private void activate_menu () {
        if (menu == null) {
            build_context_menu (item);
        }

        main_box.get_style_context ().add_class ("highlight");
        menu.popup_at_pointer (null);
    }

    private void build_context_menu (Objects.Item item) {
        menu = new Gtk.Menu ();
        menu.width_request = 235;

        menu.hide.connect (() => {
            main_box.get_style_context ().remove_class ("highlight");
        });

        var uncomplete_menu = new Widgets.ImageMenuItem (_("Mark Incomplete"), "emblem-default-symbolic");
        var delete_menu = new Widgets.ImageMenuItem (_("Delete"), "user-trash-symbolic");
        delete_menu.get_style_context ().add_class ("menu-danger");

        menu.add (uncomplete_menu);
        menu.add (delete_menu);
        menu.show_all ();

        uncomplete_menu.activate.connect (() => {
            item.checked = 0;
            item.date_completed = "";

            Planner.database.update_item_completed (item);
            if (item.is_todoist == 1) {
                Planner.todoist.item_uncomplete (item);
            }
        });

        delete_menu.activate.connect (() => {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Delete task"),
                _("Are you sure you want to delete <b>%s</b>?".printf (Planner.utils.get_dialog_text (item.content))),
                "user-trash-full",
            Gtk.ButtonsType.CANCEL);

            var remove_button = new Gtk.Button.with_label (_("Delete"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                Planner.database.delete_item (item);
                if (item.is_todoist == 1) {
                    Planner.todoist.add_delete_item (item);
                }
            }

            message_dialog.destroy ();
        });
    }
    
    public void hide_destroy () {
        main_revealer.reveal_child = false;

        Timeout.add (500, () => {
            destroy ();
            return false;
        });
    }
}
