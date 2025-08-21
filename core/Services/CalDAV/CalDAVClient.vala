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

    public CalDAVClient (Soup.Session session, string base_url, string base64_credentials) {
        base (session, base_url, base64_credentials);
    }

    public CalDAVClient.with_credentials (Soup.Session session, string base_url, string username, string password) {
        this (session, base_url, Base64.encode ("%s:%s".printf (username, password).data));
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
                    <x0:propfind xmlns:x0="DAV:" xmlns:x1="http://sabredav.org/ns">
                        <x0:prop>
                            <x0:displayname/>
                            <x1:email-address/>
                        </x0:prop>
                    </x0:propfind>
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

    public async Gee.ArrayList<Objects.Project> fetch_project_list (string calendar_home_path, Objects.Source source, GLib.Cancellable cancellable) throws GLib.Error {
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


        var multi_status = yield propfind (calendar_home_path, xml, "1", cancellable);

        Gee.ArrayList<Objects.Project> projects = new Gee.ArrayList<Objects.Project> ();

        foreach (var response in multi_status.responses ()) {
            string? href = response.href;

            foreach (var propstat in response.propstats ()) {
                if (propstat.status != Soup.Status.OK) continue;

                var resourcetype = propstat.get_first_prop_with_tagname ("resourcetype");

                if (resourcetype == null) continue;

                bool is_calendar = resourcetype.get_elements_by_tag_name ("calendar").length > 0;
                bool is_vtodo = false;

                if (is_calendar) {
                    var supported_calendar = propstat.get_first_prop_with_tagname ("supported-calendar-component-set");
                    if (supported_calendar != null) {
                        var calendar_comps = supported_calendar.get_elements_by_tag_name ("comp");
                        foreach (GXml.DomElement calendar_comp in calendar_comps) {
                            if (calendar_comp.get_attribute ("name") == "VTODO") {
                                is_vtodo = true;
                            }
                        }
                    }
                }

                if (is_vtodo) {
                    var resource_id = propstat.get_first_prop_with_tagname ("resource-id");
                    var name = propstat.get_first_prop_with_tagname ("displayname");
                    var color = propstat.get_first_prop_with_tagname ("calendar-color");
                    var sync_id = propstat.get_first_prop_with_tagname ("sync-token");

                    if (href != null && name != null) {
                        print ("Found VTODO Calendar %s (%s)\n", name.text_content.strip (), get_absolute_url (href));

                        var project = new Objects.Project ();
                        project.id = Util.get_default ().generate_id (project); // THIS ID is INTERNAL and no longer used for requests
                        project.calendar_url = get_absolute_url (href);
                        project.name = name.text_content;
                        project.color = color.text_content;
                        project.sync_id = sync_id.text_content;
                        project.source_id = source.id;
                        projects.add (project);
                    }
                }
            }
        }

        return projects;
    }


    public async void update_tasks_for_project (Objects.Project project, GLib.Cancellable cancellable) {
        var xml = """<?xml version="1.0" encoding="utf-8"?>
        <x1:calendar-query xmlns:x0="DAV:" xmlns:x1="urn:ietf:params:xml:ns:caldav">
            <x0:prop>
                <x0:getetag/>
                <x0:displayname/>
                <x0:owner/>
                <x0:sync-token/>
                <x0:current-user-privilege-set/>
                <x0:getcontenttype/>
                <x0:resourcetype/>
                <x1:calendar-data/>
            </x0:prop>
            <x1:filter>
                <x1:comp-filter name="VCALENDAR">
                    <x1:comp-filter name="VTODO">
                    </x1:comp-filter>
                </x1:comp-filter>
            </x1:filter>
        </x1:calendar-query>
        """;

        var multi_status = yield caldav_client.propfind (project.calendar_url, xml, 1, cancellable);

        foreach (var response in multi_status.responses ()) {
            string? href = response.href;

            foreach (var propstat in response.propstats ()) {
                if (propstat.status != Soup.Status.OK) continue;


            }
        }
    }

}
