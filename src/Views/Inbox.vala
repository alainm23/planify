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

public class Views.Inbox : Gtk.EventBox {
    private bool first_init;

    private Gtk.ListBox tasks_list;
    public Inbox () {
        Object (
            expand: true
        );
    }  

    construct {
        first_init = true;

        var inbox_icon = new Gtk.Image.from_icon_name ("mail-mailbox-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

        var inbox_label = new Gtk.Label ("<b>%s</b>".printf (_("Inbox")));
        inbox_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        inbox_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.hexpand = true;
        top_box.margin = 12;

        top_box.pack_start (inbox_icon, false, false, 0);
        top_box.pack_start (inbox_label, false, false, 12);

        tasks_list = new Gtk.ListBox  ();
        tasks_list.valign = Gtk.Align.START;
        tasks_list.activate_on_single_click = true;
        tasks_list.selection_mode = Gtk.SelectionMode.SINGLE;
        tasks_list.hexpand = true;

        // Search Entry
        var search_entry = new Gtk.SearchEntry ();
        search_entry.valign = Gtk.Align.CENTER;
        search_entry.halign = Gtk.Align.CENTER;
        search_entry.margin = 3;
        search_entry.width_request = 200;
        search_entry.placeholder_text = _("Search task");

        // To Do
        var todo_image = new Gtk.Image ();
        todo_image.gicon = new ThemedIcon ("mail-mailbox-symbolic");
        todo_image.pixel_size = 16;

        var todo_label = new Gtk.Label ("<b>8</b>");
        todo_label.use_markup = true;

        var todo_grid = new Gtk.Grid ();
        todo_grid.tooltip_text = _("To do tasks");
        todo_grid.add (todo_image);
        todo_grid.add (todo_label);

        // Completed
        var completed_image = new Gtk.Image ();
        completed_image.gicon = new ThemedIcon ("emblem-default-symbolic");
        completed_image.pixel_size = 16;

        var completed_label = new Gtk.Label ("<b>2</b>");
        completed_label.use_markup = true;

        var completed_grid = new Gtk.Grid ();
        completed_grid.tooltip_text = _("Completed tasks");
        completed_grid.add (completed_image);
        completed_grid.add (completed_label);

        var zoom_in = new Gtk.Image.from_icon_name ("zoom-in-symbolic", Gtk.IconSize.MENU);
        var zoom_out = new Gtk.Image.from_icon_name ("zoom-out-symbolic", Gtk.IconSize.MENU);

        var show_label = _("Show completed tasks");
        var hide_label = _("Hide completed tasks");

        var show_hide_button = new Gtk.Button ();
        show_hide_button.can_focus = false;
        show_hide_button.margin_bottom = 1;
        show_hide_button.valign = Gtk.Align.END;
        show_hide_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        show_hide_button.always_show_image = true;
        show_hide_button.image = zoom_in;
        show_hide_button.label = show_label;

        var actionbar = new Gtk.ActionBar ();
        actionbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        actionbar.pack_start (show_hide_button);
        actionbar.pack_end (search_entry);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, true, 0);
        main_box.pack_start (tasks_list, false, true, 0);
        main_box.pack_end (actionbar, false, true, 0);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (main_box);

        var main_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_grid.expand = true;
        main_grid.add (scrolled);

        add (main_grid);

        show_hide_button.clicked.connect (() => {
            if (show_hide_button.image == zoom_in) {
                show_hide_button.image = zoom_out;
                show_hide_button.label = hide_label;
            } else {
                show_hide_button.image = zoom_in;
                show_hide_button.label = show_label;
            }
        });
    }
}