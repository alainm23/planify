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

public class Layouts.SectionRow : Gtk.ListBoxRow {
    public Objects.Section section { get; construct; }

    private Gtk.Button hide_button;
    private Gtk.Revealer hide_revealer;
    private Gtk.Revealer bottom_revealer;
    private Widgets.EditableLabel name_editable;
    private Widgets.LoadingButton menu_loading_button;
    private Gtk.ListBox listbox;
    private Gtk.ListBox checked_listbox;
    private Gtk.Revealer checked_revealer;
    private Gtk.Revealer content_revealer;
    private Gtk.Box handle_grid;
    //  private Gtk.EventBox sectionrow_eventbox;
    private Gtk.Grid placeholder_grid;
    //  private Gtk.EventBox placeholder_eventbox;
    private Gtk.Revealer placeholder_revealer;
    //  private Gtk.Grid content_grid;
    //  private Gtk.Revealer top_motion_revealer;
    //  private Gtk.Revealer bottom_motion_revealer;

    public bool is_inbox_section {
        get {
            return section.id == Constants.INACTIVE;
        }
    }

    public bool has_children {
        get {
            return Util.get_default ().get_children (listbox).length () > 0 ||
            Util.get_default ().get_children (checked_listbox).length () > 0;
        }
    }

    public bool is_creating {
        get {
            return section.id == Constants.INACTIVE;
        }
    }

    public Gee.HashMap <string, Layouts.ItemRow> items;
    public Gee.HashMap <string, Layouts.ItemRow> items_checked;

    public signal void children_size_changed ();

    public SectionRow (Objects.Section section) {
        Object (
            section: section
        );
    }

    public SectionRow.for_project (Objects.Project project) {
        var section = new Objects.Section ();
        section.id = Constants.INACTIVE;
        section.project_id = project.id;
        section.name = _("(No Section)");

        Object (
            section: section
        );
    }

    construct {
        add_css_class ("row");

        items = new Gee.HashMap <string, Layouts.ItemRow> ();
        items_checked = new Gee.HashMap <string, Layouts.ItemRow> ();

        var chevron_right_image = new Widgets.DynamicIcon ();
        chevron_right_image.size = 19;
        chevron_right_image.update_icon_name ("chevron-right"); 

        hide_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        hide_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        hide_button.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        hide_button.add_css_class ("no-padding");
        hide_button.add_css_class ("hidden-button");
        hide_button.child = chevron_right_image;

        if (section.collapsed) {
            hide_button.add_css_class ("opened");
        }

        hide_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            reveal_child = false
        };

        hide_revealer.child = hide_button;

        name_editable = new Widgets.EditableLabel (("New section"), false) {
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_start = 6,
            margin_top = 3
        };

        name_editable.add_css_class ("font-bold");

        name_editable.text = section.name;

        menu_loading_button = new Widgets.LoadingButton (LoadingButtonType.ICON, "content-loading-symbolic") {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.END,
            can_focus = false,
            hexpand = false,
            margin_end = 6
        };

        menu_loading_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        menu_loading_button.add_css_class ("no-padding");
        menu_loading_button.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var name_menu_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        name_menu_grid.append (name_editable);
        name_menu_grid.append (menu_loading_button);
        name_menu_grid.add_css_class ("transition");

