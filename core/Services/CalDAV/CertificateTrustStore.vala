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

public class Services.CalDAV.RejectedCertificateContext : GLib.Object {
    public string url { get; construct; }
    public GLib.TlsCertificate certificate { get; construct; }
    public GLib.TlsCertificateFlags flags { get; construct; }

    public RejectedCertificateContext (string url, GLib.TlsCertificate certificate, GLib.TlsCertificateFlags flags) {
        Object (url: url, certificate: certificate, flags: flags);
    }
}

public class Services.CalDAV.CertificateTrustStore : GLib.Object {
    private static CertificateTrustStore ? _instance;
    private Gee.HashMap<string, Gee.HashMap<string, string> > pending_trusted_certificates_by_source;
    private Gee.HashMap<string, RejectedCertificateContext> tls_failures_by_source;

    public static CertificateTrustStore get_default () {
        if (_instance == null) {
            _instance = new CertificateTrustStore ();
        }
        return _instance;
    }

    private CertificateTrustStore () {
        pending_trusted_certificates_by_source = new Gee.HashMap<string, Gee.HashMap<string, string> > ();
        tls_failures_by_source = new Gee.HashMap<string, RejectedCertificateContext> ();
    }

    private string ? extract_normalized_host (string url) {
        try {
            var uri = GLib.Uri.parse (url, GLib.UriFlags.NONE);
            var host = uri.get_host ();
            if (host == null) {
                return null;
            }

            var normalized_host = host.strip ().down ();
            if (normalized_host.contains (" ")) {
                return null;
            }

            return normalized_host;
        } catch (Error e) {
            Services.LogService.get_default ().warn ("CertificateTrustStore", "Failed to parse host from URL '%s': %s".printf (url, e.message));
            return null;
        }
    }

    public RejectedCertificateContext ? get_last_tls_failure_for_source (string source_id) {
        return tls_failures_by_source.has_key (source_id) ? tls_failures_by_source[source_id] : null;
    }

    public string compute_certificate_sha256_fingerprint (GLib.TlsCertificate certificate) {
        return Checksum.compute_for_string (ChecksumType.SHA256, certificate.certificate_pem, -1);
    }

    public string build_tls_failure_message_for_source (string source_id) {
        var context = get_last_tls_failure_for_source (source_id);

        if (context == null) {
            return _("The server certificate could not be verified.");
        }

        var host = extract_normalized_host (context.url);
        var server_label = host ?? context.url;

        var cert = context.certificate;
        GLib.TlsCertificateFlags errors = context.flags;

        var parts = new Gee.ArrayList<string> ();

        if ((errors & GLib.TlsCertificateFlags.UNKNOWN_CA) != 0) {
            parts.add (_("The certificate is signed by an untrusted authority"));
        }

        if ((errors & GLib.TlsCertificateFlags.BAD_IDENTITY) != 0) {
            var subject = cert.get_subject_name () ?? _("unknown subject");
            parts.add (_("Host mismatch (%s)").printf (subject));
        }


        if ((errors & GLib.TlsCertificateFlags.NOT_ACTIVATED) != 0) {
            var not_before = cert.get_not_valid_before ();

            string date = _("unknown");
            if (not_before != null) {
                date = "%s, %s".printf (
                    not_before.format (Utils.Datetime.get_default_date_format (false, true, true)),
                    not_before.format (Utils.Datetime.get_default_time_format ())
                );
            }

            parts.add (_("Not yet valid (from %s)").printf (date));
        }

        if ((errors & GLib.TlsCertificateFlags.EXPIRED) != 0) {
            var not_after = cert.get_not_valid_after ();

            string date = _("unknown");
            if (not_after != null) {
                date = "%s, %s".printf (
                    not_after.format (Utils.Datetime.get_default_date_format (false, true, true)),
                    not_after.format (Utils.Datetime.get_default_time_format ())
                );
            }

            parts.add (_("Expired (since %s)").printf (date));
        }

        if ((errors & GLib.TlsCertificateFlags.REVOKED) != 0) {
            parts.add (_("Revoked certificate"));
        }

        if ((errors & GLib.TlsCertificateFlags.INSECURE) != 0) {
            parts.add (_("Insecure cryptography"));
        }

        if ((errors & GLib.TlsCertificateFlags.GENERIC_ERROR) != 0) {
            parts.add (_("Generic TLS error"));
        }

        string details;

        if (parts.size == 0) {
            details = _("Unknown validation error");
        } else {
            details = "";
            foreach (var part in parts) {
                details = details + "\n - " + part;
            }
        }

        return _("Certificate validation for host '%s' failed: %s").printf (
            server_label,
            details
        );
    }

