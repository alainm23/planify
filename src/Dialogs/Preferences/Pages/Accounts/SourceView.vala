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
    private Gtk.Box? certificate_sections_box;
    private Adw.ActionRow? last_sync_row;
    private Gtk.Label? last_sync_label;
    private Gtk.Image? last_sync_row_arrow_icon;

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

        last_sync_label = new Gtk.Label ("");

        last_sync_row = new Adw.ActionRow ();
        last_sync_row.title = _("Last Sync");
        last_sync_row.add_suffix (last_sync_label);

        last_sync_row_arrow_icon = new Gtk.Image.from_icon_name ("go-next-symbolic");
        last_sync_row.add_suffix (last_sync_row_arrow_icon);
        last_sync_row_arrow_icon.set_visible (false);

        update_last_sync_row ();

        var default_group = new Adw.PreferencesGroup () {
            margin_top = 24
        };

        default_group.add (display_entry);

        if (source.source_type != SourceType.LOCAL) {
            default_group.add (sync_server_row);
            default_group.add (last_sync_row);
        }

        certificate_sections_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

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
            margin_top = 24,
            margin_bottom = 24
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

        if (source.source_type == SourceType.CALDAV) {
            refresh_certificate_sections ();
            main_content.append (certificate_sections_box);
        }

        if (source.source_type != SourceType.LOCAL) {
            main_content.append (delete_stack);
        }

        var content_clamp = new Adw.Clamp () {
            maximum_size = 600,
            margin_start = 24,
            margin_end = 24,
            child = main_content
        };

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = content_clamp
        };

        var toolbar_view = new Adw.ToolbarView () {
            content = scrolled_window
        };
        toolbar_view.add_top_bar (new Adw.HeaderBar ());

        child = toolbar_view;

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

        signal_map[last_sync_row.activated.connect (() => {
            show_sync_error_details ();
        })] = last_sync_row;

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

        signal_map[source.deleted.connect (() => {
            preferences_dialog.pop_subpage ();
        })] = source;

        signal_map[source.sync_failed.connect ((status) => {
            update_last_sync_row ();
        })] = source;

        signal_map[source.sync_finished.connect (() => {
            update_last_sync_row ();
        })] = source;

        destroy.connect (() => {
            clean_up ();
        });
    }

    private void update_last_sync_row () {
        if (last_sync_row == null || last_sync_label == null) {
            return;
        }

        if (source.sync_status != null) {
            last_sync_label.label = _("Failed");
            last_sync_label.add_css_class ("error");
            last_sync_row.activatable = true;
            last_sync_row_arrow_icon.set_visible (true);
            last_sync_row.subtitle = _("View details");
            return;
        }

        last_sync_label.remove_css_class ("error");
        last_sync_row.activatable = false;
        last_sync_row_arrow_icon.set_visible (false);
        last_sync_row.subtitle = null;

        if (source.last_sync == null || source.last_sync == "") {
            last_sync_label.label = _("Never");
            return;
        }

        var last_sync_date = new GLib.DateTime.from_iso8601 (source.last_sync, new GLib.TimeZone.local ());
        if (last_sync_date == null) {
            last_sync_label.label = _("Unknown");
            return;
        }

        last_sync_label.label = Utils.Datetime.get_relative_date_from_date (last_sync_date);
    }

    private void show_sync_error_details () {
        if (source.sync_status == null) {
            return;
        }

        var can_review_certificate = source.source_type == SourceType.CALDAV &&
            source.sync_status.error_type == SyncErrorType.CERTIFICATE_ERROR;

        if (can_review_certificate) {
            open_pending_certificate_dialog ();
        } else {
            var dialog = new Adw.AlertDialog (
                source.sync_status.title,
                source.sync_status.description
            );

            dialog.add_response ("close", _("Close"));
            dialog.close_response = "close";

            dialog.present (Planify._instance.main_window);
        }

    }

    private void refresh_certificate_sections () {
        if (certificate_sections_box == null || source.source_type != SourceType.CALDAV) {
            return;
        }

        Gtk.Widget? child = certificate_sections_box.get_first_child ();
        while (child != null) {
            var next = child.get_next_sibling ();
            certificate_sections_box.remove (child);
            child = next;
        }

        var certificates = Services.CalDAV.CertificateTrustStore.get_default ().get_trusted_certificates_for_source (source.id);
        if (certificates.size == 0) {
            return;
        }

        var certificates_group = new Adw.PreferencesGroup () {
            title = _("Manually Trusted Certificates")
        };

        foreach (var certificate in certificates) {
            var host = certificate.has_key ("host") ? certificate["host"] : _("Unknown host");
            var fingerprint = certificate.has_key ("fingerprint_sha256") ? certificate["fingerprint_sha256"] : _("Unknown fingerprint");
            var certificate_host = host;

            var certificate_row = new Adw.ActionRow () {
                title = host,
                subtitle = fingerprint,
                subtitle_selectable = true
            };

            var delete_certificate_button = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
                tooltip_text = _("Untrust Certificate"),
                valign = Gtk.Align.CENTER,
                css_classes = { "flat", "destructive-action" }
            };

            certificate_row.add_suffix (delete_certificate_button);

            signal_map[delete_certificate_button.clicked.connect (() => {
                var deleted = Services.CalDAV.CertificateTrustStore.get_default ().remove_trusted_certificate_for_source (source.id, certificate_host);
                if (!deleted) {
                    popup_toast (_("Could not untrust certificate"));
                    return;
                }

                // Force a new Soup.Session for the next request so removed trust does not linger.
                Services.CalDAV.Core.get_default ().remove_client (source.id);
                refresh_certificate_sections ();
                Services.CalDAV.Core.get_default ().sync.begin (source);
                popup_toast (_("Certificate untrusted"));
            })] = delete_certificate_button;

            certificates_group.add (certificate_row);
        }

        certificate_sections_box.append (certificates_group);
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

    public bool open_pending_certificate_dialog () {
        if (source.source_type != SourceType.CALDAV) {
            return false;
        }

        var tls_failure_context = Services.CalDAV.CertificateTrustStore.get_default ().get_last_tls_failure_for_source (source.id);
        if (tls_failure_context == null || tls_failure_context.flags != GLib.TlsCertificateFlags.UNKNOWN_CA) {
            return false;
        }

        var trust_page = Dialogs.Preferences.Pages.CertificateDetails.build_for_source (
            preferences_dialog,
            source.id,
            source.caldav_data.server_url
        );
        if (trust_page == null) {
            return false;
        }

        signal_map[trust_page.certificate_trusted.connect (() => {
            var persisted = Services.CalDAV.CertificateTrustStore.get_default ().persist_pending_trusted_certificates_for_source (source.id);
            if (!persisted) {
                popup_toast (_("Failed to save trusted certificates"));
                return;
            }

            Services.CalDAV.Core.get_default ().sync.begin (source);
            refresh_certificate_sections ();
        })] = trust_page;

        preferences_dialog.push_subpage (trust_page);
        return true;
    }
}
