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
    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();

    public ManageProjects () {
        Object (
            title: _("Archived Projects"),
            content_width: 320,
            content_height: 420
        );
    }

    ~ManageProjects () {
        debug ("Destroying - Dialogs.ManageProjects\n");
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

        foreach (Objects.Project project in Services.Store.instance ().get_all_projects_archived ()) {
            if (project.is_archived) {
                listbox.append (new Widgets.ProjectItemRow (project, "menu"));
            }
        }

        signal_map[Services.Store.instance ().project_unarchived.connect (() => {
            if (Services.Store.instance ().get_all_projects_archived ().size <= 0) {
                close ();
            }
        })] = Services.Store.instance ();

        closed.connect (() => {
            clean_up ();
            Services.EventBus.get_default ().connect_typing_accel ();
        });
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox)) {
            ((Widgets.ProjectItemRow) child).clean_up ();
        }
    }
}
