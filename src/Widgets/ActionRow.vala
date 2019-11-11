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

public class Widgets.ActionRow : Gtk.ListBoxRow {
    public Gtk.Image icon { get; set; }

    public string icon_name  { get; construct; }
    public string item_name { get; construct; }
    public string item_base_name { get; construct; }

    private Gtk.Label count_label;

    private Gtk.Revealer secondary_revealer;
    private Gtk.Revealer primary_revealer;

    private Gtk.Revealer main_revealer;

    private const Gtk.TargetEntry[] targetEntriesItem = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public ActionRow (string name, string icon, string item_base_name, string tooltip_text) {
        Object (
            item_name: name,    
            icon_name: icon,
            item_base_name: item_base_name,
            tooltip_text: tooltip_text
        );
    }

    construct {
        get_style_context ().add_class ("pane-row");

        icon = new Gtk.Image ();
        icon.halign = Gtk.Align.CENTER;
        icon.valign = Gtk.Align.CENTER;
        icon.gicon = new ThemedIcon (icon_name);
        icon.pixel_size = 14;

        var title_name = new Gtk.Label (item_name);
        title_name.margin_bottom = 1;
        title_name.get_style_context ().add_class ("pane-item");
        title_name.use_markup = true;

        count_label = new Gtk.Label ("<small>%s</small>".printf (""));
        count_label.valign = Gtk.Align.CENTER;
        count_label.margin_top = 3;
        count_label.use_markup = true;
        count_label.opacity = 0.7;

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        main_box.margin = 6;
        main_box.margin_start = 12;

        main_box.pack_start (icon, false, false, 0);
        main_box.pack_start (title_name, false, false, 6);
        main_box.pack_start (count_label, false, false, 0);

        main_revealer = new Gtk.Revealer ();
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        main_revealer.add (main_box);
        main_revealer.reveal_child = true;

        add (main_revealer);
        build_drag_and_drop ();

        if (item_base_name == "inbox") {
            icon.get_style_context ().add_class ("inbox-icon");
        } else if (item_base_name == "today") {
            if (icon_name == "planner-today-day-symbolic") {
                icon.get_style_context ().add_class ("today-day-icon");
            } else {    
                icon.get_style_context ().add_class ("today-night-icon");
            }
        } else if (item_base_name == "upcoming") {
            icon.get_style_context ().add_class ("upcoming-icon");
        }
    }

    private void build_drag_and_drop () {
        if (item_base_name == "inbox") {
            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, targetEntriesItem, Gdk.DragAction.MOVE);
            drag_data_received.connect (on_drag_item_received);
            drag_motion.connect (on_drag_item_motion);
            drag_leave.connect (on_drag_item_leave);
        }
    }

    private void on_drag_item_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type) {
        if (item_base_name == "inbox") {
            Widgets.ItemRow source;
            var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
            source = (Widgets.ItemRow) row;

            if (source.item.is_todoist == 0) {
                if (Application.database.move_item (source.item, Application.settings.get_int64 ("inbox-project"))) {
                    source.get_parent ().remove (source);
                }
            } else {
                Application.todoist.move_item (source.item, Application.settings.get_int64 ("inbox-project"));
            }
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
