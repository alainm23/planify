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
    private Gtk.Label current_location_content;
    private Gtk.Grid location_grid;
    private Gtk.Menu menu = null;

    public DatabaseSettings () {
        var database_header = new Gtk.Label (_("Database"));
        database_header.get_style_context ().add_class ("font-weight-600");
        database_header.halign = Gtk.Align.START;

        current_location_content = new Gtk.Label ("<small>%s</small>".printf (Planner.database.get_database_path ()));
        current_location_content.get_style_context ().add_class ("font-weight-600");
        current_location_content.halign = Gtk.Align.START;
        current_location_content.use_markup = true;
        current_location_content.ellipsize = Pango.EllipsizeMode.MIDDLE;

        location_grid = new Gtk.Grid ();
        location_grid.orientation = Gtk.Orientation.VERTICAL;
        location_grid.add (database_header);
        location_grid.add (current_location_content);
        location_grid.margin_end = 16;
        location_grid.tooltip_text = _("Current location: %s".printf (Planner.database.get_database_path ()));

        var change_button = new Gtk.Button.with_label (_("Change"));
        change_button.valign = Gtk.Align.CENTER;
        change_button.can_focus = false;

        var menu_button = new Gtk.Button.from_icon_name ("pan-down-symbolic", Gtk.IconSize.MENU);
        menu_button.can_focus = false;

        var button_grid = new Gtk.Grid ();
        button_grid.valign = Gtk.Align.CENTER;
        button_grid.get_style_context ().add_class ("grid-linked");
        button_grid.add (change_button);
        button_grid.add (menu_button);

        var menu_icon = new Gtk.Image ();
        menu_icon.gicon = new ThemedIcon ("preferences-system-symbolic");
        menu_icon.pixel_size = 14;

        var current_location_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        current_location_box.margin_start = 12;
        current_location_box.margin_end = 9;
        current_location_box.margin_top = 3;
        current_location_box.margin_bottom = 3;
        current_location_box.hexpand = true;
        current_location_box.pack_start (location_grid, false, false, 0);
        current_location_box.pack_end (button_grid, false, false, 0);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.margin_top = 12;
        main_box.get_style_context ().add_class ("view");
        main_box.hexpand = true;
        main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);
        main_box.pack_start (current_location_box, false, false, 0);
        main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);
        
        add (main_box);

        menu_button.clicked.connect (() => {
            if (menu == null) {
                menu = new Gtk.Menu ();

                var reset_default = new Gtk.MenuItem.with_label (_("Reset to default"));

                menu.add (reset_default);
                menu.show_all ();

                reset_default.activate.connect (() => {
                    var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                        _("Are you sure you want to restore the database location to default?"),
                        _("The new database location will be: <b>%s</b>").printf (Environment.get_user_data_dir () + "/com.github.alainm23.planner/database.db"),
                        "dialog-warning",
                    Gtk.ButtonsType.CANCEL);
        
                    var remove_button = new Gtk.Button.with_label (_("Change"));
                    remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
                    message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);
        
                    message_dialog.show_all ();
        
                    if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                        Planner.database.reset_database_path_to_default ();
                    }
        
                    message_dialog.destroy ();
                });
            }
            
            menu.popup_at_pointer (null);
        });

        change_button.clicked.connect (() => {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Are you sure you want to change the database location?"),
                _("This process will move your database file to the selected location."),
                "dialog-warning",
            Gtk.ButtonsType.CANCEL);

            var remove_button = new Gtk.Button.with_label (_("Change"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                var dialog = new Gtk.FileChooserDialog (
                    _("database location"), 
                    this as Gtk.Window, 
                    Gtk.FileChooserAction.SAVE,
                    _("_Cancel"),
                    Gtk.ResponseType.CANCEL,
                    _("_Open"),
                    Gtk.ResponseType.ACCEPT
                );

                dialog.local_only = false; //allow for uri
                var filter = new Gtk.FileFilter ();
                filter.add_pattern ("*.db");
                filter.set_filter_name (_("Planner DB Files (sqlite)"));
                dialog.add_filter (filter);
                dialog.set_modal (true);
                dialog.set_file (GLib.File.new_for_path (Planner.database.get_database_path ()));
                dialog.response.connect (dialog_response);
                dialog.show ();
            }

            message_dialog.destroy ();
        });
    }

    private void dialog_response (Gtk.Dialog dialog, int response_id) {
        var open_dialog = dialog as Gtk.FileChooserDialog;
        
        switch (response_id) {
            case Gtk.ResponseType.ACCEPT:
                var filename = open_dialog.get_filename ();
                var file = GLib.File.new_for_path (filename);
                if (!file.query_exists ()) {
                    var old_file = GLib.File.new_for_path (Planner.database.get_database_path ());
                    old_file.copy (file, FileCopyFlags.ALL_METADATA, null, (current_num_bytes, total_num_bytes) => {
                        print ("%" + int64.FORMAT + " bytes of %" + int64.FORMAT + " bytes copied.\n",
                            current_num_bytes, total_num_bytes);
                    });
                }

                Planner.database.set_database_path (filename);
                current_location_content.label = "<small>%s</small>".printf (filename);
                location_grid.tooltip_text = _("Current location: %s".printf (filename));

                break;
            default:
                break;
        }

        dialog.destroy ();
    }
}
