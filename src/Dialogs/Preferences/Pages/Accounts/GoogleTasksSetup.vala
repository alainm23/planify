/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

public class Dialogs.Preferences.Pages.GoogleTasksSetup : Dialogs.Preferences.Pages.BasePage {
    public Accounts accounts_page { get; construct; }

    private Widgets.LoadingButton login_button;
    private Gtk.Button cancel_button;
    private GLib.Cancellable? cancellable = null;

    public GoogleTasksSetup (Adw.PreferencesDialog preferences_dialog, Accounts accounts_page) {
        Object (
            preferences_dialog: preferences_dialog,
            accounts_page: accounts_page,
            title: _("Google Tasks")
        );
    }

    ~GoogleTasksSetup () {
        debug ("Destroying - Dialogs.Preferences.Pages.GoogleTasksSetup\n");
    }

    construct {
        var icon = new Gtk.Image.from_icon_name ("web-browser-symbolic") {
            pixel_size = 64,
            margin_bottom = 6
        };

        var title_label = new Gtk.Label (_("Connect to Google Tasks")) {
            css_classes = { "font-bold", "title-2" },
            margin_top = 24
        };

        var description_label = new Gtk.Label (_("Sign in with your Google account in the browser to sync your tasks")) {
            css_classes = { "dimmed", "caption" },
            wrap = true,
            justify = CENTER,
            max_width_chars = 40
        };

        login_button = new Widgets.LoadingButton.with_label (_("Sign in with Browser")) {
            css_classes = { "suggested-action", "pill" },
            halign = CENTER,
            margin_top = 12
        };

        cancel_button = new Gtk.Button.with_label (_("Cancel")) {
            css_classes = { "flat", "pill" },
            halign = CENTER,
            visible = false
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            vexpand = true,
            hexpand = true,
            valign = CENTER,
            halign = CENTER,
            margin_bottom = 32
        };

        content_box.append (icon);
        content_box.append (title_label);
        content_box.append (description_label);
        content_box.append (login_button);
        content_box.append (cancel_button);

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (new Adw.HeaderBar ());
        toolbar_view.content = content_box;

        child = toolbar_view;

        signal_map[login_button.clicked.connect (start_login)] = login_button;

        signal_map[cancel_button.clicked.connect (() => {
            if (cancellable != null) {
                cancellable.cancel ();
            }
        })] = cancel_button;

        destroy.connect (() => {
            // Stops the local sign-in server if the page is closed while waiting.
            if (cancellable != null) {
                cancellable.cancel ();
            }

            clean_up ();
        });
    }

    private void start_login () {
        cancellable = new GLib.Cancellable ();

        login_button.is_loading = true;
        login_button.sensitive = false;
        cancel_button.visible = true;
        title = _("Waiting for login…");

        Services.GoogleTasks.get_default ().login.begin (cancellable, (obj, res) => {
            HttpResponse response = Services.GoogleTasks.get_default ().login.end (res);
            cancellable = null;

            if (response.status) {
                preferences_dialog.pop_subpage ();
                return;
            }

            login_button.is_loading = false;
            login_button.sensitive = true;
            cancel_button.visible = false;
            title = _("Google Tasks");

            // -1: cancelled by the user, nothing to show.
            if (response.error_code == -1) {
                return;
            }

            if (response.error_code == 409) {
                popup_toast (response.error);
            } else {
                preferences_dialog.pop_subpage ();
                accounts_page.show_message_error (response.error_code, response.error.strip ());
            }
        });
    }
}
