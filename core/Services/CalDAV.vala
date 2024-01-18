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
                        <x1:prop-filter name="completed">
                            <x1:is-not-defined/>
                        </x1:prop-filter>
                    </x1:comp-filter>
                </x1:comp-filter>
            </x1:filter>
        </x1:calendar-query>
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
                response.error_code = (int) message.status_code;
                response.error = (string) stream.get_data ();
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

            Services.Settings.get_default ().settings.set_string ("caldav-user-displayname", d_displayname.text_content);
            Services.Settings.get_default ().settings.set_string ("caldav-user-email", d_email.text_content);

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

            GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
            GXml.DomHTMLCollection response = doc.get_elements_by_tag_name ("d:response");
            foreach (GXml.DomElement element in response) {
                if (is_calendar (element)) {
                    var project = new Objects.Project.from_caldav_xml (element);
                    Services.Database.get_default ().insert_project (project);
                    yield get_all_tasks_by_tasklist (project);
                }
            }

            first_sync_finished ();
            log_in ();
        } catch (Error e) {
			debug (e.message);
		}
    }

    public async void get_all_tasks_by_tasklist (Objects.Project project) {
        var server_url = Services.Settings.get_default ().settings.get_string ("caldav-server-url");
        var username = Services.Settings.get_default ().settings.get_string ("caldav-username");
        var credential = Services.Settings.get_default ().settings.get_string ("caldav-credential");

        var url = "%s/remote.php/dav/calendars/%s/%s/".printf (server_url, username, project.id);
        var message = new Soup.Message ("REPORT", url);
		message.request_headers.append ("Authorization", "Basic %s".printf (credential));
        message.request_headers.append ("Depth", "1");
        message.set_request_body_from_bytes ("application/xml", new Bytes (TASKS_REQUEST.data));

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

    public async void update_all_tasks_by_tasklist (Objects.Project project) {
        var server_url = Services.Settings.get_default ().settings.get_string ("caldav-server-url");
        var username = Services.Settings.get_default ().settings.get_string ("caldav-username");
        var credential = Services.Settings.get_default ().settings.get_string ("caldav-credential");

        var url = "%s/remote.php/dav/calendars/%s/%s/".printf (server_url, username, project.id);
        var message = new Soup.Message ("REPORT", url);
		message.request_headers.append ("Authorization", "Basic %s".printf (credential));
        message.request_headers.append ("Depth", "1");
        message.set_request_body_from_bytes ("application/xml", new Bytes (TASKS_REQUEST.data));

        try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            
            GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
            GXml.DomHTMLCollection response = doc.get_elements_by_tag_name ("d:response");
            foreach (GXml.DomElement element in response) {
                Objects.Item? item = Services.Database.get_default ().get_item (
                    Util.get_default ().get_task_uid (element)
                );

                if (item != null) {
                    string old_project_id = item.project_id;
				    string old_section_id = item.section_id;
                    string old_parent_id = item.parent_id;

                    item.update_from_caldav_xml (element);
                    Services.Database.get_default ().update_item (item);

                    if (old_parent_id != item.parent_id) {
                        Services.EventBus.get_default ().item_moved (item, old_project_id, old_section_id, old_parent_id);
                    }
                } else {
                    add_item_if_not_exists (element, project);
                }
            }
        } catch (Error e) {
			debug (e.message);
		}
    }

    private void add_item_if_not_exists (GXml.DomElement element, Objects.Project project) {
        string parent_id = Util.get_default ().get_related_to_uid (element);
        if (parent_id != "") {
            Objects.Item? parent_item = Services.Database.get_default ().get_item (parent_id);
            if (parent_item != null) {
                var item = new Objects.Item.from_caldav_xml (element);
                item.project_id = project.id;
                parent_item.add_item_if_not_exists (item);
            } else {
                var item = new Objects.Item.from_caldav_xml (element);
                item.project_id = project.id;
                project.add_item_if_not_exists (item);
            }
        } else {
            var item = new Objects.Item.from_caldav_xml (element);
            item.project_id = project.id;
            project.add_item_if_not_exists (item);
        }
	}

    public void sync_async () {
        sync.begin ((obj, res) => {
			sync.end (res);
		});
	}

    private async void sync () {
        sync_started ();

        var server_url = Services.Settings.get_default ().settings.get_string ("caldav-server-url");
        var username = Services.Settings.get_default ().settings.get_string ("caldav-username");
        var credential = Services.Settings.get_default ().settings.get_string ("caldav-credential");

        var url = "%s/remote.php/dav/calendars/%s/".printf (server_url, username);
        var message = new Soup.Message ("PROPFIND", url);
		message.request_headers.append ("Authorization", "Basic %s".printf (credential));
        message.set_request_body_from_bytes ("application/xml", new Bytes (TASKLIST_REQUEST.data));

        try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
            GXml.DomHTMLCollection response = doc.get_elements_by_tag_name ("d:response");
            foreach (GXml.DomElement element in response) {
                if (is_calendar (element)) {
                    Objects.Project? project = Services.Database.get_default ().get_project (get_id_from_url (element));
                    if (project == null) {
                        project = new Objects.Project.from_caldav_xml (element);
                        Services.Database.get_default ().insert_project (project);
                        yield get_all_tasks_by_tasklist (project);
                    } else {
                        project.update_from_xml (element);
                        Services.Database.get_default ().update_project (project);
                        yield update_all_tasks_by_tasklist (project);
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
			yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
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
			yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
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
			yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            status = true;
        } catch (Error e) {
			debug (e.message);
		}

        return status;
    }

    /*
     * Task
     */
    
     public async HttpResponse add_task (Objects.Item item, bool update = false) {
        var server_url = Services.Settings.get_default ().settings.get_string ("caldav-server-url");
        var username = Services.Settings.get_default ().settings.get_string ("caldav-username");
        var credential = Services.Settings.get_default ().settings.get_string ("caldav-credential");

        var ics = update ? item.ics : "%s.ics".printf (item.id);

        print ("%s\n".printf (item.to_vtodo (update)));

        var url = "%s/remote.php/dav/calendars/%s/%s/%s".printf (server_url, username, item.project.id, ics);
        print ("URL: %s\n".printf (url));
        var message = new Soup.Message ("PUT", url);
		message.request_headers.append ("Authorization", "Basic %s".printf (credential));
        message.set_request_body_from_bytes ("application/xml", new Bytes (item.to_vtodo (update).data));

        HttpResponse response = new HttpResponse ();

        try {
			yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            if (update ? message.status_code == 204 : message.status_code == 201) {
                response.status = true;
                item.extra_data = Util.get_default ().generate_extra_data (ics, "", item.to_vtodo (update));
            }
        } catch (Error e) {
			debug (e.message);
		}

        return response;
     }

     public async HttpResponse delete_task (Objects.Item item) {
        var server_url = Services.Settings.get_default ().settings.get_string ("caldav-server-url");
        var username = Services.Settings.get_default ().settings.get_string ("caldav-username");
        var credential = Services.Settings.get_default ().settings.get_string ("caldav-credential");

        var url = "%s/remote.php/dav/calendars/%s/%s/%s".printf (server_url, username, item.project.id, item.ics);
        print ("url: %s\n".printf (url));
        var message = new Soup.Message ("DELETE", url);
		message.request_headers.append ("Authorization", "Basic %s".printf (credential));

        HttpResponse response = new HttpResponse ();

        try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            if (message.status_code == 204) {
                response.status = true;
            } else {
                response.error_code = (int) message.status_code;
                response.error = (string) stream.get_data ();
                print ("Code: %d, Error: %s\n".printf (response.error_code, response.error));
            }
        } catch (Error e) {
			debug (e.message);
		}

        return response;
     }

     public void remove_items () {
		Services.Settings.get_default ().settings.set_string ("caldav-server-url", "");
		Services.Settings.get_default ().settings.set_string ("caldav-username", "");
		Services.Settings.get_default ().settings.set_string ("caldav-user-email", "");
		Services.Settings.get_default ().settings.set_string ("caldav-user-displayname", "");
		Services.Settings.get_default ().settings.set_string ("caldav-credential", "");

		// Delete all projects, sections and items
		foreach (var project in Services.Database.get_default ().get_all_projects_by_backend_type (BackendType.CALDAV)) {
			Services.Database.get_default ().delete_project (project);
		}

		// Delete all labels;
		//  foreach (var label in Services.Database.get_default ().get_all_labels_by_todoist ()) {
		//  	Services.Database.get_default ().delete_label (label);
		//  }

		// Clear Queue
		//  Services.Database.get_default ().clear_queue ();

		// Clear CurTempIds
		//  Services.Database.get_default ().clear_cur_temp_ids ();

		// Check Inbox Project
		//  if (Services.Settings.get_default ().settings.get_enum ("default-inbox") == 1) {
		//  	Services.Settings.get_default ().settings.set_enum ("default-inbox", 0);
		//  	Util.get_default ().change_default_inbox ();
		//  }

		// Remove server_timeout
		//  Source.remove (server_timeout);
		//  server_timeout = 0;

		log_out ();
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
