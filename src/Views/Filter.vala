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

public class Views.Filter : Adw.Bin {
    private Layouts.HeaderBar headerbar;
    private Gtk.ListBox listbox;
    private Adw.Bin listbox_content;
    private Gtk.Stack listbox_stack;
    private Widgets.MagicButton magic_button;
    private Gtk.Revealer view_setting_revealer;

    private Gee.HashMap <string, Layouts.ItemRow> items = new Gee.HashMap <string, Layouts.ItemRow> ();

    Objects.BaseObject _filter;
    public Objects.BaseObject filter {
        get {
            return _filter;
        }

        set {
            _filter = value;
            update_request ();
            add_items ();
        }
    }

    private bool has_items {
        get {
            return items.size > 0;
        }
    }

    construct {
        var view_setting_button = new Gtk.MenuButton () {
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
            margin_end = 12,
			popover = build_view_setting_popover (),
			icon_name = "view-sort-descending-rtl-symbolic",
			css_classes = { "flat" },
			tooltip_text = _("View Option Menu")
		};

        view_setting_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = view_setting_button
        };

        headerbar = new Layouts.HeaderBar ();
        headerbar.pack_end (view_setting_revealer);

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
			selection_mode = Gtk.SelectionMode.NONE,
			hexpand = true,
			css_classes = { "listbox-background" }
        };

        listbox_content = new Adw.Bin () {
            child = listbox
        };

        var listbox_placeholder = new Adw.StatusPage ();
        listbox_placeholder.icon_name = "check-round-outline-symbolic";
        listbox_placeholder.title = _("Add Some Tasks");
        listbox_placeholder.description = _("Press a to create a new task");

        listbox_stack = new Gtk.Stack () {
            hexpand = true,
            vexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        listbox_stack.add_named (listbox_content, "listbox");
        listbox_stack.add_named (listbox_placeholder, "placeholder");

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };

        content.append (listbox_stack);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 1024,
            tightening_threshold = 800,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 64
        };

        content_clamp.child = content;

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = content_clamp
        };

        magic_button = new Widgets.MagicButton ();

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

        Timeout.add (listbox_stack.transition_duration, () => {
            validate_placeholder ();
            return GLib.Source.REMOVE;
        });

        Services.Store.instance ().item_added.connect (valid_add_item);
        Services.Store.instance ().item_deleted.connect (valid_delete_item);
        Services.Store.instance ().item_updated.connect (valid_update_item);
        Services.EventBus.get_default ().checked_toggled.connect (valid_checked_item);
        Services.Store.instance ().item_archived.connect (valid_delete_item);
        Services.Store.instance ().item_unarchived.connect ((item) => {
            valid_add_item (item);
        });

        Services.EventBus.get_default ().item_moved.connect ((item) => {
            if (items.has_key (item.id)) {
                items[item.id].update_request ();
            }

            listbox.invalidate_sort ();
        });

        magic_button.clicked.connect (() => {
            prepare_new_item ();
        });
    }

    public void prepare_new_item (string content = "") {
        var inbox_project = Services.Store.instance ().get_project (
            Services.Settings.get_default ().settings.get_string ("local-inbox-project-id")
        );

        var dialog = new Dialogs.QuickAdd ();
        dialog.set_project (inbox_project);
        dialog.update_content (content);
        
        if (filter is Objects.Filters.Priority) {
            Objects.Filters.Priority priority = ((Objects.Filters.Priority) filter);
            dialog.set_priority (priority.priority);
        } else if (filter is Objects.Filters.Tomorrow) {
            dialog.set_due (Utils.Datetime.get_format_date (
                new GLib.DateTime.now_local ().add_days (1)
            ));
        } else if (filter is Objects.Filters.Pinboard) {
            dialog.set_pinned (true);
        }

        dialog.present (Planify._instance.main_window);
    }

    private void update_request () {
        if (filter is Objects.Filters.Priority) {
            Objects.Filters.Priority priority = ((Objects.Filters.Priority) filter);
            headerbar.title = priority.name;
            listbox.set_sort_func (null);
            listbox.set_header_func (null);
            listbox_content.margin_top = 12;
            magic_button.visible = true;
        } else if (filter is Objects.Filters.Completed) {
            headerbar.title = _("Completed");
            listbox.set_sort_func (sort_completed_function);
            listbox.set_header_func (header_completed_function);
            listbox_content.margin_top = 0;
            magic_button.visible = false;
        } else if (filter is Objects.Filters.Tomorrow) {
            headerbar.title = _("Tomorrow");
            listbox.set_sort_func (null);
            listbox.set_header_func (null);
            listbox_content.margin_top = 12;
            magic_button.visible = true;
        } else if (filter is Objects.Filters.Pinboard) {
            headerbar.title = _("Pinboard");
            listbox.set_sort_func (null);
            listbox.set_header_func (null);
            listbox_content.margin_top = 12;
            magic_button.visible = true;
        } else if (filter is Objects.Filters.Anytime) {
            headerbar.title = _("Anytime");
            listbox.set_sort_func (sort_project_function);
            listbox.set_header_func (header_project_function);
            listbox_content.margin_top = 12;
            magic_button.visible = true;
        } else if (filter is Objects.Filters.Repeating) {
            headerbar.title = _("Repeating");
            listbox.set_sort_func (sort_project_function);
            listbox.set_header_func (header_project_function);
            listbox_content.margin_top = 12;
            magic_button.visible = false;
        } else if (filter is Objects.Filters.Unlabeled) {
            headerbar.title = _("Unlabeled");
            listbox.set_sort_func (sort_project_function);
            listbox.set_header_func (header_project_function);
            listbox_content.margin_top = 12;
            magic_button.visible = true;
        } else if (filter is Objects.Filters.AllItems) {
            headerbar.title = _("All Tasks");
            listbox.set_sort_func (sort_project_function);
            listbox.set_header_func (header_project_function);
            listbox_content.margin_top = 12;
            magic_button.visible = true;
        }

        view_setting_revealer.reveal_child = filter is Objects.Filters.Completed;
    }

    private void add_items () {        
        foreach (Layouts.ItemRow row in items.values) {
            listbox.remove (row);
        }

        items.clear ();

        if (filter is Objects.Filters.Priority) {
            Objects.Filters.Priority priority = ((Objects.Filters.Priority) filter);
            foreach (Objects.Item item in Services.Store.instance ().get_items_by_priority (priority.priority, false)) {
                add_item (item);
            }
        } else if (filter is Objects.Filters.Completed) {
            foreach (Objects.Item item in Services.Store.instance ().get_items_completed ()) {
                add_item (item);
            }
        } else if (filter is Objects.Filters.Tomorrow) {
            foreach (Objects.Item item in Services.Store.instance ().get_items_by_date (new GLib.DateTime.now_local ().add_days (1), false)) {
                add_item (item);
            }
        } else if (filter is Objects.Filters.Pinboard) {
            foreach (Objects.Item item in Services.Store.instance ().get_items_pinned (false)) {
                add_item (item);
            }
        } else if (filter is Objects.Filters.Anytime) {
            foreach (Objects.Item item in Services.Store.instance ().get_items_no_date (false)) {
                add_item (item);
            }
        } else if (filter is Objects.Filters.Repeating) {
            foreach (Objects.Item item in Services.Store.instance ().get_items_repeating (false)) {
                add_item (item);
            }
        } else if (filter is Objects.Filters.Unlabeled) {
            foreach (Objects.Item item in Services.Store.instance ().get_items_unlabeled (false)) {
                add_item (item);
            }
        } else if (filter is Objects.Filters.AllItems) {
            foreach (Objects.Item item in Services.Store.instance ().get_items_no_parent (false)) {
                add_item (item);
            }
        }
    }

    private void add_item (Objects.Item item) {
        items [item.id] = new Layouts.ItemRow (item);
        items [item.id].disable_drag_and_drop ();
        listbox.append (items [item.id]);
    }

    private void valid_add_item (Objects.Item item, bool insert = true) {
        if (filter is Objects.Filters.Priority) {
            Objects.Filters.Priority priority = ((Objects.Filters.Priority) filter);
            
            if (!items.has_key (item.id) && item.priority == priority.priority && insert) {
                add_item (item);   
            }
        } else if (filter is Objects.Filters.Completed) {
            if (!items.has_key (item.id) && item.checked && insert) {
                add_item (item);   
            }
        } else if (filter is Objects.Filters.Tomorrow) {
            if (!items.has_key (item.id) && item.has_due &&
                Utils.Datetime.is_tomorrow (item.due.datetime) && insert) {
                add_item (item);   
            }
        } else if (filter is Objects.Filters.Pinboard) {
            if (!items.has_key (item.id) && item.pinned && insert) {
                add_item (item);   
            }
        } else if (filter is Objects.Filters.Anytime) {
            if (!items.has_key (item.id) && !item.has_due && insert) {
                add_item (item);   
            }
        } else if (filter is Objects.Filters.Repeating) {
            if (!items.has_key (item.id) && item.has_due && item.due.is_recurring && insert) {
                add_item (item);   
            }
        } else if (filter is Objects.Filters.Unlabeled) {
            if (!items.has_key (item.id) && item.labels.size <= 0 && insert) {
                add_item (item);   
            }
        } else if (filter is Objects.Filters.AllItems) {
            if (!items.has_key (item.id) && insert) {
                add_item (item);   
            }
        }

        validate_placeholder ();
    }

    private void valid_delete_item (Objects.Item item) {
        if (items.has_key (item.id)) {
            items[item.id].hide_destroy ();
            items.unset (item.id);
        }

        validate_placeholder ();
    }

    private void valid_update_item (Objects.Item item, string update_id = "") {
        if (items.has_key (item.id) && items [item.id].update_id != update_id) {
            items[item.id].update_request ();
        }

        if (filter is Objects.Filters.Priority) {
            Objects.Filters.Priority priority = ((Objects.Filters.Priority) filter);

            if (items.has_key (item.id) && item.priority != priority.priority) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }

            if (items.has_key (item.id) && !item.checked) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }
    
            valid_add_item (item);
        } else if (filter is Objects.Filters.Completed) {
            if (items.has_key (item.id) && item.checked) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }
    
            valid_add_item (item);
        } else if (filter is Objects.Filters.Tomorrow) {
            if (items.has_key (item.id) && (!item.has_due || !Utils.Datetime.is_tomorrow (item.due.datetime))) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }

            valid_add_item (item);
        } else if (filter is Objects.Filters.Pinboard) {
            if (items.has_key (item.id) && !item.pinned) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }
    
            valid_add_item (item);
        } else if (filter is Objects.Filters.Anytime) {
            if (items.has_key (item.id) && item.has_due) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }
    
            valid_add_item (item);
        } else if (filter is Objects.Filters.Repeating) {
            if (items.has_key (item.id) && (!item.has_due || !item.due.is_recurring)) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }
    
            valid_add_item (item);
        } else if (filter is Objects.Filters.Unlabeled) {
            if (items.has_key (item.id) && item.labels.size > 0) {
                items[item.id].hide_destroy ();
                items.unset (item.id);
            }
    
            valid_add_item (item);
        }

        validate_placeholder ();
    }

    private void valid_checked_item (Objects.Item item, bool old_checked) {
        if (filter is Objects.Filters.Priority || filter is Objects.Filters.Tomorrow ||
            filter is Objects.Filters.Pinboard || filter is Objects.Filters.Anytime ||
            filter is Objects.Filters.Repeating || filter is Objects.Filters.Unlabeled ||
            filter is Objects.Filters.AllItems
        ) {
            if (!old_checked) {
                if (items.has_key (item.id) && item.completed) {
                    items[item.id].hide_destroy ();
                    items.unset (item.id);
                }
            } else {
                valid_update_item (item);
            }
        } else if (filter is Objects.Filters.Completed) {
            if (!old_checked) {
                valid_update_item (item);
            } else {
                if (items.has_key (item.id) && !item.completed) {
                    items[item.id].hide_destroy ();
                    items.unset (item.id);
                }
            }
        }

        validate_placeholder ();
    }

    private void header_completed_function (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
        var row = (Layouts.ItemRow) lbrow;
        if (row.item.completed_at == "") {
            return;
        }

        if (lbbefore != null) {
            var before = (Layouts.ItemRow) lbbefore;
            var comp_before = Utils.Datetime.get_date_from_string (before.item.completed_at);
            if (comp_before.compare (Utils.Datetime.get_date_from_string (row.item.completed_at)) == 0) {
                return;
            }
        }

        row.set_header (
            get_header_box (
                Utils.Datetime.get_relative_date_from_date (
                    Utils.Datetime.get_date_from_string (row.item.completed_at)
                )
            )
        );
    }

    private void header_project_function (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
        if (!(lbrow is Layouts.ItemRow)) {
            return;
        }

        var row = (Layouts.ItemRow) lbrow;
        if (lbbefore != null && lbbefore is Layouts.ItemRow) {
            var before = (Layouts.ItemRow) lbbefore;
            if (row.project_id == before.project_id) {
                row.set_header (null);
                return;
            }
        }

        row.set_header (get_header_box (row.item.project.name));
    }

    private int sort_completed_function (Gtk.ListBoxRow row1, Gtk.ListBoxRow? row2) {
        var completed_a = Utils.Datetime.get_date_from_string (((Layouts.ItemRow) row1).item.completed_at);
        var completed_b = Utils.Datetime.get_date_from_string (((Layouts.ItemRow) row2).item.completed_at);
        return completed_b.compare (completed_a);
    }

    private int sort_project_function (Gtk.ListBoxRow row1, Gtk.ListBoxRow? row2) {
        var item1 = ((Layouts.ItemRow) row1).item;
        var item2 = ((Layouts.ItemRow) row2).item;
        return item1.project_id.strip ().collate (item2.project_id.strip ());
    }

    private void validate_placeholder () {        
        listbox_stack.visible_child_name = has_items ? "listbox" : "placeholder";
    }

    private Gtk.Widget get_header_box (string title) {
        var header_label = new Gtk.Label (title) {
            css_classes = { "heading" },
            halign = START,
            margin_start = 3
        };

        var header_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            hexpand = true,
            margin_bottom = 6,
            margin_start = 3
        };

        var header_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_top = 12,
            margin_start = 19
        };

        header_box.append (header_label);
        header_box.append (header_separator);

        return header_box;
    }

    private Gtk.Popover build_view_setting_popover () {
		var delete_all_completed = new Widgets.ContextMenu.MenuItem (_("Delete All Completed Tasks") ,"user-trash-symbolic");
		delete_all_completed.add_css_class ("menu-item-danger");

		var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		menu_box.margin_top = menu_box.margin_bottom = 3;
		menu_box.append (delete_all_completed);

		var popover = new Gtk.Popover () {
			has_arrow = false,
			position = Gtk.PositionType.BOTTOM,
			child = menu_box,
			width_request = 250
		};

        delete_all_completed.activate_item.connect (() => {
			popover.popdown ();

			var items = Services.Store.instance ().get_items_checked ();

			var dialog = new Adw.AlertDialog (
			    _("Delete All Completed Tasks"),
				_("This will delete %d completed tasks and their subtasks".printf (items.size))
			);

			dialog.body_use_markup = true;
			dialog.add_response ("cancel", _("Cancel"));
			dialog.add_response ("delete", _("Delete"));
			dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
			dialog.present (Planify._instance.main_window);

			dialog.response.connect ((response) => {
				if (response == "delete") {
					foreach (Objects.Item item in items) {
                        item.delete_item ();
                    }
				}
			});
		});

		return popover;
	}
}
