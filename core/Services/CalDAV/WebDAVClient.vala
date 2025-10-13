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

public class Services.CalDAV.WebDAVClient : GLib.Object {

    protected Soup.Session session;

    protected string username;
    protected string password;
    protected string base_url;
    protected bool ignore_ssl;


    public WebDAVClient (Soup.Session session, string base_url, string username, string password, bool ignore_ssl = false) {
        this.session = session;
        this.base_url = base_url;
        this.username = username;
        this.password = password;
        this.ignore_ssl = ignore_ssl;
    }

    public void cleanup () {
        if (session != null) {
            session.abort ();
        }
    }

    public string get_absolute_url (string href) {
        string abs_url = null;
        try {
            abs_url = GLib.Uri.resolve_relative (base_url, href, GLib.UriFlags.NONE).to_string ();
        } catch (Error e) {
            critical ("Failed to resolve relative url: %s", e.message);
        }
        return abs_url;
    }

    public async WebDAVMultiStatus propfind (string url, string xml, string depth, GLib.Cancellable cancellable) throws GLib.Error {
        return new WebDAVMultiStatus.from_string (yield send_request ("PROPFIND", url, "application/xml", xml, depth, cancellable, { Soup.Status.MULTI_STATUS }));
    }

    public async WebDAVMultiStatus report (string url, string xml, string depth, GLib.Cancellable cancellable) throws GLib.Error {
        return new WebDAVMultiStatus.from_string (yield send_request ("REPORT", url, "application/xml", xml, depth, cancellable, { Soup.Status.MULTI_STATUS }));
    }

    protected async string send_request (string method, string url, string content_type, string? body, string? depth, GLib.Cancellable? cancellable, Soup.Status[] expected_statuses, HashTable<string,string>? extra_headers = null) throws GLib.Error {
        var abs_url = get_absolute_url (url);
        if (abs_url == null)
            throw new GLib.IOError.FAILED ("Invalid URL: %s".printf (url));

        debug ("[CalDAV] %s request to: %s", method, abs_url);
        var msg = new Soup.Message (method, abs_url);
        msg.request_headers.append ("User-Agent", Constants.SOUP_USER_AGENT);

        msg.authenticate.connect ((auth, retrying) => {
            if (retrying) {
                warning ("[CalDAV] Authentication retry failed for user: %s", this.username);
                return false;
            }

            if (auth.scheme_name == "Digest" || auth.scheme_name == "Basic") {
                debug ("[CalDAV] Authenticating with scheme: %s, username: %s, password length: %d", auth.scheme_name, this.username, this.password.length);
                auth.authenticate (this.username, this.password);
                return true;
            }
            warning ("[CalDAV] Unsupported auth schema: %s", auth.scheme_name);
            return false;
        });

        // After authentication, the body of the message needs to be set again when the message is resent.
        // https://gitlab.gnome.org/GNOME/libsoup/-/issues/358
        msg.restarted.connect (() => {
            if (body != null) {
                msg.set_request_body_from_bytes (content_type, new GLib.Bytes (body.data));
            }
        });

        if (ignore_ssl) {
            msg.accept_certificate.connect (() => {
                return true;
            });
        }

        if (depth != null) {
            msg.request_headers.replace ("Depth", depth);
        }

        if (extra_headers != null) {
            foreach (var key in extra_headers.get_keys ())
                msg.request_headers.replace (key, extra_headers.lookup (key));
        }

        if (body != null) {
            msg.set_request_body_from_bytes (content_type, new GLib.Bytes (body.data));
        }

        GLib.Bytes response;
        try {
            response = yield session.send_and_read_async (msg, Priority.DEFAULT, cancellable);
            debug ("[CalDAV] Response status: %u %s", msg.status_code, msg.reason_phrase ?? "");
        } catch (Error e) {
            if (e is GLib.IOError.CANCELLED) {
                debug ("[CalDAV] Request cancelled");
                throw e;
            }
            warning ("[CalDAV] Request failed: %s", e.message);
            throw new GLib.IOError.FAILED ("Request failed: %s".printf (e.message));
        }

        bool ok = false;
        foreach (var code in expected_statuses) {
            if (msg.status_code == code) {
                ok = true;
                break;
            }
        }

        if (!ok) {
            var response_text = (string) response.get_data ();
            var expected_codes = new StringBuilder ();
            foreach (var code in expected_statuses) {
                if (expected_codes.len > 0) expected_codes.append (", ");
                expected_codes.append_printf ("%u", code);
            }
            warning ("[CalDAV] Unexpected status %u, expected: %s", msg.status_code, expected_codes.str);
            warning ("[CalDAV] Response (first 500 chars): %s", response_text != null ? response_text.substring(0, int.min(500, response_text.length)) : "(null)");
            
            if (msg.status_code == Soup.Status.UNAUTHORIZED) {
                warning ("[CalDAV] Auth failed for user: %s", this.username);
                throw new GLib.IOError.PERMISSION_DENIED ("Authentication failed. Token may be expired or revoked.");
            }
            
            throw new GLib.IOError.FAILED (
                "%s %s failed: HTTP %u %s\n%s".printf (
                    method, abs_url, msg.status_code, msg.reason_phrase ?? "", response_text ?? "")
            );
        }

        var response_data = (string) response.get_data ();
        debug ("[CalDAV] Response length: %d bytes", response_data != null ? response_data.length : 0);
        return response_data;
    }

}


