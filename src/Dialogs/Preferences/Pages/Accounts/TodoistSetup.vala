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

public class Dialogs.Preferences.Pages.TodoistSetup : Dialogs.Preferences.Pages.BasePage {
    public Accounts accounts_page { get; construct; }
    public bool use_webkit { get; construct; }

    private Gtk.Stack stack;
    private Adw.EntryRow token_entry;
    private Widgets.LoadingButton login_button;
    
    private Objects.Source? migrate_source = null;

    public TodoistSetup (Adw.PreferencesDialog preferences_dialog, Accounts accounts_page) {
        Object (
            preferences_dialog: preferences_dialog,
            accounts_page: accounts_page,
            use_webkit: false,
            title: _("Todoist")
        );
    }

    public TodoistSetup.with_webkit (Adw.PreferencesDialog preferences_dialog, Accounts accounts_page) {
        Object (
            preferences_dialog: preferences_dialog,
            accounts_page: accounts_page,
            use_webkit: true,
            title: _("Todoist")
        );
    }

    ~TodoistSetup () {
        debug ("Destroying - Dialogs.Preferences.Pages.TodoistSetup\n");
    }

    construct {
        stack = new Gtk.Stack () {
            vexpand = true,
            hexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        stack.add_named (build_token_page (), "token");
        stack.add_named (accounts_page.build_sync_page (), "loading");

#if USE_WEBKITGTK
        if (use_webkit) {
            stack.add_named (build_webview_page (), "web_view");
            stack.visible_child_name = "web_view";
        } else {
            stack.visible_child_name = "token";
        }
#else
        stack.visible_child_name = "token";
#endif

        var scrolled_window = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
            child = stack
        };

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (new Adw.HeaderBar ());
        toolbar_view.content = scrolled_window;

        child = toolbar_view;

        destroy.connect (() => {
            clean_up ();
        });
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
            hexpand = true,
            margin_start = 12,
            margin_end = 12
        };
        content_box.append (entries_group);
        content_box.append (login_button);
        content_box.append (message_card);

        signal_map[token_entry.changed.connect (() => {
            login_button.sensitive = token_entry.text != null && token_entry.text != "";
        })] = token_entry;

        signal_map[login_button.clicked.connect (() => {
            on_token_login_clicked ();
        })] = login_button;
        

        return content_box;
    }

#if USE_WEBKITGTK
    private Gtk.Widget build_webview_page () {
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

        signal_map[banner.button_clicked.connect (() => {
            stack.visible_child_name = "token";
        })] = banner;

        webview.load_uri (oauth_open_url);

        webview.load_changed.connect ((load_event) => {
            var uri = webview.get_uri ();
            var redirect_uri = "https://github.com/alainm23/planner";

            if ((redirect_uri + "?code=" in uri) && ("&state=%s".printf (state) in uri)) {
                title = _("Synchronizing…");
                stack.visible_child_name = "loading";

                Services.Todoist.get_default ().login.begin (uri, migrate_source, (obj, res) => {
                    HttpResponse response = Services.Todoist.get_default ().login.end (res);
                    preferences_dialog.pop_subpage ();
                    webview.get_network_session ().get_website_data_manager ().clear.begin (WebKit.WebsiteDataTypes.ALL, 0, null);
                    verify_response (response);
                });
            }

            if (redirect_uri + "?error=access_denied" in uri) {
                debug ("access_denied");
                webview.get_network_session ().get_website_data_manager ().clear.begin (WebKit.WebsiteDataTypes.ALL, 0, null);
                preferences_dialog.pop_subpage ();
            }

            if (load_event == WebKit.LoadEvent.FINISHED) {
                title = _("Please Enter Your Credentials");
            } else if (load_event == WebKit.LoadEvent.STARTED) {
                title = _("Loading…");
            }
        });

        webview.load_failed.connect ((load_event, failing_uri, _error) => {
            var error = (GLib.Error) _error;
            warning ("Loading uri '%s' failed, error : %s", failing_uri, error.message);

            if (GLib.strcmp (failing_uri, oauth_open_url) == 0) {
                title = _("Network Is Not Available");

                var toast = new Adw.Toast (_("Network Is Not Available"));
                toast.button_label = _("Ok");
                toast.timeout = 0;

                toast.button_clicked.connect (() => preferences_dialog.pop_subpage ());
                preferences_dialog.add_toast (toast);
            }

            return true;
        });

        return webview_box;
    }
#endif

    private void on_token_login_clicked () {
        stack.visible_child_name = "loading";

        Services.Todoist.get_default ().login_token.begin (token_entry.text, migrate_source, (obj, res) => {
            HttpResponse response = Services.Todoist.get_default ().login_token.end (res);
            preferences_dialog.pop_subpage ();
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
            preferences_dialog.add_toast (toast);
        }
    }

    public void set_migrate_mode (Objects.Source source) {
        migrate_source = source;
    }
}

