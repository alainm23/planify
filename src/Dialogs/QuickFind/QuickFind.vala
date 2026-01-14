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
    private Gtk.ListView list_view;
    private Gtk.ScrolledWindow list_view_scrolled;
    private ListStore list_store;
    private Gtk.FilterListModel filter_model;
    private Gtk.CustomFilter custom_filter;
    private Gtk.SingleSelection selection_model;
    private Gtk.SignalListItemFactory list_item_factory;
    private Gtk.SignalListItemFactory header_factory;
    private Gtk.Stack stack;

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
            placeholder_text = _ ("Quick Find"),
            hexpand = true,
            css_classes = { "border-radius-9" }
        };

        var cancel_button = new Gtk.Button.with_label (_ ("Cancel")) {
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

        list_store = new GLib.ListStore (typeof (QuickFindItem));

        custom_filter = new Gtk.CustomFilter ((obj) => {
            var item = (QuickFindItem) obj;
            if (search_entry.text.strip () == "") {
                return false;
            }

            var matches = item_matches_search (item, search_entry.text.down ());
            return matches;
        });

        filter_model = new Gtk.FilterListModel (list_store, custom_filter) {
            incremental = false
        };

        var sort_model = new Gtk.SortListModel (filter_model, new QuickFindSectionSorter ());
        sort_model.section_sorter = new QuickFindSectionSorter ();

        selection_model = new Gtk.SingleSelection (sort_model);
        list_item_factory = QuickFindFactory.create_list_item_factory ();
        header_factory = QuickFindFactory.create_header_factory ();

        list_view = new Gtk.ListView (selection_model, list_item_factory) {
            hexpand = true,
            vexpand = true,
            css_classes = { "listbox-background" },
            margin_bottom = 6
        };
        list_view.header_factory = header_factory;

        list_view.activate.connect ((position) => {
            var item = selection_model.get_item (position);
            if (item != null) {
                var quick_find_item = (QuickFindItem) item;
                activate_item (quick_find_item);
            }
        });

        list_view_scrolled = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = list_view
        };

        stack = new Gtk.Stack ();
        stack.add_titled (get_placeholder (), "placeholder", "Placeholder");
        stack.add_titled (list_view_scrolled, "list", "List");

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (headerbar);
        toolbar_view.content = stack;

        child = toolbar_view;
        default_widget = search_entry;
        Services.EventBus.get_default ().disconnect_typing_accel ();

        populate_store ();

        search_entry.search_changed.connect (() => {
            search_changed ();
        });

        var click_gesture = new Gtk.GestureClick ();
        click_gesture.pressed.connect (() => {
            var selected = selection_model.get_selected ();
            if (selected != Gtk.INVALID_LIST_POSITION) {
                var item = selection_model.get_item (selected);
                if (item != null) {
                    activate_item ((QuickFindItem) item);
                }
            }
        });
        list_view.add_controller (click_gesture);

        var list_view_controller_key = new Gtk.EventControllerKey ();
        list_view.add_controller (list_view_controller_key);
        list_view_controller_key.key_pressed.connect (key_pressed);

        var search_entry_ctrl_key = new Gtk.EventControllerKey ();
        search_entry.add_controller (search_entry_ctrl_key);
        search_entry_ctrl_key.key_pressed.connect ((keyval, keycode, state) => {
            var key = Gdk.keyval_name (keyval).replace ("KP_", "");

            if (keyval == Gdk.Key.Escape) {
                hide_destroy ();
            } else if (key == "Down") {
                list_view.grab_focus ();
                return true;
            }

            return false;
        });

        var event_controller_key = new Gtk.EventControllerKey ();
        ((Gtk.Widget) this).add_controller (event_controller_key);
        event_controller_key.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == Gdk.Key.Escape) {
                hide_destroy ();
            }

            return false;
        });

        cancel_button.clicked.connect (() => {
            hide_destroy ();
        });

        closed.connect (() => {
            Services.EventBus.get_default ().connect_typing_accel ();
        });
    }

    private bool key_pressed (uint keyval, uint keycode, Gdk.ModifierType state) {
        var key = Gdk.keyval_name (keyval).replace ("KP_", "");

        if (key == "Up") {
            var selected = selection_model.get_selected ();
            if (selected == 0) {
                search_entry.grab_focus ();
                search_entry.set_position (search_entry.text.length);
                return true;
            }
        } else if (key == "Down") {
        } else if (key == "Enter" || key == "Return" || key == "KP_Enter") {
            var selected = selection_model.get_selected ();
            if (selected != Gtk.INVALID_LIST_POSITION) {
                var item = selection_model.get_item (selected);
                if (item != null) {
                    activate_item ((QuickFindItem) item);
                }
            }
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
                    search_entry.insert_text (c.to_string (), - 1, ref pos);
                    search_entry.set_position (pos);
                    return true;
                }
            }
        }

        return false;
    }

    private void search_changed () {
        var n_items = list_store.get_n_items ();
        for (uint i = 0; i < n_items; i++) {
            var item = (QuickFindItem) list_store.get_item (i);
            item.pattern = search_entry.text;
        }

        custom_filter.changed (Gtk.FilterChange.DIFFERENT);

        var has_results = filter_model.get_n_items () > 0;
        stack.set_visible_child_name (has_results ? "list" : "placeholder");

        if (has_results) {
            Idle.add (() => {
                list_view_scrolled.vadjustment.set_value (0);
                return GLib.Source.REMOVE;
            });
        }
    }

    private void populate_store () {
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

        foreach (var obj in filters) {
            var item = new QuickFindItem (obj, "");
            list_store.append (item);
        }

        foreach (var project in Services.Store.instance ().projects) {
            var item = new QuickFindItem (project, "");
            list_store.append (item);
        }

        foreach (var section in Services.Store.instance ().sections) {
            var item = new QuickFindItem (section, "");
            list_store.append (item);
        }

        foreach (var item_obj in Services.Store.instance ().items) {
            if (item_obj.project != null) {
                var item = new QuickFindItem (item_obj, "");
                list_store.append (item);
            }
        }

        foreach (var label in Services.Store.instance ().labels) {
            var item = new QuickFindItem (label, "");
            list_store.append (item);
        }
    }

    private bool item_matches_search (QuickFindItem item, string search_text_lower) {
        var base_object = item.base_object;
        bool matches = false;

        if (base_object.object_type == ObjectType.FILTER) {
            var filter_name = base_object.name.down ();
            matches = search_text_lower in filter_name ||
            search_text_lower in base_object.keywords.down ();
        } else if (base_object is Objects.Item) {
            var item_obj = (Objects.Item) base_object;
            var item_content = item_obj.content.down ();
            matches = search_text_lower in item_content;
        } else {
            matches = search_text_lower in base_object.name.down ();
        }

        return matches;
    }

    private Gtk.Widget get_placeholder () {
        var message_label = new Gtk.Label (_ ("Quickly switch projects and views, find tasks, search by labels")) {
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

    private void activate_item (QuickFindItem item) {
        var base_object = item.base_object;

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
        close ();
    }
}
