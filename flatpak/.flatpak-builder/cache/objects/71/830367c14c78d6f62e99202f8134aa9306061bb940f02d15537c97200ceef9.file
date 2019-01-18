// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2017 elementary LLC. (https://elementary.io)
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
 * Authored by: Maxwell Barvian <maxwell@elementary.io>
 *              Corentin Noël <corentin@elementary.io>
 */

namespace Maya {
    namespace Option {
        private static bool ADD_EVENT = false;
        private static string SHOW_DAY = null;
        private static bool PRINT_VERSION = false;
    }

    public class Application : Gtk.Application {
        public MainWindow window;
        private View.CalendarView calview;
        private View.AgendaView sidebar;

        construct {
            flags |= ApplicationFlags.HANDLES_OPEN;

            application_id = Build.EXEC_NAME;

            Intl.setlocale (LocaleCategory.ALL, "");
            Intl.textdomain (Build.GETTEXT_PACKAGE);
        }

        public const OptionEntry[] app_options = {
            { "add-event", 'a', 0, OptionArg.NONE, out Option.ADD_EVENT, N_("Create an event"), null },
            { "show-day", 's', 0, OptionArg.STRING, out Option.SHOW_DAY, N_("Focus the given day"), N_("date") },
            { "version", 'v', 0, OptionArg.NONE, out Option.PRINT_VERSION, N_("Print version info and exit"), null },
            { null }
        };

        protected override void activate () {
            if (get_windows () != null) {
                get_windows ().data.present (); // present window if app is already running
                return;
            }

            if (Option.SHOW_DAY != null) {
                var date = Date ();
                date.set_parse (Option.SHOW_DAY);
                if (date.valid () == true) {
                    var datetime = Settings.SavedState.get_default ().get_selected ();
                    datetime = datetime.add_years ((int)date.get_year () - datetime.get_year ());
                    datetime = datetime.add_days ((int)date.get_day_of_year () - datetime.get_day_of_year ());
                    Settings.SavedState.get_default ().selected_day = datetime.format ("%Y-%j");
                    Settings.SavedState.get_default ().month_page = datetime.format ("%Y-%m");
                } else {
                    warning ("Invalid date '%s' - Ignoring", Option.SHOW_DAY);
                }
            }

            var calmodel = Model.CalendarModel.get_default ();
            calmodel.load_all_sources ();

            init_gui ();
            window.show_all ();

            if (Option.ADD_EVENT) {
                on_tb_add_clicked (calview.selected_date);
            }

            Gtk.main ();
        }

        public override void open (File[] files, string hint) {
            bool first_start = false;
            if (get_windows () == null) {
                var calmodel = Model.CalendarModel.get_default ();
                calmodel.load_all_sources ();

                init_gui ();
                window.show_all ();
                first_start = true;
            }

            var dialog = new Maya.View.ImportDialog (files);
            dialog.transient_for = window;
            dialog.show_all ();

            if (first_start) {
                Gtk.main ();
            }
        }

        /**
         * Initializes the graphical window and its components
         */
        void init_gui () {
            var saved_state = Settings.SavedState.get_default ();

            window = new MainWindow (this);
            window.title = _(Build.APP_NAME);
            window.default_width = saved_state.window_width;
            window.default_height = saved_state.window_height;

            if (saved_state.window_state == Settings.WindowState.MAXIMIZED) {
                window.maximize ();
            }

            window.delete_event.connect (on_window_delete_event);
            window.destroy.connect (on_quit);

            var quit_action = new SimpleAction ("quit", null);
            quit_action.activate.connect (() => {
                if (window != null) {
                    window.destroy ();
                }
            });

            add_action (quit_action);
            set_accels_for_action("app.quit", new string[] { "<Control>q" });

            var toolbar = new View.HeaderBar ();
            toolbar.add_calendar_clicked.connect (() => on_tb_add_clicked (calview.selected_date));
            toolbar.on_menu_today_toggled.connect (on_menu_today_toggled);
            window.set_titlebar (toolbar);

            sidebar = new View.AgendaView ();
            // Don't automatically display all the widgets on the sidebar
            sidebar.no_show_all = true;
            sidebar.show ();
            sidebar.event_removed.connect (on_remove);
            sidebar.event_modified.connect (on_modified);
            sidebar.set_size_request(160,0);

            calview = new View.CalendarView ();
            calview.vexpand = true;
            calview.on_event_add.connect ((date) => on_tb_add_clicked (date));
            calview.edition_request.connect (on_modified);
            calview.selection_changed.connect ((date) => sidebar.set_selected_date (date));

            window.hpaned.pack1 (calview, true, false);
            window.hpaned.pack2 (sidebar, true, false);
            window.hpaned.position = saved_state.hpaned_position;

            add_window (window);
        }

        /**
         * Called when the remove button is selected.
         */
        void on_remove (E.CalComponent comp) {
            Model.CalendarModel.get_default ().remove_event (comp.get_data<E.Source> ("source"), comp, E.CalObjModType.THIS);
        }

        /**
         * Called when the edit button is selected.
         */
        void on_modified (E.CalComponent comp) {
            var dialog = new Maya.View.EventDialog (comp, null);
            dialog.transient_for = window;
            dialog.present ();
        }

        void on_quit () {
            Model.CalendarModel.get_default ().delete_trashed_calendars ();
            Gtk.main_quit ();
        }

        void update_saved_state () {
            debug("Updating saved state");

            // Save window state
            var saved_state = Settings.SavedState.get_default ();
            if ((window.get_window ().get_state () & Settings.WindowState.MAXIMIZED) != 0) {
                saved_state.window_state = Settings.WindowState.MAXIMIZED;
            } else {
                saved_state.window_state = Settings.WindowState.NORMAL;
            }

            // Save window size
            if (saved_state.window_state == Settings.WindowState.NORMAL) {
                int width, height;
                window.get_size (out width, out height);
                saved_state.window_width = width;
                saved_state.window_height = height;
            }

            saved_state.hpaned_position = window.hpaned.position;
        }

        //--- SIGNAL HANDLERS ---//

        bool on_window_delete_event (Gdk.EventAny event) {
            update_saved_state ();
            return false;
        }

        void on_tb_add_clicked (DateTime dt) {
            var dialog = new Maya.View.EventDialog (null, dt);
            dialog.transient_for = window;
            dialog.show_all ();
        }

        void on_menu_today_toggled () {
            calview.today ();
        }
    }

    public static int main (string[] args) {
        var context = new OptionContext (_("Calendar"));
        context.add_main_entries (Application.app_options, "maya");
        context.add_group (Gtk.get_option_group (true));

        try {
            context.parse (ref args);
        } catch (Error e) {
            warning (e.message);
        }

        if (Option.PRINT_VERSION) {
            stdout.printf("Maya %s\n", Build.VERSION);
            stdout.printf("Copyright 2011-2017 elementary LLC.\n");
            return 0;
        }

        GtkClutter.init (ref args);
        var app = new Application ();

        return app.run (args);
    }
}
