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

public class Dialogs.QuickAdd : Adw.Window {
    private Layouts.QuickAdd quick_add_widget;

	public QuickAdd () {
        Object (
            deletable: true,
            resizable: true,
            modal: true,
            transient_for: (Gtk.Window) Planify.instance.main_window,
            width_request: 600,
            halign: Gtk.Align.START
        );
    }

    construct {
        quick_add_widget = new Layouts.QuickAdd ();
        set_content (quick_add_widget);

        quick_add_widget.hide_destroy.connect (hide_destroy);
        quick_add_widget.send_interface_id.connect ((id) => {
            var item = Services.Database.get_default ().get_item_by_id (id);
			Services.Database.get_default ().add_item (item);
        });
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }

    public void update_content (string content = "") {
        quick_add_widget.update_content (content);
    }

    public void set_project (Objects.Project project) {
        quick_add_widget.set_project (project);
    }

    public void set_due (GLib.DateTime date) {
        quick_add_widget.set_due (date);
    }

    public void set_pinned (bool pinned) {
        quick_add_widget.set_pinned (pinned);
    }

    public void set_priority (int priority) {
        quick_add_widget.set_priority (priority);
    }
}