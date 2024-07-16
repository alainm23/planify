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
    private Secret.Schema schema;

	private static Core? _instance;
	public static Core get_default () {
		if (_instance == null) {
			_instance = new Core ();
		}

		return _instance;
	}

    public signal void first_sync_started ();
	public signal void first_sync_finished ();

    public signal void sync_started ();
	public signal void sync_finished ();

    public signal void log_out ();
	public signal void log_in ();

    private uint server_timeout = 0;
    private Gee.HashMap<string, string> request_map;

    // vala-lint=naming-convention
    public static string USER_DATA_REQUEST = """
        <x0:propfind xmlns:x0="DAV:">
            <x0:prop>
                <x0:displayname/>
                <x2:email-address xmlns:x2="http://sabredav.org/ns"/>
            </x0:prop>
        </x0:propfind>
    """;

    // vala-lint=naming-convention
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
    
	public Core () {
		session = new Soup.Session ();
		parser = new Json.Parser ();

        schema = new Secret.Schema ("io.github.alainm23.planify", Secret.SchemaFlags.NONE,
            "username", Secret.SchemaAttributeType.STRING,
            "server_url", Secret.SchemaAttributeType.STRING
        );

        var network_monitor = GLib.NetworkMonitor.get_default ();
		network_monitor.network_changed.connect (() => {
			if (GLib.NetworkMonitor.get_default ().network_available &&
                is_logged_in () &&
			    Services.Settings.get_default ().settings.get_boolean ("caldav-sync-server")) {
				sync_async ();
			}
		});

        request_map = new Gee.HashMap<string, string> ();
        request_map.set (CalDAVType.NEXTCLOUD.to_string () + "login", Services.CalDAV.Constants.LOGIN_REQUEST);
        request_map.set (CalDAVType.RADICALE.to_string () + "login", Services.CalDAV.Constants.LOGIN_REQUEST);
	}

    public void run_server () {
		sync_async ();

		server_timeout = Timeout.add_seconds (15 * 60, () => {
			if (Services.Settings.get_default ().settings.get_boolean ("caldav-sync-server")) {
				sync_async ();
			}

			return true;
		});
	}

    public string get_request_data (CalDAVType caldav_type, string method) {
        if (request_map.has_key (caldav_type.to_string () + method)) {
            return request_map[caldav_type.to_string () + method];
        }

        return "";
    }

    public async HttpResponse login (CalDAVType caldav_type, string server_url, string username, string password, GLib.Cancellable cancellable) {
        HttpResponse response = new HttpResponse ();
        string _server_url = "";

        try {
            var uri = GLib.Uri.parse (server_url, GLib.UriFlags.NONE);

            if (caldav_type == CalDAVType.NEXTCLOUD) {
                _server_url = "%s://%s".printf (uri.get_scheme (), uri.get_host ());
            } else if (caldav_type == CalDAVType.RADICALE) {
                _server_url = uri.get_host ();
            }
        } catch (Error e) {
            response.error_code = e.code;
            response.error = e.message;
            return response;
        }

        string url = Services.CalDAV.Backend.generate_server_url (caldav_type, _server_url, username, GLib.Uri.escape_string (password));
        print ("Server URL: %s\n".printf (url));

        string credentials = "%s:%s".printf (username, password);
        string base64_credentials = Base64.encode (credentials.data);

        var message = new Soup.Message ("PROPFIND", url);
		message.request_headers.append ("Authorization", "Basic %s".printf (base64_credentials));
        message.set_request_body_from_bytes ("application/xml", new Bytes (get_request_data (caldav_type, "login").data));

        try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, cancellable);
            
            print_root ("login", (string) stream.get_data ());
            print ("login status_code: %s\n".printf (message.status_code.to_string ()));

            if (message.status_code == 207) {
                Services.Settings.get_default ().settings.set_string ("caldav-server-url", url);
                Services.Settings.get_default ().settings.set_string ("caldav-username", username);
                Services.Settings.get_default ().settings.set_enum ("caldav-type", caldav_type);
                
                yield Secret.password_storev (schema, get_attributes (), Secret.COLLECTION_DEFAULT, username, password, cancellable); 

                response.status = true;
            } else {
                response.error_code = (int) message.status_code;
                response.error = (string) stream.get_data ();
            }
        } catch (Error e) {
			print ("login error: %s".printf (e.message));
            response.error_code = e.code;
            response.error = e.message;
		}

        return response;
    }

    public CalDAVType get_backend_type () {
        return (CalDAVType) Services.Settings.get_default ().settings.get_enum ("caldav-type");
    }

    public async void first_sync () {
        if (get_backend_type () == CalDAVType.NEXTCLOUD) {
            string url = "%s/principals/users/%s/".printf (
                Services.Settings.get_default ().settings.get_string ("caldav-server-url"),
                Services.Settings.get_default ().settings.get_string ("caldav-username")
            );
    
            var message = new Soup.Message ("PROPFIND", url);
    
            try {
                yield set_credential (message);
                message.set_request_body_from_bytes ("application/xml", new Bytes (USER_DATA_REQUEST.data));
    
                GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
    
                print_root ("first_sync", (string) stream.get_data ());
    
                GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
                GXml.DomElement d_displayname = doc.get_elements_by_tag_name ("d:displayname").get_element (0);
                GXml.DomElement d_email = doc.get_elements_by_tag_name ("s:email-address").get_element (0);
    
                Services.Settings.get_default ().settings.set_string ("caldav-user-displayname", d_displayname.text_content);
                Services.Settings.get_default ().settings.set_string ("caldav-user-email", d_email.text_content);
    
                yield get_all_tasklist ();
            } catch (Error e) {
                debug (e.message);
            }
        } else {
            yield get_all_tasklist ();
        }
    }

    public async void get_all_tasklist () {
        var url = "%s/calendars/%s/".printf (
            Services.Settings.get_default ().settings.get_string ("caldav-server-url"),
            Services.Settings.get_default ().settings.get_string ("caldav-username")
        );

        var message = new Soup.Message ("PROPFIND", url);

        try {
            yield set_credential (message);
            message.set_request_body_from_bytes ("application/xml", new Bytes (TASKLIST_REQUEST.data));

			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            print_root ("get_all_tasklist", (string) stream.get_data ());

            GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
            GXml.DomHTMLCollection response = doc.get_elements_by_tag_name ("d:response");
            foreach (GXml.DomElement element in response) {
                if (is_vtodo_calendar (element)) {
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
        var url = "%s/calendars/%s/%s/".printf (
            Services.Settings.get_default ().settings.get_string ("caldav-server-url"),
            Services.Settings.get_default ().settings.get_string ("caldav-username"),
            project.id
        );

        var message = new Soup.Message ("REPORT", url);

        try {
            yield set_credential (message);
            message.request_headers.append ("Depth", "1");
            message.set_request_body_from_bytes ("application/xml", new Bytes (TASKS_REQUEST.data));

			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            
            print_root ("get_all_tasks_by_tasklist", (string) stream.get_data ());

            GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
            GXml.DomHTMLCollection response = doc.get_elements_by_tag_name ("d:response");
            
            // Categories
            Gee.HashMap<string, string> labels_map = new Gee.HashMap<string, string> ();
            foreach (GXml.DomElement element in response) {
                setup_categories (element, labels_map);
            }

            foreach (string category in labels_map.values) {
                var label = new Objects.Label ();
                label.id = Util.get_default ().generate_id (label);
                label.name = category;
                label.color = Util.get_default ().get_random_color ();
                label.backend_type = BackendType.CALDAV;
                Services.Database.get_default ().insert_label (label);
            }

            foreach (GXml.DomElement element in response) {
                add_item_if_not_exists (element, project);
            }
        } catch (Error e) {
			debug (e.message);
		}
    }

    private void setup_categories (GXml.DomElement element, Gee.HashMap<string, string> labels_map) {
        GXml.DomElement propstat = element.get_elements_by_tag_name ("d:propstat").get_element (0);
        GXml.DomElement prop = propstat.get_elements_by_tag_name ("d:prop").get_element (0);
        string data = prop.get_elements_by_tag_name ("cal:calendar-data").get_element (0).text_content;

        var categories = Util.find_string_value ("CATEGORIES", data);
        if (categories != "") {
            string _categories = categories.replace ("\\,", ";");
            string[] categories_list = _categories.split (",");
            foreach (unowned string str in categories_list) {
                string category = str.replace (";", ",");

                if (!labels_map.has_key (category)) {
                    labels_map.set (category, category);
                }
            }
        }
    }

    public async void update_all_tasks_by_tasklist (Objects.Project project, Gee.HashMap<string, string> labels_map) {
        var url = "%s/calendars/%s/%s/".printf (
            Services.Settings.get_default ().settings.get_string ("caldav-server-url"),
            Services.Settings.get_default ().settings.get_string ("caldav-username"),
            project.id
        );
        var message = new Soup.Message ("REPORT", url);

        try {
            yield set_credential (message);
            message.request_headers.append ("Depth", "1");
            message.set_request_body_from_bytes ("application/xml", new Bytes (TASKS_REQUEST.data));

			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            
            print_root ("update_all_tasks_by_tasklist", (string) stream.get_data ());

            GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
            GXml.DomHTMLCollection response = doc.get_elements_by_tag_name ("d:response");

            foreach (GXml.DomElement element in response) {
                setup_categories (element, labels_map);
            }

            foreach (string category in labels_map.values) {
                var label = Services.Database.get_default ().get_label_by_name (category, true, BackendType.CALDAV);
                if (label == null) {
                    label = new Objects.Label ();
                    label.id = Util.get_default ().generate_id (label);
                    label.name = category;
                    label.color = Util.get_default ().get_random_color ();
                    label.backend_type = BackendType.CALDAV;
                    Services.Database.get_default ().insert_label (label);
                }
            }

            Gee.HashMap <string, Objects.Item> items_map = new Gee.HashMap <string, Objects.Item> ();
            foreach (GXml.DomElement element in response) {
                Objects.Item? item = Services.Database.get_default ().get_item (
                    Util.get_task_uid (element)
                );

                if (item != null) {
                    items_map.set (item.id, item);

                    string old_project_id = item.project_id;
                    string old_parent_id = item.parent_id;

                    item.update_from_caldav_xml (element);
                    item.project_id = project.id;
                    Services.Database.get_default ().update_item (item);

                    if (old_project_id != item.project_id || old_parent_id != item.parent_id) {
                        Services.EventBus.get_default ().item_moved (item, old_project_id, "", old_parent_id);
                    }

                    bool old_checked = item.checked;
                    if (old_checked != item.checked) {
                        Services.Database.get_default ().checked_toggled (item, old_checked);
                    }
                } else {
                    item = add_item_if_not_exists (element, project);
                    items_map.set (item.id, item);
                }
            }

            foreach (Objects.Item item in project.all_items) {
                if (!items_map.has_key (item.id)) {
                    Services.Database.get_default ().delete_item (item);
                }
            }
        } catch (Error e) {
			debug (e.message);
		}
    }

    private Objects.Item add_item_if_not_exists (GXml.DomElement element, Objects.Project project) {
        Objects.Item return_value;

        string parent_id = Util.get_related_to_uid (element);
        if (parent_id != "") {
            Objects.Item? parent_item = Services.Database.get_default ().get_item (parent_id);
            if (parent_item != null) {
                return_value = new Objects.Item.from_caldav_xml (element);
                return_value.project_id = project.id;
                parent_item.add_item_if_not_exists (return_value);
            } else {
                return_value = new Objects.Item.from_caldav_xml (element);
                return_value.project_id = project.id;
                project.add_item_if_not_exists (return_value);
            }
        } else {
            return_value = new Objects.Item.from_caldav_xml (element);
            return_value.project_id = project.id;
            project.add_item_if_not_exists (return_value);
        }

        return return_value;
	}

    public void sync_async () {
        sync.begin ((obj, res) => {
			sync.end (res);
		});
	}

    private async void sync () {
        sync_started ();

        var url = "%s/calendars/%s/".printf (
            Services.Settings.get_default ().settings.get_string ("caldav-server-url"),
            Services.Settings.get_default ().settings.get_string ("caldav-username")
        );
        var message = new Soup.Message ("PROPFIND", url);

        try {
            yield set_credential (message);
            message.set_request_body_from_bytes ("application/xml", new Bytes (TASKLIST_REQUEST.data));
            
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            print_root ("sync", (string) stream.get_data ());

            GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
            GXml.DomHTMLCollection response = doc.get_elements_by_tag_name ("d:response");
 
            foreach (GXml.DomElement element in response) {
                if (is_vtodo_calendar (element)) {
                    Objects.Project? project = Services.Database.get_default ().get_project (get_tasklist_id_from_url (element));
                    if (project == null) {
                        project = new Objects.Project.from_caldav_xml (element);
                        Services.Database.get_default ().insert_project (project);
                        yield get_all_tasks_by_tasklist (project);
                    } else {
                        project.update_from_xml (element, false);
                        Services.Database.get_default ().update_project (project);
                    }
                } else if (is_deleted_calendar (element)) {
                    Objects.Project? project = Services.Database.get_default ().get_project (get_tasklist_id_from_url (element));
                    if (project != null) {
                        Services.Database.get_default ().delete_project (project);
                    }
                }
            }
        } catch (Error e) {
			debug (e.message);
		}

        foreach (Objects.Project project in Services.Database.get_default ().get_all_projects_by_backend_type (BackendType.CALDAV)) {
			yield sync_tasklist (project);
		}

        Services.Settings.get_default ().settings.set_string ("caldav-last-sync", new GLib.DateTime.now_local ().to_string ());
        sync_finished ();
    }

    public async void sync_tasklist (Objects.Project project) {
        var url = "%s/calendars/%s/%s".printf (
            Services.Settings.get_default ().settings.get_string ("caldav-server-url"),
            Services.Settings.get_default ().settings.get_string ("caldav-username"),
            project.id
        );

        var message = new Soup.Message ("REPORT", url);

        try {
            yield set_credential (message);
            message.set_request_body_from_bytes ("application/xml", new Bytes ((SYNC_TOKEN_REQUEST.printf (project.sync_id)).data));
    
            if (project.sync_id == "") {
                return;
            }

            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            print_root ("sync_tasklist", (string) stream.get_data ());

            GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
            GXml.DomHTMLCollection response = doc.get_elements_by_tag_name ("d:response");

            foreach (GXml.DomElement element in response) {
                GXml.DomHTMLCollection status = element.get_elements_by_tag_name ("d:status");
                string ics = get_task_ics_from_url (element);
                bool is_vtodo = is_vtodo (element);
                
                if (!is_vtodo) {
                    continue;
                }

                if (status.length > 0 && status.get_element (0).text_content == "HTTP/1.1 404 Not Found") {
                    Objects.Item? item = Services.Database.get_default ().get_item_by_ics (ics);
                    if (item != null) {
                        Services.Database.get_default ().delete_item (item);
                    }
                } else {
                    string vtodo = yield get_vtodo_by_url (project.id, ics);

                    ICal.Component ical = new ICal.Component.from_string (vtodo);
                    Objects.Item? item = Services.Database.get_default ().get_item (ical.get_uid ());
    
                    if (item != null) {
                        string old_project_id = item.project_id;
                        string old_parent_id = item.parent_id;
                        
                        item.update_from_vtodo (vtodo, ics);
                        item.project_id = project.id;
                        Services.Database.get_default ().update_item (item);
    
                        if (old_project_id != item.project_id || old_parent_id != item.parent_id) {
                            Services.EventBus.get_default ().item_moved (item, old_project_id, "", old_parent_id);
                        }
    
                        bool old_checked = item.checked;
                        if (old_checked != item.checked) {
                            Services.Database.get_default ().checked_toggled (item, old_checked);
                        }
                    } else {
                        string parent_id = Util.find_string_value ("RELATED-TO", vtodo);
                        if (parent_id != "") {
                            Objects.Item? parent_item = Services.Database.get_default ().get_item (parent_id);
                            if (parent_item != null) {
                                var new_item = new Objects.Item.from_vtodo (vtodo, ics);
                                new_item.project_id = project.id;
                                parent_item.add_item_if_not_exists (new_item);
                            } else {
                                var new_item = new Objects.Item.from_vtodo (vtodo, ics);
                                new_item.project_id = project.id;
                                project.add_item_if_not_exists (new_item);
                            }
                        } else {
                            var new_item = new Objects.Item.from_vtodo (vtodo, ics);
                            new_item.project_id = project.id;
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
    }

    private async string? get_vtodo_by_url (string tasklist_id, string task_ics) {
        var url = "%s/calendars/%s/%s/%s".printf (
            Services.Settings.get_default ().settings.get_string ("caldav-server-url"),
            Services.Settings.get_default ().settings.get_string ("caldav-username"),
            tasklist_id,
            task_ics
        );
        
        var message = new Soup.Message ("GET", url);
        string return_value = null;

        try {
            yield set_credential (message);

            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            print_root ("get_vtodo_by_url", (string) stream.get_data ());
            return_value = (string) stream.get_data ();
        } catch (Error e) {
            debug (e.message);
        }

        return return_value;
    }

    private async void add_project_if_not_exists (GXml.DomElement element, Gee.HashMap<string, string> labels_map) {
        if (is_vtodo_calendar (element)) {
            Objects.Project? project = Services.Database.get_default ().get_project (get_tasklist_id_from_url (element));
            if (project == null) {
                project = new Objects.Project.from_caldav_xml (element);
                Services.Database.get_default ().insert_project (project);
                yield get_all_tasks_by_tasklist (project);
            } else {
                project.update_from_xml (element);
                Services.Database.get_default ().update_project (project);
                yield update_all_tasks_by_tasklist (project, labels_map);
            }
        } else if (is_deleted_calendar (element)) {
            Objects.Project? project = Services.Database.get_default ().get_project (get_tasklist_id_from_url (element));
            if (project != null) {
                Services.Database.get_default ().delete_project (project);
            }
        }
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

    public async bool add_tasklist (Objects.Project project) {
        var url = "%s/calendars/%s/%s/".printf (
            Services.Settings.get_default ().settings.get_string ("caldav-server-url"),
            Services.Settings.get_default ().settings.get_string ("caldav-username"),
            project.id
        );
        
        var message = new Soup.Message ("MKCOL", url);
        bool status = false;

        try {
            yield set_credential (message);
            message.set_request_body_from_bytes ("application/xml", new Bytes ((CREATE_TASKLIST_REQUEST.printf (project.name, project.color_hex)).data));
    

			yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            status = true;
        } catch (Error e) {
			debug (e.message);
		}

        return status;
    }

    public async bool update_tasklist (Objects.Project project) {        
        var url = "%s/calendars/%s/%s/".printf (
            Services.Settings.get_default ().settings.get_string ("caldav-server-url"),
            Services.Settings.get_default ().settings.get_string ("caldav-username"),
            project.id
        );
        
        var message = new Soup.Message ("PROPPATCH", url);
        bool status = false;

        try {
            yield set_credential (message);
            message.set_request_body_from_bytes ("application/xml", new Bytes ((UPDATE_TASKLIST_REQUEST.printf (project.name, project.color_hex)).data));
    
			yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            status = true;
        } catch (Error e) {
			debug (e.message);
		}

        return status;
    }

    public async bool delete_tasklist (Objects.Project project) {        
        var url = "%s/calendars/%s/%s/".printf (
            Services.Settings.get_default ().settings.get_string ("caldav-server-url"),
            Services.Settings.get_default ().settings.get_string ("caldav-username"),
            project.id
        );

        var message = new Soup.Message ("DELETE", url);
        bool status = false;

        try {
            yield set_credential (message);

			yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
            status = true;
        } catch (Error e) {
			debug (e.message);
		}

        return status;
    }

    public async HttpResponse refresh_tasklist (Objects.Project project) {
        var url = "%s/calendars/%s/%s/".printf (
            Services.Settings.get_default ().settings.get_string ("caldav-server-url"),
            Services.Settings.get_default ().settings.get_string ("caldav-username"),
            project.id
        );
        var message = new Soup.Message ("PROPFIND", url);

        HttpResponse return_value = new HttpResponse ();

        try {
            yield set_credential (message);
            message.set_request_body_from_bytes ("application/xml", new Bytes ((TASKLIST_REQUEST).data));

            GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            print_root ("refresh_tasklist", (string) stream.get_data ());

            GXml.DomDocument doc = new GXml.Document.from_string ((string) stream.get_data ());
            GXml.DomHTMLCollection response = doc.get_elements_by_tag_name ("d:response");
            
            // Categories
            Gee.HashMap<string, string> labels_map = new Gee.HashMap<string, string> ();

            foreach (GXml.DomElement element in response) {
                yield add_project_if_not_exists (element, labels_map);
            }

            return_value.status = true;
        } catch (Error e) {
			debug (e.message);
		}

        return return_value;
    }

    /*
     * Task
     */
    
     public async HttpResponse add_task (Objects.Item item, bool update = false) {
        var ics = update ? item.ics : "%s.ics".printf (item.id);

        var url = "%s/calendars/%s/%s/%s".printf (
            Services.Settings.get_default ().settings.get_string ("caldav-server-url"),
            Services.Settings.get_default ().settings.get_string ("caldav-username"),
            item.project.id,
            ics
        );
        var message = new Soup.Message ("PUT", url);

        HttpResponse response = new HttpResponse ();

        try {
            yield set_credential (message);
            message.set_request_body_from_bytes ("application/xml", new Bytes (item.to_vtodo ().data));

			yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            if (update ? message.status_code == 204 : message.status_code == 201) {
                response.status = true;
                item.extra_data = Util.generate_extra_data (ics, "", item.to_vtodo ());
            }
        } catch (Error e) {
			debug (e.message);
		}

        return response;
     }

     public async HttpResponse delete_task (Objects.Item item) {
        var url = "%s/calendars/%s/%s/%s".printf (
            Services.Settings.get_default ().settings.get_string ("caldav-server-url"),
            Services.Settings.get_default ().settings.get_string ("caldav-username"),
            item.project.id,
            item.ics
        );
        var message = new Soup.Message ("DELETE", url);

        HttpResponse response = new HttpResponse ();

        try {
            yield set_credential (message);
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            print_root ("delete_task", (string) stream.get_data ());

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

     public async HttpResponse complete_item (Objects.Item item) {
        var ics = item.ics;
        var body = item.to_vtodo ();

        var url = "%s/calendars/%s/%s/%s".printf (
            Services.Settings.get_default ().settings.get_string ("caldav-server-url"),
            Services.Settings.get_default ().settings.get_string ("caldav-username"),
            item.project.id,
            ics
        );
        var message = new Soup.Message ("PUT", url);

        HttpResponse response = new HttpResponse ();

        try {
            yield set_credential (message);
            message.set_request_body_from_bytes ("application/xml", new Bytes (body.data));
            
			yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            if (message.status_code == 204) {
                response.status = true;
                item.extra_data = Util.generate_extra_data (ics, "", body);
            }
        } catch (Error e) {
			debug (e.message);
		}

        return response;
     }

     public async HttpResponse move_task (Objects.Item item, string project_id) {
        var url = "%s/calendars/%s/%s/%s".printf (
            Services.Settings.get_default ().settings.get_string ("caldav-server-url"),
            Services.Settings.get_default ().settings.get_string ("caldav-username"),
            item.project.id,
            item.ics
        );
        var destination = "/remote.php/dav/calendars/%s/%s/%s".printf (
            Services.Settings.get_default ().settings.get_string ("caldav-username"),
            project_id,
            item.ics
        );
        var message = new Soup.Message ("MOVE", url);

        HttpResponse response = new HttpResponse ();

        try {
            yield set_credential (message);
            message.request_headers.append ("Destination", destination);

			yield session.send_and_read_async (message, GLib.Priority.HIGH, null);

            if (message.status_code == 201 || message.status_code == 204) {
                response.status = true;
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

		// Delete all projects, sections and items
		foreach (var project in Services.Database.get_default ().get_all_projects_by_backend_type (BackendType.CALDAV)) {
			Services.Database.get_default ().delete_project (project);
		}

		// Delete all labels;
		foreach (var label in Services.Database.get_default ().get_labels_by_backend_type (BackendType.CALDAV)) {
			Services.Database.get_default ().delete_label (label);
		}

		// Remove server_timeout
		GLib.Source.remove (server_timeout);
		server_timeout = 0;

		log_out ();
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

    private GLib.HashTable <string, string> get_attributes () {
        var attributes = new GLib.HashTable <string, string> (str_hash, str_equal);
        attributes["username"] = Services.Settings.get_default ().settings.get_string ("caldav-username");
        attributes["server_url"] = Services.Settings.get_default ().settings.get_string ("caldav-server-url");

        print ("get_attributes - username: %s\n".printf (attributes["username"]));
        print ("get_attributes - server_url: %s\n".printf (attributes["server_url"]));

        return attributes;
    }

    private async void set_credential (Soup.Message message) throws Error {
        string username = Services.Settings.get_default ().settings.get_string ("caldav-username");
        string password = yield Secret.password_lookupv (schema, get_attributes (), null);
        string credentials = "%s:%s".printf (username, password);
        string base64_credentials = Base64.encode (credentials.data);
        message.request_headers.append ("Authorization", "Basic %s".printf (base64_credentials));
    }

    private void print_root (string fuction, string data) {
        print (fuction + "\n");
        print (data + "\n");
	}
}
