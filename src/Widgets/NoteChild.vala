/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Widgets.NoteChild : Gtk.FlowBoxChild {
    private Gtk.Entry title_entry;
    private Gtk.SourceView source_view;

    public NoteChild () {
        /*
        Object (
            label: _label
        );
        */
    }

    construct {
        can_focus = false;

        title_entry = new Gtk.Entry ();
        title_entry.margin_start = 6;
        title_entry.margin_top = 6;
        title_entry.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        title_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        title_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        title_entry.get_style_context ().add_class ("planner-entry");
        title_entry.get_style_context ().add_class ("no-padding");
        title_entry.get_style_context ().add_class ("planner-entry-bold");
        title_entry.placeholder_text = _("Title");

        source_view = new Gtk.SourceView ();
        source_view.can_focus = true;
        source_view.margin = 6;
        source_view.expand = true;

        var preferences_button = new Gtk.ToggleButton ();
        preferences_button.add (new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.MENU));
        preferences_button.tooltip_text = _("Preferences");
        preferences_button.valign = Gtk.Align.CENTER;
        preferences_button.halign = Gtk.Align.CENTER;
        preferences_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        preferences_button.get_style_context ().add_class ("settings-button");

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        action_box.margin_end = 6;
        action_box.margin_bottom = 6;
        action_box.pack_end (preferences_button, false, false, 0);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.height_request = 200;
        main_box.width_request = 200;
        main_box.valign = Gtk.Align.START;
        main_box.halign = Gtk.Align.START;
        main_box.get_style_context ().add_class (Granite.STYLE_CLASS_CARD);
        main_box.get_style_context ().add_class ("planner-card-radius");

        main_box.pack_start (title_entry, false, false, 0);
        main_box.pack_start (source_view, true, true, 0);
        main_box.pack_end (action_box, false, false, 0);

        add (main_box);
    }
}
