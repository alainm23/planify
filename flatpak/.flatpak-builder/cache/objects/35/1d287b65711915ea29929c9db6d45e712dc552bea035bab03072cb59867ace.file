// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2015 Maya Developers (http://launchpad.net/maya)
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
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

public class Maya.View.SourceItem : Gtk.ListBoxRow {
    public signal void remove_request (E.Source source);
    public signal void edit_request (E.Source source);

    public string location { public get; private set; }
    public string label { public get; private set; }
    public E.Source source { public get; private set; }

    private Gtk.Stack stack;
    private Gtk.Grid info_grid;

    private Gtk.Button delete_button;
    private Gtk.Revealer delete_revealer;
    private Gtk.Button edit_button;
    private Gtk.Revealer edit_revealer;

    private Gtk.Label calendar_name_label;
    private Gtk.Label calendar_color_label;
    private Gtk.CheckButton visible_checkbutton;

    public SourceItem (E.Source source) {
        this.source = source;
        margin_start = 6;

        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        // Source widget
        E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

        calendar_name_label = new Gtk.Label (source.dup_display_name ());
        ((Gtk.Misc) calendar_name_label).xalign = 0.0f;
        calendar_name_label.hexpand = true;

        label = source.dup_display_name ();
        location = Maya.Util.get_source_location (source);

        calendar_color_label = new Gtk.Label ("  ");
        Util.style_calendar_color (calendar_color_label, cal.dup_color (), true);

        visible_checkbutton = new Gtk.CheckButton ();
        visible_checkbutton.active = cal.selected;
        visible_checkbutton.toggled.connect (() => {
            var calmodel = Model.CalendarModel.get_default ();
            if (visible_checkbutton.active == true) {
                calmodel.add_source (source);
            } else {
                calmodel.remove_source (source);
            }

            cal.set_selected (visible_checkbutton.active);
            try {
                source.write_sync ();
            } catch (GLib.Error error) {
                critical (error.message);
            }
        });

        delete_button = new Gtk.Button.from_icon_name ("edit-delete-symbolic", Gtk.IconSize.MENU);
        delete_button.set_tooltip_text (_("Remove"));
        delete_button.clicked.connect (() => {remove_request (source);});
        delete_button.relief = Gtk.ReliefStyle.NONE;
        delete_revealer = new Gtk.Revealer ();
        delete_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        delete_revealer.add (delete_button);
        delete_revealer.show_all ();
        delete_revealer.set_reveal_child (false);
        if (source.removable == false) {
            delete_revealer.hide ();
            delete_revealer.no_show_all = true;
        }

        edit_button = new Gtk.Button.from_icon_name ("edit-symbolic", Gtk.IconSize.MENU);
        edit_button.set_tooltip_text (_("Edit…"));
        edit_button.clicked.connect (() => {edit_request (source);});
        edit_button.relief = Gtk.ReliefStyle.NONE;
        edit_revealer = new Gtk.Revealer ();
        edit_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        edit_revealer.add (edit_button);
        edit_revealer.show_all ();
        edit_revealer.set_reveal_child (false);
        if (source.writable == false) {
            edit_revealer.hide ();
            edit_revealer.no_show_all = true;
        }

        var calendar_grid = new Gtk.Grid ();
        calendar_grid.column_spacing = 6;
        calendar_grid.attach (visible_checkbutton, 0, 0, 1, 1);
        calendar_grid.attach (calendar_color_label, 1, 0, 1, 1);
        calendar_grid.attach (calendar_name_label, 2, 0, 1, 1);
        calendar_grid.attach (delete_revealer, 3, 0, 1, 1);
        calendar_grid.attach (edit_revealer, 4, 0, 1, 1);

        var calendar_event_box = new Gtk.EventBox ();
        calendar_event_box.add (calendar_grid);

        stack.add_named (calendar_event_box, "calendar");

        // Info bar
        info_grid = new Gtk.Grid ();
        info_grid.column_spacing = 12;
        info_grid.row_spacing = 6;
        info_grid.no_show_all = true;
        var undo_button = new Gtk.Button.with_label (_("Undo"));
        undo_button.clicked.connect (() => {
            Model.CalendarModel.get_default ().restore_calendar ();
            stack.set_visible_child_name ("calendar");
            info_grid.no_show_all = true;
            info_grid.hide ();
        });

        var close_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        close_button.relief = Gtk.ReliefStyle.NONE;
        close_button.clicked.connect (() => {
            hide ();
            destroy ();
        });

        var message_label = new Gtk.Label (_("Calendar \"%s\" removed.").printf (source.display_name));
        message_label.hexpand = true;
        ((Gtk.Misc) message_label).xalign = 0.0f;
        info_grid.attach (message_label, 0, 0, 1, 1);
        info_grid.attach (undo_button, 1, 0, 1, 1);
        info_grid.attach (close_button, 2, 0, 1, 1);
        stack.add_named (info_grid, "info");
        stack.set_visible_child_name ("calendar");

        add (stack);

        calendar_event_box.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        calendar_event_box.enter_notify_event.connect ((event) => {
            delete_revealer.set_reveal_child (true);
            edit_revealer.set_reveal_child (true);
            return false;
        });

        calendar_event_box.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR)
                return false;

            delete_revealer.set_reveal_child (false);
            edit_revealer.set_reveal_child (false);
            return false;
        });

        source.changed.connect (source_has_changed);
    }

    public void source_has_changed () {
        calendar_name_label.label = source.dup_display_name ();
        E.SourceCalendar cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);

        Util.style_calendar_color (calendar_color_label, cal.dup_color (), true);

        visible_checkbutton.active = cal.selected;
    }

    public void show_calendar_removed () {
        info_grid.no_show_all = false;
        info_grid.show_all ();
        stack.set_visible_child_name ("info");
    }
}

public class Maya.View.SourceItemHeader : Gtk.ListBoxRow {
    public string label { public get; private set; }
    public uint children = 1;
    public SourceItemHeader (string label) {
        this.label = label;
        var header_label = new Gtk.Label (label);
        header_label.get_style_context ().add_class ("h4");
        ((Gtk.Misc) header_label).xalign = 0.0f;
        header_label.hexpand = true;
        add (header_label);
    }
}
