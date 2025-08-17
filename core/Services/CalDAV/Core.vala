/*
 * Copyright © 2024 Alain M. (https://github.com/alainm23/planify)
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
    private Soup.Session session;
    private Json.Parser parser;

    private static Core ? _instance;
    public static Core get_default () {
        if (_instance == null) {
            _instance = new Core ();
        }

        return _instance;
    }

    public signal void first_sync_started ();
    public signal void first_sync_finished ();

    public Gee.HashMap<string, Services.CalDAV.Providers.Base> providers_map = new Gee.HashMap<string, Services.CalDAV.Providers.Base> ();

    public Core () {
        session = new Soup.Session ();
        parser = new Json.Parser ();

        providers_map.set (CalDAVType.NEXTCLOUD.to_string (), new Services.CalDAV.Providers.Nextcloud ());
        providers_map.set (CalDAVType.GENERIC.to_string (), new Services.CalDAV.Providers.Generic ());
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

    public async string resolve_well_known_caldav (Soup.Session session, string base_url) {
        var well_known_url = make_absolute_url (base_url, "/.well-known/caldav");
        var msg = new Soup.Message ("GET", well_known_url);
        msg.set_flags (Soup.MessageFlags.NO_REDIRECT);

        try {
            GLib.Bytes stream = yield session.send_and_read_async (msg, Priority.DEFAULT, null);
            // These are all the redirect status codes.
            // https://www.rfc-editor.org/rfc/rfc6764#section-5
            // https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
            if (msg.status_code == 301 || msg.status_code == 302 || msg.status_code == 307 || msg.status_code == 308 ) {
                string? location = msg.response_headers.get_one ("Location");
                if (location != null) {
                    if (location.has_prefix ("/")) {
                        location = make_absolute_url (base_url, location);
                    }

                    return location;
                }
            }
            return base_url;
        } catch (Error e) {
            warning ("Failed to check .well-known/caldav: %s", e.message);
            return base_url;
        }
    }



    public async string? resolve_calendar_home (CalDAVType caldav_type, string dav_url, string username, string password, GLib.Cancellable cancellable) {
        var caldav_client = new Services.CalDAV.CalDAVClient.with_credentials (session, dav_url, username, password);

        try {
            string? principal_url = yield caldav_client.get_principal_url ();

            if (principal_url == null) {
                critical ("No principal url received");
                return null;
            }

            var calendar_home = yield caldav_client.get_calendar_home (principal_url);

            return calendar_home;
        } catch (Error e) {
            print ("login error: %s".printf (e.message));
            return null;
        }
    }

    public async HttpResponse login (CalDAVType caldav_type, string dav_url, string username, string password, string calendar_home, GLib.Cancellable cancellable) {
        HttpResponse response = new HttpResponse (); // TODO: This isn't always an HTTP Response, find a better name

        if (!providers_map.has_key (caldav_type.to_string ())) {
            response.error_code = 409;
            response.error = _("No Provider Available");
            return response;
        }

        if (Services.Store.instance ().source_caldav_exists (dav_url, username)) {
            response.error_code = 409;
            response.error = _("Source already exists");
            return response;
        }

        var base64_credentials = Base64.encode ("%s:%s".printf (username, password).data);
        var caldav_client = new Services.CalDAV.CalDAVClient.with_credentials (session, dav_url, username, password);

        try {
            string? principal_url = yield caldav_client.get_principal_url ();

            if (principal_url == null) {
                response.error_code = 409;
                response.error = _("No principal url received");
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
            caldav_data.caldav_type = caldav_type;
            caldav_data.credentials = base64_credentials;

            source.data = caldav_data;

            GLib.Value _data_object = Value (typeof (Objects.Source));
            _data_object.set_object (source);

            response.data_object = _data_object;
            response.status = true;

        } catch (Error e) {
            print ("login error: %s".printf (e.message));
            response.error_code = e.code;
            response.error = e.message;
        }

        return response;
    }

    public async HttpResponse add_caldav_account (Objects.Source source, GLib.Cancellable cancellable) {
        HttpResponse response = new HttpResponse (); // TODO: This isn't always an HTTP Response, find a better name

        if (!providers_map.has_key (source.caldav_data.caldav_type.to_string ())) {
            response.error = _("No Provider Available");
            return response;
        }

        Services.CalDAV.Providers.Base provider = providers_map.get (source.caldav_data.caldav_type.to_string ());
        var caldav_client = new Services.CalDAV.CalDAVClient (session, source.caldav_data.server_url, source.caldav_data.credentials);

        string? principal_url = yield caldav_client.get_principal_url ();

        if (principal_url == null) {
            critical ("No principal url received");
            return null;
        }

        first_sync_started ();

        try {
            yield caldav_client.update_userdata (principal_url, source);

            Services.Store.instance ().insert_source (source);

            yield caldav_client.fetch_all_tasklists (source.caldav_data.calendar_home_url, source);

            yield get_all_tasklist (source, response, cancellable);

            response.status = true;
        } catch (Error e) {
            response.error_code = e.code;
            response.error = e.message;
            debug (e.message);
        }

        return response;
    }

    public async void get_all_tasklist (Objects.Source source, HttpResponse response, GLib.Cancellable cancellable) {
        if (!providers_map.has_key (source.caldav_data.caldav_type.to_string ())) {
            return;
        }

        Services.CalDAV.Providers.Base provider = providers_map.get (source.caldav_data.caldav_type.to_string ());

        var url = provider.get_all_taskslist_url (source.caldav_data.server_url, source.caldav_data.username);

        var message = new Soup.Message ("PROPFIND", url);
        message.request_headers.append ("Authorization", "Basic %s".printf (source.caldav_data.credentials));
        message.set_request_body_from_bytes ("application/xml", new Bytes (provider.TASKLIST_REQUEST.data));
        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, cancellable);

            GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
            Gee.ArrayList<Objects.Project> projects = provider.get_projects_by_doc (doc, source);

            foreach (Objects.Project project in projects) {
                Services.Store.instance ().insert_project (project);
                yield get_all_tasks_by_tasklist (project);
            }

            first_sync_finished ();
        } catch (Error e) {
            response.error_code = e.code;
            response.error = e.message;
            debug (e.message);
        }
    }

    public async void get_all_tasks_by_tasklist (Objects.Project project) {
        var url = "%s/calendars/%s/%s/".printf (
            project.source.caldav_data.server_url,
            project.source.caldav_data.username,
            project.id
        );

        var message = new Soup.Message ("REPORT", url);
        message.request_headers.append ("Authorization", "Basic %s".printf (project.source.caldav_data.credentials));
        message.request_headers.append ("Depth", "1");
        message.set_request_body_from_bytes ("application/xml", new Bytes (Services.CalDAV.Providers.Nextcloud.TASKS_REQUEST.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
            GXml.DomHTMLCollection response = doc.get_elements_by_tag_name ("d:response");

            foreach (GXml.DomElement element in response) {
                add_item_if_not_exists (element, project);
            }
        } catch (Error e) {
            debug (e.message);
        }
    }

    private Objects.Item add_item_if_not_exists (GXml.DomElement element, Objects.Project project) {
        Objects.Item return_value = new Objects.Item.from_caldav_xml (element, project.id);

        string parent_id = Util.get_related_to_uid (element);
        if (parent_id != "") {
            Objects.Item ? parent_item = Services.Store.instance ().get_item (parent_id);
            if (parent_item != null) {
                parent_item.add_item_if_not_exists (return_value);
            } else {
                project.add_item_if_not_exists (return_value);
            }
        } else {
            project.add_item_if_not_exists (return_value);
        }

        return return_value;
    }

    public async void sync (Objects.Source source) {
        if (!providers_map.has_key (source.caldav_data.caldav_type.to_string ())) {
            return;
        }

        Services.CalDAV.Providers.Base provider = providers_map.get (source.caldav_data.caldav_type.to_string ());

        var url = "%s/calendars/%s/".printf (source.caldav_data.server_url, source.caldav_data.username);
        var message = new Soup.Message ("PROPFIND", url);
        message.request_headers.append ("Authorization", "Basic %s".printf (source.caldav_data.credentials));
        message.request_headers.append ("Depth", "1");
        message.set_request_body_from_bytes ("application/xml", new Bytes (provider.TASKLIST_REQUEST.data));

        source.sync_started ();

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
            GXml.DomHTMLCollection response = doc.get_elements_by_tag_name ("d:response");

            foreach (GXml.DomElement element in response) {
                if (is_vtodo_calendar (element)) {
                    Objects.Project ? project = Services.Store.instance ().get_project (get_tasklist_id_from_url (element));
                    if (project == null) {
                        project = new Objects.Project.from_caldav_xml (element);
                        project.source_id = source.id;

                        Services.Store.instance ().insert_project (project);
                        yield get_all_tasks_by_tasklist (project);
                    } else {
                        project.update_from_xml (element, false);
                        Services.Store.instance ().update_project (project);
                    }
                } else if (is_deleted_calendar (element)) {
                    Objects.Project ? project = Services.Store.instance ().get_project (get_tasklist_id_from_url (element));
                    if (project != null) {
                        Services.Store.instance ().delete_project (project);
                    }
                }
            }

            foreach (Objects.Project project in Services.Store.instance ().get_projects_by_source (source.id)) {
                yield sync_tasklist (project);
            }

            source.sync_finished ();
            source.last_sync = new GLib.DateTime.now_local ().to_string ();
        } catch (Error e) {
            debug ("Failed to sync: " + e.message);
            source.sync_failed ();
        }
    }

    public async void sync_tasklist (Objects.Project project) {
        if (project.is_deck) {
            return;
        }

        project.loading = true;
        yield update_tasklist_detail (project);

        var url = "%s/calendars/%s/%s".printf (project.source.caldav_data.server_url, project.source.caldav_data.username, project.id);
        var message = new Soup.Message ("REPORT", url);
        message.request_headers.append ("Authorization", "Basic %s".printf (project.source.caldav_data.credentials));
        message.set_request_body_from_bytes ("application/xml", new Bytes ((Services.CalDAV.Providers.Nextcloud.SYNC_TOKEN_REQUEST.printf (project.sync_id)).data));

        try {
            if (project.sync_id == "") {
                project.loading = false;
                return;
            }

            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
            GXml.DomHTMLCollection response = doc.get_elements_by_tag_name ("d:response");

            foreach (GXml.DomElement element in response) {
                GXml.DomHTMLCollection status = element.get_elements_by_tag_name ("d:status");
                string ics = get_task_ics_from_url (element);

                if (status.length > 0 && status.get_element (0).text_content == "HTTP/1.1 404 Not Found") { // TODO: Use the soup parser -> See WebDAVClient.vala
                    Objects.Item ? item = Services.Store.instance ().get_item_by_ics (ics);
                    if (item != null) {
                        Services.Store.instance ().delete_item (item);
                    }
                } else {
                    if (!is_vtodo (element)) {
                        continue;
                    }

                    string vtodo = yield get_vtodo_by_url (project, ics);

                    ICal.Component ical = new ICal.Component.from_string (vtodo);
                    Objects.Item ? item = Services.Store.instance ().get_item (ical.get_uid ());

                    if (item != null) {
                        string old_project_id = item.project_id;
                        string old_parent_id = item.parent_id;
                        bool old_checked = item.checked;

                        item.update_from_vtodo (vtodo, ics);
                        item.project_id = project.id;
                        Services.Store.instance ().update_item (item);

                        if (old_project_id != item.project_id || old_parent_id != item.parent_id) {
                            Services.EventBus.get_default ().item_moved (item, old_project_id, "", old_parent_id);
                        }

                        if (old_checked != item.checked) {
                            Services.Store.instance ().complete_item (item, old_checked);
                        }
                    } else {
                        var new_item = new Objects.Item.from_vtodo (vtodo, ics, project.id);
                        if (new_item.has_parent) {
                            Objects.Item ? parent_item = new_item.parent;
                            if (parent_item != null) {
                                parent_item.add_item_if_not_exists (new_item);
                            } else {
                                project.add_item_if_not_exists (new_item);
                            }
                        } else {
                            project.add_item_if_not_exists (new_item);
                        }
                    }
                }
            }

            GXml.DomHTMLCollection sync_token = doc.get_elements_by_tag_name ("d:sync-token");
            if (sync_token.length > 0) {
                project.sync_id = sync_token.get_element (0).text_content;
                project.update_local ();
            }
        } catch (Error e) {
            debug (e.message);
        }

        project.loading = false;
    }

    private async string ? get_vtodo_by_url (Objects.Project project, string task_ics) {
        var url = "%s/calendars/%s/%s/%s".printf (project.source.caldav_data.server_url, project.source.caldav_data.username, project.id, task_ics);

        var message = new Soup.Message ("GET", url);
        message.request_headers.append ("Authorization", "Basic %s".printf (project.source.caldav_data.credentials));

        string return_value = null;

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            return_value = (string) stream.get_data ();
        } catch (Error e) {
            debug (e.message);
        }

        return return_value;
    }

    public string get_tasklist_id_from_url (GXml.DomElement element) {
        GXml.DomElement href = element.get_elements_by_tag_name ("d:href").get_element (0);
        string[] parts = href.text_content.split ("/");
        return parts[parts.length - 2];
    }

    public string get_task_ics_from_url (GXml.DomElement element) {
        GXml.DomElement href = element.get_elements_by_tag_name ("d:href").get_element (0);
        string[] parts = href.text_content.split ("/");
        return parts[parts.length - 1];
    }

    public bool is_vtodo (GXml.DomElement element) {
        GXml.DomHTMLCollection propstat = element.get_elements_by_tag_name ("d:propstat");

        if (propstat.length <= 0) {
            return false;
        }

        GXml.DomHTMLCollection prop = propstat.get_element (0).get_elements_by_tag_name ("d:prop");

        if (prop.length <= 0) {
            return false;
        }

        GXml.DomHTMLCollection getcontenttype = prop.get_element (0).get_elements_by_tag_name ("d:getcontenttype");

        if (getcontenttype.length <= 0) {
            return false;
        }

        if (getcontenttype.get_element (0).text_content.index_of ("vtodo") > -1) {
            return true;
        }

        return false;
    }

    /*
     * Tasklist
     */

    public async HttpResponse add_tasklist (Objects.Project project) {
        var url = "%s/calendars/%s/%s/".printf (project.source.caldav_data.server_url, project.source.caldav_data.username, project.id);
        var message = new Soup.Message ("MKCOL", url);
        message.request_headers.append ("Authorization", "Basic %s".printf (project.source.caldav_data.credentials));
        message.set_request_body_from_bytes ("application/xml", new Bytes ((Services.CalDAV.Providers.Nextcloud.CREATE_TASKLIST_REQUEST.printf (project.name, project.color_hex)).data));

        HttpResponse response = new HttpResponse ();

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            if (message.get_status () == Soup.Status.CREATED) {
                response.status = true;
            } else {
                response.error_code = (int) message.status_code;
                response.error = (string) stream.get_data ();
            }
        } catch (Error e) {
            response.error_code = e.code;
            response.error = e.message;
            debug (e.message);
        }

        return response;
    }

    public async HttpResponse update_tasklist (Objects.Project project) {
        var url = "%s/calendars/%s/%s/".printf (project.source.caldav_data.server_url, project.source.caldav_data.username, project.id);

        var message = new Soup.Message ("PROPPATCH", url);
        message.request_headers.append ("Authorization", "Basic %s".printf (project.source.caldav_data.credentials));
        message.set_request_body_from_bytes ("application/xml", new Bytes ((Services.CalDAV.Providers.Nextcloud.UPDATE_TASKLIST_REQUEST.printf (project.name, project.color_hex)).data));

        HttpResponse response = new HttpResponse ();

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            if (message.get_status () == Soup.Status.MULTI_STATUS) {
                response.status = true;
            } else {
                response.error_code = (int) message.status_code;
                response.error = (string) stream.get_data ();
            }
        } catch (Error e) {
            response.error_code = e.code;
            response.error = e.message;
            debug (e.message);
        }

        return response;
    }

    public async HttpResponse delete_tasklist (Objects.Project project) {
        var url = "%s/calendars/%s/%s/".printf (project.source.caldav_data.server_url, project.source.caldav_data.username, project.id);

        var message = new Soup.Message ("DELETE", url);
        message.request_headers.append ("Authorization", "Basic %s".printf (project.source.caldav_data.credentials));

        HttpResponse response = new HttpResponse ();

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            if (message.get_status () == Soup.Status.NO_CONTENT) {
                response.status = true;
            } else {
                response.error_code = (int) message.status_code;
                response.error = (string) stream.get_data ();
            }
        } catch (Error e) {
            response.error_code = e.code;
            response.error = e.message;
            debug (e.message);
        }

        return response;
    }

    private async void update_tasklist_detail (Objects.Project project) {
        var url = "%s/calendars/%s/%s/".printf (project.source.caldav_data.server_url, project.source.caldav_data.username, project.id);

        var message = new Soup.Message ("PROPFIND", url);
        message.request_headers.append ("Authorization", "Basic %s".printf (project.source.caldav_data.credentials));
        message.set_request_body_from_bytes ("application/xml", new Bytes ((Services.CalDAV.Providers.Nextcloud.TASKS_REQUEST_DETAIL).data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
            GXml.DomHTMLCollection response_collection = doc.get_elements_by_tag_name ("d:response");

            if (response_collection.length > 0) {
                GXml.DomElement d_response = response_collection.get_element (0);
                GXml.DomElement d_prop = d_response.get_elements_by_tag_name ("d:prop").get_element (0);

                GXml.DomHTMLCollection displayname_elements = d_prop.get_elements_by_tag_name ("d:displayname");
                if (displayname_elements.length > 0) {
                    project.name = displayname_elements.get_element (0).text_content;
                }

                GXml.DomHTMLCollection color_elements = d_prop.get_elements_by_tag_name ("x1:calendar-color");
                if (color_elements.length > 0) {
                    project.color = color_elements.get_element (0).text_content;
                }

                Services.Store.instance ().update_project (project);
            }
        } catch (Error e) {
            debug (e.message);
        }
    }

    public async void update_sync_token (Objects.Project project) {
        var url = "%s/calendars/%s/%s/".printf (project.source.caldav_data.server_url, project.source.caldav_data.username, project.id);

        var message = new Soup.Message ("PROPFIND", url);
        message.request_headers.append ("Authorization", "Basic %s".printf (project.source.caldav_data.credentials));
        message.set_request_body_from_bytes ("application/xml", new Bytes ((Services.CalDAV.Providers.Nextcloud.GET_SYNC_TOKEN_REQUEST).data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
            GXml.DomHTMLCollection sync_token_collection = doc.get_elements_by_tag_name ("d:sync-token");

            if (sync_token_collection.length > 0) {
                project.sync_id = sync_token_collection.get_element (0).text_content;
                project.update_local ();
            }
        } catch (Error e) {
            debug (e.message);
        }
    }

    /*
     * Task
     */

    public async HttpResponse add_task (Objects.Item item, bool update = false) {
        var ics = update ? item.ics : "%s.ics".printf (item.id);

        var url = "%s/calendars/%s/%s/%s".printf (item.project.source.caldav_data.server_url, item.project.source.caldav_data.username, item.project.id, ics);

        var message = new Soup.Message ("PUT", url);
        message.request_headers.append ("Authorization", "Basic %s".printf (item.project.source.caldav_data.credentials));
        message.set_request_body_from_bytes ("application/xml", new Bytes (item.to_vtodo ().data));

        HttpResponse response = new HttpResponse ();

        try {
            yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            if (update ? message.get_status () == Soup.Status.NO_CONTENT : message.get_status () == Soup.Status.CREATED) {
                response.status = true;
                item.extra_data = Util.generate_extra_data (ics, "", item.to_vtodo ());
            }
        } catch (Error e) {
            debug (e.message);
        }

        return response;
    }

    public async HttpResponse delete_task (Objects.Item item) {
        var url = "%s/calendars/%s/%s/%s".printf (item.project.source.caldav_data.server_url, item.project.source.caldav_data.username, item.project.id, item.ics);

        var message = new Soup.Message ("DELETE", url);
        message.request_headers.append ("Authorization", "Basic %s".printf (item.project.source.caldav_data.credentials));

        HttpResponse response = new HttpResponse ();

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            if (message.get_status () == Soup.Status.NO_CONTENT) {
                response.status = true;
            } else {
                response.error_code = (int) message.status_code;
                response.error = (string) stream.get_data ();
            }
        } catch (Error e) {
            response.error_code = e.code;
            response.error = e.message;
        }

        return response;
    }

    public async HttpResponse complete_item (Objects.Item item) {
        var ics = item.ics;
        var body = item.to_vtodo ();

        var url = "%s/calendars/%s/%s/%s".printf (item.project.source.caldav_data.server_url, item.project.source.caldav_data.username, item.project.id, ics);

        var message = new Soup.Message ("PUT", url);
        message.request_headers.append ("Authorization", "Basic %s".printf (item.project.source.caldav_data.credentials));
        message.set_request_body_from_bytes ("application/xml", new Bytes (body.data));

        HttpResponse response = new HttpResponse ();

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            if (message.get_status () == Soup.Status.NO_CONTENT) {
                response.status = true;
                item.extra_data = Util.generate_extra_data (ics, "", body);
            } else {
                response.error_code = (int) message.status_code;
                response.error = (string) stream.get_data ();
            }
        } catch (Error e) {
            debug (e.message);
        }

        return response;
    }

    public async HttpResponse move_task (Objects.Item item, string project_id) {
        string username = item.project.source.caldav_data.username;

        var url = "%s/calendars/%s/%s/%s".printf (item.project.source.caldav_data.server_url, username, item.project.id, item.ics);
        var destination = "%s/calendars/%s/%s/%s".printf (item.project.source.caldav_data.server_url, username, project_id, item.ics);

        var message = new Soup.Message ("MOVE", url);
        message.request_headers.append ("Authorization", "Basic %s".printf (item.project.source.caldav_data.credentials));
        message.request_headers.append ("Destination", destination);

        HttpResponse response = new HttpResponse ();

        try {
            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            if (message.get_status () == Soup.Status.CREATED || message.get_status () == Soup.Status.NO_CONTENT) {
                response.status = true;
            } else {
                response.error_code = (int) message.status_code;
                response.error = (string) stream.get_data ();
            }
        } catch (Error e) {
            debug (e.message);
            response.error = e.message;
        }

        return response;
    }

    /*
     *  Utils
     */

    public bool is_logged_in () {
        var server_url = Services.Settings.get_default ().settings.get_string ("caldav-server-url");
        var username = Services.Settings.get_default ().settings.get_string ("caldav-username");
        return server_url != "" && username != "";
    }

    public bool is_vtodo_calendar (GXml.DomElement element) {
        GXml.DomElement propstat = element.get_elements_by_tag_name ("d:propstat").get_element (0);
        GXml.DomElement prop = propstat.get_elements_by_tag_name ("d:prop").get_element (0);
        GXml.DomElement resourcetype = prop.get_elements_by_tag_name ("d:resourcetype").get_element (0);

        bool is_calendar = resourcetype.get_elements_by_tag_name ("cal:calendar").length > 0;
        bool is_vtodo = false;

        if (is_calendar) {
            GXml.DomElement supported_calendar = prop.get_elements_by_tag_name ("cal:supported-calendar-component-set").get_element (0);
            GXml.DomHTMLCollection calendar_comps = supported_calendar.get_elements_by_tag_name ("cal:comp");
            foreach (GXml.DomElement calendar_comp in calendar_comps) {
                if (calendar_comp.get_attribute ("name") == "VTODO") {
                    is_vtodo = true;
                }
            }
        }

        return is_vtodo;
    }

    public bool is_deleted_calendar (GXml.DomElement element) {
        GXml.DomElement propstat = element.get_elements_by_tag_name ("d:propstat").get_element (0);
        GXml.DomElement prop = propstat.get_elements_by_tag_name ("d:prop").get_element (0);
        GXml.DomElement resourcetype = prop.get_elements_by_tag_name ("d:resourcetype").get_element (0);
        return resourcetype.get_elements_by_tag_name ("x2:deleted-calendar").length > 0;
    }
}
