/*
* Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
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

public class Layouts.SectionBoard :  Gtk.FlowBoxChild {
    public Objects.Section section { get; construct; }

    public Gee.HashMap <string, Layouts.ItemBoard> items;
    public Gee.HashMap <string, Layouts.ItemBoard> items_checked;

    private Widgets.EditableLabel name_editable;
    private Gtk.ListBox listbox;
    private Gtk.ListBox checked_listbox;
    private Gtk.Revealer checked_revealer;
    private Widgets.LoadingButton add_button;

    public bool is_inbox_section {
        get {
            return section.id == "";
        }
    }

    public SectionBoard (Objects.Section section) {
        Object (
            section: section,
            focusable: false,
            width_request: 325,
            vexpand: true
        );
    }

    public SectionBoard.for_project (Objects.Project project) {
        var section = new Objects.Section ();
        section.id = "";
        section.project_id = project.id;
        section.name = _("(No Section)");

        Object (
            section: section,
            focusable: false,
            width_request: 325,
            vexpand: true
        );
    }

    construct {
        add_css_class ("row");

        items = new Gee.HashMap <string, Layouts.ItemBoard> ();
        items_checked = new Gee.HashMap <string, Layouts.ItemBoard> ();

        name_editable = new Widgets.EditableLabel () {
            valign = Gtk.Align.CENTER,
            editable = !is_inbox_section
        };

        name_editable.add_style ("font-bold");
        name_editable.text = section.name;

        add_button = new Widgets.LoadingButton.with_icon ("plus", 16);
		add_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        var menu_image = new Widgets.DynamicIcon ();
        menu_image.size = 16;
        menu_image.update_icon_name ("dots-vertical");

        var menu_button = new Gtk.MenuButton () {
            child = menu_image,
            popover = build_context_menu ()
        };
        menu_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            margin_start = 12,
            margin_end = 12
        };

        header_box.append (name_editable);
        header_box.append (add_button);
        header_box.append (menu_button);
        
        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_bottom = 6,
            margin_start = 12,
            margin_end = 12
        };

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true,
        };
        
        listbox.add_css_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin_top = 0
        };

        listbox_grid.attach (listbox, 0, 0);

        checked_listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            selection_mode = Gtk.SelectionMode.NONE,
            hexpand = true
        };

        checked_listbox.add_css_class ("listbox-background");
        checked_listbox.add_css_class ("listbox-separator-3");

        var checked_listbox_grid = new Gtk.Grid ();
        checked_listbox_grid.attach (checked_listbox, 0, 0);

        checked_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = true
        };

        checked_revealer.child = checked_listbox_grid;

        var items_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true,
            margin_start = 12,
            margin_end = 12
        };

        items_box.append (listbox_grid);
        items_box.append (checked_revealer);
        
        var items_scrolled = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = items_box
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content_box.append (header_box);
        content_box.append (separator);
        content_box.append (items_scrolled);

        child = content_box;

        add_items ();
        show_completed_changed ();

        Timeout.add (350, () => {            
            if (section.activate_name_editable) {
                name_editable.editing (true, true);
            }

            check_inbox_visible ();
            return GLib.Source.REMOVE;
        });

        listbox.row_selected.connect ((row) => {
            var item = ((Layouts.ItemBoard) row).item;
        });

        name_editable.changed.connect (() => {
            section.name = name_editable.text;
            section.update ();
        });

        section.updated.connect (() => {
            name_editable.text = section.name;
        });

        Services.Database.get_default ().item_added.connect ((item, insert) => {
            if (item.project_id == section.project_id && item.section_id == section.id && insert) {
                add_item (item);
            }
        });

        //  if (is_inbox_section) {
        //      section.project.item_added.connect ((item) => {
        //          add_item (item);
        //      });
        //  } else {
        //      section.item_added.connect ((item) => {
        //          add_item (item);
        //      });            
        //  }
        
        Services.EventBus.get_default ().checked_toggled.connect ((item, old_checked) => {
            if (item.project_id == section.project_id && item.section_id == section.id &&
                item.parent_id == "") {
                if (!old_checked) {
                    if (items.has_key (item.id_string)) {
                        items [item.id_string].hide_destroy ();
                        items.unset (item.id_string);
                    }

                    if (!items_checked.has_key (item.id_string)) {
                        items_checked [item.id_string] = new Layouts.ItemBoard (item);
                        checked_listbox.insert (items_checked [item.id_string], 0);
                    }
                } else {
                    if (items_checked.has_key (item.id_string)) {
                        items_checked [item.id_string].hide_destroy ();
                        items_checked.unset (item.id_string);
                    }

                    if (!items.has_key (item.id_string)) {
                        items [item.id_string] = new Layouts.ItemBoard (item);
                        listbox.append (items [item.id_string]);
                    }
                }
            }
        });

        Services.Database.get_default ().item_updated.connect ((item, update_id) => {
            if (items.has_key (item.id_string)) {
                items [item.id_string].update_request ();
                update_sort ();
            }

            if (items_checked.has_key (item.id_string)) {
                items_checked [item.id_string].update_request ();
            }
        });

        Services.Database.get_default ().item_deleted.connect ((item) => {
            if (items.has_key (item.id_string)) {
                items [item.id_string].hide_destroy ();
                items.unset (item.id_string);
            }

            if (items_checked.has_key (item.id_string)) {
                items_checked [item.id_string].hide_destroy ();
                items_checked.unset (item.id_string);
            }

            check_inbox_visible ();
        });

        Services.EventBus.get_default ().item_moved.connect ((item, old_project_id, old_section_id, old_parent_id) => {
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
                item.parent_id == "") {
                add_item (item);
            }

            check_inbox_visible ();
        });

        Services.EventBus.get_default ().update_items_position.connect ((project_id, section_id) => {
            if (section.project_id == project_id && section.id == section_id) {
                // update_items_position ();
            }
        });

        section.project.show_completed_changed.connect (show_completed_changed);

        section.project.sort_order_changed.connect (() => {
            update_sort ();
        });

        Services.EventBus.get_default ().update_section_sort_func.connect ((project_id, section_id, value) => {
            if (section.project_id == project_id && section.id == section_id) {
                if (value) {
                    update_sort ();
                } else {
                    listbox.set_sort_func (null);
                }
            }
        });

        section.section_count_updated.connect (() => {
            // count_label.label = section.section_count.to_string ();
            // count_revealer.reveal_child = int.parse (count_label.label) > 0;
        });

        add_button.clicked.connect (() => {
            prepare_new_item ();
        });
    }

    //  void setup_listitem_cb (Gtk.ListItemFactory factory, Gtk.ListItem list_item) {
    //      var row = new Layouts.ItemBoard ();
    //      list_item.set_child (row);
    //  }

    //  void bind_listitem_cb (Gtk.ListItemFactory factory, Gtk.ListItem list_item) {
    //      var item = list_item.get_item () as Objects.Item;
    //      var row = list_item.get_child () as Layouts.ItemBoard;
    //      row.set_item (item);
    //  }

    public void add_items () {
        items.clear ();
        
        foreach (Objects.Item item in is_inbox_section ? section.project.items : section.items) {
            add_item (item);
        }

        update_sort ();
    }

    private void update_sort () {
        if (section.project.sort_order == 0) {
            listbox.set_sort_func (null);
        } else {
            listbox.set_sort_func (set_sort_func);
        }
    }

    private int set_sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
        Objects.Item item1 = ((Layouts.ItemBoard) lbrow).item;
        Objects.Item item2 = ((Layouts.ItemBoard) lbbefore).item;
        
        if (section.project.sort_order == 1) {
            return item1.content.collate (item2.content);
        }
        
        if (section.project.sort_order == 2) {
            if (item1.has_due && item2.has_due) {
                var date1 = item1.due.datetime;
                var date2 = item2.due.datetime;

                return date1.compare (date2);
            }

            if (!item1.has_due && item2.has_due) {
                return 1;
            }

            return 0;
        }
        
        if (section.project.sort_order == 3) {
            return item1.added_datetime.compare (item2.added_datetime);
        }
        
        if (section.project.sort_order == 4) {
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
            foreach (Layouts.ItemBoard row in items_checked.values) {
                row.hide_destroy ();
            }

            items_checked.clear ();
        }

        checked_revealer.reveal_child = section.project.show_completed;
    }

    public void add_completed_items () {
        foreach (Layouts.ItemBoard row in items_checked.values) {
            row.hide_destroy ();
        }

        items_checked.clear ();

        foreach (Objects.Item item in is_inbox_section ? section.project.items : section.items) {
            add_complete_item (item);
        }
    }

    public void add_complete_item (Objects.Item item) {
        if (section.project.show_completed && item.checked) {
            if (!items_checked.has_key (item.id_string)) {
                items_checked [item.id_string] = new Layouts.ItemBoard (item);
                checked_listbox.append (items_checked [item.id_string]);
            }
        }
    }

    public void add_item (Objects.Item item, int position = -1) {
        if (!item.checked && !items.has_key (item.id_string)) {
            items [item.id_string] = new Layouts.ItemBoard (item);

            if (position <= -1) {
                listbox.append (items [item.id_string]);
            } else {
                listbox.insert (items [item.id_string], position);
            }
        }

        check_inbox_visible ();
    }

    private Gtk.Popover build_context_menu () {
        var add_item = new Widgets.ContextMenu.MenuItem (_("Add Task"), "plus");
        var edit_item = new Widgets.ContextMenu.MenuItem (_("Edit Section"), "planner-edit");
        var move_item = new Widgets.ContextMenu.MenuItem (_("Move Section"), "chevron-right");
        var manage_item = new Widgets.ContextMenu.MenuItem (_("Manage Section Order"), "ordered-list-dark");
        var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete Section"), "planner-trash");
        delete_item.add_css_class ("menu-item-danger");
        
        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (add_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());

        if (!is_inbox_section) {
            menu_box.append (edit_item);
        }

        menu_box.append (move_item);
        menu_box.append (manage_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (delete_item);

        var menu_popover = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            position = Gtk.PositionType.BOTTOM
        };

        add_item.clicked.connect (() => {
            menu_popover.popdown ();
            prepare_new_item ();
        });

        edit_item.clicked.connect (() => {
            menu_popover.popdown ();
            name_editable.editing (true);
        });

        move_item.clicked.connect (() => {
            menu_popover.popdown ();

            var dialog = new Dialogs.ProjectPicker.ProjectPicker (PickerType.PROJECTS, section.project.backend_type);
            dialog.project = section.project;
            dialog.show ();

            dialog.changed.connect ((type, id) => {
                if (type == "project") {
                    move_section (id);
                }
            });
        });

        manage_item.clicked.connect (() => {
            menu_popover.popdown ();
            
            var dialog = new Dialogs.ManageSectionOrder (section.project);
            dialog.show ();
        });

        delete_item.clicked.connect (() => {
            menu_popover.popdown ();

            var dialog = new Adw.MessageDialog ((Gtk.Window) Planify.instance.main_window, 
            _("Delete section"), _("Are you sure you want to delete %s?".printf (section.short_name)));

            dialog.add_response ("cancel", _("Cancel"));
            dialog.add_response ("delete", _("Delete"));
            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.show ();

            dialog.response.connect ((response) => {
                if (response == "delete") {
                    if (section.project.backend_type == BackendType.TODOIST) {
                        //  remove_button.is_loading = true;
                        Services.Todoist.get_default ().delete.begin (section, (obj, res) => {
                            Services.Todoist.get_default ().delete.end (res);
                            Services.Database.get_default ().delete_section (section);
                            // remove_button.is_loading = false;
                            // message_dialog.hide_destroy ();
                        });
                    } else {
                        Services.Database.get_default ().delete_section (section);
                    }
                }
            });
        });

        return menu_popover;
    }

    public void prepare_new_item (string content = "") {
        var item = new Objects.Item ();
        item.project_id = section.project_id;
        item.section_id = section.id;
        item.content = _("My new to-do");


        if (item.project.backend_type == BackendType.TODOIST) {
            add_button.is_loading = true;
            Services.Todoist.get_default ().add.begin (item, (obj, res) => {
                add_button.is_loading = false;
                TodoistResponse response = Services.Todoist.get_default ().add.end (res);
                if (response.status) {
                    item.id = response.data;
                    item.activate_name_editable = true;
                    Services.Database.get_default ().insert_item (item, false);
                    add_item (item, 0);
                }
            });
        } else if (item.project.backend_type == BackendType.LOCAL) {
            item.id = Util.get_default ().generate_id (item);
            item.activate_name_editable = true;
            Services.Database.get_default ().insert_item (item, false);
            add_item (item, 0);
        }
    }

    private void move_section (string project_id) {
        string old_section_id = section.project_id;
        section.project_id = project_id;

        if (section.project.backend_type == BackendType.TODOIST) {
            // menu_loading_button.is_loading = true;
            Services.Todoist.get_default ().move_project_section.begin (section, project_id, (obj, res) => {
                if (Services.Todoist.get_default ().move_project_section.end (res).status) {
                    Services.Database.get_default ().move_section (section, old_section_id);
                    // menu_loading_button.is_loading = false;
                } else {
                    // menu_loading_button.is_loading = false;
                }
            });
        } else if (section.project.backend_type == BackendType.LOCAL) {
            Services.Database.get_default ().move_section (section, project_id);
        }
    }

    private void check_inbox_visible () {
        if (is_inbox_section) {
            // visible = items.size > 0;
        }
    }

    public void hide_destroy () {
        visible = false;
        Timeout.add (225, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }
}
