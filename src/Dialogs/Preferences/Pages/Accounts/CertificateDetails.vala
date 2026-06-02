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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

public class Dialogs.Preferences.Pages.CertificateDetails : Dialogs.Preferences.Pages.BasePage {
    public string server_url { get; construct; }
    public string source_id { get; construct; }
    public GLib.TlsCertificate certificate { get; construct; }

    public signal void certificate_trusted ();

    public static Dialogs.Preferences.Pages.CertificateDetails? build_for_source (
        Adw.PreferencesDialog preferences_dialog,
        string source_id,
        string fallback_server_url,
        Dialogs.Preferences.Pages.Accounts? accounts_page = null
    ) {
        var certificate_store = Services.CalDAV.CertificateTrustStore.get_default ();
        var? certificate_context = certificate_store.get_last_tls_failure_for_source (source_id);
        if (certificate_context == null || certificate_context.flags != GLib.TlsCertificateFlags.UNKNOWN_CA) {
            if (accounts_page != null) {
                accounts_page.show_message_error (
                    500,
                    certificate_store.build_tls_failure_message_for_source (source_id),
                    false
                );
            }

            return null;
        }

        return new Dialogs.Preferences.Pages.CertificateDetails (
            preferences_dialog,
            certificate_context.url ?? fallback_server_url,
            source_id,
            certificate_context.certificate
        );
    }

    public CertificateDetails (Adw.PreferencesDialog preferences_dialog, string server_url, string source_id, GLib.TlsCertificate certificate) {
        Object (
            preferences_dialog: preferences_dialog,
            server_url: server_url,
            source_id: source_id,
            certificate: certificate,
            title: _("Review certificate")
        );
    }

    construct {
        var icon = new Gtk.Image.from_icon_name ("dialog-warning-symbolic") {
            pixel_size = 48,
            css_classes = { "warning" },
            halign = Gtk.Align.CENTER
        };

        var title_label = new Gtk.Label (_("Untrusted certificate")) {
            css_classes = { "title-3", "font-bold" },
            halign = Gtk.Align.CENTER,
            margin_top = 12
        };

        var body_label = new Gtk.Label (_("The certificate for %s is self-signed and thus not trusted").printf (server_url)) {
            wrap = true,
            justify = Gtk.Justification.CENTER,
            max_width_chars = 46,
            halign = Gtk.Align.CENTER,
            css_classes = { "dimmed" }
        };

        var subject_row = new Adw.ActionRow () {
            title = _("Subject"),
            subtitle = certificate.get_subject_name () ?? _("Unknown"),
            subtitle_selectable = true
        };

        var issuer_row = new Adw.ActionRow () {
            title = _("Issuer"),
            subtitle = certificate.get_issuer_name () ?? _("Unknown"),
            subtitle_selectable = true
        };

        var not_before_row = new Adw.ActionRow () {
            title = _("Not valid before"),
            subtitle = format_certificate_datetime (certificate.get_not_valid_before ()),
            subtitle_selectable = true
        };

        var not_after_row = new Adw.ActionRow () {
            title = _("Not valid after"),
            subtitle = format_certificate_datetime (certificate.get_not_valid_after ()),
            subtitle_selectable = true
        };

        var fingerprint = Services.CalDAV.CertificateTrustStore.get_default ().compute_certificate_sha256_fingerprint (certificate);
        var fingerprint_row = new Adw.ActionRow () {
            title = _("SHA-256 fingerprint"),
            subtitle = fingerprint,
            subtitle_selectable = true
        };

        var copy_fingerprint_button = new Gtk.Button.from_icon_name ("edit-copy-symbolic") {
            tooltip_text = _("Copy fingerprint"),
            css_classes = { "flat" },
            valign = Gtk.Align.CENTER
        };
        fingerprint_row.add_suffix (copy_fingerprint_button);
        fingerprint_row.activatable_widget = copy_fingerprint_button;

        var details_group = new Adw.PreferencesGroup () {
            title = _("Certificate details"),
            margin_top = 12
        };
        details_group.add (subject_row);
        details_group.add (issuer_row);
        details_group.add (not_before_row);
        details_group.add (not_after_row);
        details_group.add (fingerprint_row);

        var trust_button = new Adw.ButtonRow () {
            title = _("Trust certificate")
        };

        var advanced_group = new Adw.PreferencesGroup () {
            margin_bottom = 3,
            margin_start = 3,
            margin_end = 3
        };
        advanced_group.title = _("Advanced");


        advanced_group.add (trust_button);

        var advanced_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = false,
            child = advanced_group
        };

        var advanced_icon = new Gtk.Image.from_icon_name ("go-down-symbolic") {
            pixel_size = 12
        };

        var advanced_label = new Gtk.Label (_("Show advanced options"));

        var advanced_button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4) {
            halign = CENTER
        };
        advanced_button_box.append (advanced_label);
        advanced_button_box.append (advanced_icon);

        var advanced_button = new Gtk.Button () {
            child = advanced_button_box,
            css_classes = { "flat", "caption", "dimmed" },
            halign = CENTER,
            margin_top = 12
        };

        signal_map[advanced_button.clicked.connect (() => {
            var revealed = !advanced_revealer.reveal_child;
            advanced_revealer.reveal_child = revealed;
            advanced_label.label = revealed ? _("Hide advanced options") : _("Show advanced options");
            advanced_icon.icon_name = revealed ? "go-up-symbolic" : "go-down-symbolic";
        })] = advanced_button;


        signal_map[trust_button.activated.connect (() => {
            var trusted = Services.CalDAV.CertificateTrustStore.get_default ().trust_unknown_ca_certificate_for_source (source_id);
            if (!trusted) {
                popup_toast (_("Could not trust this certificate"));
                return;
            }

            certificate_trusted ();
            preferences_dialog.pop_subpage ();
        })] = trust_button;

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 24,
            margin_bottom = 24,
            margin_start = 12,
            margin_end = 12,
            vexpand = true,
            hexpand = true
        };
        content.append (icon);
        content.append (title_label);
        content.append (body_label);
        content.append (details_group);
        content.append (advanced_button);
        content.append (advanced_revealer);

        var scroll = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = content,
            vexpand = true,
            hexpand = true
        };

        var toolbar_view = new Adw.ToolbarView () {
            content = scroll
        };
        toolbar_view.add_top_bar (new Adw.HeaderBar ());

        child = toolbar_view;
    }

    private string format_certificate_datetime (GLib.DateTime? value) {
        if (value == null) {
            return _("Not available");
        }

        return "%s, %s".printf (
            value.format (Utils.Datetime.get_default_date_format (false, true, true)),
            value.format (Utils.Datetime.get_default_time_format ())
        );
    }
}
