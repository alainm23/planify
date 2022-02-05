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

public class Dialogs.Settings.Settings : Hdy.Window {
    public string view { get; construct; }

    private Gtk.Stack main_stack;
    public Gee.HashMap <string, Gtk.Widget> views;

    public Settings (string view = "settings") {
        Object (
            view: view,
            deletable: true,
            resizable: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            modal: true,
            width_request: 400,
            height_request: 500
        );
    }

    construct {
        unowned Gtk.StyleContext main_context = get_style_context ();
        main_context.add_class ("picker");
        transient_for = Planner.instance.main_window;

        views = new Gee.HashMap <string, Gtk.Widget> ();

        main_stack = new Gtk.Stack () {
            expand = true,
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT
        };

        var stack_scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        stack_scrolled.add (main_stack);
        
        add (stack_scrolled);

        Timeout.add (main_stack.transition_duration, () => {
            go_setting_view (view);
            return GLib.Source.REMOVE;
        });

        focus_out_event.connect (() => {
            hide_destroy ();
            return false;
        });

        key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_destroy ();
            }

            return false;
        });
    }

    private Gtk.Widget get_settings_view () {
        var settings_header = new Dialogs.Settings.SettingsHeader (_("Settings"), false);

        var general_content = new Dialogs.Settings.SettingsContent (_("General"));

        var appearance_item = new Dialogs.Settings.SettingsItem (
            "planner-appearance",
            _("Appearance"),
            Util.get_default ().get_theme_name ()
        );

        general_content.add_child (appearance_item);

        var contact_content = new Dialogs.Settings.SettingsContent (_("Contact us"));

        var mail_item = new Dialogs.Settings.SettingsItem (
            "planner-mail",
            _("Contact us"),
            _("Request a feature or ask us a question.")
        );

        var twitter_item = new Dialogs.Settings.SettingsItem (
            "planner-annotation-dots",
            _("Twitter"),
            _("Follow us on.")
        );

        var support_item = new Dialogs.Settings.SettingsItem (
            "planner-heart",
            _("Support & Credits"),
            _("Support us.")
        );

        contact_content.add_child (mail_item);
        contact_content.add_child (twitter_item);
        contact_content.add_child (support_item);

        var main_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START
        };
        
        main_grid.add (settings_header);
        main_grid.add (general_content);
        main_grid.add (contact_content);

        settings_header.done_activated.connect (() => {
            hide_destroy ();
        });

        appearance_item.activated.connect (() => {
            go_setting_view ("appearance");
        });

        mail_item.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://github.com/alainm23/planner/issues", null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

        twitter_item.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://twitter.com/planner_todo", null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

        support_item.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://useplanner.com/support/", null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "appearance") {
                appearance_item.description = Util.get_default ().get_theme_name ();
            }
        });

        main_grid.show_all ();
        return main_grid;
    }

    private Gtk.Widget get_appearance_view () {
        var settings_header = new Dialogs.Settings.SettingsHeader (_("Appearance"));

        var content = new Dialogs.Settings.SettingsContent (null);

        var light_item = new Gtk.RadioButton.with_label (null, _("Light")) {
            hexpand = true,
            margin_top = 3,
            margin_start = 6
        };
        var dark_item = new Gtk.RadioButton.with_label_from_widget (light_item, _("Dark")) {
            hexpand = true,
            margin_top = 3,
            margin_left = 6
        };
        var dark_blue_item = new Gtk.RadioButton.with_label_from_widget (light_item, _("Dark Blue")) {
            hexpand = true,
            margin_top = 3,
            margin_start = 6,
            margin_bottom = 6
        };

        content.add_child (light_item);
        content.add_child (dark_item);
        content.add_child (dark_blue_item);

        var main_grid = new Gtk.Grid () {
            expand = true,
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START
        };
        
        main_grid.add (settings_header);
        main_grid.add (content);

        int appearance = Planner.settings.get_enum ("appearance");
        if (appearance == 0) {
            light_item.active = true;
        } else if (appearance == 1) {
            dark_item.active = true;
        } else if (appearance == 2) {
            dark_blue_item.active = true;
        }

        settings_header.done_activated.connect (() => {
            hide_destroy ();
        });

        settings_header.back_activated.connect (() => {
            go_setting_view ("settings");
        });

        light_item.toggled.connect (() => {
            Planner.settings.set_enum ("appearance", 0);
        });

        dark_item.toggled.connect (() => {
            Planner.settings.set_enum ("appearance", 1);
        });

        dark_blue_item.toggled.connect (() => {
            Planner.settings.set_enum ("appearance", 2);
        });

        main_grid.show_all ();
        return main_grid;
    }

    private void go_setting_view (string view) {
        if (!views.has_key (view)) {
            views[view] = get_setting_view (view);
            main_stack.add_named (views[view], view);
        }

        main_stack.set_visible_child_name (view);
    }

    private Gtk.Widget? get_setting_view (string view) {
        Gtk.Widget? returned = null;

        switch (view) {
            case "settings":
                returned = get_settings_view ();
                break;
            case "appearance":
                returned = get_appearance_view ();
                break;
        }

        return returned;
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}