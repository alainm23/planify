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

public class Views.Today : Adw.Bin {
    private Layouts.HeaderBar headerbar;
    private Widgets.EventsList event_list;
    private Gtk.ListBox listbox;
    private Gtk.Revealer today_revealer;
    private Gtk.ListBox overdue_listbox;
    private Gtk.Revealer overdue_revealer;
    private Gtk.Revealer event_list_revealer;
    private Gtk.Grid listbox_grid;
    private Gtk.ScrolledWindow scrolled_window;
    private Gtk.Stack listbox_placeholder_stack;

    public Gee.HashMap <string, Layouts.ItemRow> overdue_items;
    public Gee.HashMap <string, Layouts.ItemRow> items;

    public GLib.DateTime date { get; set; default = new GLib.DateTime.now_local (); }

    private bool overdue_has_children {
        get {
            return overdue_items.size > 0;
        }
    }

    private bool today_has_children {
        get {
            return items.size > 0;
        }
    }

    private string today_label = _("Today");

    construct {
        overdue_items = new Gee.HashMap <string, Layouts.ItemRow> ();
        items = new Gee.HashMap <string, Layouts.ItemRow> ();
        
        headerbar = new Layouts.HeaderBar ();

        event_list = new Widgets.EventsList.for_day (date) {
            margin_top = 12
        };

        event_list_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = event_list.has_items,
            child = event_list
        };

        var event_list_clamp = new Adw.Clamp () {
            maximum_size = 1024,
            tightening_threshold = 800,
            margin_start = 24,
            margin_end = 24,
            child = event_list_revealer
        };
        
        event_list.change.connect (() => {
            event_list_revealer.reveal_child = event_list.has_items;
        });

        var overdue_label = new Gtk.Label (_("Overdue")) {
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER,
            hexpand = true
        };

        overdue_label.add_css_class ("font-bold");
        
        var reschedule_button = new Gtk.Button.with_label (_("Reschedule")) {
            hexpand = true,
            halign = Gtk.Align.END
        };

