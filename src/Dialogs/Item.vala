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

public class Dialogs.Item : Adw.Window {
    public Objects.Item item { get; construct; }

    private Gtk.Label nav_label;
    private Layouts.ItemRow row;

    public Item (Objects.Item item) {
        Object (
            item: item,
            transient_for: (Gtk.Window) Planify.instance.main_window,
            destroy_with_parent: true,
            deletable: true,
            resizable: true,
            width_request: 500,
            modal: false
        );
    }

    construct {
        var view_headerbar = new Adw.HeaderBar () {
            title_widget = new Gtk.Label (null),
            hexpand = true
        };
        
        view_headerbar.add_css_class ("flat");

        nav_label = new Gtk.Label (null) {
            margin_start = 12,
            valign = CENTER
        };
        nav_label.add_css_class ("h4");

        view_headerbar.pack_start (nav_label);

        row = new Layouts.ItemRow.for_board (item) {
            margin_start = 12,
            margin_bottom = 12,
            vexpand = true
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true,
            vexpand = true
        };        
        content_box.append (view_headerbar);
        content_box.append (row);
        
        content = content_box;

        Timeout.add (225, () => {
            row.edit = true;
            update_request ();
            return GLib.Source.REMOVE;
        });

        Services.Database.get_default ().item_updated.connect ((_item, update_id) => {
            if (item.id == _item.id) {
                row.update_request ();
                update_request ();
            }
        });

        item.deleted.connect (() => {
            hide_destroy ();
        });
    }

    public void update_request () {
        string section_name = _("(No Section)");
        if (item.section_id != "") {
            section_name = item.section.name;
        }
        nav_label.label = "%s → %s".printf (item.project.short_name, section_name);
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}
