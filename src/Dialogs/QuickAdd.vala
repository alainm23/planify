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

public class Dialogs.QuickAdd : Adw.Dialog {
    public Objects.Item item { get; construct; }
    private Layouts.QuickAdd quick_add_widget;

    construct {
        Services.EventBus.get_default ().disconnect_typing_accel ();

        quick_add_widget = new Layouts.QuickAdd ();
        child = quick_add_widget;

        quick_add_widget.hide_destroy.connect (hide_destroy);
        quick_add_widget.add_item_db.connect ((add_item_db));

        closed.connect (() => {
            Services.EventBus.get_default ().connect_typing_accel ();
        });
    }

    private void add_item_db (Objects.Item item, Gee.ArrayList<Objects.Reminder> reminders) {
        if (item.has_parent) {
			item.parent.add_item_if_not_exists (item);
		} else {
            if (item.section_id != "") {
                item.section.add_item_if_not_exists (item);
            } else {
                item.project.add_item_if_not_exists (item);
            }
        }

        if (reminders.size > 0) {
            quick_add_widget.is_loading = true;

            foreach (Objects.Reminder reminder in reminders) {
                reminder.item_id = item.id;

                if (item.project.backend_type == BackendType.TODOIST) {
                    Services.Todoist.get_default ().add.begin (reminder, (obj, res) => {
                        HttpResponse response = Services.Todoist.get_default ().add.end (res);
                        item.loading = false;
    
                        if (response.status) {
                            reminder.id = response.data;
                        } else {
                            reminder.id = Util.get_default ().generate_id (reminder);
                        }
    
                        item.add_reminder_if_not_exists (reminder);
                    });
                } else {
                    reminder.id = Util.get_default ().generate_id (reminder);
                    item.add_reminder_if_not_exists (reminder);
                }
            }
        }
        
        Services.EventBus.get_default ().update_section_sort_func (item.project_id, item.section_id, false);
        quick_add_widget.added_successfully ();
    }

    public void hide_destroy () {
        force_close ();
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

    public void set_labels (Gee.HashMap<string, Objects.Label> new_labels) {
        quick_add_widget.set_labels (new_labels);
    }
}
