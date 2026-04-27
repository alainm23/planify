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


public class Services.CalDAV.CalDAVClient : Services.CalDAV.WebDAVClient {

    public CalDAVClient (Soup.Session session, string base_url, string username, string password, bool ignore_ssl = false) {
        base (session, base_url, username, password, ignore_ssl);
    }


    public async string? get_principal_url (GLib.Cancellable cancellable) throws GLib.Error {
        Services.LogService.get_default ().info ("CalDAV", "Fetching principal URL");
        var xml = """<?xml version="1.0" encoding="utf-8"?>
                        <propfind xmlns="DAV:">
                            <prop>
                                <current-user-principal/>
                            </prop>
                        </propfind>
        """;

        var multi_status = yield propfind ("", xml, "0", cancellable);

        foreach (var response in multi_status.responses ()) {
            foreach (var propstat in response.propstats ()) {
                foreach (var principal in propstat.prop.get_elements_by_tag_name ("current-user-principal")) {
                    var href_elements = principal.get_elements_by_tag_name ("href");
                    foreach (var href in href_elements) {
                        string link = href.text_content.strip ();
                        return get_absolute_url (link);
                    }
                }
            }
        }

        return null;
    }

    public async string? get_calendar_home (string principal_url, GLib.Cancellable cancellable) throws GLib.Error {
        Services.LogService.get_default ().info ("CalDAV", "Fetching calendar home");
        var xml = """<?xml version="1.0" encoding="utf-8"?>
                        <propfind xmlns="DAV:" xmlns:cal="urn:ietf:params:xml:ns:caldav">
                            <prop>
                                <cal:calendar-home-set/>
                            </prop>
                        </propfind>
        """;


        var multi_status = yield propfind (principal_url, xml, "0", cancellable);

        foreach (var response in multi_status.responses ()) {
            foreach (var propstat in response.propstats ()) {
                foreach (var calendar_home in propstat.prop.get_elements_by_tag_name ("calendar-home-set")) {
                    var href_elements = calendar_home.get_elements_by_tag_name ("href");
                    foreach (var href in href_elements) {
                        string link = href.text_content.strip ();
                        return get_absolute_url (link);
                    }
                }
            }
        }
        return null;
    }


    public async void update_userdata (string principal_url, Objects.Source source, GLib.Cancellable cancellable) throws GLib.Error {
        Services.LogService.get_default ().info ("CalDAV", "Updating user data");
        var xml = """<?xml version="1.0" encoding="utf-8"?>
                    <d:propfind xmlns:d="DAV:" xmlns:s="http://sabredav.org/ns">
                        <d:prop>
                            <d:displayname/>
                            <s:email-address/>
                        </d:prop>
                    </d:propfind>
        """;

        var multi_status = yield propfind (principal_url, xml, "0", cancellable);

        foreach (var response in multi_status.responses ()) {
            foreach (var propstat in response.propstats ()) {
                var prop = propstat.prop;

                var names = prop.get_elements_by_tag_name ("displayname");
                if (names.size > 0) {
                    source.caldav_data.user_displayname = names[0].text_content.strip ();
                }

                var emails = prop.get_elements_by_tag_name ("email-address");
                if (emails.size > 0) {
                    source.caldav_data.user_email = emails[0].text_content.strip ();
                };
            }
        }

        if (source.caldav_data.user_email != null && source.caldav_data.user_email != "") {
            source.display_name = source.caldav_data.user_email;
            return;
        }

        if (source.caldav_data.user_displayname != null && source.caldav_data.user_displayname != "") {
            source.display_name = source.caldav_data.user_displayname;
            return;
        }

        source.display_name = _ ("CalDAV");
    }

