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

public class Widgets.Toast : Gtk.Revealer {
    public string title { get; construct; }
    public uint duration { get; construct; }

    private Gtk.Label message_label;
    

    public Toast (string title, uint duration) {
        Object (
            title: title,
            duration: duration
        );
    }

    construct {
        halign = Gtk.Align.CENTER;
        transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        reveal_child = false;

        var close_image = new Gtk.Image ();
        close_image.gicon = new ThemedIcon ("close-symbolic");
        close_image.pixel_size = 16;

        var close_button = new Gtk.Button ();
        close_button.valign = Gtk.Align.START;
        close_button.halign = Gtk.Align.START;
        close_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        close_button.get_style_context ().add_class ("magic-button");
        close_button.get_style_context ().add_class ("close-button");
        
        close_button.add (close_image);

        var close_revealer = new Gtk.Revealer ();
        close_revealer.valign = Gtk.Align.START;
        close_revealer.halign = Gtk.Align.START;
        close_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        close_revealer.add (close_button);

        message_label = new Gtk.Label (title){
            margin_bottom = 3
        };
        message_label.get_style_context ().add_class ("font-weight-600");
        message_label.use_markup = true;

        var notification_box = new Gtk.Grid ();
        notification_box.column_spacing = 6;
        notification_box.valign = Gtk.Align.CENTER;
        notification_box.add (message_label);

        var notification_frame = new Gtk.Frame (null);
        notification_frame.margin = 9;
        notification_frame.get_style_context ().add_class (Granite.STYLE_CLASS_CARD);
        notification_frame.add (notification_box);
        //  if (NotificationStyle.ERROR == notification_type) {
        //      notification_frame.get_style_context ().add_class ("error");
        //  }

        var notification_overlay = new Gtk.Overlay ();
        notification_overlay.add_overlay (close_revealer);
        notification_overlay.add (notification_frame);

        var notification_eventbox = new Gtk.EventBox ();
        notification_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        notification_eventbox.above_child = false;
        notification_eventbox.add (notification_overlay);

        add (notification_eventbox);

        close_button.clicked.connect (() => {
            reveal_child = false;
        });

        notification_eventbox.enter_notify_event.connect ((event) => {
            if (duration != -1) {
                close_revealer.reveal_child = true;
            }

            return true;
        });

        notification_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            close_revealer.reveal_child = false;
            return true;
        });
    }

    public void send_notification () {
        if (!child_revealed) {
            reveal_child = true;

            GLib.Timeout.add (duration, () => {
                reveal_child = false;
                return GLib.Source.REMOVE;
            });
        }
    }
}