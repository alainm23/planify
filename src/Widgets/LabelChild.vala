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

public class Widgets.LabelChild : Gtk.FlowBoxChild {
    public Objects.Label label { get; construct; }
    public bool show_close = true;
    public const string COLOR_CSS = """
        .label-%i {
            background-image:
                linear-gradient(
                    to bottom,
                    shade (
                    %s,
                        1.3
                    ),
                    %s
            );
            border: 1px solid shade (%s, 0.9);
            color: %s;
            border-radius: 3px;
            font-size: 11px;
            font-weight: 600;
            margin: 2px;
            padding: 0px 3px 0px 3px;
        }
    """;
    public LabelChild (Objects.Label _label) {
        Object (
            label: _label
        );
    }

    construct {
        get_style_context ().add_class ("label-child");

        var remove_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.MENU);
        remove_button.get_style_context ().add_class ("button-close");

        var remove_revealer = new Gtk.Revealer ();
        remove_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        remove_revealer.valign = Gtk.Align.START;
        remove_revealer.halign = Gtk.Align.START;
        remove_revealer.add (remove_button);
        remove_revealer.reveal_child = false;

        var name_label = new Gtk.Label (label.name);
        name_label.margin = 6;
        name_label.get_style_context ().add_class ("label-" + label.id.to_string ());

        var overlay = new Gtk.Overlay ();
        overlay.valign = Gtk.Align.START;
        //overlay.halign = Gtk.Align.START;
        overlay.add_overlay (remove_revealer);
        overlay.add (name_label);

        var eventbox = new Gtk.EventBox ();
        eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        eventbox.add (overlay);

        add (eventbox);
        show_all ();

        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (
                label.id,                                       // id
                label.color,
                label.color,
                label.color,                                    // Background Color
                Application.utils.convert_invert (label.color)  // Text Color
            );
            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }

        eventbox.enter_notify_event.connect ((event) => {
            if (show_close) {
                remove_revealer.reveal_child = true;
            }

            return false;
        });

        eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            if (show_close) {
                remove_revealer.reveal_child = false;
            }

            return false;
        });

        remove_button.clicked.connect (() => {
            Timeout.add (20, () => {
                this.opacity = this.opacity - 0.1;

                if (this.opacity <= 0) {
                    destroy ();
                    return false;
                }

                return true;
            });
        });
    }
}
