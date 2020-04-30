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
    public string view { get; construct; }

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

        string tooltip_string = "<b>%s</b>:\n%s".printf (_("Content"), item.content);
        if (item.note != "") {
            tooltip_string += "\n\n" + "<b>%s</b>:\n%s".printf (_("Note"), item.note);
        }

        if (item.due_date != "") {
            tooltip_string += "\n\n" + "<b>%s</b>:\n%s".printf (_("Due date"), Planner.utils.get_relative_date_from_string (item.due_date));
        }

        tooltip_string += "\n\n" + "<b>%s</b>:\n%s".printf (_("Date completed"), Planner.utils.get_relative_date_from_string (item.date_completed));
        tooltip_markup = tooltip_string;

        var checked_button = new Gtk.CheckButton ();
        checked_button.margin_start = 1;
        checked_button.can_focus = false;
        checked_button.valign = Gtk.Align.START;
        checked_button.halign = Gtk.Align.START;
        checked_button.get_style_context ().add_class ("checklist-completed");
        checked_button.active = true;
        checked_button.margin_top = 2;

        var content_label = new Gtk.Label (item.content);
        content_label.margin_start = 7;
        content_label.halign = Gtk.Align.START;
        content_label.valign = Gtk.Align.CENTER;
        content_label.xalign = 0;
        content_label.wrap = true;
        content_label.use_markup = true;

        var completed_label = new Gtk.Label ("<small>%s</small>".printf (Planner.utils.get_relative_date_from_string (item.date_completed)));
        completed_label.halign = Gtk.Align.START;
        completed_label.valign = Gtk.Align.CENTER;
        completed_label.use_markup = true;
        completed_label.get_style_context ().add_class ("completed-label");
        completed_label.get_style_context ().add_class ("font-bold");

        var bottom_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 9);
        bottom_box.hexpand = true;
        bottom_box.margin_start = 26;
        bottom_box.pack_start (completed_label, false, false, 0);

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
                "<small>%s</small>".printf (project.name)
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
        box.pack_start (checked_button, false, false, 0);
        box.pack_start (content_label, false, false, 0);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.margin_top = 6;
        main_box.pack_start (box, false, true, 0);
        main_box.pack_start (bottom_box, false, false, 0);

        main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = true;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (main_box);

        add (main_revealer);

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
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;

        Timeout.add (500, () => {
            destroy ();
            return false;
        });
    }
}
