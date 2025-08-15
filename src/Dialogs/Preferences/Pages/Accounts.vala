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

public class Dialogs.Preferences.Pages.Accounts : Adw.Bin {
    private Gtk.Stack todoist_stack;

    public signal void pop_subpage ();
    public signal void push_subpage (Adw.NavigationPage page);
    public signal void add_toast (Adw.Toast toast);

    ~Accounts () {
        print ("Destroying Dialogs.Preferences.Pages.Accounts\n");
    }

    construct {
        var settings_header = new Dialogs.Preferences.SettingsHeader (_("Accounts"));

        var todoist_item = new Widgets.ContextMenu.MenuItem (_("Todoist"));
        var nextcloud_item = new Widgets.ContextMenu.MenuItem (_("Nextcloud"));

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (todoist_item);
        menu_box.append (nextcloud_item);

        var popover = new Gtk.Popover () {
            has_arrow = true,
            child = menu_box,
            width_request = 250,
            position = Gtk.PositionType.BOTTOM
        };

        var add_source_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            icon_name = "plus-large-symbolic",
            css_classes = { "flat" },
            tooltip_markup = _("Add Source"),
            popover = popover
        };

        var sources_group = new Layouts.HeaderItem (_("Accounts")) {
            card = true,
            reveal = true,
            listbox_margin_top = 6
        };

        sources_group.add_widget_end (add_source_button);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        content_box.append (sources_group);
        content_box.append (new Gtk.Label (_("You can sort your accounts by dragging and dropping")) {
            css_classes = { "caption", "dimmed" },
            halign = START,
            margin_start = 12
        });

        var content_clamp = new Adw.Clamp () {
            maximum_size = 600,
            margin_start = 24,
            margin_end = 24
        };

        content_clamp.child = content_box;

        var toolbar_view = new Adw.ToolbarView () {
            content = content_clamp
        };
        toolbar_view.add_top_bar (settings_header);

        child = toolbar_view;

        Gee.HashMap<string, Widgets.SourceRow> sources_hashmap = new Gee.HashMap<string, Widgets.SourceRow> ();
        foreach (Objects.Source source in Services.Store.instance ().sources) {
            if (!sources_hashmap.has_key (source.id)) {
                sources_hashmap[source.id] = new Widgets.SourceRow (source);
                sources_group.add_child (sources_hashmap[source.id]);
            }
        }

        Services.Store.instance ().source_added.connect ((source) => {
            if (!sources_hashmap.has_key (source.id)) {
                sources_hashmap[source.id] = new Widgets.SourceRow (source);
                sources_group.add_child (sources_hashmap[source.id]);
            }
        });

        Services.Store.instance ().source_deleted.connect ((source) => {
            if (sources_hashmap.has_key (source.id)) {
                sources_hashmap[source.id].hide_destroy ();
                sources_hashmap.unset (source.id);
            }
        });

        settings_header.back_activated.connect (() => {
            pop_subpage ();
        });

        todoist_item.clicked.connect (() => {
            push_subpage (get_oauth_todoist_page ());
        });

        nextcloud_item.clicked.connect (() => {
            push_subpage (get_nextcloud_setup_page ());
        });