    public async Gee.ArrayList<Objects.Project> fetch_project_list (Objects.Source source, GLib.Cancellable cancellable) throws GLib.Error {
        Services.LogService.get_default ().info ("CalDAV", "Fetching project list");
        var xml = """<?xml version='1.0' encoding='utf-8'?>
                    <d:propfind xmlns:d="DAV:" xmlns:ical="http://apple.com/ns/ical/" xmlns:cal="urn:ietf:params:xml:ns:caldav">
                        <d:prop>
                            <d:resourcetype />
                            <d:displayname />
                            <d:sync-token />
                            <ical:calendar-color />
                            <cal:supported-calendar-component-set />
                        </d:prop>
                    </d:propfind>
        """;


        var multi_status = yield propfind (source.caldav_data.calendar_home_url, xml, "1", cancellable);

        Gee.ArrayList<Objects.Project> projects = new Gee.ArrayList<Objects.Project> ();

        foreach (var response in multi_status.responses ()) {
            string? href = response.href;

            foreach (var propstat in response.propstats ()) {
                if (propstat.status != Soup.Status.OK) continue;

                var resourcetype = propstat.get_first_prop_with_tagname ("resourcetype");
                var supported_calendar = propstat.get_first_prop_with_tagname ("supported-calendar-component-set");

                if (is_vtodo_calendar (resourcetype, supported_calendar)) {
                    var project = new Objects.Project.from_propstat (propstat, get_absolute_url (href));
                    project.source_id = source.id;

                    projects.add (project);
                }
            }
        }

        return projects;
    }


    public async void sync (Objects.Source source, GLib.Cancellable cancellable) throws GLib.Error {
        Services.LogService.get_default ().info ("CalDAV", "Syncing project list");
        var xml = """<?xml version='1.0' encoding='utf-8'?>
                    <d:propfind xmlns:d="DAV:" xmlns:ical="http://apple.com/ns/ical/" xmlns:cal="urn:ietf:params:xml:ns:caldav" xmlns:nc="http://nextcloud.com/ns">
                        <d:prop>
                            <d:resourcetype />
                            <d:displayname />
                            <d:sync-token />
                            <ical:calendar-color />
                            <cal:supported-calendar-component-set />
                            <nc:deleted-at/>
                        </d:prop>
                    </d:propfind>
        """;

        var multi_status = yield propfind (source.caldav_data.calendar_home_url, xml, "1", cancellable);


        // Delete CalDAV Generic
        var server_urls = new Gee.HashSet<string> ();
        foreach (var response in multi_status.responses ()) {
            if (response.href != null) {
                server_urls.add (get_absolute_url (response.href));
            }
        }

        var local_projects = Services.Store.instance ().get_projects_by_source (source.id);
        foreach (Objects.Project local_project in local_projects) {
            if (!server_urls.contains (local_project.calendar_url)) {
                Services.Store.instance ().delete_project (local_project);
            }
        }

        foreach (var response in multi_status.responses ()) {
            string? href = response.href;

            foreach (var propstat in response.propstats ()) {
                if (propstat.status != Soup.Status.OK) {
                    continue;
                }

                var resourcetype = propstat.get_first_prop_with_tagname ("resourcetype");
                var supported_calendar = propstat.get_first_prop_with_tagname ("supported-calendar-component-set");

                if (is_deleted_calendar (resourcetype)) {
                    Services.LogService.get_default ().info ("CalDAV", "Removing deleted calendar from server");
                    Objects.Project ? project = Services.Store.instance ().get_project_via_url (get_absolute_url (href));
                    if (project != null) {
                        Services.Store.instance ().delete_project (project);
                    }

                    continue;
                }

                if (is_vtodo_calendar (resourcetype, supported_calendar)) {
                    var name = propstat.get_first_prop_with_tagname ("displayname");

                    if (href != null && name != null) {
                        Objects.Project ? project = Services.Store.instance ().get_project_via_url (get_absolute_url (href));

                        if (project == null) {
                            Services.LogService.get_default ().info ("CalDAV", "Discovered new project, fetching items");
                            project = new Objects.Project.from_propstat (propstat, get_absolute_url (href));
                            project.source_id = source.id;

                            Services.Store.instance ().insert_project (project);
                            yield fetch_items_for_project (project, cancellable);
                        } else {
                            project.update_from_propstat (propstat, false);
                            Services.Store.instance ().update_project (project);
                        }
                    }
                }
            }
        }
    }

