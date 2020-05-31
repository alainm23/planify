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
    private Gtk.Image notification_image;
    private Gtk.Revealer image_revealer;

    private Gtk.Label message_label;
    private Gtk.Button undo_button;
    private Gtk.Revealer undo_revealer;

    private uint main_timeout_id = 0;
    private int main_timeout = 0;

    private uint timeout_id = 0;
    private uint close_timeout = 0;

    private int64 _object_id = 0;
    private string _object_type = "";
    private string _undo_type = "";
    private string _undo_value = "";

    construct {
        margin_bottom = 6;
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.END;
        transition_type = Gtk.RevealerTransitionType.SLIDE_UP;

        var close_image = new Gtk.Image ();
        close_image.gicon = new ThemedIcon ("close-symbolic");
        close_image.pixel_size = 12;

        var close_button = new Gtk.Button ();
        close_button.image = close_image;
        close_button.valign = Gtk.Align.START;
        close_button.halign = Gtk.Align.START;
        close_button.get_style_context ().add_class ("close-button");

        var close_revealer = new Gtk.Revealer ();
        close_revealer.valign = Gtk.Align.START;
        close_revealer.halign = Gtk.Align.START;
        close_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        close_revealer.add (close_button);

        notification_image = new Gtk.Image ();
        notification_image.valign = Gtk.Align.CENTER;
        notification_image.pixel_size = 13;
        notification_image.get_style_context ().add_class ("notification-image");

        image_revealer = new Gtk.Revealer ();
        image_revealer.transition_duration = 0;
        image_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        image_revealer.add (notification_image);

        message_label = new Gtk.Label (null);
        message_label.get_style_context ().add_class ("font-weight-600");
        message_label.use_markup = true;

        undo_button = new Gtk.Button ();
        undo_button.margin_start = 6;
        undo_button.valign = Gtk.Align.CENTER;
        undo_button.label = _("Undo");

        undo_revealer = new Gtk.Revealer ();
        undo_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        undo_revealer.transition_duration = 0;
        undo_revealer.add (undo_button);

        var notification_box = new Gtk.Grid ();
        notification_box.column_spacing = 6;
        notification_box.valign = Gtk.Align.CENTER;
        notification_box.add (image_revealer);
        notification_box.add (message_label);
        notification_box.add (undo_revealer);

        var notification_frame = new Gtk.Frame (null);
        notification_frame.margin = 9;
        notification_frame.get_style_context ().add_class ("app-notification");
        notification_frame.add (notification_box);

        var notification_overlay = new Gtk.Overlay ();
        notification_overlay.add_overlay (close_revealer);
        notification_overlay.add (notification_frame);

        var notification_eventbox = new Gtk.EventBox ();
        notification_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        notification_eventbox.above_child = false;
        notification_eventbox.add (notification_overlay);

        add (notification_eventbox);

        undo_button.clicked.connect (() => {
            if (timeout_id != 0) {
                Source.remove (timeout_id);
            }

            reveal_child = false;

            if (_object_id != 0 && _undo_type != "") {
                if (_object_type == "item") {
                    var item = Planner.database.get_item_by_id (_object_id);

                    if (_undo_type == "delete") {
                        Planner.database.show_undo_item (item, _undo_type);
                    } else if (_undo_type == "complete") {
                        item.checked = 0;
                        item.date_completed = "";

                        Planner.database.update_item_completed (item);
                        if (item.is_todoist == 1) {
                            Planner.todoist.item_uncomplete (item);
                        }

                        Planner.database.show_undo_item (item, _undo_type);
                    } else if (_undo_type == "reschedule") {
                        Planner.database.update_item_recurring_due_date (item, -1);
                    }
                }
            }

            _object_id = 0;
            _object_type = "";
            _undo_type = "";
            _undo_value = "";

            // Planner.database.clear_item_to_delete ();
        });

        close_button.clicked.connect (() => {
            reveal_child = false;
            run ();
        });

        notification_eventbox.enter_notify_event.connect ((event) => {
            close_revealer.reveal_child = true;
            return true;
        });

        notification_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            close_revealer.reveal_child = false;

            return true;
        });

        Planner.notifications.send_notification.connect ((message, icon) => {
            send_simple_notification (message, icon);
        });

        Planner.notifications.send_undo_notification.connect ((object_id, object_type, undo_type, undo_value) => {
            send_undo_notification (object_id, object_type, undo_type, undo_value);
        });
    }

    public void send_simple_notification (string message, string icon) {
        main_timeout = 0;
        if (timeout_id != 0) {
            run ();

            Source.remove (timeout_id);

            main_timeout = 250;
            reveal_child = false;
        }

        main_timeout_id = GLib.Timeout.add (main_timeout, () => {
            main_timeout_id = 0;

            message_label.label = message;

            image_revealer.reveal_child = true;
            undo_revealer.reveal_child = false;
            notification_image.gicon = new ThemedIcon (icon);

            reveal_child = true;

            timeout_id = GLib.Timeout.add (2500, () => {
                timeout_id = 0;
                reveal_child = false;

                close_timeout = GLib.Timeout.add (250, () => {
                    close_timeout = 0;
                    message_label.label = "";
                    return false;
                });

                return false;
            });

            return false;
        });
    }

    public void send_undo_notification (int64 object_id, string object_type, string undo_type, string undo_value = "") {
        main_timeout = 0;
        if (timeout_id != 0) {
            run ();

            Source.remove (timeout_id);

            reveal_child = false;
            main_timeout = 250;
        }

        main_timeout_id = GLib.Timeout.add (main_timeout, () => {
            main_timeout_id = 0;
            _object_id = object_id;
            _object_type = object_type;
            _undo_type = undo_type;
            _undo_value = undo_value;

            image_revealer.reveal_child = false;
            undo_revealer.reveal_child = true;
            reveal_child = true;

            if (_undo_type == "delete") {
                message_label.label = _("Task deleted");
            } else if (_undo_type == "complete") {
                message_label.label = _("Task completed");
            } else if (_undo_type == "reschedule") {
                var item = Planner.database.get_item_by_id (_object_id);

                message_label.label = _("Completed. Next occurrence: %s".printf (
                    Planner.utils.get_default_date_format_from_string (item.due_date)
                ));
            }

            timeout_id = GLib.Timeout.add (3500, () => {
                timeout_id = 0;
                run ();

                reveal_child = false;
                close_timeout = GLib.Timeout.add (250, () => {
                    close_timeout = 0;
                    message_label.label = "";
                    return false;
                });
                return false;
            });
            return false;
        });
    }

    private void run () {
        if (_object_id != 0 && _undo_type != "") {
            if (_object_type == "item") {
                var item = Planner.database.get_item_by_id (_object_id);

                if (_undo_type == "delete") {
                    Planner.database.delete_item (item);
                    if (item.is_todoist == 1) {
                        Planner.todoist.add_delete_item (item);
                    }
                } else if (_undo_type == "complete") {
                    Planner.database.item_completed (item);
                }
            }

            _object_id = 0;
            _object_type = "";
            _undo_type = "";
            _undo_value = "";
        }
    }
}
