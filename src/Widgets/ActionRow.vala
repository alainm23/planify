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

public class Widgets.ActionRow : Gtk.ListBoxRow {
    public Gtk.Label title_name;
    public Gtk.Image icon { get; set; }

    public PaneView view { get; construct; }

    private Gtk.Label count_label;
    private Gtk.Revealer count_revealer;
    private Gtk.Label count_past_label;
    private Gtk.Revealer count_past_revealer;
    private Gtk.Revealer main_revealer;
    private Gtk.EventBox handle;
    private Gtk.Revealer motion_revealer;
    private Gtk.Revealer first_motion_revealer;
    private uint timeout_id = 0;

    private const Gtk.TargetEntry[] TARGET_ENTRIES_ITEM = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] TARGET_PANEVIEW = {
        {"PANEVIEWROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public bool reveal_drag_motion {
        set {
            motion_revealer.reveal_child = value;
        }
        get {
            return motion_revealer.reveal_child;
        }
    }

    public bool reveal_child {
        get {
            return main_revealer.reveal_child;
        }
        set {
            main_revealer.reveal_child = value;
        }
    }

    public ActionRow (PaneView view) {
        Object (
            view: view
        );
    }

    construct {
        margin_start = 6;
        get_style_context ().add_class ("action-row");

        icon = new Gtk.Image ();
        icon.halign = Gtk.Align.CENTER;
        icon.valign = Gtk.Align.CENTER;
        icon.pixel_size = 14;

        title_name = new Gtk.Label (null);
        title_name.margin_bottom = 1;
        title_name.get_style_context ().add_class ("pane-item");
        title_name.get_style_context ().add_class ("action-row-label");
        title_name.use_markup = true;

        var source_icon = new Gtk.Image ();
        source_icon.valign = Gtk.Align.CENTER;
        source_icon.get_style_context ().add_class ("dim-label");
        source_icon.margin_top = 3;
        source_icon.pixel_size = 14;
        source_icon.icon_name = "planner-online-symbolic";
        source_icon.tooltip_text = _("Todoist Project");

        count_past_label = new Gtk.Label (null);
        count_past_label.get_style_context ().add_class ("badge-expired");
        count_past_label.get_style_context ().add_class ("font-bold");
        count_past_label.valign = Gtk.Align.CENTER;
        count_past_label.use_markup = true;
        count_past_label.width_chars = 3;

        count_past_revealer = new Gtk.Revealer ();
        count_past_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        count_past_revealer.add (count_past_label);

        count_label = new Gtk.Label (null);
        count_label.valign = Gtk.Align.CENTER;
        count_label.use_markup = true;
        count_label.opacity = 0.7;
        count_label.width_chars = 3;
        count_label.margin_end = 3;

        count_revealer = new Gtk.Revealer ();
        count_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        count_revealer.add (count_label);

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.hexpand = true;
        main_box.margin = 3;
        main_box.margin_top = 2;
        main_box.margin_bottom = 2;
        main_box.pack_start (icon, false, false, 0);
        main_box.pack_start (title_name, false, false, 6);
        main_box.pack_end (count_revealer, false, false, 0);
        main_box.pack_end (count_past_revealer, false, false, 0);

        var motion_grid = new Gtk.Grid ();
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;
        motion_grid.hexpand = true;
        motion_grid.margin_bottom = 6;
        motion_grid.margin_top = 6;

        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        var first_motion_grid = new Gtk.Grid ();
        first_motion_grid.get_style_context ().add_class ("grid-motion");
        first_motion_grid.height_request = 24;
        first_motion_grid.hexpand = true;
        first_motion_grid.margin_bottom = 6;
        first_motion_grid.margin_top = 6;

        first_motion_revealer = new Gtk.Revealer ();
        first_motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        first_motion_revealer.add (first_motion_grid);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.hexpand = true;
        grid.add (first_motion_revealer);
        grid.add (main_box);
        grid.add (motion_revealer);

        handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.hexpand = true;
        handle.above_child = false;
        handle.add (grid);

        main_revealer = new Gtk.Revealer ();
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        main_revealer.add (handle);
        main_revealer.reveal_child = true;

        add (main_revealer);

        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, TARGET_PANEVIEW, Gdk.DragAction.MOVE);
        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);

        build_drag_and_drop (false);

        Planner.utils.drag_item_activated.connect ((active) => {
            build_drag_and_drop (active);
        });

        if (view == PaneView.INBOX) {
            tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl>1"}, _("Inbox"));
            icon.gicon = new ThemedIcon ("mail-mailbox-symbolic");
            title_name.label = _("Inbox");
            icon.get_style_context ().add_class ("inbox-icon");
        } else if (view == PaneView.TODAY) {
            tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl>2"}, _("Today"));
            icon.gicon = new ThemedIcon ("help-about-symbolic");
            title_name.label = _("Today");
            icon.get_style_context ().add_class ("today-icon");
        } else if (view == PaneView.UPCOMING) {
            tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl>3"}, _("Upcoming"));
            icon.gicon = new ThemedIcon ("x-office-calendar-symbolic");
            title_name.label = _("Upcoming");
            icon.get_style_context ().add_class ("upcoming-icon");
        }

        check_count_update ();

        handle.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                Planner.event_bus.pane_selected (
                    PaneType.ACTION,
                    ((int64) Planner.utils.get_int_by_paneview (view)).to_string ()
                );

                return false;
            }

            return false;
        });

        Planner.event_bus.pane_selected.connect ((pane_type, id) => {
            if (pane_type == PaneType.ACTION &&
                ((int64) Planner.utils.get_int_by_paneview (view)).to_string () == id) {
                handle.get_style_context ().add_class ("project-selected");
            } else {
                handle.get_style_context ().remove_class ("project-selected");
            }
        });
    }

    public string get_view_string () {
        var returned = "inbox";

        if (view == PaneView.INBOX) {
            returned = "inbox";
        } else if (view == PaneView.TODAY) {
            returned = "today";
        } else if (view == PaneView.UPCOMING) {
            returned = "upcoming";
        }

        return returned;
    }

    private void check_count_update () {
        Planner.database.update_all_bage.connect (() => {
            update_count ();
        });

        if (view == PaneView.TODAY) {
            Planner.database.item_added.connect ((item) => {
                update_count ();
            });

            //  Planner.database.item_added_with_index.connect ((item) => {
            //      update_count ();
            //  });

            Planner.database.item_completed.connect ((item) => {
                update_count ();
            });

            Planner.database.item_uncompleted.connect ((item) => {
                update_count ();
            });

            Planner.database.add_due_item.connect ((item) => {
                update_count ();
            });

            Planner.database.update_due_item.connect ((item) => {
                update_count ();
            });

            Planner.database.remove_due_item.connect ((item) => {
                update_count ();
            });

            Planner.database.item_deleted.connect ((item) => {
                update_count ();
            });

            Planner.database.project_deleted.connect ((id) => {
                update_count ();
            });

            Planner.database.section_deleted.connect ((s) => {
                update_count ();
            });
        } else if (view == PaneView.INBOX) {
            Planner.database.check_project_count.connect ((id) => {
                if (Planner.settings.get_int64 ("inbox-project") == id) {
                    update_count ();
                }
            });
        }
    }

    private void update_count (bool today=false) {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
        }

        timeout_id = Timeout.add (250, () => {
            timeout_id = 0;

            if (view == PaneView.TODAY) {
                check_today_badge ();
            } else if (view == PaneView.INBOX) {
                check_inbox_badge ();
            }
            
            return GLib.Source.REMOVE;
        });
    }

    private void check_inbox_badge () {
        int count = Planner.database.get_count_items_by_project (Planner.settings.get_int64 ("inbox-project"));
        count_label.label = "<small>%i</small>".printf (count);
        if (count <= 0) {
            count_revealer.reveal_child = false;
        } else {
            count_revealer.reveal_child = true;
        }
    }

    private void check_today_badge () {
        int today_count = Planner.database.get_today_count ();
        int past_count = Planner.database.get_past_count ();

        count_label.label = "<small>%i</small>".printf (today_count);
        count_past_label.label = "<small>%i</small>".printf (past_count);

        if (past_count <= 0) {
            count_past_revealer.reveal_child = false;
        } else {
            count_past_revealer.reveal_child = true;
        }

        if (today_count <= 0) {
            count_revealer.reveal_child = false;
        } else {
            count_revealer.reveal_child = true;
        }
    }

    /*
    *   Build DRAGN AND DROP
    */
    private void build_drag_and_drop (bool value) {
        if (value) {
            drag_motion.disconnect (on_drag_motion);
            drag_leave.disconnect (on_drag_leave);
            drag_end.disconnect (clear_indicator);

            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, TARGET_ENTRIES_ITEM, Gdk.DragAction.MOVE);
            drag_motion.connect (on_drag_item_motion);
            drag_leave.connect (on_drag_item_leave);

            if (view == PaneView.INBOX) {
                drag_data_received.connect (on_drag_imbox_item_received);
            } else if (view == PaneView.TODAY) {
                drag_data_received.connect (on_drag_today_item_received);
            } else if (view == PaneView.UPCOMING) {
                drag_data_received.connect (on_drag_upcoming_item_received);
            }
        } else {
            drag_data_received.disconnect (on_drag_imbox_item_received);
            drag_data_received.disconnect (on_drag_today_item_received);
            drag_data_received.disconnect (on_drag_upcoming_item_received);
            drag_motion.disconnect (on_drag_item_motion);
            drag_leave.disconnect (on_drag_item_leave);

            Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION, TARGET_PANEVIEW, Gdk.DragAction.MOVE);
            drag_motion.connect (on_drag_motion);
            drag_leave.connect (on_drag_leave);
            drag_end.connect (clear_indicator);
        }
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = ((Widgets.ActionRow) widget).handle;

        Gtk.Allocation alloc;
        row.get_allocation (out alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr = new Cairo.Context (surface);
        cr.set_source_rgba (0, 0, 0, 0);
        cr.set_line_width (1);

        cr.move_to (0, 0);
        cr.line_to (alloc.width, 0);
        cr.line_to (alloc.width, alloc.height);
        cr.line_to (0, alloc.height);
        cr.line_to (0, 0);
        cr.stroke ();

        cr.set_source_rgba (255, 255, 255, 0);
        cr.rectangle (0, 0, alloc.width, alloc.height);
        cr.fill ();

        row.get_style_context ().add_class ("drag-begin");
        row.draw (cr);
        row.get_style_context ().remove_class ("drag-begin");

        Gtk.drag_set_icon_surface (context, surface);
        main_revealer.reveal_child = false;
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (Widgets.ActionRow))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("PANEVIEWROW"), 32, data
        );
    }

    public void clear_indicator (Gdk.DragContext context) {
        reveal_drag_motion = false;
        main_revealer.reveal_child = true;
        first_motion_revealer.reveal_child = false;
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        Gtk.Allocation alloc;
        handle.get_allocation (out alloc);
        
        if (get_index () == 0) {
            if (y > (alloc.height / 2)) {
                reveal_drag_motion = true;
                first_motion_revealer.reveal_child = false;
            } else {
                first_motion_revealer.reveal_child = true;
                reveal_drag_motion = false;
            }
        } else {
            reveal_drag_motion = true;
        }

        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        reveal_drag_motion = false;
        first_motion_revealer.reveal_child = false;
    }

    private void on_drag_imbox_item_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type) {
        Widgets.ItemRow source;
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        if (source.item.is_todoist == Planner.database.get_project_by_id (Planner.settings.get_int64 ("inbox-project")).is_todoist) {
            Planner.database.move_item (source.item, Planner.settings.get_int64 ("inbox-project"));
            if (source.item.is_todoist == 1) {
                Planner.todoist.move_item (source.item, Planner.settings.get_int64 ("inbox-project"));
            }
        } else {
            Planner.notifications.send_notification (
                _("Unable to move task")
            );
        }
    }

    private void on_drag_today_item_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type) {
        Widgets.ItemRow source;
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        bool new_date = false;
        var date = new GLib.DateTime.now_local ();
        if (source.item.due_date == "") {
            new_date = true;
        }

        source.item.due_date = Planner.utils.get_datetime (date);
        Planner.database.set_due_item (source.item, new_date);
        if (source.item.is_todoist == 1) {
            Planner.todoist.update_item (source.item);
        }
    }

    private void on_drag_upcoming_item_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type) {
        Widgets.ItemRow source;
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        bool new_date = false;
        var date = new GLib.DateTime.now_local ().add_days (1);
        if (source.item.due_date == "") {
            new_date = true;
        }

        source.item.due_date = Planner.utils.get_datetime (date);
        Planner.database.set_due_item (source.item, new_date);
        if (source.item.is_todoist == 1) {
            Planner.todoist.update_item (source.item);
        }
    }

    public bool on_drag_item_motion (Gdk.DragContext context, int x, int y, uint time) {
        get_style_context ().add_class ("highlight");
        return true;
    }

    public void on_drag_item_leave (Gdk.DragContext context, uint time) {
        get_style_context ().remove_class ("highlight");
    }
}
