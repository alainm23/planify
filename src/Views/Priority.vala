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

public class Views.Priority : Gtk.EventBox {
    public int priority { get; set; }
    public Gee.HashMap <string, Widgets.ItemRow> items_loaded;
    private Gtk.ListBox listbox;

    construct {
        items_loaded = new Gee.HashMap <string, Widgets.ItemRow> ();

        var icon_image = new Gtk.Image ();
        icon_image.valign = Gtk.Align.CENTER;
        icon_image.pixel_size = 16;

        var title_label = new Gtk.Label ( null);
        title_label.get_style_context ().add_class ("title-label");
        title_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_end = 36;
        top_box.margin_start = 42;
        top_box.margin_bottom = 6;
        top_box.margin_top = 6;

        top_box.pack_start (icon_image, false, false, 0);
        top_box.pack_start (title_label, false, false, 0);

        listbox = new Gtk.ListBox ();
        listbox.expand = true;
        listbox.margin_end = 32;
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        var g = new Gtk.Grid ();
        g.margin_start = 30;
        g.margin_top = 12;
        g.add (listbox);

        var box_scrolled = new Gtk.ScrolledWindow (null, null);
        box_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        box_scrolled.expand = true;
        box_scrolled.add (g);
        
        var placeholder_view = new Widgets.Placeholder (
            _("All clear"),
            _("No tasks in this filter at the moment."),
            "edit-flag-symbolic"
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

        notify["priority"].connect (() => {
            items_loaded.clear ();
            
            if (priority == 1) {
                if (Planner.settings.get_enum ("appearance") == 0) {
                    icon_image.gicon = new ThemedIcon ("flag-outline-light");
                } else {
                    icon_image.gicon = new ThemedIcon ("flag-outline-dark");
                }
                title_label.label = "<b>%s</b>".printf (_("Priority 4"));
            } else if (priority == 2) {
                icon_image.gicon = new ThemedIcon ("priority-2");
                title_label.label = "<b>%s</b>".printf (_("Priority 3"));
            } else if (priority == 3) {
                icon_image.gicon = new ThemedIcon ("priority-3");
                title_label.label = "<b>%s</b>".printf (_("Priority 2"));
            } else if (priority == 4) {
                icon_image.gicon = new ThemedIcon ("priority-4");
                title_label.label = "<b>%s</b>".printf (_("Priority 1"));
            }

            foreach (unowned Gtk.Widget child in listbox.get_children ()) {
                child.destroy ();
            }
            
            foreach (Objects.Item item in Planner.database.get_items_by_priority (priority)) {
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

        listbox.row_activated.connect ((row) => {
            var item = ((Widgets.ItemRow) row);
            item.reveal_child = true;
        });

        Planner.database.item_updated.connect ((item) => {
            Idle.add (() => {
                if (items_loaded.has_key (item.id.to_string ())) {
                    if (priority != items_loaded.get (item.id.to_string ()).item.priority) {
                        items_loaded.get (item.id.to_string ()).hide_destroy ();
                        items_loaded.unset (item.id.to_string ());
    
                        if (items_loaded.size > 0) {
                            view_stack.visible_child_name = "listbox";
                        } else {
                            view_stack.visible_child_name = "placeholder";
                        }
                    }
                }

                return false;
            });
        });
    }
}
