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
    private Gtk.Revealer indicator_revealer;
    private Widgets.ContextMenu.MenuCheckPicker priority_filter;

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
        
        var indicator_grid = new Gtk.Grid () {
			width_request = 9,
			height_request = 9,
			margin_top = 6,
			margin_end = 6,
			css_classes = { "indicator" }
		};

        indicator_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = indicator_grid,
			halign = END,
			valign = START,
			sensitive = false,
        };

        var view_setting_button = new Gtk.MenuButton () {
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
            margin_end = 12,
			popover = build_view_setting_popover (),
			icon_name = "view-sort-descending-rtl-symbolic",
			css_classes = { "flat" },
			tooltip_text = _("View Option Menu")
		};

		var view_setting_overlay = new Gtk.Overlay ();
		view_setting_overlay.child = view_setting_button;
		view_setting_overlay.add_overlay (indicator_revealer);

        headerbar = new Layouts.HeaderBar ();
        headerbar.pack_end (view_setting_overlay);

        event_list = new Widgets.EventsList.for_day (date) {
            margin_top = 12,
            margin_start = 24
        };

        event_list_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = event_list.has_items,
            child = event_list
        };

        var filters = new Widgets.FilterFlowBox (Objects.Filters.Today.get_default ()) {
            valign = Gtk.Align.START,
            vexpand = false,
            vexpand_set = true
        };

        filters.flowbox.margin_start = 24;
        filters.flowbox.margin_top = 12;
        filters.flowbox.margin_end = 12;
        filters.flowbox.margin_bottom = 3;

        var overdue_label = new Gtk.Label (_("Overdue")) {
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER,
            hexpand = true
        };

        overdue_label.add_css_class ("font-bold");

        var reschedule_button = new Widgets.ScheduleButton (_("Reschedule")) {
            visible_clear_button = false,
            visible_no_date = true
        };

        var overdue_header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_start = 26,
        };
        overdue_header_box.append (overdue_label);
        overdue_header_box.append (reschedule_button);

        overdue_listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true,
            css_classes = { "listbox-background" }
        };
        overdue_listbox.set_sort_func (set_sort_func);

        var overdue_listbox_grid = new Gtk.Grid () {
            margin_top = 6
        };

        overdue_listbox_grid.attach (overdue_listbox, 0, 0);

        var overdue_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 6,
            margin_start = 24
        };

        var overdue_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 12
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
            margin_start = 26
        };
        today_header_box.append (today_label);

        var today_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_start = 24
        };

        var today_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 12
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
            hexpand = true,
            css_classes = { "listbox-background" }
        };
        listbox.set_sort_func (set_sort_func);

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

        var listbox_placeholder = new Adw.StatusPage ();
        listbox_placeholder.icon_name = "check-round-outline-symbolic";
        listbox_placeholder.title = _("Add Some Tasks");
        listbox_placeholder.description = _("Press a to create a new task");

        listbox_placeholder_stack = new Gtk.Stack () {
            vexpand = true,
            hexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        listbox_placeholder_stack.add_named (content, "listbox");
        listbox_placeholder_stack.add_named (listbox_placeholder, "placeholder");

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content_box.append (event_list_revealer);
        content_box.append (filters);
        content_box.append (listbox_placeholder_stack);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 1024,
            tightening_threshold = 800,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 64,
            child = content_box
        };

        scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        scrolled_window.child = content_clamp;

        var magic_button = new Widgets.MagicButton ();

		var content_overlay = new Gtk.Overlay () {
			hexpand = true,
			vexpand = true
		};

		content_overlay.child = scrolled_window;
		content_overlay.add_overlay (magic_button);

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (headerbar);
		toolbar_view.content = content_overlay;

        child = toolbar_view;
        update_today_label ();
        add_today_items ();
        check_default_view ();

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
        Services.Database.get_default ().item_archived.connect (valid_delete_item);
        Services.Database.get_default ().item_unarchived.connect (valid_add_item);

        Services.EventBus.get_default ().item_moved.connect ((item) => {
            if (items.has_key (item.id)) {
                items[item.id].update_request ();
            }

            if (overdue_items.has_key (item.id)) {
                items[item.id].update_request ();
            }

            listbox.invalidate_filter ();
        });

        magic_button.clicked.connect (() => {
            prepare_new_item ();
        });

        event_list.change.connect (() => {
            event_list_revealer.reveal_child = event_list.has_items;
        });

        Services.Settings.get_default ().settings.changed["today-sort-order"].connect (() => {
            listbox.invalidate_sort ();
            overdue_listbox.invalidate_sort ();
            check_default_view ();
        });

        listbox.set_filter_func ((row) => {
			var item = ((Layouts.ItemRow) row).item;
			bool return_value = true;

			if (Objects.Filters.Today.get_default ().filters.size <= 0) {
				return true;
			}

			return_value = false;
			foreach (Objects.Filters.FilterItem filter in Objects.Filters.Today.get_default ().filters.values) {
				if (filter.filter_type == FilterItemType.PRIORITY) {
					return_value = return_value || item.priority == int.parse (filter.value);
				} else if (filter.filter_type == FilterItemType.LABEL) {
					return_value = return_value || item.has_label (filter.value);
				}
			}

			return return_value;
		});

        overdue_listbox.set_filter_func ((row) => {
			var item = ((Layouts.ItemRow) row).item;
			bool return_value = true;

			if (Objects.Filters.Today.get_default ().filters.size <= 0) {
				return true;
			}

			return_value = false;
			foreach (Objects.Filters.FilterItem filter in Objects.Filters.Today.get_default ().filters.values) {
				if (filter.filter_type == FilterItemType.PRIORITY) {
					return_value = return_value || item.priority == int.parse (filter.value);
				} else if (filter.filter_type == FilterItemType.LABEL) {
					return_value = return_value || item.has_label (filter.value);
				}
			}

			return return_value;
		});

        Objects.Filters.Today.get_default ().filter_added.connect (() => {
			listbox.invalidate_filter ();
            overdue_listbox.invalidate_filter ();
		});

		Objects.Filters.Today.get_default ().filter_removed.connect (() => {
			listbox.invalidate_filter ();
            overdue_listbox.invalidate_filter ();
		});

	    Objects.Filters.Today.get_default ().filter_updated.connect (() => {
			listbox.invalidate_filter ();
            overdue_listbox.invalidate_filter ();
		});

        reschedule_button.date_changed.connect ((datetime) => {
            foreach (unowned Gtk.Widget child in Util.get_default ().get_children (overdue_listbox) ) {
                ((Layouts.ItemRow) child).update_due (datetime);
            }
        });
    }

    private void check_placeholder () {
        if (overdue_has_children || today_has_children) {
            listbox_placeholder_stack.visible_child_name = "listbox";
        } else {
            listbox_placeholder_stack.visible_child_name = "placeholder";
        }

        listbox.invalidate_sort ();
        overdue_listbox.invalidate_sort ();
        check_default_view ();
    }

    private void add_today_items () {
        overdue_items.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (overdue_listbox) ) {
            overdue_listbox.remove (child);
        }

        foreach (Objects.Item item in Services.Database.get_default ().get_items_by_overdeue_view (false)) {
            add_overdue_item (item);
        }

        items.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox) ) {
            listbox.remove (child);
        }

        foreach (Objects.Item item in Services.Database.get_default ().get_items_by_date (date, false)) {
            add_item (item);
        }

        update_headers ();
    }

    private void add_item (Objects.Item item) {
        items [item.id] = new Layouts.ItemRow (item);
        items [item.id].disable_drag_and_drop ();
        listbox.append (items [item.id]);
        update_headers ();
        check_placeholder ();
        listbox.invalidate_filter ();
        overdue_listbox.invalidate_filter ();
    }

    private void add_overdue_item (Objects.Item item) {
        overdue_items [item.id] = new Layouts.ItemRow (item);
        overdue_items [item.id].disable_drag_and_drop ();
        overdue_listbox.append (overdue_items [item.id]);
        update_headers ();
        check_placeholder ();
        listbox.invalidate_filter ();
        overdue_listbox.invalidate_filter ();
    }

    private void valid_add_item (Objects.Item item) {
        if (!items.has_key (item.id) &&
            Services.Database.get_default ().valid_item_by_date (item, date, false)) {
            add_item (item);   
        }

        if (!overdue_items.has_key (item.id) &&
            Services.Database.get_default ().valid_item_by_overdue (item, date, false)) {
            add_overdue_item (item);
        }

        update_headers ();
        check_placeholder ();
        listbox.invalidate_filter ();
        overdue_listbox.invalidate_filter ();
    }

    private void valid_delete_item (Objects.Item item) {
        if (items.has_key (item.id)) {
            items[item.id].hide_destroy ();
            items.unset (item.id);
        }

        if (overdue_items.has_key (item.id)) {
            overdue_items[item.id].hide_destroy ();
            overdue_items.unset (item.id);
        }

        update_headers ();
        check_placeholder ();
        listbox.invalidate_filter ();
        overdue_listbox.invalidate_filter ();
    }

    private void valid_update_item (Objects.Item item) {
        if (items.has_key (item.id)) {
            items[item.id].update_request ();
        }

        if (overdue_items.has_key (item.id)) {
            overdue_items[item.id].update_request ();
        }

        if (items.has_key (item.id) && !item.has_due) {
            items[item.id].hide_destroy ();
            items.unset (item.id);
        }

        if (overdue_items.has_key (item.id) && !item.has_due) {
            overdue_items[item.id].hide_destroy ();
            overdue_items.unset (item.id);
        }

        if (items.has_key (item.id) && item.has_due) {
            if (!Services.Database.get_default ().valid_item_by_date (item, date, false)) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }
        }

        if (overdue_items.has_key (item.id) && item.has_due) {
            if (!Services.Database.get_default ().valid_item_by_overdue (item, date, false)) {
                overdue_items[item.id].hide_destroy ();
                overdue_items.unset (item.id);
            }
        }

        if (item.has_due) {
            valid_add_item (item);
        }

        update_headers ();
        check_placeholder ();
        listbox.invalidate_filter ();
        overdue_listbox.invalidate_filter ();
    }

    public void prepare_new_item (string content = "") {
        var inbox_project = Services.Database.get_default ().get_project (
            Services.Settings.get_default ().settings.get_string ("local-inbox-project-id")
        );

        var dialog = new Dialogs.QuickAdd ();
        dialog.update_content (content);
        dialog.set_project (inbox_project);
        dialog.set_due (Utils.Datetime.get_format_date (date));
        dialog.present (Planify._instance.main_window);
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
        headerbar.title = "%s   <small>%s</small>".printf (today_label, date_format);
    }

    private Gtk.Popover build_view_setting_popover () {
		var order_by_model = new Gee.ArrayList<string> ();
		order_by_model.add (_("Due Date"));
        order_by_model.add (_("Alphabetically"));
		order_by_model.add (_("Date Added"));
		order_by_model.add (_("Priority"));

		var order_by_item = new Widgets.ContextMenu.MenuPicker (_("Order by"), "view-list-ordered-symbolic", order_by_model);
		order_by_item.selected = Services.Settings.get_default ().settings.get_int ("today-sort-order");

        // Filters
        var priority_items = new Gee.ArrayList<Objects.Filters.FilterItem> ();

		priority_items.add (new Objects.Filters.FilterItem () {
			filter_type = FilterItemType.PRIORITY,
			name = _("P1"),
			value = Constants.PRIORITY_1.to_string ()
		});

		priority_items.add (new Objects.Filters.FilterItem () {
			filter_type = FilterItemType.PRIORITY,
			name = _("P2"),
			value = Constants.PRIORITY_2.to_string ()
		});
		
		priority_items.add (new Objects.Filters.FilterItem () {
			filter_type = FilterItemType.PRIORITY,
			name = _("P3"),
			value = Constants.PRIORITY_3.to_string ()
		});
		
		priority_items.add (new Objects.Filters.FilterItem () {
			filter_type = FilterItemType.PRIORITY,
			name = _("P4"),
			value = Constants.PRIORITY_4.to_string ()
		});

		priority_filter = new Widgets.ContextMenu.MenuCheckPicker (_("Priority"), "flag-outline-thick-symbolic");
		priority_filter.set_items (priority_items);

        var labels_filter = new Widgets.ContextMenu.MenuItem (_("Filter by Labels"), "tag-outline-symbolic") {
			arrow = true
		};

		var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		menu_box.margin_top = menu_box.margin_bottom = 3;
		menu_box.append (order_by_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
		menu_box.append (new Gtk.Label (_("Filter By")) {
			css_classes = { "heading", "h4" },
			margin_start = 6,
			margin_top = 6,
			margin_bottom = 6,
			halign = Gtk.Align.START
		});
		menu_box.append (priority_filter);
		menu_box.append (labels_filter);

		var popover = new Gtk.Popover () {
			has_arrow = false,
			position = Gtk.PositionType.BOTTOM,
			child = menu_box,
			width_request = 250
		};

		order_by_item.notify["selected"].connect (() => {
            Services.Settings.get_default ().settings.set_int ("today-sort-order", order_by_item.selected);
		});

        priority_filter.filter_change.connect ((filter, active) => {
			if (active) {
				Objects.Filters.Today.get_default ().add_filter (filter);
			} else {
				Objects.Filters.Today.get_default ().remove_filter (filter);
			}
		});

		labels_filter.activate_item.connect (() => {
			popover.popdown ();

			Gee.ArrayList<Objects.Label> _labels = new Gee.ArrayList<Objects.Label> ();
			foreach (Objects.Filters.FilterItem filter in Objects.Filters.Today.get_default ().filters.values) {
				if (filter.filter_type == FilterItemType.LABEL) {
					_labels.add (Services.Database.get_default ().get_label (filter.value));
				}
			}

			var dialog = new Dialogs.LabelPicker ();
			dialog.add_labels (BackendType.ALL);
			dialog.labels = _labels;
			dialog.present (Planify._instance.main_window);

			dialog.labels_changed.connect ((labels) => {				
				foreach (Objects.Label label in labels.values) {
					var filter = new Objects.Filters.FilterItem ();
					filter.filter_type = FilterItemType.LABEL;
					filter.name = label.name;
					filter.value = label.id;

					Objects.Filters.Today.get_default ().add_filter (filter);
				}

				Gee.ArrayList<Objects.Filters.FilterItem> to_remove = new Gee.ArrayList<Objects.Filters.FilterItem> ();
				foreach (Objects.Filters.FilterItem filter in Objects.Filters.Today.get_default ().filters.values) {
					if (filter.filter_type == FilterItemType.LABEL) {
						if (!labels.has_key (filter.value)) {
							to_remove.add (filter);
						}
					}
				}

				foreach (Objects.Filters.FilterItem filter in to_remove) {
					Objects.Filters.Today.get_default ().remove_filter (filter);
				}
			});
		});

		return popover;
	}

    private int set_sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
		Objects.Item item1 = ((Layouts.ItemRow) lbrow).item;
		Objects.Item item2 = ((Layouts.ItemRow) lbbefore).item;
        int sort_order = Services.Settings.get_default ().settings.get_int ("today-sort-order");

		if (sort_order == 0) {
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

        if (sort_order == 1) {
			return item1.content.strip ().collate (item2.content.strip ());
		}

		if (sort_order == 2) {
			return item1.added_datetime.compare (item2.added_datetime);
		}

		if (sort_order == 3) {
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

    private void check_default_view () {
		bool defaults = true;
        int sort_order = Services.Settings.get_default ().settings.get_int ("today-sort-order");
		
		if (sort_order != 0) {
			defaults = false;
		}

		indicator_revealer.reveal_child = !defaults;
	}
}
