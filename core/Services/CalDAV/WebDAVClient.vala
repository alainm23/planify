/*
 * Copyright © 2025 Alain M. (https://github.com/alainm23/planify)
 * Copyright © 2025 byquanton
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
 * Authored by: byquanton
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

    private static GLib.Regex ? between_tags_regex;

    private string minify_xml (string xml) {
        try {
            if (between_tags_regex == null) {
                between_tags_regex = new GLib.Regex (">\\s+<");
            }

            string result = between_tags_regex.replace_literal (xml, -1, 0, "><");

            return result.strip ();
        } catch (RegexError e) {
            Services.LogService.get_default ().error ("WebDAV", "Regex error: " + e.message);
            return xml;
        }
    }

    protected string get_absolute_url (string href) {
        string abs_url = null;
        try {
            abs_url = GLib.Uri.resolve_relative (base_url, href, GLib.UriFlags.NONE).to_string ();
        } catch (Error e) {
            Services.LogService.get_default ().error ("WebDAV", "Failed to resolve relative url: %s".printf (e.message));
        }
        return abs_url;
    }

    public async WebDAVMultiStatus propfind (string url, string xml, string depth, GLib.Cancellable cancellable) throws GLib.Error {
        Services.LogService.get_default ().debug ("WebDAV", "PROPFIND request (depth: %s)".printf (depth));
        var result = yield send_request ("PROPFIND", url, "application/xml", minify_xml (xml), depth, cancellable, { Soup.Status.MULTI_STATUS });
        return new WebDAVMultiStatus.from_string (result.data);
    }

    public async WebDAVMultiStatus report (string url, string xml, string depth, GLib.Cancellable cancellable) throws GLib.Error {
        Services.LogService.get_default ().debug ("WebDAV", "REPORT request (depth: %s)".printf (depth));
        var result = yield send_request ("REPORT", url, "application/xml", minify_xml (xml), depth, cancellable, { Soup.Status.MULTI_STATUS });
        return new WebDAVMultiStatus.from_string (result.data);
    }

    protected async HttpResponse send_request (string method, string url, string content_type, string? body, string? depth, GLib.Cancellable? cancellable, Soup.Status[] expected_statuses, HashTable<string,string>? extra_headers = null) throws GLib.Error {
        var abs_url = get_absolute_url (url);
        if (abs_url == null)
            throw new GLib.IOError.FAILED ("Invalid URL: %s".printf (url));

        Services.LogService.get_default ().debug ("WebDAV", "%s %s".printf (method, abs_url));

        var msg = new Soup.Message (method, abs_url);
        msg.request_headers.append ("User-Agent", Constants.SOUP_USER_AGENT);

        msg.authenticate.connect ((auth, retrying) => {
            if (retrying) {
                Services.LogService.get_default ().error ("WebDAV", "Authentication failed, not retrying");
                return false;
            }

            if (auth.scheme_name == "Digest" || auth.scheme_name == "Basic") {
                auth.authenticate (this.username, this.password);
                return true;
            }
            Services.LogService.get_default ().warn ("WebDAV", "Unsupported auth schema: %s".printf (auth.scheme_name));
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
        } catch (Error e) {
            if (e is GLib.IOError.CANCELLED) {
                Services.LogService.get_default ().info ("WebDAV", "Request cancelled");
                throw e;
            }
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
            Services.LogService.get_default ().error ("WebDAV", "%s %s failed: HTTP %u %s".printf (method, abs_url, msg.status_code, msg.reason_phrase ?? ""));
            throw new GLib.IOError.FAILED (
                "%s %s failed: HTTP %u %s\n%s".printf (
                    method, abs_url, msg.status_code, msg.reason_phrase ?? "", response_text ?? "")
            );
        }

        var response_data = response.get_data ();
        response_data += '\0';

        return new HttpResponse () {
            status = true,
            http_code = (int) msg.status_code,
            etag = msg.response_headers.get_one ("ETag"),
            data = (string) response_data
        };
    }
}


public class Services.CalDAV.WebDAVXmlElement {
    private string local_name;
    public string text_content = "";
    private Gee.ArrayList<WebDAVXmlElement>? children = null;
    private Gee.HashMap<string, string>? attributes = null;

    public WebDAVXmlElement (string local_name) {
        this.local_name = local_name;
    }

    internal void add_child (WebDAVXmlElement child) {
        if (children == null) {
            children = new Gee.ArrayList<WebDAVXmlElement> ();
        }
        children.add (child);
    }

    internal void set_attribute (string name, string value) {
        if (attributes == null) {
            attributes = new Gee.HashMap<string, string> ();
        }
        attributes[name] = value;
    }

    public string? get_attribute (string name) {
        return attributes != null ? attributes[name] : null;
    }

    public WebDAVXmlElement? get_child (string name) {
        if (children != null) {
            foreach (var child in children) {
                if (child.local_name == name) {
                    return child;
                }
            }
        }

        return null;
    }

    public string get_text () {
        return text_content.strip ();
    }

    public Gee.ArrayList<WebDAVXmlElement> get_children (string name) {
        var results = new Gee.ArrayList<WebDAVXmlElement> ();
        if (children != null) {
            foreach (var child in children) {
                if (child.local_name == name) {
                    results.add (child);
                }
            }
        }

        return results;
    }
}

private class Services.CalDAV.WebDAVXmlParser {
    private WebDAVXmlElement? root = null;
    private Gee.ArrayList<WebDAVXmlElement> stack = new Gee.ArrayList<WebDAVXmlElement> ();

    public static WebDAVXmlElement parse (string xml) throws GLib.Error {
        var builder = new WebDAVXmlParser ();

        GLib.MarkupParser parser = {
            WebDAVXmlParser.on_start_element,
            WebDAVXmlParser.on_end_element,
            WebDAVXmlParser.on_text,
            null,
            null
        };

        var context = new GLib.MarkupParseContext (parser, GLib.MarkupParseFlags.TREAT_CDATA_AS_TEXT, builder, null);
        context.parse (xml, -1);
        context.end_parse ();

        if (builder.root == null) {
            throw new GLib.MarkupError.EMPTY ("Empty XML document");
        }

        return builder.root;
    }

    private static string local_name (string name) {
        int idx = name.last_index_of (":");
        return idx >= 0 ? name.substring (idx + 1) : name;
    }

    private static void on_start_element (GLib.MarkupParseContext context, string element_name, [CCode (array_length = false, array_null_terminated = true)] string[] attr_names, [CCode (array_length = false, array_null_terminated = true)] string[] attr_values) throws GLib.MarkupError {
        unowned WebDAVXmlParser self = (WebDAVXmlParser) context.get_user_data ();
        var element = new WebDAVXmlElement (local_name (element_name));

        for (int i = 0; attr_names[i] != null; i++) {
            element.set_attribute (local_name (attr_names[i]), attr_values[i]);
        }

        if (self.stack.is_empty) {
            self.root = element;
        } else {
            self.stack.last ().add_child (element);
        }
        self.stack.add (element);
    }

    private static void on_end_element (GLib.MarkupParseContext context, string element_name) throws GLib.MarkupError {
        unowned WebDAVXmlParser self = (WebDAVXmlParser) context.get_user_data ();
        self.stack.remove_at (self.stack.size - 1);
    }

    private static void on_text (GLib.MarkupParseContext context, string text, size_t text_len) throws GLib.MarkupError {
        unowned WebDAVXmlParser self = (WebDAVXmlParser) context.get_user_data ();
        if (!self.stack.is_empty) {
            self.stack.last ().text_content += text;
        }
    }
}


public class Services.CalDAV.WebDAVMultiStatus : Object {
    public WebDAVXmlElement root { get; private set; }

    public WebDAVMultiStatus.from_string (string xml) throws GLib.Error {
        this.root = WebDAVXmlParser.parse (xml);
    }

    public Gee.ArrayList<WebDAVResponse> responses () {
        var list = new Gee.ArrayList<WebDAVResponse> ();
        foreach (var resp in root.get_children ("response")) {
            list.add (new WebDAVResponse (resp));
        }
        return list;
    }
}


public class Services.CalDAV.WebDAVResponse : Object {
    public string? href { get; private set; }
    public Soup.Status status { get; private set; default = Soup.Status.NONE; }

    private Gee.ArrayList<WebDAVXmlElement> ok_props = new Gee.ArrayList<WebDAVXmlElement> ();

    public WebDAVResponse (WebDAVXmlElement element) {
        href = element.get_child ("href")?.get_text ();
        status = parse_status_line (element.get_child ("status")?.get_text () ?? "");

        foreach (var propstat in element.get_children ("propstat")) {
            var prop = propstat.get_child ("prop");
            if (prop != null && parse_status_line (propstat.get_child ("status")?.get_text () ?? "") == Soup.Status.OK) {
                ok_props.add (prop);
            }
        }
    }

    public WebDAVXmlElement? get_prop (string name) {
        foreach (var prop in ok_props) {
            var found = prop.get_child (name);
            if (found != null) {
                return found;
            }
        }

        return null;
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
}
