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

public class Dialogs.Preferences.Pages.Backup : Dialogs.Preferences.Pages.BasePage {
    private Layouts.HeaderItem backups_group;
    private Layouts.HeaderItem extra_group;

    private Gtk.Box pagination_box;
    private int current_page = 0;
    private const int PAGE_SIZE = 7;

    public Backup (Adw.PreferencesDialog preferences_dialog) {
        Object (
            preferences_dialog: preferences_dialog,
            title: _("Backups")
        );
    }

    ~Backup () {
        debug ("Destroying - Dialogs.Preferences.Pages.Backup\n");
    }

    construct {
        var description_label = new Gtk.Label (
            _("Never worry about losing your data. You can create backups of your active projects, tasks and comments and import them later.") // vala-lint=line-length
                                ) {
            justify = Gtk.Justification.FILL,
            use_markup = true,
            wrap = true,
            xalign = 0,
            margin_end = 3,
            margin_start = 3
        };

        var auto_backup_row = new Adw.SwitchRow () {
            title = _("Automatic Daily Backup"),
            subtitle = _("Creates a backup every day at midnight")
        };
        auto_backup_row.active = Services.Settings.get_default ().settings.get_boolean ("backup-automatic");

        var max_backups_row = new Adw.SpinRow.with_range (0, 365, 1) {
            title = _("Backups to Keep"),
            subtitle = _("Older backups are removed automatically. Zero keeps them all"),
            value = Services.Settings.get_default ().settings.get_int ("backup-max-count")
        };

        var auto_backup_group = new Adw.PreferencesGroup ();
        auto_backup_group.add (auto_backup_row);
        auto_backup_group.add (max_backups_row);

        var add_button = new Gtk.Button.with_label (_("Create Backup")) {
            margin_top = 12
        };

        var import_button = new Gtk.Button.with_label (_("Import Backup"));

        backups_group = new Layouts.HeaderItem (_("Backup Files")) {
            card = true,
            reveal = true,
            placeholder_message = _("No backups found, create one clicking the button above.")
        };

        backups_group.set_sort_func (set_sort_func);

        string backups_path = Environment.get_user_data_dir () + "/io.github.alainm23.planify/backups";

        var open_folder_button = new Gtk.Button.from_icon_name ("folder-open-symbolic") {
            valign = CENTER,
            tooltip_text = _("Open backup folder"),
            css_classes = { "flat" }
        };

        var location_row = new Adw.ActionRow () {
            title = _("Backup Location"),
            subtitle = backups_path,
            subtitle_selectable = true
        };
        location_row.add_prefix (new Gtk.Image.from_icon_name ("folder-symbolic"));
        location_row.add_suffix (open_folder_button);
        location_row.activatable_widget = open_folder_button;

        var location_group = new Adw.PreferencesGroup () {
            margin_top = 12
        };
        location_group.add (location_row);

        pagination_box = new Gtk.Box (HORIZONTAL, 6) {
            halign = CENTER,
            margin_top = 6
        };
        pagination_box.add_css_class ("linked");
        pagination_box.visible = false;

        var backups_box = new Gtk.Box (VERTICAL, 6) {
            margin_top = 12
        };
        backups_box.append (backups_group);
        backups_box.append (pagination_box);
        backups_box.append (location_group);

        extra_group = new Layouts.HeaderItem (_("Extra Backup Locations")) {
            card = true,
            reveal = true,
            placeholder_message = _("No extra locations added yet.")
        };

        var add_folder_button = new Gtk.Button.from_icon_name ("list-add-symbolic") {
            css_classes = { "flat" }
        };

        extra_group.add_widget_end (add_folder_button);

        var extra_locations_box = new Gtk.Box (VERTICAL, 6);
        extra_locations_box.append (extra_group);

        var extra_location_label = new Gtk.Label (_("Backup copies will also be saved to these folders after each backup is created.")) {
            wrap = true,
            xalign = 0,
            margin_start = 6
        };
        extra_location_label.add_css_class ("dimmed");
        extra_location_label.add_css_class ("caption");
        extra_locations_box.append (extra_location_label);

        var import_planner_button = new Gtk.Button.with_label (_("Migrate"));

        var migrate_group = new Layouts.HeaderItem (_("Migrate From Planner"));
        migrate_group.reveal = true;
        migrate_group.add_child (import_planner_button);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            vexpand = true,
            hexpand = true,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_top = 12
        };
        content_box.append (description_label);
        content_box.append (auto_backup_group);
        content_box.append (add_button);
        content_box.append (import_button);
        content_box.append (backups_box);
        content_box.append (extra_locations_box);
        // content_box.append (migrate_group);

