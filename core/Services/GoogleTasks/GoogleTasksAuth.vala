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
 */

/*
 * Google sign-in for a desktop app: the system browser opens Google's consent page and
 * Google redirects back to a one-shot HTTP server on 127.0.0.1 (loopback), which gets
 * the authorization code. PKCE ties the code to this process, and the state value
 * rejects redirects that this login didn't start.
 * https://developers.google.com/identity/protocols/oauth2/native-app
 */
public class Services.GoogleTasksAuth : GLib.Object {
    // Gives up if the user doesn't finish the login in the browser.
    private const uint LOGIN_TIMEOUT_SECONDS = 5 * 60;

    private delegate void FinishFunc ();

    private Soup.Session session;

    public GoogleTasksAuth (Soup.Session session) {
        this.session = session;
    }

    /*
     * Opens the browser and waits for the authorization code, then exchanges it for
     * tokens. Returns the token JSON object, or throws on error or cancellation.
     */
    public async Json.Object authorize (GLib.Cancellable? cancellable) throws GLib.Error {
        string code_verifier = random_string (64);
        string code_challenge = base64url (sha256 (code_verifier));
        string state = random_string (32);

        var server = (Soup.Server) GLib.Object.new (typeof (Soup.Server));
        server.listen_local (0, Soup.ServerListenOptions.IPV4_ONLY);

        string redirect_uri = "";
        foreach (unowned GLib.Uri uri in server.get_uris ()) {
            redirect_uri = "http://127.0.0.1:%d".printf (uri.get_port ());
            break;
        }

        if (redirect_uri == "") {
            server.disconnect ();
            throw new GLib.IOError.FAILED ("Could not start the local sign-in server");
        }

        string? code = null;
        GLib.Error? redirect_error = null;
        bool done = false;
        SourceFunc callback = authorize.callback;

        // Ends the wait once, whatever ends it first: the redirect, a timeout or a cancel.
        FinishFunc finish = () => {
            if (!done) {
                done = true;
                Idle.add (() => {
                    callback ();
                    return GLib.Source.REMOVE;
                });
            }
        };

        server.add_handler (null, (srv, msg, path, query) => {
            if (path != "/") {
                // Browsers also ask for /favicon.ico and similar.
                msg.set_status (404, null);
                return;
            }

            string? received_state = query != null ? query.lookup ("state") : null;
            string? received_code = query != null ? query.lookup ("code") : null;
            string? error = query != null ? query.lookup ("error") : null;

            if (received_state != state) {
                // Not the redirect of this login: ignore it and keep waiting.
                respond (msg, _("This sign-in link isn't valid anymore. Please try again from Planify."));
                return;
            }

            if (error != null) {
                redirect_error = new GLib.IOError.PERMISSION_DENIED (
                    error == "access_denied" ? _("Access was denied") : error
                );
                respond (msg, _("Sign-in was cancelled. You can close this tab."));
            } else if (received_code == null || received_code == "") {
                redirect_error = new GLib.IOError.FAILED ("Google didn't return an authorization code");
                respond (msg, _("Something went wrong. Please try again from Planify."));
            } else {
                code = received_code;
                respond (msg, _("You're signed in. You can close this tab and go back to Planify."));
            }

            finish ();
        });

        uint timeout_id = 0;
        timeout_id = Timeout.add_seconds (LOGIN_TIMEOUT_SECONDS, () => {
            timeout_id = 0;
            redirect_error = new GLib.IOError.TIMED_OUT (_("Sign-in took too long"));
            finish ();
            return GLib.Source.REMOVE;
        });

        ulong cancel_id = 0;
        if (cancellable != null) {
            cancel_id = cancellable.connect (() => {
                redirect_error = new GLib.IOError.CANCELLED ("Sign-in cancelled");
                finish ();
            });
        }

        string auth_url = "%s?client_id=%s&redirect_uri=%s&response_type=code&scope=%s&access_type=offline&prompt=consent&state=%s&code_challenge=%s&code_challenge_method=S256".printf (
            Constants.GOOGLE_AUTH_ENDPOINT,
            escape (Constants.GOOGLE_CLIENT_ID),
            escape (redirect_uri),
            escape (Constants.GOOGLE_SCOPE),
            escape (state),
            escape (code_challenge)
        );

        try {
            AppInfo.launch_default_for_uri (auth_url, null);
        } catch (Error e) {
            redirect_error = e;
            finish ();
        }

        yield;

        // Let the browser get its page before the server goes away.
        Timeout.add_seconds (2, () => {
            server.disconnect ();
            return GLib.Source.REMOVE;
        });

        if (timeout_id != 0) {
            GLib.Source.remove (timeout_id);
        }

        if (cancellable != null && cancel_id != 0) {
            cancellable.disconnect (cancel_id);
        }

        if (redirect_error != null) {
            throw redirect_error;
        }

        return yield exchange_code (code ?? "", code_verifier, redirect_uri);
    }

