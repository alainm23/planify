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

    public string icon_name { get; construct; }
    public string item_name { get; construct; }
    public string item_base_name { get; construct; }

    private Gtk.Label count_label;
    private Gtk.Revealer count_revealer;
    private Gtk.Label count_past_label;
    private Gtk.Revealer count_past_revealer;
    private Gtk.Revealer main_revealer;

    private uint timeout_id = 0;

    private const Gtk.TargetEntry[] TARGET_ENTRIES_ITEM = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public bool reveal_child {
        get {
            return main_revealer.reveal_child;
        }
        set {
            main_revealer.reveal_child = value;
        }
    }

    public ActionRow (string name, string icon, string item_base_name, string[]? accels) {
        Object (
            item_name: name,
            icon_name: icon,
            item_base_name: item_base_name,
            tooltip_markup: Granite.markup_accel_tooltip (accels, name)
        );
    }

    construct {
        margin_start = margin_end = 6;
        margin_bottom = 3;
        get_style_context ().add_class ("pane-row");
        get_style_context ().add_class ("action-row");


        icon = new Gtk.Image ();
        icon.halign = Gtk.Align.CENTER;
        icon.valign = Gtk.Align.CENTER;
        icon.gicon = new ThemedIcon (icon_name);
        icon.pixel_size = 16;

        title_name = new Gtk.Label (item_name);
        title_name.margin_bottom = 1;
        title_name.get_style_context ().add_class ("pane-item");
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

        count_revealer = new Gtk.Revealer ();
        count_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        count_revealer.add (count_label);

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.margin = 3;
        main_box.pack_start (icon, false, false, 0);
        main_box.pack_start (title_name, false, false, 6);
        main_box.pack_end (count_revealer, false, false, 0);
        main_box.pack_end (count_past_revealer, false, false, 0);

        main_revealer = new Gtk.Revealer ();
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        main_revealer.add (main_box);
        main_revealer.reveal_child = true;

        add (main_revealer);
        build_drag_and_drop ();

        if (item_base_name == "search") {
            icon.get_style_context ().add_class ("search-icon");
        } else if (item_base_name == "inbox") {
            icon.get_style_context ().add_class ("inbox-icon");
        } else if (item_base_name == "today") {
            icon.get_style_context ().add_class ("today-icon");
            //  if (icon_name == "planner-today-day-symbolic") {
            //      icon.get_style_context ().add_class ("today-day-icon");
            //  } else {
            //      icon.get_style_context ().add_class ("today-night-icon");
            //  }
        } else if (item_base_name == "upcoming") {
            icon.get_style_context ().add_class ("upcoming-icon");
        }

        check_count_update ();
    }

    private void check_count_update () {
        Planner.database.update_all_bage.connect (() => {
            update_count ();
        });

        if (item_base_name == "today") {
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
        } else if (item_base_name == "inbox") {
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

            if (item_base_name == "today") {
                check_today_badge ();
            } else if (item_base_name == "inbox") {
                check_inbox_badge ();
            }
            
            return false;
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
    private void build_drag_and_drop () {
        Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, TARGET_ENTRIES_ITEM, Gdk.DragAction.MOVE);
        drag_motion.connect (on_drag_item_motion);
        drag_leave.connect (on_drag_item_leave);

        if (item_base_name == "inbox") {
            drag_data_received.connect (on_drag_imbox_item_received);
        } else if (item_base_name == "today") {
            drag_data_received.connect (on_drag_today_item_received);
        } else if (item_base_name == "upcoming") {
            drag_data_received.connect (on_drag_upcoming_item_received);
        }
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

        source.item.due_date = date.to_string ();

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

        source.item.due_date = date.to_string ();

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
