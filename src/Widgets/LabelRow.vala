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

public class Widgets.LabelRow : Gtk.ListBoxRow {
    public Objects.Label label { get; construct; }
    public Gtk.ScrolledWindow scrolled { get; set; }

    private Gtk.Entry name_entry;
    private Gtk.Label name_label;
    private Gtk.Stack name_stack;

    private Gtk.Popover popover = null;
    private Gtk.ToggleButton color_button;
    private Gtk.Revealer buttons_revealer;
    private Gtk.Revealer motion_revealer;
    private Gtk.Separator separator;
    public Gtk.Revealer main_revealer;
    private int color_selected = 30;

    private bool scroll_up = false;
    private bool scrolling = false;
    private bool should_scroll = false;
    public Gtk.Adjustment vadjustment;

    private const int SCROLL_STEP_SIZE = 5;
    private const int SCROLL_DISTANCE = 30;
    private const int SCROLL_DELAY = 50;
    private bool entry_menu_opened = false;
    private const Gtk.TargetEntry[] TARGET_ENTRIES_LABEL = {
        {"LABELROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public LabelRow (Objects.Label label) {
        Object (
            label: label
        );
    }

    construct {
        color_selected = label.color;
        can_focus = false;

        color_button = new Gtk.ToggleButton ();
        color_button.valign = Gtk.Align.CENTER;
        color_button.get_style_context ().add_class ("flat");
        color_button.get_style_context ().add_class ("area-row");
        color_button.get_style_context ().add_class ("label-%s".printf (label.id.to_string ()));

        var color_image = new Gtk.Image ();
        color_image.gicon = new ThemedIcon ("tag-symbolic");
        color_image.pixel_size = 16;

        color_button.add (color_image);

        name_label = new Gtk.Label (label.name);
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("font-weight-600");
        name_label.valign = Gtk.Align.CENTER;
        name_label.margin_start = 3;
        name_label.set_ellipsize (Pango.EllipsizeMode.END);

        name_entry = new Gtk.Entry ();
        name_entry.text = label.name;
        name_entry.placeholder_text = _("Home");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("check-entry");
        name_entry.get_style_context ().add_class ("font-weight-600");
        name_entry.hexpand = true;

        name_stack = new Gtk.Stack ();
        name_stack.margin_bottom = 1;
        name_stack.transition_type = Gtk.StackTransitionType.NONE;
        name_stack.add_named (name_label, "name_label");
        name_stack.add_named (name_entry, "name_entry");

        var delete_button = new Gtk.Button.from_icon_name ("window-close-symbolic");
        delete_button.valign = Gtk.Align.CENTER;
        delete_button.can_focus = false;
        delete_button.get_style_context ().add_class ("flat");
        delete_button.get_style_context ().add_class ("delete-check-button");

        buttons_revealer = new Gtk.Revealer ();
        buttons_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        buttons_revealer.add (delete_button);

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.margin_start = 6;
        box.margin_top = 3;
        box.margin_bottom = 3;
        box.margin_end = 6;
        box.pack_start (color_button, false, false, 0);
        box.pack_start (name_stack, false, true, 0);
        box.pack_end (buttons_revealer, false, true, 0);

        var motion_grid = new Gtk.Grid ();
        motion_grid.margin = 6;
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;

        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.visible = false;
        separator.no_show_all = true;

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.get_style_context ().add_class ("label-row");
        main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);
        main_box.pack_start (box, false, false, 0);
        main_box.pack_start (separator, false, false, 0);

        var handle_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        handle_box.pack_start (main_box, false, false, 0);
        handle_box.pack_start (motion_revealer, false, false, 0);

        var handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.add (handle_box);

        main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = true;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (handle);

        add (main_revealer);
        build_drag_and_drop ();

        handle.enter_notify_event.connect ((event) => {
            buttons_revealer.reveal_child = true;
            delete_button.get_style_context ().add_class ("closed");

            return true;
        });

        handle.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            if (color_button.active == false) {
                buttons_revealer.reveal_child = false;
                delete_button.get_style_context ().remove_class ("closed");
            }

            return true;
        });

        delete_button.clicked.connect (() => {
            Planner.database.delete_label (label);
        });

        color_button.toggled.connect (() => {
            if (color_button.active) {
                if (popover == null) {
                    create_popover ();
                }

                popover.show_all ();
            }
        });

        name_entry.changed.connect (() => {
            save ();
        });

        name_entry.activate.connect (() => {
            name_stack.visible_child_name = "name_label";
        });

        name_entry.focus_out_event.connect (() => {
            if (entry_menu_opened == false) {
                name_stack.visible_child_name = "name_label";
            }
            
            return false;
        });

        name_entry.populate_popup.connect ((menu) => {
            entry_menu_opened = true;
            menu.hide.connect (() => {
                entry_menu_opened = false;
            });
        });

        Planner.database.label_deleted.connect ((l) => {
            if (label.id == l.id) {
                main_revealer.reveal_child = false;

                Timeout.add (500, () => {
                    destroy ();
                    return false;
                });
            }
        });
    }

    private void build_drag_and_drop () {
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, TARGET_ENTRIES_LABEL, Gdk.DragAction.MOVE);
        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);

        Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION, TARGET_ENTRIES_LABEL, Gdk.DragAction.MOVE);
        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);
        drag_end.connect (clear_indicator);
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = (Widgets.LabelRow) widget;

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
            Gdk.Atom.intern_static_string ("LABELROW"), 32, data
        );
    }

    public void clear_indicator (Gdk.DragContext context) {
        main_revealer.reveal_child = true;
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        motion_revealer.reveal_child = true;
        separator.visible = true;
        separator.no_show_all = false;

        int index = get_index ();
        Gtk.Allocation alloc;
        get_allocation (out alloc);

        int real_y = (index * alloc.height) - alloc.height + y;
        check_scroll (real_y);

        if (should_scroll && !scrolling) {
            scrolling = true;
            Timeout.add (SCROLL_DELAY, scroll);
        }

        return true;
    }

    private void check_scroll (int y) {
        vadjustment = scrolled.vadjustment;

        if (vadjustment == null) {
            return;
        }

        double vadjustment_min = vadjustment.value;
        double vadjustment_max = vadjustment.page_size + vadjustment_min;
        double show_min = double.max (0, y - SCROLL_DISTANCE);
        double show_max = double.min (vadjustment.upper, y + SCROLL_DISTANCE);

        if (vadjustment_min > show_min) {
            should_scroll = true;
            scroll_up = true;
        } else if (vadjustment_max < show_max) {
            should_scroll = true;
            scroll_up = false;
        } else {
            should_scroll = false;
        }
    }

    private bool scroll () {
        if (should_scroll) {
            if (scroll_up) {
                vadjustment.value -= SCROLL_STEP_SIZE;
            } else {
                vadjustment.value += SCROLL_STEP_SIZE;
            }
        } else {
            scrolling = false;
        }

        return should_scroll;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        motion_revealer.reveal_child = false;
        separator.visible = false;
        separator.no_show_all = true;
        should_scroll = false;
    }

    private void save () {
        label.name = name_entry.text;
        label.color = color_selected;
        name_label.label = label.name;

        label.save ();
    }

    private void create_popover () {
        popover = new Gtk.Popover (color_button);
        popover.position = Gtk.PositionType.BOTTOM;

        var color_30 = new Gtk.RadioButton (null);
        color_30.valign = Gtk.Align.START;
        color_30.halign = Gtk.Align.START;
        color_30.tooltip_text = Planner.utils.get_color_name (30);
        color_30.get_style_context ().add_class ("color-30");
        color_30.get_style_context ().add_class ("color-radio");

        var color_31 = new Gtk.RadioButton.from_widget (color_30);
        color_31.valign = Gtk.Align.START;
        color_31.halign = Gtk.Align.START;
        color_31.tooltip_text = Planner.utils.get_color_name (31);
        color_31.get_style_context ().add_class ("color-31");
        color_31.get_style_context ().add_class ("color-radio");

        var color_32 = new Gtk.RadioButton.from_widget (color_30);
        color_32.valign = Gtk.Align.START;
        color_32.halign = Gtk.Align.START;
        color_32.tooltip_text = Planner.utils.get_color_name (32);
        color_32.get_style_context ().add_class ("color-32");
        color_32.get_style_context ().add_class ("color-radio");

        var color_33 = new Gtk.RadioButton.from_widget (color_30);
        color_33.valign = Gtk.Align.START;
        color_33.halign = Gtk.Align.START;
        color_33.tooltip_text = Planner.utils.get_color_name (33);
        color_33.get_style_context ().add_class ("color-33");
        color_33.get_style_context ().add_class ("color-radio");

        var color_34 = new Gtk.RadioButton.from_widget (color_30);
        color_34.valign = Gtk.Align.START;
        color_34.halign = Gtk.Align.START;
        color_34.tooltip_text = Planner.utils.get_color_name (34);
        color_34.get_style_context ().add_class ("color-34");
        color_34.get_style_context ().add_class ("color-radio");

        var color_35 = new Gtk.RadioButton.from_widget (color_30);
        color_35.valign = Gtk.Align.START;
        color_35.halign = Gtk.Align.START;
        color_35.tooltip_text = Planner.utils.get_color_name (35);
        color_35.get_style_context ().add_class ("color-35");
        color_35.get_style_context ().add_class ("color-radio");

        var color_36 = new Gtk.RadioButton.from_widget (color_30);
        color_36.valign = Gtk.Align.START;
        color_36.halign = Gtk.Align.START;
        color_36.tooltip_text = Planner.utils.get_color_name (36);
        color_36.get_style_context ().add_class ("color-36");
        color_36.get_style_context ().add_class ("color-radio");

        var color_37 = new Gtk.RadioButton.from_widget (color_30);
        color_37.valign = Gtk.Align.START;
        color_37.halign = Gtk.Align.START;
        color_37.tooltip_text = Planner.utils.get_color_name (37);
        color_37.get_style_context ().add_class ("color-37");
        color_37.get_style_context ().add_class ("color-radio");

        var color_38 = new Gtk.RadioButton.from_widget (color_30);
        color_38.valign = Gtk.Align.START;
        color_38.halign = Gtk.Align.START;
        color_38.tooltip_text = Planner.utils.get_color_name (38);
        color_38.get_style_context ().add_class ("color-38");
        color_38.get_style_context ().add_class ("color-radio");

        var color_39 = new Gtk.RadioButton.from_widget (color_30);
        color_39.valign = Gtk.Align.START;
        color_39.halign = Gtk.Align.START;
        color_39.tooltip_text = Planner.utils.get_color_name (39);
        color_39.get_style_context ().add_class ("color-39");
        color_39.get_style_context ().add_class ("color-radio");

        var color_40 = new Gtk.RadioButton.from_widget (color_30);
        color_40.valign = Gtk.Align.START;
        color_40.halign = Gtk.Align.START;
        color_40.tooltip_text = Planner.utils.get_color_name (40);
        color_40.get_style_context ().add_class ("color-40");
        color_40.get_style_context ().add_class ("color-radio");

        var color_41 = new Gtk.RadioButton.from_widget (color_30);
        color_41.valign = Gtk.Align.START;
        color_41.halign = Gtk.Align.START;
        color_41.tooltip_text = Planner.utils.get_color_name (41);
        color_41.get_style_context ().add_class ("color-41");
        color_41.get_style_context ().add_class ("color-radio");

        var color_42 = new Gtk.RadioButton.from_widget (color_30);
        color_42.valign = Gtk.Align.START;
        color_42.halign = Gtk.Align.START;
        color_42.tooltip_text = Planner.utils.get_color_name (42);
        color_42.get_style_context ().add_class ("color-42");
        color_42.get_style_context ().add_class ("color-radio");

        var color_43 = new Gtk.RadioButton.from_widget (color_30);
        color_43.valign = Gtk.Align.START;
        color_43.halign = Gtk.Align.START;
        color_43.tooltip_text = Planner.utils.get_color_name (43);
        color_43.get_style_context ().add_class ("color-43");
        color_43.get_style_context ().add_class ("color-radio");

        var color_44 = new Gtk.RadioButton.from_widget (color_30);
        color_44.valign = Gtk.Align.START;
        color_44.halign = Gtk.Align.START;
        color_44.tooltip_text = Planner.utils.get_color_name (44);
        color_44.get_style_context ().add_class ("color-44");
        color_44.get_style_context ().add_class ("color-radio");

        var color_45 = new Gtk.RadioButton.from_widget (color_30);
        color_45.valign = Gtk.Align.START;
        color_45.halign = Gtk.Align.START;
        color_45.tooltip_text = Planner.utils.get_color_name (45);
        color_45.get_style_context ().add_class ("color-45");
        color_45.get_style_context ().add_class ("color-radio");

        var color_46 = new Gtk.RadioButton.from_widget (color_30);
        color_46.valign = Gtk.Align.START;
        color_46.halign = Gtk.Align.START;
        color_46.tooltip_text = Planner.utils.get_color_name (46);
        color_46.get_style_context ().add_class ("color-46");
        color_46.get_style_context ().add_class ("color-radio");

        var color_47 = new Gtk.RadioButton.from_widget (color_30);
        color_47.valign = Gtk.Align.START;
        color_47.halign = Gtk.Align.START;
        color_47.tooltip_text = Planner.utils.get_color_name (47);
        color_47.get_style_context ().add_class ("color-47");
        color_47.get_style_context ().add_class ("color-radio");

        var color_48 = new Gtk.RadioButton.from_widget (color_30);
        color_48.valign = Gtk.Align.START;
        color_48.halign = Gtk.Align.START;
        color_48.tooltip_text = Planner.utils.get_color_name (48);
        color_48.get_style_context ().add_class ("color-48");
        color_48.get_style_context ().add_class ("color-radio");

        var color_49 = new Gtk.RadioButton.from_widget (color_30);
        color_49.valign = Gtk.Align.START;
        color_49.halign = Gtk.Align.START;
        color_49.tooltip_text = Planner.utils.get_color_name (49);
        color_49.get_style_context ().add_class ("color-49");
        color_49.get_style_context ().add_class ("color-radio");

        var color_box = new Gtk.Grid ();
        color_box.hexpand = true;
        color_box.margin_start = 6;
        color_box.margin_end = 6;
        color_box.column_homogeneous = true;
        color_box.row_homogeneous = true;
        color_box.row_spacing = 9;
        color_box.column_spacing = 12;

        color_box.attach (color_30, 0, 0, 1, 1);
        color_box.attach (color_31, 1, 0, 1, 1);
        color_box.attach (color_32, 2, 0, 1, 1);
        color_box.attach (color_33, 3, 0, 1, 1);
        color_box.attach (color_34, 4, 0, 1, 1);
        color_box.attach (color_35, 5, 0, 1, 1);
        color_box.attach (color_36, 6, 0, 1, 1);
        color_box.attach (color_37, 0, 1, 1, 1);
        color_box.attach (color_38, 1, 1, 1, 1);
        color_box.attach (color_39, 2, 1, 1, 1);
        color_box.attach (color_40, 3, 1, 1, 1);
        color_box.attach (color_41, 4, 1, 1, 1);
        color_box.attach (color_42, 5, 1, 1, 1);
        color_box.attach (color_43, 6, 1, 1, 1);
        color_box.attach (color_44, 0, 2, 1, 1);
        color_box.attach (color_45, 1, 2, 1, 1);
        color_box.attach (color_46, 2, 2, 1, 1);
        color_box.attach (color_47, 3, 2, 1, 1);
        color_box.attach (color_48, 4, 2, 1, 1);
        color_box.attach (color_49, 5, 2, 1, 1);

        var popover_grid = new Gtk.Grid ();
        popover_grid.width_request = 235;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.margin_top = 6;
        popover_grid.margin_bottom = 6;
        popover_grid.add (color_box);

        popover.add (popover_grid);

        popover.closed.connect (() => {
            buttons_revealer.reveal_child = false;
            color_button.active = false;
        });

        switch (label.color) {
            case 30:
                color_30.active = true;
                break;
            case 31:
                color_31.active = true;
                break;
            case 32:
                color_32.active = true;
                break;
            case 33:
                color_33.active = true;
                break;
            case 34:
                color_34.active = true;
                break;
            case 35:
                color_35.active = true;
                break;
            case 36:
                color_36.active = true;
                break;
            case 37:
                color_37.active = true;
                break;
            case 38:
                color_38.active = true;
                break;
            case 39:
                color_39.active = true;
                break;
            case 40:
                color_40.active = true;
                break;
            case 41:
                color_41.active = true;
                break;
            case 42:
                color_42.active = true;
                break;
            case 43:
                color_43.active = true;
                break;
            case 44:
                color_44.active = true;
                break;
            case 45:
                color_45.active = true;
                break;
            case 46:
                color_46.active = true;
                break;
            case 47:
                color_47.active = true;
                break;
            case 48:
                color_48.active = true;
                break;
            case 49:
                color_49.active = true;
                break;
            default:
                break;
        }

        color_30.toggled.connect (() => {
            color_selected = 30;
            save ();
        });

        color_31.toggled.connect (() => {
            color_selected = 31;
            save ();
        });

        color_32.toggled.connect (() => {
            color_selected = 32;
            save ();
        });

        color_33.toggled.connect (() => {
            color_selected = 33;
            save ();
        });

        color_34.toggled.connect (() => {
            color_selected = 34;
            save ();
        });

        color_35.toggled.connect (() => {
            color_selected = 35;
            save ();
        });

        color_36.toggled.connect (() => {
            color_selected = 36;
            save ();
        });

        color_37.toggled.connect (() => {
            color_selected = 37;
            save ();
        });

        color_38.toggled.connect (() => {
            color_selected = 38;
            save ();
        });

        color_39.toggled.connect (() => {
            color_selected = 39;
            save ();
        });

        color_40.toggled.connect (() => {
            color_selected = 40;
            save ();
        });

        color_41.toggled.connect (() => {
            color_selected = 41;
            save ();
        });

        color_42.toggled.connect (() => {
            color_selected = 42;
            save ();
        });

        color_43.toggled.connect (() => {
            color_selected = 43;
            save ();
        });

        color_44.toggled.connect (() => {
            color_selected = 44;
            save ();
        });

        color_45.toggled.connect (() => {
            color_selected = 45;
            save ();
        });

        color_46.toggled.connect (() => {
            color_selected = 46;
        });

        color_47.toggled.connect (() => {
            color_selected = 47;
            save ();
        });

        color_48.toggled.connect (() => {
            color_selected = 48;
            save ();
        });

        color_49.toggled.connect (() => {
            color_selected = 49;
            save ();
        });
    }

    public void edit () {
        name_stack.visible_child_name = "name_entry";
        name_entry.grab_focus_without_selecting ();
        if (name_entry.cursor_position < name_entry.text_length) {
            name_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) name_entry.text_length, false);
        }
    }
}
