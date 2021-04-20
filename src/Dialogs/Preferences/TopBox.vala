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

public class Dialogs.Preferences.TopBox : Hdy.HeaderBar {
    public signal void back_activated ();
    public signal void done_activated ();

    public TopBox (string icon, string title) {
        decoration_layout = "close:";
        has_subtitle = false;
        show_close_button = false;
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var back_button = new Gtk.Button.from_icon_name ("arrow-back-symbolic", Gtk.IconSize.MENU);
        back_button.always_show_image = true;
        back_button.can_focus = false;
        back_button.label = _("Back");
        back_button.margin = 3;
        back_button.valign = Gtk.Align.CENTER;
        back_button.get_style_context ().add_class ("back-b");
        back_button.get_style_context ().add_class ("flat");

        var title_icon = new Gtk.Image ();
        title_icon.halign = Gtk.Align.CENTER;
        title_icon.valign = Gtk.Align.CENTER;
        title_icon.pixel_size = 16;
        title_icon.gicon = new ThemedIcon (icon);

        var title_button = new Gtk.Label (title);
        title_button.valign = Gtk.Align.CENTER;
        title_button.get_style_context ().add_class ("font-bold");
        title_button.get_style_context ().add_class ("h3");

        var top_grid = new Gtk.Grid ();
        top_grid.valign = Gtk.Align.CENTER;
        top_grid.column_spacing = 6;
        // top_grid.add (title_icon);
        top_grid.add (title_button);

        var done_button = new Gtk.Button.with_label (_("Done"));
        done_button.get_style_context ().add_class ("flat");

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        header_box.hexpand = true;
        header_box.pack_start (back_button, false, false, 0);
        header_box.set_center_widget (top_grid);
        header_box.pack_end (done_button, false, false, 0);

        back_button.clicked.connect (() => {
            back_activated ();
        });

        done_button.clicked.connect (() => {
            done_activated ();
        });

        set_custom_title (header_box);
    }
}
