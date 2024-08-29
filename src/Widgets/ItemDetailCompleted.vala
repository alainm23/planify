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

public class Widgets.ItemDetailCompleted : Adw.Bin {
    public Objects.Item item { get; construct; }

    private Gtk.ListBox listbox;

    public signal void view_item (Objects.Item item);
    private Gee.HashMap <string, Widgets.CompletedTaskRow> items_checked = new Gee.HashMap <string, Widgets.CompletedTaskRow> ();
    private Gee.HashMap<ulong, weak GLib.Object> signals_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public ItemDetailCompleted (Objects.Item item) {
        Object (
            item: item
        );
    }

    ~ItemDetailCompleted () {
        print ("Destroying Widgets.ItemDetailCompleted\n");
    }

    construct {
        var content_textview = new Widgets.TextView () {
            left_margin = 12,
            right_margin = 12,
            top_margin = 12,
            bottom_margin = 12,
            height_request = 64,
            wrap_mode = Gtk.WrapMode.WORD,
            event_focus = false
        };

        content_textview.remove_css_class ("view");
        content_textview.add_css_class ("card");
        content_textview.buffer.text = item.content;
        content_textview.editable = false;

        var content_group = new Adw.PreferencesGroup () {
            margin_start = 12,
            margin_end = 12
        };
		content_group.title = _("Title");
        content_group.add (content_textview);

        var properties_grid = new Gtk.Grid () {
            column_homogeneous = true,
            column_spacing = 12,
            row_homogeneous = true,
            row_spacing = 12
        };

        properties_grid.attach (add_property_card ("month-symbolic", _("Completed At"),
            Utils.Datetime.get_relative_date_from_date (
                Utils.Datetime.get_date_from_string (item.completed_at)
            )
        ), 0, 0);

        properties_grid.attach (add_property_card ("arrow3-right-symbolic", _("Section"), item.has_section ? item.section.name : _("No Section")), 1, 0);
        
        properties_grid.attach (add_property_card ("flag-outline-thick-symbolic", _("Priority"), item.priority_text), 0, 1);

        var properties_group = new Adw.PreferencesGroup () {
            margin_start = 12,
            margin_end = 12,
            margin_top = 12
        };
        
		properties_group.title = _("Properties");
        properties_group.add (properties_grid);

        var current_buffer = new Widgets.Markdown.Buffer ();
        current_buffer.text = item.description;

        var markdown_edit_view = new Widgets.Markdown.EditView () {
            card = true,
            left_margin = 12,
            right_margin = 12,
            top_margin = 12,
            bottom_margin = 12
        };

        markdown_edit_view.buffer = current_buffer;
        markdown_edit_view.is_editable = false;

        var description_group = new Adw.PreferencesGroup () {
            margin_start = 12,
            margin_end = 12,
            margin_top = 12
        };
		description_group.title = _("Description");
        description_group.add (markdown_edit_view);

        listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = START,
            css_classes = { "listbox-background", "listbox-separator-6" }
        };

        var subitems_group = new Adw.PreferencesGroup () {
            margin_start = 12,
            margin_end = 12,
            margin_top = 12
        };
        
		subitems_group.title = _("Sub-tasks");
        subitems_group.add (listbox);

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.START,
            margin_bottom = 24,
            margin_start = 12,
            margin_end = 12
        };

        content.append (content_group);
        content.append (properties_group);
        content.append (description_group);

        if (item.items.size > 0) {
            content.append (subitems_group);
        }
        
        var scrolled_window = new Widgets.ScrolledWindow (content);

        child = scrolled_window;
        add_items ();

        signals_map[Services.EventBus.get_default ().checked_toggled.connect ((_item, old_checked) => {
            if (_item.parent_id != item.id) {
                return;
            }

            if (!old_checked) {
                if (!items_checked.has_key (_item.id)) {
                    items_checked [_item.id] = new Widgets.CompletedTaskRow (_item);
                    listbox.append (items_checked [_item.id]);
                }
            } else {
                if (items_checked.has_key (_item.id)) {
                    items_checked [_item.id].hide_destroy ();
                    items_checked.unset (_item.id);
                }
            }
		})] = Services.EventBus.get_default ();
        
        signals_map[listbox.row_activated.connect ((row) => {
            Objects.Item item = ((Widgets.CompletedTaskRow) row).item;
            view_item (item);
        })] = listbox;

        destroy.connect (() => {
            foreach (var entry in signals_map.entries) {
                entry.value.disconnect (entry.key);
            }
            
            signals_map.clear ();
        });
    }

    private void add_items () {
        foreach (Objects.Item subitem in item.items) {
            if (!subitem.checked) {
                continue;
            }

            if (!items_checked.has_key (subitem.id)) {
                items_checked [subitem.id] = new Widgets.CompletedTaskRow (subitem);
                listbox.append (items_checked [subitem.id]);
            }
        }
    }

    private Gtk.Widget add_property_card (string icon_name, string title, string value) {
        var card_grid = new Gtk.Grid () {
            column_spacing = 12,
            margin_start = 12,
            margin_end = 6,
            margin_top = 6,
            margin_bottom = 6,
            vexpand = true,
            hexpand = true
        };
        card_grid.attach (new Gtk.Image.from_icon_name (icon_name), 0, 0, 1, 2);

        card_grid.attach (new Gtk.Label (title) {
            halign = START,
            css_classes = { "title-4", "caption" }
        }, 1, 0, 1, 1);
        
        card_grid.attach (new Gtk.Label (value) {
            xalign = 0,
            use_markup = true,
            halign = START,
            ellipsize = Pango.EllipsizeMode.END,
            css_classes = { "caption" }
        }, 1, 1, 1, 1);

        var card = new Adw.Bin () {
            child = card_grid,
            css_classes = { "card" }
        };

        return card;
    }
}