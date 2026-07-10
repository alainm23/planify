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
    private Gtk.Stack main_stack;

    private string source_id;

    public NextcloudSetup (Adw.PreferencesDialog preferences_dialog, Accounts accounts_page) {
        Object (
            preferences_dialog: preferences_dialog,
            accounts_page: accounts_page,
            title: _("Nextcloud")
        );
    }

    ~NextcloudSetup () {
        debug ("Destroying - Dialogs.Preferences.Pages.NextcloudSetup\n");
    }

    construct {
        source_id = Util.get_default ().generate_id ();

        var icon = new Gtk.Image.from_icon_name ("cloud-outline-thick-symbolic") {
            pixel_size = 48,
            css_classes = { "dimmed" }
        };

        var title_label = new Gtk.Label (_("Connect to Nextcloud")) {
            css_classes = { "font-bold", "title-3" },
            margin_top = 12
        };

        var description_label = new Gtk.Label (_("Sign in with your Nextcloud account to sync tasks via CalDAV")) {
            css_classes = { "dimmed", "caption" },
            wrap = true,
            justify = CENTER,
            max_width_chars = 40
        };

        var header_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            halign = CENTER,
            margin_bottom = 18
        };
        header_box.append (icon);
        header_box.append (title_label);
        header_box.append (description_label);

        server_entry = new Adw.EntryRow ();
        server_entry.title = _("Server URL");

        var entries_group = new Adw.PreferencesGroup ();
        entries_group.add (server_entry);

        var step1_label = new Gtk.Label (_("https://cloud.example.com")) {
            xalign = 0,
            css_classes = { "monospace", "caption" }
        };

        var step2_label = new Gtk.Label (_("https://example.com/nextcloud")) {
            xalign = 0,
            css_classes = { "monospace", "caption" }
        };

        var examples_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 4) {
            margin_top = 8,
            margin_bottom = 8,
            margin_start = 12,
            margin_end = 12
        };
        examples_box.append (step1_label);
        examples_box.append (step2_label);

        var examples_group = new Adw.PreferencesGroup () {
            margin_top = 6
        };
        examples_group.title = _("URL examples");
        examples_group.add (examples_box);

        login_button = new Widgets.LoadingButton.with_label (_("Log In")) {
            margin_top = 24,
            sensitive = false,
            css_classes = { "suggested-action", "pill" },
            halign = CENTER
        };

        cancel_button = new Gtk.Button.with_label (_("Cancel")) {
            css_classes = { "flat", "pill" },
            halign = CENTER,
            visible = false,
            margin_top = 12
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            vexpand = true,
            hexpand = true,
            margin_start = 12,
            margin_end = 12,
            margin_top = 24
        };

        content_box.append (header_box);
        content_box.append (entries_group);
        content_box.append (login_button);
        content_box.append (cancel_button);
        content_box.append (examples_group);

        var loading_page = new Dialogs.Preferences.Pages.Accounts.LoadingPage () {
            show_progress = true
        };

        main_stack = new Gtk.Stack () {
            vexpand = true,
            hexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE,
        };

        main_stack.add_named (content_box, "main-page");
        main_stack.add_named (loading_page, "loading-page");

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (new Adw.HeaderBar ());
        toolbar_view.content = main_stack;

        child = toolbar_view;

        signal_map[server_entry.changed.connect (() => {
            if (server_entry.text != null && server_entry.text != "") {
                var is_valid = is_valid_url (server_entry.text);
                if (!is_valid) {
                    server_entry.add_css_class ("error");
                } else {
                    server_entry.remove_css_class ("error");
                }
                login_button.sensitive = is_valid;
            } else {
                server_entry.remove_css_class ("error");
                login_button.sensitive = false;
            }
        })] = server_entry;

        signal_map[server_entry.entry_activated.connect (() => {
            if (login_button.sensitive) {
                on_login_button_clicked ();
            }
        })] = server_entry;

        signal_map[login_button.clicked.connect (() => {
            on_login_button_clicked ();
        })] = login_button;

        signal_map[Services.CalDAV.Core.get_default ().sync_progress.connect ((current, total, message) => {
            loading_page.sync_label = message;
            loading_page.progress = total > 0 ? (double) current / (double) total : 0.0;
        })] = Services.CalDAV.Core.get_default ();

        destroy.connect (() => {
            Services.CalDAV.CertificateTrustStore.get_default ().clear_source_state (source_id);
            clean_up ();
        });
    }

    private void on_login_button_clicked () {
        Services.LogService.get_default ().info ("NextcloudSetup", "Login button clicked");
        GLib.Cancellable cancellable = new GLib.Cancellable ();
        login_button.is_loading = true;
        cancel_button.visible = true;

        signal_map[cancel_button.clicked.connect (() => {
            Services.LogService.get_default ().info ("NextcloudSetup", "Login cancelled by user");
            cancellable.cancel ();
        })] = cancel_button;

        var core_service = Services.CalDAV.Core.get_default ();
        var nextcloud_provider = new Services.CalDAV.Providers.Nextcloud ();

        Services.LogService.get_default ().info ("NextcloudSetup", "Starting Nextcloud login flow");
        nextcloud_provider.start_login_flow.begin (server_entry.text, cancellable, source_id, (obj, res) => {
            HttpResponse response = nextcloud_provider.start_login_flow.end (res);

            if (response.status) {
                Services.LogService.get_default ().info ("NextcloudSetup", "Login successful, syncing account");
                Objects.Source source = (Objects.Source) response.data_object.get_object ();
                main_stack.visible_child_name = "loading-page";

                core_service.add_caldav_account.begin (source, cancellable, (obj, res) => {
                    response = core_service.add_caldav_account.end (res);

                    if (response.status) {
                        Services.LogService.get_default ().info ("NextcloudSetup", "Account synced successfully");
                        preferences_dialog.pop_subpage ();
                    } else {
                        Services.LogService.get_default ().error ("NextcloudSetup", "Account sync failed: %s".printf (response.error));
                        main_stack.visible_child_name = "main-page";
                        login_button.is_loading = false;
                        cancel_button.visible = false;
                        accounts_page.show_message_error (response.error_code, response.error.strip ());
                    }
                });
            } else {
                Services.LogService.get_default ().error ("NextcloudSetup", "Login flow failed: %s".printf (response.error));
                login_button.is_loading = false;
                cancel_button.visible = false;

                var certificate_store = Services.CalDAV.CertificateTrustStore.get_default ();
                var tls_failure_context = certificate_store.get_last_tls_failure_for_source (source_id);
                if (tls_failure_context != null) {
                    open_certificate_details_page (source_id, server_entry.text, accounts_page, () => {
                        on_login_button_clicked ();
                    });
                    return;
                }

                if (response.error_code == 409) {
                    var toast = new Adw.Toast (response.error.strip ());
                    toast.timeout = 3;
                    preferences_dialog.add_toast (toast);
                } else if (response.error_code == 0 && certificate_store.get_last_tls_failure_for_source (source_id) != null) {
                    accounts_page.show_message_error (
                        500,
                        certificate_store.build_tls_failure_message_for_source (source_id),
                        false
                    );
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
