/*
* Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
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

public class Layouts.ItemSidebarView : Adw.Bin {
    construct {
        var close_button = new Gtk.Button.from_icon_name ("window-close-symbolic");

        var headerbar = new Adw.HeaderBar () {
			title_widget = new Gtk.Label (null),
			hexpand = true,
            decoration_layout = ":",
			css_classes = { "flat" }
		};

        headerbar.pack_end (close_button);

        var content_textview = new Widgets.TextView () {
            left_margin = 6,
            right_margin = 6,
            top_margin = 6,
            bottom_margin = 6,
            height_request = 128
        };
        content_textview.wrap_mode = Gtk.WrapMode.WORD;
        //  content_textview.buffer.text = item.content;
        //  content_textview.editable = !item.completed && !item.project.is_deck;
        content_textview.remove_css_class ("view");
        content_textview.add_css_class ("card");

        var content_group = new Adw.PreferencesGroup () {
            margin_start = 12,
            margin_end = 12
        };
		content_group.title = _("Title");
        content_group.add (content_textview);

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.START,
            margin_bottom = 24
        };

        content.append (headerbar);
        content.append (content_group);
        
        child = content;

        close_button.clicked.connect (() => {
            Services.EventBus.get_default ().close_item ();
        });
    }
}
