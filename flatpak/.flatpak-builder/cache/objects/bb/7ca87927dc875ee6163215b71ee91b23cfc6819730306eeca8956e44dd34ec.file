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

namespace Maya.View.Widgets {

    public class ContractorMenuItem : Gtk.MenuItem {
        private Granite.Services.Contract contract;

        public ContractorMenuItem (Granite.Services.Contract cont) {
            this.contract = cont;

            label = cont.get_display_name ();
        }

        public override void activate () {
            /* creates a .ics file */
            Util.save_temp_selected_calendars ();

            string file_path = GLib.Environment.get_tmp_dir () + "/calendar.ics";
            File cal_file = File.new_for_path(file_path);

            try {
                contract.execute_with_file (cal_file);
            } catch (Error err) {
                warning (err.message);
            }
        }
    }

    public class ContractorButtonWithMenu : Gtk.MenuButton {

        private Gtk.FileChooserDialog filechooser;

        public ContractorButtonWithMenu (string tooltiptext) {
            Object (
                image: new Gtk.Image.from_icon_name ("document-export", Gtk.IconSize.LARGE_TOOLBAR),
                tooltip_text: tooltiptext
            );

            var menu = new Gtk.Menu ();

            try {
                var contracts = Granite.Services.ContractorProxy.get_contracts_by_mime ("text/calender");

                for (int i = 0; i < contracts.size; i++) {
                    var contract = contracts.get (i);
                    Gtk.MenuItem menu_item;

                    menu_item = new ContractorMenuItem (contract);
                    menu.append (menu_item);
                }
            } catch (GLib.Error error) {
                critical (error.message);
            }
            Gtk.MenuItem item = new Gtk.MenuItem.with_label(_("Export Calendar…"));
            item.activate.connect (savecal);
            menu.append (item);
            menu.show_all ();
            popup = menu;
        }

        private void savecal () {
            /* creates a .ics file */
            Util.save_temp_selected_calendars ();
            filechooser = new Gtk.FileChooserDialog (_("Export Calendar…"), null, Gtk.FileChooserAction.SAVE);
            var filter = new Gtk.FileFilter ();
            filter.add_mime_type("text/calendar");
            filechooser.set_current_name(_("calendar.ics"));
            filechooser.set_filter (filter);
            filechooser.add_button (_("Cancel"), Gtk.ResponseType.CLOSE);
            filechooser.add_button (_("Save"), Gtk.ResponseType.APPLY);
            filechooser.response.connect (on_response);
            filechooser.show_all ();
            filechooser.run ();


        }

        private void on_response (Gtk.Dialog source, int response_id) {
            switch (response_id) {
            case Gtk.ResponseType.APPLY:
                var destination = filechooser.get_filename ();
                if (destination == null) {
                    destination = filechooser.get_current_folder();
                } else if (!destination.has_suffix(".ics")) {
                    destination += ".ics";
                }
                try {
                    GLib.Process.spawn_command_line_async ("mv " + GLib.Environment.get_tmp_dir () + "/calendar.ics " + destination);
                } catch (SpawnError e) {
                    warning (e.message);
                }
                filechooser.destroy ();
                break;
            case Gtk.ResponseType.CLOSE:
                filechooser.destroy ();
                break;
            }
        }
    }

}
