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

public class Views.Completed : Gtk.EventBox {
    public Gee.HashMap <string, Widgets.ItemCompletedRow> items_loaded;
    private Gtk.ListBox listbox;

    construct {
        items_loaded = new Gee.HashMap <string, Widgets.ItemCompletedRow> ();

        var icon_image = new Gtk.Image ();
        icon_image.valign = Gtk.Align.CENTER;
        icon_image.gicon = new ThemedIcon ("emblem-default-symbolic");
        icon_image.get_style_context ().add_class ("completed-icon");
        icon_image.pixel_size = 16;

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Completed")));
        title_label.get_style_context ().add_class ("title-label");
        title_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_end = 36;
        top_box.margin_start = 42;
        top_box.margin_bottom = 18;
        top_box.margin_top = 6;

        top_box.pack_start (icon_image, false, false, 0);
        top_box.pack_start (title_label, false, false, 0);

        listbox = new Gtk.ListBox ();
        listbox.margin_bottom = 32;
        listbox.expand = true;
        listbox.margin_start = 38;
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.hexpand = true;
        box.add (listbox);

        var box_scrolled = new Gtk.ScrolledWindow (null, null);
        box_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        box_scrolled.expand = true;
        box_scrolled.add (box);

        var placeholder_view = new Widgets.Placeholder (
            _("All clear"),
            _("No tasks in this filter at the moment."),
            "tag-symbolic"
        );
        placeholder_view.reveal_child = true;

        var view_stack = new Gtk.Stack ();
        view_stack.expand = true;
        view_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        view_stack.add_named (box_scrolled, "listbox");
        view_stack.add_named (placeholder_view, "placeholder");

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (view_stack, false, true, 0);

        add (main_box);
        show_all ();
    }

    public void add_all_items () {
        foreach (unowned Gtk.Widget child in listbox.get_children ()) {
            child.destroy ();
        }

        foreach (var item in Planner.database.get_all_completed_items ()) {
            var row = new Widgets.ItemCompletedRow (item, "completed");

            items_loaded.set (item.id.to_string (), row);

            listbox.add (row);
            listbox.show_all ();
        }

        //listbox.set_sort_func (sort_function);
        //listbox.set_header_func (update_headers);
    }
}
