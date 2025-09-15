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

public class Dialogs.Preferences.Pages.CalDAVSetup : Dialogs.Preferences.Pages.BasePage {
    public Accounts accounts_page { get; construct; }

    private Adw.EntryRow server_entry;
    private Adw.EntryRow username_entry;
    private Adw.PasswordEntryRow password_entry;

    private Widgets.LoadingButton login_button;
    private Gtk.Button cancel_button;

    // Advanced Options
    private Adw.EntryRow calendar_home_entry;
    private Widgets.IgnoreSSLSwitchRow ignore_ssl_row;

    public CalDAVSetup (Adw.PreferencesDialog preferences_dialog, Accounts accounts_page) {
        Object (
            preferences_dialog: preferences_dialog,
            accounts_page: accounts_page,
            title: _("CalDAV")
        );
    }

    ~CalDAVSetup () {
        debug ("Destroying Dialogs.Preferences.Pages.CalDAVSetup\n");
    }

    construct {
        server_entry = new Adw.EntryRow ();
        server_entry.title = _("Server URL");

        username_entry = new Adw.EntryRow ();
        username_entry.title = _("Username");

        password_entry = new Adw.PasswordEntryRow ();
        password_entry.title = _("Password");
        password_entry.input_purpose = Gtk.InputPurpose.PASSWORD;
        password_entry.enable_emoji_completion = false;

        // Advanced options

        var advanced_entries_group = new Adw.PreferencesGroup ();

        calendar_home_entry = new Adw.EntryRow ();
        calendar_home_entry.title = _("Calendar Home URL");

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

        advanced_entries_group.add (calendar_home_entry);
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

        var entries_group = new Adw.PreferencesGroup ();
        entries_group.add (server_entry);
        entries_group.add (username_entry);
        entries_group.add (password_entry);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            vexpand = true,
            hexpand = true
        };
        content_box.append (entries_group);
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

        signal_map[server_entry.changed.connect (() => validate_entries ())] = server_entry;
        signal_map[username_entry.changed.connect (() => validate_entries ())] = username_entry;
        signal_map[password_entry.changed.connect (() => validate_entries ())] = password_entry;

        signal_map[login_button.clicked.connect (() => on_login_button_clicked ())] = login_button;

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

    private void validate_entries () {
        bool valid = server_entry.text != null && server_entry.text != "" &&
                     username_entry.text != null && username_entry.text != "" &&
                     password_entry.text != null && password_entry.text != "" &&
                     is_valid_url (server_entry.text);

        if (!is_valid_url (server_entry.text)) {
            server_entry.add_css_class ("error");
        } else {
            server_entry.remove_css_class ("error");
        }

        login_button.sensitive = valid;
    }

    private void on_login_button_clicked () {
        GLib.Cancellable cancellable = new GLib.Cancellable ();
        login_button.is_loading = true;
        cancel_button.visible = true;

        signal_map[cancel_button.clicked.connect (() => cancellable.cancel ())] = cancel_button;

        do_login.begin (cancellable);
    }


    private async void do_login (GLib.Cancellable cancellable) {
        if (server_entry.text == null || server_entry.text == "") {
            login_button.is_loading = false;
            cancel_button.visible = false;
            accounts_page.show_message_error (0, "Invalid Server URL");
            return;
        }

        var dav_endpoint = yield Services.CalDAV.Core.get_default ().resolve_well_known_caldav (new Soup.Session (), server_entry.text, ignore_ssl_row.active);

        var calendar_home = "";

        if (calendar_home_entry.text != null && calendar_home_entry.text != "") {
            calendar_home = calendar_home_entry.text;
        }else {
            calendar_home = yield Services.CalDAV.Core.get_default ().resolve_calendar_home (CalDAVType.GENERIC, dav_endpoint, username_entry.text, password_entry.text, cancellable, ignore_ssl_row.active);
        }

        if (calendar_home == null) {
            login_button.is_loading = false;
            cancel_button.visible = false;
            accounts_page.show_message_error (0, "Failed to resolve calendar home");
            return;
        } else {
            calendar_home_entry.text = calendar_home;
        }

        HttpResponse response = yield Services.CalDAV.Core.get_default ().login (CalDAVType.GENERIC, dav_endpoint, username_entry.text, password_entry.text, calendar_home, cancellable, ignore_ssl_row.active);

        if (response.status) {
            Objects.Source source = (Objects.Source) response.data_object.get_object ();
            response = yield Services.CalDAV.Core.get_default ().add_caldav_account (source, cancellable);

            if (!response.status) {
                login_button.is_loading = false;
                cancel_button.visible = false;
                accounts_page.show_message_error (response.error_code, response.error.strip ());
            }
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
    }

    private bool is_valid_url (string uri) {
        var scheme = Uri.parse_scheme (uri);
        if (scheme == null) {
            return false;
        }

        return scheme.has_prefix ("http");
    }
}

