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

public class Services.CalDAV.Providers.Radicale : Services.CalDAV.Providers.Base {
    public Radicale () {
        LOGIN_REQUEST = """
            <d:propfind xmlns:d="DAV:">
                <d:prop>
                    <d:current-user-principal />
                </d:prop>
            </d:propfind>
        """;

        USER_DATA_REQUEST = """
            <x0:propfind xmlns:x0="DAV:">
                <x0:prop>
                    <x0:displayname/>
                    <x2:email-address xmlns:x2="http://sabredav.org/ns"/>
                </x0:prop>
            </x0:propfind>
        """;

        TASKLIST_REQUEST = """
            <?xml version="1.0" encoding="utf-8" ?>
            <propfind
                xmlns="DAV:"
                xmlns:C="urn:ietf:params:xml:ns:caldav"
                xmlns:CR="urn:ietf:params:xml:ns:carddav"
                xmlns:CS="http://calendarserver.org/ns/"
                xmlns:I="http://apple.com/ns/ical/"
                xmlns:INF="http://inf-it.com/ns/ab/"
                xmlns:RADICALE="http://radicale.org/ns/">
                <prop>
                    <resourcetype />
                    <RADICALE:displayname />
                    <I:calendar-color />
                    <INF:addressbook-color />
                    <C:calendar-description />
                    <C:supported-calendar-component-set />
                    <CR:addressbook-description />
                    <CS:source />
                    <sync-token />
                    <RADICALE:getcontentcount />
                    <getcontentlength />
                </prop>
            </propfind>
        """;
    }

    public override string get_server_url (string url, string username, string password) {
        int server_port = 80;
        string server_url = "";
        string scheme = "";

        try {
            var _uri = GLib.Uri.parse (url, GLib.UriFlags.NONE);
            server_port = _uri.get_port ();
            server_url = _uri.get_host ();
            scheme = _uri.get_scheme ();
        } catch (Error e) {
            debug (e.message);
        }

        return "%s://%s:%s@%s:%i".printf (scheme, username, Uri.escape_string (password), server_url, server_port);
    }

    public override string get_account_url (string server_url, string username) {
        return "%s/%s/".printf (server_url, username);
    }

    public override void set_user_data (GXml.DomDocument doc, Objects.Source source) {
        source.caldav_data.user_displayname = source.caldav_data.username;
        source.caldav_data.user_email = "";
    }

    public override string get_all_taskslist_url (string server_url, string username) {
        return "%s/%s/".printf (server_url, username);
    }

    public override Gee.ArrayList<Objects.Project> get_projects_by_doc (GXml.DomDocument doc, Objects.Source source) {
        Gee.ArrayList<Objects.Project> return_value = new Gee.ArrayList<Objects.Project> ();

        GXml.DomHTMLCollection response = doc.get_elements_by_tag_name ("response");
        foreach (GXml.DomElement element in response) {
            if (is_vtodo_calendar (element)) {
                var project = new Objects.Project ();
                project.id = get_id_from_url (element);
                project.name = get_prop_value (element, "RADICALE:displayname");
                project.color = get_prop_value (element, "ICAL:calendar-color");
                project.sync_id = get_prop_value (element, "sync-token");

                return_value.add (project);
            }
        }

        return return_value;
    }

    public string get_id_from_url (GXml.DomElement element) {
        if (element.get_elements_by_tag_name ("href").length <= 0) {
            return "";
        }

        GXml.DomElement href = element.get_elements_by_tag_name ("href").get_element (0);

        string[] parts = href.text_content.split ("/");
        return parts[parts.length - 2];
    }

    public string get_prop_value (GXml.DomElement element, string key) {
        if (element.get_elements_by_tag_name ("propstat").length <= 0) {
            return "";
        }

        GXml.DomElement propstat = element.get_elements_by_tag_name ("propstat").get_element (0);

        if (propstat.get_elements_by_tag_name ("prop").length <= 0) {
            return "";
        }

        GXml.DomElement prop = propstat.get_elements_by_tag_name ("prop").get_element (0);

        if (prop.get_elements_by_tag_name (key).length <= 0) {
            return "";
        }

        return prop.get_elements_by_tag_name (key).get_element (0).text_content;
    }

    public override bool is_vtodo_calendar (GXml.DomElement element) {
        if (element.get_elements_by_tag_name ("propstat").length <= 0) {
            return false;
        }

        GXml.DomElement propstat = element.get_elements_by_tag_name ("propstat").get_element (0);

        if (propstat.get_elements_by_tag_name ("prop").length <= 0) {
            return false;
        }

        GXml.DomElement prop = propstat.get_elements_by_tag_name ("prop").get_element (0);

        if (prop.get_elements_by_tag_name ("resourcetype").length <= 0) {
            return false;
        }

        GXml.DomElement resourcetype = prop.get_elements_by_tag_name ("resourcetype").get_element (0);

        bool is_calendar = resourcetype.get_elements_by_tag_name ("C:calendar").length > 0;
        bool is_vtodo = false;

        if (is_calendar) {
            if (prop.get_elements_by_tag_name ("C:supported-calendar-component-set").length <= 0) {
                return false;
            }

            GXml.DomElement supported_calendar = prop.get_elements_by_tag_name ("C:supported-calendar-component-set").get_element (0);
            GXml.DomHTMLCollection calendar_comps = supported_calendar.get_elements_by_tag_name ("C:comp");
            foreach (GXml.DomElement calendar_comp in calendar_comps) {
                if (calendar_comp.get_attribute ("name") == "VTODO") {
                    is_vtodo = true;
                }
            }
        }

        return is_vtodo;
    }
}
