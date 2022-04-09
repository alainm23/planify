public class Dialogs.Settings.SettingsCalDAV : Gtk.EventBox {
    private Granite.ValidatedEntry url_entry;
    private Granite.ValidatedEntry username_entry;
    private Gtk.Entry password_entry;
    private Gtk.Entry display_name_entry;
    private Gtk.Stack stack;
    private Widgets.LoadingButton search_button;
    private Gtk.Stack message_stack;
    private Granite.Widgets.Toast toast;

    private static Services.AccountsModel accountsmodel;

    private GLib.Cancellable? cancellable;
    private E.SourceRegistry? registry = null;
    private E.Source? source = null;
    private ListStore calendars_store;

    private bool is_loading {
        set {
            search_button.is_loading = value;
            url_entry.sensitive = !value;
            username_entry.sensitive = !value;
            password_entry.sensitive = !value;
            display_name_entry.sensitive = !value;
        }
    }

    public string visible_child_name {
        get {
            return stack.visible_child_name;
        }

        set {
            stack.visible_child_name = value;
        }
    }

    static construct {
        accountsmodel = new Services.AccountsModel ();
    }

    construct {
        calendars_store = new ListStore (typeof (E.Source));

        // Sources Grid
        var acounts_content = new Dialogs.Settings.SettingsContent (_("Accounts")) {
            margin_bottom = 0
        };
        acounts_content.add_action = true;

        var listbox = new Gtk.ListBox ();
        listbox.bind_model (accountsmodel.accounts_liststore, create_account_row);
        // listbox.set_placeholder (welcome);
        
        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("picker-background");

        acounts_content.add_child (listbox);
        
        var add_source = new Gtk.Button.with_label ("Add Account…") {
            margin_start = 12,
            margin_top = 6,
            halign = Gtk.Align.START
        };
        add_source.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var sources_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        toast = new Granite.Widgets.Toast ("");

        sources_grid.add (acounts_content);
        sources_grid.add (toast);

        // Login Grid
        var url_label = new Granite.HeaderLabel (_("Server URL")) {
            margin_start = 6,
            margin_end = 6
        };
        url_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        url_entry = new Granite.ValidatedEntry () {
            hexpand = true,
            margin_start = 6,
            margin_end = 6
        };
        url_entry.get_style_context ().add_class ("border-radius-6");

        var url_message_revealer = new ValidationMessage (_("Invalid URL"));
        url_message_revealer.label_widget.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);

        var username_label = new Granite.HeaderLabel (_("User Name")) {
            margin_start = 6,
            margin_end = 6,
            margin_top = 6
        };
        username_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        username_entry = new Granite.ValidatedEntry () {
            margin_start = 6,
            margin_end = 6
        };
        username_entry.get_style_context ().add_class ("border-radius-6");

        var password_label = new Granite.HeaderLabel (_("Password")) {
            margin_start = 6,
            margin_end = 6,
            margin_top = 6
        };
        password_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        password_entry = new Gtk.Entry () {
            activates_default = true,
            input_purpose = Gtk.InputPurpose.PASSWORD,
            visibility = false,
            margin_start = 6,
            margin_end = 6
        };
        password_entry.get_style_context ().add_class ("border-radius-6");

        var display_name_label = new Granite.HeaderLabel (_("Account Display Name")) {
            margin_start = 6,
            margin_end = 6,
            margin_top = 6
        };
        display_name_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        display_name_entry = new Granite.ValidatedEntry () {
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 9
        };
        display_name_entry.get_style_context ().add_class ("border-radius-6");

        var login_page = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        unowned Gtk.StyleContext login_page_context = login_page.get_style_context ();
        login_page_context.add_class ("picker-content");

        login_page.add (url_label);
        login_page.add (url_entry);
        login_page.add (url_message_revealer);
        login_page.add (username_label);
        login_page.add (username_entry);
        login_page.add (password_label);
        login_page.add (password_entry);
        login_page.add (display_name_label);
        login_page.add (display_name_entry);

        search_button = new Widgets.LoadingButton (LoadingButtonType.ICON, "folder-saved-search-symbolic") {
            can_focus = false
        };

        search_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        search_button.get_style_context ().add_class ("circle-button");

        var action_area = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_top = 12,
            halign = Gtk.Align.CENTER,
            vexpand = true
        };

        action_area.add (search_button);

        message_stack = new Gtk.Stack () {
            expand = true,
            homogeneous = false,
            margin_top = 12
        };

        var login_content_page = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            margin = 12,
            margin_top = 0
        };

        login_content_page.add (login_page);
        login_content_page.add (message_stack);
        login_content_page.add (action_area);

        stack = new Gtk.Stack () {
            expand = true,
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT,
            homogeneous = false
        };

        stack.add_named (sources_grid, "sources");
        stack.add_named (login_content_page, "login");

        add (stack);

        acounts_content.add_activated.connect (() => {
            stack.visible_child_name = "login";
        });

        username_entry.changed.connect (() => {
            username_entry.is_valid = username_entry.text != null && username_entry.text != "";
            display_name_entry.text = username_entry.text;
            validate_form ();
        });

        url_entry.changed.connect (() => {
            if (url_entry.text != null && url_entry.text != "") {
                var is_valid_url = is_valid_url (url_entry.text);
                url_entry.is_valid = is_valid_url;
                url_message_revealer.reveal_child = !is_valid_url;
            } else {
                url_entry.is_valid = false;
                url_message_revealer.reveal_child = false;
            }

            validate_form ();
        });

        search_button.clicked.connect (() => {
            find_sources.begin ();
        });
    }

    private void validate_form () {
        search_button.sensitive = url_entry.is_valid && username_entry.is_valid;
    }

    private void set_default () {
        search_button.is_loading = false;
        url_entry.text = "";
        username_entry.text = "";
        password_entry.text = "";
        display_name_entry.text = "";
    }

    private bool is_valid_url (string uri) {
        var scheme = Uri.parse_scheme (uri);
        if (scheme == null) {
            return false;
        }

        return scheme.has_prefix ("http");
    }

    private Gtk.Widget create_account_row (GLib.Object object) {
        var e_source = (E.Source) object;
        
        var image = new Gtk.Image () {
            pixel_size = 27,
            gicon = new ThemedIcon ("planner-cloud")
        };

        var label = new Gtk.Label (e_source.display_name) {
            halign = Gtk.Align.START,
            hexpand = true,
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0
        };

        var url_label = new Gtk.Label (null) {
            halign = Gtk.Align.START,
            hexpand = true,
            ellipsize = Pango.EllipsizeMode.END,
            xalign = 0
        };

        url_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);
        url_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var remove_image = new Widgets.DynamicIcon ();
        remove_image.size = 19;
        remove_image.update_icon_name ("planner-close-circle");

        var remove_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        remove_button.add (remove_image);

        unowned Gtk.StyleContext remove_button_context = remove_button.get_style_context ();
        remove_button_context.add_class (Gtk.STYLE_CLASS_FLAT);
        remove_button_context.add_class ("no-padding");

        if (e_source.has_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND)) {
            unowned var webdav_extension = (E.SourceWebdav) e_source.get_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND);
            url_label.label = webdav_extension.soup_uri.to_string (false);

            if (webdav_extension.soup_uri.user != null && webdav_extension.soup_uri.user != "") {
                url_label.label = url_label.label.replace (webdav_extension.soup_uri.user + "@", "");
            }
        }

        var grid = new Gtk.Grid () {
            column_spacing = 6,
            margin = 3
        };

        grid.attach (image, 0, 0, 1, 2);
        grid.attach (label, 1, 0, 1, 1);
        grid.attach (url_label, 1, 1, 1, 1);
        grid.attach (remove_button, 2, 0, 2, 2);
        grid.show_all ();

        remove_button.clicked.connect (() => {
            e_source.remove.begin (null);
        });

        return grid;
    }

    private async void find_sources () {
        if (cancellable != null) {
            cancellable.cancel ();
        }

        var error_view = message_stack.get_child_by_name ("error");
        if (error_view != null) {
            message_stack.remove (error_view);
        }

        cancellable = new GLib.Cancellable ();

        is_loading = true;

        try {
            var source = new E.Source (null, null);
            source.parent = "caldav-stub";

            unowned var col = (E.SourceCollection)source.get_extension (E.SOURCE_EXTENSION_COLLECTION);
            col.backend_name = "caldav";

            unowned var webdav = (E.SourceWebdav)source.get_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND);
            webdav.soup_uri = new Soup.URI (url_entry.text);
            webdav.calendar_auto_schedule = true;

            unowned var auth = (E.SourceAuthentication)source.get_extension (E.SOURCE_EXTENSION_AUTHENTICATION);
            auth.user = username_entry.text;

            unowned var offline = (E.SourceOffline)source.get_extension (E.SOURCE_EXTENSION_OFFLINE);
            offline.set_stay_synchronized (true);

            var credentials = new E.NamedParameters ();
            credentials.set (E.SOURCE_CREDENTIAL_USERNAME, username_entry.text);
            credentials.set (E.SOURCE_CREDENTIAL_PASSWORD, password_entry.text);

            // var found_calendars = yield find_sources_supporting (E.WebDAVDiscoverSupports.EVENTS, source, credentials, cancellable);
            var found_tasklists = yield find_sources_supporting (E.WebDAVDiscoverSupports.TASKS, source, credentials, cancellable);

            Idle.add (() => {
                calendars_store.splice (0, 0, (Object[]) found_tasklists);
                save_configuration.begin ((obj, res) => {
                    try {
                        save_configuration.end (res);
                        stack.visible_child_name = "sources";
                        set_default ();
                    } catch (Error e) {
                        error_view = message_stack.get_child_by_name ("error");
                        if (error_view != null) {
                            message_stack.remove (error_view);
                        }

                        error_view = get_message_view (_("Could not save configuration"), "danger");
                        error_view.show_all ();
    
                        message_stack.add_named (error_view, "error");
                        message_stack.set_visible_child_name ("error");
                    }
                });
                return Source.REMOVE;
            });
        } catch (GLib.Error e) {
            is_loading = false;

            error_view = message_stack.get_child_by_name ("error");
            if (error_view != null) {
                message_stack.remove (error_view);
            }

            error_view = get_message_view (_("Could not fetch tasklists"), "danger");
            error_view.show_all ();

            message_stack.add_named (error_view, "error");
            message_stack.set_visible_child_name ("error");
        }
    }

    private async E.Source[] find_sources_supporting (E.WebDAVDiscoverSupports only_supports, E.Source source, E.NamedParameters credentials, GLib.Cancellable? cancellable) throws Error {
        E.Source[] e_sources = {};
        GLib.Error? discover_error = null;

#if HAS_EDS_3_40
        source.webdav_discover_sources.begin (
#else
        E.webdav_discover_sources.begin (
            source,
#endif
        null,
        only_supports,
        credentials,
        cancellable,
        (obj, res) => {
            string certificate_pem;
            GLib.TlsCertificateFlags certificate_errors;
            GLib.SList<E.WebDAVDiscoveredSource?> discovered_sources;
            GLib.SList<string> calendar_user_addresses;
            try {
#if HAS_EDS_3_40
                source.webdav_discover_sources.end (
#else
                E.webdav_discover_sources_finish (
                    source,
#endif
                    res,
                    out certificate_pem,
                    out certificate_errors,
                    out discovered_sources,
                    out calendar_user_addresses
                );

                /** Get WebDAV host: This is used to check whether we are dealing with a calendar source
                * stored on the server itself or if its a subscription from a third party server. In case
                * we are dealing with a calendar subscription we are going to ignore it, because we can't
                * possibly know its credentials. So the user has to add any subscription in the corresponding
                * app manually.
                */
                string? webdav_host = null;
                if (source.has_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND)) {
                    unowned var webdav_extension = (E.SourceWebdav) source.get_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND);
                    webdav_host = webdav_extension.soup_uri.host;
                }

                foreach (unowned E.WebDAVDiscoveredSource? disc_source in discovered_sources) {
                    if (disc_source == null || (only_supports & disc_source.supports) == 0 || webdav_host != null && !disc_source.href.contains (webdav_host)) {
                        continue;
                    }

                    var e_source = new E.Source (null, null) {
                        display_name = disc_source.display_name
                    };

                    unowned var webdav = (E.SourceWebdav) e_source.get_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND);
                    webdav.soup_uri = new Soup.URI (disc_source.href);
                    webdav.color = disc_source.color;

                    switch (only_supports) {
                        case E.WebDAVDiscoverSupports.EVENTS:
                            unowned var calendar = (E.SourceCalendar) e_source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
                            calendar.backend_name = "caldav";
                            calendar.color = disc_source.color;
                            break;
                        case E.WebDAVDiscoverSupports.TASKS:
                            unowned var tasklist = (E.SourceTaskList) e_source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);
                            tasklist.backend_name = "caldav";
                            tasklist.color = disc_source.color;
                            break;
                    }

                    e_sources += e_source;
                }
                E.webdav_discover_do_free_discovered_sources ((owned) discovered_sources);

            } catch (GLib.IOError.CANCELLED e) {
            } catch (Error e) {
                discover_error = e;
            }

            find_sources_supporting.callback ();
        });

        yield;

        if (discover_error != null) {
            throw discover_error;
        }
        return e_sources;
    }

    private async void save_configuration () throws Error {
        if (cancellable != null) {
            cancellable.cancel ();
        }
        cancellable = new GLib.Cancellable ();

        if (registry == null) {
            registry = yield new E.SourceRegistry (cancellable);
        }

        if (cancellable.is_cancelled ()) {
            return;
        }
        GLib.List<E.Source> new_sources = new GLib.List<E.Source> ();

        /* store the collection source first, so we can use it as parent for the other ones */
        var collection_source = new E.Source (null, null);
        collection_source.parent = "";
        collection_source.display_name = display_name_entry.text;

        unowned var collection_extension = (E.SourceCollection) collection_source.get_extension (E.SOURCE_EXTENSION_COLLECTION);
        collection_extension.backend_name = "webdav";
        collection_extension.calendar_url = url_entry.text;
        collection_extension.identity = username_entry.text;

        unowned var authentication_extension = (E.SourceAuthentication) collection_source.get_extension (E.SOURCE_EXTENSION_AUTHENTICATION);
        authentication_extension.user = username_entry.text;

        unowned var webdav_extension = (E.SourceWebdav) collection_source.get_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND);
        webdav_extension.soup_uri = new Soup.URI (url_entry.text);
        webdav_extension.calendar_auto_schedule = true;

        unowned var offline_extension = (E.SourceOffline) collection_source.get_extension (E.SOURCE_EXTENSION_OFFLINE);
        offline_extension.set_stay_synchronized (true);

        new_sources.append (collection_source);

        /* First store passwords, thus the evolution-source-registry has them ready if needed. */
        yield collection_source.store_password (password_entry.text, true, cancellable);
        yield registry.create_sources (new_sources, cancellable);

        /* Discovers all child sources and EDS automatically adds them */
        yield registry.refresh_backend (collection_source.uid, cancellable);

        /* if we are editing an existing account, make sure we delete the old collection source at this point */
        if (this.source != null) {
            yield this.source.remove (cancellable);
        }
    }

    private Gtk.Widget get_message_view (string message, string class_name) {
        var message_label = new Gtk.Label (message) {
            wrap = true,
            justify = Gtk.Justification.CENTER,
            hexpand = true,
            margin = 6
        };
        
        unowned Gtk.StyleContext message_label_context = message_label.get_style_context ();
        message_label_context.add_class ("dim-label");
        message_label_context.add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var placeholder_grid = new Gtk.Grid ();

        unowned Gtk.StyleContext placeholder_grid_context = placeholder_grid.get_style_context ();
        placeholder_grid_context.add_class ("transition");
        placeholder_grid_context.add_class ("pane-content");
        placeholder_grid_context.add_class (class_name);

        placeholder_grid.add (message_label);

        placeholder_grid.show_all ();
        return placeholder_grid;
    }
}

private class ValidationMessage : Gtk.Revealer {
    public Gtk.Label label_widget;
    public string label { get; construct set; }

    public ValidationMessage (string label) {
        Object (label: label);
    }

    construct {
        label_widget = new Gtk.Label (label) {
            halign = Gtk.Align.END,
            justify = Gtk.Justification.RIGHT,
            max_width_chars = 55,
            wrap = true,
            xalign = 1,
            margin_end = 6,
            margin_top = 3
        };
        label_widget.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        add (label_widget);

        bind_property ("label", label_widget, "label");
    }
}