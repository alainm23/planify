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

public class Widgets.SourceRow : Gtk.ListBoxRow {
    public Objects.Source source { get; construct; }
    
    private Gtk.Revealer main_revealer;

    public signal void view_detail ();

    public SourceRow (Objects.Source source) {
        Object (
            source: source
        );
    }

    construct {
        add_css_class ("no-selectable");
        
        var visible_checkbutton = new Gtk.CheckButton () {
            active = source.is_visible
        };

        var header_label = new Gtk.Label (source.header_text);

        var subheader_label = new Gtk.Label (source.subheader_text) {
            halign = Gtk.Align.START,
            css_classes = { "caption", "dim-label" },
            visible = source.source_type != SourceType.LOCAL
        };

        var header_label_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.CENTER
        };
        header_label_box.append (header_label);
        header_label_box.append (subheader_label);

        var setting_button = new Gtk.Button.from_icon_name ("settings-symbolic") {
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			css_classes = { "flat" },
            visible = source.source_type != SourceType.LOCAL
		};

        var renove_item = new Widgets.ContextMenu.MenuItem (_("Remove"), "user-trash-symbolic");

		var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		menu_box.margin_top = menu_box.margin_bottom = 3;
		menu_box.append (renove_item);

		var popover = new Gtk.Popover () {
			has_arrow = true,
			child = menu_box,
			width_request = 250,
			position = Gtk.PositionType.BOTTOM
		};

		var menu_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
			icon_name = "view-more-symbolic",
            css_classes = { "flat", "dim-label" },
            tooltip_markup = _("Add Source"),
			popover = popover,
            visible = source.source_type != SourceType.LOCAL
        };

        var end_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            halign = END
        };
        end_box.append (setting_button);
        end_box.append (menu_button);

		var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6
        };
        
        content_box.append (visible_checkbutton);
        content_box.append (header_label_box);
        content_box.append (end_box);

        var card = new Adw.Bin () {
            child = content_box,
            margin_top = 3,
            margin_bottom = 3,
            margin_start = 3,
            margin_end = 3
        };

		main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			child = card
        };

		child = main_revealer;

		Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        visible_checkbutton.toggled.connect (() => {
            source.is_visible = visible_checkbutton.active;
            source.save ();
        });

        setting_button.clicked.connect (() => {
            view_detail ();
        });

        renove_item.clicked.connect (() => {
            popover.popdown ();
            source.delete_source (Planify._instance.main_window);
        });
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }
}