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

        var error_image = new Gtk.Image () {
            gicon = new ThemedIcon ("dialog-warning-symbolic"),
            pixel_size = 13
        };

        stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        stack.add_named (sync_button, "sync");
        stack.add_named (error_image, "error");

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = stack
        };

        child = main_revealer;

        Timeout.add (main_revealer.transition_duration, () => {
            network_available ();
            return GLib.Source.REMOVE;
        });

        sync_button.clicked.connect (() => {
            clicked ();
        });

        Services.NetworkMonitor.instance ().network_changed.connect (() => {
            network_available ();
        });
    }

    private void network_available () {
        if (Services.NetworkMonitor.instance ().network_available) {
            stack.visible_child_name = "sync";
        } else {
            stack.visible_child_name = "error";
            tooltip_markup = "<b>%s</b>\n%s".printf (_("Offline Mode Is On"), _("Looks like you'are not connected to the\ninternet. Changes you make in offline\nmode will be synced when you reconnect")); // vala-lint=line-length
        }
    }

    public void sync_started () {
        sync_button.add_css_class ("is_loading");
    }
    
    public void sync_finished () {
        sync_button.remove_css_class ("is_loading");
    }
}