        var sectionrow_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        sectionrow_grid.append (hide_revealer);
        sectionrow_grid.append (name_menu_grid);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_start = 26,
            margin_bottom = 6,
            margin_end = 6
        };

        var v_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        v_box.append (sectionrow_grid);
        v_box.append (separator);

        var sectionrow_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = !is_inbox_section
        };

        sectionrow_revealer.child = v_box;

        handle_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        handle_grid.append (sectionrow_revealer);
        handle_grid.add_css_class ("transition");
        //  sectionrow_eventbox = new Gtk.EventBox ();
        //  sectionrow_eventbox.get_style_context ().add_class ("transition");
        //  sectionrow_eventbox.add (handle_grid);

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            selection_mode = Gtk.SelectionMode.NONE,
            hexpand = true,
        };
        
        listbox.add_css_class ("listbox-background");

        if (is_inbox_section) {
            listbox.set_placeholder (get_inbox_placeholder ());
        } else {
            listbox.set_placeholder (get_placeholder ());
        }

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

        var checked_listbox_grid = new Gtk.Grid ();
        checked_listbox_grid.attach (checked_listbox, 0, 0);

        checked_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = section.project.show_completed
        };

        checked_revealer.child = checked_listbox_grid;

        var bottom_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true
        };
        
        bottom_grid.append (listbox_grid);
        bottom_grid.append (checked_revealer);

        bottom_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child =  true // section.collapsed
        };

        bottom_revealer.child = bottom_grid;

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true
        };

        content_box.append (handle_grid);
        content_box.append (bottom_revealer);

        content_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        
        content_revealer.child = content_box;

        child = content_revealer;
        add_items ();


        Timeout.add (content_revealer.transition_duration, () => {
            content_revealer.reveal_child = true;
            
            if (section.activate_name_editable) {
                name_editable.editing (true, true);
            }

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

        //  listbox.add.connect ((widget) => {
        //      children_size_changed ();
        //  });

        //  listbox.remove.connect (() => {
        //      children_size_changed ();
        //  });

        //  checked_listbox.add.connect (() => {
        //      children_size_changed ();
        //  });

        //  checked_listbox.remove.connect (() => {
        //      children_size_changed ();
        //  });

        //  sectionrow_eventbox.button_press_event.connect ((sender, evt) => {
        //      if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
        //          Timeout.add (Constants.DRAG_TIMEOUT, () => {
        //              if (main_revealer.reveal_child) {
        //                  name_editable.editing (true);
        //              }
        //              return GLib.Source.REMOVE;
        //          });
        //      } else if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
        //          build_content_menu ();
        //      }

        //      return Gdk.EVENT_PROPAGATE;
        //  });

        //  sectionrow_eventbox.enter_notify_event.connect ((event) => {
        //      hide_revealer.reveal_child = !is_creating && has_children;
        //      return false;
        //  });

        //  sectionrow_eventbox.leave_notify_event.connect ((event) => {
        //      if (event.detail == Gdk.NotifyType.INFERIOR) {
        //          return false;
        //      }

        //      hide_revealer.reveal_child = false;
        //      return false;
        //  });

        // menu_loading_button.clicked.connect (build_content_menu);

        //  Planner.event_bus.checked_toggled.connect ((item, old_checked) => {
        //      if (item.project_id == section.project_id && item.section_id == section.id &&
        //          item.parent_id == Constants.INACTIVE) {
        //          if (!old_checked) {
        //              if (items.has_key (item.id_string)) {
        //                  items [item.id_string].hide_destroy ();
        //                  items.unset (item.id_string);
        //              }

        //              if (!items_checked.has_key (item.id_string)) {
        //                  items_checked [item.id_string] = new Layouts.ItemRow (item);
        //                  checked_listbox.insert (items_checked [item.id_string], 0);
        //                  checked_listbox.show_all ();
        //              }
        //          } else {
        //              if (items_checked.has_key (item.id_string)) {
        //                  items_checked [item.id_string].hide_destroy ();
        //                  items_checked.unset (item.id_string);
        //              }

        //              if (!items.has_key (item.id_string)) {
        //                  items [item.id_string] = new Layouts.ItemRow (item);
        //                  listbox.add (items [item.id_string]);
        //                  listbox.show_all ();
        //              }
        //          }
        //      }
        //  });

        Services.Database.get_default ().item_updated.connect ((item, update_id) => {
            if (items.has_key (item.id_string)) {
                if (items [item.id_string].update_id != update_id) {
                    items [item.id_string].update_request ();
                    // update_sort ();
                }
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

        Planner.event_bus.update_items_position.connect ((project_id, section_id) => {
            if (section.project_id == project_id && section.id == section_id) {
                // update_items_position ();
            }
        });

        Planner.event_bus.magic_button_activated.connect ((value) => {
            if (!is_inbox_section) {
                // build_placeholder_drag_and_drop (value);
            }
        });

        Planner.event_bus.update_inserted_item_map.connect ((row) => {
            if (row.item.project_id == section.project_id &&
                row.item.section_id == section.id) {
                items [row.item.id_string] = row;
                // update_sort ();
            }
        });

        name_editable.focus_changed.connect ((active) => {
            Planner.event_bus.unselect_all ();

            if (active) {
                hide_revealer.reveal_child = false;
                placeholder_revealer.reveal_child = false;
                name_menu_grid.get_style_context ().add_class ("editable-label-focus");
            } else {
                placeholder_revealer.reveal_child = true;
                name_menu_grid.get_style_context ().remove_class ("editable-label-focus");
            }
        });

        section.project.show_completed_changed.connect (show_completed_changed);

        section.project.sort_order_changed.connect (() => {
            // update_sort ();
        });

        hide_button.clicked.connect (() => {
            section.collapsed = !section.collapsed;
            bottom_revealer.reveal_child = section.collapsed;
            
            if (section.collapsed) {
                hide_button.get_style_context ().add_class ("opened");
            } else {
                hide_button.get_style_context ().remove_class ("opened");
            }

            section.update (false);
        });

        Planner.event_bus.update_section_sort_func.connect ((project_id, section_id, value) => {
            if (section.project_id == project_id && section.id == section_id) {
                if (value) {
                    // update_sort ();
                } else {
                    listbox.set_sort_func (null);
                }
            }
        });
    }

    private void show_completed_changed () {
        if (section.project.show_completed) {
            add_completed_items ();
        } else {
            items_checked.clear ();

            //  foreach (unowned Gtk.Widget child in checked_listbox.get_children ()) {
            //      child.destroy ();
            //  }
        }

        checked_revealer.reveal_child = section.project.show_completed;
    }


    public void add_completed_items () {
        items_checked.clear ();

        //  foreach (unowned Gtk.Widget child in checked_listbox.get_children ()) {
        //      child.destroy ();
        //  }

        foreach (Objects.Item item in is_inbox_section ? section.project.items : section.items) {
            add_complete_item (item);
        }
    }

    public void add_complete_item (Objects.Item item) {
        if (section.project.show_completed && item.checked) {
            if (!items_checked.has_key (item.id_string)) {
                items_checked [item.id_string] = new Layouts.ItemRow (item);
                checked_listbox.append (items_checked [item.id_string]);
                checked_listbox.show ();
            }
        }
    }

    private void update_items_position () {
        Timeout.add (content_revealer.transition_duration, () => {
            Layouts.ItemRow item_row = null;
            var row_index = 0;

            do {
                item_row = (Layouts.ItemRow) listbox.get_row_at_index (row_index);

                if (item_row != null) {
                    item_row.item.child_order = row_index;
                    Services.Database.get_default ().update_child_order (item_row.item);
                }

                row_index++;
            } while (item_row != null);

            return GLib.Source.REMOVE;
        });
    }

    private void update_sort () {
        if (section.project.sort_order == 0) {
            listbox.set_sort_func (null);
        } else {
            listbox.set_sort_func (set_sort_func);
        }
    }

    public void add_items () {
        // items.clear ();

        Gtk.Widget child;
        for (child = listbox.get_first_child (); child != null; child = listbox.get_next_sibling ()) {
            child.destroy ();
        }

        foreach (Objects.Item item in is_inbox_section ? section.project.items : section.items) {
            add_item (item);
        }

        // update_sort ();
    }

    public void add_item (Objects.Item item) {
        if (!item.checked && !items.has_key (item.id_string)) {
            items [item.id_string] = new Layouts.ItemRow (item);
            listbox.append (items [item.id_string]);
            listbox.show ();
        }
    }

    private Gtk.Widget get_inbox_placeholder () {
        placeholder_grid = new Gtk.Grid () {
            margin_start = 20,
            margin_end = 6,
            height_request = 0
        };

        placeholder_grid.add_css_class ("transition");

        var gesture_click = new Gtk.GestureClick ();
        gesture_click.set_button (1);
        placeholder_grid.add_controller (gesture_click);

        placeholder_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = true
        };
        placeholder_revealer.child = placeholder_grid;

        gesture_click.pressed.connect (() => {
            // prepare_new_item ();
        });

        placeholder_revealer.show ();

        return placeholder_revealer;
    }

    private Gtk.Widget get_placeholder () {
        var message_label = new Gtk.Label (_("No tasks available. Create one by dragging the '+' button here or clicking on this space.")) {
            wrap = true,
            justify = Gtk.Justification.CENTER,
            hexpand = true,
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6
        };
        
        message_label.add_css_class ("dim-label");
        message_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        placeholder_grid = new Gtk.Grid () {
            margin_end = 6,
            margin_bottom = 6,
            margin_start = 20,
            margin_top = 0
        };

        placeholder_grid.add_css_class ("transition");
        placeholder_grid.add_css_class ("pane-content");

        placeholder_grid.attach (message_label, 0, 0);

        var gesture_click = new Gtk.GestureClick ();
        gesture_click.set_button (1);
        placeholder_grid.add_controller (gesture_click);

        placeholder_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = true
        };
        placeholder_revealer.child = placeholder_grid;

        gesture_click.pressed.connect (() => {
            // prepare_new_item ();
        });

        placeholder_revealer.show ();

        return placeholder_revealer;
    }

    public void prepare_new_item (string content = "") {
        Planner.event_bus.item_selected (null);

        section.collapsed = true;
        // bottom_revealer.reveal_child = section.collapsed;
            
        if (section.collapsed) {
            // hide_button.get_style_context ().add_class ("opened");
        }

        section.update (false);

        Layouts.ItemRow row;
        if (is_inbox_section) {
            row = new Layouts.ItemRow.for_project (section.project);
        } else {
            row = new Layouts.ItemRow.for_section (section);
        }

        // row.update_content (content);
        // row.update_priority (Util.get_default ().get_default_priority ());

        row.item_added.connect (() => {
            Util.get_default ().item_added (row);
        });
        
        // if (has_children) {
        //     listbox.insert (row, 0);
        // } else {
            listbox.append (row);
        // }
        
        listbox.show ();
    }

    private int set_sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
        Objects.Item item1 = ((Layouts.ItemRow) lbrow).item;
        Objects.Item item2 = ((Layouts.ItemRow) lbbefore).item;
        
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

    public void hide_destroy () {
        content_revealer.reveal_child = false;
        Timeout.add (content_revealer.transition_duration, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}