public class Services.CalDAV.WebDAVMultiStatus : Object {
    private GXml.DomElement root;
    private string xml_content;

    public WebDAVMultiStatus.from_string (string xml) throws GLib.Error {
        this.xml_content = xml;
        debug ("[CalDAV] Parsing XML response, length: %d", xml != null ? xml.length : 0);
        
        if (xml == null || xml.strip () == "") {
            warning ("[CalDAV] Empty XML response");
            xml = "<?xml version=\"1.0\"?><multistatus xmlns=\"DAV:\"/>";
        }
        
        try {
            this.root = new GXml.XDocument.from_string (xml).document_element;
        } catch (Error e) {
            warning ("[CalDAV] XML parse error: %s", e.message);
            warning ("[CalDAV] XML content (first 1000 chars): %s", xml.substring(0, int.min(1000, xml.length)));
            throw e;
        }
    }

    public void debug_print () {
        print ("-------------------------------\n");
        debug ("%s\b", xml_content);
        print ("-------------------------------\n");
    }

    public Gee.ArrayList<WebDAVResponse> responses () {
        var list = new Gee.ArrayList<WebDAVResponse> ();
        foreach (var resp in root.get_elements_by_tag_name ("response")) {
            list.add (new WebDAVResponse (resp));
        }
        return list;
    }

    public string ? get_first_text_content_by_tag_name (string tag_name) {
        foreach (var h in root.get_elements_by_tag_name (tag_name)) {
            var text = h.text_content.strip ();
            if (text != null && text.length > 0) {
                return text;
            }
        }

        return null;
    }
}


public class Services.CalDAV.WebDAVResponse : Object {
    public string? href { get; private set; }
    public Soup.Status status { get; private set; default = Soup.Status.NONE; }
    private GXml.DomElement element;

    public WebDAVResponse (GXml.DomElement element) {
        this.element = element;
        parse_href ();
        parse_status ();
    }

    private void parse_href () {
        foreach (var h in element.get_elements_by_tag_name ("href")) {
            var text = h.text_content.strip ();
            if (text != null && text.length > 0) {
                href = text;
                break;
            }
        }
    }

    private void parse_status () {
        foreach (var s in element.get_elements_by_tag_name ("status")) {
            var text = s.text_content.strip ();
            if (text != null && text.length > 0) {
                status = parse_status_line (text);
                break;
            }
        }
    }

    private Soup.Status parse_status_line (string status_line) {
        Soup.HTTPVersion ver;
        uint code;
        string reason;

        if (Soup.headers_parse_status_line (status_line, out ver, out code, out reason)) {
            return (Soup.Status) code;
        }

        return Soup.Status.NONE;
    }

    public Gee.ArrayList<WebDAVPropStat> propstats () {
        var results = new Gee.ArrayList<WebDAVPropStat> ();
        foreach (var ps in element.get_elements_by_tag_name ("propstat")) {
            results.add (new WebDAVPropStat (ps));
        }
        return results;
    }
}


public class Services.CalDAV.WebDAVPropStat : Object {
    public Soup.Status status { get; private set; }
    public GXml.DomElement prop { get; private set; }

    public WebDAVPropStat (GXml.DomElement element) {
        var status_list = element.get_elements_by_tag_name ("status");
        if (status_list.length == 1) {
            var text = status_list[0].text_content.strip ();
            if (text != null && text.length > 0)
                status = parse_status_line (text);
        }

        var prop_list = element.get_elements_by_tag_name ("prop");
        if (prop_list.length == 1) {
            prop = prop_list[0];
        }
    }

    private Soup.Status parse_status_line (string status_line) {
        Soup.HTTPVersion ver;
        uint code;
        string reason;

        if (Soup.headers_parse_status_line (status_line, out ver, out code, out reason)) {
            return (Soup.Status) code;
        }

        return Soup.Status.NONE;
    }

    public GXml.DomElement? get_first_prop_with_tagname (string tagname) {
        if (prop == null) {
            return null;
        }

        foreach (var e in prop.get_elements_by_tag_name (tagname)) {
            return e;
        }

        return null;
    }

}
