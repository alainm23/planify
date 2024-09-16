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

public class Layouts.ItemSidebarView : Adw.Bin {
	public Objects.Item item { get; set; }

	private Gtk.Button parent_back_button;
	private Gtk.Label parent_label;
	private Gtk.Revealer spinner_revealer;
	private Widgets.TextView content_textview;
	private Widgets.Markdown.Buffer current_buffer;
	private Widgets.Markdown.EditView markdown_edit_view = null;
	private Gtk.Revealer markdown_revealer;
	private Widgets.StatusButton status_button;
	private Widgets.ScheduleButton schedule_button;
	private Widgets.PriorityButton priority_button;
	private Widgets.LabelPicker.LabelButton label_button;
	private Widgets.PinButton pin_button;
	private Widgets.SectionPicker.SectionButton section_button;
	private Widgets.ReminderPicker.ReminderButton reminder_button;
	private Widgets.SubItems subitems;
	private Widgets.Attachments attachments;

	private Widgets.ContextMenu.MenuItem copy_clipboard_item;
	private Widgets.ContextMenu.MenuItem duplicate_item;
	private Widgets.ContextMenu.MenuItem move_item;
	private Widgets.ContextMenu.MenuItem repeat_item;

	private Gee.HashMap<ulong, GLib.Object> signals_map = new Gee.HashMap<ulong, GLib.Object> ();
	public string update_id { get; set; default = Util.get_default ().generate_id (); }
	private ulong description_handler_change_id = 0;

	public bool show_completed {
		get {
			return Services.Settings.get_default ().settings.get_boolean ("always-show-completed-subtasks");
		}
	}

	construct {
		var previous_icon = new Gtk.Image.from_icon_name ("go-previous-symbolic");

		parent_label = new Gtk.Label (null) {
			css_classes = { "font-bold" },
			ellipsize = Pango.EllipsizeMode.END
		};

		var parent_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
		parent_box.append (previous_icon);
		parent_box.append (parent_label);

		parent_back_button = new Gtk.Button () {
			child = parent_box,
			css_classes = { "flat" },
			valign = Gtk.Align.CENTER
		};

		var close_button = new Gtk.Button.from_icon_name ("step-out-symbolic") {
			tooltip_text = _("Close Detail")
		};

		var menu_button = new Gtk.MenuButton () {
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			popover = build_context_menu (),
			icon_name = "view-more-symbolic",
			css_classes = { "flat" }
		};

		pin_button = new Widgets.PinButton ();

		var spinner = new Gtk.Spinner () {
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			spinning = true
		};

		spinner_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.CROSSFADE,
			child = spinner
		};

		var headerbar = new Adw.HeaderBar () {
			title_widget = new Gtk.Label (null),
			hexpand = true,
			decoration_layout = ":",
			css_classes = { "flat" }
		};

		headerbar.pack_start (parent_back_button);
		headerbar.pack_end (close_button);
		headerbar.pack_end (menu_button);
		headerbar.pack_end (pin_button);
		headerbar.pack_end (spinner_revealer);

		content_textview = new Widgets.TextView () {
			left_margin = 12,
			right_margin = 12,
			top_margin = 12,
			bottom_margin = 12,
			height_request = 64,
			wrap_mode = Gtk.WrapMode.WORD,
			accepts_tab = false
		};

		content_textview.remove_css_class ("view");
		content_textview.add_css_class ("card");

		var content_group = new Adw.PreferencesGroup () {
			margin_start = 12,
			margin_end = 12
		};
		content_group.title = _("Title");
		content_group.add (content_textview);

		status_button = new Widgets.StatusButton ();
		section_button = new Widgets.SectionPicker.SectionButton ();
		schedule_button = new Widgets.ScheduleButton.for_board ();
		priority_button = new Widgets.PriorityButton.for_board ();
		label_button = new Widgets.LabelPicker.LabelButton.for_board ();
		reminder_button = new Widgets.ReminderPicker.ReminderButton.for_board ();

		var properties_grid = new Gtk.Grid () {
			column_homogeneous = true,
			column_spacing = 12,
			row_homogeneous = true,
			row_spacing = 12
		};

		properties_grid.attach (status_button, 0, 0);
		properties_grid.attach (section_button, 1, 0);
		properties_grid.attach (schedule_button, 0, 1);
		properties_grid.attach (priority_button, 1, 1);
		properties_grid.attach (label_button, 0, 2);
		properties_grid.attach (reminder_button, 1, 2);

		var properties_group = new Adw.PreferencesGroup () {
			margin_start = 12,
			margin_end = 12,
			margin_top = 12
		};

		properties_group.title = _("Properties");
		properties_group.add (properties_grid);

		current_buffer = new Widgets.Markdown.Buffer ();