    private async Json.Object exchange_code (string code, string code_verifier, string redirect_uri) throws GLib.Error {
        string body = "client_id=%s&client_secret=%s&code=%s&code_verifier=%s&grant_type=authorization_code&redirect_uri=%s".printf (
            escape (Constants.GOOGLE_CLIENT_ID),
            escape (Constants.GOOGLE_CLIENT_SECRET),
            escape (code),
            escape (code_verifier),
            escape (redirect_uri)
        );

        return yield post_token (body);
    }

    // Gets a new access token. Throws IOError.PERMISSION_DENIED when the refresh token
    // is no longer valid (revoked, or expired: 7 days while the app is in testing).
    public async Json.Object refresh (string refresh_token) throws GLib.Error {
        string body = "client_id=%s&client_secret=%s&refresh_token=%s&grant_type=refresh_token".printf (
            escape (Constants.GOOGLE_CLIENT_ID),
            escape (Constants.GOOGLE_CLIENT_SECRET),
            escape (refresh_token)
        );

        return yield post_token (body);
    }

    private async Json.Object post_token (string body) throws GLib.Error {
        var message = new Soup.Message ("POST", Constants.GOOGLE_TOKEN_ENDPOINT);
        message.set_request_body_from_bytes ("application/x-www-form-urlencoded", new GLib.Bytes (body.data));

        GLib.Bytes stream;
        try {
            stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
        } catch (Error e) {
            throw new GLib.IOError.NOT_CONNECTED ("Request failed: %s".printf (e.message));
        }

        var parser = new Json.Parser ();
        parser.load_from_data ((string) stream.get_data (), (ssize_t) stream.get_size ());
        var root = parser.get_root ().get_object ();

        if (message.status_code != 200) {
            string error = root.has_member ("error") ? root.get_string_member ("error") : "HTTP %u".printf (message.status_code);
            // Never log the response body: on success it holds the tokens.
            Services.LogService.get_default ().error ("GoogleTasks", "Token request failed: %s".printf (error));

            if (error == "invalid_grant") {
                throw new GLib.IOError.PERMISSION_DENIED ("invalid_grant");
            }

            throw new GLib.IOError.FAILED (error);
        }

        return root;
    }

    private static void respond (Soup.ServerMessage msg, string text) {
        string html = """<!DOCTYPE html><html><head><meta charset="utf-8"><title>Planify</title>
<style>body{font-family:sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0}</style>
</head><body><p>%s</p></body></html>""".printf (GLib.Markup.escape_text (text));
        msg.set_status (200, null);
        msg.set_response ("text/html", Soup.MemoryUse.COPY, html.data);
    }

    private static string escape (string value) {
        return GLib.Uri.escape_string (value, null, false);
    }

    // PKCE verifier and state: unreserved URL characters, from /dev/urandom.
    private static string random_string (int length) {
        const string ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~";
        uint8[] bytes = new uint8[length];

        try {
            var stream = GLib.File.new_for_path ("/dev/urandom").read ();
            size_t read;
            stream.read_all (bytes, out read);
            stream.close ();
        } catch (Error e) {
            for (int i = 0; i < length; i++) {
                bytes[i] = (uint8) GLib.Random.int_range (0, 256);
            }
        }

        var builder = new StringBuilder ();
        foreach (uint8 b in bytes) {
            builder.append_c (ALPHABET[b % ALPHABET.length]);
        }

        return builder.str;
    }

    private static uint8[] sha256 (string text) {
        var checksum = new GLib.Checksum (GLib.ChecksumType.SHA256);
        checksum.update (text.data, text.data.length);

        uint8[] digest = new uint8[32];
        size_t length = digest.length;
        checksum.get_digest (digest, ref length);

        return digest;
    }

    private static string base64url (uint8[] data) {
        return GLib.Base64.encode ((uchar[]) data).replace ("+", "-").replace ("/", "_").replace ("=", "");
    }
}
