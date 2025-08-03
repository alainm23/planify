/*
 * Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
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

public class Widgets.SyncButton : Adw.Bin {
    private Gtk.Revealer main_revealer;
    private Gtk.Stack stack;
    private Gtk.Button sync_button;

    public signal void clicked ();

    public bool reveal_child {
        set {
            main_revealer.reveal_child = value;
        }
    }

    construct {
        sync_button = new Gtk.Button.from_icon_name ("update-symbolic") {
            valign = Gtk.Align.CENTER,
            css_classes = { "flat", "header-item-button", "dim-label" }
        };

        var error_button = new Gtk.Button.from_icon_name ("dialog-warning-symbolic") {
            valign = Gtk.Align.CENTER,
            css_classes = { "flat", "header-item-button", "dim-label" }
        };

        stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        stack.add_named (sync_button, "sync");
        stack.add_named (error_button, "error");

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = stack
        };

        child = main_revealer;

        Timeout.add (main_revealer.transition_duration, () => {
            return GLib.Source.REMOVE;
        });

        sync_button.clicked.connect (() => {
            clicked ();
        });

        error_button.clicked.connect (() => {
            clicked ();
        });
    }

    public void sync_started () {
        stack.visible_child_name = "sync";
        tooltip_markup = "";
        sync_button.add_css_class ("is_loading");
    }

    public void sync_finished () {
        sync_button.remove_css_class ("is_loading");
    }

    public void sync_failed () {
        sync_button.remove_css_class ("is_loading");
        stack.visible_child_name = "error";
        tooltip_markup = "<b>%s</b>\n%s".printf (_("Failed to connect to server"), _("It looks like the server is unreachable,\nare you connected to the internet?\nAny changes you make while disconnected\nwill be synchronized when you reconnect.")); // vala-lint=line-length
    }
}