    public async void fetch_project_details (Objects.Project project, GLib.Cancellable cancellable) throws GLib.Error {
        Services.LogService.get_default ().debug ("CalDAV", "Fetching project details");
        var xml = """<?xml version='1.0' encoding='utf-8'?>
                    <d:propfind xmlns:d="DAV:" xmlns:ical="http://apple.com/ns/ical/" xmlns:cal="urn:ietf:params:xml:ns:caldav">
                        <d:prop>
                            <d:resourcetype />
                            <d:displayname />
                            <d:sync-token />
                            <ical:calendar-color />
                            <cal:supported-calendar-component-set />
                        </d:prop>
                    </d:propfind>
        """;

        var multi_status = yield propfind (project.calendar_url, xml, "1", cancellable);

        foreach (var response in multi_status.responses ()) {

            foreach (var propstat in response.propstats ()) {
                if (propstat.status != Soup.Status.OK) {
                    continue;
                }

                var resourcetype = propstat.get_first_prop_with_tagname ("resourcetype");
                var supported_calendar = propstat.get_first_prop_with_tagname ("supported-calendar-component-set");
            
                if (is_vtodo_calendar (resourcetype, supported_calendar)) {
                    project.update_from_propstat (propstat, false);
                    Services.Store.instance ().update_project (project);
                    return;
                }
            }
        }
    }

    public delegate void ProgressCallback (int current, int total, string message);

    public async void fetch_items_for_project (Objects.Project project, GLib.Cancellable cancellable, owned ProgressCallback? progress_callback = null) throws GLib.Error {
        Services.LogService.get_default ().info ("CalDAV", "Fetching items for project");
        SourceFunc callback = fetch_items_for_project.callback;

        var xml = """<?xml version="1.0" encoding="utf-8"?>
        <cal:calendar-query xmlns:d="DAV:" xmlns:cal="urn:ietf:params:xml:ns:caldav">
            <d:prop>
                <d:getetag/>
                <d:displayname/>
                <d:owner/>
                <d:sync-token/>
                <d:current-user-privilege-set/>
                <d:getcontenttype/>
                <d:resourcetype/>
                <cal:calendar-data/>
            </d:prop>
            <cal:filter>
                <cal:comp-filter name="VCALENDAR">
                    <cal:comp-filter name="VTODO">
                    </cal:comp-filter>
                </cal:comp-filter>
            </cal:filter>
        </cal:calendar-query>
        """;
        
        var multi_status = yield report (project.calendar_url, xml, "1", cancellable);
        var responses = multi_status.responses ();
        
        if (progress_callback != null) {
            progress_callback (0, responses.size, _ ("Loading tasks for %s…").printf (project.name));
        }

        project.freeze_update = true;

        int index = 0;
        var items_list = new Gee.ArrayList<Objects.Item> ();

        Idle.add (() => {
            if (index >= responses.size) {
                if (progress_callback != null) {
                    progress_callback (responses.size, responses.size, _ ("Loaded tasks for %s…").printf (project.name));
                }
                // Two-pass insert: parents first, then subtasks
                var parents = new Gee.ArrayList<Objects.Item> ();
                var subtasks = new Gee.ArrayList<Objects.Item> ();
                foreach (var item in items_list) {
                    if (item.has_parent) {
                        subtasks.add (item);
                    } else {
                        parents.add (item);
                    }
                }
                project.add_items_batched (parents);
                project.add_items_batched (subtasks);
                Idle.add ((owned) callback);
                return false;
            }
            
            var response = responses[index];
            string? href = response.href;

            foreach (var propstat in response.propstats ()) {
                if (propstat.status != Soup.Status.OK) {
                    continue;
                }

                var calendar_data = propstat.get_first_prop_with_tagname ("calendar-data");
                if (calendar_data == null || calendar_data.text_content == null) {
                    continue;
                }

                var getetag = propstat.get_first_prop_with_tagname ("getetag");
                string etag = getetag != null ? getetag.text_content.strip () : "";

                var resource_url = get_absolute_url (href);
                upsert_vtodo_content (project, resource_url, etag, calendar_data.text_content, items_list);
            }

            if (progress_callback != null && index % 10 == 0) {
                progress_callback (index, responses.size, _ ("Syncing task %d of %d").printf (index, responses.size));
            }

            index++;

            if (index >= responses.size) {
                if (progress_callback != null) {
                    progress_callback (responses.size, responses.size, _ ("Loaded tasks for %s…").printf (project.name));
                }
                project.add_items_batched (items_list);
                Idle.add ((owned) callback);
                return false;
            }
            return true;
        });
        yield;

        project.freeze_update = false;
        project.count_update ();
        Services.Store.instance ().update_project (project);
    }

