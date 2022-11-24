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

public class Dialogs.TodoistOAuth : Adw.Window {
    private WebKit.WebView webview;
    private string OAUTH_OPEN_URL = "https://todoist.com/oauth/authorize?client_id=%s&scope=%s&state=%s"; // vala-lint=line-length
    private string STATE = Util.get_default ().generate_string ();

    public TodoistOAuth () {
        Object (
            transient_for: (Gtk.Window) Planner.instance.main_window,
            deletable: true,
            // resizable: true,
            destroy_with_parent: true,
            // window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            modal: true,
            title: _("Todoist Sync"),
            height_request: 500,
            width_request: 425
        );
    }

    construct {
        OAUTH_OPEN_URL = OAUTH_OPEN_URL.printf (Constants.TODOIST_CLIENT_ID, Constants.TODOIST_SCOPE, STATE);

        var info_label = new Gtk.Label (_("Loading…"));

        var spinner = new Gtk.Spinner ();
        spinner.add_css_class ("text-color");
        spinner.start ();

        var container_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        container_grid.valign = Gtk.Align.CENTER;
        container_grid.append (spinner);
        container_grid.append (info_label);

        webview = new WebKit.WebView ();
        webview.vexpand = true;
        webview.hexpand = true;

        // WebKit.WebContext.get_default ().set_preferred_languages (GLib.Intl.get_language_names ());
        // WebKit.WebContext.get_default ().set_tls_errors_policy (WebKit.TLSErrorsPolicy.IGNORE);

        var scrolled = new Gtk.ScrolledWindow ();
        scrolled.child = webview;

        webview.load_uri (OAUTH_OPEN_URL);

        // Loading
        var spinner_loading = new Gtk.Spinner ();
        spinner_loading.valign = Gtk.Align.CENTER;
        spinner_loading.halign = Gtk.Align.CENTER;
        spinner_loading.width_request = 50;
        spinner_loading.height_request = 50;
        spinner_loading.start ();
        
        var stack = new Gtk.Stack ();
        stack.vexpand = true;
        stack.hexpand = true;
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        stack.add_named (scrolled, "web_view");
        stack.add_named (spinner_loading, "spinner-view");

        var header = new Adw.HeaderBar ();
        header.add_css_class (Granite.STYLE_CLASS_FLAT);
        header.title_widget = container_grid;

        var main_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_grid.append (header);
        main_grid.append (stack);

        content = main_grid;

        webview.load_changed.connect ((load_event) => {
            var redirect_uri = webview.get_uri ();
            if (("https://github.com/alainm23/planner?code=" in redirect_uri) &&
                ("&state=%s".printf (STATE) in redirect_uri)) {
                info_label.label = _("Synchronizing… Wait a moment please.");
                webview.stop_loading ();
                Services.Todoist.get_default ().get_todoist_token (redirect_uri);
            }

            if ("https://github.com/alainm23/planner?error=access_denied" in redirect_uri) {
                debug ("access_denied");
                destroy ();
            }

            if (load_event == WebKit.LoadEvent.FINISHED) {
                info_label.label = _("Please enter your credentials…");
                spinner.stop ();
                spinner.hide ();

                return;
            }

            if (load_event == WebKit.LoadEvent.STARTED) {
                info_label.label = _("Loading…");
                spinner.start ();
                spinner.show ();

                return;
            }

            return;
        });

        webview.load_failed.connect ((load_event, failing_uri, _error) => {
            var error = (GLib.Error)_error;
            warning ("Loading uri '%s' failed, error : %s", failing_uri, error.message);
            if (GLib.strcmp (failing_uri, OAUTH_OPEN_URL) == 0) {
                info_label.label = _("Network Is Not Available");
                stack.visible_child_name = "error_view";
            }

            return true;
        });

        Services.Todoist.get_default ().first_sync_started.connect (() => {
            stack.visible_child_name = "spinner-view";
        });

        Services.Todoist.get_default ().first_sync_finished.connect (() => {
            destroy ();
        });
    }
}