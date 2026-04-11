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

    private Gtk.Stack stack;
    private Adw.EntryRow token_entry;
    private Widgets.LoadingButton login_button;
    private Widgets.LoadingButton oauth_button;
    private Gtk.Button cancel_button;
    private string oauth_state;

    private Objects.Source? migrate_source = null;

    public TodoistSetup (Adw.PreferencesDialog preferences_dialog, Accounts accounts_page) {
        Object (
            preferences_dialog: preferences_dialog,
            accounts_page: accounts_page,
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

        stack.add_named (build_main_page (), "main");
        stack.add_named (build_token_page (), "token");
        stack.add_named (accounts_page.build_sync_page (), "loading");

        stack.visible_child_name = "main";

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

        // Listen for OAuth callback
        signal_map[Services.EventBus.get_default ().oauth_callback.connect ((uri) => {
            handle_oauth_callback (uri);
        })] = Services.EventBus.get_default ();

        destroy.connect (() => {
            clean_up ();
        });
    }

    private Gtk.Widget build_main_page () {
        var icon = new Gtk.Image.from_icon_name ("todoist") {
            pixel_size = 64,
            margin_bottom = 6
        };

        var title_label = new Gtk.Label (_("Connect to Todoist")) {
            css_classes = { "font-bold", "title-2" },
            margin_top = 24
        };

        var description_label = new Gtk.Label (_("Sign in with your Todoist account to sync your tasks")) {
            css_classes = { "dimmed", "caption" },
            wrap = true,
            justify = CENTER,
            max_width_chars = 40
        };

        oauth_button = new Widgets.LoadingButton.with_label (_("Sign in with Browser")) {
            css_classes = { "suggested-action", "pill" },
            halign = CENTER,
            margin_top = 12
        };

        cancel_button = new Gtk.Button.with_label (_("Cancel")) {
            css_classes = { "flat", "pill" },
            halign = CENTER,
            visible = false
        };

        var token_button = new Gtk.Button.with_label (_("Use API Token instead")) {
            css_classes = { "flat", "caption", "accent" },
            halign = CENTER,
            margin_top = 6
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            vexpand = true,
            hexpand = true,
            valign = CENTER,
            halign = CENTER,
            margin_bottom = 32
        };

        content_box.append (icon);
        content_box.append (title_label);
        content_box.append (description_label);
        content_box.append (oauth_button);
        content_box.append (cancel_button);
        content_box.append (token_button);

        signal_map[oauth_button.clicked.connect (() => {
            start_oauth_flow ();
        })] = oauth_button;

        signal_map[cancel_button.clicked.connect (() => {
            cancel_oauth_flow ();
        })] = cancel_button;

        signal_map[token_button.clicked.connect (() => {
            stack.visible_child_name = "token";
        })] = token_button;

        return content_box;
    }

    private Gtk.Widget build_token_page () {
        var icon = new Gtk.Image.from_icon_name ("key4-symbolic") {
            pixel_size = 48,
            css_classes = { "dimmed" }
        };

        var title_label = new Gtk.Label (_("API Token")) {
            css_classes = { "font-bold", "title-3" },
            margin_top = 12
        };

        var description_label = new Gtk.Label (_("Connect using your personal Todoist API token")) {
            css_classes = { "dimmed", "caption" },
            wrap = true,
            justify = CENTER,
            max_width_chars = 40
        };

        var header_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            halign = CENTER,
            margin_bottom = 18
        };
        header_box.append (icon);
        header_box.append (title_label);
        header_box.append (description_label);

        token_entry = new Adw.EntryRow ();
        token_entry.title = _("Paste your API token");

        var entries_group = new Adw.PreferencesGroup ();
        entries_group.add (token_entry);

        login_button = new Widgets.LoadingButton.with_label (_("Connect")) {
            margin_top = 16,
            sensitive = false,
            css_classes = { "suggested-action", "pill" },
            halign = CENTER
        };

        var step1_label = new Gtk.Label (_("1. Go to Todoist → Settings → Integrations → Developer")) {
            wrap = true,
            xalign = 0
        };

        var step2_label = new Gtk.Label (_("2. Copy your API token")) {
            wrap = true,
            xalign = 0
        };

        var step3_label = new Gtk.Label (_("3. Paste it in the field above")) {
            wrap = true,
            xalign = 0
        };

        var steps_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 8) {
            margin_top = 8,
            margin_bottom = 8,
            margin_start = 12,
            margin_end = 12
        };
        steps_box.append (step1_label);
        steps_box.append (step2_label);
        steps_box.append (step3_label);

        var instructions_group = new Adw.PreferencesGroup () {
            margin_top = 18
        };
        instructions_group.title = _("How to get your token");
        instructions_group.add (steps_box);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            vexpand = true,
            hexpand = true,
            margin_start = 12,
            margin_end = 12,
            margin_top = 24
        };
        content_box.append (header_box);
        content_box.append (entries_group);
        content_box.append (login_button);
        content_box.append (instructions_group);

        signal_map[token_entry.changed.connect (() => {
            login_button.sensitive = token_entry.text != null && token_entry.text != "";
        })] = token_entry;

        signal_map[login_button.clicked.connect (() => {
            on_token_login_clicked ();
        })] = login_button;

        return content_box;
    }

    private void start_oauth_flow () {
        oauth_state = Util.get_default ().generate_string ();

        string oauth_url = "https://todoist.com/oauth/authorize?client_id=%s&scope=%s&state=%s&redirect_uri=%s".printf (
            Constants.TODOIST_CLIENT_ID,
            Constants.TODOIST_SCOPE,
            oauth_state,
            Constants.TODOIST_REDIRECT_URI
        );

        oauth_button.is_loading = true;
        oauth_button.sensitive = false;
        cancel_button.visible = true;
        title = _("Waiting for login…");

        try {
            AppInfo.launch_default_for_uri (oauth_url, null);
        } catch (Error e) {
            warning ("Error opening browser: %s", e.message);
            oauth_button.is_loading = false;
            cancel_button.visible = false;
            title = _("Todoist");
        }
    }

    private void cancel_oauth_flow () {
        oauth_button.is_loading = false;
        oauth_button.sensitive = true;
        cancel_button.visible = false;
        title = _("Todoist");
    }

    private void handle_oauth_callback (string uri) {
        var parts = uri.replace ("planify://", "").split ("?", 2);
        string query = parts.length > 1 ? parts[1] : "";

        string code = "";
        foreach (string param in query.split ("&")) {
            var kv = param.split ("=", 2);
            if (kv.length == 2 && kv[0] == "code") {
                code = kv[1];
            }
        }

        if (code == "") {
            oauth_button.is_loading = false;
            title = _("Todoist");
            return;
        }

        title = _("Synchronizing…");
        stack.visible_child_name = "loading";

        Services.Todoist.get_default ().login.begin (
            "%s?code=%s".printf (Constants.TODOIST_REDIRECT_URI, code), migrate_source, (obj, res) => {
                HttpResponse response = Services.Todoist.get_default ().login.end (res);
                preferences_dialog.pop_subpage ();
                verify_response (response);
            }
        );
    }

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
