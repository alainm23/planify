/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
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

public class Services.Deck.DeckClient : Object {
    private Soup.Session session;
    private string base_url;
    private string internal_base_url;
    private string username;
    private string password;

    public DeckClient (string base_url, string username, string password) {
        this.base_url = base_url;
        this.internal_base_url = base_url.replace ("/api/v1.0", "");
        this.username = username;
        this.password = password;
        this.session = new Soup.Session ();
        this.session.user_agent = Constants.SOUP_USER_AGENT;
    }

    private Soup.Message build_message (string method, string endpoint, string? body = null) {
        var url = base_url + endpoint;
        var msg = new Soup.Message (method, url);

        // Basic Auth
        var credentials = Base64.encode (("%s:%s".printf (username, password)).data);
        msg.request_headers.append ("Authorization", "Basic %s".printf (credentials));
        msg.request_headers.append ("OCS-APIRequest", "true");
        msg.request_headers.append ("Content-Type", "application/json");

        if (body != null) {
            msg.set_request_body_from_bytes ("application/json", new Bytes (body.data));
        }

        return msg;
    }

    private async Json.Array send_array_request (string method, string endpoint, string? body = null, string? if_modified_since = null) throws GLib.Error {
        var msg = build_message (method, endpoint, body);

        if (if_modified_since != null && if_modified_since != "") {
            // Convert ISO 8601 to IMF-fixdate in English (required by Deck API)
            try {
                var dt = new GLib.DateTime.from_iso8601 (if_modified_since, new GLib.TimeZone.utc ());
                // Format in English locale
                string[] months = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};
                string[] days = {"Mon","Tue","Wed","Thu","Fri","Sat","Sun"};
                string imf = "%s, %02d %s %04d %02d:%02d:%02d GMT".printf (
                    days[dt.get_day_of_week () - 1],
                    dt.get_day_of_month (),
                    months[dt.get_month () - 1],
                    dt.get_year (),
                    dt.get_hour (),
                    dt.get_minute (),
                    dt.get_second ()
                );
                msg.request_headers.append ("If-Modified-Since", imf);
            } catch (Error e) {
                // Skip If-Modified-Since if conversion fails
            }
        }

        Services.LogService.get_default ().debug ("Deck", "%s %s%s".printf (method, base_url, endpoint));

        var bytes = yield session.send_and_read_async (msg, Priority.DEFAULT, null);
        var response = (string) bytes.get_data ();

        if (msg.status_code == 304) {
            return new Json.Array ();
        }

        if (msg.status_code < 200 || msg.status_code >= 300) {
            throw new GLib.IOError.FAILED ("HTTP %u: %s".printf (msg.status_code, response));
        }

