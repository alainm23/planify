/*
* Copyright © 2020 Roman Schaller. (https://github.com/alainm23/planner)
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
* Authored by: Roman Schaller. <roman.schaller@gmail.com>
*/

public class Dialogs.Preferences.DatabaseSettings : Gtk.EventBox {
    public signal void resetSettings ();
    public signal void locationChanged (GLib.File file);

    public DatabaseSettings () {

        var location_path = Planner.database.get_database_path();
        var current_location_label = new Gtk.Label (_("Current location: %s").printf(location_path));
        current_location_label.get_style_context ().add_class ("font-weight-600");

        var current_location_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        current_location_box.margin_start = 12;
        current_location_box.margin_end = 12;
        current_location_box.margin_top = 6;
        current_location_box.margin_bottom = 6;
        current_location_box.hexpand = true;
        current_location_box.pack_start (current_location_label, false, true, 0);

        var change_location_button = new Gtk.Button.with_label(_("Change..."));
        change_location_button.can_focus = false;
        change_location_button.get_style_context ().add_class ("no-padding");
        change_location_button.valign = Gtk.Align.CENTER;
        var database_location_reset_default = new Gtk.Button.with_label(_("reset to default"));
        database_location_reset_default.can_focus = false;
        database_location_reset_default.get_style_context ().add_class ("no-padding");
        database_location_reset_default.valign = Gtk.Align.CENTER;

        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        button_box.margin_start = 12;
        button_box.margin_end = 12;
        button_box.margin_top = 6;
        button_box.margin_bottom = 6;
        button_box.hexpand = true;
        button_box.pack_end (change_location_button, false, true, 0);
        button_box.pack_end (database_location_reset_default, false, true, 0);
      
        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.get_style_context ().add_class ("view");
        main_box.hexpand = true;
        main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);
        main_box.pack_start (current_location_box, false, false, 0);
        main_box.pack_start (button_box, false, false, 0);
        

        database_location_reset_default.clicked.connect (() => {
            resetSettings ();
        });

        change_location_button.clicked.connect (() => {
            var dialog = new Gtk.FileChooserDialog (_("database location"), 
                                                    this as Gtk.Window, 
                                                    Gtk.FileChooserAction.SAVE,
                                                    Gtk.Stock.CANCEL,
                                                    Gtk.ResponseType.CANCEL,
                                                    Gtk.Stock.OPEN,
                                                    Gtk.ResponseType.ACCEPT);
            dialog.local_only = false; //allow for uri
            var filter = new Gtk.FileFilter();
            filter.add_pattern ("*.db");
            filter.set_filter_name (_("Planner DB Files (sqlite)"));
            dialog.add_filter (filter);
            dialog.set_modal (true);
            dialog.response.connect (dialog_response);
            dialog.show ();
        });

        add (main_box);
    }

    void dialog_response (Gtk.Dialog dialog, int response_id) {
        var open_dialog = dialog as Gtk.FileChooserDialog;
        switch (response_id) {
            case Gtk.ResponseType.ACCEPT:
                var file = open_dialog.get_filename();
                this.locationChanged (GLib.File.new_for_path(file));
                break;
            default:
                break;
        }
        dialog.destroy ();
    }
}