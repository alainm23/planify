/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Dialogs.GoogleOAuth : Adw.Window {
    private WebKit.WebView webview;

    private const string CLIENT_ID = "507369778499-aqom2u384dbbqdk9j6fhrh32gfjevmnr.apps.googleusercontent.com";
    private const string CLIENT_SECRET = "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";
    private const string REDIRECT_URI = "https://github.com/alainm23/planify";
    private const string AUTH_ENDPOINT = "https://accounts.google.com/o/oauth2/auth";
    private const string TOKEN_ENDPOINT = "https://accounts.google.com/o/oauth2/token";
    private const string SCOPE = "https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/tasks https://www.googleapis.com/auth/tasks.readonly";

    private uint timeout_id = 0;

    public GoogleOAuth () {
        Object (
            transient_for: (Gtk.Window) Planner.instance.main_window,
            deletable: true,
            destroy_with_parent: true,
            modal: true,
            title: _("Todoist Sync"),
            height_request: 575,
            width_request: 475
        );
    }

    construct {
        string authorizationUrl = AUTH_ENDPOINT + "?client_id=" + CLIENT_ID +
                                  "&redirect_uri=" + REDIRECT_URI +
                                  "&scope=" + SCOPE +
                                  "&prompt=consent" +
                                  "&access_type=offline" +
                                  "&response_type=code";

        var info_label = new Gtk.Label (_("Loading"));

        var spinner = new Gtk.Spinner ();
        spinner.add_css_class ("text-color");
        spinner.start ();

        var container_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        container_grid.valign = Gtk.Align.CENTER;
        container_grid.append (spinner);
        container_grid.append (info_label);

        webview = new WebKit.WebView ();
        webview.zoom_level = 0.75;
        webview.vexpand = true;
        webview.hexpand = true;

        webview.load_uri (authorizationUrl);

        var sync_image = new Widgets.DynamicIcon () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER
        };

        sync_image.update_icon_name ("planner-cloud");
        sync_image.size = 128;

        // Loading
        var progress_bar = new Gtk.ProgressBar () {
            margin_top = 6
        };

        var sync_label = new Gtk.Label (_("Planner is sync your tasks, this may take a few minutes."));
        sync_label.wrap = true;
        sync_label.justify = Gtk.Justification.CENTER;
        sync_label.margin_top = 12;
        sync_label.margin_start = 12;
        sync_label.margin_end = 12;

        var sync_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 24,
            margin_start = 64,
            margin_end = 64
        };
        sync_box.append (sync_image);
        sync_box.append (progress_bar);
        sync_box.append (sync_label);

        var stack = new Gtk.Stack ();
        stack.vexpand = true;
        stack.hexpand = true;
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        stack.add_named (webview, "web_view");
        stack.add_named (sync_box, "spinner-view");

        var scrolled = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };

        scrolled.child = stack;

        var header = new Adw.HeaderBar ();
        header.add_css_class (Granite.STYLE_CLASS_FLAT);
        header.title_widget = container_grid;

        var main_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_grid.append (header);
        main_grid.append (scrolled);

        content = main_grid;

        webview.load_changed.connect ((load_event) => {
            var redirect_uri = webview.get_uri ();
            
            if (redirect_uri.has_prefix (REDIRECT_URI)) {
                string authorization_code = extractAuthorizationCode(redirect_uri);
                get_token (authorization_code);
                spinner.stop ();
            }

            if (load_event == WebKit.LoadEvent.FINISHED) {
                info_label.label = _("Please enter your credentials");
                spinner.stop ();
                spinner.hide ();
                return;
            }

            if (load_event == WebKit.LoadEvent.STARTED) {
                info_label.label = _("Loading");
                spinner.start ();
                spinner.show ();
                return;
            }

            return;
        });

        webview.load_failed.connect ((load_event, failing_uri, _error) => {
            var error = (GLib.Error)_error;
            warning ("Loading uri '%s' failed, error : %s", failing_uri, error.message);
            if (GLib.strcmp (failing_uri, authorizationUrl) == 0) {
                info_label.label = _("Network Is Not Available");
                stack.visible_child_name = "error_view";
            }

            return true;
        });

        Services.GoogleTasks.get_default ().first_sync_started.connect (() => {
            stack.visible_child_name = "spinner-view";
        });

        Services.GoogleTasks.get_default ().first_sync_finished.connect (() => {
            hide_destroy ();
        });

        Services.GoogleTasks.get_default ().first_sync_progress.connect ((progress) => {
            progress_bar.fraction = progress;
        });
    }

    private string? extractAuthorizationCode(string uri) {
        string[] query = uri.split("?");
    
        if (query.length >= 2) {
            string[] params = query[1].split("&");
            
            foreach (string param in params) {
                string[] keyValue = param.split("=");
                
                if (keyValue.length >= 2 && keyValue[0] == "code") {
                    return keyValue[1];
                }
            }
        }
        
        return null;
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }

    private void get_token (string authorization_code) {
        if (timeout_id != 0) {
            GLib.Source.remove (timeout_id);
        }

        timeout_id = Timeout.add (1000, () => {
            timeout_id = 0;

            Services.GoogleTasks.get_default ().request_access_token.begin (authorization_code, (obj, res) => {
                Services.GoogleTasks.get_default ().request_access_token.end (res);
            });

            return GLib.Source.REMOVE;
        });
    }
}