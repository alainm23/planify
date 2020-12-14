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

public class Widgets.ToolsMenu : Gtk.Revealer {
    private Widgets.SyncButton sync_menu;

    construct {
        transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        reveal_child = false;
        valign = Gtk.Align.END;
        halign = Gtk.Align.CENTER;

        var close_image = new Gtk.Image ();
        close_image.gicon = new ThemedIcon ("close-symbolic");
        close_image.pixel_size = 12;

        var close_button = new Gtk.Button ();
        close_button.tooltip_markup = Granite.markup_accel_tooltip ({"Escape"}, _("Close"));
        close_button.image = close_image;
        close_button.valign = Gtk.Align.START;
        close_button.halign = Gtk.Align.START;
        close_button.get_style_context ().add_class ("close-button");

        var preferences_menu = new Widgets.ToolMenuItem (_("Preferences"), {"Ctrl", ","});
        var whats_new_menu = new Widgets.ToolMenuItem (_("What's new"), {});
        var keyboard_menu = new Widgets.ToolMenuItem (_("Keyboard shortcuts"), {"f1"});

        sync_menu = new Widgets.SyncButton ();
        sync_menu.visible = Planner.settings.get_boolean ("todoist-account");
        sync_menu.no_show_all = !Planner.settings.get_boolean ("todoist-account");

        var sync_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3,
            visible = Planner.settings.get_boolean ("todoist-account"),
            no_show_all = !Planner.settings.get_boolean ("todoist-account")
        };

        var content_grid = new Gtk.Grid ();
        content_grid.orientation = Gtk.Orientation.VERTICAL;
        content_grid.margin_top = 3;
        content_grid.margin_bottom = 3;
        content_grid.add (preferences_menu);
        content_grid.add (keyboard_menu);
        content_grid.add (whats_new_menu);
        content_grid.add (sync_separator);
        content_grid.add (sync_menu);

        var main_grid = new Gtk.Grid ();
        main_grid.margin = 9;
        main_grid.width_request = 240;
        main_grid.expand = false;
        main_grid.get_style_context ().add_class ("add-project-widget");
        main_grid.add (content_grid);
        
        var overlay = new Gtk.Overlay ();
        overlay.add_overlay (close_button);
        overlay.add (main_grid);

        add (overlay);
        check_network_available ();
        var network_monitor = GLib.NetworkMonitor.get_default ();
        network_monitor.network_changed.connect (() => {
            check_network_available ();
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "todoist-account") {
                sync_menu.visible = Planner.settings.get_boolean ("todoist-account");
                sync_menu.no_show_all = !Planner.settings.get_boolean ("todoist-account");

                sync_separator.visible = Planner.settings.get_boolean ("todoist-account");
                sync_separator.no_show_all = !Planner.settings.get_boolean ("todoist-account");
            }
        });

        sync_menu.clicked.connect (() => {
            Planner.todoist.sync ();
        });

        Planner.todoist.sync_started.connect (() => {
            sync_menu.sensitive = false;
            sync_menu.is_loading = true;
        });

        Planner.todoist.sync_finished.connect (() => {
            sync_menu.sensitive = true;
            sync_menu.is_loading = false;
        });


        close_button.clicked.connect (() => {
            reveal_child = false;
        });

        preferences_menu.clicked.connect (() => {
            reveal_child = false;
            var dialog = new Dialogs.Preferences.Preferences ();
            dialog.destroy.connect (Gtk.main_quit);
            dialog.show_all ();
        });

        whats_new_menu.clicked.connect (() => {
            reveal_child = false;
            Planner.utils.open_whats_new_dialog ();
        });

        keyboard_menu.clicked.connect (() => {
            reveal_child = false;
            var dialog = new Dialogs.ShortcutsDialog ();
            dialog.destroy.connect (Gtk.main_quit);
            dialog.show_all ();
        });
    }

    public void check_network_available () {
        sync_menu.network_available = GLib.NetworkMonitor.get_default ().get_network_available ();
    }
}

public class Widgets.ToolMenuItem : Gtk.Button {
    public string[] accels { get; construct; }
    public string text { get; construct; }

    public ToolMenuItem (string text, string[] accels) {
        Object (
            text: text,
            accels: accels
        );
    }

    construct {
        get_style_context ().remove_class ("button");
        get_style_context ().add_class ("flat");
        get_style_context ().add_class ("menuitem");
        get_style_context ().add_class ("no-border");
        can_focus = false;

        var item_label = new Gtk.Label (text);
        item_label.get_style_context ().add_class ("font-weight-600");

        var shortcut_label = new Widgets.ShortcutLabel (accels);

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        box.hexpand = true;
        box.margin_start = 3;
        box.margin_end = 3;
        box.pack_start (item_label, false, true, 0);
        box.pack_end (shortcut_label, false, false, 0);

        add (box);
    }
}

public class Widgets.SyncButton : Gtk.Button {
    private Gtk.Stack stack;
    private Gtk.Image sync_image;
    private Gtk.Image error_image;
    private Gtk.Label item_label;
    
    public bool network_available {
        set {
            if (value) {
                stack.visible_child_name = "sync_image";
                tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl>S"}, _("Sync"));
            } else {
                stack.visible_child_name = "error_image";
                tooltip_markup = "<b>%s</b>\n%s".printf (_("Offline mode is on"), _("Looks like you'are not connected to the\ninternet. Changes you make in offline\nmode will be synced when you reconnect")); // vala-lint=line-length
            }
        }
    }

    public bool is_loading {
        set {
            if (value) {
                item_label.label = _("Sync…");
                sync_image.get_style_context ().add_class ("is_loading");
            } else {
                item_label.label = _("Sync Now");
                sync_image.get_style_context ().remove_class ("is_loading");
            }
        }
    }

    construct {
        get_style_context ().remove_class ("button");
        get_style_context ().add_class ("flat");
        get_style_context ().add_class ("menuitem");
        get_style_context ().add_class ("no-border");
        can_focus = false;

        item_label = new Gtk.Label (_("Sync Now"));
        item_label.get_style_context ().add_class ("font-weight-600");

        sync_image = new Gtk.Image ();
        sync_image.gicon = new ThemedIcon ("emblem-synchronizing-symbolic");
        sync_image.get_style_context ().add_class ("sync-image-rotate");
        sync_image.pixel_size = 16;

        error_image = new Gtk.Image ();
        error_image.gicon = new ThemedIcon ("dialog-warning-symbolic");
        error_image.pixel_size = 16;
        
        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        stack.add_named (sync_image, "sync_image");
        stack.add_named (error_image, "error_image");

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        box.hexpand = true;
        box.margin_start = 3;
        box.margin_end = 3;
        box.pack_start (item_label, false, true, 0);
        box.pack_end (stack, false, false, 0);

        add (box);
    }
}
