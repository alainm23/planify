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

public class Services.CalDAV.Providers.Nextcloud : Object {

    private Soup.Session session;
    private Json.Parser parser;

    public Nextcloud () {
        session = new Soup.Session ();
        parser = new Json.Parser ();
    }

    private string validate_server_url (string url) {
        Services.LogService.get_default ().info ("Nextcloud", "Validating server URL");
        string server_url = "";

        try {
            var _uri = GLib.Uri.parse (url, GLib.UriFlags.NONE);

            server_url = "%s://%s".printf (_uri.get_scheme (), _uri.get_host ());
            if (_uri.get_port () > 0) {
                server_url = "%s://%s:%d".printf (_uri.get_scheme (), _uri.get_host (), _uri.get_port ());
            }

            string path = _uri.get_path ();
            if (path.has_suffix ("/")) {
                path = path.substring (0, path.length - 1);
            }

            server_url += path;
        } catch (Error e) {
            Services.LogService.get_default ().error ("Nextcloud", "Failed to validate server URL: %s".printf (e.message));
        }

        return server_url;
    }

    public async HttpResponse start_login_flow (string server_url, GLib.Cancellable cancellable, string source_id) {
        Services.LogService.get_default ().info ("Nextcloud", "Starting login flow");
        HttpResponse response = new HttpResponse ();

        string login_url = "%s/index.php/login/v2".printf (validate_server_url (server_url));

        var message = new Soup.Message ("POST", login_url);
        message.request_headers.append ("User-Agent", Constants.SOUP_USER_AGENT);         // The User Agent is used by Nextcloud for the App Name

        Services.CalDAV.CertificateTrustStore.get_default ().attach_certificate_handler (message, source_id, login_url);

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, cancellable);

            parser.load_from_data ((string) stream.get_data ());

            var root = parser.get_root ().get_object ();

            var login_link = root.get_string_member ("login");

            var poll = root.get_object_member ("poll");
            var poll_token = poll.get_string_member ("token");
            var poll_endpoint = poll.get_string_member ("endpoint");

            AppInfo.launch_default_for_uri (login_link, null);

            Services.LogService.get_default ().info ("Nextcloud", "Login page opened in browser, waiting for authentication");

            int timeout = 20 * 60;
            int interval = 5;

            while (timeout > 0 && !cancellable.is_cancelled ()) {
                var poll_msg = new Soup.Message ("POST", poll_endpoint);

                poll_msg.request_headers.append ("User-Agent", Constants.SOUP_USER_AGENT);
                poll_msg.set_request_body_from_bytes ("application/json", new Bytes ("""{ "token": "%s" }""".printf (poll_token).data));
                Services.CalDAV.CertificateTrustStore.get_default ().attach_certificate_handler (poll_msg, source_id, poll_endpoint);

                try {
                    GLib.Bytes poll_response = yield session.send_and_read_async (poll_msg, GLib.Priority.HIGH, cancellable);

                    var poll_str = (string) poll_response.get_data ();

                    Json.Parser poll_parser = new Json.Parser ();
                    poll_parser.load_from_data (poll_str);

                    var poll_root = poll_parser.get_root ();

                    if (poll_root.get_node_type () == Json.NodeType.OBJECT) {
                        var poll_object = poll_root.get_object ();

                        if (poll_object.has_member ("loginName")) {
                            Services.LogService.get_default ().info ("Nextcloud", "Authentication successful, resolving CalDAV endpoint");

                            var server = poll_object.get_string_member ("server");
                            var login_name = poll_object.get_string_member ("loginName");
                            var app_password = poll_object.get_string_member ("appPassword");

                            var dav_endpoint = yield Core.get_default ().resolve_well_known_caldav (session, server, source_id);
                            Services.LogService.get_default ().info ("Nextcloud", "Resolved well-known CalDAV endpoint");

                            var calendar_home = yield Core.get_default ().resolve_calendar_home (CalDAVType.NEXTCLOUD, dav_endpoint, login_name, app_password, cancellable, source_id);
                            Services.LogService.get_default ().info ("Nextcloud", "Resolved calendar home");
                            
                            var login_response = yield Core.get_default ().login (CalDAVType.NEXTCLOUD, dav_endpoint, login_name, app_password, calendar_home, cancellable, source_id);

                            return login_response;
                        }
                    }
                } catch (Error err) {
                    Services.LogService.get_default ().error ("Nextcloud", "Polling error: %s".printf (err.message));
                    response.error_code = err.code;
                    response.error = "Polling error: %s".printf (err.message);
                    break;
                }

                yield Util.nap (interval * 1000);

                timeout -= interval;
            }
        } catch (Error e) {
            Services.LogService.get_default ().error ("Nextcloud", "Login flow error: %s".printf (e.message));
            response.error_code = e.code;
            response.error = "login error: %s".printf (e.message);
        }

        return response;
    }
}
