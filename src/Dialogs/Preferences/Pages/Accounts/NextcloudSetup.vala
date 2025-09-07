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


public class Dialogs.Preferences.Pages.NextcloudSetup : Dialogs.Preferences.Pages.BasePage {
    public Accounts accounts_page { get; construct; }

    private Adw.EntryRow server_entry;
    private Widgets.LoadingButton login_button;
    private Gtk.Button cancel_button;

    // Advanced Options
    private Widgets.IgnoreSSLSwitchRow ignore_ssl_row;

    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public NextcloudSetup (Adw.PreferencesDialog preferences_dialog, Accounts accounts_page) {
        Object (
            preferences_dialog: preferences_dialog,
            accounts_page: accounts_page,
            title: _("Nextcloud")
        );
    }

    ~NextcloudSetup () {
        print ("Destroying - Dialogs.Preferences.Pages.NextcloudSetup\n");
    }

    construct {
        server_entry = new Adw.EntryRow ();
        server_entry.title = _("Server URL");

        var entries_group = new Adw.PreferencesGroup ();
        entries_group.add (server_entry);

        var message_label = new Gtk.Label ("%s\n\n%s\n%s"
                                            .printf (_("Server URL examples:"), _("- https://cloud.example.com/"),
                                                     _("- https://example.com/nextcloud/"))) {
            wrap = true,
            css_classes = { "dim-label", "caption" }
        };

        var message_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12,
        };

        message_box.append (message_label);

        var message_card = new Adw.Bin () {
            css_classes = { "card" },
            child = message_box
        };

        var message_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = true,
            child = message_card
        };

        // Advanced options

        var advanced_entries_group = new Adw.PreferencesGroup ();

        ignore_ssl_row = new Widgets.IgnoreSSLSwitchRow ();

        var advanced_options_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = false,
            child = advanced_entries_group
        };

        var advanced_button = new Gtk.Button.with_label (_("Advanced Options")) {
            css_classes = { "flat" }
        };

        signal_map[advanced_button.clicked.connect (() => {
            advanced_options_revealer.reveal_child = !advanced_options_revealer.reveal_child;
        })] = advanced_button;
        advanced_entries_group.add (ignore_ssl_row);


        login_button = new Widgets.LoadingButton.with_label (_("Log In")) {
            margin_top = 12,
            sensitive = false,
            css_classes = { "suggested-action" }
        };

        cancel_button = new Gtk.Button.with_label (_("Cancel")) {
            css_classes = { "flat" },
            visible = false
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            vexpand = true,
            hexpand = true
        };

        content_box.append (entries_group);
        content_box.append (message_revealer);
        content_box.append (advanced_button);
        content_box.append (advanced_options_revealer);
        content_box.append (login_button);
        content_box.append (cancel_button);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 400,
            margin_start = 24,
            margin_end = 24,
            margin_top = 12,
            child = content_box
        };

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (new Adw.HeaderBar ());
        toolbar_view.content = content_clamp;

        child = toolbar_view;

        signal_map[server_entry.changed.connect (() => {
            if (server_entry.text != null && server_entry.text != "") {
                var is_valid_url = is_valid_url (server_entry.text);
                if (!is_valid_url) {
                    server_entry.add_css_class ("error");
                } else {
                    server_entry.remove_css_class ("error");
                }
            } else {
                server_entry.remove_css_class ("error");
            }

            if (server_entry.has_css_class ("error")) {
                login_button.sensitive = false;
            } else {
                login_button.sensitive = true;
            }
        })] = server_entry;

        signal_map[login_button.clicked.connect (() => {
            on_login_button_clicked ();
        })] = login_button;

        signal_map[Services.CalDAV.Core.get_default ().first_sync_started.connect (() => {
            login_button.is_loading = true;
        })] = Services.CalDAV.Core.get_default ();

        signal_map[Services.CalDAV.Core.get_default ().first_sync_finished.connect (() => {
            preferences_dialog.pop_subpage ();
        })] = Services.CalDAV.Core.get_default ();

        destroy.connect (() => {
            clean_up ();
        });
    }

    private void on_login_button_clicked () {
        GLib.Cancellable cancellable = new GLib.Cancellable ();
        login_button.is_loading = true;
        cancel_button.visible = true;

        signal_map[cancel_button.clicked.connect (() => {
            cancellable.cancel ();
        })] = cancel_button;

        var core_service = Services.CalDAV.Core.get_default ();
        var nextcloud_provider = new Services.CalDAV.Providers.Nextcloud ();

        nextcloud_provider.start_login_flow.begin (server_entry.text, cancellable, ignore_ssl_row.active, (obj, res) => {
            HttpResponse response = nextcloud_provider.start_login_flow.end (res);

            if (response.status) {
                Objects.Source source = (Objects.Source) response.data_object.get_object ();
                core_service.add_caldav_account.begin (source, cancellable, (obj, res) => {
                    response = core_service.add_caldav_account.end (res);

                    if (!response.status) {
                        login_button.is_loading = false;
                        cancel_button.visible = false;
                        accounts_page.show_message_error (response.error_code, response.error.strip ());
                    }
                });
            } else {
                login_button.is_loading = false;
                cancel_button.visible = false;

                if (response.error_code == 409) {
                    var toast = new Adw.Toast (response.error.strip ());
                    toast.timeout = 3;
                    preferences_dialog.add_toast (toast);
                } else {
                    accounts_page.show_message_error (response.error_code, response.error.strip ());
                }
            }
        });
    }


    private bool is_valid_url (string uri) {
        var scheme = Uri.parse_scheme (uri);
        if (scheme == null) {
            return false;
        }

        return scheme.has_prefix ("http");
    }
}
