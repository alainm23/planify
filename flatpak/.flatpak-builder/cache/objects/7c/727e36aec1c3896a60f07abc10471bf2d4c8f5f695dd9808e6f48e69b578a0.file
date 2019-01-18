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
 * Authored by: Jaap Broekhuizen
 */

namespace Maya.View {

public enum EventType {
    ADD,
    EDIT
}

public class EventDialog : Gtk.Dialog {
        public E.Source? source { get; set; }
        public E.Source? original_source { get; private set; }
        public E.CalComponent ecal { get; set; }
        public DateTime date_time { get; set; }

        /**
         * A boolean indicating whether we can edit the current event.
         */
        public bool can_edit = true;

        private E.CalObjModType mod_type { get; private set; default = E.CalObjModType.ALL; }
        private EventType event_type { get; private set; }

        private EventEdition.GuestsPanel guests_panel;
        private EventEdition.InfoPanel info_panel;
        private EventEdition.LocationPanel location_panel;
        private EventEdition.ReminderPanel reminder_panel;
        private EventEdition.RepeatPanel repeat_panel;

        public EventDialog (E.CalComponent? ecal = null, DateTime? date_time = null) {
            this.deletable = false;

            if (ecal != null)
                original_source = ecal.get_data<E.Source> ("source");
            this.date_time = date_time;

            this.ecal = ecal;

            if (date_time != null) {
                title = _("Add Event");
                event_type = EventType.ADD;
            } else {
                title = _("Edit Event");
                event_type = EventType.EDIT;
            }

            // Dialog properties
            window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
            type_hint = Gdk.WindowTypeHint.DIALOG;

            // Build dialog
            build_dialog (date_time != null);
        }

        //--- Public Methods ---//

        void build_dialog (bool add_event) {
            guests_panel = new EventEdition.GuestsPanel (this);
            info_panel = new EventEdition.InfoPanel (this);
            location_panel = new EventEdition.LocationPanel (this);
            reminder_panel = new EventEdition.ReminderPanel (this);
            repeat_panel = new EventEdition.RepeatPanel (this);

            var handler = new Maya.Services.EventParserHandler ();
            var parser = handler.get_parser (handler.get_locale ());
            if (handler.get_locale ().contains (parser.get_language ())) {
                // If there is handler for the current locale then...
                info_panel.nl_parsing_enabled = true;
                bool event_parsed = false;
                info_panel.parse_event.connect ((ev_str) => {
                    if (!event_parsed) {
                        var ev = parser.parse_source (ev_str);
                        info_panel.title = ev.title;
                        info_panel.from_date = ev.from;
                        info_panel.to_date = ev.to;
                        info_panel.from_time = ev.from;
                        info_panel.to_time = ev.to;
                        info_panel.all_day = ev.all_day;
                        guests_panel.guests = ev.participants;
                        location_panel.location = ev.location;
                        event_parsed = true;
                    }
                    else
                        save_dialog ();
                });
            }

            var stack = new Gtk.Stack ();
            stack.add_titled (info_panel, "infopanel", _("General Informations"));
            stack.add_titled (location_panel, "locationpanel", _("Location"));
            stack.add_titled (guests_panel, "guestspanel", _("Guests"));
            stack.add_titled (reminder_panel, "reminderpanel", _("Reminders"));
            stack.add_titled (repeat_panel, "repeatpanel", _("Repeat"));
            stack.child_set_property (info_panel, "icon-name", "office-calendar-symbolic");
            stack.child_set_property (location_panel, "icon-name", "mark-location-symbolic");
            stack.child_set_property (guests_panel, "icon-name", "system-users-symbolic");
            stack.child_set_property (reminder_panel, "icon-name", "alarm-symbolic");
            stack.child_set_property (repeat_panel, "icon-name", "media-playlist-repeat-symbolic");

            var stack_switcher = new Gtk.StackSwitcher ();
            stack_switcher.homogeneous = true;
            stack_switcher.margin = 12;
            stack_switcher.margin_top = 0;
            stack_switcher.stack = stack;

            var buttonbox = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
            buttonbox.margin_top = 6;
            buttonbox.margin_end = 12;
            buttonbox.margin_start = 12;
            buttonbox.spacing = 6;

            buttonbox.baseline_position = Gtk.BaselinePosition.CENTER;
            buttonbox.set_layout (Gtk.ButtonBoxStyle.END);

            if (add_event == false) {
                var delete_button = new Gtk.Button.with_label (_("Delete Event"));
                delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                delete_button.clicked.connect (remove_event);
                buttonbox.add (delete_button);
                buttonbox.set_child_secondary (delete_button, true);
                buttonbox.set_child_non_homogeneous (delete_button, true);
            }

            Gtk.Button create_button = new Gtk.Button ();
            create_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            create_button.clicked.connect (save_dialog);
            if (add_event == true) {
                create_button.label = _("Create Event");
                create_button.sensitive = false;
            } else {
                create_button.label = _("Save Changes");
            }

            var cancel_button = new Gtk.Button.with_label (_("Cancel"));
            cancel_button.clicked.connect (() => {this.destroy ();});

            buttonbox.add (cancel_button);
            buttonbox.add (create_button);

            var grid = new Gtk.Grid ();
            grid.row_spacing = 6;
            grid.column_spacing = 12;
            grid.attach (stack_switcher, 0, 0, 1, 1);
            grid.attach (stack, 0, 1, 1, 1);
            grid.attach (buttonbox, 0, 2, 1, 1);

            ((Gtk.Container)get_content_area ()).add (grid);

            info_panel.valid_event.connect ((is_valid) => {
                create_button.sensitive = is_valid;
            });

            show_all ();
            stack.set_visible_child_name ("infopanel");
        }

        public static Gtk.Label make_label (string text) {
            var label = new Gtk.Label ("<span weight='bold'>%s</span>".printf (text));
            label.use_markup = true;
            label.set_alignment (0.0f, 0.5f);
            return label;
        }

        private void save_dialog () {
            info_panel.save ();
            location_panel.save ();
            guests_panel.save ();
            reminder_panel.save ();
            repeat_panel.save ();

            var calmodel = Model.CalendarModel.get_default ();
            if (event_type == EventType.ADD)
                calmodel.add_event (source, ecal);
            else {
                assert (original_source != null);

                if (original_source.dup_uid () == source.dup_uid ()) {
                    // Same uids, just modify
                    calmodel.update_event (source, ecal, mod_type);
                } else {
                    // Different calendar, remove and readd
                    calmodel.remove_event (original_source, ecal, mod_type);
                    calmodel.add_event (source, ecal);
                }
            }

            this.destroy ();
        }

        private void remove_event () {
            var calmodel = Model.CalendarModel.get_default ();
            calmodel.remove_event (original_source, ecal, mod_type);
            this.destroy ();
        }
    }
}
