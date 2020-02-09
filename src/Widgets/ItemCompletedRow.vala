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

    private Gtk.CheckButton checked_button;
    private Gtk.Label content_label;

    public ItemCompletedRow (Objects.Item item) {
        Object (
            item: item
        );
    }

    construct {
        can_focus = false;
        get_style_context ().add_class ("item-row");

        tooltip_markup = "<b>%s</b>:\n%s\n<b>%s</b>:\n%s\n<b>%s</b>:\n%s\n<b>%s</b>:\n%s".printf (
            _("Content"), item.content,
            _("Note"), item.note,
            _("Due date"), Planner.utils.get_relative_date_from_string (item.due_date),
            _("Date completed"), Planner.utils.get_relative_date_from_string (item.date_completed)
        );

        var loading_spinner = new Gtk.Spinner ();
        loading_spinner.margin_start = 17;
        loading_spinner.start ();

        var loading_revealer = new Gtk.Revealer ();
        loading_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        loading_revealer.add (loading_spinner);

        checked_button = new Gtk.CheckButton ();
        checked_button.can_focus = false;
        checked_button.margin_start = 9;
        checked_button.valign = Gtk.Align.CENTER;
        checked_button.halign = Gtk.Align.START;
        checked_button.get_style_context ().add_class ("checklist-button");
        checked_button.active = true;

        var completed_label = new Gtk.Label (Planner.utils.get_relative_date_from_string (item.date_completed));
        completed_label.halign = Gtk.Align.START;
        completed_label.valign = Gtk.Align.CENTER;

        completed_label.get_style_context ().add_class ("due-preview");

        content_label = new Gtk.Label ("<s>%s</s>".printf (item.content));
        content_label.margin_start = 9;
        content_label.halign = Gtk.Align.START;
        content_label.valign = Gtk.Align.CENTER;
        content_label.xalign = 0;
        content_label.use_markup = true;
        content_label.get_style_context ().add_class ("label");
        content_label.ellipsize = Pango.EllipsizeMode.END;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.margin = 3;
        box.margin_start = 0;
        box.pack_start (loading_revealer, false, false, 0);
        box.pack_start (checked_button, false, false, 0);
        //box.pack_start (completed_label, false, false, 0);
        box.pack_start (content_label, false, false, 0);

        add (box);

        Planner.database.item_completed.connect ((i) => {
            if (item.id == i.id) {
                if (i.checked == 0) {
                    destroy ();
                }
            }
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
    }
}
