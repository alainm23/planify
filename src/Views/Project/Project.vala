
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

public class Views.Project : Adw.Bin {
	public Objects.Project project { get; construct; }

	private Gtk.Stack view_stack;
	private Adw.ToolbarView toolbar_view;
	private Widgets.ContextMenu.MenuItem show_completed_item;
	private Widgets.ContextMenu.MenuItem delete_all_completed;
	private Widgets.ContextMenu.MenuItem expand_all_item;
	private Widgets.ContextMenu.MenuItem collapse_all_item;
	private Widgets.ContextMenu.MenuCheckPicker priority_filter;
	private Widgets.ContextMenu.MenuPicker due_date_item;
	private Widgets.MultiSelectToolbar multiselect_toolbar;
	private Gtk.Revealer indicator_revealer;

	public ProjectViewStyle view_style {
        get {
            return project.source_type == BackendType.CALDAV ? ProjectViewStyle.LIST : project.view_style;
        }
    }

	public Project (Objects.Project project) {
		Object (
			project: project
		);
	}

	construct {
		var menu_button = new Gtk.MenuButton () {
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			margin_end = 12,
			popover = build_context_menu_popover (),
			icon_name = "view-more-symbolic",
			css_classes = { "flat" },
			tooltip_text = _("Project Actions")
		};

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
			popover = build_view_setting_popover (),
			icon_name = "view-sort-descending-rtl-symbolic",
			css_classes = { "flat" },
			tooltip_text = _("View Option Menu")
		};

		var view_setting_overlay = new Gtk.Overlay ();
		view_setting_overlay.child = view_setting_button;
		view_setting_overlay.add_overlay (indicator_revealer);
		
		var headerbar = new Layouts.HeaderBar ();
		headerbar.title = project.name;

		if (!project.is_deck) {
			headerbar.pack_end (menu_button);
		}

		headerbar.pack_end (view_setting_overlay);

		view_stack = new Gtk.Stack () {
			hexpand = true,
			vexpand = true,
			transition_type = Gtk.StackTransitionType.SLIDE_RIGHT
		};

		view_stack.add_named (new Gtk.Spinner () {
			hexpand = true,
			vexpand = true,
			halign = CENTER,
			valign = CENTER,
			spinning = true
		}, "loading");

