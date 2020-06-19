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

public class Widgets.CheckRow : Gtk.ListBoxRow {
    public Objects.Item item { get; construct; }

    private Gtk.CheckButton checked_button;
    private Gtk.Label content_label;
    private Widgets.Entry content_entry;
    private Gtk.Stack content_stack;
    private Gtk.Revealer motion_revealer;
    private Gtk.Separator drag_separator;
    private Gtk.Revealer main_revealer;

    private const Gtk.TargetEntry[] TARGET_ENTRIES_CHECK = {
        {"CHECKROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public signal void hide_item ();
    // public signal void activate (int index);

    public CheckRow (Objects.Item item) {
        Object (
            item: item
        );
    }

    construct {
        tooltip_text = item.content;
        can_focus = false;
        get_style_context ().add_class ("check-row");

        checked_button = new Gtk.CheckButton ();
        checked_button.margin_start = 6;
        checked_button.can_focus = false;
        checked_button.valign = Gtk.Align.CENTER;
        checked_button.halign = Gtk.Align.CENTER;
        checked_button.get_style_context ().add_class ("checklist-border");
        checked_button.get_style_context ().add_class ("checklist-check");

        content_label = new Gtk.Label (item.content);
        content_label.halign = Gtk.Align.START;
        content_label.valign = Gtk.Align.CENTER;
        content_label.set_ellipsize (Pango.EllipsizeMode.END);
        content_label.use_markup = true;

        content_entry = new Widgets.Entry ();
        content_entry.placeholder_text = _("Task name");
        content_entry.get_style_context ().add_class ("flat");
        content_entry.get_style_context ().add_class ("check-entry");
        content_entry.get_style_context ().add_class ("active");
        content_entry.text = item.content;
        content_entry.hexpand = true;

        content_stack = new Gtk.Stack ();
        content_stack.transition_type = Gtk.StackTransitionType.NONE;
        content_stack.add_named (content_label, "label");
        content_stack.add_named (content_entry, "entry");

        var delete_button = new Gtk.Button.from_icon_name ("window-close-symbolic");
        delete_button.valign = Gtk.Align.CENTER;
        delete_button.can_focus = false;
        delete_button.tooltip_text = _("Delete");
        delete_button.get_style_context ().add_class ("flat");
        delete_button.get_style_context ().add_class ("delete-check-button");

        var delete_revealer = new Gtk.Revealer ();
        delete_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        delete_revealer.add (delete_button);

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.get_style_context ().add_class ("transition");
        box.hexpand = true;
        box.margin_top = 3;
        box.margin_bottom = 2;
        box.pack_start (checked_button, false, false, 0);
        box.pack_start (content_stack, false, true, 9);
        box.pack_end (delete_revealer, false, true, 0);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        drag_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        drag_separator.visible = false;
        drag_separator.no_show_all = true;

        var motion_grid = new Gtk.Grid ();
        motion_grid.margin = 6;
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;

        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.hexpand = true;
        main_box.margin_end = 9;
        main_box.pack_start (separator, false, false, 0);
        main_box.pack_start (box, false, false, 0);
        main_box.pack_start (drag_separator, false, false, 0);
        main_box.pack_start (motion_revealer, false, false, 0);

        var handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.expand = true;
        handle.above_child = false;
        handle.add (main_box);

        main_revealer = new Gtk.Revealer ();
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        main_revealer.reveal_child = true;
        main_revealer.add (handle);

        add (main_revealer);
        build_drag_and_drop ();

        if (item.checked == 1) {
            checked_button.active = true;
        } else {
            checked_button.active = false;
        }

        handle.enter_notify_event.connect ((event) => {
            delete_revealer.reveal_child = true;
            delete_button.get_style_context ().add_class ("closed");

            return false;
        });

        handle.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            delete_revealer.reveal_child = false;
            delete_button.get_style_context ().remove_class ("closed");

            return false;
        });

        content_entry.changed.connect (() => {
            save ();
        });

        content_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_item ();
            }

