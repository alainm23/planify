
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

public class Layouts.SectionBoard : Gtk.FlowBoxChild {
    public Objects.Section section { get; construct; }

    private Gtk.ListBox listbox;
    private Gtk.ListBox checked_listbox;
    private Gtk.Revealer checked_revealer;

    public Gee.HashMap <string, Layouts.ItemCard> items;
    public Gee.HashMap <string, Layouts.ItemCard> items_checked;

    public bool is_inbox_section {
        get {
            return section.id == Constants.INACTIVE;
        }
    }

    public SectionBoard (Objects.Section section) {
        Object (
            section: section,
            width_request: 275,
            vexpand: true,
            can_focus: false
        );
    }

    construct {
        get_style_context ().add_class ("row");

        items = new Gee.HashMap <string, Layouts.ItemCard> ();
        items_checked = new Gee.HashMap <string, Layouts.ItemCard> ();

        var name_editable = new Widgets.EditableLabel ("font-bold", _("New section"), true) {
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_start = 6,
            margin_top = 3,
            margin_bottom = 3
        };

        name_editable.text = section.name;

        var add_button = new Widgets.LoadingButton (LoadingButtonType.ICON, "planner-plus-circle") {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END,
            can_focus = false,
            hexpand = false,
            margin_end = 6
        };
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        add_button.get_style_context ().add_class ("no-padding");
        add_button.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var menu_button = new Widgets.LoadingButton (LoadingButtonType.ICON, "content-loading-symbolic") {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END,
            can_focus = false,
            hexpand = false,
            margin_end = 6
        };
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        menu_button.get_style_context ().add_class ("no-padding");
        menu_button.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var top_grid = new Gtk.Grid () {
            hexpand = true,
            margin = 6,
            margin_bottom = 0,
            column_spacing = 3
        };

        top_grid.add (name_editable);
        top_grid.add (add_button);
        top_grid.add (menu_button);
        top_grid.get_style_context ().add_class ("transition");

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };

        listbox.get_style_context ().add_class ("picker-bg");
        listbox.get_style_context ().add_class ("listbox-separator-3");

        var listbox_grid = new Gtk.Grid () {
            margin = 9,
            margin_bottom = 3
        };
        listbox_grid.add (listbox);