		var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			hexpand = true,
			vexpand = true
		};

		content_box.append (view_stack);

		var magic_button = new Widgets.MagicButton ();

		var content_overlay = new Gtk.Overlay () {
			hexpand = true,
			vexpand = true
		};

		content_overlay.child = content_box;

		if (!project.is_deck) {
			content_overlay.add_overlay (magic_button);
		}

		multiselect_toolbar = new Widgets.MultiSelectToolbar (project);

		toolbar_view = new Adw.ToolbarView () {
			bottom_bar_style = Adw.ToolbarStyle.RAISED_BORDER,
			reveal_bottom_bars = false
		};
		toolbar_view.add_top_bar (headerbar);
		toolbar_view.add_bottom_bar (multiselect_toolbar);
		toolbar_view.content = content_overlay;

		child = toolbar_view;
		update_project_view ();
		check_default_filters ();
		show ();

		magic_button.clicked.connect (() => {
			prepare_new_item ();
		});

		project.updated.connect (() => {
			headerbar.title = project.name;
		});

		multiselect_toolbar.closed.connect (() => {
			project.show_multi_select = false;
		});

		project.show_multi_select_change.connect (() => {
			toolbar_view.reveal_bottom_bars = project.show_multi_select;
			
			if (project.show_multi_select) {
				Services.EventBus.get_default ().multi_select_enabled = true;
				Services.EventBus.get_default ().show_multi_select (true);
				Services.EventBus.get_default ().magic_button_visible (false);
				Services.EventBus.get_default ().disconnect_typing_accel ();
			} else {
				Services.EventBus.get_default ().multi_select_enabled = false;
				Services.EventBus.get_default ().show_multi_select (false);
				Services.EventBus.get_default ().magic_button_visible (true);
				Services.EventBus.get_default ().connect_typing_accel ();
			}
		});

		project.filter_added.connect (() => {
			check_default_filters ();
		});

		project.filter_updated.connect (() => {
			check_default_filters ();
		});

		project.filter_removed.connect ((filter) => {
			priority_filter.unchecked (filter);
			
			if (filter.filter_type == FilterItemType.DUE_DATE) {
				due_date_item.selected = 0;
			}

			check_default_filters ();
		});

		project.view_style_changed.connect (() => {
			update_project_view ();

			expand_all_item.visible = view_style == ProjectViewStyle.LIST;
			collapse_all_item.visible = view_style == ProjectViewStyle.LIST;
		});
	}

	private void check_default_filters () {
		bool defaults = true;
		
		if (project.sort_order != 0) {
			defaults = false;
		}

		if (project.show_completed != false) {
			defaults = false;
		}

		if (project.filters.size > 0) {
			defaults = false;
		}

		indicator_revealer.reveal_child = !defaults;
	}

	private void update_project_view () {
		view_stack.visible_child_name = "loading";

		Timeout.add (275, () => {
			if (view_style == ProjectViewStyle.LIST) {
				Views.List? list_view;
				list_view = (Views.List) view_stack.get_child_by_name (view_style.to_string ());
				if (list_view == null) {
					list_view = new Views.List (project);
					view_stack.add_named (list_view, view_style.to_string ());
				}
			} else if (view_style == ProjectViewStyle.BOARD) {
				Views.Board? board_view;
				board_view = (Views.Board) view_stack.get_child_by_name (view_style.to_string ());
				if (board_view == null) {
					board_view = new Views.Board (project);
					view_stack.add_named (board_view, view_style.to_string ());
				}
			}
	
			view_stack.set_visible_child_name (view_style.to_string ());
			
			return GLib.Source.REMOVE;
		});
	}

	public void prepare_new_item (string content = "") {
		if (project.is_deck) {
			return;
		}

		if (view_style == ProjectViewStyle.LIST) {
			Views.List? list_view;
			list_view = (Views.List) view_stack.get_child_by_name (view_style.to_string ());
			if (list_view != null) {
				list_view.prepare_new_item (content);
			}
		} else {
			Views.Board? board_view;
			board_view = (Views.Board) view_stack.get_child_by_name (view_style.to_string ());
			if (board_view != null) {
                board_view.prepare_new_item (content);
			}
		}
	}

	private Gtk.Popover build_context_menu_popover () {
		var edit_item = new Widgets.ContextMenu.MenuItem (_("Edit Project"), "edit-symbolic");
		var duplicate_item = new Widgets.ContextMenu.MenuItem (_("Duplicate"), "tabs-stack-symbolic");
		var schedule_item = new Widgets.ContextMenu.MenuItem (_("When?"), "month-symbolic");
		var add_section_item = new Widgets.ContextMenu.MenuItem (_("Add Section"), "tab-new-symbolic");
		add_section_item.secondary_text = "S";
		var manage_sections = new Widgets.ContextMenu.MenuItem (_("Manage Sections"), "permissions-generic-symbolic");
		
		var select_item = new Widgets.ContextMenu.MenuItem (_("Select"), "list-large-symbolic");
		var paste_item = new Widgets.ContextMenu.MenuItem (_("Paste"), "tabs-stack-symbolic");
		expand_all_item = new Widgets.ContextMenu.MenuItem (_("Expand All"), "size-vertically-symbolic") {
			visible = view_style == ProjectViewStyle.LIST
		};
		collapse_all_item = new Widgets.ContextMenu.MenuItem (_("Collapse All"), "size-vertically-symbolic") {
			visible = view_style == ProjectViewStyle.LIST
		};
		var archive_item = new Widgets.ContextMenu.MenuItem (_("Archive"), "shoe-box-symbolic");
		var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete Project"), "user-trash-symbolic");
		delete_item.add_css_class ("menu-item-danger");

		var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		menu_box.margin_top = menu_box.margin_bottom = 3;

		if (!project.is_deck && !project.inbox_project) {
            menu_box.append (edit_item);
        }

		if (!project.is_inbox_project) {
			menu_box.append (schedule_item);
			menu_box.append (duplicate_item);
			menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
		}

		if (project.source_type == BackendType.LOCAL || project.source_type == BackendType.TODOIST) {
			menu_box.append (add_section_item);
			menu_box.append (manage_sections);
			menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
		}

		menu_box.append (select_item);
		menu_box.append (paste_item);
		menu_box.append (expand_all_item);
		menu_box.append (collapse_all_item);
		menu_box.append (show_completed_item);

		if (!project.is_deck && !project.inbox_project) {
			menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
			menu_box.append (archive_item);
			menu_box.append (delete_item);
		}

		var popover = new Gtk.Popover () {
			has_arrow = false,
			position = Gtk.PositionType.BOTTOM,
			child = menu_box,
			width_request = 250
		};

		edit_item.activate_item.connect (() => {
			popover.popdown ();

			var dialog = new Dialogs.Project (project);
			dialog.present (Planify._instance.main_window);
		});

		schedule_item.activate_item.connect (() => {
			popover.popdown ();

			var dialog = new Dialogs.DatePicker (_("When?"));
			dialog.clear = project.due_date != "";
			dialog.present (Planify._instance.main_window);

			dialog.date_changed.connect (() => {
				if (dialog.datetime == null) {
					project.due_date = "";
				} else {
					project.due_date = dialog.datetime.to_string ();
				}

				project.update_local ();
			});
		});

		add_section_item.activate_item.connect (() => {
			popover.popdown ();
			prepare_new_section ();
		});

		manage_sections.clicked.connect (() => {
			popover.popdown ();
			var dialog = new Dialogs.ManageSectionOrder (project);
			dialog.present (Planify._instance.main_window);
		});

		paste_item.clicked.connect (() => {
			popover.popdown ();
			Gdk.Clipboard clipboard = Gdk.Display.get_default ().get_clipboard ();

			clipboard.read_text_async.begin (null, (obj, res) => {
				try {
					string content = clipboard.read_text_async.end (res);
					Services.EventBus.get_default ().paste_action (project.id, content);
				} catch (GLib.Error error) {
					debug (error.message);
				}
			});
		});

		expand_all_item.clicked.connect (() => {
			popover.popdown ();
			Services.EventBus.get_default ().expand_all (project.id, true);
		});

		collapse_all_item.clicked.connect (() => {
			popover.popdown ();
			Services.EventBus.get_default ().expand_all (project.id, false);
		});

		select_item.clicked.connect (() => {
			popover.popdown ();
			project.show_multi_select = true;
		});

		delete_item.clicked.connect (() => {
			popover.popdown ();
			project.delete_project ((Gtk.Window) Planify.instance.main_window);
		});
		
		duplicate_item.clicked.connect (() => {
            popover.popdown ();
            Util.get_default ().duplicate_project.begin (project, project.parent_id);
        });

		archive_item.clicked.connect (() => {
            popover.popdown ();
            project.archive_project ((Gtk.Window) Planify.instance.main_window);
        });
		
		return popover;
	}

	private Gtk.Popover build_view_setting_popover () {
		var list_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
			halign = CENTER
		};

		list_box.append (new Gtk.Image.from_icon_name ("list-symbolic"));
		list_box.append (new Gtk.Label (_("List")) {
			css_classes = { "caption" },
			valign = CENTER
		});

		var list_button = new Gtk.ToggleButton () {
			child = list_box,
			active = view_style == ProjectViewStyle.LIST
		};

		var board_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
			halign = CENTER
		};

		board_box.append (new Gtk.Image.from_icon_name ("view-columns-symbolic"));
		board_box.append (new Gtk.Label (_("Board")) {
			css_classes = { "caption" },
			valign = CENTER
		});

		var board_button = new Gtk.ToggleButton () {
			group = list_button,
			child = board_box,
			active = view_style == ProjectViewStyle.BOARD
		};

		var view_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
			css_classes = { "linked" },
			hexpand = true,
			homogeneous = true,
			margin_start = 3,
			margin_end = 3,
			margin_bottom = 12
		};

		view_box.append (list_button);
		view_box.append (board_button);

		var order_by_model = new Gee.ArrayList<string> ();
		order_by_model.add (_("Custom sort order"));
		order_by_model.add (_("Alphabetically"));
		order_by_model.add (_("Due Date"));
		order_by_model.add (_("Date Added"));
		order_by_model.add (_("Priority"));

		var order_by_item = new Widgets.ContextMenu.MenuPicker (_("Sorting"), "vertical-arrows-long-symbolic", order_by_model);
		order_by_item.selected = project.sort_order;

		// Filters
		var due_date_model = new Gee.ArrayList<string> ();
		due_date_model.add (_("All (default)"));
		due_date_model.add (_("Today"));
		due_date_model.add (_("This Week"));
		due_date_model.add (_("Next 7 Days"));
		due_date_model.add (_("This Month"));
		due_date_model.add (_("Next 30 Days"));
		due_date_model.add (_("No Date"));

		due_date_item = new Widgets.ContextMenu.MenuPicker (_("Duedate"), "month-symbolic", due_date_model);
		due_date_item.selected = 0;

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

		show_completed_item = new Widgets.ContextMenu.MenuItem (
			project.show_completed ? _("Hide Completed Tasks") : _("Show Completed Tasks"),
			"check-round-outline-symbolic"
		);

		delete_all_completed = new Widgets.ContextMenu.MenuItem (_("Delete All Completed Tasks") ,"user-trash-symbolic") {
			visible = project.show_completed && Services.Store.instance ().get_items_checked_by_project (project).size > 0
		};
		delete_all_completed.add_css_class ("menu-item-danger");

		var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		menu_box.margin_top = menu_box.margin_bottom = 3;

		if (project.source_type == BackendType.LOCAL || project.source_type == BackendType.TODOIST) {
			menu_box.append (view_box);
			menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
		}

		menu_box.append (new Gtk.Label (_("Sort By")) {
			css_classes = { "heading", "h4" },
			margin_start = 6,
			margin_top = 6,
			margin_bottom = 6,
			halign = Gtk.Align.START
		});
		menu_box.append (order_by_item);
		menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
		menu_box.append (new Gtk.Label (_("Filter By")) {
			css_classes = { "heading", "h4" },
			margin_start = 6,
			margin_top = 6,
			margin_bottom = 6,
			halign = Gtk.Align.START
		});
		menu_box.append (due_date_item);
		menu_box.append (priority_filter);
		menu_box.append (labels_filter);
		menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
		menu_box.append (show_completed_item);
		menu_box.append (delete_all_completed);

		var popover = new Gtk.Popover () {
			has_arrow = false,
			position = Gtk.PositionType.BOTTOM,
			child = menu_box,
			width_request = 250
		};

		order_by_item.notify["selected"].connect (() => {
			project.sort_order = order_by_item.selected;
			project.update_local ();
			check_default_filters ();
		});

		show_completed_item.activate_item.connect (() => {
			popover.popdown ();

			project.show_completed = !project.show_completed;
			project.update_local ();

			show_completed_item.title = project.show_completed ? _("Hide Completed Tasks") : _("Show Completed Tasks");
			delete_all_completed.visible = project.show_completed && Services.Store.instance ().get_items_checked_by_project (project).size > 0;
			check_default_filters ();
		});

		list_button.toggled.connect (() => {
			popover.popdown ();

			project.view_style = ProjectViewStyle.LIST;
			project.update_local ();
		});

		board_button.toggled.connect (() => {
			popover.popdown ();
			
			project.view_style = ProjectViewStyle.BOARD;
			project.update_local ();
		});

		project.sort_order_changed.connect (() => {
			order_by_item.update_selected (project.sort_order);
			check_default_filters ();
		});

		delete_all_completed.activate_item.connect (() => {
			popover.popdown ();

			var items = Services.Store.instance ().get_items_checked_by_project (project);

			var dialog = new Adw.AlertDialog (
			    _("Delete All Completed Tasks"),
				_("This will delete %d completed tasks and their subtasks from project %s".printf (items.size, project.name))
			);

			dialog.body_use_markup = true;
			dialog.add_response ("cancel", _("Cancel"));
			dialog.add_response ("delete", _("Delete"));
			dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
			dialog.present (Planify._instance.main_window);

			dialog.response.connect ((response) => {
				if (response == "delete") {
					delete_all_action (items);
				}
			});
		});

		due_date_item.notify["selected"].connect (() => {
			if (due_date_item.selected <= 0) {
				Objects.Filters.FilterItem filter = project.get_filter (FilterItemType.DUE_DATE.to_string ());
				if (filter != null) {
					project.remove_filter (filter);
				}
			} else {
				Objects.Filters.FilterItem filter = project.get_filter (FilterItemType.DUE_DATE.to_string ());
				bool insert = false;

				if (filter == null) {
					filter = new Objects.Filters.FilterItem ();
					filter.filter_type = FilterItemType.DUE_DATE;
					insert = true;
				}				
				
				if (due_date_item.selected == 1) {
					filter.name = _("Today");
				} else if (due_date_item.selected == 2) {
					filter.name = _("This Week");
				} else if (due_date_item.selected == 3) {
					filter.name = _("Next 7 Days");
				} else if (due_date_item.selected == 4) {
					filter.name = _("This Month");
				} else if (due_date_item.selected == 5) {
					filter.name = _("Next 30 Days");
				} else if (due_date_item.selected == 6) {
					filter.name = _("No Date");
				}

				filter.value = due_date_item.selected.to_string ();
				
				if (insert) {
					project.add_filter (filter);
				} else {
					project.update_filter (filter);
				}
			}
		});

		priority_filter.filter_change.connect ((filter, active) => {
			if (active) {
				project.add_filter (filter);
			} else {
				project.remove_filter (filter);
			}
		});

		labels_filter.activate_item.connect (() => {
			popover.popdown ();

			Gee.ArrayList<Objects.Label> _labels = new Gee.ArrayList<Objects.Label> ();
			foreach (Objects.Filters.FilterItem filter in project.filters.values) {
				if (filter.filter_type == FilterItemType.LABEL) {
					_labels.add (Services.Store.instance ().get_label (filter.value));
				}
			}

			var dialog = new Dialogs.LabelPicker ();
			dialog.add_labels (project.source);
			dialog.labels = _labels;
			dialog.present (Planify._instance.main_window);

			dialog.labels_changed.connect ((labels) => {				
				foreach (Objects.Label label in labels.values) {
					var filter = new Objects.Filters.FilterItem ();
					filter.filter_type = FilterItemType.LABEL;
					filter.name = label.name;
					filter.value = label.id;

					project.add_filter (filter);
				}

				Gee.ArrayList<Objects.Filters.FilterItem> to_remove = new Gee.ArrayList<Objects.Filters.FilterItem> ();
				foreach (Objects.Filters.FilterItem filter in project.filters.values) {
					if (filter.filter_type == FilterItemType.LABEL) {
						if (!labels.has_key (filter.value)) {
							to_remove.add (filter);
						}
					}
				}

				foreach (Objects.Filters.FilterItem filter in to_remove) {
					project.remove_filter (filter);
				}
			});
		});

		return popover;
	}

	public void prepare_new_section () {
		if (project.source_type == BackendType.CALDAV) {
			return;
		}

		var dialog = new Dialogs.Section.new (project);
		dialog.present (Planify._instance.main_window);
	}

	public void delete_all_action (Gee.ArrayList<Objects.Item> items) {
		foreach (Objects.Item item in items) {
			item.delete_item ();
		}
	}
}