        sources_group.row_activated.connect ((row) => {
            push_subpage (get_source_view (((Widgets.SourceRow) row).source));
        });
    }

    private Adw.NavigationPage get_source_view (Objects.Source source) {
        var settings_header = new Dialogs.Preferences.SettingsHeader (source.subheader_text);

        var avatar = new Adw.Avatar (84, source.user_displayname, true);

        if (source.source_type == SourceType.TODOIST) {
            var file = File.new_for_path (Util.get_default ().get_avatar_path (source.avatar_path));
            if (file.query_exists ()) {
                var image = new Gtk.Image.from_file (file.get_path ());
                avatar.custom_image = image.get_paintable ();
            }
        }

        var user_label = new Gtk.Label (source.user_displayname) {
            margin_top = 12,
            css_classes = { "title-1" }
        };

        var email_label = new Gtk.Label (source.user_email) {
            css_classes = { "dimmed" },
            margin_top = 6,
            visible = source.user_email != null && source.user_email != ""
        };

        var user_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 24
        };
        user_box.append (avatar);
        user_box.append (user_label);
        user_box.append (email_label);

        if (source.source_type == SourceType.CALDAV) {
            var url_label = new Gtk.Label (source.caldav_data.server_url) {
                css_classes = { "dimmed" }
            };
            user_box.append (url_label);
        }

        var display_entry = new Adw.EntryRow () {
            title = _("Display Name"),
            text = source.display_name,
            show_apply_button = true
        };

        var sync_server_row = new Adw.SwitchRow ();
        sync_server_row.title = _("Sync Server");
        sync_server_row.subtitle =
            _(
                "Activate this setting so that Planify automatically synchronizes with your account account every 15 minutes");
        sync_server_row.active = source.sync_server;

        var last_sync_label = new Gtk.Label (
            Utils.Datetime.get_relative_date_from_date (
                new GLib.DateTime.from_iso8601 (
                    source.last_sync, new GLib.TimeZone.local ()
                )
            )
        );

        var last_sync_row = new Adw.ActionRow ();
        last_sync_row.activatable = false;
        last_sync_row.title = _("Last Sync");
        last_sync_row.add_suffix (last_sync_label);

        var default_group = new Adw.PreferencesGroup () {
            margin_top = 24
        };

        default_group.add (display_entry);

        if (source.source_type != SourceType.LOCAL) {
            default_group.add (sync_server_row);
            default_group.add (last_sync_row);
        }

        var delete_button = new Adw.ButtonRow () {
            title = _("Delete Source")
        };
        delete_button.add_css_class ("destructive-action");

        var delete_group = new Adw.PreferencesGroup () {
            margin_top = 24
        };
        delete_group.add (delete_button);

        var main_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            vexpand = true,
            hexpand = true
        };

        if (source.source_type != SourceType.LOCAL) {
            main_content.append (user_box);
        }
        
        main_content.append (default_group);

        if (source.source_type != SourceType.LOCAL) {
            main_content.append (delete_group);
        }

        var content_clamp = new Adw.Clamp () {
            maximum_size = 600,
            margin_start = 24,
            margin_end = 24,
            child = main_content
        };

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (settings_header);
        toolbar_view.content = content_clamp;

        var page = new Adw.NavigationPage (toolbar_view, "source_view");

        settings_header.back_activated.connect (() => {
            pop_subpage ();
        });

        sync_server_row.activated.connect (() => {
            source.sync_server = !source.sync_server;
            source.save ();

            if (source.sync_server) {
                source.run_server ();
            } else {
                source.remove_sync_server ();
            }
        });

        display_entry.apply.connect (() => {
            source.display_name = display_entry.text;
            source.save ();
        });

        delete_button.activated.connect (() => {
            var dialog = new Adw.AlertDialog (
                _("Delete Source?"),
                _("This can not be undone")
            );

            dialog.add_response ("cancel", _("Cancel"));
            dialog.add_response ("delete", _("Delete"));
            dialog.close_response = "cancel";
            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.present (Planify._instance.main_window);

            dialog.response.connect ((response) => {
                if (response == "delete") {
                    source.delete_source ();
                }
            });
        });

        source.deleted.connect (() => {
            pop_subpage ();
        });

        return page;
    }

    private Adw.NavigationPage get_oauth_todoist_page () {
        var settings_header = new Dialogs.Preferences.SettingsHeader (_("Loading…"));

        string oauth_open_url = "https://todoist.com/oauth/authorize?client_id=%s&scope=%s&state=%s";
        string state = Util.get_default ().generate_string ();
        oauth_open_url = oauth_open_url.printf (Constants.TODOIST_CLIENT_ID, Constants.TODOIST_SCOPE, state);

        WebKit.WebView webview = new WebKit.WebView ();
        webview.zoom_level = 0.85;
        webview.vexpand = true;
        webview.hexpand = true;

        WebKit.WebContext.get_default ().set_preferred_languages (GLib.Intl.get_language_names ());
        webview.network_session.set_tls_errors_policy (WebKit.TLSErrorsPolicy.IGNORE);

        var banner = new Adw.Banner (("Trouble logging in? Use your token instead")) {
            revealed = true,
            button_label = _("Enter token")
        };

        var webview_box = new Gtk.Box (VERTICAL, 0);
        webview_box.append (banner);
        webview_box.append (webview);

        var sync_box = build_sync_page ();

        todoist_stack = new Gtk.Stack () {
            vexpand = true,
            hexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        todoist_stack.add_named (webview_box, "web_view");
        todoist_stack.add_named (sync_box, "loading");
        todoist_stack.add_named (get_token_todoist_page (), "token");

        var scrolled_window = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = todoist_stack
        };

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (settings_header);
        toolbar_view.content = scrolled_window;

        var page = new Adw.NavigationPage (toolbar_view, "oauth-todoist");

        webview.load_uri (oauth_open_url);

        settings_header.back_activated.connect (() => {
            pop_subpage ();
        });

        webview.load_changed.connect ((load_event) => {
            var uri = webview.get_uri ();
            var redirect_uri = "https://github.com/alainm23/planner";
            print ("url: %s\n".printf (uri));

            if ((redirect_uri + "?code=" in uri) &&
                ("&state=%s".printf (state) in uri)) {
                settings_header.title = _("Synchronizing…");                 // vala-lint=ellipsis

                todoist_stack.visible_child_name = "loading";
                Services.Todoist.get_default ().login.begin (uri, (obj, res) => {
                    HttpResponse response = Services.Todoist.get_default ().login.end (res);
                    pop_subpage ();
                    webview.get_network_session ().get_website_data_manager ().clear.begin (WebKit.WebsiteDataTypes.ALL,
                                                                                            0, null);
                    verify_response (response);
                });
            }

            if (redirect_uri + "?error=access_denied" in uri) {
                debug ("access_denied");
                webview.get_network_session ().get_website_data_manager ().clear.begin (WebKit.WebsiteDataTypes.ALL, 0,
                                                                                        null);
                pop_subpage ();
            }

            if (load_event == WebKit.LoadEvent.FINISHED) {
                settings_header.title = _("Please Enter Your Credentials");
                return;
            }

            if (load_event == WebKit.LoadEvent.STARTED) {
                settings_header.title = _("Loading…");
                return;
            }

            return;
        });

        webview.load_failed.connect ((load_event, failing_uri, _error) => {
            var error = (GLib.Error) _error;
            warning ("Loading uri '%s' failed, error : %s", failing_uri, error.message);

            if (GLib.strcmp (failing_uri, oauth_open_url) == 0) {
                settings_header.title = _("Network Is Not Available");

                var toast = new Adw.Toast (_("Network Is Not Available"));
                toast.button_label = _("Ok");
                toast.timeout = 0;

                toast.button_clicked.connect (() => {
                    pop_subpage ();
                });

                add_toast (toast);
            }

            return true;
        });

        banner.button_clicked.connect (() => {
            todoist_stack.visible_child_name = "token";
        });

        return page;
    }

    private Gtk.Widget get_token_todoist_page () {
        var server_entry = new Adw.EntryRow ();
        server_entry.title = _("Token");

        var entries_group = new Adw.PreferencesGroup ();

        entries_group.add (server_entry);

        var message_label = new Gtk.Label ("%s\n\n%s\n%s\n%s"
                                            .printf (
                                               _("How to get your token?"),
                                               _("1. Go to Todoist → Settings → Integrations → Developer"),
                                               _("2. Find 'API token' and copy your token"),
                                               _("3. Paste it in the field above"))
                            ) {
            use_markup = true,
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

        var login_button = new Widgets.LoadingButton.with_label (_("Connect with Token")) {
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

        server_entry.changed.connect (() => {
            login_button.sensitive = server_entry.text != null && server_entry.text != "";
        });

        login_button.clicked.connect (() => {
            todoist_stack.visible_child_name = "loading";

            Services.Todoist.get_default ().login_token.begin (server_entry.text, (obj, res) => {
                HttpResponse response = Services.Todoist.get_default ().login_token.end (res);
                pop_subpage ();
                verify_response (response);
            });
        });

        return content_clamp;
    }

    private Adw.NavigationPage get_nextcloud_setup_page () {
        var settings_header = new Dialogs.Preferences.SettingsHeader (_("Nextcloud Setup"));

        var server_entry = new Adw.EntryRow () {
            title = _("Server URL")
        };

        var entries_group = new Adw.PreferencesGroup ();

        entries_group.add (server_entry);

        var message_label = new Gtk.Label ("%s\n\n%s\n%s"
                                            .printf (_("Server URL examples:"), _("- https://cloud.example.com/"),
                                                     _("- https://example.com/nextcloud/"))) {
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
            css_classes = { "card" },
            child = message_box
        };

        var message_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = true,
            child = message_card
        };

        var login_button = new Widgets.LoadingButton.with_label (_("Log In")) {
            margin_top = 12,
            sensitive = false,
            css_classes = { "suggested-action" }
        };

        var cancel_button = new Gtk.Button.with_label (_("Cancel")) {
            css_classes = { "flat" },
            visible = false
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            vexpand = true,
            hexpand = true
        };

        content_box.append (entries_group);
        content_box.append (message_revealer);
        content_box.append (login_button);
        content_box.append (cancel_button);

        var sync_box = build_sync_page ();

        var main_stack = new Gtk.Stack () {
            vexpand = true,
            hexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        main_stack.add_named (content_box, "main");
        main_stack.add_named (sync_box, "loading");

        var content_clamp = new Adw.Clamp () {
            maximum_size = 400,
            margin_start = 24,
            margin_end = 24,
            margin_top = 12,
            child = main_stack
        };

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (settings_header);
        toolbar_view.content = content_clamp;

        var page = new Adw.NavigationPage (toolbar_view, "oauth-todoist");

        settings_header.back_activated.connect (() => {
            pop_subpage ();
        });

        server_entry.changed.connect (() => {
            if (server_entry.text != null && server_entry.text != "") {
                var is_valid_url = is_valid_url (server_entry.text);
                if (!is_valid_url) {
                    server_entry.add_css_class ("error");
                } else {
                    server_entry.remove_css_class ("error");
                }
            } else {
                server_entry.remove_css_class ("error");
            }

            if (server_entry.has_css_class ("error")) {
                login_button.sensitive = false;
            } else {
                login_button.sensitive = true;
            }
        });

        login_button.clicked.connect (() => {
            GLib.Cancellable cancellable = new GLib.Cancellable ();
            login_button.is_loading = true;
            cancel_button.visible = true;
            server_entry.sensitive = false;
            login_button.sensitive = false;

            cancel_button.clicked.connect (() => {
                cancellable.cancel ();
            });

            var core_service = Services.CalDAV.Core.get_default ();
            var nextcloud_provider =
                (Services.CalDAV.Providers.Nextcloud) core_service.providers_map.get (
                    CalDAVType.NEXTCLOUD.to_string ());

            nextcloud_provider.start_login_flow.begin (server_entry.text, cancellable, (obj, res) => {
                HttpResponse response = nextcloud_provider.start_login_flow.end (res);

                if (response.status) {
                    Objects.Source source = (Objects.Source) response.data_object.get_object ();
                    core_service.add_caldav_account.begin (source, cancellable, (obj, res) => {
                        response = core_service.add_caldav_account.end (res);

                        if (!response.status) {
                            login_button.is_loading = false;
                            cancel_button.visible = false;
                            server_entry.sensitive = true;
                            login_button.sensitive = true;

                            show_message_error (response.error_code, response.error.strip ());
                        }
                    });
                } else {
                    login_button.is_loading = false;
                    cancel_button.visible = false;
                    server_entry.sensitive = true;
                    login_button.sensitive = true;

                    if (response.error_code == 409) {
                        var toast = new Adw.Toast (response.error.strip ());
                        toast.timeout = 3;
                        add_toast (toast);
                    } else {
                        show_message_error (response.error_code, response.error.strip ());
                    }
                }
            });
        });

        Services.CalDAV.Core.get_default ().first_sync_started.connect (() => {
            main_stack.visible_child_name = "loading";
        });

        Services.CalDAV.Core.get_default ().first_sync_finished.connect (() => {
            pop_subpage ();
        });

        return page;
    }

    private void verify_response (HttpResponse response) {
        if (response.status) {
            return;
        }

        if (response.error_code != 409) {
            show_message_error (response.error_code, response.error.strip ());
        } else {
            var toast = new Adw.Toast (response.error.strip ());
            toast.timeout = 3;
            add_toast (toast);
        }
    }

    private bool is_valid_url (string uri) {
        var scheme = Uri.parse_scheme (uri);
        if (scheme == null) {
            return false;
        }

        return scheme.has_prefix ("http");
    }

    private void show_message_error (int error_code, string error_message, bool visible_issue_button = true) {
        var error_view = new Widgets.ErrorView () {
            error_code = error_code,
            error_message = error_message,
            visible_issue_button = visible_issue_button
        };

        var page = new Adw.NavigationPage (error_view, "");

        push_subpage (page);
    }

    private Gtk.Widget build_sync_page () {
        var image = new Adw.Spinner () {
            valign = CENTER,
            halign = CENTER,
            height_request = 64,
            width_request = 64
        };

        var label = new Gtk.Label (_("Planify is is syncing your tasks, this may take a few minutes")) {
            css_classes = { "dimmed" },
            wrap = true,
            halign = CENTER,
            justify = CENTER,
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
}