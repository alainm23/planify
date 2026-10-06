/*
 * Copyright © 2025 Alain M. (https://github.com/alainm23/planify)
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

public class Dialogs.Preferences.Pages.SourceView : Dialogs.Preferences.Pages.BasePage {
    public Objects.Source source { get; construct; }

    public SourceView (Adw.PreferencesDialog preferences_dialog, Objects.Source source) {
        Object (
            preferences_dialog: preferences_dialog,
            source: source,
            title: _("Source")
        );
    }

    ~SourceView () {
        debug ("Destroying Dialogs.Preferences.Pages.SourceView\n");
    }

    construct {
        var avatar = new Adw.Avatar (84, source.user_displayname, true);

        if (source.source_type == SourceType.TODOIST) {
            var file = File.new_for_path (Util.get_default ().get_avatar_path (source.avatar_path));
            if (file.query_exists ()) {
                var image = new Gtk.Image.from_file (file.get_path ());
                avatar.custom_image = image.get_paintable ();
            }
        }

        var user_label = new Gtk.Label (source.user_displayname) {
            margin_top = 12,
            css_classes = { "title-1" }
        };

        var email_label = new Gtk.Label (source.user_email) {
            css_classes = { "dimmed" },
            margin_top = 6,
            visible = source.user_email != null && source.user_email != ""
        };

        var user_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 24
        };
        user_box.append (avatar);
        user_box.append (user_label);
        user_box.append (email_label);

        if (source.source_type == SourceType.CALDAV) {
            var url_label = new Gtk.Label (source.caldav_data.server_url) {
                css_classes = { "dimmed" }
            };
            user_box.append (url_label);
        }

        var display_entry = new Adw.EntryRow () {
            title = _("Display Name"),
            text = source.display_name,
            show_apply_button = true
        };

        var sync_server_row = new Adw.SwitchRow ();
        sync_server_row.title = _("Sync Server");
        sync_server_row.subtitle =
            _(
                "Activate this setting so that Planify automatically synchronizes with your account account every 15 minutes");
        sync_server_row.active = source.sync_server;

        var last_sync_label = new Gtk.Label (
            Utils.Datetime.get_relative_date_from_date (
                new GLib.DateTime.from_iso8601 (
                    source.last_sync, new GLib.TimeZone.local ()
                )
            )
        );

        var last_sync_row = new Adw.ActionRow ();
        last_sync_row.activatable = false;
        last_sync_row.title = _("Last Sync");
        last_sync_row.add_suffix (last_sync_label);

        var default_group = new Adw.PreferencesGroup () {
            margin_top = 24
        };

        default_group.add (display_entry);

        var sync_group = new Adw.PreferencesGroup () {
            margin_top = 12
        };

        if (source.source_type != SourceType.LOCAL) {
            sync_group.add (sync_server_row);
            sync_group.add (last_sync_row);
        }

        if (source.source_type == SourceType.CALDAV && source.caldav_data.caldav_type == CalDAVType.NEXTCLOUD) {
            var deck_row = new Adw.SwitchRow () {
                title = _("Nextcloud Deck"),
                subtitle = _("Sync boards and cards from Nextcloud Deck"),
                active = source.caldav_data.use_deck
            };

            var deck_group = new Adw.PreferencesGroup () {
                margin_top = 12
            };
            deck_group.add (deck_row);

            deck_row.notify["active"].connect (() => {
                if (deck_row.active) {
                    Services.Deck.Core.get_default ().probe.begin (source, (obj, res) => {
                        bool available = Services.Deck.Core.get_default ().probe.end (res);
                        if (available) {
                            source.caldav_data.use_deck = true;
                            Services.Store.instance ().update_source (source);
                            Services.CalDAV.Core.get_default ().sync.begin (source);
                        } else {
                            deck_row.active = false;
                            var toast = Util.get_default ().create_toast (_("Nextcloud Deck is not available on this server"));
                            Services.EventBus.get_default ().send_toast (toast);
                        }
                    });
                } else {
                    source.caldav_data.use_deck = false;
                    Services.Store.instance ().update_source (source);
                    foreach (var project in Services.Store.instance ().get_projects_by_source (source.id)) {
                        if (project.is_deck) {
                            Services.Store.instance ().delete_project (project);
                        }
                    }
                }
            });

            var delete_button = new Adw.ButtonRow () {
                title = _("Delete Source")
            };
            delete_button.add_css_class ("destructive-action");

            var delete_group = new Adw.PreferencesGroup ();
            delete_group.add (delete_button);

            var delete_spinner = new Adw.Spinner () {
                valign = CENTER,
                halign = CENTER,
                height_request = 32,
                width_request = 32
            };

            var delete_stack = new Gtk.Stack () {
                margin_top = 24
            };
            delete_stack.add_child (delete_group);
            delete_stack.add_child (delete_spinner);

            var main_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
                vexpand = true,
                hexpand = true
            };
            main_content.append (user_box);
            main_content.append (default_group);
            main_content.append (deck_group);
            main_content.append (sync_group);
            main_content.append (delete_stack);

            var content_clamp = new Adw.Clamp () {
                maximum_size = 600,
                margin_start = 24,
                margin_end = 24,
                child = main_content
            };

            var toolbar_view = new Adw.ToolbarView () {
                content = content_clamp
            };
            toolbar_view.add_top_bar (new Adw.HeaderBar ());
            child = toolbar_view;

            signal_map[delete_button.activated.connect (() => {
                var dialog = new Adw.AlertDialog (
                    _("Delete Source?"),
                    _("This can not be undone")
                );
                dialog.add_response ("cancel", _("Cancel"));
                dialog.add_response ("delete", _("Delete"));
                dialog.close_response = "cancel";
                dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
                dialog.present (Planify._instance.main_window);
                dialog.response.connect ((response) => {
                    if (response == "delete") {
                        delete_stack.visible_child = delete_spinner;
                        source.delete_source.begin ();
                    }
                });
            })] = delete_button;
        } else {
            var delete_button = new Adw.ButtonRow () {
                title = _("Delete Source")
            };
            delete_button.add_css_class ("destructive-action");

            var delete_group = new Adw.PreferencesGroup ();
            delete_group.add (delete_button);

            var delete_spinner = new Adw.Spinner () {
                valign = CENTER,
                halign = CENTER,
                height_request = 32,
                width_request = 32
            };

            var delete_stack = new Gtk.Stack () {
                margin_top = 24
            };
            delete_stack.add_child (delete_group);
            delete_stack.add_child (delete_spinner);

            var main_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
                vexpand = true,
                hexpand = true
            };

            if (source.source_type != SourceType.LOCAL) {
                main_content.append (user_box);
            }
            main_content.append (default_group);
            if (source.source_type != SourceType.LOCAL) {
                main_content.append (sync_group);
                main_content.append (delete_stack);
            }

            var content_clamp = new Adw.Clamp () {
                maximum_size = 600,
                margin_start = 24,
                margin_end = 24,
                child = main_content
            };

            var toolbar_view = new Adw.ToolbarView () {
                content = content_clamp
            };
            toolbar_view.add_top_bar (new Adw.HeaderBar ());
            child = toolbar_view;

            signal_map[delete_button.activated.connect (() => {
                string current_inbox_id = Services.Settings.get_default ().settings.get_string ("local-inbox-project-id");
                Objects.Project? current_inbox = Services.Store.instance ().get_project (current_inbox_id);

                if (current_inbox != null && current_inbox.source_id == source.id) {
                    show_inbox_warning_dialog ();
                    return;
                }

                var dialog = new Adw.AlertDialog (
                    _("Delete Source?"),
                    _("This can not be undone")
                );
                dialog.add_response ("cancel", _("Cancel"));
                dialog.add_response ("delete", _("Delete"));
                dialog.close_response = "cancel";
                dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
                dialog.present (Planify._instance.main_window);
                dialog.response.connect ((response) => {
                    if (response == "delete") {
                        delete_stack.visible_child = delete_spinner;
                        source.delete_source.begin ();
                    }
                });
            })] = delete_button;
        }

        signal_map[sync_server_row.notify["active"].connect (() => {
            source.sync_server = sync_server_row.active;
            source.save ();
            if (source.sync_server) {
                source.run_server ();
            } else {
                source.remove_sync_server ();
            }
        })] = sync_server_row;

        signal_map[display_entry.apply.connect (() => {
            source.display_name = display_entry.text;
            source.save ();
        })] = display_entry;

        signal_map[source.deleted.connect (() => {
            preferences_dialog.pop_subpage ();
        })] = source;

        destroy.connect (() => {
            clean_up ();
        });
    }

    private void show_inbox_warning_dialog () {
        var dialog = new Adw.AlertDialog (
            _("Cannot Delete This Source"),
            _("This source contains your current Inbox project. Please change your Inbox project first.")
        );

        dialog.add_response ("cancel", _("Cancel"));
        dialog.add_response ("change", _("Change Inbox"));
        dialog.set_response_appearance ("change", Adw.ResponseAppearance.SUGGESTED);
        dialog.set_default_response ("change");
        dialog.set_close_response ("cancel");

        dialog.choose.begin (Planify._instance.main_window, null, (obj, res) => {
            string response = dialog.choose.end (res);
            if (response == "change") {
                preferences_dialog.push_subpage (new Dialogs.Preferences.Pages.InboxPage (preferences_dialog));
            }
        });
    }
}