        var parser = new Json.Parser ();
        parser.load_from_data (response, -1);
        return parser.get_root ().get_array ();
    }

    private async Json.Object send_object_request (string method, string endpoint, string? body = null, bool use_internal = false) throws GLib.Error {
        var url = (use_internal ? internal_base_url : base_url) + endpoint;
        var msg = new Soup.Message (method, url);
        var credentials = Base64.encode (("%s:%s".printf (username, password)).data);
        msg.request_headers.append ("Authorization", "Basic %s".printf (credentials));
        msg.request_headers.append ("OCS-APIRequest", "true");
        msg.request_headers.append ("Content-Type", "application/json");
        if (body != null) {
            msg.set_request_body_from_bytes ("application/json", new Bytes (body.data));
        }

        Services.LogService.get_default ().debug ("Deck", "%s %s%s\nBody: %s".printf (method, base_url, endpoint, body ?? "(null)"));

        var bytes = yield session.send_and_read_async (msg, Priority.DEFAULT, null);
        var response = (string) bytes.get_data ();

        if (msg.status_code < 200 || msg.status_code >= 300) {
            throw new GLib.IOError.FAILED ("HTTP %u: %s".printf (msg.status_code, response));
        }

        var parser = new Json.Parser ();
        parser.load_from_data (response, -1);
        return parser.get_root ().get_object ();
    }

    // Probe — check if Deck is installed
    public async bool probe () {
        try {
            yield send_array_request ("GET", "/boards");
            return true;
        } catch (Error e) {
            return false;
        }
    }

    // Boards
    public async Json.Array get_boards () throws GLib.Error {
        return yield send_array_request ("GET", "/boards");
    }

    public async Json.Object create_board (string title, string color) throws GLib.Error {
        var body = """{"title": "%s", "color": "%s"}""".printf (title, color.replace ("#", ""));
        return yield send_object_request ("POST", "/boards", body);
    }

    public async void update_board (int board_id, string title, string color) throws GLib.Error {
        var body = """{"title": "%s", "color": "%s"}""".printf (title, color.replace ("#", ""));
        yield send_object_request ("PUT", "/boards/%d".printf (board_id), body);
    }

    public async void delete_board (int board_id) throws GLib.Error {
        yield send_object_request ("DELETE", "/boards/%d".printf (board_id));
    }

    // Stacks
    public async Json.Array get_stacks (int board_id, string? if_modified_since = null) throws GLib.Error {
        return yield send_array_request ("GET", "/boards/%d/stacks".printf (board_id), null, if_modified_since);
    }

    public async Json.Object create_stack (int board_id, string title, int order = 0) throws GLib.Error {
        var body = """{"title": "%s", "order": %d}""".printf (title, order);
        return yield send_object_request ("POST", "/boards/%d/stacks".printf (board_id), body);
    }

    public async void update_stack (int board_id, int stack_id, string title, int order = 0) throws GLib.Error {
        var body = """{"title": "%s", "order": %d}""".printf (title, order);
        yield send_object_request ("PUT", "/boards/%d/stacks/%d".printf (board_id, stack_id), body);
    }

    public async void delete_stack (int board_id, int stack_id) throws GLib.Error {
        yield send_object_request ("DELETE", "/boards/%d/stacks/%d".printf (board_id, stack_id));
    }

    // Cards
    public async Json.Object create_card (int board_id, int stack_id, string title, string description = "", string? duedate = null, int order = 0) throws GLib.Error {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("title"); builder.add_string_value (title);
        builder.set_member_name ("type"); builder.add_string_value ("plain");
        builder.set_member_name ("order"); builder.add_int_value (order);
        builder.set_member_name ("description"); builder.add_string_value (description);
        if (duedate != null) {
            builder.set_member_name ("duedate"); builder.add_string_value (duedate);
        }
        builder.end_object ();

        var generator = new Json.Generator ();
        generator.set_root (builder.get_root ());
        var body = generator.to_data (null);

        return yield send_object_request ("POST", "/boards/%d/stacks/%d/cards".printf (board_id, stack_id), body);
    }

    public async void update_card (int board_id, int stack_id, int card_id, string title, string description = "", string? duedate = null, bool archived = false, int order = 0) throws GLib.Error {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("id"); builder.add_int_value (card_id);
        builder.set_member_name ("title"); builder.add_string_value (title);
        builder.set_member_name ("description"); builder.add_string_value (description);
        builder.set_member_name ("stackId"); builder.add_int_value (stack_id);
        builder.set_member_name ("type"); builder.add_string_value ("plain");
        builder.set_member_name ("order"); builder.add_int_value (order);
        builder.set_member_name ("archived"); builder.add_boolean_value (archived);
        if (duedate != null) {
            builder.set_member_name ("duedate"); builder.add_string_value (duedate);
        } else {
            builder.set_member_name ("duedate"); builder.add_null_value ();
        }
        builder.end_object ();

        var generator = new Json.Generator ();
        generator.set_root (builder.get_root ());
        var body = generator.to_data (null);

        yield send_object_request ("PUT", "/cards/%d".printf (card_id), body, true);
    }

    public async void delete_card (int board_id, int stack_id, int card_id) throws GLib.Error {
        yield send_object_request ("DELETE", "/boards/%d/stacks/%d/cards/%d".printf (board_id, stack_id, card_id));
    }
}
