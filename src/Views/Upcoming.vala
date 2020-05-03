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

public class Views.Upcoming : Gtk.EventBox {
    public GLib.DateTime date { get; set; default = new GLib.DateTime.now_local (); }
    private Gtk.ListBox listbox;
    public Gee.ArrayList<Widgets.ItemRow?> items_opened;
    
    construct {
        items_opened = new Gee.ArrayList<Widgets.ItemRow?> ();

        var icon_image = new Gtk.Image ();
        icon_image.valign = Gtk.Align.CENTER;
        icon_image.gicon = new ThemedIcon ("x-office-calendar-symbolic");
        icon_image.get_style_context ().add_class ("upcoming-icon");
        icon_image.pixel_size = 16;

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Upcoming")));
        title_label.get_style_context ().add_class ("title-label");
        title_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_end = 36;
        top_box.margin_start = 42;
        top_box.margin_bottom = 12;
        top_box.margin_top = 6;

        top_box.pack_start (icon_image, false, false, 0);
        top_box.pack_start (title_label, false, false, 0);

        listbox = new Gtk.ListBox ();
        listbox.get_style_context ().add_class ("listbox");
        listbox.margin_top = 6;
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        var listbox_grid = new Gtk.Grid ();
        listbox_grid.margin_bottom = 3;
        listbox_grid.margin_end = 3;
        listbox_grid.add (listbox);

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        listbox_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        listbox_scrolled.expand = true;
        listbox_scrolled.add (listbox_grid);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (listbox_scrolled, false, true, 0);

        add (main_box);

        Planner.calendar_model.month_start = Util.get_start_of_month ();

        add_upcomings ();

        listbox_scrolled.edge_reached.connect ((pos) => {
            if (pos == Gtk.PositionType.BOTTOM) {
                add_upcomings ();
            }
        });

        show_all ();

        Planner.utils.add_item_show_queue_view.connect ((row, view) => {
            if (view == "upcoming") {
                items_opened.add (row);
            }
        });

        Planner.utils.remove_item_show_queue_view.connect ((row, view) => {
            if (view == "upcoming") {
                remove_item_show_queue (row);
            }
        });
    }

    private void remove_item_show_queue (Widgets.ItemRow row) {
        items_opened.remove (row);
    }

    private void add_upcomings () {
        for (int i = 0; i < 14; i++) {
            date = date.add_days (1);

            var row = new Widgets.UpcomingRow (date);

            listbox.add (row);
            listbox.show_all ();

            Planner.calendar_model.month_start = Util.get_start_of_month (date);
        }
    }

    public void hide_last_item () {
        if (items_opened.size > 0) {
            var last = items_opened [items_opened.size - 1];
            remove_item_show_queue (last);
            last.hide_item ();

            if (items_opened.size > 0) {
                var focus = items_opened [items_opened.size - 1];
                focus.grab_focus ();
                focus.content_entry_focus ();
            }
        }
    }
}
