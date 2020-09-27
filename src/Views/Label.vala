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

public class Views.Label : Gtk.EventBox {
    public Objects.Label label { get; set; }
    public Gee.HashMap <string, Widgets.ItemRow> items_loaded;
    private Gtk.ListBox listbox;

    construct {
        items_loaded = new Gee.HashMap <string, Widgets.ItemRow> ();

        var icon_image = new Gtk.Image ();
        icon_image.valign = Gtk.Align.CENTER;
        icon_image.gicon = new ThemedIcon ("tag-symbolic");
        icon_image.pixel_size = 16;
        icon_image.margin_top = 1;

        var title_label = new Gtk.Label ( null);
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
        top_box.margin_bottom = 6;
        top_box.margin_top = 6;

        top_box.pack_start (icon_image, false, false, 0);
        top_box.pack_start (title_label, false, false, 0);
        top_box.pack_start (hidden_button, false, false, 0);

        listbox = new Gtk.ListBox ();
        listbox.expand = true;
        listbox.margin_start = 30;
        listbox.margin_end = 32;
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;
        listbox.margin_top = 12;

        var box_scrolled = new Gtk.ScrolledWindow (null, null);
        box_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        box_scrolled.expand = true;
        box_scrolled.add (listbox);

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

        notify["label"].connect (() => {
            items_loaded.clear ();

            title_label.label = "<b>%s</b>".printf (label.name);

            foreach (string c in icon_image.get_style_context ().list_classes ()) {
                icon_image.get_style_context ().remove_class (c);
            }
            icon_image.get_style_context ().add_class ("label-color-%i".printf (label.color));

            foreach (unowned Gtk.Widget child in listbox.get_children ()) {
                child.destroy ();
            }

            foreach (Objects.Item item in Planner.database.get_items_by_label (label.id)) {
                var row = new Widgets.ItemRow (item, "label");

                listbox.add (row);
                items_loaded.set (item.id.to_string (), row);

                listbox.show_all ();
            }

            if (items_loaded.size > 0) {
                view_stack.visible_child_name = "listbox";
            } else {
                view_stack.visible_child_name = "placeholder";
            }
        });

        listbox.row_activated.connect ((r) => {
            var row = ((Widgets.ItemRow) r);

            if (Planner.event_bus.ctrl_pressed) {
                Planner.event_bus.select_item (row);
            } else {
                row.reveal_child = true;
                Planner.event_bus.unselect_all ();
            }
        });

        Planner.database.item_label_deleted.connect ((i, item_id, l) => {
            if (label.id == l.id && items_loaded.has_key (item_id.to_string ())) {
                items_loaded.get (item_id.to_string ()).hide_destroy ();
                items_loaded.unset (item_id.to_string ());

                if (items_loaded.size > 0) {
                    view_stack.visible_child_name = "listbox";
                } else {
                    view_stack.visible_child_name = "placeholder";
                }
            }
        });

        hidden_button.clicked.connect (() => {
            listbox.foreach ((widget) => {
                var listBoxRow = (Widgets.ItemRow)widget;
                if (listBoxRow.reveal_child) listBoxRow.hide_item();
            });
        });
    }
}
