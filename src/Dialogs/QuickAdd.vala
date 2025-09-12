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

    public int position {
        set {
            quick_add_widget.position = value;
        }

        get {
            return quick_add_widget.position;
        }
    }

    public QuickAdd () {
        Object (
            content_width: 550
        );
    }

    ~QuickAdd () {
        print ("Destroying Dialogs.QuickAdd\n");
    }

    construct {
        Services.EventBus.get_default ().disconnect_all_accels ();

        quick_add_widget = new Layouts.QuickAdd ();
        child = quick_add_widget;

        quick_add_widget.hide_destroy.connect (hide_destroy);
        quick_add_widget.add_item_db.connect ((add_item_db));
        quick_add_widget.parent_can_close.connect ((active) => {
            Timeout.add (250, () => {
                can_close = active;
                return GLib.Source.REMOVE;
            });
        });

        closed.connect (() => {
            Services.EventBus.get_default ().connect_all_accels ();
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
                item.add_reminder (reminder);
            }
        }

        if (Services.Settings.get_default ().get_boolean ("automatic-reminders-enabled") && item.has_time) {
            var reminder = new Objects.Reminder ();
            reminder.mm_offset = Util.get_reminders_mm_offset ();
            reminder.reminder_type = ReminderType.RELATIVE;
            item.add_reminder (reminder);
        }

        Services.EventBus.get_default ().update_section_sort_func (item.project_id, item.section_id, false);
        quick_add_widget.added_successfully ();
    }

    public void hide_destroy () {
        close ();
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

    public void set_labels (Gee.HashMap<string, Objects.Label> new_labels) {
        quick_add_widget.set_labels (new_labels);
    }

    public void set_new_task_position (NewTaskPosition value) {
        quick_add_widget.new_task_position = value;
    }
}
