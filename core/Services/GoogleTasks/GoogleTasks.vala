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
 * Google Tasks accounts: sign-in, and a valid access token for each request. Syncing
 * tasks lists and tasks is added on top of this.
 */
public class Services.GoogleTasks : GLib.Object {
    private const string USERINFO_URL = "https://www.googleapis.com/oauth2/v2/userinfo";
    // Refresh this long before the access token expires, so a request never uses one
    // that expires on the way.
    private const int64 REFRESH_MARGIN_SECONDS = 60;

    private Soup.Session session;
    private Services.GoogleTasksAuth auth;

    private static GoogleTasks? _instance;
    public static GoogleTasks get_default () {
        if (_instance == null) {
            _instance = new GoogleTasks ();
        }

        return _instance;
    }

    public GoogleTasks () {
        session = new Soup.Session () {
            timeout = Constants.SOUP_TIMEOUT
        };
        session.user_agent = Constants.SOUP_USER_AGENT;
        auth = new Services.GoogleTasksAuth (session);
    }

    /*
     * Signs in with the browser and adds the account. Returns status 409 when the
     * account is already added.
     */
    public async HttpResponse login (GLib.Cancellable? cancellable = null) {
        var response = new HttpResponse ();
        Services.LogService.get_default ().info ("GoogleTasks", "Starting sign-in");

        try {
            var tokens = yield auth.authorize (cancellable);

            var data = new Objects.SourceGoogleTasksData ();
            apply_tokens (data, tokens);

            if (data.refresh_token == "") {
                throw new GLib.IOError.FAILED ("Google didn't return a refresh token");
            }

            yield load_user_info (data);

            if (Services.Store.instance ().source_google_tasks_exists (data.user_email)) {
                response.error_code = 409;
                response.error = _("This Google account is already added");
                return response;
            }

            var source = new Objects.Source ();
            source.id = Util.get_default ().generate_id ();
            source.source_type = SourceType.GOOGLE_TASKS;
            source.display_name = data.user_email;
            source.sync_server = true;
            source.data = data;

            Services.Store.instance ().insert_source (source);

            response.status = true;
            Services.LogService.get_default ().info ("GoogleTasks", "Account added");
        } catch (Error e) {
            bool cancelled = e is GLib.IOError.CANCELLED;

            if (!cancelled) {
                Services.LogService.get_default ().error ("GoogleTasks", "Sign-in failed: %s".printf (e.message));
            }

            response.error_code = cancelled ? -1 : 0;
            response.error = e.message;
        }

        return response;
    }

    /*
     * The access token for a request, refreshed first when it's about to expire. When
     * the refresh token is no longer valid, the account is marked as needing to sign in
     * again and IOError.PERMISSION_DENIED is thrown.
     */
    public async string get_access_token (Objects.Source source) throws GLib.Error {
        var data = source.google_tasks_data;
        int64 now = GLib.get_real_time () / GLib.TimeSpan.SECOND;

        if (data.access_token != "" && data.expires_at - REFRESH_MARGIN_SECONDS > now) {
            return data.access_token;
        }

        try {
            var tokens = yield auth.refresh (data.refresh_token);
            apply_tokens (data, tokens);
            source.save ();
            return data.access_token;
        } catch (Error e) {
            if (e is GLib.IOError.PERMISSION_DENIED) {
                Services.LogService.get_default ().warn ("GoogleTasks", "Sign-in expired, re-login required");
                source.sync_status = new SyncStatus (
                    SyncErrorType.AUTH_EXPIRED,
                    _("Authentication Expired"),
                    _("Your Google session has expired. Please remove and re-add your account in Preferences.")
                );
                source.sync_failed (source.sync_status);
            }

            throw e;
        }
    }

    // Stores the tokens of a token response. A refresh response has no refresh token,
    // so the one already stored is kept.
    private void apply_tokens (Objects.SourceGoogleTasksData data, Json.Object tokens) {
        data.access_token = tokens.get_string_member ("access_token");

        if (tokens.has_member ("refresh_token")) {
            data.refresh_token = tokens.get_string_member ("refresh_token");
        }

        int64 expires_in = tokens.has_member ("expires_in") ? tokens.get_int_member ("expires_in") : 3600;
        data.expires_at = GLib.get_real_time () / GLib.TimeSpan.SECOND + expires_in;
    }

    private async void load_user_info (Objects.SourceGoogleTasksData data) throws GLib.Error {
        var message = new Soup.Message ("GET", USERINFO_URL);
        message.request_headers.append ("Authorization", "Bearer %s".printf (data.access_token));

        var stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
        if (message.status_code != 200) {
            throw new GLib.IOError.FAILED ("Could not read the Google account: HTTP %u".printf (message.status_code));
        }

        var parser = new Json.Parser ();
        parser.load_from_data ((string) stream.get_data (), (ssize_t) stream.get_size ());
        var user = parser.get_root ().get_object ();

        data.user_id = user.has_member ("id") ? user.get_string_member ("id") : "";
        data.user_email = user.has_member ("email") ? user.get_string_member ("email") : "";
        data.user_name = user.has_member ("name") ? user.get_string_member ("name") : data.user_email;
        data.user_avatar = user.has_member ("picture") ? user.get_string_member ("picture") : "";
    }
}
