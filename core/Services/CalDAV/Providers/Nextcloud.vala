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

public class Services.CalDAV.Providers.Nextcloud : Services.CalDAV.Providers.Base {    
    // vala-lint=naming-convention
    public static string GET_SYNC_TOKEN_REQUEST = """
        <x0:propfind xmlns:x0="DAV:">
            <x0:prop>
                <x0:sync-token/>
            </x0:prop>
        </x0:propfind>
    """;

    // vala-lint=naming-convention
    public static string CREATE_TASKLIST_REQUEST = """
        <x0:mkcol xmlns:x0="DAV:">
            <x0:set>
                <x0:prop>
                    <x0:resourcetype>
                        <x0:collection/>
                        <x1:calendar xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                    </x0:resourcetype>0
                    <x0:displayname>%s</x0:displayname>
                    <x6:calendar-color xmlns:x6="http://apple.com/ns/ical/">%s</x6:calendar-color>
                    <x4:calendar-enabled xmlns:x4="http://owncloud.org/ns">1</x4:calendar-enabled>
                    <x1:supported-calendar-component-set xmlns:x1="urn:ietf:params:xml:ns:caldav">
                        <x1:comp name="VTODO"/>
                    </x1:supported-calendar-component-set>
                </x0:prop>
            </x0:set>
        </x0:mkcol>
    """; 
    
    // vala-lint=naming-convention
    public static string UPDATE_TASKLIST_REQUEST = """
        <x0:propertyupdate xmlns:x0="DAV:">
            <x0:set>
                <x0:prop>
                    <x0:displayname>%s</x0:displayname>
                    <x6:calendar-color xmlns:x6="http://apple.com/ns/ical/">%s</x6:calendar-color>
                </x0:prop>
            </x0:set>
        </x0:propertyupdate>
    """; 

    // vala-lint=naming-convention
    public static string SYNC_TOKEN_REQUEST = """
        <d:sync-collection xmlns:d="DAV:">
            <d:sync-token>%s</d:sync-token>
            <d:sync-level>1</d:sync-level>
            <d:prop>
                <d:getetag/>
                <d:getcontenttype/>
            </d:prop>
        </d:sync-collection>
    """; 
    
