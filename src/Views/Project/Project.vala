
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

public class Views.Project : Gtk.Grid {
	public Objects.Project project { get; construct; }

	private Gtk.Stack view_stack;
	private Adw.ToolbarView toolbar_view;
	private Widgets.ContextMenu.MenuItem show_completed_item;
	private Widgets.MultiSelectToolbar multiselect_toolbar;

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
			child = new Widgets.DynamicIcon.from_icon_name ("dots-vertical"),
			css_classes = { "flat" }
		};

		var view_setting_button = new Gtk.MenuButton () {
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			popover = build_view_setting_popover (),
			child = new Widgets.DynamicIcon.from_icon_name ("planner-settings-sliders"),
			css_classes = { "flat" }
		};
		
		var headerbar = new Layouts.HeaderBar ();
		headerbar.title = project.name;

		headerbar.pack_end (menu_button);
		headerbar.pack_end (view_setting_button);

		view_stack = new Gtk.Stack () {
			hexpand = true,
			vexpand = true,
			transition_type = Gtk.StackTransitionType.SLIDE_RIGHT
		};

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
		content_overlay.add_overlay (magic_button);

		multiselect_toolbar = new Widgets.MultiSelectToolbar (project);

		toolbar_view = new Adw.ToolbarView () {
			bottom_bar_style = Adw.ToolbarStyle.RAISED_BORDER,
			reveal_bottom_bars = false
		};
		toolbar_view.add_top_bar (headerbar);
		toolbar_view.add_bottom_bar (multiselect_toolbar);
		toolbar_view.content = content_overlay;

		attach (toolbar_view, 0, 0);
		update_project_view (ProjectViewStyle.LIST);
		show();

		magic_button.clicked.connect (() => {
			prepare_new_item ();
		});

		magic_button.drag_begin.connect (() => {
			Services.EventBus.get_default ().project_view_drag_action (project.id, true);
		});

		magic_button.drag_end.connect (() => {
			Services.EventBus.get_default ().project_view_drag_action (project.id, false);
		});

		project.updated.connect (() => {
			headerbar.title = project.name;
		});

		multiselect_toolbar.closed.connect (() => {
			Services.EventBus.get_default ().multi_select_enabled = false;
			Services.EventBus.get_default ().show_multi_select (false);
			Services.EventBus.get_default ().magic_button_visible (true);
			Services.EventBus.get_default ().connect_typing_accel ();

			toolbar_view.reveal_bottom_bars = false;
		});
	}

	private void update_project_view (ProjectViewStyle view_style) {
		if (view_style == ProjectViewStyle.LIST) {
			Views.List? list_view;
			list_view = (Views.List) view_stack.get_child_by_name (view_style.to_string ());
			if (list_view == null) {
				list_view = new Views.List (project);
				view_stack.add_named (list_view, view_style.to_string ());
			}

			Views.Board? board_view;
			board_view = (Views.Board) view_stack.get_child_by_name ("board");
			if (board_view != null) {
				view_stack.remove (board_view);
			}
		} else if (view_style == ProjectViewStyle.BOARD) {
			Views.Board? board_view;
			board_view = (Views.Board) view_stack.get_child_by_name (view_style.to_string ());
			if (board_view == null) {
				board_view = new Views.Board (project);
				view_stack.add_named (board_view, view_style.to_string ());
			}

			Views.List? list_view;
			list_view = (Views.List) view_stack.get_child_by_name ("list");
			if (list_view != null) {
				view_stack.remove (list_view);
			}
		}

		view_stack.set_visible_child_name (view_style.to_string ());
		project.view_style = view_style;
		project.update (false);
	}

	public void prepare_new_item (string content = "") {
		if (project.view_style == ProjectViewStyle.LIST) {
			Views.List? list_view;
			list_view = (Views.List) view_stack.get_child_by_name (project.view_style.to_string ());
			if (list_view != null) {
				list_view.prepare_new_item (content);
			}
		} else {
			Views.Board? board_view;
			board_view = (Views.Board) view_stack.get_child_by_name (project.view_style.to_string ());
			if (board_view != null) {
                board_view.prepare_new_item (content);
			}
		}
	}

	private Gtk.Popover build_context_menu_popover () {
		var edit_item = new Widgets.ContextMenu.MenuItem (_("Edit Project"), "planner-edit");
		var schedule_item = new Widgets.ContextMenu.MenuItem (_("When?"), "planner-calendar");
		var description_item = new Widgets.ContextMenu.MenuItem (_("Description"), "planner-note");
		var add_section_item = new Widgets.ContextMenu.MenuItem (_("Add Section"), "planner-section");
		var filter_by_tags = new Widgets.ContextMenu.MenuItem (_("Filter by Labels"), "planner-tag");
		var select_item = new Widgets.ContextMenu.MenuItem (_("Select"), "unordered-list");
		var paste_item = new Widgets.ContextMenu.MenuItem (_("Paste"), "planner-clipboard");
		var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete Project"), "planner-trash");
		delete_item.add_css_class ("menu-item-danger");

		var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		menu_box.margin_top = menu_box.margin_bottom = 3;

		if (!project.is_inbox_project) {
			menu_box.append (edit_item);
			menu_box.append (description_item);
			menu_box.append (schedule_item);
			menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
		}

		menu_box.append (add_section_item);
		menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
		menu_box.append (select_item);
		menu_box.append (paste_item);
		menu_box.append (show_completed_item);

		if (!project.inbox_project) {
			menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
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
			dialog.show ();
		});

		description_item.activate_item.connect (() => {
			popover.popdown ();
			var dialog = new Dialogs.ProjectDescription (project);
			dialog.show ();
		});

		schedule_item.activate_item.connect (() => {
			popover.popdown ();

			var dialog = new Dialogs.DatePicker (_("When?"));
			dialog.clear = project.due_date != "";
			dialog.show ();

			dialog.date_changed.connect (() => {
				if (dialog.datetime == null) {
					project.due_date = "";
				} else {
					project.due_date = dialog.datetime.to_string ();
				}

				project.update_no_timeout ();
			});
		});

		filter_by_tags.activate_item.connect (() => {
			popover.popdown ();

			var dialog = new Dialogs.LabelPicker ();
			dialog.labels = project.label_filter;
			dialog.show ();

			dialog.labels_changed.connect ((labels) => {
				project.label_filter = labels;
			});
		});

		add_section_item.activate_item.connect (() => {
			Objects.Section new_section = prepare_new_section ();

			if (project.backend_type == BackendType.TODOIST) {
				add_section_item.is_loading = true;
				Services.Todoist.get_default ().add.begin (new_section, (obj, res) => {
					TodoistResponse response = Services.Todoist.get_default ().add.end (res);

					if (response.status) {
						new_section.id = response.data;
						project.add_section_if_not_exists (new_section);
						add_section_item.is_loading = false;
						popover.popdown ();
					}
				});
			} else {
				new_section.id = Util.get_default ().generate_id (new_section);
				project.add_section_if_not_exists (new_section);
				popover.popdown ();
			}
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

		select_item.clicked.connect (() => {
			popover.popdown ();

			Services.EventBus.get_default ().multi_select_enabled = true;
			Services.EventBus.get_default ().show_multi_select (true);
			Services.EventBus.get_default ().magic_button_visible (false);
			Services.EventBus.get_default ().disconnect_typing_accel ();

			toolbar_view.reveal_bottom_bars = true;
		});

		delete_item.clicked.connect (() => {
			popover.popdown ();

			var dialog = new Adw.MessageDialog ((Gtk.Window) Planify.instance.main_window,
			                                    _("Delete project"), _("Are you sure you want to delete <b>%s</b>?".printf (Util.get_default ().get_dialog_text (project.short_name))));

			dialog.body_use_markup = true;
			dialog.add_response ("cancel", _("Cancel"));
			dialog.add_response ("delete", _("Delete"));
			dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
			dialog.show ();

			dialog.response.connect ((response) => {
				if (response == "delete") {
					if (project.backend_type == BackendType.TODOIST) {
						Services.Todoist.get_default ().delete.begin (project, (obj, res) => {
							if (Services.Todoist.get_default ().delete.end (res).status) {
								Services.Database.get_default ().delete_project (project);
							}
						});
					} else if (project.backend_type == BackendType.LOCAL) {
						Services.Database.get_default ().delete_project (project);
					}
				}
			});
		});

		return popover;
	}

	private Gtk.Popover build_view_setting_popover () {
		var order_by_model = new Gee.ArrayList<string> ();
		order_by_model.add (_("Custom sort order"));
		order_by_model.add (_("Alphabetically"));
		order_by_model.add (_("Due date"));
		order_by_model.add (_("Date added"));
		order_by_model.add (_("Priority"));

		var order_by_item = new Widgets.ContextMenu.MenuPicker (_("Order by"), null, order_by_model, project.sort_order);

		show_completed_item = new Widgets.ContextMenu.MenuItem (
			project.show_completed ? _("Hide completed tasks") : _("Show Completed Tasks"),
			"planner-check-circle"
			);

		var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		menu_box.margin_top = menu_box.margin_bottom = 3;
		menu_box.append (order_by_item);
		menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
		menu_box.append (show_completed_item);

		var popover = new Gtk.Popover () {
			has_arrow = false,
			position = Gtk.PositionType.BOTTOM,
			child = menu_box,
			width_request = 250
		};

		order_by_item.selected.connect ((index) => {
			project.sort_order = index;
			project.update (false);
		});

		show_completed_item.activate_item.connect (() => {
			popover.popdown ();

			project.show_completed = !project.show_completed;
			project.update ();

			show_completed_item.title = project.show_completed ? _("Hide Completed Tasks") : _("Show completed tasks");
		});

		return popover;
	}

	public Objects.Section prepare_new_section () {
		Objects.Section new_section = new Objects.Section ();
		new_section.project_id = project.id;
		new_section.name = _("New section");
		new_section.activate_name_editable = true;
		new_section.section_order = project.sections.size;

		return new_section;
	}
}
