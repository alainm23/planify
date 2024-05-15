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

public class Dialogs.ManageProjects : Adw.Dialog {
    private Gtk.ListBox listbox;
    private Widgets.ScrolledWindow scrolled_window;

    public ManageProjects () {
        Object (
            title: _("Archived Projects"),
            content_width: 320,
            content_height: 420
        );
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class ("flat");

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

        child = toolbar_view;
        Services.EventBus.get_default ().disconnect_typing_accel ();

        foreach (Objects.Project project in Services.Database.get_default ().get_all_projects_archived ()) {
            if (project.is_archived) {
                listbox.append (new Dialogs.ProjectPicker.ProjectPickerRow (project, "menu"));
            }
        }

        Services.Database.get_default ().project_unarchived.connect (() => {
            if (Services.Database.get_default ().get_all_projects_archived ().size <= 0) {
                hide_destroy ();
            }
        });

        var destroy_controller = new Gtk.EventControllerKey ();
        add_controller (destroy_controller);
        destroy_controller.key_released.connect ((keyval, keycode, state) => {
            if (keyval == 65307) {
                hide_destroy ();
            }
        });

        closed.connect (() => {
            Services.EventBus.get_default ().connect_typing_accel ();
        });
    }

    private void hide_destroy () {
        close ();
    }
}
