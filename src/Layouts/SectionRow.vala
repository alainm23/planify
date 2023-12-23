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

public class Layouts.SectionRow : Gtk.ListBoxRow {
	public Objects.Section section { get; construct; }

	private Gtk.Revealer hide_revealer;
	private Gtk.Revealer bottom_revealer;
	private Widgets.EditableLabel name_editable;
	private Gtk.ListBox listbox;
	private Gtk.ListBox checked_listbox;
	private Gtk.Revealer checked_revealer;
	private Gtk.Revealer content_revealer;
	private Gtk.Box handle_grid;
	private Gtk.Box sectionrow_grid;
	private Gtk.Label count_label;
	private Gtk.Revealer count_revealer;
	private Gtk.Revealer placeholder_revealer;
	private Gtk.Grid drop_widget;
	private Gtk.Revealer drop_widget_revealer;

	public bool is_inbox_section {
		get {
			return section.id == "";
		}
	}

	public bool has_children {
		get {
			return items.size > 0 ||
			       items_checked.size > 0;
		}
	}

	public bool is_creating {
		get {
			return section.id == "";
		}
	}

	public Gee.HashMap <string, Layouts.ItemRow> items;
	public Gee.HashMap <string, Layouts.ItemRow> items_checked;
	public bool on_drag = false;

	public signal void children_size_changed ();

	public SectionRow (Objects.Section section) {
		Object (
			section: section,
			focusable: false,
			can_focus: true
		);
	}

	public SectionRow.for_project (Objects.Project project) {
		var section = new Objects.Section ();
		section.id = "";
		section.project_id = project.id;
		section.name = _("(No Section)");

		Object (
			section: section,
			focusable: false,
			can_focus: true
		);
	}

	construct {
		add_css_class ("row");

		items = new Gee.HashMap <string, Layouts.ItemRow> ();
		items_checked = new Gee.HashMap <string, Layouts.ItemRow> ();

		name_editable = new Widgets.EditableLabel (("New section"), false) {
			valign = Gtk.Align.CENTER,
			hexpand = true,
			margin_top = 3
		};

		name_editable.add_css_class ("font-bold");
		name_editable.text = section.name;

		count_label = new Gtk.Label (section.section_count.to_string ()) {
			hexpand = true,
			halign = Gtk.Align.CENTER
		};

		count_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
		count_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

		count_revealer = new Gtk.Revealer () {
			reveal_child = int.parse (count_label.label) > 0,
			transition_type = Gtk.RevealerTransitionType.CROSSFADE
		};

		count_revealer.child = count_label;

		var add_button = new Gtk.Button () {
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			child = new Widgets.DynamicIcon.from_icon_name ("plus")
		};

		add_button.add_css_class (Granite.STYLE_CLASS_FLAT);

		var menu_button = new Gtk.MenuButton () {
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			popover = build_context_menu (),
			child = new Widgets.DynamicIcon.from_icon_name ("dots-vertical")
		};
		menu_button.add_css_class (Granite.STYLE_CLASS_FLAT);

		var actions_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		actions_box.append (add_button);
		actions_box.append (menu_button);

		var actions_box_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            reveal_child = false,
			child = actions_box
        };

		sectionrow_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		sectionrow_grid.add_css_class ("transition");
		sectionrow_grid.append (name_editable);
        sectionrow_grid.append (actions_box_revealer);