    private bool is_certificate_already_trusted_for_source (string source_id, string url, GLib.TlsCertificate certificate) {
        var host = extract_normalized_host (url);
        if (host == null) {
            return false;
        }

        var certificate_fingerprint = compute_certificate_sha256_fingerprint (certificate);

        var db_fingerprint = Services.Database.get_default ().get_trusted_certificate_fingerprint (source_id, host);
        if (db_fingerprint != null && db_fingerprint == certificate_fingerprint) {
            return true;
        }

        if (pending_trusted_certificates_by_source.has_key (source_id)) {
            var pending_trusted_certificates = pending_trusted_certificates_by_source[source_id];
            if (pending_trusted_certificates.has_key (host) && pending_trusted_certificates[host] == certificate_fingerprint) {
                return true;
            }
        }

        return false;
    }

    public void attach_certificate_handler (Soup.Message message, string source_id, string url) {
        message.accept_certificate.connect ((certificate, errors) => {
            if (errors != GLib.TlsCertificateFlags.UNKNOWN_CA) {
                Services.LogService.get_default ().warn (
                    "CertificateTrustStore",
                    build_tls_failure_message_for_source (source_id)
                );
                tls_failures_by_source[source_id] = new RejectedCertificateContext (url, certificate, errors);
                return false;
            }

            if (is_certificate_already_trusted_for_source (source_id, url, certificate)) {
                tls_failures_by_source.unset (source_id);
                return true;
            }

            tls_failures_by_source[source_id] = new RejectedCertificateContext (url, certificate, errors);
            Services.LogService.get_default ().info ("CertificateTrustStore", "Rejected certificate remembered for source '%s' and URL '%s'".printf (source_id, url));
            return false;
        });
    }

    public bool trust_unknown_ca_certificate_for_source (string source_id) {
        var context = get_last_tls_failure_for_source (source_id);
        if (context == null || context.flags != GLib.TlsCertificateFlags.UNKNOWN_CA) {
            return false;
        }

        var host = extract_normalized_host (context.url);
        if (host == null) {
            return false;
        }

        if (!pending_trusted_certificates_by_source.has_key (source_id)) {
            pending_trusted_certificates_by_source[source_id] = new Gee.HashMap<string, string> ();
        }

        var pending_trusted_certificates = pending_trusted_certificates_by_source[source_id];
        pending_trusted_certificates[host] = compute_certificate_sha256_fingerprint (context.certificate);

        tls_failures_by_source.unset (source_id);

        Services.LogService.get_default ().info ("CertificateTrustStore", "Rejected certificate accepted for source '%s' and host '%s'".printf (source_id, host));
        return true;
    }

    public bool remove_trusted_certificate_for_source (string source_id, string host) {
        var host_key = host.down ();
        var deleted = Services.Database.get_default ().delete_trusted_certificate (source_id, host_key);

        if (pending_trusted_certificates_by_source.has_key (source_id)) {
            var pending_trusted_certificates = pending_trusted_certificates_by_source[source_id];
            pending_trusted_certificates.unset (host_key);

            if (pending_trusted_certificates.size == 0) {
                pending_trusted_certificates_by_source.unset (source_id);
            }
        }

        if (deleted) {
            Services.LogService.get_default ().info ("CertificateTrustStore", "Trusted certificate deleted for source '%s' and host '%s'".printf (source_id, host_key));
        }

        return deleted;
    }

    public bool persist_pending_trusted_certificates_for_source (string source_id) {
        if (!pending_trusted_certificates_by_source.has_key (source_id)) {
            return true;
        }

        var pending_trusted_certificates = pending_trusted_certificates_by_source[source_id];
        if (!Services.Database.get_default ().upsert_trusted_certificates_transaction (source_id, pending_trusted_certificates)) {
            Services.LogService.get_default ().warn (
                "CertificateTrustStore",
                "Failed to persist pending trusted certificates for source '%s'. In-memory state preserved for retry.".printf (source_id)
            );
            return false;
        }

        pending_trusted_certificates_by_source.unset (source_id);

        Services.LogService.get_default ().info ("CertificateTrustStore", "Pending trusted certificates persisted for source '%s'".printf (source_id));
        return true;
    }

    public Gee.ArrayList<Gee.HashMap<string, string> > get_trusted_certificates_for_source (string source_id) {
        return Services.Database.get_default ().get_trusted_certificates_for_source (source_id);
    }

    public void clear_source_state (string source_id) {
        pending_trusted_certificates_by_source.unset (source_id);
        tls_failures_by_source.unset (source_id);
    }
}