    public async void sync_tasklist (Objects.Project project, GLib.Cancellable cancellable) throws GLib.Error {
        if (project.is_deck || project.is_archived) {
            Services.LogService.get_default ().debug ("CalDAV", "Skipping sync for %s project".printf (project.is_archived ? "archived" : "deck"));
            return;
        }

        Services.LogService.get_default ().info ("CalDAV", "Syncing tasklist");

        var xml = """
        <?xml version='1.0' encoding='utf-8'?>
        <d:sync-collection xmlns:d="DAV:">
            <d:sync-token>%s</d:sync-token>
            <d:sync-level>1</d:sync-level>
            <d:prop>
                <d:getetag/>
                <d:getcontenttype/>
            </d:prop>
        </d:sync-collection>
        """.printf (project.sync_id);

        project.loading = true;
        project.sync_started ();

        yield fetch_project_details (project, cancellable);

        Services.LogService.get_default ().debug ("CalDAV", "sync_id after fetch_project_details: '%s'".printf (project.sync_id ?? "(null)"));

        if (project.sync_id == null || project.sync_id == "") {
            Services.LogService.get_default ().warn ("CalDAV", "No sync-token from server, falling back to etag-based sync for '%s'".printf (project.name));
            project.loading = false;
            project.freeze_update = false;
            yield etag_sync_project (project, cancellable);
            project.sync_finished ();
            return;
        }

        WebDAVMultiStatus multi_status;
        try {
            multi_status = yield report (project.calendar_url, xml, "1", cancellable);
        } catch (Error e) {
            if (e is GLib.IOError.CANCELLED) {
                throw e;
            }
            // sync-collection fails with a 412 Precondition Failed on Vikunja (but it sends a sync-token?)

            Services.LogService.get_default ().warn ("CalDAV", "sync-collection failed, falling back to ETag sync: %s".printf (e.message));
            project.loading = false;
            project.freeze_update = false;
            yield etag_sync_project (project, cancellable);
            project.sync_finished ();
            return;
        }
        project.freeze_update = true;

        foreach (WebDAVResponse response in multi_status.responses ()) {
            string? href = response.href;
            var url = get_absolute_url (href);

            if (response.status == Soup.Status.NOT_FOUND) {
                Objects.Item ? item = Services.Store.instance ().get_item_by_ical_url (url);
                if (item != null) {
                    Services.Store.instance ().delete_item (item);
                }

                continue;
            }

            foreach (WebDAVPropStat propstat in response.propstats ()) {
                if (propstat.status == Soup.Status.NOT_FOUND) {
                    Objects.Item ? item = Services.Store.instance ().get_item_by_ical_url (url);
                    if (item != null) {
                        Services.Store.instance ().delete_item (item);
                    }
                } else {
                    bool is_vtodo = false;

                    var getcontenttype = propstat.get_first_prop_with_tagname ("getcontenttype");
                    if (getcontenttype != null) {
                        if (getcontenttype.text_content.down ().index_of ("vtodo") > -1) {
                            is_vtodo = true;
                        }
                    }

                    if (is_vtodo) {
                        var getetag = propstat.get_first_prop_with_tagname ("getetag");
                        string etag = getetag != null ? getetag.text_content.strip () : "";

                        string vtodo_content = yield get_vtodo_by_url (url, cancellable);
                        upsert_vtodo_content (project, url, etag, vtodo_content);
                    }
                }
            }
        }

        var sync_token = multi_status.get_first_text_content_by_tag_name ("sync-token");
        if (sync_token != null && sync_token != project.sync_id) {
            project.sync_id = sync_token;
            project.update_local ();
        } else if (sync_token == null) {
            // Some CalDAV providers do not support sync-token. Keep token empty
            // so subsequent syncs always take the ETag fallback path.
            project.sync_id = "";
            project.update_local ();
        }

        project.loading = false;
        project.freeze_update = false;
        project.count_update ();
        Services.Store.instance ().update_project (project);
    }


