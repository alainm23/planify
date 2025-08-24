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
            debug (e.message);
        }

        return server_url;
    }

    public async HttpResponse start_login_flow (string server_url, GLib.Cancellable cancellable) {
        HttpResponse response = new HttpResponse ();

        string login_url = "%s/index.php/login/v2".printf (validate_server_url (server_url));

        var message = new Soup.Message ("POST", login_url);
        message.request_headers.append ("User-Agent", Constants.SOUP_USER_AGENT);         // The User Agent is used by Nextcloud for the App Name

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, cancellable);

            parser.load_from_data ((string) stream.get_data ());

            var root = parser.get_root ().get_object ();

            var login_link = root.get_string_member ("login");

            var poll = root.get_object_member ("poll");
            var poll_token = poll.get_string_member ("token");
            var poll_endpoint = poll.get_string_member ("endpoint");

            AppInfo.launch_default_for_uri (login_link, null);

            int timeout = 20 * 60;
            int interval = 5;

            while (timeout > 0 && !cancellable.is_cancelled ()) {
                var poll_msg = new Soup.Message ("POST", poll_endpoint);

                poll_msg.request_headers.append ("User-Agent", Constants.SOUP_USER_AGENT);
                poll_msg.set_request_body_from_bytes ("application/json", new Bytes ("""{ "token": "%s" }""".printf (poll_token).data));

                try {
                    GLib.Bytes poll_response = yield session.send_and_read_async (poll_msg, GLib.Priority.HIGH, cancellable);

                    var poll_str = (string) poll_response.get_data ();

                    Json.Parser poll_parser = new Json.Parser ();
                    poll_parser.load_from_data (poll_str);

                    var poll_root = poll_parser.get_root ();

                    if (poll_root.get_node_type () == Json.NodeType.OBJECT) {
                        var poll_object = poll_root.get_object ();

                        if (poll_object.has_member ("loginName")) {

                            var server = poll_object.get_string_member ("server");
                            var login_name = poll_object.get_string_member ("loginName");
                            var app_password = poll_object.get_string_member ("appPassword");

                            var dav_endpoint = yield Core.get_default ().resolve_well_known_caldav (session, server);
                            print ("Using DAV Endpoint: %s\n", dav_endpoint);

                            var calendar_home = yield Core.get_default ().resolve_calendar_home (CalDAVType.NEXTCLOUD, dav_endpoint, login_name, app_password, cancellable);
                            print ("Calendar Home: %s\n", calendar_home);
                            var login_response = yield Core.get_default ().login (CalDAVType.NEXTCLOUD, dav_endpoint, login_name, app_password, calendar_home, cancellable);

                            return login_response;
                        }
                    }
                } catch (Error err) {
                    response.error_code = err.code;
                    response.error = "Polling error: %s".printf (err.message);
                    break;
                }

                yield Util.nap (interval * 1000);

                timeout -= interval;
            }
        } catch (Error e) {
            response.error_code = e.code;
            response.error = "login error: %s".printf (e.message);
        }

        return response;
    }
}
