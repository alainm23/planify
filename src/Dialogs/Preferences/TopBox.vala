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

public class Dialogs.Preferences.TopBox : Gtk.Box {
    private Gtk.Button default_button;

    public signal void back_activated ();
    public signal void action_activated ();

    public string action_button {
        set {
            var image = new Gtk.Image ();
            image.gicon = new ThemedIcon (value);
            image.pixel_size = 16;

            default_button.image = image;
            default_button.visible = true;
        }
    }

    public TopBox (string icon, string title) {
        var back_button = new Gtk.Button.from_icon_name ("arrow-back-symbolic", Gtk.IconSize.MENU);
        back_button.always_show_image = true;
        back_button.can_focus = false;
        back_button.label = _("Back");
        back_button.margin = 3;
        back_button.valign = Gtk.Align.CENTER;
        back_button.get_style_context ().add_class ("flat");
        back_button.get_style_context ().add_class ("dim-label");

        var title_button = new Gtk.Label (title);
        title_button.valign = Gtk.Align.CENTER;
        title_button.get_style_context ().add_class ("font-bold");
        title_button.get_style_context ().add_class ("h3");

        default_button = new Gtk.Button ();
        default_button.margin = 3;
        default_button.valign = Gtk.Align.CENTER;
        default_button.get_style_context ().add_class ("flat");
        default_button.get_style_context ().add_class ("dim-label");
        default_button.visible = false;
        default_button.no_show_all = true;

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        header_box.pack_start (back_button, false, false, 0);
        header_box.set_center_widget (title_button);
        header_box.pack_end (default_button, false, false, 0);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.hexpand = true;
        main_box.valign = Gtk.Align.START;
        main_box.pack_start (header_box);

        back_button.clicked.connect (() => {
            back_activated ();
        });

        default_button.clicked.connect (() => {
            action_activated ();
        });

        add (main_box);
    }
}
