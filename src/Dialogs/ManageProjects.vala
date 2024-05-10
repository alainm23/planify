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

public class Dialogs.ManageProjects : Adw.Window {
    private Gtk.ListBox listbox;
    private Widgets.ScrolledWindow scrolled_window;

    public ManageProjects () {
        Object (
            deletable: true,
            resizable: true,
            modal: true,
            title: _("Archived Projects"),
            width_request: 320,
            height_request: 420,
            transient_for: (Gtk.Window) Planify.instance.main_window
        );
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);

        listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = START,
            css_classes = { "listbox-background" }
        };

        var listbox_card = new Adw.Bin () {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 6,
            margin_top = 3,
            css_classes = { "card" },
            child = listbox,
            valign = START
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.append (listbox_card);

        scrolled_window = new Widgets.ScrolledWindow (content_box);

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (headerbar);
		toolbar_view.content = scrolled_window;

        content = toolbar_view;

        foreach (Objects.Project project in Services.Database.get_default ().projects) {
            if (project.is_archived) {
                listbox.append (new Dialogs.ProjectPicker.ProjectPickerRow (project, "menu"));
            }
        }
    }
}