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

public class Dialogs.TodoistOAuth : Gtk.Dialog {
    public string view { get; construct; }
    private WebKit.WebView webview;

    private const string OAUTH_OPEN_URL = "https://todoist.com/oauth/authorize?client_id=b0dd7d3714314b1dbbdab9ee03b6b432&scope=data:read_write,data:delete,project:delete&state=XE3K-4BBL-4XLG-UDS8"; // vala-lint=line-length

    public TodoistOAuth (string view="welcome") {
        Object (
            transient_for: Planner.instance.main_window,
            deletable: true,
            resizable: true,
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            modal: true,
            view: view
        );
    }

    construct {
        height_request = 700;
        width_request = 600;
        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);

        var info_label = new Gtk.Label (_("Loading…"));

        var spinner = new Gtk.Spinner ();
        spinner.get_style_context ().add_class ("text-color");
        spinner.start ();

        var container_grid = new Gtk.Grid ();
        container_grid.border_width = 6;
        container_grid.column_spacing = 6;
        container_grid.valign = Gtk.Align.CENTER;
        container_grid.add (spinner);
        container_grid.add (info_label);

        webview = new WebKit.WebView ();
        webview.expand = true;
        WebKit.WebContext.get_default ().set_preferred_languages (GLib.Intl.get_language_names ());

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (webview);

        webview.load_uri (OAUTH_OPEN_URL);

        // Alert
        var alert_view = new Granite.Widgets.AlertView (
            _("Network Is Not Available"),
            _("Connect to the Internet to connect with Todoist"),
            "network-error"
        );

        // Spinner
        var spinner_loading = new Gtk.Spinner ();
        spinner_loading.valign = Gtk.Align.CENTER;
        spinner_loading.halign = Gtk.Align.CENTER;
        spinner_loading.width_request = 50;
        spinner_loading.height_request = 50;
        spinner_loading.active = true;
        spinner_loading.start ();

        var stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        stack.add_named (scrolled, "web_view");
        stack.add_named (alert_view, "error_view");
        stack.add_named (spinner_loading, "spinner_loading");

        get_content_area ().pack_start (stack, true, true, 0);

        use_header_bar = 1;
        var header_bar = (Gtk.HeaderBar) get_header_bar ();
        header_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        header_bar.get_style_context ().add_class ("oauth-dialog");
        header_bar.custom_title = container_grid;

        webview.load_changed.connect ((load_event) => {
            var redirect_uri = webview.get_uri ();
            if (("https://github.com/alainm23/planner?code=" in redirect_uri) &&
                ("&state=XE3K-4BBL-4XLG-UDS8" in redirect_uri)) {
                info_label.label = _("Synchronizing… Wait a moment please.");
                stack.visible_child_name = "spinner_loading";
                webview.stop_loading ();
                Planner.todoist.get_todoist_token (redirect_uri, view);
            }

            if ("https://github.com/alainm23/planner?error=access_denied" in redirect_uri) {
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

        Planner.todoist.first_sync_finished.connect (() => {
            destroy ();
        });
    }
}
