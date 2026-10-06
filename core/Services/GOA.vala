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
 * Authored by: Alain M. <alainmh23@gmail.com>
 */

public class Services.GOA : Object {
    private static GLib.Once<Services.GOA> _instance;
    public static unowned Services.GOA get_default () {
        return _instance.once (() => {
            return new Services.GOA ();
        });
    }

    public class DetectedAccount : Object {
        public string id { get; construct; }
        public string provider_type { get; construct; }
        public string display_name { get; construct; }
        public string identity { get; construct; }
        public string server_uri { get; construct; }
        public bool accept_ssl_errors { get; construct; }

        public DetectedAccount (string id, string provider_type, string display_name,
                                string identity, string server_uri, bool accept_ssl_errors) {
            Object (
                id: id,
                provider_type: provider_type,
                display_name: display_name,
                identity: identity,
                server_uri: server_uri,
                accept_ssl_errors: accept_ssl_errors
            );
        }

        public bool is_nextcloud () {
            return provider_type == "nextcloud" || provider_type == "owncloud";
        }

        public string username {
            get {
                _username = compute_username ();
                return _username;
            }
        }
        private string _username;

        private string compute_username () {
            if (identity == null || identity == "") {
                return "";
            }

            int at = identity.last_index_of_char ('@');
            if (at < 0) {
                return identity;
            }

            string local_part = identity.substring (0, at);
            string host_part = identity.substring (at + 1);

            string server_host = "";
            try {
                var uri = GLib.Uri.parse (server_uri, GLib.UriFlags.NONE);
                server_host = uri.get_host () ?? "";
            } catch (Error e) {
                server_host = "";
            }

            if (server_host != "" && host_part.has_prefix (server_host)) {
                return local_part;
            }

            return identity;
        }
    }

    private Goa.Client? client = null;
    private bool tried_init = false;


    private async Goa.Client? get_client () {
        if (client != null) {
            return client;
        }

        if (tried_init) {
            return client;
        }
        tried_init = true;

        try {
            client = yield new Goa.Client (null);
        } catch (Error e) {
            Services.LogService.get_default ().info (
                "GOA", "GNOME Online Accounts not available: %s".printf (e.message)
            );
            client = null;
        }

        return client;
    }

    public async bool is_available () {
        return (yield get_client ()) != null;
    }

    private const string[] SUPPORTED_PROVIDERS = { "nextcloud", "owncloud", "webdav" };

    private static bool is_supported_provider (string provider_type) {
        foreach (unowned string p in SUPPORTED_PROVIDERS) {
            if (p == provider_type) {
                return true;
            }
        }
        return false;
    }

    private static string normalize_server_uri (string raw) {
        try {
            var uri = GLib.Uri.parse (raw, GLib.UriFlags.NONE);
            var scheme = uri.get_scheme ();
            var host = uri.get_host ();

            if (host == null || host == "") {
                return raw;
            }

            string server = "%s://%s".printf (scheme, host);

            int port = uri.get_port ();
            bool default_port = (scheme == "https" && port == 443)
                || (scheme == "http" && port == 80);
            if (port > 0 && !default_port) {
                server += ":%d".printf (port);
            }

            string path = uri.get_path ();
            if (path != null && path != "" && path != "/"
                && !path.has_prefix ("/remote.php")
                && !path.has_prefix ("/dav")) {
                if (path.has_suffix ("/")) {
                    path = path.substring (0, path.length - 1);
                }
                server += path;
            }

            return server;
        } catch (Error e) {
            Services.LogService.get_default ().warn (
                "GOA", "Could not normalize URI '%s': %s".printf (raw, e.message)
            );
            return raw;
        }
    }

    public async Gee.ArrayList<DetectedAccount> list_caldav_accounts () {
        var result = new Gee.ArrayList<DetectedAccount> ();

        var goa_client = yield get_client ();
        if (goa_client == null) {
            return result;
        }

        foreach (unowned Goa.Object object in goa_client.get_accounts ()) {
            var account = object.get_account ();
            if (account == null || account.calendar_disabled) {
                continue;
            }

            if (!is_supported_provider (account.provider_type)) {
                continue;
            }

            var calendar = object.get_calendar ();
            if (calendar == null || calendar.uri == null || calendar.uri == "") {
                continue;
            }

            result.add (new DetectedAccount (
                account.id,
                account.provider_type,
                account.provider_name,
                account.presentation_identity,
                normalize_server_uri (calendar.uri),
                calendar.accept_ssl_errors
            ));
        }

        return result;
    }
}
