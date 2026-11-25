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
 *
 * Authored by: Pascal Wittmann <mail@pascal-wittmann.de>
 */

// Row that lets the user attach an mTLS client certificate (.pem or .p12/.pfx).
// File contents are kept base64-encoded so they survive Flatpak sandbox restarts.
public class Widgets.ClientCertificateRow : Adw.ExpanderRow {
    private Adw.ActionRow file_row;
    private Gtk.Button choose_button;
    private Adw.PasswordEntryRow password_entry;

    // base64 encoded raw bytes of the selected certificate file.
    public string cert_data { get; private set; default = ""; }
    // "pem" or "pkcs12".
    public string cert_format { get; private set; default = ""; }

    public string cert_password {
        get { return password_entry.text; }
    }

    public bool cert_enabled {
        get { return enable_expansion; }
    }

    public bool has_certificate {
        get { return enable_expansion && cert_data != ""; }
    }

    public signal void changed ();

    public ClientCertificateRow () {
        title = _("Client certificate (mTLS)");
        subtitle = _("Authenticate to the server with a client certificate");
        show_enable_switch = true;
        enable_expansion = false;

        file_row = new Adw.ActionRow () {
            title = _("Certificate file"),
            subtitle = _("No file selected"),
            activatable = true
        };

        choose_button = new Gtk.Button.with_label (_("Choose…")) {
            valign = Gtk.Align.CENTER,
            css_classes = { "flat" }
        };
        file_row.add_suffix (choose_button);
        file_row.activatable_widget = choose_button;

        password_entry = new Adw.PasswordEntryRow () {
            title = _("Certificate password (PKCS#12)")
        };
        password_entry.input_purpose = Gtk.InputPurpose.PASSWORD;
        password_entry.enable_emoji_completion = false;

        add_row (file_row);
        add_row (password_entry);

        choose_button.clicked.connect (on_choose_clicked);

        password_entry.changed.connect (() => {
            changed ();
        });

        notify["enable-expansion"].connect (() => {
            changed ();
        });
    }

    // Prefills the row with a stored certificate for the edit view.
    public void set_certificate (string data, string format, string password) {
        cert_data = data;
        cert_format = format;
        password_entry.text = password ?? "";

        if (data != "") {
            enable_expansion = true;
            file_row.subtitle = format == "pkcs12"
                ? _("PKCS#12 certificate stored")
                : _("PEM certificate stored");
        } else {
            enable_expansion = false;
            file_row.subtitle = _("No file selected");
        }
    }

    private void on_choose_clicked () {
        var chooser = new Gtk.FileDialog () {
            title = _("Select client certificate"),
            modal = true
        };

        var filter = new Gtk.FileFilter ();
        filter.name = _("Certificates (PEM, PKCS#12)");
        filter.add_pattern ("*.pem");
        filter.add_pattern ("*.crt");
        filter.add_pattern ("*.cert");
        filter.add_pattern ("*.p12");
        filter.add_pattern ("*.pfx");

        var filters = new GLib.ListStore (typeof (Gtk.FileFilter));
        filters.append (filter);
        chooser.filters = filters;
        chooser.default_filter = filter;

        chooser.open.begin (Planify._instance.main_window, null, (obj, res) => {
            try {
                var file = chooser.open.end (res);
                if (file != null) {
                    load_certificate (file);
                }
            } catch (Error e) {
                // The user dismissing the dialog also lands here.
                Services.LogService.get_default ().debug ("ClientCertificateRow", "File dialog closed: %s".printf (e.message));
            }
        });
    }

    private void load_certificate (GLib.File file) {
        try {
            uint8[] contents;
            string etag;
            file.load_contents (null, out contents, out etag);

            cert_data = Base64.encode (contents);
            cert_format = detect_format (file, contents);

            file_row.subtitle = file.get_basename ();
            changed ();
        } catch (Error e) {
            Services.LogService.get_default ().error ("ClientCertificateRow", "Failed to read certificate: %s".printf (e.message));
            file_row.subtitle = _("Failed to read file");
            cert_data = "";
            cert_format = "";
            changed ();
        }
    }

    private string detect_format (GLib.File file, uint8[] contents) {
        var name = file.get_basename ();
        if (name != null) {
            var lower = name.down ();
            if (lower.has_suffix (".p12") || lower.has_suffix (".pfx")) {
                return "pkcs12";
            }
            if (lower.has_suffix (".pem") || lower.has_suffix (".crt") || lower.has_suffix (".cert")) {
                return "pem";
            }
        }

        // Fall back to sniffing the contents: PEM starts with "-----BEGIN".
        if ("-----BEGIN" in (string) contents) {
            return "pem";
        }

        return "pkcs12";
    }
}
