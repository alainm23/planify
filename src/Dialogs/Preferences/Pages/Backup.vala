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

    public Backup (Adw.PreferencesDialog preferences_dialog) {
        Object (
            preferences_dialog: preferences_dialog,
            title: _("Backup")
        );
    }

    ~Backup () {
        print ("Destroying - Dialogs.Preferences.Pages.Backup\n");
    }

    construct {
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

        backups_group = new Layouts.HeaderItem (_("Backup Files")) {
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

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (new Adw.HeaderBar ());
        toolbar_view.content = scrolled_window;

        child = toolbar_view;

        signal_map[add_button.clicked.connect (() => {
            Services.Backups.get_default ().create_backup ();
            popup_toast (_("The Backup was created successfully."));
        })] = add_button;

        signal_map[import_button.clicked.connect (() => {
            Services.Backups.get_default ().choose_backup_file.begin ((obj, res) => {
                GLib.File file = Services.Backups.get_default ().choose_backup_file.end (res);
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

        foreach (Objects.Backup backup in Services.Backups.get_default ().backups) {
            add_backup_row (backup, backups_group);
        }

        signal_map[Services.Backups.get_default ().backup_added.connect ((backup) => {
            add_backup_row (backup, backups_group);
        })] = Services.Backups.get_default ();

        destroy.connect (() => {
            clean_up ();
        });
    }

    private int set_sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
        Objects.Backup item1 = ((BackupRow) lbrow).backup;
        Objects.Backup item2 = ((BackupRow) lbbefore).backup;
        return item2.datetime.compare (item1.datetime);
    }

    private void add_backup_row (Objects.Backup backup, Layouts.HeaderItem group) {
        var row = new BackupRow (backup);

        signal_map[row.view.connect (() => {
            view_backup (backup);
        })] = row;

        group.insert_child (row, 0);
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

        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }

    public class BackupRow : Gtk.ListBoxRow {
        public Objects.Backup backup { get; construct; }

        private Gtk.Revealer main_revealer;
        public signal void view ();
        public Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

        public BackupRow (Objects.Backup backup) {
            Object (
                backup: backup
            );
        }

        ~BackupRow () {
            print ("Destroying - BackupRow\n");
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

            signal_map[view_button.clicked.connect (() => {
                view ();
            })] = view_button;

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
                Services.Backups.get_default ().save_file_as (backup);
            })] = download_item;

            signal_map[delete_item.clicked.connect (() => {
                menu_popover.popdown ();
                Services.Backups.get_default ().delete_backup (backup);
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

    public class ImportView : Dialogs.Preferences.Pages.BasePage {
        public Objects.Backup backup { get; construct; }

        public ImportView (Adw.PreferencesDialog preferences_dialog, Objects.Backup backup) {
            Object (
                preferences_dialog: preferences_dialog,
                backup: backup
            );
        }

        ~ImportView () {
            print ("Destroying Dialogs.Preferences.Pages.ImportView\n");
        }

        construct {
            var title = new Gtk.Label (_("Import Overview")) {
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
            
            var toolbar_view = new Adw.ToolbarView ();
            toolbar_view.add_top_bar (new Adw.HeaderBar () {
                show_title = false
            });
            toolbar_view.content = scrolled_window;

            child = toolbar_view;

            signal_map[cancel_button.clicked.connect (() => {
                preferences_dialog.pop_subpage ();
            })] = cancel_button;

            signal_map[confirm_button.clicked.connect (() => {
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