        reschedule_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        var overdue_header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 2
        };
        overdue_header_box.append (overdue_label);

        overdue_listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };

        overdue_listbox.add_css_class ("listbox-background");

        var overdue_listbox_grid = new Gtk.Grid () {
            margin_top = 6
        };

        overdue_listbox_grid.attach (overdue_listbox, 0, 0);

        var overdue_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 6,
            margin_start = 3
        };

        var overdue_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 12,
            margin_start = 2
        };

        overdue_box.append (overdue_header_box);
        overdue_box.append (overdue_separator);
        overdue_box.append (overdue_listbox_grid);

        overdue_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        overdue_revealer.child = overdue_box;

        var today_label = new Gtk.Label (_("Today")) {
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER,
            hexpand = true
        };

        today_label.add_css_class ("font-bold");
        
        var today_header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 2
        };
        today_header_box.append (today_label);

        var today_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_start = 3
        };

        var today_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 12,
            margin_start = 2
        };
        today_box.append (today_header_box);
        today_box.append (today_separator);

        today_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        today_revealer.child = today_box;

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };

        listbox.add_css_class ("listbox-background");

        listbox_grid = new Gtk.Grid () {
            margin_top = 6,
            margin_start = 3
        };

        listbox_grid.attach (listbox, 0, 0);

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content.append (overdue_revealer);
        content.append (today_revealer);
        content.append (listbox_grid);

        var listbox_placeholder = new Widgets.Placeholder (
            _("Press 'a' or tap the plus button to create a new to-do"), "planner-check-circle"
        );

        listbox_placeholder_stack = new Gtk.Stack () {
            vexpand = true,
            hexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        listbox_placeholder_stack.add_named (content, "listbox");
        listbox_placeholder_stack.add_named (listbox_placeholder, "placeholder");

        var content_clamp = new Adw.Clamp () {
            maximum_size = 1024,
            tightening_threshold = 800,
            margin_start = 24,
            margin_end = 24,
            child = listbox_placeholder_stack
        };

        scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        scrolled_window.child = content_clamp;

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content_box.append (event_list_clamp);
        content_box.append (scrolled_window);

        var magic_button = new Widgets.MagicButton ();

		var content_overlay = new Gtk.Overlay () {
			hexpand = true,
			vexpand = true
		};

		content_overlay.child = content_box;
		content_overlay.add_overlay (magic_button);

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (headerbar);
		toolbar_view.content = content_overlay;

        child = toolbar_view;
        update_today_label ();
        add_today_items ();

        Timeout.add (listbox_placeholder_stack.transition_duration, () => {
            check_placeholder ();
            return GLib.Source.REMOVE;
        });

        Services.EventBus.get_default ().day_changed.connect (() => {
            date = new GLib.DateTime.now_local ();
            update_today_label ();
            add_today_items ();
        });

        Services.Database.get_default ().item_added.connect (valid_add_item);
        Services.Database.get_default ().item_deleted.connect (valid_delete_item);
        Services.Database.get_default ().item_updated.connect (valid_update_item);

        Services.EventBus.get_default ().item_moved.connect ((item) => {
            if (items.has_key (item.id_string)) {
                items[item.id_string].update_request ();
            }

            if (overdue_items.has_key (item.id_string)) {
                items[item.id_string].update_request ();
            }
        });

        magic_button.clicked.connect (() => {
            prepare_new_item ();
        });
    }

    private void check_placeholder () {
        if (overdue_has_children || today_has_children) {
            listbox_placeholder_stack.visible_child_name = "listbox";
        } else {
            listbox_placeholder_stack.visible_child_name = "placeholder";
        }
    }

    private void add_today_items () {
        items.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox) ) {
            listbox.remove (child);
        }

        foreach (Objects.Item item in Services.Database.get_default ().get_items_by_date (date, false)) {
            add_item (item);
        }

        overdue_items.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (overdue_listbox) ) {
            overdue_listbox.remove (child);
        }

        foreach (Objects.Item item in Services.Database.get_default ().get_items_by_overdeue_view (false)) {
            add_overdue_item (item);
        }

        update_headers ();
    }

    private void add_item (Objects.Item item) {
        items [item.id_string] = new Layouts.ItemRow (item) {
            show_project_label = true
        };
        listbox.append (items [item.id_string]);
        update_headers ();
        check_placeholder ();
    }

    private void add_overdue_item (Objects.Item item) {
        overdue_items [item.id_string] = new Layouts.ItemRow (item) {
            show_project_label = true
        };
        overdue_listbox.append (overdue_items [item.id_string]);
        update_headers ();
        check_placeholder ();
    }

    private void valid_add_item (Objects.Item item, bool insert = true) {
        if (!items.has_key (item.id_string) &&
            Services.Database.get_default ().valid_item_by_date (item, date, false)) {
            add_item (item);   
        }

        if (!overdue_items.has_key (item.id_string) &&
            Services.Database.get_default ().valid_item_by_overdue (item, date, false)) {
            add_overdue_item (item);
        }

        update_headers ();
        check_placeholder ();
    }

    private void valid_delete_item (Objects.Item item) {
        if (items.has_key (item.id_string)) {
            items[item.id_string].hide_destroy ();
            items.unset (item.id_string);
        }

        if (overdue_items.has_key (item.id_string)) {
            overdue_items[item.id_string].hide_destroy ();
            overdue_items.unset (item.id_string);
        }

        update_headers ();
        check_placeholder ();
    }

    private void valid_update_item (Objects.Item item) {
        if (items.has_key (item.id_string)) {
            items[item.id_string].update_request ();
        }

        if (overdue_items.has_key (item.id_string)) {
            overdue_items[item.id_string].update_request ();
        }

        if (items.has_key (item.id_string) && !item.has_due) {
            items[item.id_string].hide_destroy ();
            items.unset (item.id_string);
        }

        if (overdue_items.has_key (item.id_string) && !item.has_due) {
            overdue_items[item.id_string].hide_destroy ();
            overdue_items.unset (item.id_string);
        }

        if (items.has_key (item.id_string) && item.has_due) {
            if (!Services.Database.get_default ().valid_item_by_date (item, date, false)) {
                items[item.id_string].hide_destroy ();
                items.unset (item.id_string);
            }
        }

        if (overdue_items.has_key (item.id_string) && item.has_due) {
            if (!Services.Database.get_default ().valid_item_by_overdue (item, date, false)) {
                overdue_items[item.id_string].hide_destroy ();
                overdue_items.unset (item.id_string);
            }
        }

        if (item.has_due) {
            valid_add_item (item);
        }

        update_headers ();
        check_placeholder ();
    }

    public void prepare_new_item (string content = "") {
        var inbox_project = Services.Database.get_default ().get_project (
            Services.Settings.get_default ().settings.get_string ("inbox-project-id")
        );

        var dialog = new Dialogs.QuickAdd ();
        dialog.update_content (content);
        dialog.set_project (inbox_project);
        dialog.set_due (Util.get_default ().get_format_date (date));
        dialog.show ();
    }
    
    private void update_headers () {
        if (overdue_has_children) {
            overdue_revealer.reveal_child = true;
            today_revealer.reveal_child = today_has_children;
            listbox_grid.margin_top = 6;
        } else {
            overdue_revealer.reveal_child = false;
            today_revealer.reveal_child = false;
            listbox_grid.margin_top = 12;
        }
    }

    public void update_today_label () {
        var date = new GLib.DateTime.now_local ();
        var date_format = "%s %s".printf (date.format ("%a"),
            date.format (
            Granite.DateTime.get_default_date_format (false, true, false)
        ));
        headerbar.title = "%s <small>%s</small>".printf (today_label, date_format);
    }
}
