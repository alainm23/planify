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

public class Services.CalDAV.Core : GLib.Object {

    private Gee.HashMap<string, Services.CalDAV.CalDAVClient> clients;

    public signal void sync_progress (int current, int total, string message);

    private static Core ? _instance;
    public static Core get_default () {
        if (_instance == null) {
            _instance = new Core ();
        }

        return _instance;
    }

    public Core () {
        clients = new Gee.HashMap<string, Services.CalDAV.CalDAVClient> ();
    }


    public Services.CalDAV.CalDAVClient get_client (Objects.Source source) {
        if (!clients.has_key (source.id)) {
            var client = new Services.CalDAV.CalDAVClient (
                new Soup.Session (),
                source.caldav_data.server_url,
                source.caldav_data.username,
                source.caldav_data.password,
                source.caldav_data.ignore_ssl
            );
            clients[source.id] = client;
        }
        return clients[source.id];
    }

    public Services.CalDAV.CalDAVClient? get_client_by_id (string source_id) {
        if (clients.has_key (source_id)) {
            return clients[source_id];
        }
        return null;
    }

    public void remove_client (string source_id) {
        clients.unset (source_id);
    }

    public void clear () {
        clients.clear ();
    }


    private string make_absolute_url (string base_url, string href) {
        string abs_url = null;
        try {
            abs_url = GLib.Uri.resolve_relative (base_url, href, GLib.UriFlags.NONE).to_string ();
        } catch (Error e) {
            critical ("Failed to resolve relative url: %s", e.message);
        }
        return abs_url;
    }

    public async string resolve_well_known_caldav (Soup.Session session, string base_url, bool ignore_ssl = false) throws GLib.Error {
        var well_known_url = make_absolute_url (base_url, "/.well-known/caldav");
        var msg = new Soup.Message ("GET", well_known_url);
        msg.request_headers.append ("User-Agent", Constants.SOUP_USER_AGENT);

        msg.set_flags (Soup.MessageFlags.NO_REDIRECT);

        if (ignore_ssl) {
            msg.accept_certificate.connect (() => {
                return true;
            });
        }

        try {
            yield session.send_and_read_async (msg, Priority.DEFAULT, null);
            // These are all the redirect status codes.
            // https://www.rfc-editor.org/rfc/rfc6764#section-5
            // https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
            if (msg.status_code == 301 || msg.status_code == 302 || msg.status_code == 307 || msg.status_code == 308 ) {
                string? location = msg.response_headers.get_one ("Location");
                if (location != null) {
                    if (location.has_prefix ("/")) {
                        location = make_absolute_url (base_url, location);
                    }

                    // Prevent https → http downgrade
                    // See https://github.com/alainm23/planify/issues/1149#issuecomment-3236718109
                    var base_scheme = GLib.Uri.parse_scheme (base_url);
                    var location_scheme = GLib.Uri.parse_scheme (location);

                    if (base_scheme == "https" && location_scheme == "http") {
                        if (location.has_prefix ("http://")) {
                            warning ("Resolving .well-known/caldav caused a redirect from https to http. Preventing downgrade.");
                            location = "https" + location.substring (4); // removes http and puts https infront
                        } else {
                            warning ("Redirect location has http scheme but unexpected format: %s", location);
                            return base_url;
                        }
                    }

                    return location;
                }
            }
            return base_url;
        } catch (Error e) {
            if (e is GLib.IOError.CANCELLED) {
                throw e;
            }
            warning ("Failed to check .well-known/caldav: %s", e.message);
            return base_url;
        }
    }


    public async string? resolve_calendar_home (CalDAVType caldav_type, string dav_url, string username, string password, GLib.Cancellable cancellable, bool ignore_ssl = false) throws GLib.Error {
        var caldav_client = new Services.CalDAV.CalDAVClient (new Soup.Session (), dav_url, username, password, ignore_ssl);

        try {
            string? principal_url = yield caldav_client.get_principal_url (cancellable);

            if (principal_url == null) {
                throw new GLib.IOError.FAILED ("No principal url received");
            }

            var calendar_home = yield caldav_client.get_calendar_home (principal_url, cancellable);

            return calendar_home;
        } catch (Error e) {
            if (e is GLib.IOError.CANCELLED) {
                throw e;
            }
            throw new GLib.IOError.FAILED ("Failed to resolve calendar home: %s".printf (e.message));
        }
    }

