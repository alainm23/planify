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

namespace Maya.View {
    public class HeaderBar : Gtk.HeaderBar {
        public signal void on_search (string search);
        public signal void on_menu_today_toggled ();
        public signal void add_calendar_clicked ();

        public Gtk.SearchEntry search_bar;
        private Widgets.DateSwitcher month_switcher;
        private Widgets.DateSwitcher year_switcher;

        public HeaderBar () {
            Object (show_close_button: true);
        }

        construct {
            var button_add = new Gtk.Button.from_icon_name ("appointment-new", Gtk.IconSize.LARGE_TOOLBAR);
            button_add.tooltip_text = _("Create a new event");

            var button_today = new Gtk.Button.from_icon_name ("calendar-go-today", Gtk.IconSize.LARGE_TOOLBAR);
            button_today.tooltip_text = _("Go to today's date");

            var source_popover = new View.SourceSelector ();

            var menu_button = new Gtk.MenuButton ();
            menu_button.image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
            menu_button.popover = source_popover;
            menu_button.tooltip_text = _("Manage Calendars");

            month_switcher = new Widgets.DateSwitcher (10);
            year_switcher = new Widgets.DateSwitcher (-1);
            var calmodel = Model.CalendarModel.get_default ();
            set_switcher_date (calmodel.month_start);

            var contractor = new Widgets.ContractorButtonWithMenu (_("Export or Share the default Calendar"));

            var title_grid = new Gtk.Grid ();
            title_grid.column_spacing = 6;
            title_grid.add (button_today);
            title_grid.add (month_switcher);
            title_grid.add (year_switcher);

            var spinner = new Widgets.DynamicSpinner ();

            pack_start (button_add);
            pack_start (spinner);
            set_custom_title (title_grid);
            pack_end (menu_button);
            pack_end (contractor);

            button_add.clicked.connect (() => add_calendar_clicked ());
            button_today.clicked.connect (() => on_menu_today_toggled ());
            month_switcher.left_clicked.connect (() => Model.CalendarModel.get_default ().change_month (-1));
            month_switcher.right_clicked.connect (() => Model.CalendarModel.get_default ().change_month (1));
            year_switcher.left_clicked.connect (() => Model.CalendarModel.get_default ().change_year (-1));
            year_switcher.right_clicked.connect (() => Model.CalendarModel.get_default ().change_year (1));
            calmodel.parameters_changed.connect (() => {
                set_switcher_date (calmodel.month_start);
            });
        }

        public void set_switcher_date (DateTime date) {
            month_switcher.text = date.format ("%OB");
            year_switcher.text = date.format ("%Y");
        }
    }
}
