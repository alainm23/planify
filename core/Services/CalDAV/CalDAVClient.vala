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
                    print ("Found VTODO Calendar (%s)\n", get_absolute_url (href));

                    var project = new Objects.Project.from_propstat (propstat, get_absolute_url (href));
                    project.source_id = source.id;

                    projects.add (project);
                }
            }
        }

        return projects;
    }


    public async void sync (Objects.Source source, GLib.Cancellable cancellable) throws GLib.Error {
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

        // TODO: Implement check for deleted calendars

        foreach (var response in multi_status.responses ()) {
            string? href = response.href;

            foreach (var propstat in response.propstats ()) {
                if (propstat.status != Soup.Status.OK) continue;

                var resourcetype = propstat.get_first_prop_with_tagname ("resourcetype");
                var supported_calendar = propstat.get_first_prop_with_tagname ("supported-calendar-component-set");

                if (is_vtodo_calendar (resourcetype, supported_calendar)) {
                    var name = propstat.get_first_prop_with_tagname ("displayname");

                    if (href != null && name != null) {
                        Objects.Project ? project = Services.Store.instance ().get_project_via_url (get_absolute_url (href));

                        if (project == null) {
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
                if (propstat.status != Soup.Status.OK) continue;

                project.update_from_propstat (propstat, false);
                Services.Store.instance ().update_project (project);
            }
        }
    }

    public async void fetch_items_for_project (Objects.Project project, GLib.Cancellable cancellable) throws GLib.Error {
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

        foreach (var response in multi_status.responses ()) {
            string? href = response.href;

            foreach (var propstat in response.propstats ()) {
                if (propstat.status != Soup.Status.OK) continue;

                var calendar_data = propstat.get_first_prop_with_tagname ("calendar-data");
                string? parent_id = Util.find_string_value ("RELATED-TO", calendar_data.text_content);

                Objects.Item item = new Objects.Item.from_vtodo (calendar_data.text_content, get_absolute_url (href), project.id);

                if (parent_id != null && parent_id != "") {
                    Objects.Item ? parent_item = Services.Store.instance ().get_item (parent_id);
                    if (parent_item != null) {
                        parent_item.add_item_if_not_exists (item);
                    } else {
                        project.add_item_if_not_exists (item);
                    }
                } else {
                    project.add_item_if_not_exists (item);
                }
            }
        }
    }


    public async void sync_tasklist (Objects.Project project, GLib.Cancellable cancellable) throws GLib.Error {
        var xml = """
        <d:sync-collection xmlns:d="DAV:">
            <d:sync-token>%s</d:sync-token>
            <d:sync-level>1</d:sync-level>
            <d:prop>
                <d:getetag/>
                <d:getcontenttype/>
            </d:prop>
        </d:sync-collection>
        """.printf (project.sync_id);


        if (project.is_deck) {
            return;
        }

        project.loading = true;

        yield fetch_project_details (project, cancellable);

        if (project.sync_id == "") {
            project.loading = false;
            return;
        }

        var multi_status = yield report (project.calendar_url, xml, "1", cancellable);

        foreach (var response in multi_status.responses ()) {
            string? href = response.href;

            foreach (var propstat in response.propstats ()) {
                if (propstat.status == Soup.Status.NOT_FOUND) {
                    Objects.Item ? item = Services.Store.instance ().get_item_by_ical_url (get_absolute_url (href));
                    if (item != null) {
                        Services.Store.instance ().delete_item (item);
                    }
                }else {
                    bool is_vtodo = false;

                    var getcontenttype = propstat.get_first_prop_with_tagname ("getcontenttype");
                    if (getcontenttype != null) {
                        if (getcontenttype.text_content.index_of ("vtodo") > -1) {
                            is_vtodo = true;
                        }
                    }

                    if (is_vtodo) {
                        string vtodo = yield get_vtodo_by_url (project, get_absolute_url (href), cancellable);

                        ICal.Component ical = new ICal.Component.from_string (vtodo);
                        Objects.Item ? item = Services.Store.instance ().get_item (ical.get_uid ());

                        if (item != null) {
                            string old_project_id = item.project_id;
                            string old_parent_id = item.parent_id;
                            bool old_checked = item.checked;

                            item.update_from_vtodo (vtodo, get_absolute_url (href));
                            item.project_id = project.id;
                            Services.Store.instance ().update_item (item);

                            if (old_project_id != item.project_id || old_parent_id != item.parent_id) {
                                Services.EventBus.get_default ().item_moved (item, old_project_id, "", old_parent_id);
                            }

                            if (old_checked != item.checked) {
                                Services.Store.instance ().complete_item (item, old_checked);
                            }
                        } else {
                            var new_item = new Objects.Item.from_vtodo (vtodo, get_absolute_url (href), project.id);
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
            }
        }

        var sync_token = multi_status.get_first_text_content_by_tag_name ("sync-token");
        if (sync_token != null && sync_token != project.sync_id) {
            project.sync_id = sync_token;
            project.update_local ();
        }

        project.loading = false;
    }


    private async string? get_vtodo_by_url (Objects.Project project, string url, GLib.Cancellable cancellable) throws GLib.Error {
        return yield send_request ("GET", url, "", null, null, cancellable,
                                   { Soup.Status.OK });
    }

    public async void update_sync_token (Objects.Project project, GLib.Cancellable cancellable) throws GLib.Error {
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

        var url = "%s/%s".printf (project.source.caldav_data.calendar_home_url, project.id);

        HttpResponse response = new HttpResponse ();

        try {
            yield send_request ("MKCOL", url, "application/xml", xml, null, null,
                                { Soup.Status.CREATED });

            response.status = true;
        } catch (Error e) {
            response.error_code = e.code;
            response.error = e.message;
        }

        return response;
    }

    public async HttpResponse update_project (Objects.Project project) {
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
            response.error_code = e.code;
            response.error = e.message;
        }

        return response;
    }

    public async HttpResponse delete_project (Objects.Project project) {
        HttpResponse response = new HttpResponse ();

        try {
            yield send_request ("DELETE", project.calendar_url, "text/calendar", null, null, null,
                                { Soup.Status.NO_CONTENT });
            response.status = true;
        } catch (Error e) {
            response.error_code = e.code;
            response.error = e.message;
        }

        return response;
    }

    public async HttpResponse add_item (Objects.Item item, bool update = false) {
        var url = update ? item.ical_url : "%s/%s".printf (item.project.calendar_url, "%s.ics".printf (item.id));
        var body = item.to_vtodo ();

        var expected = update ? new Soup.Status[]{ Soup.Status.NO_CONTENT }
                              : new Soup.Status[]{ Soup.Status.CREATED };


        HttpResponse response = new HttpResponse ();

        try {
            yield send_request ("PUT", url, "text/calendar", body, null, null, expected);
            item.extra_data = Util.generate_extra_data (url, "", body);

            response.status = true;
        } catch (Error e) {
            response.error_code = e.code;
            response.error = e.message;
        }

        return response;
    }

    public async HttpResponse complete_item (Objects.Item item) {
        var body = item.to_vtodo ();

        HttpResponse response = new HttpResponse ();

        try {
            yield send_request ("PUT", item.ical_url, "", body, null, null, { Soup.Status.NO_CONTENT });
            item.extra_data = Util.generate_extra_data (item.ical_url, "", body);

            response.status = true;
        } catch (Error e) {
            response.error_code = e.code;
            response.error = e.message;
        }

        return response;
    }


    public async HttpResponse move_item (Objects.Item item, Objects.Project destination_project) {
        var destination = "%s/%s".printf (destination_project.calendar_url, "%s.ics".printf (item.id));

        var headers = new HashTable<string,string> (str_hash, str_equal);
        headers.insert ("Destination", destination);

        HttpResponse response = new HttpResponse ();


        try {
            yield send_request ("MOVE", item.ical_url, "", null, null, null, {Soup.Status.NO_CONTENT, Soup.Status.CREATED }, headers);

            item.extra_data = Util.generate_extra_data (destination, "", item.calendar_data);

            response.status = true;
        } catch (Error e) {
            response.error_code = e.code;
            response.error = e.message;
        }

        return response;
    }


    public async HttpResponse delete_item (Objects.Item item) {
        HttpResponse response = new HttpResponse ();

        try {
            yield send_request ("DELETE", item.ical_url, "", null, null, null, { Soup.Status.NO_CONTENT, Soup.Status.OK });

            response.status = true;
        } catch (Error e) {
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
}
