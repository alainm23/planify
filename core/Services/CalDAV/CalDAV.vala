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

public class Services.CalDAV : GLib.Object {
	private Soup.Session session;
	private Json.Parser parser;

	private static CalDAV? _instance;
	public static CalDAV get_default () {
		if (_instance == null) {
			_instance = new CalDAV ();
		}

		return _instance;
	}

    public signal void first_sync_started ();
	public signal void first_sync_finished ();

    public signal void sync_started ();
	public signal void sync_finished ();

    public signal void log_out ();
	public signal void log_in ();

    public static string USER_PRINCIPAL_REQUEST = """
        <d:propfind xmlns:d="DAV:">
            <d:prop>
                <d:current-user-principal />
            </d:prop>
        </d:propfind>
    """;

    public static string USER_DATA_REQUEST = """
        <x0:propfind xmlns:x0="DAV:">
            <x0:prop>
                <x0:displayname/>
                <x2:email-address xmlns:x2="http://sabredav.org/ns"/>
            </x0:prop>
        </x0:propfind>
    """;

    public static string TASKLIST_REQUEST = """
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

	public CalDAV () {
		session = new Soup.Session ();
		parser = new Json.Parser ();
	}

    public async HttpResponse login (string server_url, string username, string password) {
        var url = "%s/remote.php/dav/".printf (server_url);
        string credentials = "%s:%s".printf(username, password);
        string base64_credentials = Base64.encode(credentials.data);

        var message = new Soup.Message ("PROPFIND", url);
		message.request_headers.append ("Authorization", "Basic %s".printf (base64_credentials));
        message.set_request_body_from_bytes ("application/xml", new Bytes (USER_PRINCIPAL_REQUEST.data));
        
        HttpResponse response = new HttpResponse ();

        try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            if (message.status_code == 207) {
                Services.Settings.get_default ().settings.set_string ("caldav-server-url", server_url);
                Services.Settings.get_default ().settings.set_string ("caldav-username", username);
                Services.Settings.get_default ().settings.set_string ("caldav-credential", base64_credentials);                
                response.status = true;
            } else {
                debug ((string) stream.get_data ());
                GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
                response.from_error_xml (doc, (int) message.status_code);
            }
        } catch (Error e) {
			debug (e.message);
		}

        return response;
    }

    public async void first_sync () {
        var server_url = Services.Settings.get_default ().settings.get_string ("caldav-server-url");
        var username = Services.Settings.get_default ().settings.get_string ("caldav-username");
        var credential = Services.Settings.get_default ().settings.get_string ("caldav-credential");

        var url = "%s/remote.php/dav/principals/users/%s/".printf (server_url, username);
        var message = new Soup.Message ("PROPFIND", url);
		message.request_headers.append ("Authorization", "Basic %s".printf (credential));
        message.set_request_body_from_bytes ("application/xml", new Bytes (USER_DATA_REQUEST.data));

        first_sync_started ();

        try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            
            GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
            GXml.DomElement d_displayname = doc.get_elements_by_tag_name ("d:displayname").get_element (0);
            GXml.DomElement d_email = doc.get_elements_by_tag_name ("s:email-address").get_element (0);

            Services.Settings.get_default ().settings.set_string ("caldav-user-email", d_displayname.text_content);
            Services.Settings.get_default ().settings.set_string ("caldav-user-displayname", d_email.text_content);

            yield get_all_tasklist ();
        } catch (Error e) {
			debug (e.message);
		}
    }

    public async void get_all_tasklist () {
        var server_url = Services.Settings.get_default ().settings.get_string ("caldav-server-url");
        var username = Services.Settings.get_default ().settings.get_string ("caldav-username");
        var credential = Services.Settings.get_default ().settings.get_string ("caldav-credential");

        var url = "%s/remote.php/dav/calendars/%s/".printf (server_url, username);
        var message = new Soup.Message ("PROPFIND", url);
		message.request_headers.append ("Authorization", "Basic %s".printf (credential));
        message.set_request_body_from_bytes ("application/xml", new Bytes (TASKLIST_REQUEST.data));

        try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            debug ((string) stream.get_data ());

            GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
            GXml.DomHTMLCollection response = doc.get_elements_by_tag_name ("d:response");
            foreach (GXml.DomElement element in response) {
                if (is_calendar (element)) {
                    Services.Database.get_default ().insert_project (new Objects.Project.from_caldav_xml (element));
                }
            }

            first_sync_finished ();
            log_in ();
        } catch (Error e) {
			debug (e.message);
		}
    }

    public void sync_async () {
        sync_started ();
        sync.begin ((obj, res) => {
			sync.end (res);
		});
	}

    private async void sync () {
        var server_url = Services.Settings.get_default ().settings.get_string ("caldav-server-url");
        var username = Services.Settings.get_default ().settings.get_string ("caldav-username");
        var credential = Services.Settings.get_default ().settings.get_string ("caldav-credential");

        var url = "%s/remote.php/dav/calendars/%s/".printf (server_url, username);
        var message = new Soup.Message ("PROPFIND", url);
		message.request_headers.append ("Authorization", "Basic %s".printf (credential));
        message.set_request_body_from_bytes ("application/xml", new Bytes (TASKLIST_REQUEST.data));

        try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            // debug ((string) stream.get_data ());

            GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
            GXml.DomHTMLCollection response = doc.get_elements_by_tag_name ("d:response");
            foreach (GXml.DomElement element in response) {
                if (is_calendar (element)) {
                    Objects.Project? project = Services.Database.get_default ().get_project (get_id_from_url (element));
                    if (project != null) {
                        project.update_from_xml (element);
                        Services.Database.get_default ().update_project (project);
                    } else {
                        Services.Database.get_default ().insert_project (new Objects.Project.from_caldav_xml (element));
                    }
                } else if (is_deleted_calendar (element)) {
                    Objects.Project? project = Services.Database.get_default ().get_project (get_id_from_url (element));
                    if (project != null) {
                        Services.Database.get_default ().delete_project (project);
                    }
                }
            }

            sync_finished ();
        } catch (Error e) {
			debug (e.message);
		}
    }

    public string get_id_from_url (GXml.DomElement element) {
        GXml.DomElement href = element.get_elements_by_tag_name ("d:href").get_element (0);
        string[] parts = href.text_content.split ("/");
        return parts[parts.length - 2];
    }

    /*
     * Tasklist
     */

    public async bool add_tasklist (Objects.Project project) {
        var server_url = Services.Settings.get_default ().settings.get_string ("caldav-server-url");
        var username = Services.Settings.get_default ().settings.get_string ("caldav-username");
        var credential = Services.Settings.get_default ().settings.get_string ("caldav-credential");

        var url = "%s/remote.php/dav/calendars/%s/%s/".printf (server_url, username, project.id);
        var message = new Soup.Message ("MKCOL", url);
		message.request_headers.append ("Authorization", "Basic %s".printf (credential));
        message.set_request_body_from_bytes ("application/xml", new Bytes ((CREATE_TASKLIST_REQUEST.printf (project.name, project.color_hex)).data));

        bool status = false;

        try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            status = true;
        } catch (Error e) {
			debug (e.message);
		}

        return status;
    }

    public async bool update_tasklist (Objects.Project project) {
        var server_url = Services.Settings.get_default ().settings.get_string ("caldav-server-url");
        var username = Services.Settings.get_default ().settings.get_string ("caldav-username");
        var credential = Services.Settings.get_default ().settings.get_string ("caldav-credential");

        var url = "%s/remote.php/dav/calendars/%s/%s/".printf (server_url, username, project.id);
        var message = new Soup.Message ("PROPPATCH", url);
		message.request_headers.append ("Authorization", "Basic %s".printf (credential));
        message.set_request_body_from_bytes ("application/xml", new Bytes ((UPDATE_TASKLIST_REQUEST.printf (project.name, project.color_hex)).data));

        bool status = false;

        try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            status = true;
        } catch (Error e) {
			debug (e.message);
		}

        return status;
    }

    public async bool delete_tasklist (Objects.Project project) {
        var server_url = Services.Settings.get_default ().settings.get_string ("caldav-server-url");
        var username = Services.Settings.get_default ().settings.get_string ("caldav-username");
        var credential = Services.Settings.get_default ().settings.get_string ("caldav-credential");

        var url = "%s/remote.php/dav/calendars/%s/%s/".printf (server_url, username, project.id);
        var message = new Soup.Message ("DELETE", url);
		message.request_headers.append ("Authorization", "Basic %s".printf (credential));

        bool status = false;

        try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            status = true;
        } catch (Error e) {
			debug (e.message);
		}

        return status;
    }

    /*
     *  Utils
     */
    
    public bool is_logged_in () {
        var server_url = Services.Settings.get_default ().settings.get_string ("caldav-server-url");
        var username = Services.Settings.get_default ().settings.get_string ("caldav-username");
        var credential = Services.Settings.get_default ().settings.get_string ("caldav-credential");
        return server_url != "" && username != "" && credential != "";
    }

    public bool is_calendar (GXml.DomElement element) {
        GXml.DomElement propstat = element.get_elements_by_tag_name ("d:propstat").get_element (0);
        GXml.DomElement prop = propstat.get_elements_by_tag_name ("d:prop").get_element (0);
        GXml.DomElement resourcetype = prop.get_elements_by_tag_name ("d:resourcetype").get_element (0);
        return resourcetype.get_elements_by_tag_name ("cal:calendar").length > 0;
    }

    public bool is_deleted_calendar (GXml.DomElement element) {
        GXml.DomElement propstat = element.get_elements_by_tag_name ("d:propstat").get_element (0);
        GXml.DomElement prop = propstat.get_elements_by_tag_name ("d:prop").get_element (0);
        GXml.DomElement resourcetype = prop.get_elements_by_tag_name ("d:resourcetype").get_element (0);
        return resourcetype.get_elements_by_tag_name ("x2:deleted-calendar").length > 0;
    }
}