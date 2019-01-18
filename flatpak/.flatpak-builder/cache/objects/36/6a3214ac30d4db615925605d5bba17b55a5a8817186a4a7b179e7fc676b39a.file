// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2015 Maya Developers (http://launchpad.net/maya)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Maxwell Barvian
 *              Corentin Noël <corentin@elementaryos.org>
 */

/**
 * Represents a single day on the grid.
 */
public class Maya.View.GridDay : Gtk.EventBox {

    /*
     * Event emitted when the day is double clicked or the ENTER key is pressed.
     */
    public signal void on_event_add (DateTime date);

    public DateTime date { get; private set; }
    // We need to know if it is the first column in order to not draw it's left border
    public bool draw_left_border = true;
    Gtk.Label label;
    Gtk.Grid container_grid;
    VAutoHider event_box;
    GLib.HashTable<string, EventButton> event_buttons;

    public bool in_current_month {
        set {
            if (value) {
                get_style_context ().remove_class ("other_month");
                get_style_context ().remove_class (Gtk.STYLE_CLASS_DIM_LABEL);
            } else {
                get_style_context ().add_class ("other_month");
                get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            }
        }
    }

    private const int EVENT_MARGIN = 3;

    public GridDay (DateTime date) {
        this.date = date;
        event_buttons = new GLib.HashTable<string, EventButton> (str_hash, str_equal);

        container_grid = new Gtk.Grid ();
        label = new Gtk.Label ("");
        event_box = new VAutoHider ();
        event_box.expand = true;

        // EventBox Properties
        can_focus = true;
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.KEY_PRESS_MASK;
        events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;
        var style_provider = Util.Css.get_css_provider ();
        get_style_context ().add_provider (style_provider, 600);
        get_style_context ().add_class ("cell");

        label.halign = Gtk.Align.END;
        label.get_style_context ().add_provider (style_provider, 600);
        label.name = "date";

        Util.set_margins (label, EVENT_MARGIN, EVENT_MARGIN, 0, EVENT_MARGIN);
        Util.set_margins (event_box, 0, EVENT_MARGIN, EVENT_MARGIN, EVENT_MARGIN);
        container_grid.attach (label, 0, 0, 1, 1);
        container_grid.attach (event_box, 0, 1, 1, 1);

        add (container_grid);
        container_grid.show_all ();

        // Signals and handlers
        button_press_event.connect (on_button_press);
        key_press_event.connect (on_key_press);
        scroll_event.connect ((event) => {return GesturesUtils.on_scroll_event (event);});

        Gtk.TargetEntry dnd = {"binary/calendar", 0, 0};
        Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION, {dnd}, Gdk.DragAction.MOVE);
    }

    public override bool drag_drop (Gdk.DragContext context, int x, int y, uint time_) {
        Gtk.drag_finish (context, true, false, time_);
        Gdk.Atom atom = Gtk.drag_dest_find_target (this, context, Gtk.drag_dest_get_target_list (this));
        Gtk.drag_get_data (this, context, atom, time_);
        return true;
    }

    public override void drag_data_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint info, uint time_) {
        var calmodel = Model.CalendarModel.get_default ();
        var comp = calmodel.drag_component;
        unowned iCal.Component icalcomp = comp.get_icalcomponent ();
        E.Source src = comp.get_data ("source");
        var start = icalcomp.get_dtstart ();
        var end = icalcomp.get_dtend ();
        var gap = date.get_day_of_month () - start.day;
        start.day += gap;

        if (end.is_null_time () == 0) {
            end.day += gap;
            icalcomp.set_dtend (end);
        }

        icalcomp.set_dtstart (start);
        calmodel.update_event (src, comp, E.CalObjModType.ALL);
    }

    public void add_event_button (EventButton button) {
        unowned iCal.Component calcomp = button.comp.get_icalcomponent ();
        string uid = calcomp.get_uid ();
        lock (event_buttons) {
            if (event_buttons.contains (uid)) {
                return;
            }

            event_buttons.set (uid, button);
        }

        if (button.get_parent () != null) {
            button.unparent ();
        }

        event_box.add (button);
        button.show_all ();

    }

    public bool update_event (E.CalComponent comp) {
        unowned iCal.Component calcomp = comp.get_icalcomponent ();
        string uid = calcomp.get_uid ();

        lock (event_buttons) {
            var button = event_buttons.get (uid);
            if (button != null) {
                button.update (comp);
                event_box.update (button);
            } else {
                return false;
            }
        }

        return true;
    }

    public void remove_event (E.CalComponent comp) {
        unowned iCal.Component calcomp = comp.get_icalcomponent ();
        string uid = calcomp.get_uid ();
        lock (event_buttons) {
            var button = event_buttons.get (uid);
            if (button != null) {
                event_buttons.remove (uid);
                destroy_button (button);
            }
        }
    }

    public void clear_events () {
        foreach (weak EventButton button in event_buttons.get_values ()) {
            destroy_button (button);
        }

        event_buttons.remove_all ();
    }

    private void destroy_button (EventButton button) {
        button.set_reveal_child (false);
        Timeout.add (button.transition_duration, () => {
            button.destroy ();
            return false;
        });
    }

    public void update_date (DateTime date) {
        this.date = date;
        label.label = date.get_day_of_month ().to_string ();
    }

    public void set_selected (bool selected) {
        if (selected) {
            set_state_flags (Gtk.StateFlags.SELECTED, true);
        } else {
            set_state_flags (Gtk.StateFlags.NORMAL, true);
        }
    }

    private bool on_button_press (Gdk.EventButton event) {
        if (event.type == Gdk.EventType.2BUTTON_PRESS && event.button == Gdk.BUTTON_PRIMARY)
            on_event_add (date);

        grab_focus ();
        return false;
    }

    private bool on_key_press (Gdk.EventKey event) {
        if (event.keyval == Gdk.keyval_from_name("Return") ) {
            on_event_add (date);
            return true;
        }

        return false;
    }
}
