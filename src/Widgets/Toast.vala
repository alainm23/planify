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
    public string query { get; construct; }
    public string title { get; construct; }
    public NotificationStyle notification_type { get; construct; }

    private Gtk.Label message_label;
    private Gtk.Button undo_button;

    private uint timeout_id = 0;
    private uint duration = 2000;

    public Toast (string title, string query="", NotificationStyle notification_type) {
        Object (
            title: title,
            query: query,
            notification_type: notification_type
        );
    }

    construct {
        halign = Gtk.Align.CENTER;
        transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        reveal_child = false;

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

        message_label = new Gtk.Label (title);
        message_label.get_style_context ().add_class ("font-weight-600");
        message_label.use_markup = true;
        message_label.margin_start = 6;

        undo_button = new Gtk.Button ();
        undo_button.margin_start = 6;
        undo_button.valign = Gtk.Align.CENTER;
        undo_button.label = _("Undo");

        var undo_revealer = new Gtk.Revealer ();
        undo_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        undo_revealer.transition_duration = 0;
        undo_revealer.add (undo_button);

        var loading_spinner = new Gtk.Spinner ();
        loading_spinner.margin_start = 6;
        loading_spinner.start ();
        
        var loading_revealer = new Gtk.Revealer ();
        loading_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        loading_revealer.transition_duration = 0;
        loading_revealer.add (loading_spinner);

        if (query != "" &&
            (Planner.todoist.get_string_member_by_object (query, "type") == "item_delete" ||
            Planner.todoist.get_string_member_by_object (query, "type") == "item_complete" ||
            Planner.todoist.get_string_member_by_object (query, "type") == "item_reschedule")) {
            undo_revealer.reveal_child = true;
            duration = 3500;
        } else if (query != "" &&
            (Planner.todoist.get_string_member_by_object (query, "type") == "item_duplicate" ||
            Planner.todoist.get_string_member_by_object (query, "type") == "item_add_from_clipboard")) {
            loading_revealer.reveal_child = true;
            duration = -1;

            Planner.todoist.item_added_completed.connect ((_temp_id_mapping) => {
                if (Planner.todoist.get_string_member_by_object (query, "object_id") == _temp_id_mapping.to_string ()) {
                    reveal_child = false;

                    if (Planner.todoist.get_string_member_by_object (query, "type") == "item_duplicate") {
                        Planner.notifications.send_notification (_("Task duplicate"));
                    } else if (Planner.todoist.get_string_member_by_object (query, "type") == "item_add_from_clipboard") {
                        Planner.notifications.send_notification (_("Task added from clipboard"));
                    }

                    GLib.Timeout.add (transition_duration, () => {
                        destroy ();
                        return false;
                    });
                }
            });

            Planner.todoist.item_added_error.connect ((_temp_id_mapping) => {
                if (Planner.todoist.get_string_member_by_object (query, "object_id") == _temp_id_mapping.to_string ()) {
                    reveal_child = false;

                    if (Planner.todoist.get_string_member_by_object (query, "type") == "item_duplicate") {
                        debug ("Error duplicate or add task");
                        Planner.notifications.send_notification (
                            _("Failed to duplicate task. Try again."),
                            NotificationStyle.ERROR
                        );
                    } else if (Planner.todoist.get_string_member_by_object (query, "type") == "item_add_from_clipboard") {
                        debug ("Error add task from clipboard");
                        Planner.notifications.send_notification (
                            _("Failed to add task from clipboard. Try again."),
                            NotificationStyle.ERROR
                        );
                    }

                    GLib.Timeout.add (transition_duration, () => {
                        destroy ();
                        return false;
                    });
                }
            });
        } else if (query != "" &&
            (Planner.todoist.get_string_member_by_object (query, "type") == "convert_project")) {
            loading_revealer.reveal_child = true;
            duration = -1;

            Planner.todoist.convert_finished.connect ((id) => {
                if (Planner.todoist.get_string_member_by_object (query, "object_id") == id.to_string ()) {
                    reveal_child = false;

                    Planner.notifications.send_notification (_("Converted project"));
                    Planner.todoist.sync ();
                    Planner.database.delete_project (id);

                    GLib.Timeout.add (transition_duration, () => {
                        destroy ();
                        return false;
                    });
                }
            });

            Planner.todoist.convert_error.connect ((id) => {
                if (Planner.todoist.get_string_member_by_object (query, "object_id") == id.to_string ()) {
                    reveal_child = false;

                    debug ("Error converting project to todoist");
                    Planner.notifications.send_notification (
                        _("Failed to convert project. Try again."),
                        NotificationStyle.ERROR
                    );

                    GLib.Timeout.add (transition_duration, () => {
                        destroy ();
                        return false;
                    });
                }
            });
        }

        var notification_box = new Gtk.Grid ();
        notification_box.column_spacing = 6;
        notification_box.valign = Gtk.Align.CENTER;
        notification_box.add (loading_revealer);
        notification_box.add (message_label);
        notification_box.add (undo_revealer);

        var notification_frame = new Gtk.Frame (null);
        notification_frame.margin = 9;
        notification_frame.get_style_context ().add_class ("app-notification");
        notification_frame.add (notification_box);
        if (NotificationStyle.ERROR == notification_type) {
            notification_frame.get_style_context ().add_class ("error");
        }

        var notification_overlay = new Gtk.Overlay ();
        notification_overlay.add_overlay (close_revealer);
        notification_overlay.add (notification_frame);

        var notification_eventbox = new Gtk.EventBox ();
        notification_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        notification_eventbox.above_child = false;
        notification_eventbox.add (notification_overlay);

        add (notification_eventbox);
        
        undo_button.clicked.connect (() => {
            reveal_child = false;
            if (timeout_id != 0) {
                Source.remove (timeout_id);
                timeout_id = 0;
            }
            
            if (Planner.todoist.get_string_member_by_object (query, "object_type") == "item") {
                var item = Planner.database.get_item_by_id (
                    int64.parse (Planner.todoist.get_string_member_by_object (query, "object_id"))
                );
                
                if (item.id != 0) {
                    if (Planner.todoist.get_string_member_by_object (query, "type") == "item_delete") {
                        Planner.database.show_undo_item (item, "item_delete");
                    } else if (Planner.todoist.get_string_member_by_object (query, "type") == "item_complete") {
                        item.checked = 0;
                        item.date_completed = "";
    
                        Planner.database.update_item_completed (item);
                        if (item.is_todoist == 1) {
                            Planner.todoist.item_uncomplete (item);
                        }
    
                        Planner.database.show_undo_item (item, "item_complete");
                    } else if (Planner.todoist.get_string_member_by_object (query, "type") == "item_reschedule") {
                        Planner.database.update_item_recurring_due_date (item, -1);
                    }
                }
            } else if (Planner.todoist.get_string_member_by_object (query, "object_type") == "task") {
                if (Planner.todoist.get_string_member_by_object (query, "type") == "item_delete") {
                    Planner.event_bus.show_undo_task (
                        Planner.todoist.get_string_member_by_object (query, "object_id"),
                        "item_delete"
                    );
                }
            }

            GLib.Timeout.add (transition_duration, () => {
                destroy ();
                return false;
            });
        });

        close_button.clicked.connect (() => {
            reveal_child = false;
            if (timeout_id != 0) {
                Source.remove (timeout_id);
                timeout_id = 0;
            }

            run_query ();
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

            if (duration != -1) {
                timeout_id = GLib.Timeout.add (duration, () => {
                    reveal_child = false;
                    timeout_id = 0;
    
                    run_query ();
                    return false;
                });
            }
        }
    }

    public void run_query () {
        if (query != "") {
            if (Planner.todoist.get_string_member_by_object (query, "object_type") == "item") {
                var item = Planner.database.get_item_by_id (
                    int64.parse (Planner.todoist.get_string_member_by_object (query, "object_id"))
                );

                if (item.id != 0) {
                    if (Planner.todoist.get_string_member_by_object (query, "type") == "item_delete") {
                        Planner.database.delete_item (item);
                        if (item.is_todoist == 1) {
                            Planner.todoist.add_delete_item (item);
                        }
                    } else if (Planner.todoist.get_string_member_by_object (query, "type") == "item_complete") {
                        item.checked = 1;
                        item.date_completed = new GLib.DateTime.now_local ().to_string ();

                        Planner.database.update_item_completed (item);
                        if (item.is_todoist == 1) {
                            Planner.todoist.item_complete (item);
                        }
                    }
                }
            } else if (Planner.todoist.get_string_member_by_object (query, "object_type") == "task") {
                
            }
        }

        GLib.Timeout.add (transition_duration, () => {
            destroy ();
            return false;
        });
    }
}
