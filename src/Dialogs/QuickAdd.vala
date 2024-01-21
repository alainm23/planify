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
    public Objects.Item item { get; construct; }
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
        quick_add_widget.add_item_db.connect ((add_item_db));
    }

    private void add_item_db (Objects.Item item) {
        if (item.parent_id != "") {
			Services.Database.get_default ().get_item (item.parent_id).add_item_if_not_exists (item);
            quick_add_widget.added_successfully ();
			return;
		}

        if (item.section_id != "") {
			Services.Database.get_default ().get_section (item.section_id).add_item_if_not_exists (item);
		} else {
			Services.Database.get_default ().get_project (item.project_id).add_item_if_not_exists (item);
		}

        Services.EventBus.get_default ().update_section_sort_func (item.project_id, item.section_id, false);
        quick_add_widget.added_successfully ();
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
        quick_add_widget.for_project (project);
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

    public void for_base_object (Objects.BaseObject base_object) {
        if (base_object is Objects.Project) {
            quick_add_widget.for_project (base_object as Objects.Project);
        } else if (base_object is Objects.Section) {
            quick_add_widget.for_section (base_object as Objects.Section);
        } else if (base_object is Objects.Item) {
            quick_add_widget.for_parent (base_object as Objects.Item);
        }
    }

    public void set_index (int index) {
        quick_add_widget.set_index (index);
    }
}