    public async HttpResponse login (CalDAVType caldav_type, string dav_url, string username, string password, string calendar_home, GLib.Cancellable cancellable, bool ignore_ssl = false) {
        HttpResponse response = new HttpResponse ();

        if (Services.Store.instance ().source_caldav_exists (dav_url, username)) {
            response.error_code = 409;
            response.error = _("Source already exists");
            return response;
        }

        var caldav_client = new Services.CalDAV.CalDAVClient (new Soup.Session (), dav_url, username, password, ignore_ssl);

        try {
            string? principal_url = yield caldav_client.get_principal_url (cancellable);

            if (principal_url == null) {
                response.error_code = 409;
                response.error = _("Failed to resolve principal url");
                return response;
            }

            var source = new Objects.Source ();
            source.id = Util.get_default ().generate_id ();
            source.source_type = SourceType.CALDAV;
            source.last_sync = new GLib.DateTime.now_local ().to_string ();

            Objects.SourceCalDAVData caldav_data = new Objects.SourceCalDAVData ();
            caldav_data.server_url = dav_url;
            caldav_data.calendar_home_url = calendar_home;
            caldav_data.username = username;
            caldav_data.password = password;
            caldav_data.caldav_type = caldav_type;
            caldav_data.ignore_ssl = ignore_ssl;

            source.data = caldav_data;

            GLib.Value _data_object = Value (typeof (Objects.Source));
            _data_object.set_object (source);

            response.data_object = _data_object;
            response.status = true;

            clients[source.id] = caldav_client;
        } catch (Error e) {
            print ("login error: %s".printf (e.message));
            response.error_code = e.code;
            response.error = e.message;
        }

        return response;
    }

    // TODO: why is this a seperate method, can this be merged with login?
    public async HttpResponse add_caldav_account (Objects.Source source, GLib.Cancellable cancellable) {
        HttpResponse response = new HttpResponse ();
        var caldav_client = get_client (source);

        try {
            string? principal_url = yield caldav_client.get_principal_url (cancellable);

            if (principal_url == null) {
                response.error_code = 409;
                response.error = _("Failed to resolve principal url");
                return response;
            }


            yield caldav_client.update_userdata (principal_url, source, cancellable);
            Services.Store.instance ().insert_source (source);

            Gee.ArrayList<Objects.Project> projects = yield caldav_client.fetch_project_list (source, cancellable);

            sync_progress (0, projects.size, _("Starting sync…"));

            const int BATCH_SIZE = 5;
            int processed = 0;

            for (int i = 0; i < projects.size; i += BATCH_SIZE) {
                var batch_end = int.min (i + BATCH_SIZE, projects.size);
                
                for (int j = i; j < batch_end; j++) {
                    Services.Store.instance ().insert_project (projects[j]);
                }
                
                yield Util.nap (10);
                
                for (int j = i; j < batch_end; j++) {
                    sync_progress (processed + 1, projects.size, _("Syncing %s…").printf (projects[j].name));
                    yield caldav_client.fetch_items_for_project (projects[j], cancellable, (current, total, msg) => {
                        sync_progress (current, total, msg);
                    });
                    processed++;
                }
            }

            sync_progress (projects.size, projects.size, _("Sync completed"));
            response.status = true;
        } catch (Error e) {
            response.error_code = e.code;
            response.error = e.message;
            debug (e.message);
        }

        return response;
    }


    public async void sync (Objects.Source source) {
        var caldav_client = get_client (source);

        source.sync_started ();

        try {
            var cancellable = new GLib.Cancellable ();
            yield caldav_client.sync (source, cancellable);

            foreach (Objects.Project project in Services.Store.instance ().get_projects_by_source (source.id)) {
                yield caldav_client.sync_tasklist (project, cancellable);
            }

            source.sync_finished ();
            source.last_sync = new GLib.DateTime.now_local ().to_string ();
        } catch (Error e) {
            warning ("Failed to sync: %s", e.message);
            source.sync_failed ();
        }
    }
}
