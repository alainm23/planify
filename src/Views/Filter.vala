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

public class Views.Filter : Gtk.EventBox {
    public string filter { get; set; }
    public Gee.HashMap <string, Widgets.ItemRow> items_loaded;
    private Gtk.ListBox listbox;
    private Gtk.Stack view_stack;
    private Gtk.Image icon_image;

    construct {
        items_loaded = new Gee.HashMap <string, Widgets.ItemRow> ();

        icon_image = new Gtk.Image ();
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

        view_stack = new Gtk.Stack ();
        view_stack.expand = true;
        view_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        view_stack.add_named (box_scrolled, "listbox");
        view_stack.add_named (placeholder_view, "placeholder");

        var magic_button = new Widgets.MagicButton ();

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (view_stack, false, true, 0);

        var overlay = new Gtk.Overlay ();
        overlay.expand = true;
        overlay.add_overlay (magic_button);
        overlay.add (main_box);

        add (overlay);
        show_all ();

        notify["filter"].connect (() => {
            clear ();
            
            if (filter == "p4") {
                if (Planner.settings.get_enum ("appearance") == 0) {
                    icon_image.gicon = new ThemedIcon ("flag-outline-light");
                } else {
                    icon_image.gicon = new ThemedIcon ("flag-outline-dark");
                }
                title_label.label = "<b>%s</b>".printf (_("None"));
            } else if (filter == "p3") {
                icon_image.gicon = new ThemedIcon ("priority-2");
                title_label.label = "<b>%s</b>".printf (_("Priority 3"));
            } else if (filter == "p2") {
                icon_image.gicon = new ThemedIcon ("priority-3");
                title_label.label = "<b>%s</b>".printf (_("Priority 2"));
            } else if (filter == "p1") {
                icon_image.gicon = new ThemedIcon ("priority-4");
                title_label.label = "<b>%s</b>".printf (_("Priority 1"));
            } else if (filter == "tomorrow") {
                icon_image.gicon = new ThemedIcon ("x-office-calendar-symbolic");
                icon_image.get_style_context ().add_class ("upcoming-icon");
                title_label.label = "<b>%s</b>".printf (_("Tomorrow"));
            }

            if (filter == "p4" || filter == "p3" || filter == "p2" || filter == "p1") {
                int priority;
                if (filter == "p4") {
                    priority = 1;
                } else if (filter == "p3") {
                    priority = 2;
                } else if (filter == "p2") {
                    priority = 3;
                } else if (filter == "p1") {
                    priority = 4;
                }

                foreach (Objects.Item item in Planner.database.get_items_by_priority (priority)) {
                    var row = new Widgets.ItemRow (item, "label");
    
                    listbox.add (row);
                    items_loaded.set (item.id.to_string (), row);
    
                    listbox.show_all ();
                }
            } else if (filter == "tomorrow") {
                foreach (var item in Planner.database.get_items_by_date (new GLib.DateTime.now_local ().add_days (1))) {
                    var row = new Widgets.ItemRow (item, "label");
    
                    listbox.add (row);
                    items_loaded.set (item.id.to_string (), row);
    
                    listbox.show_all ();
                }
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

        Planner.database.item_updated.connect ((item) => {
            update_item (item);
        });

        Planner.database.item_added.connect ((item, index) => {
            if (valid_filter (item)) {
                add_item (item);
            }
        });

        Planner.database.add_due_item.connect ((item) => {
            if (valid_filter (item)) {
                add_item (item);
            }
        });

        Planner.database.update_due_item.connect ((item) => {
            update_item (item);
        });

        Planner.database.remove_due_item.connect ((item) => {
            update_item (item);
        });

        Planner.database.item_deleted.connect ((item) => {
            if (items_loaded.has_key (item.id.to_string ())) {
                items_loaded.get (item.id.to_string ()).hide_destroy ();
                items_loaded.unset (item.id.to_string ());
            }
        });

        magic_button.clicked.connect (() => {
            add_new_item (Planner.settings.get_enum ("new-tasks-position"));
        });
    }

    private void update_item (Objects.Item item) {
        if (items_loaded.has_key (item.id.to_string ())) {
            if (valid_filter (item) == false) {
                items_loaded.get (item.id.to_string ()).hide_destroy ();
                items_loaded.unset (item.id.to_string ());

                if (items_loaded.size > 0) {
                    view_stack.visible_child_name = "listbox";
                } else {
                    view_stack.visible_child_name = "placeholder";
                }
            }
        } else {
            if (valid_filter (item)) {
                add_item (item);
            }
        }
    }

    private void add_item (Objects.Item item) {
        var row = new Widgets.ItemRow (item);

        listbox.add (row);
        items_loaded.set (item.id.to_string (), row);
        listbox.show_all ();
        view_stack.visible_child_name = "listbox";
    }

    public void clear () {
        items_loaded.clear ();
        foreach (unowned Gtk.Widget child in listbox.get_children ()) {
            child.destroy ();
        }
        icon_image.get_style_context ().remove_class ("upcoming-icon");
    }

    private bool valid_filter (Objects.Item item) {
        var returned = false;

        if (filter == "p4") {
            returned = item.priority == 1;
        } else if (filter == "p3") {
            returned = item.priority == 2;
        } else if (filter == "p2") {
            returned = item.priority == 3;
        } else if (filter == "p1") {
            returned = item.priority == 4;
        } else if (filter == "tomorrow") {
            returned = Planner.utils.is_tomorrow (Planner.utils.get_date_with_time_from_string (item.due_date));
        }

        return returned;
    }

    public void hide_items () {
        listbox.foreach ((widget) => {
            var row = (Widgets.ItemRow) widget;
            if (row.reveal_child) {
                row.hide_item ();
            }
        });
    }

    public void add_new_item (int index=-1) {
        var inbox_project = Planner.database.get_project_by_id (Planner.settings.get_int64 ("inbox-project"));

        var new_item = new Widgets.NewItem (
            inbox_project.id,
            0,
            inbox_project.is_todoist,
            "",
            index,
            listbox,
            0
        );
        
        if (index == -1) {
            listbox.add (new_item);
        } else {
            listbox.insert (new_item, index);
        }

        listbox.show_all ();
        view_stack.visible_child_name = "listbox";
    }
}
