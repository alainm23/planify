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

public class Dialogs.Preferences.Pages.BasePage : Adw.NavigationPage {
    public Adw.PreferencesDialog preferences_dialog { get; construct; }
    public Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public delegate void CertificateRetryCallback ();

    public virtual void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }

    public void popup_toast (string message) {
        var toast = new Adw.Toast (message);
        toast.timeout = 3;

        if (preferences_dialog != null) {
            preferences_dialog.add_toast (toast);
        }
    }

    protected void open_certificate_details_page (
        string source_id,
        string server_url,
        Dialogs.Preferences.Pages.Accounts? accounts_page,
        CertificateRetryCallback retry_callback
    ) {
        var trust_page = Dialogs.Preferences.Pages.CertificateDetails.build_for_source (
            preferences_dialog,
            source_id,
            server_url,
            accounts_page
        );
        if (trust_page == null) {
            return;
        }

        signal_map[trust_page.certificate_trusted.connect (() => {
            retry_callback ();
        })] = trust_page;

        preferences_dialog.push_subpage (trust_page);
    }
}