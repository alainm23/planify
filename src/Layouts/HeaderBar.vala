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

public class Layouts.HeaderBar : Adw.Bin {
    private Adw.HeaderBar headerbar;
    private Gtk.Label title_label;
    private Gtk.Label subtitle_label;
    private Gtk.Revealer subtitle_revealer;
    private Gtk.Revealer title_box_revealer;
    private Gtk.Revealer back_button_revealer;
    private Gtk.Button back_button;
    private Gtk.Button sidebar_button;

    private string _title;
    public string title {
        set {
            _title = value;
            title_label.label = _title;
        }

        get {
            return _title;
        }
    }

    private string _subtitle;
    public string subtitle {
        set {
            _subtitle = value;
            subtitle_label.label = _subtitle;
            subtitle_revealer.reveal_child = _subtitle.length > 0;
        }

        get {
            return _title;
        }
    }

    public bool back_revealer {
        set {
            back_button_revealer.reveal_child = value;
        }

        get {
            return back_button_revealer.reveal_child;
        }
    }

    public signal void back_activated ();

    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    ~HeaderBar () {
        debug ("Destroying - Layouts.HeaderBar\n");
    }

    construct {
        sidebar_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            css_classes = { "flat" },
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Open/Close Sidebar"), "M"),
        };

        update_sidebar_icon ();

        // Back Button
        back_button = new Gtk.Button.from_icon_name ("go-previous-symbolic") {
            valign = Gtk.Align.CENTER,
            css_classes = { "flat" },
            tooltip_text = _("Back")
        };

        back_button_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = back_button,
            reveal_child = false
        };

        // Title
        title_label = new Gtk.Label (null) {
            css_classes = { "font-bold" },
            ellipsize = END
        };

        subtitle_label = new Gtk.Label (null) {
            css_classes = { "caption", "dimmed" },
            ellipsize = END
        };

        subtitle_revealer = new Gtk.Revealer () {
            transition_type = SLIDE_DOWN,
            child = subtitle_label
        };

        var title_box = new Gtk.Box (VERTICAL, 0) {
            valign = CENTER,
            halign = CENTER
        };

        title_box.append (title_label);
        title_box.append (subtitle_revealer);

        title_box_revealer = new Gtk.Revealer () {
            transition_type = CROSSFADE,
            child = title_box
        };

        headerbar = new Adw.HeaderBar () {
            hexpand = true,
            title_widget = title_box_revealer,
        };

        headerbar.pack_start (sidebar_button);
        headerbar.pack_start (back_button_revealer);

        child = headerbar;

        signal_map[sidebar_button.clicked.connect (() => {
            bool slim_mode = Services.Settings.get_default ().settings.get_boolean ("slim-mode");
            Services.Settings.get_default ().settings.set_boolean ("slim-mode", !slim_mode);
        })] = sidebar_button;

        signal_map[back_button.clicked.connect (() => {
            back_activated ();
        })] = back_button;

        signal_map[Services.Settings.get_default ().settings.changed["slim-mode"].connect (() => {
            update_sidebar_icon ();
        })] = Services.Settings.get_default ();
    }

    private void update_sidebar_icon () {
        if (Services.Settings.get_default ().settings.get_boolean ("slim-mode")) {
            sidebar_button.icon_name = "dock-right-symbolic";
        } else {
            sidebar_button.icon_name = "dock-left-symbolic";
        }
    }

    public void pack_end (Gtk.Widget widget) {
        headerbar.pack_end (widget);
    }

    public void revealer_title_box (bool reveal) {
        title_box_revealer.reveal_child = reveal;
    }

    public void update_title_box_visibility (bool visible) {
        title_box_revealer.reveal_child = visible;
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }
}
