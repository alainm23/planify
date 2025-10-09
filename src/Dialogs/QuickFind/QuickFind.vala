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

public class Dialogs.QuickFind.QuickFind : Adw.Dialog {
    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox listbox;
    private Gee.ArrayList<Dialogs.QuickFind.QuickFindItem> items = new Gee.ArrayList<Dialogs.QuickFind.QuickFindItem> ();
    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();

    public QuickFind () {
        Object (
            content_width: 425,
            content_height: 350,
            presentation_mode: Adw.DialogPresentationMode.FLOATING
        );
    }

    ~QuickFind () {
        debug ("Destroying Dialogs.QuickFind.QuickFind\n");
    }

    construct {
        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Quick Find"),
            hexpand = true,
            css_classes = { "border-radius-9" }
        };

        var cancel_button = new Gtk.Button.with_label (_("Cancel")) {
            css_classes = { "flat" }
        };

        var headerbar_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6
        };

        headerbar_box.append (search_entry);
        headerbar_box.append (cancel_button);

        var headerbar = new Adw.HeaderBar () {
            title_widget = headerbar_box,
            show_start_title_buttons = false,
            show_end_title_buttons = false,
            css_classes = { "flat" }
        };

        listbox = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true,
            css_classes = { "listbox-background" },
            margin_bottom = 6
        };

        listbox.set_placeholder (get_placeholder ());
        listbox.set_header_func (header_function);

        var listbox_scrolled = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = listbox
        };

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (headerbar);
        toolbar_view.content = listbox_scrolled;

        child = toolbar_view;
        default_widget = search_entry;
        Services.EventBus.get_default ().disconnect_typing_accel ();

        signal_map[search_entry.search_changed.connect (() => {
            search_changed ();
        })] = search_entry;

        var listbox_controller_key = new Gtk.EventControllerKey ();
        listbox.add_controller (listbox_controller_key);
        signal_map[listbox_controller_key.key_pressed.connect (key_pressed)] = listbox_controller_key;

        signal_map[listbox.row_activated.connect ((row) => {
            row_activated (row);
        })] = listbox;

        var search_entry_ctrl_key = new Gtk.EventControllerKey ();
        search_entry.add_controller (search_entry_ctrl_key);
        signal_map[search_entry_ctrl_key.key_pressed.connect ((keyval, keycode, state) => {
            var key = Gdk.keyval_name (keyval).replace ("KP_", "");
            
            if (keyval == 65307) {
                hide_destroy ();
            } else if (key == "Down") {
                listbox.get_row_at_index (0).grab_focus ();
                return true;
            }

            return false;
        })] = search_entry_ctrl_key;

        var event_controller_key = new Gtk.EventControllerKey ();
        ((Gtk.Widget) this).add_controller (event_controller_key);
        signal_map[event_controller_key.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == 65307) {
                hide_destroy ();
            }

            return false;
        })] = event_controller_key;

        signal_map[cancel_button.clicked.connect (() => {
            hide_destroy ();
        })] = cancel_button;

        closed.connect (() => {
            foreach (var entry in signal_map.entries) {
                entry.value.disconnect (entry.key);
            }

            signal_map.clear ();

            Services.EventBus.get_default ().connect_typing_accel ();
        });
    }

    private bool key_pressed (uint keyval, uint keycode, Gdk.ModifierType state) {
        var key = Gdk.keyval_name (keyval).replace ("KP_", "");

        if (key == "Up") {
            var selected_row = listbox.get_selected_row ();
            
            if (selected_row != null) {
                Gtk.ListBoxRow first_visible_row = null;
                int index = 0;
                while (true) {
                    var row = listbox.get_row_at_index (index);
                    if (row == null) break;
                    if (row.get_child_visible ()) {
                        first_visible_row = row;
                        break;
                    }
                    index++;
                }
                
                if (first_visible_row != null && selected_row == first_visible_row) {
                    search_entry.grab_focus ();
                    search_entry.set_position (search_entry.text.length);
                    return true;
                }
            }
        } else if (key == "Down") {
        } else if (key == "Enter" || key == "Return" || key == "KP_Enter") {
        } else if (key == "BackSpace") {
            if (!search_entry.has_focus && search_entry.text.length > 0) {
                search_entry.grab_focus ();
                int pos = search_entry.text.length;
                search_entry.delete_text (pos - 1, pos);
                search_entry.set_position (pos - 1);
                return true;
            }
        } else {
            if (!search_entry.has_focus) {
                unichar c = Gdk.keyval_to_unicode (keyval);
                if (c.isprint ()) {
                    search_entry.grab_focus ();
                    int pos = search_entry.text.length;
                    search_entry.insert_text (c.to_string (), -1, ref pos);
                    search_entry.set_position (pos);
                    return true;
                }
            }
        }

        return false;
    }

    private void search_changed () {
        if (search_entry.text.strip () != "") {
            clean_results ();
            search ();
        } else {
            clean_results ();
        }
    }

    private void search () {
        Objects.BaseObject[] filters = {
            Objects.Filters.Inbox.get_default (),
            Objects.Filters.Today.get_default (),
            Objects.Filters.Scheduled.get_default (),
            Objects.Filters.Pinboard.get_default (),
            Objects.Filters.Priority.high (),
            Objects.Filters.Priority.medium (),
            Objects.Filters.Priority.low (),
            Objects.Filters.Priority.none (),
            Objects.Filters.Labels.get_default (),
            Objects.Filters.Completed.get_default (),
            Objects.Filters.Tomorrow.get_default (),
            Objects.Filters.Anytime.get_default (),
            Objects.Filters.Repeating.get_default (),
            Objects.Filters.Unlabeled.get_default (),
            Objects.Filters.AllItems.get_default ()
        };

        foreach (Objects.BaseObject object in filters) {
            if (search_entry.text.down () in object.name.down () || search_entry.text.down () in object.keywords.down ()) {
                var row = new Dialogs.QuickFind.QuickFindItem (object, search_entry.text);
                listbox.append (row);
                items.add (row);
            }
        }

        foreach (Objects.Project project in Services.Store.instance ().get_all_projects_by_search (search_entry.text)) {
            var row = new Dialogs.QuickFind.QuickFindItem (project, search_entry.text);
            listbox.append (row);
            items.add (row);
        }

        foreach (Objects.Section section in Services.Store.instance ().get_all_sections_by_search (search_entry.text)) {
            var row = new Dialogs.QuickFind.QuickFindItem (section, search_entry.text);
            listbox.append (row);
            items.add (row);
        }

        foreach (Objects.Item item in Services.Store.instance ().get_all_items_by_search (search_entry.text)) {
            if (item.project != null) {
                var row = new Dialogs.QuickFind.QuickFindItem (item, search_entry.text);
                listbox.append (row);
                items.add (row);
            }
        }

        foreach (Objects.Label label in Services.Store.instance ().get_all_labels_by_search (search_entry.text)) {
            var row = new Dialogs.QuickFind.QuickFindItem (label, search_entry.text);
            listbox.append (row);
            items.add (row);
        }
    }

    private Gtk.Widget get_placeholder () {
        var message_label = new Gtk.Label (_("Quickly switch projects and views, find tasks, search by labels")) {
            wrap = true,
            justify = Gtk.Justification.CENTER,
            hexpand = true,
            vexpand = true,
            margin_top = 6,
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 6
        };

        var placeholder_grid = new Gtk.Grid () {
            hexpand = true,
            vexpand = true,
            margin_top = 24,
            margin_start = 24,
            margin_end = 24,
            margin_bottom = 24
        };

        placeholder_grid.attach (message_label, 0, 0);

        return placeholder_grid;
    }

    private void row_activated (Gtk.ListBoxRow row) {
        var base_object = ((Dialogs.QuickFind.QuickFindItem) row).base_object;

        if (base_object.object_type == ObjectType.PROJECT) {
            Services.EventBus.get_default ().pane_selected (PaneType.PROJECT, base_object.id_string);
        } else if (base_object.object_type == ObjectType.SECTION) {
            Services.EventBus.get_default ().pane_selected (PaneType.PROJECT,
                                                            ((Objects.Section) base_object).project_id.to_string ()
            );
        } else if (base_object.object_type == ObjectType.ITEM) {
            Services.EventBus.get_default ().pane_selected (PaneType.PROJECT,
                                                            ((Objects.Item) base_object).project_id.to_string ()
            );

            Timeout.add (275, () => {
                Services.EventBus.get_default ().open_item ((Objects.Item) base_object);
                return GLib.Source.REMOVE;
            });
        } else if (base_object.object_type == ObjectType.LABEL) {
            Services.EventBus.get_default ().pane_selected (PaneType.LABEL,
                                                            ((Objects.Label) base_object).id_string
            );
        } else if (base_object.object_type == ObjectType.FILTER) {
            Services.EventBus.get_default ().pane_selected (PaneType.FILTER, base_object.view_id);
        }

        hide_destroy ();
    }

    private void hide_destroy () {
        listbox.set_header_func (null);
        close ();
    }

    private void clean_results () {
        foreach (Dialogs.QuickFind.QuickFindItem item in items) {
            item.hide_destroy ();
        }

        items.clear ();
    }

    private void header_function (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow ? lbbefore) {
        var row = (Dialogs.QuickFind.QuickFindItem) lbrow;

        if (lbbefore != null) {
            var before = (Dialogs.QuickFind.QuickFindItem) lbbefore;
            if (row.base_object.object_type == before.base_object.object_type) {
                return;
            }
        }

        var header_label = new Gtk.Label (row.base_object.object_type.get_header ()) {
            css_classes = { "caption", "font-bold" },
            halign = Gtk.Align.START,
            margin_start = 12,
            margin_bottom = 6,
            margin_top = 6
        };

        row.set_header (header_label);
    }
}