            return false;
        });

        content_entry.activate.connect (() => {
            content_stack.visible_child_name = "label";
        });

        content_entry.focus_out_event.connect (() => {
            content_stack.visible_child_name = "label";
            content_label.label = Planner.utils.get_markup_format (item.content);
            tooltip_text = item.content;
            
            return false;
        });

        checked_button.toggled.connect (() => {
            if (checked_button.active) {
                item.checked = 1;
                item.date_completed = new GLib.DateTime.now_local ().to_string ();

                Planner.database.update_item_completed (item);
                if (item.is_todoist == 1) {
                    Planner.todoist.item_complete (item);
                }
            } else {
                item.checked = 0;
                item.date_completed = "";

                Planner.database.update_item_completed (item);
                if (item.is_todoist == 1) {
                    Planner.todoist.item_uncomplete (item);
                }
            }
        });

        delete_button.clicked.connect (() => {
            Planner.database.delete_item (item);
            if (item.is_todoist == 1) {
                Planner.todoist.add_delete_item (item);
            }
        });

        Planner.database.item_deleted.connect ((i) => {
            if (item.id == i.id) {
                main_revealer.reveal_child = false;

                Timeout.add (500, () => {
                    destroy ();
                    return false;
                });
            }
        });

        Planner.database.item_id_updated.connect ((current_id, new_id) => {
            Idle.add (() => {
                if (item.id == current_id) {
                    item.id = new_id;
                }

                return false;
            });
        });

        Planner.database.project_id_updated.connect ((current_id, new_id) => {
            Idle.add (() => {
                if (item.project_id == current_id) {
                    item.project_id = new_id;
                }

                return false;
            });
        });

        Planner.database.section_id_updated.connect ((current_id, new_id) => {
            Idle.add (() => {
                if (item.section_id == current_id) {
                    item.section_id = new_id;
                }

                return false;
            });
        });

        Planner.database.item_completed.connect ((i) => {
            if (item.id == i.id) {
                checked_button.active = true;
            }
        });

        Planner.database.item_uncompleted.connect ((i) => {
            if (item.id == i.id) {
                checked_button.active = false;
            }
        });
    }

    private void save () {
        item.content = content_entry.text;
        item.save ();
    }

    public void edit () {
        content_stack.visible_child_name = "entry";
        content_entry.grab_focus_without_selecting ();
        if (content_entry.cursor_position < content_entry.text_length) {
            content_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) content_entry.text_length, false);
        }
    }

    private void build_drag_and_drop () {
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, TARGET_ENTRIES_CHECK, Gdk.DragAction.MOVE);
        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);

        Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION, TARGET_ENTRIES_CHECK, Gdk.DragAction.MOVE);
        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);
        drag_end.connect (clear_indicator);
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = (Widgets.CheckRow) widget;

        Gtk.Allocation alloc;
        row.get_allocation (out alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr = new Cairo.Context (surface);
        cr.set_source_rgba (0, 0, 0, 0.3);
        cr.set_line_width (1);

        cr.move_to (0, 0);
        cr.line_to (alloc.width, 0);
        cr.line_to (alloc.width, alloc.height);
        cr.line_to (0, alloc.height);
        cr.line_to (0, 0);
        cr.stroke ();

        cr.set_source_rgba (255, 255, 255, 0.5);
        cr.rectangle (0, 0, alloc.width, alloc.height);
        cr.fill ();

        row.draw (cr);
        Gtk.drag_set_icon_surface (context, surface);
        main_revealer.reveal_child = false;
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (Widgets.LabelRow))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("CHECKROW"), 32, data
        );
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        motion_revealer.reveal_child = false;

        drag_separator.visible = false;
        drag_separator.no_show_all = true;
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        motion_revealer.reveal_child = true;

        drag_separator.visible = true;
        drag_separator.no_show_all = false;
        return true;
    }

    public void clear_indicator (Gdk.DragContext context) {
        main_revealer.reveal_child = true;

        drag_separator.visible = false;
        drag_separator.no_show_all = true;
    }
}
