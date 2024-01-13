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

public class Dialogs.Preferences.Pages.Backup : Adw.Bin {
	private Gtk.Stack stack;

	public signal void pop_subpage ();
	public signal void popup_toast (string message);
    construct {
        var settings_header = new Dialogs.Preferences.SettingsHeader (_("Backups"));

		stack = new Gtk.Stack () {
			hexpand = true,
			vexpand = true,
			transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT
		};

		stack.add_named (get_backup_page (), "backup-page");

		var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (settings_header);
		toolbar_view.content = stack;

		child = toolbar_view;

		settings_header.back_activated.connect (() => {
			pop_subpage ();
		});
    }

	private Gtk.Widget get_backup_page () {
		var description_label = new Gtk.Label (
            _("Never worry about losing your data. You can create backups of your active projects, tasks and comments and import them later.") // vala-lint=line-length
        ) {
			justify = Gtk.Justification.FILL,
			use_markup = true,
			wrap = true,
			xalign = 0,
			margin_end = 6,
			margin_start = 6
		};

		var add_button = new Gtk.Button.with_label (_("Create Backup")) {
			margin_top = 12
		};

		var import_button = new Gtk.Button.with_label (_("Import Backup"));

		var backups_group = new Layouts.HeaderItem (_("Backup Files")) {
			margin_top = 12,
			reveal = true
		};
		
		backups_group.set_sort_func (set_sort_func);

		var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
			vexpand = true,
			hexpand = true
		};

		content_box.append (description_label);
		content_box.append (add_button);
		content_box.append (import_button);
		content_box.append (backups_group);

		var content_clamp = new Adw.Clamp () {
			maximum_size = 400,
			margin_start = 24,
			margin_end = 24,
			margin_top = 12,
			margin_bottom = 12,
			child = content_box
		};