		markdown_revealer = new Gtk.Revealer ();

		var description_group = new Adw.PreferencesGroup () {
			margin_start = 12,
			margin_end = 12,
			margin_top = 12
		};
		description_group.title = _("Description");
		description_group.add (markdown_revealer);

		subitems = new Widgets.SubItems.for_board () {
			margin_top = 12
		};

		attachments = new Widgets.Attachments (true) {
			margin_top = 12,
			card = true
		};

		var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			valign = Gtk.Align.START,
			margin_bottom = 24,
			margin_start = 6,
			margin_end = 6
		};

		content.append (content_group);
		content.append (properties_group);
		content.append (description_group);
		content.append (subitems);
		content.append (attachments);

		var scrolled_window = new Widgets.ScrolledWindow (content);

		var toolbar_view = new Adw.ToolbarView () {
			bottom_bar_style = Adw.ToolbarStyle.RAISED_BORDER,
			reveal_bottom_bars = false
		};
		toolbar_view.add_top_bar (headerbar);
		toolbar_view.content = scrolled_window;

		child = toolbar_view;

		close_button.clicked.connect (() => {
			Services.EventBus.get_default ().close_item ();
		});

		var content_controller_key = new Gtk.EventControllerKey ();
		content_textview.add_controller (content_controller_key);
		content_controller_key.key_released.connect ((keyval, keycode, state) => {
			update_content_description ();
		});

		schedule_button.duedate_changed.connect (() => {
			update_due (schedule_button.duedate);
		});

		priority_button.changed.connect ((priority) => {
			if (item.priority != priority) {
				item.priority = priority;

				if (item.project.source_type == SourceType.TODOIST ||
				    item.project.source_type == SourceType.CALDAV) {
					item.update_async ("");
				} else {
					item.update_local ();
				}
			}
		});

		label_button.labels_changed.connect ((labels) => {
			update_labels (labels);
		});

		pin_button.changed.connect (() => {
			item.update_pin (!item.pinned);
		});

		section_button.selected.connect ((section) => {
			move (item.project, section.id, "");
		});

		reminder_button.reminder_added.connect ((reminder) => {
			reminder.item_id = item.id;

			if (item.project.source_type == SourceType.TODOIST) {
				item.loading = true;
				Services.Todoist.get_default ().add.begin (reminder, (obj, res) => {
					HttpResponse response = Services.Todoist.get_default ().add.end (res);
					item.loading = false;

					if (response.status) {
						reminder.id = response.data;
					} else {
						reminder.id = Util.get_default ().generate_id (reminder);
					}

					item.add_reminder_if_not_exists (reminder);
				});
			} else {
				reminder.id = Util.get_default ().generate_id (reminder);
				item.add_reminder_if_not_exists (reminder);
			}
		});

		status_button.changed.connect ((active) => {
			checked_toggled (active);
		});

		parent_back_button.clicked.connect (() => {
			if (item.has_parent) {
				Services.EventBus.get_default ().open_item (item.parent);
			} else {
				Services.EventBus.get_default ().close_item ();
			}
		});
	}

	private void update_content_description () {
		if (item.content != content_textview.buffer.text ||
		    item.description != current_buffer.get_all_text ().chomp ()) {
			item.content = content_textview.buffer.text;
			item.description = current_buffer.get_all_text ().chomp ();
			item.update_async_timeout (update_id);
		}
	}

	public void present_item (Objects.Item _item) {
		if (Services.Settings.get_default ().settings.get_boolean ("always-show-details-sidebar")) {
			disconnect_all ();	
		}

		item = _item;
		update_id = Util.get_default ().generate_id ();

		build_markdown_edit_view ();

		label_button.source = item.project.source;
		update_request ();

		subitems.present_item (item);
		subitems.reveal_child = true;

		attachments.present_item (item);

		if (item.has_parent) {
			parent_label.label = item.parent.content;
			parent_label.tooltip_text = item.parent.content;
		} else {
			if (item.section_id != "") {
				parent_label.label = item.section.name;
				parent_label.tooltip_text = item.section.name;
			} else {
				parent_label.label = item.project.name;
				parent_label.tooltip_text = item.project.name;
			}
		}

		content_textview.grab_focus ();

		signals_map[Services.EventBus.get_default ().checked_toggled.connect ((_item) => {
			if (item.id == _item.id) {
				update_request ();
			}
		})] = Services.EventBus.get_default ();

		signals_map[item.updated.connect ((_update_id) => {
			if (update_id != _update_id) {
				update_request ();
			}
		})] = item;

		signals_map[item.pin_updated.connect (() => {
			pin_button.update_from_item (item);
		})] = item;

		signals_map[item.reminder_added.connect ((reminder) => {
			reminder_button.add_reminder (reminder, item.reminders);
		})] = item;

		signals_map[item.reminder_deleted.connect ((reminder) => {
			reminder_button.delete_reminder (reminder, item.reminders);
		})] = item;

		signals_map[item.loading_change.connect (() => {
			spinner_revealer.reveal_child = item.loading;
		})] = item;
	}

	public void disconnect_all () {
		foreach (var entry in signals_map.entries) {
			entry.value.disconnect (entry.key);
		}

		if (description_handler_change_id != 0) {
			current_buffer.disconnect (description_handler_change_id);
			description_handler_change_id = 0;
		}

		signals_map.clear ();
		subitems.disconnect_all ();
		attachments.disconnect_all ();

		destroy_markdown_edit_view ();
	}

	public void update_request () {
		content_textview.buffer.text = item.content;

		if (description_handler_change_id != 0) {
			current_buffer.disconnect (description_handler_change_id);
			description_handler_change_id = 0;
		}

		current_buffer.text = item.description;

		if (description_handler_change_id == 0) {
			description_handler_change_id = current_buffer.changed.connect (() => {
				update_content_description ();
			});
		}

		schedule_button.update_from_item (item);
		priority_button.update_from_item (item);
		status_button.update_from_item (item);

		label_button.labels = item._get_labels ();
		label_button.update_from_item (item);

		pin_button.update_from_item (item);

		section_button.set_sections (item.project.sections);
		section_button.update_from_item (item);

		reminder_button.set_reminders (item.reminders);

		content_textview.editable = !item.completed;
		markdown_edit_view.is_editable = !item.completed;
		schedule_button.sensitive = !item.completed;
		priority_button.sensitive = !item.completed;
		label_button.sensitive = !item.completed;
		pin_button.sensitive = !item.completed;
		section_button.sensitive = !item.completed;
		reminder_button.sensitive = !item.completed;
		copy_clipboard_item.sensitive = !item.completed;
		duplicate_item.sensitive = !item.completed;
		move_item.sensitive = !item.completed;
		repeat_item.sensitive = !item.completed;
		subitems.add_button.sensitive = !item.completed;
	}

	public void update_due (Objects.DueDate duedate) {
		if (item == null) {
			return;
		}

		item.update_due (duedate);
	}

	public void update_labels (Gee.HashMap<string, Objects.Label> new_labels) {
		bool update = false;

		foreach (var entry in new_labels.entries) {
			if (item.get_label (entry.key) == null) {
				item.add_label_if_not_exists (entry.value);
				update = true;
			}
		}

		foreach (var label in item._get_labels ()) {
			if (!new_labels.has_key (label.id)) {
				item.delete_item_label (label.id);
				update = true;
			}
		}

		if (!update) {
			return;
		}

		item.update_async ("");
	}

	private Gtk.Popover build_context_menu () {
		var use_note_item = new Widgets.ContextMenu.MenuSwitch (_("Use as a Note"), "paper-symbolic");
		use_note_item.active = item.item_type == ItemType.NOTE;

		copy_clipboard_item = new Widgets.ContextMenu.MenuItem (_("Copy to Clipboard"), "clipboard-symbolic");
		duplicate_item = new Widgets.ContextMenu.MenuItem (_("Duplicate"), "tabs-stack-symbolic");
		move_item = new Widgets.ContextMenu.MenuItem (_("Move"), "arrow3-right-symbolic");
		repeat_item = new Widgets.ContextMenu.MenuItem (_("Repeat"), "playlist-repeat-symbolic");
		repeat_item.arrow = true;

		var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete Task"), "user-trash-symbolic");
		delete_item.add_css_class ("menu-item-danger");

		var more_information_item = new Widgets.ContextMenu.MenuItem (_("Change History"), "rotation-edit-symbolic");

		var popover = new Gtk.Popover () {
			has_arrow = false,
			position = Gtk.PositionType.BOTTOM,
			width_request = 250
		};

		var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		menu_box.margin_top = menu_box.margin_bottom = 3;

		if (!item.completed) {
			menu_box.append (use_note_item);
			menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
			menu_box.append (copy_clipboard_item);
			menu_box.append (duplicate_item);
			menu_box.append (move_item);
		}


		menu_box.append (delete_item);
		menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
		menu_box.append (more_information_item);

		popover.child = menu_box;

		use_note_item.activate_item.connect (() => {
			item.item_type = use_note_item.active ? ItemType.NOTE : ItemType.TASK;
			item.update_local ();
		});

		copy_clipboard_item.clicked.connect (() => {
			popover.popdown ();
			item.copy_clipboard ();
		});

		duplicate_item.clicked.connect (() => {
			popover.popdown ();
			Util.get_default ().duplicate_item.begin (item, item.project_id, item.section_id, item.parent_id);
		});

		move_item.clicked.connect (() => {
			popover.popdown ();

			Dialogs.ProjectPicker.ProjectPicker dialog;
			if (item.project.is_inbox_project) {
				dialog = new Dialogs.ProjectPicker.ProjectPicker.for_projects ();
			} else {
				dialog = new Dialogs.ProjectPicker.ProjectPicker.for_project (item.source);
			}

			dialog.add_sections (item.project.sections);
			dialog.project = item.project;
			dialog.section = item.section;
			dialog.present (Planify._instance.main_window);

			dialog.changed.connect ((type, id) => {
				if (type == "project") {
					move (Services.Store.instance ().get_project (id), "");
				} else {
					move (item.project, id);
				}
			});
		});

		delete_item.activate_item.connect (() => {
			popover.popdown ();
			delete_request ();
		});

		more_information_item.activate_item.connect (() => {
			popover.popdown ();
			var dialog = new Dialogs.ItemChangeHistory (item);
			dialog.present (Planify._instance.main_window);
		});

		return popover;
	}

	public void move (Objects.Project project, string section_id, string parent_id = "") {
		string project_id = project.id;

		if (item.project.source_id != project.source_id) {
			Util.get_default ().move_backend_type_item.begin (item, project);
		} else {
			if (item.project_id != project_id || item.section_id != section_id || item.parent_id != parent_id) {
				item.move (project, section_id);
			}
		}
	}

	public void delete_request (bool undo = true) {
		var dialog = new Adw.AlertDialog (
			_("Are you sure you want to delete?"),
			_("This can not be undone")
			);

		dialog.add_response ("cancel", _("Cancel"));
		dialog.add_response ("delete", _("Delete"));
		dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
		dialog.present (Planify._instance.main_window);

		dialog.response.connect ((response) => {
			if (response == "delete") {
				item.delete_item ();
				Services.EventBus.get_default ().close_item ();
			}
		});
	}

	public void prepare_new_item (string content = "") {
		var dialog = new Dialogs.QuickAdd ();
		dialog.for_base_object (item);
		dialog.update_content (content);
		dialog.present (Planify._instance.main_window);
	}

	public void checked_toggled (bool active) {
		bool old_checked = item.checked;

		if (active) {
			complete_item (old_checked);
		} else {
			var old_completed_at = item.completed_at;

			item.checked = false;
			item.completed_at = "";
			_complete_item.begin (old_checked, old_completed_at);
		}
	}

	private void complete_item (bool old_checked) {
		if (Services.Settings.get_default ().settings.get_boolean ("task-complete-tone")) {
			Util.get_default ().play_audio ();
		}

		if (item.due.is_recurring && !item.due.is_recurrency_end) {
			update_next_recurrency ();
		} else {
			var old_completed_at = item.completed_at;

			item.checked = true;
			item.completed_at = new GLib.DateTime.now_local ().to_string ();
			_complete_item (old_checked, old_completed_at);
		}
	}

	private async void _complete_item (bool old_checked, string old_completed_at) {
		HttpResponse response = yield item.complete_item (old_checked);

		if (!response.status) {
			_complete_item_error (response, old_checked, old_completed_at);
		}
	}

	private void _complete_item_error (HttpResponse response, bool old_checked, string old_completed_at) {
		item.checked = old_checked;
		item.completed_at = old_completed_at;

		Services.EventBus.get_default ().send_error_toast (response.error_code, response.error);
	}

	private void update_next_recurrency () {
		var promise = new Services.Promise<GLib.DateTime> ();

		promise.resolved.connect ((result) => {
			recurrency_update_complete (result);
		});

		item.update_next_recurrency (promise);
	}

	private void recurrency_update_complete (GLib.DateTime next_recurrency) {
		var title = _("Completed. Next occurrence: %s".printf (Utils.Datetime.get_default_date_format_from_date (next_recurrency)));
		var toast = Util.get_default ().create_toast (title, 3);
		Services.EventBus.get_default ().send_toast (toast);
	}

	private void build_markdown_edit_view () {
		if (markdown_edit_view != null) {
			return;
		}

		markdown_edit_view = new Widgets.Markdown.EditView () {
			card = true,
			left_margin = 12,
			right_margin = 12,
			top_margin = 12,
			bottom_margin = 12,
			margin_top = 3,
			margin_bottom = 3,
			margin_start = 3,
			margin_end = 3
		};
		markdown_edit_view.buffer = current_buffer;

		markdown_revealer.child = markdown_edit_view;
		markdown_revealer.reveal_child = true;
	}

	private void destroy_markdown_edit_view () {
		markdown_revealer.reveal_child = false;
		markdown_revealer.child = null;
		markdown_edit_view = null;
	}
}
