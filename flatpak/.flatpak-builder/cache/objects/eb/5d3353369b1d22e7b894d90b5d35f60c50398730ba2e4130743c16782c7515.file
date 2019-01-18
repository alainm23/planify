// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2014-2015 Maya Developers (http://launchpad.net/maya)
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

public class Maya.View.ImportDialog : Gtk.Dialog {
    File[] files;
    Widgets.CalendarButton calchooser_button;
    public ImportDialog (File[] files) {
        // Dialog properties
        window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
        type_hint = Gdk.WindowTypeHint.DIALOG;

        this.files = files;
        Gtk.Label import_label;
        if (files.length == 1) {
            string name = "";
            var file = files[0];
            try {
                var fileinfo = file.query_info (FileAttribute.STANDARD_DISPLAY_NAME, FileQueryInfoFlags.NONE, null);
                name = fileinfo.get_display_name ();
            } catch (Error e) {
                // This should never happen.
                critical (e.message);
            }

            import_label = new Gtk.Label (_("Import events from \"%s\" into the following calendar:").printf (name));
        } else {
            import_label = new Gtk.Label (ngettext ("Import events from %d file into the following calendar:", "Import events from %d files into the following calendar:", files.length));
        }

        import_label.wrap = true;
        ((Gtk.Misc) import_label).xalign = 0.0f;

        calchooser_button = new Widgets.CalendarButton ();
        var expander_grid = new Gtk.Grid ();
        expander_grid.expand = true;
        var ok_button = new Gtk.Button.with_label (_("Import"));
        ok_button.clicked.connect (() => import_files ());
        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.clicked.connect (() => destroy ());
        var grid = new Gtk.Grid ();
        grid.row_spacing = 6;
        grid.margin_start = grid.margin_end = 12;
        grid.column_spacing = 12;
        grid.attach (import_label, 0, 0, 2, 1);
        grid.attach (calchooser_button, 0, 1, 2, 1);
        grid.attach (expander_grid, 0, 2, 2, 1);
        var button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_box.spacing = 6;
        button_box.layout_style = Gtk.ButtonBoxStyle.END;
        button_box.add (cancel_button);
        button_box.add (ok_button);
        grid.attach (button_box, 1, 3, 1, 1);
        get_content_area ().add (grid);
    }

    private void import_files () {
        var source = calchooser_button.current_source;
        var calmodel = Model.CalendarModel.get_default ();
        foreach (var file in files) {
            var ical = E.Util.parse_ics_file (file.get_path ());
            if (ical.is_valid () == 1) {
                for (unowned iCal.Component comp = ical.get_first_component (iCal.ComponentKind.VEVENT);
                     comp != null;
                     comp = ical.get_next_component (iCal.ComponentKind.VEVENT)) {
                    var ecal = new E.CalComponent.from_string (comp.as_ical_string ());
                    calmodel.add_event (source, ecal);
                }
            }
        }

        destroy ();
    }
}