        checked_listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };

        unowned Gtk.StyleContext checked_listbox_context = checked_listbox.get_style_context ();
        checked_listbox_context.add_class ("listbox-background");

        var checked_listbox_grid = new Gtk.Grid () {
            margin = 9,
            margin_top = 0
        };
        checked_listbox_grid.add (checked_listbox);

        checked_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = section.project.show_completed
        };

        checked_revealer.add (checked_listbox_grid);

        var content_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            hexpand = true
        };
        
        content_grid.add (listbox_grid);
        content_grid.add (checked_revealer);

        var scrolled_window = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        scrolled_window.add (content_grid);

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            hexpand = true
        };

        main_grid.get_style_context ().add_class ("section-board");

        main_grid.add (top_grid);
        main_grid.add (scrolled_window);

        add (main_grid);
        add_items ();
        show_completed_changed ();

        Timeout.add (225, () => {
            update_sort ();
            return GLib.Source.REMOVE;
        });

        name_editable.changed.connect (() => {
            section.name = name_editable.text;
            section.update ();
        });

        section.updated.connect (() => {
            name_editable.text = section.name;
        });


        if (is_inbox_section) {
            section.project.item_added.connect ((item) => {
                add_item (item);
            });
        } else {
            section.item_added.connect ((item) => {
                add_item (item);
            });            
        }

        Planner.event_bus.checked_toggled.connect ((item, old_checked) => {
            if (item.project_id == section.project_id && item.section_id == section.id &&
                item.parent_id == Constants.INACTIVE) {
                if (!old_checked) {
                    if (items.has_key (item.id_string)) {
                        items [item.id_string].hide_destroy ();
                        items.unset (item.id_string);
                    }

                    if (!items_checked.has_key (item.id_string)) {
                        //  items_checked [item.id_string] = new Layouts.ItemCard (item);
                        //  checked_listbox.insert (items_checked [item.id_string], 0);
                        //  checked_listbox.show_all ();
                    }
                } else {
                    if (items_checked.has_key (item.id_string)) {
                        items_checked [item.id_string].hide_destroy ();
                        items_checked.unset (item.id_string);
                    }

                    if (!items.has_key (item.id_string)) {
                        items [item.id_string] = new Layouts.ItemCard (item);
                        listbox.add (items [item.id_string]);
                        listbox.show_all ();
                    }
                }
            }
        });

        Planner.database.item_updated.connect ((item, update_id) => {
            if (items.has_key (item.id_string)) {
                items [item.id_string].update_request ();
                update_sort ();
            }

            if (items_checked.has_key (item.id_string)) {
                items_checked [item.id_string].update_request ();
            }
        });

        Planner.database.item_deleted.connect ((item) => {
            if (items.has_key (item.id_string)) {
                items [item.id_string].hide_destroy ();
                items.unset (item.id_string);
            }

            if (items_checked.has_key (item.id_string)) {
                items_checked [item.id_string].hide_destroy ();
                items_checked.unset (item.id_string);
            }
        });

        Planner.event_bus.item_moved.connect ((item, old_project_id, old_section_id, old_parent_id, insert) => {
            if (old_project_id == section.project_id && old_section_id == section.id) {
                if (items.has_key (item.id_string)) {
                    items [item.id_string].hide_destroy ();
                    items.unset (item.id_string);
                }

                if (items_checked.has_key (item.id_string)) {
                    items_checked [item.id_string].hide_destroy ();
                    items_checked.unset (item.id_string);
                }
            }

            if (item.project_id == section.project_id && item.section_id == section.id &&
                item.parent_id == Constants.INACTIVE) {
                add_item (item);
            }
        });

        section.project.show_completed_changed.connect (show_completed_changed);

        section.project.sort_order_changed.connect (() => {
            update_sort ();
        });
    }

    private void update_sort () {
        if (section.project.sort_order == 0) {
            listbox.set_sort_func (null);
        } else {
            listbox.set_sort_func (set_sort_func);
        }
    }

    private int set_sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
        Objects.Item item1 = ((Layouts.ItemRow) lbrow).item;
        Objects.Item item2 = ((Layouts.ItemRow) lbbefore).item;

        if (section.project.sort_order == 1) {
            return item1.content.collate (item2.content);
        } else if (section.project.sort_order == 2) {
            if (item1.has_due && item2.has_due) {
                var date1 = item1.due.datetime;
                var date2 = item2.due.datetime;

                return date1.compare (date2);
            }

            if (!item1.has_due && item2.has_due) {
                return 1;
            }

            return 0;
        } else if (section.project.sort_order == 3) {
            return item1.added_datetime.compare (item2.added_datetime);
        } else if (section.project.sort_order == 4) {
            if (item1.priority < item2.priority) {
                return 1;
            }

            if (item1.priority < item2.priority) {
                return -1;
            }

            return 0;
        }

        return 0;
    }

    private void show_completed_changed () {
        if (section.project.show_completed) {
            add_completed_items ();
        } else {
            items_checked.clear ();

            foreach (unowned Gtk.Widget child in checked_listbox.get_children ()) {
                child.destroy ();
            }
        }

        checked_revealer.reveal_child = section.project.show_completed;
    }

    public void add_completed_items () {
        items_checked.clear ();

        foreach (unowned Gtk.Widget child in checked_listbox.get_children ()) {
            child.destroy ();
        }

        foreach (Objects.Item item in is_inbox_section ? section.project.items : section.items) {
            add_complete_item (item);
        }
    }

    public void add_complete_item (Objects.Item item) {
        if (section.project.show_completed && item.checked) {
            if (!items_checked.has_key (item.id_string)) {
                items_checked [item.id_string] = new Layouts.ItemCard (item);
                checked_listbox.add (items_checked [item.id_string]);
                checked_listbox.show_all ();
            }
        }
    }

    public void add_items () {
        items.clear ();

        foreach (unowned Gtk.Widget child in listbox.get_children ()) {
            child.destroy ();
        }

        foreach (Objects.Item item in is_inbox_section ? section.project.items : section.items) {
            add_item (item);
        }
    }

    public void add_item (Objects.Item item) {
        if (!item.checked && !items.has_key (item.id_string)) {
            items [item.id_string] = new Layouts.ItemCard (item);
            listbox.add (items [item.id_string]);
            listbox.show_all ();
        }
    }
}