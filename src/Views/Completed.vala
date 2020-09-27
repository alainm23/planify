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

        var hidden_button = new Gtk.Button.from_icon_name ("view-restore-symbolic", Gtk.IconSize.MENU);
        hidden_button.can_focus = false;
        hidden_button.margin_top = 1;
        hidden_button.margin_end = 3;
        hidden_button.tooltip_text = _("Hide Details");
        hidden_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_end = 36;
        top_box.margin_start = 42;
        top_box.margin_bottom = 18;
        top_box.margin_top = 6;

        top_box.pack_start (icon_image, false, false, 0);
        top_box.pack_start (title_label, false, false, 0);
        top_box.pack_start (hidden_button, false, false, 0);

        listbox = new Gtk.ListBox ();
        listbox.margin_bottom = 32;
        listbox.expand = true;
        listbox.margin_end = 32;
        listbox.margin_start = 30;
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;
        listbox.set_header_func (header_function);

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

        hidden_button.clicked.connect (() => {
            listbox.foreach ((widget) => {
                var list_box_row = (Widgets.ItemRow)widget;
                if (list_box_row.reveal_child) list_box_row.hide_item ();
            });
        });
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

    private void header_function (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
        var row = (Widgets.ItemCompletedRow) lbrow;
        if (row.item.date_completed == "") {
            return;
        }

        if (lbbefore != null) {
            var before = (Widgets.ItemCompletedRow) lbbefore;
            var comp_before = Planner.utils.get_format_date_from_string (before.item.date_completed);
            if (comp_before.compare (Planner.utils.get_format_date_from_string (row.item.date_completed)) == 0) {
                return;
            }
        }

        var header_label = new Gtk.Label (Planner.utils.get_relative_date_from_string (row.item.date_completed));
        header_label.get_style_context ().add_class ("font-bold");
        header_label.halign = Gtk.Align.START;

        var header_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        header_separator.hexpand = true;

        var header_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        header_box.margin_start = 12;
        header_box.margin_end = 12;
        header_box.margin_top = 12;
        header_box.add (header_label);
        header_box.add (header_separator);
        header_box.show_all ();

        row.set_header (header_box);
    }
}
