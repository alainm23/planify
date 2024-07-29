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
			if (stack.visible_child_name == "import-page") {
				stack.set_visible_child_name ("backup-page");
			} else {
				pop_subpage ();
			}
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
			card = true,
			margin_top = 12,
			reveal = true,
			placeholder_message = _("No backups found, create one clicking the button above.")
		};
		
		backups_group.set_sort_func (set_sort_func);

		var import_planner_button = new Gtk.Button.with_label (_("Migrate"));
		
		var migrate_group = new Layouts.HeaderItem (_("Migrate From Planner"));
		migrate_group.reveal = true;
		migrate_group.add_child (import_planner_button);

		var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
			vexpand = true,
			hexpand = true
		};

		content_box.append (description_label);
		content_box.append (add_button);
		content_box.append (import_button);
		content_box.append (backups_group);
		content_box.append (migrate_group);

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
			popup_toast (_("The Backup was created successfully."));
		});

		import_button.clicked.connect (() => {
			Services.Backups.get_default ().choose_backup_file.begin ((obj, res) => {
				GLib.File file = Services.Backups.get_default ().choose_backup_file.end (res);
				Objects.Backup backup = new Objects.Backup.from_file (file);
				view_backup (backup);
			});
		});

		import_planner_button.clicked.connect (() => {
			string path = Environment.get_home_dir () + "/.var/app/com.github.alainm23.planner/data/com.github.alainm23.planner/database.db";
			GLib.File file = GLib.File.new_for_path (path);

			if (file.query_exists ()) {
				if (Services.MigrateFromPlanner.get_default ().migrate_from_file (file)) {
					popup_toast (_("Tasks Migrate Successfully"));
					pop_subpage ();
				}
			} else {
				popup_toast (_("The database file does not exist."));
			}
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
			css_classes = { "title-1" }
		};
		var subtitle = new Gtk.Label (backup.title) {
			halign = CENTER,
			css_classes = { "dim-label" },
			margin_top = 3
		};

		var sources_row = new Adw.ActionRow ();
		sources_row.title = _("Sources");
		sources_row.add_suffix (new Gtk.Label (backup.sources.size.to_string ()));

		var projects_row = new Adw.ActionRow ();
		projects_row.title = _("Projects");
		projects_row.add_suffix (new Gtk.Label (backup.projects.size.to_string ()));

		var sections_row = new Adw.ActionRow ();
		sections_row.title = _("Sections");
		sections_row.add_suffix (new Gtk.Label (backup.sections.size.to_string ()));

		var items_row = new Adw.ActionRow ();
		items_row.title = _("To-Dos");
		items_row.add_suffix (new Gtk.Label (backup.items.size.to_string ()));

		var labels_row = new Adw.ActionRow ();
		labels_row.title = _("Labels");
		labels_row.add_suffix (new Gtk.Label (backup.labels.size.to_string ()));

		var collection_group = new Adw.PreferencesGroup () {
			margin_top = 24
		};

		collection_group.add (sources_row);
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
            css_classes = { "suggested-action", "border-radius-6" }
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
			var dialog = new Adw.AlertDialog (
				_("Restore backup"),
				_("Are you sure you want to continue? This operation will delete your current data and replace it with the backup data.")
			);

			dialog.body_use_markup = true;
			dialog.add_response ("cancel", _("Cancel"));
			dialog.add_response ("restore", _("Restore Backup"));
			dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
			dialog.present (Planify._instance.main_window);
	
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

		row.view.connect (() => {
			view_backup (backup);
		});

		group.insert_child (row, 0);
	}

	private void view_backup (Objects.Backup backup) {
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
	}
}

public class Widgets.BackupRow : Gtk.ListBoxRow {
	public Objects.Backup backup { get; construct; }
	
	private Gtk.Revealer main_revealer;
	public signal void view ();

	public BackupRow (Objects.Backup backup) {
		Object (
			backup: backup
		);
	}

	construct {
		add_css_class ("no-selectable");
        add_css_class ("transition");

		var name_label = new Gtk.Label (backup.title);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

		var view_button = new Gtk.Button.from_icon_name ("eye-open-negative-filled-symbolic") {
			valign = CENTER,
			css_classes = { "flat" },
			tooltip_text = _("View Backup")
		};

		var menu_button = new Gtk.MenuButton () {
            hexpand = true,
            halign = END,
			popover = build_context_menu (),
			icon_name = "view-more-symbolic",
			css_classes = { "flat" }
		};

		var end_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
			halign = END,
			hexpand = true,
		};

		end_box.append (view_button);
		end_box.append (menu_button);

		var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 6,
            margin_start = 12,
            margin_end = 6,
            margin_bottom = 6
        };

		content_box.append (new Gtk.Image.from_icon_name ("paper-symbolic"));
        content_box.append (name_label);
		content_box.append (end_box);

		main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			child = content_box
        };

		child = main_revealer;

		Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

		view_button.clicked.connect (() => {
			view ();
		});

		backup.deleted.connect (() => {
			hide_destroy ();
		});
	}

	private Gtk.Popover build_context_menu () {
		var download_item = new Widgets.ContextMenu.MenuItem (_("Download"), "folder-download-symbolic");
		var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete"), "user-trash-symbolic");
		delete_item.add_css_class ("menu-item-danger");

		var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		menu_box.margin_top = menu_box.margin_bottom = 3;

		menu_box.append (download_item);
		menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (delete_item);

		var menu_popover = new Gtk.Popover () {
			has_arrow = false,
			child = menu_box,
			position = Gtk.PositionType.BOTTOM,
			width_request = 250
		};

		download_item.clicked.connect (() => {
			menu_popover.popdown ();
			Services.Backups.get_default ().save_file_as (backup);
		});

		delete_item.clicked.connect (() => {
			menu_popover.popdown ();
			Services.Backups.get_default ().delete_backup (backup);
		});

		return menu_popover;
	}

	public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }
}
