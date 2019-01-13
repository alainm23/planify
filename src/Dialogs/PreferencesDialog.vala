/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Dialogs.PreferencesDialog : Gtk.Dialog {
    public weak Gtk.Window window { get; construct; }
    private Gtk.Stack main_stack;

    private GLib.HashTable<string, Widgets.SourceItem?> src_map;
    private Gtk.ListBox calendar_list;
    private Gtk.ScrolledWindow calendar_scroll;

    private Gtk.Label start_page_preview_label;
    private Gtk.Label badge_count_preview_label;
    private Gtk.Label quick_save_preview_label;
    private Gtk.Label weather_preview_label;
    private Gtk.Label calendar_preview_label;

    private Granite.Widgets.Avatar profile_image;
    private Gtk.Label username_label;

    public signal void on_close ();

    public PreferencesDialog (Gtk.Window parent) {
        Object (
            window: parent,
            transient_for: parent,
            deletable: false,
            resizable: false,
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT
        );
	}

    construct {
        title = _("Preferences");
        set_size_request (660, 569);

        var mode_button = new Granite.Widgets.ModeButton ();
        mode_button.hexpand = true;
        mode_button.halign = Gtk.Align.CENTER;

        mode_button.append_text (_("General"));
        mode_button.append_text (_("Appearance"));
        mode_button.append_text (_("Issues"));
        mode_button.append_text (_("About"));

        mode_button.selected = 0;

        main_stack = new Gtk.Stack ();
        main_stack.expand = true;
        main_stack.margin = 12;
        main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        main_stack.add_named (get_general_widget (), "general");
        main_stack.add_named (get_themes_widget (), "themes");
        main_stack.add_named (get_github_login_widget (), "github_login");
        main_stack.add_named (get_github_widget (), "issues");
        main_stack.add_named (get_about_widget (), "about");
        main_stack.add_named (get_badge_count_widget (), "badge_count");
        main_stack.add_named (get_start_page_widget (), "start_page");
        main_stack.add_named (get_quick_save_widget (), "quick_save");
        main_stack.add_named (get_weather_widget (), "weather");
        main_stack.add_named (get_calendar_widget (), "calendar");
        main_stack.add_named (get_items_widget (), "items");

        main_stack.visible_child_name = "general";

        var content_grid = new Gtk.Grid ();
        content_grid.orientation = Gtk.Orientation.VERTICAL;
        content_grid.add (mode_button);
        content_grid.add (main_stack);

        ((Gtk.Container) get_content_area ()).add (content_grid);

        var close_button = new Gtk.Button.with_label (_("Close"));
        close_button.valign = Gtk.Align.END;
        close_button.get_style_context ().add_class ("suggested-action");
        close_button.margin_bottom = 6;
        close_button.margin_end = 6;

        close_button.clicked.connect (() => {
			destroy ();
		});

        mode_button.mode_changed.connect ((widget) => {
            if (mode_button.selected == 0) {
                main_stack.visible_child_name = "general";
            } else if (mode_button.selected == 1){
                main_stack.visible_child_name = "themes";
            } else if (mode_button.selected == 2) {
                if (Application.database.user_exists ()) {
                    main_stack.visible_child_name = "issues";
                } else {
                    main_stack.visible_child_name = "github_login";
                }
            } else {
                main_stack.visible_child_name = "about";
            }
        });

        Application.github.completed_user.connect ((user) => {
            var cache_folder = GLib.Path.build_filename (GLib.Environment.get_user_cache_dir (), "com.github.alainm23.planner");
            var profile_folder = GLib.Path.build_filename (cache_folder, "profile");
            var image_path = GLib.Path.build_filename (profile_folder, ("%i.jpg").printf ((int) user.id));
            
            try {
                var pixbuf = new Gdk.Pixbuf.from_file_at_size (image_path, 48, 48);

                profile_image.pixbuf = pixbuf;
                username_label.label = "%s (%s)".printf (user.name, user.login);

                main_stack.visible_child_name = "issues";
            } catch (Error e) {
                stderr.printf ("Failed to connect to Github service.\n");
            }
        });

        add_action_widget (close_button, 0);
    }

    private Gtk.Widget get_github_login_widget () {
        var github_image = new Gtk.Image.from_icon_name ("planner-github", Gtk.IconSize.DIALOG);

        var title_label = new Gtk.Label (_("Github"));
        title_label.halign = Gtk.Align.START;
        title_label.valign = Gtk.Align.END;
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

		var subtitle_label = new Gtk.Label (_("Connect your account to work with issues"));
        subtitle_label.halign = Gtk.Align.START;
        subtitle_label.valign = Gtk.Align.START;
		subtitle_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
		subtitle_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

		var username_entry = new Gtk.Entry ();
        username_entry.margin_top = 24;
        username_entry.halign = Gtk.Align.CENTER;
		username_entry.placeholder_text = _("Username");
		username_entry.width_request = 250;

        var password_entry = new Gtk.Entry ();
		password_entry.width_request = 250;
		password_entry.placeholder_text = _("Password");
		password_entry.visibility = false;
		password_entry.input_purpose = Gtk.InputPurpose.PASSWORD;

        var entrys_grid = new Gtk.Grid ();
		entrys_grid.orientation = Gtk.Orientation.VERTICAL;
		entrys_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
		entrys_grid.halign = Gtk.Align.CENTER;
		entrys_grid.add (username_entry);
		entrys_grid.add (password_entry);

        var error_label = new Gtk.Label (_("Enter a correct Username"));
        error_label.halign = Gtk.Align.END;
        error_label.margin_end = 48;
        error_label.margin_top = 6;
        error_label.get_style_context ().add_class ("error");

        var error_revealer = new Gtk.Revealer ();
        error_revealer.add (error_label);
        error_revealer.reveal_child = false;

		var connect_button = new Gtk.Button.with_label (_("Connect"));
 		connect_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
		connect_button.margin_top = 12;
		connect_button.width_request = 250;
		connect_button.halign = Gtk.Align.CENTER;
        connect_button.sensitive = false;
        
        var forgot_button = new Gtk.LinkButton.with_label ("https://github.com/password_reset", _("Forgot password…"));
        forgot_button.margin_top = 12;

        var signup_button = new Gtk.LinkButton.with_label ("https://github.com/join", _("Don't have an account? Sign Up"));
        signup_button.margin_top = 6;

		username_entry.changed.connect ( () => {
			if (username_entry.text != "") {
				connect_button.sensitive = true;
			} else {
				connect_button.sensitive = false;
			}
		});

        var title_grid = new Gtk.Grid ();
        title_grid.column_spacing = 12;
        title_grid.halign = Gtk.Align.CENTER;
        title_grid.valign = Gtk.Align.CENTER;
        title_grid.attach (github_image, 0, 0, 1, 2);
        title_grid.attach (title_label, 1, 0, 1, 1);
        title_grid.attach (subtitle_label, 1, 1, 1, 1);

        var main_grid = new Gtk.Grid ();
        main_grid.halign = Gtk.Align.CENTER;
        main_grid.valign = Gtk.Align.CENTER;
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (title_grid);
        main_grid.add (entrys_grid);
        main_grid.add (error_revealer);
        main_grid.add (connect_button);
        main_grid.add (forgot_button);
        main_grid.add (signup_button);

        var main_frame = new Gtk.Frame (null);
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (main_grid);

        connect_button.clicked.connect (() => {
            Application.github.get_token (username_entry.text, password_entry.text);
        });

        username_entry.activate.connect (() => {
            if (username_entry.text != "" && password_entry.text != "") {
                Application.github.get_token (username_entry.text, password_entry.text);
            }
        });

        password_entry.activate.connect (() => {
            if (username_entry.text != "" && password_entry.text != "") {
                Application.github.get_token (username_entry.text, password_entry.text);
            }
        });

        username_entry.changed.connect ( () => {
            if (username_entry.text != "" && password_entry.text != "") {
                connect_button.sensitive = true;
            } else {
                connect_button.sensitive = false;
            }
        });

        password_entry.changed.connect ( () => {
            if (username_entry.text != "" && password_entry.text != "") {
                connect_button.sensitive = true;
            } else {
                connect_button.sensitive = false;
            }
        });

        Application.github.user_is_valid.connect ((valid) => {
            if (valid == false) {
                username_entry.secondary_icon_name = "dialog-error-symbolic";
                error_revealer.reveal_child = true;
            }
        });

        return main_frame;
    }
    
    private Gtk.Widget get_github_widget () {
        var user = Application.database.get_user ();

        var cache_folder = GLib.Path.build_filename (GLib.Environment.get_user_cache_dir (), "com.github.alainm23.planner");
        var profile_folder = GLib.Path.build_filename (cache_folder, "profile");
        var image_path = GLib.Path.build_filename (profile_folder, ("%i.jpg").printf ((int) user.id));

        profile_image = new Granite.Widgets.Avatar.from_file (image_path, 48);
        
        var github_icon = new Gtk.Image ();
        github_icon.valign = Gtk.Align.END;
        github_icon.halign = Gtk.Align.END;
        github_icon.gicon = new ThemedIcon ("planner-github");
        github_icon.pixel_size = 20;

        var profile_overlay = new Gtk.Overlay ();
        profile_overlay.margin_start = 6;
        profile_overlay.margin_top = 6;
        profile_overlay.margin_bottom = 6;
        profile_overlay.add_overlay (github_icon);
        profile_overlay.add (profile_image);

        username_label = new Gtk.Label ("%s (%s)".printf (user.name, user.login));
        username_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        username_label.halign = Gtk.Align.START;
        username_label.valign = Gtk.Align.END;

        var subtitle_label = new Gtk.Label (_("Check which repositories you want to work with"));
        subtitle_label.halign = Gtk.Align.START;
        subtitle_label.valign = Gtk.Align.START;
		subtitle_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
		subtitle_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        var title_grid = new Gtk.Grid ();
        title_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_BACKGROUND);
        title_grid.column_spacing = 6;
        title_grid.attach (profile_overlay, 0, 0, 1, 2);
        title_grid.attach (username_label, 1, 0, 1, 1);
        title_grid.attach (subtitle_label, 1, 1, 1, 1);

        var listbox = new Gtk.ListBox  ();
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.expand = true;

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (listbox);

        var update_issues_button = new Gtk.Button.with_label (_("Update issues"));
        update_issues_button.get_style_context ().add_class ("planner-button-issues");

        var update_repos_button = new Gtk.Button.with_label (_("Update repositories"));
        update_repos_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var reset_account_button = new Gtk.Button.with_label (_("Delete account"));
        reset_account_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        var action_grid = new Gtk.Grid ();
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 6;
        action_grid.margin = 6;
        action_grid.add (update_issues_button);
        action_grid.add (update_repos_button);
        action_grid.add (reset_account_button);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (title_grid);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (scrolled);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (action_grid);

        var main_frame = new Gtk.Frame (null);
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (main_grid);

        Application.database.adden_new_repository.connect ((repo) => {
            try {
                Idle.add (() => {
                    var item = new Widgets.RepositoryRow (repo);
                    listbox.add (item);

                    listbox.show_all ();
                    return false;
                });
            } catch (Error err) {
                stderr.printf ("Error");
            }
        });

        // Update listbox
        var all_repos = new Gee.ArrayList<Objects.Repository?> ();
        all_repos = Application.database.get_all_repos ();

        foreach (var repo in all_repos) {
            var row = new Widgets.RepositoryRow (repo);
            listbox.add (row);
        }
        
        listbox.show_all ();

        update_repos_button.clicked.connect (() => {
            if (Application.database.user_exists ()) {
                var _user = Application.database.get_user ();
                Application.github.get_repos (_user.login, _user.token, _user.id);
            }
        });

        reset_account_button.clicked.connect (() => {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Are you sure you want to delete your Github account?"),
                "",
                "dialog-warning",
            Gtk.ButtonsType.CANCEL);

            var remove_button = new Gtk.Button.with_label (_("Delete"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                if (Application.github.delete_account ()) {
                    foreach (Gtk.Widget element in listbox.get_children ()) {
                        listbox.remove (element);
                    }
                    
                    main_stack.visible_child_name = "github_login";
                }
            }

            message_dialog.destroy ();
        });

        update_issues_button.clicked.connect (() => {
            Application.github.check_issues ();
        });

        return main_frame;
    }

    private Gtk.Widget get_themes_widget () {
        var flowbox = new Gtk.FlowBox ();
        flowbox.valign = Gtk.Align.START;

        flowbox.add (new ThemeChild (1, _("Banana"), "planner-banana-theme"));
        flowbox.add (new ThemeChild (2, _("Black"), "planner-black-theme"));
        flowbox.add (new ThemeChild (3, _("Blueberry"), "planner-blueberry-theme"));
        flowbox.add (new ThemeChild (4, _("Strawberry"), "planner-strawberry-theme"));
        flowbox.add (new ThemeChild (5, _("Lemon"), "planner-lemon-theme"));
        flowbox.add (new ThemeChild (6, _("Slate"), "planner-slate-theme"));
        flowbox.add (new ThemeChild (7, _("Pink"), "planner-pink-theme"));

        flowbox.show_all ();

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (flowbox);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (scrolled);

        var main_frame = new Gtk.Frame (null);
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (main_grid);

        flowbox.child_activated.connect ((child) => {
            var item = child as ThemeChild;
            Application.utils.apply_theme (Application.utils.get_theme (item.id));

            Application.settings.set_enum ("theme", item.id);
        });

        return main_frame;
    }

    private Gtk.Widget get_badge_count_widget () {
        var back_button = new Gtk.Button.with_label (_("Back"));
        back_button.can_focus = false;
        back_button.valign = Gtk.Align.CENTER;
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Badge Count")));
        title_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin = 6;
        top_box.hexpand = true;
        top_box.pack_start (back_button, false, false, 0);
        top_box.set_center_widget (title_label);

        var icon = new Gtk.Image ();
        icon.gicon = new ThemedIcon ("planner-badge-count");
        icon.pixel_size = 32;

        var label = new Gtk.Label (_("Choose which items should be counted for the badge on the application icon."));
        label.get_style_context ().add_class ("h3");
        label.wrap = true;

        var description_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        description_box.margin = 10;
        description_box.hexpand = true;
        description_box.pack_start (icon, false, false, 0);
        description_box.pack_start (label, true, true, 0);

        var none_radio = new Gtk.RadioButton.with_label_from_widget (null, _("None"));
        none_radio.get_style_context ().add_class ("h3");
        none_radio.margin_start = 12;
        none_radio.margin_top = 6;

        var inbox_radio = new Gtk.RadioButton.with_label_from_widget (none_radio, _("Inbox"));
        inbox_radio.get_style_context ().add_class ("h3");
        inbox_radio.margin_start = 12;
        inbox_radio.margin_top = 3;

        var today_radio = new Gtk.RadioButton.with_label_from_widget (none_radio, _("Today"));
        today_radio.get_style_context ().add_class ("h3");
        today_radio.margin_start = 12;
        today_radio.margin_top = 3;

        var today_string_radio = new Gtk.RadioButton.with_label_from_widget (none_radio, "%s + %s".printf (_("Today"), _("Inbox")));
        today_string_radio.get_style_context ().add_class ("h3");
        today_string_radio.margin_start = 12;
        today_string_radio.margin_top = 3;

        var notification_radio = new Gtk.RadioButton.with_label_from_widget (none_radio, _("Notifications"));
        notification_radio.get_style_context ().add_class ("h3");
        notification_radio.margin_start = 12;
        notification_radio.margin_top = 3;
        notification_radio.margin_bottom = 6;

        int index = Application.settings.get_enum ("start-page");

        if (index == 0) {
            none_radio.active = true;
        } else if (index == 1) {
            inbox_radio.active = true;
        } else if (index == 2) {
            today_radio.active = true;
        } else if (index == 3) {
            today_string_radio.active = true;
        } else if (index == 4) {
            notification_radio.active = true;
        }

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (description_box);
        grid.add (none_radio);
        grid.add (inbox_radio);
        grid.add (today_radio);
        grid.add (today_string_radio);
        //grid.add (notification_radio);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (grid);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (top_box);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (scrolled);

        var main_frame = new Gtk.Frame (null);
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (main_grid);

        back_button.clicked.connect (() => {
            check_badge_count_preview ();
            main_stack.visible_child_name = "general";
        });

        none_radio.toggled.connect (() => {
            Application.settings.set_enum ("badge-count", 0);
        });

        inbox_radio.toggled.connect (() => {
            Application.settings.set_enum ("badge-count", 1);
        });

        today_radio.toggled.connect (() => {
            Application.settings.set_enum ("badge-count", 2);
        });

        today_string_radio.toggled.connect (() => {
            Application.settings.set_enum ("badge-count", 3);
        });

        notification_radio.toggled.connect (() => {
            Application.settings.set_enum ("badge-count", 4);
        });

        return main_frame;
    }

    private Gtk.Widget get_start_page_widget () {
        var back_button = new Gtk.Button.with_label (_("Back"));
        back_button.can_focus = false;
        back_button.valign = Gtk.Align.CENTER;
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Start Page")));
        title_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin = 6;
        top_box.hexpand = true;
        top_box.pack_start (back_button, false, false, 0);
        top_box.set_center_widget (title_label);

        var icon = new Gtk.Image ();
        icon.gicon = new ThemedIcon ("help-about");
        icon.pixel_size = 32;

        var label = new Gtk.Label (_("Choose that page should be first initial when Planner is open."));
        label.get_style_context ().add_class ("h3");
        label.wrap = true;

        var description_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        description_box.margin = 10;
        description_box.hexpand = true;
        description_box.pack_start (icon, false, false, 0);
        description_box.pack_start (label, false, false, 6);

        var inbox_radio = new Gtk.RadioButton.with_label_from_widget (null, _("Inbox"));
        inbox_radio.get_style_context ().add_class ("h3");
        inbox_radio.margin_start = 12;
        inbox_radio.margin_top = 6;

        var today_radio = new Gtk.RadioButton.with_label_from_widget (inbox_radio, _("Today"));
        today_radio.get_style_context ().add_class ("h3");
        today_radio.margin_start = 12;
        today_radio.margin_top = 3;

        var upcoming_radio = new Gtk.RadioButton.with_label_from_widget (inbox_radio, _("Upcoming"));
        upcoming_radio.get_style_context ().add_class ("h3");
        upcoming_radio.margin_start = 12;
        upcoming_radio.margin_top = 3;
        upcoming_radio.margin_bottom = 6;

        int index = Application.settings.get_enum ("start-page");

        if (index == 0) {
            inbox_radio.active = true;
        } else if (index == 1) {
            today_radio.active = true;
        } else if (index == 2) {
            upcoming_radio.active = true;
        }

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (description_box);
        grid.add (inbox_radio);
        grid.add (today_radio);
        grid.add (upcoming_radio);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (grid);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (top_box);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (scrolled);

        var main_frame = new Gtk.Frame (null);
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (main_grid);

        back_button.clicked.connect (() => {
            check_start_page_preview ();
            main_stack.visible_child_name = "general";
        });

        inbox_radio.toggled.connect (() => {
            Application.settings.set_enum ("start-page", 0);
        });

        today_radio.toggled.connect (() => {
            Application.settings.set_enum ("start-page", 1);
        });

        upcoming_radio.toggled.connect (() => {
            Application.settings.set_enum ("start-page", 2);
        });

        return main_frame;
    }

    private Gtk.Widget get_items_widget () {
        var back_button = new Gtk.Button.with_label (_("Back"));
        back_button.can_focus = false;
        back_button.valign = Gtk.Align.CENTER;
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Items")));
        title_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin = 6;
        top_box.hexpand = true;
        top_box.pack_start (back_button, false, false, 0);
        top_box.set_center_widget (title_label);

        var icon = new Gtk.Image ();
        icon.gicon = new ThemedIcon ("bookmark-new");
        icon.pixel_size = 32;

        var label = new Gtk.Label (_("Choose which items should be displayed in the left side panel."));
        label.get_style_context ().add_class ("h3");
        label.wrap = true;

        var description_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        description_box.margin = 10;
        description_box.hexpand = true;
        description_box.pack_start (icon, false, false, 0);
        description_box.pack_start (label, false, false, 6);

        var inbox_check = new Gtk.CheckButton.with_label (_("Inbox"));
        inbox_check.get_style_context ().add_class ("h3");
        inbox_check.margin_start = 12;
        inbox_check.margin_top = 6;

        var today_check = new Gtk.CheckButton.with_label (_("Today"));
        today_check.get_style_context ().add_class ("h3");
        today_check.margin_start = 12;
        today_check.margin_top = 3;

        var upcoming_check = new Gtk.CheckButton.with_label (_("Upcoming"));
        upcoming_check.get_style_context ().add_class ("h3");
        upcoming_check.margin_start = 12;
        upcoming_check.margin_top = 3;

        var all_tasks_check = new Gtk.CheckButton.with_label (_("All Tasks"));
        all_tasks_check.get_style_context ().add_class ("h3");
        all_tasks_check.margin_start = 12;
        all_tasks_check.margin_top = 3;

        var completed_check = new Gtk.CheckButton.with_label (_("Completed Tasks"));
        completed_check.get_style_context ().add_class ("h3");
        completed_check.margin_start = 12;
        completed_check.margin_top = 3;
        completed_check.margin_bottom = 6;

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (description_box);
        grid.add (inbox_check);
        grid.add (today_check);
        grid.add (upcoming_check);
        grid.add (all_tasks_check);
        grid.add (completed_check);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (grid);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (top_box);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (scrolled);

        var main_frame = new Gtk.Frame (null);
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (main_grid);

        back_button.clicked.connect (() => {
            check_start_page_preview ();
            main_stack.visible_child_name = "general";
        });

        return main_frame;
    }

    private Gtk.Widget get_quick_save_widget () {
        var back_button = new Gtk.Button.with_label (_("Back"));
        back_button.can_focus = false;
        back_button.valign = Gtk.Align.CENTER;
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Quick Save")));
        title_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin = 6;
        top_box.hexpand = true;
        top_box.pack_start (back_button, false, false, 0);
        top_box.set_center_widget (title_label);

        var icon = new Gtk.Image ();
        icon.gicon = new ThemedIcon ("input-mouse");
        icon.pixel_size = 32;

        var label = new Gtk.Label (_("Choose how many clicks to close and save all open tasks."));
        label.get_style_context ().add_class ("h3");
        label.wrap = true;

        var description_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        description_box.margin = 10;
        description_box.hexpand = true;
        description_box.pack_start (icon, false, false, 0);
        description_box.pack_start (label, false, false, 6);

        var none_radio = new Gtk.RadioButton.with_label_from_widget (null, _("None"));
        none_radio.get_style_context ().add_class ("h3");
        none_radio.margin_start = 12;
        none_radio.margin_top = 6;

        var double_radio = new Gtk.RadioButton.with_label_from_widget (none_radio, _("Double Click"));
        double_radio.get_style_context ().add_class ("h3");
        double_radio.margin_start = 12;
        double_radio.margin_top = 3;

        var triple_radio = new Gtk.RadioButton.with_label_from_widget (none_radio, _("Triple Click"));
        triple_radio.get_style_context ().add_class ("h3");
        triple_radio.margin_start = 12;
        triple_radio.margin_top = 3;
        triple_radio.margin_bottom = 6;

        int index = Application.settings.get_enum ("quick-save");

        if (index == 0) {
            none_radio.active = true;
        } else if (index == 1) {
            double_radio.active = true;
        } else if (index == 2) {
            triple_radio.active = true;
        }

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (description_box);
        grid.add (none_radio);
        grid.add (double_radio);
        grid.add (triple_radio);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (grid);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (top_box);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (scrolled);

        var main_frame = new Gtk.Frame (null);
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (main_grid);

        back_button.clicked.connect (() => {
            check_quick_save_preview ();
            main_stack.visible_child_name = "general";
        });

        none_radio.toggled.connect (() => {
            Application.settings.set_enum ("quick-save", 0);
        });

        double_radio.toggled.connect (() => {
            Application.settings.set_enum ("quick-save", 1);
        });

        triple_radio.toggled.connect (() => {
            Application.settings.set_enum ("quick-save", 2);
        });

        return main_frame;
    }

    private Gtk.Widget get_weather_widget () {
        var back_button = new Gtk.Button.with_label (_("Back"));
        back_button.can_focus = false;
        back_button.valign = Gtk.Align.CENTER;
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Weather")));
        title_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin = 6;
        top_box.hexpand = true;
        top_box.pack_start (back_button, false, false, 0);
        top_box.set_center_widget (title_label);

        var icon = new Gtk.Image ();
        icon.gicon = new ThemedIcon ("applications-internet");
        icon.pixel_size = 32;

        var label = new Gtk.Label (_("Get the weather forecast in a simple and beautiful widget."));
        label.get_style_context ().add_class ("h3");
        label.wrap = true;

        var description_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        description_box.margin = 10;
        description_box.hexpand = true;
        description_box.pack_start (icon, false, false, 0);
        description_box.pack_start (label, false, false, 6);

        var temperature_label = new Granite.HeaderLabel (_("Temperature"));
        temperature_label.margin_start = 12;

        var temperature_modebutton = new Granite.Widgets.ModeButton ();
        temperature_modebutton.margin_start = 12;
        temperature_modebutton.valign = Gtk.Align.CENTER;
        temperature_modebutton.halign = Gtk.Align.START;
        temperature_modebutton.append_text (_("°F"));
        temperature_modebutton.append_text (_("°C"));
        temperature_modebutton.selected = Application.settings.get_enum ("weather-unit-format");

        var location_label = new Granite.HeaderLabel (_("Location"));
        location_label.margin_start = 12;

        var manual_location_entry = new Gtk.Entry ();
        manual_location_entry.placeholder_text = "Seattle, US";
        manual_location_entry.text = Application.settings.get_string ("location-manual-value");

        var location_help_button = new Gtk.Button.from_icon_name ("help-contents-symbolic", Gtk.IconSize.MENU);
        location_help_button.can_focus = false;

        var manual_location_grid = new Gtk.Grid ();
        manual_location_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        manual_location_grid.add (manual_location_entry);
        manual_location_grid.add (location_help_button);

        var automatic_label = new Gtk.Label (_("Automatic:"));

        var automatic_switch = new Gtk.Switch ();
        automatic_switch.tooltip_text = _("Automatic Location");
        automatic_switch.active = Application.settings.get_boolean ("location-automatic");

        var location_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        location_box.margin_start = 12;
        location_box.margin_end = 12;
        location_box.pack_start (manual_location_grid, false, false, 0);
        location_box.pack_start (automatic_label, false, false, 6);
        location_box.pack_start (automatic_switch, false, false, 0);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (description_box);
        grid.add (temperature_label);
        grid.add (temperature_modebutton);
        grid.add (location_label);
        grid.add (location_box);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (grid);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (top_box);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (scrolled);

        var main_frame = new Gtk.Frame (null);
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (main_grid);

        back_button.clicked.connect (() => {
            check_weather_preview ();
            main_stack.visible_child_name = "general";
        });

        manual_location_entry.activate.connect (() =>{
            Application.settings.set_string ("location-manual-value", manual_location_entry.text);
            Application.notification.on_signal_location_manual ();
        });

        manual_location_entry.focus_out_event.connect (() => {
            Application.settings.set_string ("location-manual-value", manual_location_entry.text);
            Application.notification.on_signal_location_manual ();
            return false;
        });

        automatic_switch.notify["active"].connect (() => {
			if (automatic_switch.active) {
                Application.settings.set_boolean ("location-automatic", true);
                manual_location_entry.sensitive = false;

                Application.notification.on_signal_weather_update ();
			} else {
                Application.settings.set_boolean ("location-automatic", false);
			    manual_location_entry.sensitive = true;

                Application.notification.on_signal_location_manual ();
			}
		});

        location_help_button.clicked.connect (() => {
            try {
                Gtk.show_uri (null, "https://openweathermap.org/find?q=", 0);
            } catch (Error e) {
                stderr.printf ("Failed to open uri.\n");
            }
        });

        temperature_modebutton.mode_changed.connect (() => {
            Application.settings.set_enum ("weather-unit-format", temperature_modebutton.selected);
            Application.notification.on_signal_weather_update ();
        });

        return main_frame;
    }

    private Gtk.Widget get_calendar_widget () {
        var back_button = new Gtk.Button.with_label (_("Back"));
        back_button.can_focus = false;
        back_button.valign = Gtk.Align.CENTER;
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Calendar Events")));
        title_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin = 6;
        top_box.hexpand = true;
        top_box.pack_start (back_button, false, false, 0);
        top_box.set_center_widget (title_label);

        var icon = new Gtk.Image ();
        icon.gicon = new ThemedIcon ("office-calendar");
        icon.pixel_size = 32;

        var label = new Gtk.Label (_("Events from your personal and shared calendars can be displayed."));
        label.get_style_context ().add_class ("h3");
        label.wrap = true;

        var description_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        description_box.margin = 10;
        description_box.hexpand = true;
        description_box.pack_start (icon, false, false, 0);
        description_box.pack_start (label, false, false, 0);

        var show_label = new Gtk.Label (_("Enabled"));
        show_label.margin_bottom = 1;
        show_label.get_style_context ().add_class ("h3");

        var show_switch = new Gtk.Switch ();
        show_switch.get_style_context ().add_class ("active-switch");
        show_switch.valign = Gtk.Align.CENTER;
        show_switch.active = Application.settings.get_boolean ("show-calendar-events");

        var show_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        show_box.margin_start = 12;
        show_box.pack_start (show_label, false, false, 0);
        show_box.pack_start (show_switch, false, false, 12);

        calendar_list = new Gtk.ListBox ();
        calendar_list.selection_mode = Gtk.SelectionMode.NONE;
        calendar_list.set_header_func (header_update_func);
        calendar_list.set_sort_func ((child1, child2) => {
            var comparison = ((Widgets.SourceItem)child1).location.collate (((Widgets.SourceItem)child2).location);
            if (comparison == 0)
                return ((Widgets.SourceItem)child1).label.collate (((Widgets.SourceItem)child2).label);
            else
                return comparison;
        });

        calendar_scroll = new Gtk.ScrolledWindow (null, null);
        calendar_scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
        calendar_scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
        calendar_scroll.expand = true;
        calendar_scroll.add (calendar_list);

        var calendar_list_revealer = new Gtk.Revealer ();
        calendar_list_revealer.margin_start = 6;
        calendar_list_revealer.margin_top = 6;
        calendar_list_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        calendar_list_revealer.add (calendar_scroll);
        calendar_list_revealer.reveal_child = true;

        src_map = new GLib.HashTable<string, Widgets.SourceItem?>(str_hash, str_equal);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (description_box);
        grid.add (show_box);
        grid.add (calendar_list_revealer);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.expand = true;
        scrolled.add (grid);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (top_box);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (scrolled);

        var main_frame = new Gtk.Frame (null);
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (main_grid);

        populate.begin ();

        back_button.clicked.connect (() => {
            main_stack.visible_child_name = "general";
            check_calendar_preview ();
        });

        show_switch.notify["active"].connect(() => {
            calendar_list_revealer.reveal_child = show_switch.active;
            Application.settings.set_boolean ("show-calendar-events", show_switch.active);
        });

        return main_frame;
    }

    private void check_start_page_preview () {
        int index = Application.settings.get_enum ("start-page");

        if (index == 0) {
            start_page_preview_label.label = _("Inbox");
        } else if (index == 1) {
            start_page_preview_label.label = _("Today");
        } else if (index == 2) {
            start_page_preview_label.label = _("Upcoming");
        }
    }

    private void check_badge_count_preview () {
        int index = Application.settings.get_enum ("badge-count");

        if (index == 0) {
            badge_count_preview_label.label = _("None");
        } else if (index == 1) {
            badge_count_preview_label.label = _("Inbox");
        } else if (index == 2) {
            badge_count_preview_label.label = _("Today");
        } else if (index == 3) {
            badge_count_preview_label.label = "%s + %s".printf (_("Today"), _("Inbox"));
        } else if (index == 4) {
            badge_count_preview_label.label = _("Notifications");
        }
    }

    private void check_quick_save_preview () {
        int index = Application.settings.get_enum ("quick-save");

        if (index == 0) {
            quick_save_preview_label.label = _("None");
        } else if (index == 1) {
            quick_save_preview_label.label = _("Double Click");
        } else if (index == 2) {
            quick_save_preview_label.label = _("Triple Click");
        }
    }

    private void check_weather_preview () {
        string location = "";
        string unit = "";

        if (Application.settings.get_boolean ("location-automatic")) {
            location = _("Automatic Location");
        } else {
            location = Application.settings.get_string ("location-manual-value");
        }

        if (Application.settings.get_enum ("weather-unit-format") == 0) {
            unit = "°F";
        } else {
            unit = "°C";
        }

        weather_preview_label.label = "%s / %s".printf (location, unit);
    }

    private void check_calendar_preview () {
        if (Application.settings.get_boolean ("show-calendar-events")) {
            calendar_preview_label.label = _("Enabled");
        } else {
            calendar_preview_label.label = _("Disabled");
        }
    }

    private Gtk.Widget get_about_widget () {
        var planner_icon = new Gtk.Image ();
        planner_icon.gicon = new ThemedIcon ("com.github.alainm23.planner");
        planner_icon.pixel_size = 64;
        planner_icon.margin_top = 12;
        planner_icon.halign = Gtk.Align.CENTER;
        planner_icon.hexpand = true;

        var planner_label = new Gtk.Label ("Planner 1.1.1");
        planner_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        planner_label.halign = Gtk.Align.CENTER;
        planner_label.hexpand = true;

        var planner_developer = new Gtk.Label ("Alain M.");
        planner_developer.halign = Gtk.Align.CENTER;
        planner_developer.hexpand = true;
		planner_developer.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
		planner_developer.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        var home_button = new Gtk.Button.from_icon_name ("go-home-symbolic", Gtk.IconSize.MENU);
        home_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        home_button.width_request = 32;
        home_button.height_request = 32;
        home_button.can_focus = false;
        home_button.get_style_context ().add_class ("button-circular");

        home_button.clicked.connect (() => {
            try {
                Gtk.show_uri (null, "https://github.com/alainm23/planner", 1000);
            } catch (Error e) {
                stderr.printf ("Error open the uri\n");
            } 
        });

        var issues_button = new Gtk.Button.from_icon_name ("bug-symbolic", Gtk.IconSize.MENU);
        issues_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        issues_button.width_request = 32;
        issues_button.height_request = 32;
        issues_button.can_focus = false;
        issues_button.get_style_context ().add_class ("button-circular");

        issues_button.clicked.connect (() => {
            try {
                Gtk.show_uri (null, "https://github.com/alainm23/planner/issues", 1000);
            } catch (Error e) {
                stderr.printf ("Error open the uri\n");
            } 
        });

        var translate_button = new Gtk.Button.from_icon_name ("preferences-desktop-locale-symbolic", Gtk.IconSize.MENU);
        translate_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        translate_button.width_request = 32;
        translate_button.height_request = 32;
        translate_button.can_focus = false;
        translate_button.get_style_context ().add_class ("button-circular");

        issues_button.clicked.connect (() => {
            try {
                Gtk.show_uri (null, "https://github.com/alainm23/planner/tree/master/po#readme", 1000);
            } catch (Error e) {
                stderr.printf ("Error open the uri\n");
            }
        });

        var donation_button = new Gtk.Button.from_icon_name ("face-heart", Gtk.IconSize.MENU);
        donation_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        donation_button.width_request = 32;
        donation_button.height_request = 32;
        donation_button.can_focus = false;
        donation_button.get_style_context ().add_class ("button-circular");

        donation_button.clicked.connect (() => {
            try {
                Gtk.show_uri (null, "https://www.paypal.me/alainm23", 1000);
            } catch (Error e) {
                stderr.printf ("Error open the uri\n");
            }
        });

        var grid = new Gtk.Grid ();
        grid.margin_bottom = 12;
        grid.margin_top = 12;
        grid.halign = Gtk.Align.CENTER;
        grid.column_spacing = 12;
        grid.add (home_button);
        grid.add (issues_button);
        grid.add (translate_button);
        grid.add (donation_button);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (planner_icon);
        main_grid.add (planner_label);
        main_grid.add (planner_developer);
        main_grid.add (grid);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        var main_frame = new Gtk.Frame (null);
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (main_grid);

        /*
        tutorial_project_button.clicked.connect (() => {
            tutorial_project_button.visible = false;
            loading_spinner.visible = true;
            loading_spinner.no_show_all = false;

            Application.utils.create_tutorial_project ();

            Application.notification.send_local_notification (
                _("Tutorial Project Created"),
                _("A tutorial project has been created."),
                "help-about",
                4,
                false
            );

            destroy ();
        });
        */

        return main_frame;
    }

    private Gtk.Widget get_general_widget () {
        int pixel_size = 24;

        // Badge Count
        var badge_count_icon = new Gtk.Image ();
        badge_count_icon.gicon = new ThemedIcon ("planner-badge-count");
        badge_count_icon.pixel_size = pixel_size;

        var badge_count_label = new Gtk.Label (_("Badge Count"));
        badge_count_label.get_style_context ().add_class ("h3");

        badge_count_preview_label = new Gtk.Label (null);
        check_badge_count_preview ();

        var badge_count_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        badge_count_box.margin = 6;
        badge_count_box.margin_end = 12;
        badge_count_box.hexpand = true;
        badge_count_box.pack_start (badge_count_icon, false, false, 0);
        badge_count_box.pack_start (badge_count_label, false, false, 6);
        badge_count_box.pack_end (badge_count_preview_label, false, false, 0);

        var badge_count_eventbox = new Gtk.EventBox ();
        badge_count_eventbox.add (badge_count_box);

        // Show Items
        var items_icon = new Gtk.Image ();
        items_icon.gicon = new ThemedIcon ("bookmark-new");
        items_icon.pixel_size = pixel_size;

        var items_label = new Gtk.Label (_("Items"));
        items_label.get_style_context ().add_class ("h3");

        var items_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        items_box.margin = 6;
        items_box.margin_end = 12;
        items_box.hexpand = true;
        items_box.pack_start (items_icon, false, false, 0);
        items_box.pack_start (items_label, false, false, 6);

        var items_eventbox = new Gtk.EventBox ();
        items_eventbox.add (items_box);

        // Start Page
        var start_page_icon = new Gtk.Image ();
        start_page_icon.gicon = new ThemedIcon ("user-home");
        start_page_icon.pixel_size = pixel_size;

        var start_page_label = new Gtk.Label (_("Start Page"));
        start_page_label.get_style_context ().add_class ("h3");

        start_page_preview_label = new Gtk.Label (null);
        check_start_page_preview ();

        var start_page_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        start_page_box.margin = 6;
        start_page_box.margin_end = 12;
        start_page_box.hexpand = true;
        start_page_box.pack_start (start_page_icon, false, false, 0);
        start_page_box.pack_start (start_page_label, false, false, 6);
        start_page_box.pack_end (start_page_preview_label, false, false, 0);

        var start_page_eventbox = new Gtk.EventBox ();
        start_page_eventbox.add (start_page_box);

        // Quick save
        var quick_save_icon = new Gtk.Image ();
        quick_save_icon.gicon = new ThemedIcon ("input-mouse");
        quick_save_icon.pixel_size = pixel_size;

        var quick_save_label = new Gtk.Label (_("Quick Save"));
        quick_save_label.get_style_context ().add_class ("h3");

        quick_save_preview_label = new Gtk.Label (null);
        check_quick_save_preview ();

        var quick_save_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        quick_save_box.margin = 6;
        quick_save_box.margin_end = 12;
        quick_save_box.hexpand = true;
        quick_save_box.pack_start (quick_save_icon, false, false, 0);
        quick_save_box.pack_start (quick_save_label, false, false, 6);
        quick_save_box.pack_end (quick_save_preview_label, false, false, 0);

        var quick_save_eventbox = new Gtk.EventBox ();
        quick_save_eventbox.add (quick_save_box);

        // Weather
        var weather_icon = new Gtk.Image ();
        weather_icon.gicon = new ThemedIcon ("applications-internet");
        weather_icon.pixel_size = pixel_size;

        var weather_label = new Gtk.Label (_("Weather"));
        weather_label.get_style_context ().add_class ("h3");

        weather_preview_label = new Gtk.Label (null);
        check_weather_preview ();

        var weather_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        weather_box.margin = 6;
        weather_box.margin_end = 12;
        weather_box.hexpand = true;
        weather_box.pack_start (weather_icon, false, false, 0);
        weather_box.pack_start (weather_label, false, false, 6);
        weather_box.pack_end (weather_preview_label, false, false, 0);

        var weather_eventbox = new Gtk.EventBox ();
        weather_eventbox.add (weather_box);

        // Calendar
        var calendar_icon = new Gtk.Image ();
        calendar_icon.gicon = new ThemedIcon ("office-calendar");
        calendar_icon.pixel_size = pixel_size;

        var calendar_label = new Gtk.Label (_("Calendar Events"));
        calendar_label.get_style_context ().add_class ("h3");

        calendar_preview_label = new Gtk.Label (null);
        check_calendar_preview ();

        var calendar_list = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        calendar_list.margin = 6;
        calendar_list.margin_end = 12;
        calendar_list.hexpand = true;
        calendar_list.pack_start (calendar_icon, false, false, 0);
        calendar_list.pack_start (calendar_label, false, false, 6);
        calendar_list.pack_end (calendar_preview_label, false, false, 0);

        var calendar_eventbox = new Gtk.EventBox ();
        calendar_eventbox.add (calendar_list);

        // Run Background
        var run_background_icon = new Gtk.Image ();
        run_background_icon.gicon = new ThemedIcon ("preferences-system");
        run_background_icon.pixel_size = pixel_size;

        var run_background_label = new Gtk.Label (_("Run in background"));
        run_background_label.get_style_context ().add_class ("h3");

        var run_background_switch = new Gtk.Switch ();
        run_background_switch.valign = Gtk.Align.CENTER;
        run_background_switch.get_style_context ().add_class ("active-switch");
        run_background_switch.active = Application.settings.get_boolean ("run-background");

        var run_background_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        run_background_box.margin = 6;
        run_background_box.margin_end = 12;
        run_background_box.hexpand = true;
        run_background_box.tooltip_text = _("Let Planner run in background and send notifications.");
        run_background_box.pack_start (run_background_icon, false, false, 0);
        run_background_box.pack_start (run_background_label, false, false, 6);
        run_background_box.pack_end (run_background_switch, false, false, 0);

        var run_background_eventbox = new Gtk.EventBox ();
        run_background_eventbox.add (run_background_box);

        // Launch at login
        var launch_icon = new Gtk.Image ();
        launch_icon.gicon = new ThemedIcon ("system-shutdown");
        launch_icon.pixel_size = pixel_size;

        var launch_icon_label = new Gtk.Label (_("Launch at Login"));
        launch_icon_label.get_style_context ().add_class ("h3");

        var launch_switch = new Gtk.Switch ();
        launch_switch.valign = Gtk.Align.CENTER;
        launch_switch.get_style_context ().add_class ("active-switch");
        launch_switch.active = Application.settings.get_boolean ("launch-login");

        var launch_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        launch_box.margin = 6;
        launch_box.margin_end = 12;
        launch_box.hexpand = true;
        launch_box.pack_start (launch_icon, false, false, 0);
        launch_box.pack_start (launch_icon_label, false, false, 6);
        launch_box.pack_end (launch_switch, false, false, 0);

        var launch_eventbox = new Gtk.EventBox ();
        launch_eventbox.add (launch_box);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (badge_count_eventbox);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (start_page_eventbox);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (quick_save_eventbox);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (weather_eventbox);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (calendar_eventbox);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        //main_grid.add (items_eventbox);
       //main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (run_background_eventbox);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (launch_eventbox);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (main_grid);

        var main_frame = new Gtk.Frame (null);
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (scrolled);

        // Events
        badge_count_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                main_stack.visible_child_name = "badge_count";
            }

            return false;
        });

        start_page_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                main_stack.visible_child_name = "start_page";
            }

            return false;
        });

        quick_save_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                main_stack.visible_child_name = "quick_save";
            }

            return false;
        });

        weather_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                main_stack.visible_child_name = "weather";
            }

            return false;
        });

        calendar_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                main_stack.visible_child_name = "calendar";
            }

            return false;
        });

        items_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                main_stack.visible_child_name = "items";
            }

            return false;
        });

        run_background_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                if (run_background_switch.active) {
                    run_background_switch.active = false;
                } else {
                    run_background_switch.active = true;
                }
            }

            return false;
        });

        launch_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                if (launch_switch.active) {
                    launch_switch.active = false;
                } else {
                    launch_switch.active = true;
                }
            }

            return false;
        });

        run_background_switch.notify["active"].connect (() => {
            if (run_background_switch.active) {
                Application.settings.set_boolean ("run-background", true);
            } else {
                Application.settings.set_boolean ("run-background", false);
            }
        });

        launch_switch.notify["active"].connect (() => {
            if (launch_switch.active) {
                set_autostart (true);
                Application.settings.set_boolean ("launch-login", true);
            } else {
                set_autostart (false);
                Application.settings.set_boolean ("launch-login", false);
            }
        });

        return main_frame;
    }

    private void set_autostart (bool active) {
        var desktop_file_name = "com.github.alainm23.planner.desktop";
        var desktop_file_path = new DesktopAppInfo (desktop_file_name).filename;
        var desktop_file = File.new_for_path (desktop_file_path);
        var dest_path = Path.build_path (Path.DIR_SEPARATOR_S,
                                         Environment.get_user_config_dir (),
                                         "autostart",
                                         desktop_file_name);
        var dest_file = File.new_for_path (dest_path);
        try {
            desktop_file.copy (dest_file, FileCopyFlags.OVERWRITE);
        } catch (Error e) {
            warning ("Error making copy of desktop file for autostart: %s", e.message);
        }

        var keyfile = new KeyFile ();
        try {
            keyfile.load_from_file (dest_path, KeyFileFlags.NONE);
            keyfile.set_boolean ("Desktop Entry", "X-GNOME-Autostart-enabled", active);
            keyfile.save_to_file (dest_path);
        } catch (Error e) {
            warning ("Error enabling autostart: %s", e.message);
        }
    }

    public async void populate () {
        try {
            var registry = yield new E.SourceRegistry (null);
            //registry.source_disabled.connect (source_disabled);
            registry.source_enabled.connect (add_source_to_view);
            registry.source_added.connect (add_source_to_view);

            // Add sources
            registry.list_sources (E.SOURCE_EXTENSION_CALENDAR).foreach ((source) => {
                add_source_to_view (source);
            });
        } catch (GLib.Error error) {
            critical (error.message);
        }
    }

    private void header_update_func (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
        var row_location = ((Widgets.SourceItem)row).location;
        if (before != null) {
            var before_row_location = ((Widgets.SourceItem)before).location;
            if (before_row_location == row_location) {
                row.set_header (null);
                return;
            }
        }

        var header = new Widgets.SourceItemHeader (row_location);
        row.set_header (header);
        header.show_all ();
    }

    private void add_source_to_view (E.Source source) {
        if (source.enabled == false)
            return;

        if (source.dup_uid () in src_map)
            return;

        var source_item = new Widgets.SourceItem (source);
        //source_item.edit_request.connect (edit_source);

        calendar_list.add (source_item);

        int minimum_height;
        int natural_height;
        calendar_list.show_all ();
        calendar_list.get_preferred_height (out minimum_height, out natural_height);
        if (natural_height > 200) {
            calendar_scroll.set_size_request (-1, 200);
        } else {
            calendar_scroll.set_size_request (-1, natural_height);
        }

        source_item.destroy.connect (() => {
            calendar_list.show_all ();
            calendar_list.get_preferred_height (out minimum_height, out natural_height);
            if (natural_height > 200) {
                calendar_scroll.set_size_request (-1, 200);
            } else {
                calendar_scroll.set_size_request (-1, natural_height);
            }
        });

        src_map.set (source.dup_uid (), source_item);
    }
}

public class ThemeChild : Gtk.FlowBoxChild {
    private Gtk.Image image;
    private Gtk.Label name_label;
    public int id { get; construct; }

    public string title {
        get {
            return name_label.label;
        }
        set {
            name_label.label = value;
        }
    }

    public string icon_name {
        owned get {
            return image.icon_name ?? "";
        }
        set {
            if (value != null && value != "") {
                image.gicon = new ThemedIcon (value);
                image.pixel_size = 64;
                image.no_show_all = false;
                image.show ();
            } else {
                image.no_show_all = true;
                image.hide ();
            }
        }
    }

    public ThemeChild (int id, string title, string icon_name) {
        Object (
            id: id,
            title: title,
            icon_name: icon_name
        );
    }

    construct {
        margin = 12;

        name_label = new Gtk.Label (null);
        name_label.halign = Gtk.Align.CENTER;
        name_label.hexpand = true;
        name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        image = new Gtk.Image ();
        image.valign = Gtk.Align.START;

        var grid = new Gtk.Grid ();
        grid.margin = 3;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.halign = Gtk.Align.CENTER;
        grid.valign = Gtk.Align.CENTER;
        grid.vexpand = true;

        grid.add (image);
        grid.add (name_label);

        add (grid);
    }
}