        var scrolled_window = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = content_box
        };

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (new Adw.HeaderBar ());
        toolbar_view.content = scrolled_window;

        child = toolbar_view;

        signal_map[auto_backup_row.notify["active"].connect (() => {
            Services.Settings.get_default ().settings.set_boolean ("backup-automatic", auto_backup_row.active);
        })] = auto_backup_row;

        signal_map[open_folder_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri (File.new_for_path (backups_path).get_uri (), null);
            } catch (Error e) {
                warning ("Error opening backup folder: %s", e.message);
            }
        })] = open_folder_button;

        signal_map[max_backups_row.notify["value"].connect (() => {
            Services.Settings.get_default ().settings.set_int ("backup-max-count", (int) max_backups_row.value);
            // Apply the new limit right away so lowering it trims existing backups.
            Services.BackupManager.get_default ().prune_old_backups ();
        })] = max_backups_row;

        signal_map[add_button.clicked.connect (() => {
            Services.BackupManager.get_default ().create_and_distribute_backup ();
            popup_toast (_("The Backup was created successfully."));
        })] = add_button;

        signal_map[import_button.clicked.connect (() => {
            Services.BackupManager.get_default ().choose_backup_file.begin ((obj, res) => {
                GLib.File file = Services.BackupManager.get_default ().choose_backup_file.end (res);
                Objects.Backup backup = new Objects.Backup.from_file (file);
                view_backup (backup);
            });
        })] = import_button;

        signal_map[import_planner_button.clicked.connect (() => {
            string path = Environment.get_home_dir () + "/.var/app/com.github.alainm23.planner/data/com.github.alainm23.planner/database.db";
            GLib.File file = GLib.File.new_for_path (path);

            if (file.query_exists ()) {
                if (Services.MigrateFromPlanner.get_default ().migrate_from_file (file)) {
                    popup_toast (_("Tasks Migrate Successfully"));
                    preferences_dialog.pop_subpage ();
                }
            } else {
                popup_toast (_("The database file does not exist."));
            }
        })] = import_planner_button;

        signal_map[add_folder_button.clicked.connect (() => {
            var dialog = new Gtk.FileDialog ();
            dialog.select_folder.begin (Planify._instance.main_window, null, (obj, res) => {
                try {
                    var folder = dialog.select_folder.end (res);
                    var folder_path = folder.get_path ();
                    Services.BackupManager.get_default ().add_extra_folder (folder_path);
                    add_extra_folder_row (folder_path);
                } catch (Error e) {
                    debug ("Error selecting folder: %s".printf (e.message));
                }
            });
        })] = add_folder_button;

        connect_backup_group_signals ();

        render_backups_page ();

        foreach (var folder_path in Services.Settings.get_default ().settings.get_strv ("backup-extra-folders")) {
            add_extra_folder_row (folder_path);
        }

        signal_map[Services.BackupManager.get_default ().backup_added.connect ((backup) => {
            // A new backup lands on page 1; jump there and re-render.
            current_page = 0;
            render_backups_page ();
        })] = Services.BackupManager.get_default ();

        destroy.connect (() => {
            clean_up ();
        });
    }

    private int set_sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
        Objects.Backup item1 = ((BackupRow) lbrow).backup;
        Objects.Backup item2 = ((BackupRow) lbbefore).backup;
        return item2.datetime.compare (item1.datetime);
    }

    private void add_extra_folder_row (string folder_path) {
        var row = new ExtraFolderRow (folder_path);

        signal_map[row.removed.connect (() => {
            Services.BackupManager.get_default ().remove_extra_folder (folder_path);
        })] = row;

        extra_group.add_child (row);
    }

    private void add_backup_row (Objects.Backup backup, Layouts.HeaderItem group) {
        var row = new BackupRow (backup);
        group.add_child (row);

        // When a backup is deleted (manually or by retention pruning), refresh
        // the page + pagination. Deferred so a batch prune collapses into one
        // re-render instead of one per deleted file.
        signal_map[backup.deleted.connect (() => {
            Idle.add (() => {
                render_backups_page ();
                return GLib.Source.REMOVE;
            });
        })] = backup;
    }

    // Render the current page of backups (PAGE_SIZE per page, newest first)
    // and rebuild the numbered page buttons below the list.
    private void render_backups_page () {
        var all_backups = new Gee.ArrayList<Objects.Backup> ();
        all_backups.add_all (Services.BackupManager.get_default ().backups);
        all_backups.sort ((a, b) => b.datetime.compare (a.datetime));

        int total = all_backups.size;
        int total_pages = (total + PAGE_SIZE - 1) / PAGE_SIZE; // ceil
        if (total_pages < 1) {
            total_pages = 1;
        }

        // Keep the current page within range (e.g. after pruning).
        if (current_page >= total_pages) {
            current_page = total_pages - 1;
        }
        if (current_page < 0) {
            current_page = 0;
        }

        backups_group.clear ();

        int start = current_page * PAGE_SIZE;
        int end = int.min (start + PAGE_SIZE, total);
        for (int i = start; i < end; i++) {
            add_backup_row (all_backups.get (i), backups_group);
        }

        build_pagination (total_pages);
    }

    // Rebuild the numbered page buttons. Hidden when there is only one page.
    private void build_pagination (int total_pages) {
        Gtk.Widget? child = pagination_box.get_first_child ();
        while (child != null) {
            Gtk.Widget? next = child.get_next_sibling ();
            pagination_box.remove (child);
            child = next;
        }

        if (total_pages <= 1) {
            pagination_box.visible = false;
            return;
        }

        pagination_box.visible = true;

        for (int page = 0; page < total_pages; page++) {
            int page_index = page; // capture for the closure
            var button = new Gtk.Button.with_label ((page + 1).to_string ()) {
                width_request = 36
            };
            button.add_css_class ("pagination-button");

            if (page_index == current_page) {
                button.add_css_class ("suggested-action");
            } else {
                button.add_css_class ("flat");
            }

            button.clicked.connect (() => {
                if (page_index != current_page) {
                    current_page = page_index;
                    render_backups_page ();
                }
            });

            pagination_box.append (button);
        }
    }

    private void connect_backup_group_signals () {
        signal_map[backups_group.row_activated.connect ((row) => {
            view_backup (((BackupRow) row).backup);
        })] = backups_group;
    }

    private void view_backup (Objects.Backup backup) {
        if (backup.valid ()) {
            preferences_dialog.push_subpage (new ImportView (preferences_dialog, backup));
        } else {
            debug ("%s", backup.error);
            popup_toast (_("Selected file is invalid"));
        }
    }

    public override void clean_up () {
        backups_group.set_sort_func (null);
        foreach (Gtk.ListBoxRow row in backups_group.get_children ()) {
            ((BackupRow) row).clean_up ();
        }

        foreach (Gtk.ListBoxRow row in extra_group.get_children ()) {
            ((ExtraFolderRow) row).clean_up ();
        }

        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }

    public class BackupRow : Gtk.ListBoxRow {
        public Objects.Backup backup { get; construct; }

        private Gtk.Revealer main_revealer;
        public Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

        public BackupRow (Objects.Backup backup) {
            Object (
                backup: backup
            );
        }

        ~BackupRow () {
            debug ("Destroying - BackupRow\n");
        }

        construct {
            activatable = true;
            add_css_class ("transition");

            var name_label = new Gtk.Label (backup.title);
            name_label.valign = Gtk.Align.CENTER;
            name_label.ellipsize = Pango.EllipsizeMode.END;

            var next_icon = new Gtk.Image.from_icon_name ("go-next-symbolic") {
                valign = CENTER
            };

            var menu_button = new Gtk.MenuButton () {
                hexpand = true,
                halign = END,
                popover = build_context_menu (),
                icon_name = "view-more-symbolic",
                css_classes = { "flat" }
            };

            var end_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
                halign = END,
                hexpand = true,
            };

            end_box.append (menu_button);
            end_box.append (next_icon);

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

            signal_map[backup.deleted.connect (() => {
                hide_destroy ();
            })] = backup;

            destroy.connect (() => {
                clean_up ();
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

            signal_map[download_item.clicked.connect (() => {
                menu_popover.popdown ();
                Services.BackupManager.get_default ().save_file_as (backup);
            })] = download_item;

            signal_map[delete_item.clicked.connect (() => {
                menu_popover.popdown ();
                Services.BackupManager.get_default ().delete_backup (backup);
            })] = delete_item;

            return menu_popover;
        }

        public void clean_up () {
            foreach (var entry in signal_map.entries) {
                entry.value.disconnect (entry.key);
            }

            signal_map.clear ();
        }

        public void hide_destroy () {
            clean_up ();
            main_revealer.reveal_child = false;
            Timeout.add (main_revealer.transition_duration, () => {
                ((Gtk.ListBox) parent).remove (this);
                return GLib.Source.REMOVE;
            });
        }
    }

    public class ExtraFolderRow : Gtk.ListBoxRow {
        public string folder_path { get; construct; }

        private Gtk.Revealer main_revealer;
        public signal void removed ();
        public Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

        public ExtraFolderRow (string folder_path) {
            Object (folder_path: folder_path);
        }

        construct {
            add_css_class ("no-selectable");

            var path_label = new Gtk.Label (folder_path) {
                valign = CENTER,
                hexpand = true,
                halign = START,
                ellipsize = Pango.EllipsizeMode.MIDDLE
            };

            var delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
                valign = CENTER,
                css_classes = { "flat" }
            };

            var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
                margin_top = 6,
                margin_start = 12,
                margin_end = 6,
                margin_bottom = 6
            };
            content_box.append (new Gtk.Image.from_icon_name ("folder-symbolic"));
            content_box.append (path_label);
            content_box.append (delete_button);

            main_revealer = new Gtk.Revealer () {
                transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
                child = content_box
            };

            child = main_revealer;

            Timeout.add (main_revealer.transition_duration, () => {
                main_revealer.reveal_child = true;
                return GLib.Source.REMOVE;
            });

            signal_map[delete_button.clicked.connect (() => {
                removed ();
                hide_destroy ();
            })] = delete_button;

            destroy.connect (() => clean_up ());
        }

        public void clean_up () {
            foreach (var entry in signal_map.entries) {
                entry.value.disconnect (entry.key);
            }
            signal_map.clear ();
        }

        public void hide_destroy () {
            main_revealer.reveal_child = false;
            Timeout.add (main_revealer.transition_duration, () => {
                ((Gtk.ListBox) parent).remove (this);
                return GLib.Source.REMOVE;
            });
        }
    }

    public class ImportView : Dialogs.Preferences.Pages.BasePage {
        public Objects.Backup backup { get; construct; }

        public ImportView (Adw.PreferencesDialog preferences_dialog, Objects.Backup backup) {
            Object (
                preferences_dialog: preferences_dialog,
                backup: backup
            );
        }

        ~ImportView () {
            debug ("Destroying Dialogs.Preferences.Pages.ImportView\n");
        }

        construct {
            var title = new Gtk.Label (_("Restore Backup")) {
                halign = CENTER,
                css_classes = { "title-1" }
            };

            var subtitle = new Gtk.Label (backup.title) {
                halign = CENTER,
                css_classes = { "dimmed" },
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

            var confirm_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Restore Backup")) {
                valign = CENTER,
                margin_top = 24,
                css_classes = { "flat", "destructive-action" },
                halign = CENTER
            };

            var buttons_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
                hexpand = true,
                margin_bottom = 12
            };
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
            
            var toolbar_view = new Adw.ToolbarView ();
            toolbar_view.add_top_bar (new Adw.HeaderBar () {
                show_title = false
            });
            toolbar_view.add_top_bar (new Adw.Banner (_("This will replace all your current data")) {
                revealed = true
            });
            toolbar_view.content = scrolled_window;

            child = toolbar_view;

            signal_map[confirm_button.clicked.connect (() => {
                var dialog = new Adw.AlertDialog (
                    _("Restore backup"),
                    _("Are you sure you want to continue? This operation will delete your current data and replace it with the backup data.")
                );

                dialog.body_use_markup = true;
                dialog.add_response ("cancel", _("Cancel"));
                dialog.add_response ("restore", _("Restore Backup"));
                dialog.set_response_appearance ("restore", Adw.ResponseAppearance.DESTRUCTIVE);
                dialog.present (Planify._instance.main_window);

                dialog.response.connect ((response) => {
                    if (response == "restore") {
                        Services.BackupManager.get_default ().patch_backup (backup);
                    }
                });
            })] = confirm_button;

            destroy.connect (() => {
                clean_up ();
            });
        }

        public override void clean_up () {
            foreach (var entry in signal_map.entries) {
                entry.value.disconnect (entry.key);
            }

            signal_map.clear ();
        }
    }
}