    /**
    * Adds or updates items in a project based on VTODO content from a CalDAV server.
    *
    * If @batched_items is provided, all new items are added to this list instead of
    * being added directly to the project.
    *
    */
    private void upsert_vtodo_content (Objects.Project project, string url, string etag, string vtodo_content, Gee.ArrayList<Objects.Item>? batched_items = null) {
        ICal.Component vcalendar = new ICal.Component.from_string (vtodo_content);
        ICal.Component vtodo_comp = vcalendar.get_first_component (ICal.ComponentKind.VTODO_COMPONENT);
        while (vtodo_comp != null) {
            string uid = vtodo_comp.get_uid ();
            if (uid != null && uid != "") {
                Objects.Item ? item = Services.Store.instance ().get_item (uid);

                if (item != null) {
                    string old_project_id = item.project_id;
                    string old_parent_id = item.parent_id;
                    bool old_checked = item.checked;

                    item.update_from_vtodo (vtodo_content, url);
                    item.extra_data = Util.generate_extra_data (url, etag, vtodo_content);
                    item.project_id = project.id;
                    Services.Store.instance ().update_item (item);

                    if (old_project_id != item.project_id || old_parent_id != item.parent_id) {
                        Services.EventBus.get_default ().item_moved (item, old_project_id, "", old_parent_id);
                    }

                    if (old_checked != item.checked) {
                        Services.Store.instance ().complete_item (item, old_checked);
                    }
                } else {
                    var new_item = new Objects.Item.from_vtodo (vtodo_content, url, project.id);
                    new_item.extra_data = Util.generate_extra_data (url, etag, vtodo_content);

                    if (batched_items != null) {
                        batched_items.add (new_item);
                    } else {
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
            vtodo_comp = vcalendar.get_next_component (ICal.ComponentKind.VTODO_COMPONENT);
        }
    }


    private async void etag_sync_project (Objects.Project project, GLib.Cancellable cancellable) throws GLib.Error {
        Services.LogService.get_default ().info ("CalDAV", "ETag sync for '%s'".printf (project.name));

        // Step 1: fetch {url → etag} from server (lightweight, no calendar-data)
        var xml = """<?xml version="1.0" encoding="utf-8"?>
        <cal:calendar-query xmlns:d="DAV:" xmlns:cal="urn:ietf:params:xml:ns:caldav">
            <d:prop>
                <d:getetag/>
            </d:prop>
            <cal:filter>
                <cal:comp-filter name="VCALENDAR">
                    <cal:comp-filter name="VTODO"/>
                </cal:comp-filter>
            </cal:filter>
        </cal:calendar-query>
        """;

        var multi_status = yield report (project.calendar_url, xml, "1", cancellable);

        // Build server map: url → etag
        var server_map = new Gee.HashMap<string, string> ();
        foreach (var response in multi_status.responses ()) {
            if (response.href == null) continue;
            string url = get_absolute_url (response.href);
            foreach (var propstat in response.propstats ()) {
                if (propstat.status != Soup.Status.OK) continue;
                var getetag = propstat.get_first_prop_with_tagname ("getetag");
                server_map[url] = getetag != null ? getetag.text_content.strip () : "";
            }
        }

        Services.LogService.get_default ().debug ("CalDAV", "Project has %d items".printf (server_map.size));
        project.freeze_update = true;

        
        try {
            // Step 2: delete local items no longer on server
            var stale_items = new Gee.ArrayList<Objects.Item> ();
            foreach (var local_item in Services.Store.instance ().get_items_by_project (project)) {
                if (!server_map.has_key (local_item.ical_url)) {
                    stale_items.add (local_item);
                }
            }

            foreach (var stale_item in stale_items) {
                Services.LogService.get_default ().debug ("CalDAV", "Deleting stale item: %s".printf (stale_item.content));
                Services.Store.instance ().delete_item (stale_item);
            }
            // Step 3: fetch and update only changed/new items
            foreach (var entry in server_map.entries) {
                string url = entry.key;
                string server_etag = entry.value;

                Objects.Item? local_item = Services.Store.instance ().get_item_by_ical_url (url);
                if (local_item != null && server_etag != "" && local_item.etag == server_etag) {
                    // ETag matches, skip
                    continue;
                }

                string vtodo_content = yield get_vtodo_by_url (url, cancellable);
                upsert_vtodo_content (project, url, server_etag, vtodo_content);
            }
        } finally {
            project.freeze_update = false;
            project.count_update ();
            Services.Store.instance ().update_project (project);
        }
    }

    private async string? get_vtodo_by_url (string url, GLib.Cancellable cancellable) throws GLib.Error {
        return yield send_request ("GET", url, "", null, null, cancellable, { Soup.Status.OK });
    }

    public async void update_sync_token (Objects.Project project, GLib.Cancellable cancellable) throws GLib.Error {
        Services.LogService.get_default ().debug ("CalDAV", "Updating sync token");
        var xml = """<?xml version="1.0" encoding="utf-8"?>
        <d:propfind xmlns:d="DAV:">
            <d:prop>
                <d:sync-token/>
            </d:prop>
        </d:propfind>
        """;

        var multi_status = yield propfind (project.calendar_url, xml, "1", cancellable);

        foreach (var response in multi_status.responses ()) {
            foreach (var propstat in response.propstats ()) {
                if (propstat.status != Soup.Status.OK) continue;

                var sync_token = propstat.get_first_prop_with_tagname ("sync-token");
                if (sync_token != null) {
                    project.sync_id = sync_token.text_content;
                    project.update_local ();
                }
            }
        }
    }

    public async HttpResponse create_project (Objects.Project project) {
        Services.LogService.get_default ().info ("CalDAV", "Creating project");
        var xml = """<?xml version="1.0" encoding="utf-8"?>
            <d:mkcol xmlns:d="DAV:" xmlns:ical="http://apple.com/ns/ical/" xmlns:oc="http://owncloud.org/ns" xmlns:cal="urn:ietf:params:xml:ns:caldav">
            <d:set>
                <d:prop>
                    <d:resourcetype>
                        <d:collection/>
                        <cal:calendar/>
                    </d:resourcetype>
                    <d:displayname>%s</d:displayname>
                    <ical:calendar-color>%s</ical:calendar-color>
                    <oc:calendar-enabled>1</oc:calendar-enabled>
                    <cal:supported-calendar-component-set >
                        <cal:comp name="VTODO"/>
                    </cal:supported-calendar-component-set>
                </d:prop>
            </d:set>
        </d:mkcol>
        """.printf (project.name, project.color_hex);

        var calendar_url = GLib.Uri.resolve_relative (project.source.caldav_data.calendar_home_url, project.id, GLib.UriFlags.NONE);
        if (!calendar_url.has_suffix ("/")) {
            calendar_url += "/";
        }

        HttpResponse response = new HttpResponse ();

        try {
            yield send_request ("MKCOL", calendar_url, "application/xml", xml, null, null,
                                { Soup.Status.CREATED, Soup.Status.OK });
            project.calendar_url = calendar_url;
            response.status = true;
        } catch (Error e) {
            if ("HTTP 403" in e.message) {
                Services.LogService.get_default ().warn ("CalDAV", "Server does not allow creating calendars via CalDAV");
                response.error_code = 403;
                response.error = _("This server does not allow creating projects via CalDAV. Please create it directly from your calendar provider's website.");
            } else {
                Services.LogService.get_default ().error ("CalDAV", "Failed to create project: %s".printf (e.message));
                response.error_code = e.code;
                response.error = e.message;
            }
        }

        return response;
    }

    public async HttpResponse update_project (Objects.Project project) {
        Services.LogService.get_default ().info ("CalDAV", "Updating project");
        var xml = """<?xml version="1.0" encoding="utf-8"?>
        <d:propertyupdate xmlns:d="DAV:" xmlns:ical="http://apple.com/ns/ical/">
            <d:set>
                <d:prop>
                    <d:displayname>%s</d:displayname>
                    <ical:calendar-color>%s</ical:calendar-color>
                </d:prop>
            </d:set>
        </d:propertyupdate>
        """.printf (project.name, project.color_hex);

        HttpResponse response = new HttpResponse ();

        try {
            yield send_request ("PROPPATCH", project.calendar_url, "application/xml", xml, null, null,
                                    { Soup.Status.MULTI_STATUS });

            response.status = true;
        } catch (Error e) {
            Services.LogService.get_default ().error ("CalDAV", "Failed to update project: %s".printf (e.message));
            response.error_code = e.code;
            response.error = e.message;
        }

        return response;
    }

    public async HttpResponse delete_project (Objects.Project project) {
        Services.LogService.get_default ().info ("CalDAV", "Deleting project");
        HttpResponse response = new HttpResponse ();

        try {
            yield send_request ("DELETE", project.calendar_url, "text/calendar", null, null, null,
                                { Soup.Status.NO_CONTENT, Soup.Status.MULTI_STATUS, Soup.Status.OK });
            response.status = true;
        } catch (Error e) {
            if ("HTTP 403" in e.message) {
                Services.LogService.get_default ().warn ("CalDAV", "Server does not allow deleting calendars via CalDAV");
                response.error_code = 403;
                response.error = _("This server does not allow deleting projects via CalDAV. Please delete it directly from your calendar provider's website.");
            } else if ("HTTP 405" in e.message) {
                Services.LogService.get_default ().warn ("CalDAV", "Server does not support project deletion via CalDAV");
                response.error_code = 405;
                response.error = _("This server does not support deleting projects via CalDAV. Please delete it from the server directly.");
            } else {
                Services.LogService.get_default ().error ("CalDAV", "Failed to delete project: %s".printf (e.message));
                response.error_code = e.code;
                response.error = e.message;
            }
        }

        return response;
    }

    public async HttpResponse add_item (Objects.Item item, bool update = false) {
        Services.LogService.get_default ().info ("CalDAV", update ? "Updating item" : "Adding item");
        var url = update ? item.ical_url : GLib.Path.build_path ("/", item.project.calendar_url, "%s.ics".printf (item.id));
        var body = item.to_vtodo ();

        var expected = update ? new Soup.Status[]{ Soup.Status.NO_CONTENT, Soup.Status.CREATED, Soup.Status.OK }
                              : new Soup.Status[]{ Soup.Status.CREATED, Soup.Status.OK };

        HttpResponse response = new HttpResponse ();

        try {
            HashTable<string, string>? headers = null;
            if (update && item.etag != null && item.etag != "") {
                headers = new HashTable<string, string> (str_hash, str_equal);
                headers.insert ("If-Match", item.etag);
            }
            yield send_request ("PUT", url, "text/calendar", body, null, null, expected, headers);
            item.extra_data = Util.generate_extra_data (url, last_response_etag ?? "", body);
            response.status = true;
        } catch (Error e) {
            if ("HTTP 412" in e.message) {
                Services.LogService.get_default ().warn ("CalDAV", "Conflict detected (412), re-fetching item");
                response.error_code = 412;
                response.error = _("Task was modified on another device. Please sync to get the latest version.");
            } else {
                Services.LogService.get_default ().error ("CalDAV", "Failed to %s item: %s".printf (update ? "update" : "add", e.message));
                response.error_code = e.code;
                response.error = e.message;
            }
        }

        return response;
    }

    public async HttpResponse complete_item (Objects.Item item) {
        Services.LogService.get_default ().info ("CalDAV", "Completing item");
        var body = item.to_vtodo ();

        HttpResponse response = new HttpResponse ();

        try {
            HashTable<string, string>? headers = null;
            if (item.etag != null && item.etag != "") {
                headers = new HashTable<string, string> (str_hash, str_equal);
                headers.insert ("If-Match", item.etag);
            }
            yield send_request ("PUT", item.ical_url, "text/calendar", body, null, null, { Soup.Status.NO_CONTENT, Soup.Status.CREATED }, headers);
            item.extra_data = Util.generate_extra_data (item.ical_url, last_response_etag ?? "", body);
            response.status = true;
        } catch (Error e) {
            if ("HTTP 412" in e.message) {
                Services.LogService.get_default ().warn ("CalDAV", "Conflict on complete (412), re-fetching ETag and retrying");
                try {
                    var retry_cancellable = new GLib.Cancellable ();
                    string vtodo_content = yield get_vtodo_by_url (item.ical_url, retry_cancellable);
                    // Extract fresh ETag via HEAD or from last GET response
                    string fresh_etag = last_response_etag ?? "";
                    item.extra_data = Util.generate_extra_data (item.ical_url, fresh_etag, vtodo_content);

                    HashTable<string, string>? retry_headers = null;
                    if (fresh_etag != "") {
                        retry_headers = new HashTable<string, string> (str_hash, str_equal);
                        retry_headers.insert ("If-Match", fresh_etag);
                    }
                    yield send_request ("PUT", item.ical_url, "text/calendar", body, null, null, { Soup.Status.NO_CONTENT, Soup.Status.CREATED }, retry_headers);
                    item.extra_data = Util.generate_extra_data (item.ical_url, last_response_etag ?? "", body);
                    response.status = true;
                } catch (Error retry_error) {
                    Services.LogService.get_default ().error ("CalDAV", "Retry complete failed: %s".printf (retry_error.message));
                    response.error_code = 412;
                    response.error = _("Task was modified on another device. Please sync to get the latest version.");
                }
            } else {
                Services.LogService.get_default ().error ("CalDAV", "Failed to complete item: %s".printf (e.message));
                response.error_code = e.code;
                response.error = e.message;
            }
        }

        return response;
    }


    public async HttpResponse move_item (Objects.Item item, Objects.Project destination_project) {
        Services.LogService.get_default ().info ("CalDAV", "Moving item to another project");
        var destination = GLib.Path.build_path ("/", destination_project.calendar_url, "%s.ics".printf (item.id));

        var headers = new HashTable<string,string> (str_hash, str_equal);
        headers.insert ("Destination", destination);

        HttpResponse response = new HttpResponse ();

        try {
            yield send_request ("MOVE", item.ical_url, "", null, null, null, { Soup.Status.NO_CONTENT, Soup.Status.CREATED }, headers);
            item.extra_data = Util.generate_extra_data (destination, "", item.calendar_data);
            response.status = true;
        } catch (Error e) {
            if ("HTTP 502" in e.message || "HTTP 405" in e.message || "HTTP 501" in e.message) {
                Services.LogService.get_default ().warn ("CalDAV", "MOVE not supported, falling back to PUT+DELETE");
                response = yield move_item_fallback (item, destination_project, destination);
            } else {
                Services.LogService.get_default ().error ("CalDAV", "Failed to move item: %s".printf (e.message));
                response.error_code = e.code;
                response.error = e.message;
            }
        }

        return response;
    }

    private async HttpResponse move_item_fallback (Objects.Item item, Objects.Project destination_project, string destination) {
        HttpResponse response = new HttpResponse ();
        var body = item.to_vtodo ();

        try {
            yield send_request ("PUT", destination, "text/calendar", body, null, null, { Soup.Status.CREATED, Soup.Status.NO_CONTENT });
            item.extra_data = Util.generate_extra_data (destination, last_response_etag ?? "", body);

            yield send_request ("DELETE", item.ical_url, "", null, null, null, { Soup.Status.NO_CONTENT, Soup.Status.OK });

            response.status = true;
        } catch (Error e) {
            Services.LogService.get_default ().error ("CalDAV", "Failed to move item (fallback): %s".printf (e.message));
            response.error_code = e.code;
            response.error = e.message;
        }

        return response;
    }


    public async HttpResponse delete_item (Objects.Item item) {
        Services.LogService.get_default ().info ("CalDAV", "Deleting item");
        HttpResponse response = new HttpResponse ();

        try {
            yield send_request ("DELETE", item.ical_url, "", null, null, null, { Soup.Status.NO_CONTENT, Soup.Status.OK });

            response.status = true;
        } catch (Error e) {
            Services.LogService.get_default ().error ("CalDAV", "Failed to delete item: %s".printf (e.message));
            response.error_code = e.code;
            response.error = e.message;
        }


        return response;
    }



    private bool is_vtodo_calendar (GXml.DomElement? resourcetype, GXml.DomElement? supported_calendar) {
        if (resourcetype == null) {
            return false;
        }

        bool is_calendar = resourcetype.get_elements_by_tag_name ("calendar").length > 0;
        if (!is_calendar) {
            return false;
        }

        if (supported_calendar != null) {
            var calendar_comps = supported_calendar.get_elements_by_tag_name ("comp");
            foreach (GXml.DomElement calendar_comp in calendar_comps) {
                if (calendar_comp.get_attribute ("name") == "VTODO") {
                    return true;
                }
            }
        }

        return false;
    }

    public bool is_deleted_calendar (GXml.DomElement? resourcetype) {
        if (resourcetype == null) {
            return false;
        }

        return resourcetype.get_elements_by_tag_name ("deleted-calendar").length > 0;
    }
}
