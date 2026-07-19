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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

public class Services.AI.Claude : GLib.Object {
    private const string API_URL = "https://api.anthropic.com/v1/messages";
    private const string ANTHROPIC_VERSION = "2023-06-01";
    private const string SECRET_SERVICE = "io.github.alainm23.planify.claude";
    private const string SECRET_KEY_ATTR = "service";
    private const string SECRET_KEY_VALUE = "planify-claude-apikey";

    private static Secret.Schema SCHEMA;

    private Soup.Session session;

    public enum Status {
        NOT_CONFIGURED,
        CONFIGURED,
        ERROR
    }

    public Status status { get; private set; default = Status.NOT_CONFIGURED; }
    public string last_error { get; private set; default = ""; }

    public signal void status_changed ();

    private static Claude? _instance;
    public static Claude get_default () {
        if (_instance == null) _instance = new Claude ();
        return _instance;
    }

    static construct {
        SCHEMA = new Secret.Schema (
            SECRET_SERVICE,
            Secret.SchemaFlags.NONE,
            SECRET_KEY_ATTR, Secret.SchemaAttributeType.STRING
        );
    }

    public Claude () {
        session = new Soup.Session ();
        update_status ();
    }

    public string? resolve_api_key () {
        string? env_key = GLib.Environment.get_variable ("ANTHROPIC_API_KEY");
        if (env_key != null && env_key.length > 0) return env_key;

        try {
            return Secret.password_lookup_sync (SCHEMA, null, SECRET_KEY_ATTR, SECRET_KEY_VALUE);
        } catch (Error e) {
            return null;
        }
    }

    public bool is_configured () {
        return resolve_api_key () != null;
    }

    public void store_api_key (string api_key) throws Error {
        Secret.password_store_sync (SCHEMA, Secret.COLLECTION_DEFAULT,
            "Planify Claude API Key", api_key, null,
            SECRET_KEY_ATTR, SECRET_KEY_VALUE);
        update_status ();
    }

    public void clear_api_key () throws Error {
        Secret.password_clear_sync (SCHEMA, null, SECRET_KEY_ATTR, SECRET_KEY_VALUE);
        update_status ();
    }

    public string get_model () {
        return Services.Settings.get_default ().settings.get_string ("claude-model");
    }

    private void update_status () {
        status = is_configured () ? Status.CONFIGURED : Status.NOT_CONFIGURED;
        status_changed ();
    }

    public async string? send_request (string prompt) {
        string? api_key = resolve_api_key ();
        if (api_key == null) {
            status = Status.NOT_CONFIGURED;
            status_changed ();
            return null;
        }

        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("model");
        builder.add_string_value (get_model ());
        builder.set_member_name ("max_tokens");
        builder.add_int_value (2048);
        builder.set_member_name ("messages");
        builder.begin_array ();
        builder.begin_object ();
        builder.set_member_name ("role");
        builder.add_string_value ("user");
        builder.set_member_name ("content");
        builder.add_string_value (prompt);
        builder.end_object ();
        builder.end_array ();
        builder.end_object ();

        var generator = new Json.Generator ();
        generator.set_root (builder.get_root ());
        string body = generator.to_data (null);

        var message = new Soup.Message ("POST", API_URL);
        message.request_headers.append ("x-api-key", api_key);
        message.request_headers.append ("anthropic-version", ANTHROPIC_VERSION);
        message.set_request_body_from_bytes ("application/json", new GLib.Bytes (body.data));

        try {
            GLib.Bytes stream = yield session.send_and_read_async (
                message, GLib.Priority.DEFAULT, null);
            string response_body = (string) stream.get_data ();

            var parser = new Json.Parser ();
            parser.load_from_data (response_body);
            var root = parser.get_root ().get_object ();

            if (root.has_member ("error")) {
                last_error = root.get_object_member ("error").get_string_member ("message");
                status = Status.ERROR;
                status_changed ();
                return null;
            }

            last_error = "";
            status = Status.CONFIGURED;
            status_changed ();

            return root
                .get_array_member ("content")
                .get_object_element (0)
                .get_string_member ("text");
        } catch (Error e) {
            last_error = e.message;
            status = Status.ERROR;
            status_changed ();
            return null;
        }
    }

    public async bool ping () {
        string? result = yield send_request ("Reply with only the word: OK");
        return result != null;
    }
}