		var scrolled_window = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
			child = content_clamp
        };

		add_button.clicked.connect (() => {
			Services.Backups.get_default ().create_backup ();
		});

		import_button.clicked.connect (() => {
			Services.Backups.get_default ().import_backup.begin ((obj, res) => {
				GLib.File file = Services.Backups.get_default ().import_backup.end (res);

				var backup = new Objects.Backup.from_file (file);

				if (backup.valid ()) {
					Gtk.Widget? import_page;
					import_page = (Gtk.Widget) stack.get_child_by_name ("import-page");

					if (import_page != null) {
						stack.remove (import_page);
					}

					stack.add_named (get_import_page (backup), "import-page");
					stack.set_visible_child_name ("import-page");
				} else {
					debug ("%s", backup.error);
					popup_toast (_("Selected file is invalid"));
				}
			});
		});

		foreach (Objects.Backup backup in Services.Backups.get_default ().backups) {
			add_backup_row (backup, backups_group);
		}

		Services.Backups.get_default ().backup_added.connect ((backup) => {
			add_backup_row (backup, backups_group);
		});

		return scrolled_window;
	}

	private Gtk.Widget get_import_page (Objects.Backup backup) {
		var title = new Gtk.Label (_("Import Overview")) {
			halign = CENTER,
			css_classes = { "h1" }
		};
		var subtitle = new Gtk.Label (backup.title) {
			halign = CENTER,
			css_classes = { "dim-label" },
			margin_top = 3
		};

		var todoist_row = new Adw.ActionRow ();
		todoist_row.title = _("Todoist");
		todoist_row.add_suffix (generate_icon (backup.todoist_backend ? "object-select-symbolic" : "window-close-symbolic", 16));

		var general_group = new Adw.PreferencesGroup () {
			margin_top = 24
		};
		general_group.add (todoist_row);

		var projects_row = new Adw.ActionRow ();
		projects_row.title = _("Projects");
		projects_row.add_suffix (new Gtk.Label (backup.projects.size.to_string ()));

		var sections_row = new Adw.ActionRow ();
		sections_row.title = _("Sections");
		sections_row.add_suffix (new Gtk.Label (backup.sections.size.to_string ()));

		var items_row = new Adw.ActionRow ();
		items_row.title = _("Items");
		items_row.add_suffix (new Gtk.Label (backup.items.size.to_string ()));

		var labels_row = new Adw.ActionRow ();
		labels_row.title = _("Labels");
		labels_row.add_suffix (new Gtk.Label (backup.labels.size.to_string ()));

		var collection_group = new Adw.PreferencesGroup () {
			margin_top = 24
		};

		collection_group.add (projects_row);
		collection_group.add (sections_row);
		collection_group.add (items_row);
		collection_group.add (labels_row);

		var cancel_button = new Gtk.Button.with_label (_("Cancel")) {
			valign = CENTER,
            css_classes = { "border-radius-6" }
		};

		var confirm_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Confirm")) {
            valign = CENTER,
            css_classes = { Granite.STYLE_CLASS_SUGGESTED_ACTION, "border-radius-6" }
        };

		var buttons_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            homogeneous = true,
            hexpand = true,
			vexpand = true,
			valign = END,
			margin_bottom = 12
        };
        buttons_box.append (cancel_button);
        buttons_box.append (confirm_button);

		var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			vexpand = true,
			hexpand = true
		};

		content_box.append (title);
		content_box.append (subtitle);
		content_box.append (general_group);
		content_box.append (collection_group);
		content_box.append (buttons_box);

		var content_clamp = new Adw.Clamp () {
			maximum_size = 400,
			margin_start = 24,
			margin_end = 24,
			margin_top = 12,
			margin_bottom = 12,
			child = content_box
		};

		var scrolled_window = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
			child = content_clamp
        };

		cancel_button.clicked.connect (() => {
			stack.set_visible_child_name ("backup-page");
		});

		confirm_button.clicked.connect (() => {
			var dialog = new Adw.MessageDialog (Planify._instance.main_window,
				_("Restore backup"), _("Are you sure you want to continue? This operation will delete your current data and replace it with the backup data."));

			dialog.body_use_markup = true;
			dialog.add_response ("cancel", _("Cancel"));
			dialog.add_response ("restore", _("Restore Backup"));
			dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
			dialog.show ();
	
			dialog.response.connect ((response) => {
				if (response == "restore") {
					Services.Backups.get_default ().patch_backup (backup);
				}
			});
		});

		return scrolled_window;
	}

	private int set_sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
		Objects.Backup item1 = ((Widgets.BackupRow) lbrow).backup;
		Objects.Backup item2 = ((Widgets.BackupRow) lbbefore).backup;
		return item2.datetime.compare (item1.datetime);
	}

	private void add_backup_row (Objects.Backup backup, Layouts.HeaderItem group) {
		var row = new Widgets.BackupRow (backup);
		group.insert_child (row, 0);
	}

	private Gtk.Widget generate_icon (string icon_name, int size = 32) {
		var icon = new Widgets.DynamicIcon.from_icon_name (icon_name);
		icon.size = size;
		return icon;
	}
}

public class Widgets.BackupRow : Gtk.ListBoxRow {
	public Objects.Backup backup { get; construct; }
	
	public BackupRow (Objects.Backup backup) {
		Object (
			backup: backup
		);
	}

	construct {
		add_css_class ("selectable-item");
        add_css_class ("transition");

		var name_label = new Gtk.Label (backup.title);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

		var download_button = new Gtk.Button () {
			valign = CENTER,
			halign = END,
			hexpand = true,
			child = new Widgets.DynamicIcon.from_icon_name ("download"),
			css_classes = { "flat" },
			tooltip_text = _("Download")
		};

		var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 3,
            margin_start = 9,
            margin_end = 3,
            margin_bottom = 3
        };

		content_box.append (new Widgets.DynamicIcon.from_icon_name ("file"));
        content_box.append (name_label);
		content_box.append (download_button);

		var main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			child = content_box
        };

		child = main_revealer;

		Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

		download_button.clicked.connect (() => {
			Services.Backups.get_default ().save_file_as (backup);
		});
	}
}
