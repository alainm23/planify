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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Alain M. <alainmh23@gmail.com>
 */

public class Dialogs.Preferences.Pages.TodoistSetup : Adw.NavigationPage {

    public Accounts accounts_page { get; construct; }
    public bool use_webkit { get; construct; }

    private Gtk.Stack todoist_stack;
    private Adw.EntryRow token_entry;
    private Widgets.LoadingButton login_button;

    public TodoistSetup (Accounts accounts_page) {
        Object (accounts_page: accounts_page, use_webkit: false);
    }

#if USE_WEBKITGTK
    public TodoistSetup.with_webkit (Accounts accounts_page) {
        Object (accounts_page: accounts_page, use_webkit: true);
    }
#endif

    construct {
        title = "Todoist Setup";
        setup_ui ();
        connect_signals ();
    }

    ~TodoistSetup () {
        print ("Destroying Dialogs.Preferences.Pages.TodoistSetup\n");
    }

    private void setup_ui () {
        var header = new Dialogs.Preferences.SettingsHeader (_("Todoist Setup"));
        header.back_activated.connect (() => accounts_page.pop_subpage ());

        todoist_stack = new Gtk.Stack () {
            vexpand = true,
            hexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        var token_page = build_token_page ();
        var sync_page = build_sync_page ();

        todoist_stack.add_named (token_page, "token");
        todoist_stack.add_named (sync_page, "loading");

#if USE_WEBKITGTK
        if (use_webkit) {
            var webview_page = build_webview_page (header);
            todoist_stack.add_named (webview_page, "web_view");
            todoist_stack.visible_child_name = "web_view";
        } else {
            todoist_stack.visible_child_name = "token";
        }
#else
        todoist_stack.visible_child_name = "token";
#endif

        var scrolled_window = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
            child = todoist_stack
        };

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (header);
        toolbar_view.content = scrolled_window;

        child = toolbar_view;
    }

    private void connect_signals () {
        if (token_entry != null) {
            token_entry.changed.connect (() => {
                login_button.sensitive = token_entry.text != null && token_entry.text != "";
            });

            login_button.clicked.connect (() => on_token_login_clicked ());
        }
    }

    private Gtk.Widget build_token_page () {
        token_entry = new Adw.EntryRow ();
        token_entry.title = _("Token");

        var entries_group = new Adw.PreferencesGroup ();
        entries_group.add (token_entry);

        var message_label = new Gtk.Label ("%s\n\n%s\n%s\n%s".printf (
                                            _("How to get your token?"),
                                            _("1. Go to Todoist → Settings → Integrations → Developer"),
                                            _("2. Find 'API token' and copy your token"),
                                            _("3. Paste it in the field above"))) {
            wrap = true,
            css_classes = { "dimmed", "caption" }
        };

        var message_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12,
        };
        message_box.append (message_label);

        var message_card = new Adw.Bin () {
            child = message_box,
            css_classes = { "card" },
            margin_top = 12
        };

        login_button = new Widgets.LoadingButton.with_label (_("Connect with Token")) {
            margin_top = 12,
            sensitive = false,
            css_classes = { "suggested-action" }
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            vexpand = true,
            hexpand = true
        };
        content_box.append (entries_group);
        content_box.append (login_button);
        content_box.append (message_card);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 400,
            margin_start = 24,
            margin_end = 24,
            margin_top = 12,
            child = content_box
        };

        return content_clamp;
    }

#if USE_WEBKITGTK
    private Gtk.Widget build_webview_page (Dialogs.Preferences.SettingsHeader header) {
        string oauth_open_url = "https://todoist.com/oauth/authorize?client_id=%s&scope=%s&state=%s";
        string state = Util.get_default ().generate_string ();
        oauth_open_url = oauth_open_url.printf (Constants.TODOIST_CLIENT_ID, Constants.TODOIST_SCOPE, state);

        WebKit.WebView webview = new WebKit.WebView ();
        webview.zoom_level = 0.85;
        webview.vexpand = true;
        webview.hexpand = true;

        WebKit.WebContext.get_default ().set_preferred_languages (GLib.Intl.get_language_names ());

        var banner = new Adw.Banner ("Trouble logging in? Use your token instead") {
            revealed = true,
            button_label = _("Enter token")
        };

        var webview_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        webview_box.append (banner);
        webview_box.append (webview);

        banner.button_clicked.connect (() => {
            todoist_stack.visible_child_name = "token";
        });

        webview.load_uri (oauth_open_url);

        webview.load_changed.connect ((load_event) => {
            var uri = webview.get_uri ();
            var redirect_uri = "https://github.com/alainm23/planner";

            if ((redirect_uri + "?code=" in uri) && ("&state=%s".printf (state) in uri)) {
                header.title = _("Synchronizing…");
                todoist_stack.visible_child_name = "loading";

                Services.Todoist.get_default ().login.begin (uri, (obj, res) => {
                    HttpResponse response = Services.Todoist.get_default ().login.end (res);
                    accounts_page.pop_subpage ();
                    webview.get_network_session ().get_website_data_manager ().clear.begin (WebKit.WebsiteDataTypes.ALL, 0, null);
                    verify_response (response);
                });
            }

            if (redirect_uri + "?error=access_denied" in uri) {
                debug ("access_denied");
                webview.get_network_session ().get_website_data_manager ().clear.begin (WebKit.WebsiteDataTypes.ALL, 0, null);
                accounts_page.pop_subpage ();
            }

            if (load_event == WebKit.LoadEvent.FINISHED) {
                header.title = _("Please Enter Your Credentials");
            } else if (load_event == WebKit.LoadEvent.STARTED) {
                header.title = _("Loading…");
            }
        });

        webview.load_failed.connect ((load_event, failing_uri, _error) => {
            var error = (GLib.Error) _error;
            warning ("Loading uri '%s' failed, error : %s", failing_uri, error.message);

            if (GLib.strcmp (failing_uri, oauth_open_url) == 0) {
                header.title = _("Network Is Not Available");

                var toast = new Adw.Toast (_("Network Is Not Available"));
                toast.button_label = _("Ok");
                toast.timeout = 0;

                toast.button_clicked.connect (() => accounts_page.pop_subpage ());
                accounts_page.add_toast (toast);
            }

            return true;
        });

        return webview_box;
    }
#endif

    private Gtk.Widget build_sync_page () {
        var image = new Adw.Spinner () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            height_request = 64,
            width_request = 64
        };

        var label = new Gtk.Label (_("Planify is syncing your tasks, this may take a few minutes")) {
            css_classes = { "dimmed" },
            wrap = true,
            halign = Gtk.Align.CENTER,
            justify = Gtk.Justification.CENTER,
            margin_start = 12,
            margin_end = 12,
        };

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 24) {
            margin_top = 128,
            margin_start = 64,
            margin_end = 64
        };
        box.append (image);
        box.append (label);

        return box;
    }

    private void on_token_login_clicked () {
        todoist_stack.visible_child_name = "loading";

        Services.Todoist.get_default ().login_token.begin (token_entry.text, (obj, res) => {
            HttpResponse response = Services.Todoist.get_default ().login_token.end (res);
            accounts_page.pop_subpage ();
            verify_response (response);
        });
    }

    private void verify_response (HttpResponse response) {
        if (response.status) return;

        if (response.error_code != 409) {
            accounts_page.show_message_error (response.error_code, response.error.strip ());
        } else {
            var toast = new Adw.Toast (response.error.strip ());
            toast.timeout = 3;
            accounts_page.add_toast (toast);
        }
    }
}