		var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
			margin_bottom = 6,
			margin_end = 6
		};

		var header_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			margin_start = 3
		};
		header_box.append (sectionrow_grid);
		header_box.append (separator);

		var sectionrow_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			reveal_child = !is_inbox_section
		};

		sectionrow_revealer.child = header_box;

		handle_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			margin_top = is_inbox_section ? 12 : 0,
			margin_start = 21
		};

		handle_grid.append (sectionrow_revealer);
		handle_grid.add_css_class ("transition");

		listbox = new Gtk.ListBox () {
			valign = Gtk.Align.START,
			selection_mode = Gtk.SelectionMode.NONE,
			hexpand = true,
		};

		listbox.add_css_class ("listbox-background");

		var listbox_grid = new Adw.Bin () {
			margin_top = 0,
			child = listbox
		};

		drop_widget = new Gtk.Grid () {
            height_request = 27,
			margin_start = 21,
            css_classes = { "drop-area", "drop-target" }
		};

		drop_widget_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			child = drop_widget
		};

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
			reveal_child = true
		};

		checked_revealer.child = checked_listbox_grid;

		var bottom_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			hexpand = true
		};

		bottom_grid.append (listbox_grid);
		bottom_grid.append (drop_widget_revealer);
		bottom_grid.append (checked_revealer);

		bottom_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			reveal_child =  true
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
		show_completed_changed ();
		build_drag_and_drop ();

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

		var edit_gesture = new Gtk.GestureClick ();
		edit_gesture.set_button (1);
		handle_grid.add_controller (edit_gesture);

		edit_gesture.pressed.connect (() => {
			Timeout.add (Constants.DRAG_TIMEOUT, () => {
				if (!on_drag) {
					name_editable.editing (true);
				}

				return GLib.Source.REMOVE;
			});
		});

		Services.EventBus.get_default ().checked_toggled.connect ((item, old_checked) => {
			if (item.project_id == section.project_id && item.section_id == section.id &&
			    item.parent_id == "") {
				if (!old_checked) {
					if (items.has_key (item.id_string)) {
						items [item.id_string].hide_destroy ();
						items.unset (item.id_string);
					}

					if (!items_checked.has_key (item.id_string)) {
						items_checked [item.id_string] = new Layouts.ItemRow (item);
						checked_listbox.insert (items_checked [item.id_string], 0);
					}
				} else {
					if (items_checked.has_key (item.id_string)) {
						items_checked [item.id_string].hide_destroy ();
						items_checked.unset (item.id_string);
					}

					if (!items.has_key (item.id_string)) {
						items [item.id_string] = new Layouts.ItemRow (item);
						listbox.append (items [item.id_string]);
					}
				}
			}
		});

		Services.Database.get_default ().item_updated.connect ((item, update_id) => {
			if (items.has_key (item.id_string)) {
				if (items [item.id_string].update_id != update_id) {
					items [item.id_string].update_request ();
					update_sort ();
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

		Services.EventBus.get_default ().item_moved.connect ((item, old_project_id, old_section_id, old_parent_id) => {
			if (old_project_id == section.project_id &&
				old_section_id == section.id) {
				if (items.has_key (item.id_string)) {
					items [item.id_string].hide_destroy ();
					items.unset (item.id_string);
				}

				if (items_checked.has_key (item.id_string)) {
					items_checked [item.id_string].hide_destroy ();
					items_checked.unset (item.id_string);
				}
			}

			if (item.project_id == section.project_id &&
				item.section_id == section.id &&
			    item.parent_id == "") {
				add_item (item);
			}
		});

		Services.EventBus.get_default ().update_items_position.connect ((project_id, section_id) => {
			if (section.project_id == project_id && section.id == section_id) {
			}
		});

		Services.EventBus.get_default ().magic_button_activated.connect ((value) => {
			if (!is_inbox_section) {
			}
		});

		Services.EventBus.get_default ().update_inserted_item_map.connect ((_row, old_section_id) => {
			var row = (Layouts.ItemRow) _row;

			if (row.item.project_id == section.project_id &&
			    row.item.section_id == section.id) {
				if (!items.has_key (row.item.id)) {
					items [row.item.id] = row;
					update_sort ();
				}
			}

			if (row.item.project_id == section.project_id &&
			    row.item.section_id != section.id &&
				old_section_id == section.id) {
				if (items.has_key (row.item.id)) {
					items.unset (row.item.id);
				}
			}
		});

		name_editable.focus_changed.connect ((active) => {
			Services.EventBus.get_default ().unselect_all ();

			if (active) {
				hide_revealer.reveal_child = false;
				placeholder_revealer.reveal_child = false;
			} else {
				placeholder_revealer.reveal_child = true;
			}
		});

		section.project.show_completed_changed.connect (show_completed_changed);

		section.project.sort_order_changed.connect (() => {
			update_sort ();
		});

		Services.EventBus.get_default ().update_section_sort_func.connect ((project_id, section_id, value) => {
			if (section.project_id == project_id && section.id == section_id) {
				if (value) {
					update_sort ();
				} else {
					listbox.set_sort_func (null);
				}
			}
		});

		section.section_count_updated.connect (() => {
			count_label.label = section.section_count.to_string ();
			count_revealer.reveal_child = int.parse (count_label.label) > 0;
		});

		Services.EventBus.get_default ().item_drag_begin.connect ((item) => {
			if (item.project_id == section.project_id) {
				check_drop_widget ();
			}
		});

		Services.EventBus.get_default ().item_drag_end.connect ((item) => {
			if (item.project_id == section.project_id) {
				drop_widget_revealer.reveal_child = false;
			}
		});

        add_button.clicked.connect (() => {
            prepare_new_item ();
        });

		var motion_gesture = new Gtk.EventControllerMotion ();
        sectionrow_grid.add_controller (motion_gesture);

        motion_gesture.enter.connect (() => {
            actions_box_revealer.reveal_child = true;
        });

        motion_gesture.leave.connect (() => {
			if (!menu_button.active) {
				actions_box_revealer.reveal_child = false;
			}
        });
	}

	private void check_drop_widget () {
		drop_widget_revealer.reveal_child = items.size <= 0;
	}

	private void show_completed_changed () {
		if (section.project.show_completed) {
			add_completed_items ();
		} else {
			foreach (Layouts.ItemRow row in items_checked.values) {
				row.hide_destroy ();
			}

			items_checked.clear ();
		}

		checked_revealer.reveal_child = section.project.show_completed;
	}

	public void add_completed_items () {
		foreach (Layouts.ItemRow row in items_checked.values) {
			row.hide_destroy ();
		}

		items_checked.clear ();

		foreach (Objects.Item item in is_inbox_section ? section.project.items : section.items) {
			add_complete_item (item);
		}
	}

	public void add_complete_item (Objects.Item item) {
		if (section.project.show_completed && item.checked) {
			if (!items_checked.has_key (item.id_string)) {
				items_checked [item.id_string] = new Layouts.ItemRow (item);
				checked_listbox.append (items_checked [item.id_string]);
			}
		}
	}

	private void update_sort () {
		if (section.project.sort_order == 0) {
			listbox.set_sort_func (null);
		} else {
			listbox.set_sort_func (set_sort_func);
		}
	}

	public void add_items () {
		items.clear ();

		Gtk.Widget child;
		for (child = listbox.get_first_child (); child != null; child = listbox.get_next_sibling ()) {
			child.destroy ();
		}

		foreach (Objects.Item item in is_inbox_section ? section.project.items : section.items) {
			add_item (item);
		}

		update_sort ();
	}

	public void add_item (Objects.Item item) {
		if (!item.checked && !items.has_key (item.id_string)) {
			items [item.id_string] = new Layouts.ItemRow (item);

			if (item.child_order <= -1) {
				listbox.append (items [item.id_string]);
			} else {
				listbox.insert (items [item.id_string], 0);
			}
		}
	}

	public void prepare_new_item (string content = "") {
		var dialog = new Dialogs.QuickAdd ();
        dialog.for_base_object (section);
        dialog.update_content (content);
        dialog.show ();
	}

	private int set_sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
		Objects.Item item1 = ((Layouts.ItemRow) lbrow).item;
		Objects.Item item2 = ((Layouts.ItemRow) lbbefore).item;

		if (section.project.sort_order == 1) {
			return item1.content.strip ().collate (item2.content.strip ());
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
			((Gtk.ListBox) parent).remove (this);
			return GLib.Source.REMOVE;
		});
	}

	private Gtk.Popover build_context_menu () {
		var add_item = new Widgets.ContextMenu.MenuItem (_("Add Task"), "plus");
		var edit_item = new Widgets.ContextMenu.MenuItem (_("Edit Section"), "planner-edit");
		var move_item = new Widgets.ContextMenu.MenuItem (_("Move Section"), "chevron-right");
		var manage_item = new Widgets.ContextMenu.MenuItem (_("Manage Section Order"), "ordered-list");
		var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete Section"), "planner-trash");
		delete_item.add_css_class ("menu-item-danger");

		var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		menu_box.margin_top = menu_box.margin_bottom = 3;
		menu_box.append (add_item);
		menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
		menu_box.append (edit_item);
		menu_box.append (move_item);
		menu_box.append (manage_item);
		menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
		menu_box.append (delete_item);

		var menu_popover = new Gtk.Popover () {
			has_arrow = false,
			child = menu_box,
			position = Gtk.PositionType.BOTTOM
		};

		add_item.clicked.connect (() => {
			menu_popover.popdown ();
			prepare_new_item ();
		});

		edit_item.clicked.connect (() => {
			menu_popover.popdown ();
			name_editable.editing (true);
		});

		move_item.clicked.connect (() => {
			menu_popover.popdown ();

			var dialog = new Dialogs.ProjectPicker.ProjectPicker (PickerType.PROJECTS, section.project.backend_type);
			dialog.project = section.project;
			dialog.show ();

			dialog.changed.connect ((type, id) => {
				if (type == "project") {
					move_section (id);
				}
			});
		});

		manage_item.clicked.connect (() => {
			menu_popover.popdown ();

			var dialog = new Dialogs.ManageSectionOrder (section.project);
			dialog.show ();
		});

		delete_item.clicked.connect (() => {
			menu_popover.popdown ();

			var dialog = new Adw.MessageDialog ((Gtk.Window) Planify.instance.main_window,
			                                    _("Delete section"), _("Are you sure you want to delete <b>%s</b>?".printf (Util.get_default ().get_dialog_text (section.short_name))));

			dialog.body_use_markup = true;
			dialog.add_response ("cancel", _("Cancel"));
			dialog.add_response ("delete", _("Delete"));
			dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
			dialog.show ();

			dialog.response.connect ((response) => {
				if (response == "delete") {
					if (section.project.backend_type == BackendType.TODOIST) {
						//  remove_button.is_loading = true;
						Services.Todoist.get_default ().delete.begin (section, (obj, res) => {
							Services.Todoist.get_default ().delete.end (res);
							Services.Database.get_default ().delete_section (section);
							// remove_button.is_loading = false;
							// message_dialog.hide_destroy ();
						});
					} else {
						Services.Database.get_default ().delete_section (section);
					}
				}
			});
		});

		return menu_popover;
	}

	private void build_drag_and_drop () {
		var drop_target = new Gtk.DropTarget (typeof (Layouts.ItemRow), Gdk.DragAction.MOVE);
		drop_target.preload = true;

		drop_target.drop.connect ((target, value, x, y) => {
			var picked_widget = (Layouts.ItemRow) value;
			var old_section_id = "";

			picked_widget.drag_end ();

			old_section_id = picked_widget.item.section_id;

			picked_widget.item.project_id = section.project_id;
			picked_widget.item.section_id = section.id;

			if (picked_widget.item.project.backend_type == BackendType.TODOIST) {
				string type = "section_id";
				string id = section.id;

				if (is_inbox_section) {
					type = "project_id";
					id = section.project_id;
				}

				Services.Todoist.get_default ().move_item.begin (picked_widget.item, type, id, (obj, res) => {
					if (Services.Todoist.get_default ().move_item.end (res).status) {
						Services.Database.get_default ().update_item (picked_widget.item);
					}
				});
			} else if (picked_widget.item.project.backend_type == BackendType.LOCAL) {
				Services.Database.get_default ().update_item (picked_widget.item);
			}

			var source_list = (Gtk.ListBox) picked_widget.parent;
			source_list.remove (picked_widget);

			listbox.append (picked_widget);
			Services.EventBus.get_default ().update_inserted_item_map (picked_widget, old_section_id, "");
			update_items_item_order (listbox);

			return true;
		});

		drop_widget.add_controller (drop_target);
	}

	private void update_items_item_order (Gtk.ListBox listbox) {
		unowned Layouts.ItemRow? item_row = null;
		var row_index = 0;

		do {
			item_row = (Layouts.ItemRow) listbox.get_row_at_index (row_index);

			if (item_row != null) {
				item_row.item.child_order = row_index;
				Services.Database.get_default ().update_item (item_row.item);
			}

			row_index++;
		} while (item_row != null);
	}

	public void drag_begin () {
		sectionrow_grid.add_css_class ("card");
		opacity = 0.3;
		on_drag = true;
		bottom_revealer.reveal_child = false;
	}

	public void drag_end () {
		sectionrow_grid.remove_css_class ("card");
		opacity = 1;
		on_drag = false;
	}

	private void move_section (string project_id) {
		string old_section_id = section.project_id;
		section.project_id = project_id;

		if (section.project.backend_type == BackendType.TODOIST) {
			// menu_loading_button.is_loading = true;
			Services.Todoist.get_default ().move_project_section.begin (section, project_id, (obj, res) => {
				if (Services.Todoist.get_default ().move_project_section.end (res).status) {
					Services.Database.get_default ().move_section (section, old_section_id);
					// menu_loading_button.is_loading = false;
				} else {
					// menu_loading_button.is_loading = false;
				}
			});
		} else if (section.project.backend_type == BackendType.LOCAL) {
			Services.Database.get_default ().move_section (section, project_id);
		}
	}
}