    // vala-lint=naming-convention
    public static string TASKS_REQUEST = """
        <x1:calendar-query xmlns:x1="urn:ietf:params:xml:ns:caldav">
            <x0:prop xmlns:x0="DAV:">
                <x0:getcontenttype/>
                <x0:getetag/>
                <x0:resourcetype/>
                <x0:displayname/>
                <x0:owner/>
                <x0:resourcetype/>
                <x0:sync-token/>
                <x0:current-user-privilege-set/>
                <x0:getcontenttype/>
                <x0:getetag/>
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

    // vala-lint=naming-convention
    public static string TASKS_REQUEST_DETAIL = """
        <x0:propfind xmlns:x0="DAV:">
            <x0:prop>
                <x0:resourcetype/>
                <x0:displayname/>
                <x0:sync-token/>
            </x0:prop>
        </x0:propfind>
    """;

    public Nextcloud () {
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
            <x0:propfind xmlns:x0="DAV:">
            <x0:prop>
                <x0:getcontenttype/>
                <x0:getetag/>
                <x0:resourcetype/>
                <x0:displayname/>
                <x0:owner/>
                <x0:resourcetype/>
                <x0:sync-token/>
                <x0:current-user-privilege-set/>
                <x0:displayname/>
                <x0:owner/>
                <x0:resourcetype/>
                <x0:sync-token/>
                <x0:current-user-privilege-set/>
                <x4:invite xmlns:x4="http://owncloud.org/ns"/>
                <x5:allowed-sharing-modes xmlns:x5="http://calendarserver.org/ns/"/>
                <x5:publish-url xmlns:x5="http://calendarserver.org/ns/"/>
                <x6:calendar-order xmlns:x6="http://apple.com/ns/ical/"/>
                <x6:calendar-color xmlns:x6="http://apple.com/ns/ical/"/>
                <x5:getctag xmlns:x5="http://calendarserver.org/ns/"/>
                <x1:calendar-description xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:calendar-timezone xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:supported-calendar-component-set xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:supported-calendar-data xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:max-resource-size xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:min-date-time xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:max-date-time xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:max-instances xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:max-attendees-per-instance xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:supported-collation-set xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:calendar-free-busy-set xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:schedule-calendar-transp xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:schedule-default-calendar-URL xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x4:calendar-enabled xmlns:x4="http://owncloud.org/ns"/>
                <x3:owner-displayname xmlns:x3="http://nextcloud.com/ns"/>
                <x3:trash-bin-retention-duration xmlns:x3="http://nextcloud.com/ns"/>
                <x3:deleted-at xmlns:x3="http://nextcloud.com/ns"/>
                <x0:displayname/>
                <x0:owner/>
                <x0:resourcetype/>
                <x0:sync-token/>
                <x0:current-user-privilege-set/>
                <x4:invite xmlns:x4="http://owncloud.org/ns"/>
                <x5:allowed-sharing-modes xmlns:x5="http://calendarserver.org/ns/"/>
                <x5:publish-url xmlns:x5="http://calendarserver.org/ns/"/>
                <x6:calendar-order xmlns:x6="http://apple.com/ns/ical/"/>
                <x6:calendar-color xmlns:x6="http://apple.com/ns/ical/"/>
                <x5:getctag xmlns:x5="http://calendarserver.org/ns/"/>
                <x1:calendar-description xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:calendar-timezone xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:supported-calendar-component-set xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:supported-calendar-data xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:max-resource-size xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:min-date-time xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:max-date-time xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:max-instances xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:max-attendees-per-instance xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:supported-collation-set xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:calendar-free-busy-set xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:schedule-calendar-transp xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:schedule-default-calendar-URL xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x4:calendar-enabled xmlns:x4="http://owncloud.org/ns"/>
                <x3:owner-displayname xmlns:x3="http://nextcloud.com/ns"/>
                <x3:trash-bin-retention-duration xmlns:x3="http://nextcloud.com/ns"/>
                <x3:deleted-at xmlns:x3="http://nextcloud.com/ns"/>
                <x0:displayname/>
                <x0:owner/>
                <x0:resourcetype/>
                <x0:sync-token/>
                <x0:current-user-privilege-set/>
                <x4:invite xmlns:x4="http://owncloud.org/ns"/>
                <x5:allowed-sharing-modes xmlns:x5="http://calendarserver.org/ns/"/>
                <x5:publish-url xmlns:x5="http://calendarserver.org/ns/"/>
                <x6:calendar-order xmlns:x6="http://apple.com/ns/ical/"/>
                <x6:calendar-color xmlns:x6="http://apple.com/ns/ical/"/>
                <x5:getctag xmlns:x5="http://calendarserver.org/ns/"/>
                <x1:calendar-description xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:calendar-timezone xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:supported-calendar-component-set xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:supported-calendar-data xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:max-resource-size xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:min-date-time xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:max-date-time xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:max-instances xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:max-attendees-per-instance xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:supported-collation-set xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:calendar-free-busy-set xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:schedule-calendar-transp xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:schedule-default-calendar-URL xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x4:calendar-enabled xmlns:x4="http://owncloud.org/ns"/>
                <x3:owner-displayname xmlns:x3="http://nextcloud.com/ns"/>
                <x3:trash-bin-retention-duration xmlns:x3="http://nextcloud.com/ns"/>
                <x3:deleted-at xmlns:x3="http://nextcloud.com/ns"/>
                <x5:source xmlns:x5="http://calendarserver.org/ns/"/>
                <x6:refreshrate xmlns:x6="http://apple.com/ns/ical/"/>
                <x5:subscribed-strip-todos xmlns:x5="http://calendarserver.org/ns/"/>
                <x5:subscribed-strip-alarms xmlns:x5="http://calendarserver.org/ns/"/>
                <x5:subscribed-strip-attachments xmlns:x5="http://calendarserver.org/ns/"/>
                <x0:displayname/>
                <x0:owner/>
                <x0:resourcetype/>
                <x0:sync-token/>
                <x0:current-user-privilege-set/>
                <x4:invite xmlns:x4="http://owncloud.org/ns"/>
                <x5:allowed-sharing-modes xmlns:x5="http://calendarserver.org/ns/"/>
                <x5:publish-url xmlns:x5="http://calendarserver.org/ns/"/>
                <x6:calendar-order xmlns:x6="http://apple.com/ns/ical/"/>
                <x6:calendar-color xmlns:x6="http://apple.com/ns/ical/"/>
                <x5:getctag xmlns:x5="http://calendarserver.org/ns/"/>
                <x1:calendar-description xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:calendar-timezone xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:supported-calendar-component-set xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:supported-calendar-data xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:max-resource-size xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:min-date-time xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:max-date-time xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:max-instances xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:max-attendees-per-instance xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:supported-collation-set xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:calendar-free-busy-set xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:schedule-calendar-transp xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x1:schedule-default-calendar-URL xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x4:calendar-enabled xmlns:x4="http://owncloud.org/ns"/>
                <x3:owner-displayname xmlns:x3="http://nextcloud.com/ns"/>
                <x3:trash-bin-retention-duration xmlns:x3="http://nextcloud.com/ns"/>
                <x3:deleted-at xmlns:x3="http://nextcloud.com/ns"/>
                <x1:calendar-availability xmlns:x1="urn:ietf:params:xml:ns:caldav"/>
                <x0:displayname/>
                <x0:owner/>
                <x0:resourcetype/>
                <x0:sync-token/>
                <x0:current-user-privilege-set/>
                <x0:displayname/>
                <x0:owner/>
                <x0:resourcetype/>
                <x0:sync-token/>
                <x0:current-user-privilege-set/>
            </x0:prop>
        </x0:propfind>
        """;
    }

    public override string get_server_url (string url, string username, string password) {
        string server_url = "";

        try {
            var _uri = GLib.Uri.parse (url, GLib.UriFlags.NONE);
            server_url = "%s://%s".printf (_uri.get_scheme (), _uri.get_host ());
            if (_uri.get_port () > 0) {
                server_url = "%s://%s:%d".printf (_uri.get_scheme (), _uri.get_host (), _uri.get_port ());
            }
            
            server_url += _uri.get_path ();
        } catch (Error e) {
            debug (e.message);
        }

        return "%s/remote.php/dav".printf (server_url);
    }

    public override string get_account_url (string server_url, string username) {
        return "%s/principals/users/%s/".printf (server_url, username);
    }

    public override void set_user_data (GXml.DomDocument doc, Objects.Source source) {
        if (doc.get_elements_by_tag_name ("d:displayname").length > 0) {
            source.caldav_data.user_displayname = doc.get_elements_by_tag_name ("d:displayname").get_element (0).text_content;
        }
        
        if (doc.get_elements_by_tag_name ("s:email-address").length > 0) {
            source.caldav_data.user_email = doc.get_elements_by_tag_name ("s:email-address").get_element (0).text_content;
        }
        
        if (source.caldav_data.user_email != null && source.caldav_data.user_email != "") {
            source.display_name = source.caldav_data.user_email;
            return;
        }
        
        if (source.caldav_data.user_displayname != null && source.caldav_data.user_displayname != "") {
            source.display_name = source.caldav_data.user_displayname;
            return;
        }
        
        source.display_name = _("Nextcloud");
    }

    public override string get_all_taskslist_url (string server_url, string username) {
        return "%s/calendars/%s/".printf (server_url, username);;
    }

    public override Gee.ArrayList<Objects.Project> get_projects_by_doc (GXml.DomDocument doc, Objects.Source source) {
        Gee.ArrayList<Objects.Project> return_value = new Gee.ArrayList<Objects.Project> ();

        GXml.DomHTMLCollection response = doc.get_elements_by_tag_name ("d:response");
        foreach (GXml.DomElement element in response) {
            if (is_vtodo_calendar (element)) {
                var project = new Objects.Project ();
                project.id = get_id_from_url (element);
                project.name = get_prop_value (element, "d:displayname");
                project.color = get_prop_value (element, "x1:calendar-color");
                project.sync_id = get_prop_value (element, "d:sync-token");
                project.source_id = source.id;
                return_value.add (project);
            }
        }

        return return_value;
    }

    public string get_id_from_url (GXml.DomElement element) {
        if (element.get_elements_by_tag_name ("d:href").length <= 0) {
            return "";
        }

        GXml.DomElement href = element.get_elements_by_tag_name ("d:href").get_element (0);

        string[] parts = href.text_content.split ("/");
        return parts[parts.length - 2];
    }

    public string get_prop_value (GXml.DomElement element, string key) {
        if (element.get_elements_by_tag_name ("d:propstat").length <= 0) {
            return "";
        }

        GXml.DomElement propstat = element.get_elements_by_tag_name ("d:propstat").get_element (0);

        if (propstat.get_elements_by_tag_name ("d:prop").length <= 0) {
            return "";
        }

        GXml.DomElement prop = propstat.get_elements_by_tag_name ("d:prop").get_element (0);

        if (prop.get_elements_by_tag_name (key).length <= 0) {
            return "";
        }

        return prop.get_elements_by_tag_name (key).get_element (0).text_content;
    }

    public override bool is_vtodo_calendar (GXml.DomElement element) {
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
}
