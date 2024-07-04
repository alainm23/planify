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
    private Widgets.Markdown.EditView markdown_edit_view;
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
            if (Services.Settings.get_default ().settings.get_boolean ("always-show-completed-subtasks")) {
                return true;
            } else {
                return item.project.show_completed;
            }
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
            wrap_mode = Gtk.WrapMode.WORD
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

        markdown_edit_view = new Widgets.Markdown.EditView () {
            card = true,
            left_margin = 12,
            right_margin = 12,
            top_margin = 12,
            bottom_margin = 12,
        };
        markdown_edit_view.buffer = current_buffer;

        var description_group = new Adw.PreferencesGroup () {
            margin_start = 12,
            margin_end = 12,
            margin_top = 12
        };
		description_group.title = _("Description");
        description_group.add (markdown_edit_view);

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

        schedule_button.date_changed.connect ((datetime) => {
            update_due (datetime);
        });

        priority_button.changed.connect ((priority) => {
            if (item.priority != priority) {
                item.priority = priority;

                if (item.project.backend_type == BackendType.TODOIST ||
                    item.project.backend_type == BackendType.CALDAV) {
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
            update_pinned (!item.pinned);
        });

        section_button.selected.connect ((section) => {
            move (item.project, section.id, "");
        });

        reminder_button.reminder_added.connect ((reminder) => {
            reminder.item_id = item.id;

            if (item.project.backend_type == BackendType.TODOIST) {
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
        item = _item;
        update_id = Util.get_default ().generate_id ();

        label_button.backend_type = item.project.backend_type;
        update_request ();
        subitems.present_item (item);
        attachments.present_item (item);
        subitems.reveal_child = true;
        
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

        content_textview.sensitive = !item.completed;
        markdown_edit_view.sensitive = !item.completed;
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

    public void update_due (GLib.DateTime? datetime) {
        if (item == null) {
            return;
        }

        item.update_due (datetime);
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

    public void update_pinned (bool pinned) {
        item.pinned = pinned;
        
        if (item.project.backend_type == BackendType.CALDAV) {
            item.update_async ("");
        } else {
            item.update_local ();
        }
    }

    private Gtk.Popover build_context_menu () {
        var back_item = new Widgets.ContextMenu.MenuItem (_("Back"), "go-previous-symbolic");

        var use_note_item = new Widgets.ContextMenu.MenuSwitch (_("Use as a Note"), "paper-symbolic");
        use_note_item.active = item.item_type == ItemType.NOTE;

        copy_clipboard_item = new Widgets.ContextMenu.MenuItem (_("Copy to Clipboard"), "clipboard-symbolic");
        duplicate_item = new Widgets.ContextMenu.MenuItem (_("Duplicate"), "tabs-stack-symbolic");
        move_item = new Widgets.ContextMenu.MenuItem (_("Move"), "arrow3-right-symbolic");
        repeat_item = new Widgets.ContextMenu.MenuItem (_("Repeat"), "playlist-repeat-symbolic");
        repeat_item.arrow = true;

        var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete Task"), "user-trash-symbolic");
        delete_item.add_css_class ("menu-item-danger");

        var more_information_item = new Widgets.ContextMenu.MenuItem ("", null);
        more_information_item.add_css_class ("caption");

        var popover = new Gtk.Popover () {
            has_arrow = false,
            position = Gtk.PositionType.BOTTOM,
            width_request = 225
        };

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;

        if (!item.completed) {
            menu_box.append (use_note_item);
            menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
            menu_box.append (copy_clipboard_item);
            menu_box.append (duplicate_item);
            menu_box.append (move_item);
            menu_box.append (repeat_item);
            menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        }

        
        menu_box.append (delete_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (more_information_item);

        var menu_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT,
            vhomogeneous = false
        };

        menu_stack.add_named (menu_box, "menu");
        menu_stack.add_named (get_repeat_widget (popover, back_item), "repeat");

        popover.child = menu_stack;

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

            BackendType backend_type;
            if (item.project.is_inbox_project) {
                backend_type = BackendType.ALL;
            } else {
                backend_type = item.project.backend_type;
            }

            var dialog = new Dialogs.ProjectPicker.ProjectPicker (PickerType.PROJECTS, backend_type);
            dialog.add_sections (item.project.sections);
            dialog.project = item.project;
            dialog.section = item.section;
            dialog.present (Planify._instance.main_window);

            dialog.changed.connect ((type, id) => {
                if (type == "project") {
                    move (Services.Database.get_default ().get_project (id), "");
                } else {
                    move (item.project, id);
                }
            });
        });

        repeat_item.clicked.connect (() => {
            menu_stack.set_visible_child_name ("repeat");
        });

        popover.closed.connect (() => {
            menu_stack.set_visible_child_name ("menu");
        });

        back_item.clicked.connect (() => {
            menu_stack.set_visible_child_name ("menu");
        });

        popover.show.connect (() => {
            more_information_item.title = get_updated_info ();
        });

        delete_item.activate_item.connect (() => {
            popover.popdown ();
            delete_request ();
        });

        return popover;
    }

    private Gtk.Widget get_repeat_widget (Gtk.Popover popover, Widgets.ContextMenu.MenuItem back_item) {
        var none_item = new Widgets.ContextMenu.MenuItem (_("None"));
        var daily_item = new Widgets.ContextMenu.MenuItem (_("Daily"));
        var weekly_item = new Widgets.ContextMenu.MenuItem (_("Weekly"));
        var monthly_item = new Widgets.ContextMenu.MenuItem (_("Monthly"));
        var yearly_item = new Widgets.ContextMenu.MenuItem (_("Yearly"));
        var custom_item = new Widgets.ContextMenu.MenuItem (_("Custom"));
        
        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (back_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (daily_item);
        menu_box.append (weekly_item);
        menu_box.append (monthly_item);
        menu_box.append (yearly_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (none_item);
        menu_box.append (custom_item);
        
        daily_item.clicked.connect (() => {
            popover.popdown ();

            var duedate = new Objects.DueDate ();
            duedate.is_recurring = true;
            duedate.recurrency_type = RecurrencyType.EVERY_DAY;
            duedate.recurrency_interval = 1;

            item.set_recurrency (duedate);
        });

        weekly_item.clicked.connect (() => {
            popover.popdown ();

            var duedate = new Objects.DueDate ();
            duedate.is_recurring = true;
            duedate.recurrency_type = RecurrencyType.EVERY_WEEK;
            duedate.recurrency_interval = 1;

            item.set_recurrency (duedate);
        });

        monthly_item.clicked.connect (() => {
            popover.popdown ();

            var duedate = new Objects.DueDate ();
            duedate.is_recurring = true;
            duedate.recurrency_type = RecurrencyType.EVERY_MONTH;
            duedate.recurrency_interval = 1;

            item.set_recurrency (duedate);
        });

        yearly_item.clicked.connect (() => {
            popover.popdown ();

            var duedate = new Objects.DueDate ();
            duedate.is_recurring = true;
            duedate.recurrency_type = RecurrencyType.EVERY_YEAR;
            duedate.recurrency_interval = 1;

            item.set_recurrency (duedate);
        });

        none_item.clicked.connect (() => {
            popover.popdown ();

            var duedate = new Objects.DueDate ();
            duedate.is_recurring = false;
            duedate.recurrency_type = RecurrencyType.NONE;
            duedate.recurrency_interval = 0;

            item.set_recurrency (duedate);
        });

        custom_item.clicked.connect (() => {
            popover.popdown ();

            var dialog = new Dialogs.RepeatConfig ();
            dialog.present (Planify._instance.main_window);

            if (item.has_due) {
                dialog.duedate = item.due;
            }

            dialog.change.connect ((duedate) => {
                item.set_recurrency (duedate);
            });
        });

        return menu_box;
    }

    public void move (Objects.Project project, string section_id, string parent_id = "") {
        string project_id = project.id;

        if (item.project.backend_type != project.backend_type) {
            Util.get_default ().move_backend_type_item.begin (item, project);
        } else {
            if (item.project_id != project_id || item.section_id != section_id || item.parent_id != parent_id) {
                item.move (project, section_id);
            }
        }
    }

    private string get_updated_info () {
        string added_at = _("Added at");
        string updated_at = _("Updated at");
        string added_date = Utils.Datetime.get_relative_date_from_date (item.added_datetime);
        string updated_date = "(" + _("Not available") + ")";
        if (item.updated_at != "") {
            updated_date = Utils.Datetime.get_relative_date_from_date (item.updated_datetime);
        }

        return "<b>%s:</b> %s\n<b>%s:</b> %s".printf (added_at, added_date, updated_at, updated_date);
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
            item.checked = false;
            item.completed_at = "";
            _complete_item (old_checked);
        }
    }

    private void complete_item (bool old_checked) {
        if (Services.Settings.get_default ().settings.get_boolean ("task-complete-tone")) {
            Util.get_default ().play_audio ();
        }
        
        if (item.due.is_recurring && !item.due.is_recurrency_end) {
            update_next_recurrency ();
        } else {
            item.checked = true;
            item.completed_at = Utils.Datetime.get_format_date (
                new GLib.DateTime.now_local ()
            ).to_string ();
            _complete_item (old_checked);
        }
	}

    private void _complete_item (bool old_checked) {
        if (item.project.backend_type == BackendType.LOCAL) {
            Services.Database.get_default ().checked_toggled (item, old_checked);
        } else if (item.project.backend_type == BackendType.TODOIST) {
            item.loading = true;
            Services.Todoist.get_default ().complete_item.begin (item, (obj, res) => {
                if (Services.Todoist.get_default ().complete_item.end (res).status) {
                    Services.Database.get_default ().checked_toggled (item, old_checked);
                }

                item.loading = false;
            });
        } else if (item.project.backend_type == BackendType.CALDAV) {
            item.loading = true;
            Services.CalDAV.Core.get_default ().complete_item.begin (item, (obj, res) => {
                if (Services.CalDAV.Core.get_default ().complete_item.end (res).status) {
                    Services.Database.get_default ().checked_toggled (item, old_checked);
                }

                item.loading = false;
            });
        }
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
		Services.EventBus.get_default ().send_notification (toast);
	}
}
