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

public class Views.Label : Adw.Bin {
    private Layouts.HeaderBar headerbar;
    private Gtk.ListBox listbox;
    private Gtk.Stack listbox_stack;

    public Gee.HashMap <string, Layouts.ItemRow> items;

    private bool has_items {
        get {
            return items.size > 0;
        }
    }

    Objects.Label _label;
    public Objects.Label label {
        get {
            return _label;
        }

        set {
            _label = value;
            update_request ();
            add_items ();
        }
    }

    construct {
        items = new Gee.HashMap <string, Layouts.ItemRow> ();

        headerbar = new Layouts.HeaderBar ();
        headerbar.back_revealer = true;

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };

        listbox.add_css_class ("listbox-background");

        var listbox_grid = new Gtk.Grid () {
            margin_top = 20
        };

        listbox_grid.attach (listbox, 0, 0);

        var listbox_placeholder = new Widgets.Placeholder (
            _("No to-dos for this filter yet."), "planner-check-circle"
        );

        listbox_stack = new Gtk.Stack () {
            vexpand = true,
            hexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        listbox_stack.add_named (listbox_grid, "listbox");
        listbox_stack.add_named (listbox_placeholder, "placeholder");


        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content.append (listbox_stack);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 1024,
            tightening_threshold = 800,
            margin_start = 24,
            margin_end = 24
        };

        content_clamp.child = content;

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        scrolled_window.child = content_clamp;

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (headerbar);
		toolbar_view.content = scrolled_window;

        child = toolbar_view;

        Timeout.add (listbox_stack.transition_duration, () => {
            validate_placeholder ();
            return GLib.Source.REMOVE;
        });

        Services.Database.get_default ().item_added.connect (valid_add_item);
        Services.Database.get_default ().item_deleted.connect (valid_delete_item);
        Services.Database.get_default ().item_updated.connect (valid_update_item);

        scrolled_window.vadjustment.value_changed.connect (() => {
            if (scrolled_window.vadjustment.value > 50) {
                Services.EventBus.get_default ().view_header (true);
            } else {
                Services.EventBus.get_default ().view_header (false);
            }
        });

        headerbar.back_activated.connect (() => {
            Services.EventBus.get_default ().pane_selected (PaneType.FILTER, FilterType.LABELS.to_string ());
        });
    }

    private void validate_placeholder () {
        listbox_stack.visible_child_name = has_items ? "listbox" : "placeholder";
    }

    private void valid_add_item (Objects.Item item, bool insert = true) {
        if (!items.has_key (item.id_string) && item.labels.has_key (label.id_string)
            && insert) {
            add_item (item);   
        }

        validate_placeholder ();
    }

    private void valid_delete_item (Objects.Item item) {
        if (items.has_key (item.id_string)) {
            items[item.id_string].hide_destroy ();
            items.unset (item.id_string);
        }

        validate_placeholder ();
    }

    private void valid_update_item (Objects.Item item) {
        if (items.has_key (item.id_string) && !item.labels.has_key (label.id_string)) {
            items[item.id_string].hide_destroy ();
            items.unset (item.id_string);
        }

        valid_add_item (item);
    }

    private void add_items () {        
        foreach (Layouts.ItemRow row in items.values) {
            listbox.remove (row);
        }

        items.clear ();

        foreach (Objects.Item item in Services.Database.get_default ().get_items_by_label (label, false)) {
            add_item (item);
        }

        validate_placeholder ();
    }

    private void add_item (Objects.Item item) {
        items [item.id_string] = new Layouts.ItemRow (item) {
            show_project_label = true
        };
        listbox.append (items [item.id_string]);
    }

    public void update_request () { 
        headerbar.title = label.name;
    }
}
