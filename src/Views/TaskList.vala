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

public class Views.TaskList : Gtk.EventBox {
    public E.Source? source { get; set; }
    private ECal.ClientView view;
    
    private Gtk.Label name_label;
    private Widgets.Entry name_entry;
    private Gtk.Stack name_stack;
    private Gtk.Revealer action_revealer;
    private Gtk.ListBox listbox;
    private Gtk.ToggleButton settings_button;

    private bool entry_menu_opened = false;

    construct {
        name_label = new Gtk.Label (null);
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("title-label");
        name_label.get_style_context ().add_class ("font-bold");

        var name_eventbox = new Gtk.EventBox ();
        name_eventbox.valign = Gtk.Align.START;
        name_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        name_eventbox.hexpand = true;
        name_eventbox.add (name_label);

        name_entry = new Widgets.Entry ();
        name_entry.get_style_context ().add_class ("font-bold");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("title-label");
        name_entry.get_style_context ().add_class ("project-name-entry");
        name_entry.hexpand = true;

        name_stack = new Gtk.Stack ();
        name_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        name_stack.add_named (name_eventbox, "name_label");
        name_stack.add_named (name_entry, "name_entry");

        var submit_button = new Gtk.Button.with_label (_("Save"));
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("planner-button");

        var action_grid = new Gtk.Grid ();
        action_grid.halign = Gtk.Align.START;
        action_grid.margin_top = 6;
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 6;
        action_grid.margin_start = 42;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        action_revealer = new Gtk.Revealer ();
        action_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        action_revealer.add (action_grid);

        var settings_image = new Gtk.Image ();
        settings_image.gicon = new ThemedIcon ("view-more-symbolic");
        settings_image.pixel_size = 14;

        settings_button = new Gtk.ToggleButton ();
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.can_focus = false;
        settings_button.tooltip_text = _("Project Menu");
        settings_button.image = settings_image;
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_end = 36;
        top_box.margin_start = 42;
        top_box.margin_top = 6;

        top_box.pack_start (name_stack, false, true, 0);
        top_box.pack_end (settings_button, false, false, 0);

        listbox = new Gtk.ListBox ();
        listbox.margin_start = 30;
        listbox.margin_top = 12;
        listbox.margin_end = 32;
        listbox.valign = Gtk.Align.START;
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        var magic_button = new Widgets.MagicButton ();

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (action_revealer, false, false, 0);
        main_box.pack_start (listbox, false, false, 0);

        var overlay = new Gtk.Overlay ();
        overlay.expand = true;
        overlay.add_overlay (magic_button);
        overlay.add (main_box);

        add (overlay);

        notify["source"].connect (() => {
            if (view != null) {
                Planner.task_store.destroy_task_list_view (view);
            }
            foreach (unowned Gtk.Widget child in listbox.get_children ()) {
                child.destroy ();
            }

            if (source != null) {
                update_request ();

                try {
                    view = Planner.task_store.create_task_list_view (
                        source,
                        "(contains? 'any' '')",
                        on_tasks_added,
                        on_tasks_modified,
                        on_tasks_removed
                    );

                } catch (Error e) {
                    print (e.message);
                    critical (e.message);
                }

            } else {
                
            }

            show_all ();
        });

        listbox.row_activated.connect ((r) => {
            var row = ((Widgets.TaskRow) r);
            row.reveal_child = true;
        });

        cancel_button.clicked.connect (() => {
            action_revealer.reveal_child = false;
            name_stack.visible_child_name = "name_label";
            name_entry.text = source.display_name;
        });
        
        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                action_revealer.reveal_child = false;
                name_stack.visible_child_name = "name_label";
                name_entry.text = source.display_name;
            }

            return false;
        });

        name_entry.focus_out_event.connect (() => {
            if (entry_menu_opened == false) {
                save ();
            }
        });

        name_entry.populate_popup.connect ((menu) => {
            entry_menu_opened = true;
            menu.hide.connect (() => {
                entry_menu_opened = false;
            });
        });

        name_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                action_revealer.reveal_child = true;
                name_stack.visible_child_name = "name_entry";

                name_entry.grab_focus_without_selecting ();
                if (name_entry.cursor_position < name_entry.text_length) {
                    name_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) name_entry.text_length, false);
                }
            }

            return false;
        });

        name_entry.changed.connect (() => {
            if (name_entry.text.strip () != "" && source.display_name != name_entry.text) {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }
        });

        submit_button.clicked.connect (() => {
            save ();
        });

        name_entry.activate.connect (() => {
            save ();
        });
    }

    private void save () {
        if (source != null) {
            source.display_name = name_entry.text;
            
            name_label.label = name_entry.text;
            action_revealer.reveal_child = false;
            name_stack.visible_child_name = "name_label";

            source.write.begin (null);
        }
    }

    private void on_tasks_added (Gee.Collection<ECal.Component> tasks) {
        tasks.foreach ((task) => {
            var row = new Widgets.TaskRow (task, source);
            //  var task_row = new Tasks.TaskRow.for_component (task, source);
            row.task_completed.connect ((task) => {
                Planner.task_store.complete_task (source, task);
            });
            row.task_changed.connect ((task) => {
                Planner.task_store.update_task (source, task, ECal.ObjModType.THIS_AND_FUTURE);
            });
            //  task_row.task_removed.connect ((task) => {
            //      Tasks.Application.model.remove_task (source, task, ECal.ObjModType.ALL);
            //  });
            listbox.add (row);
            return true;
        });
        listbox.show_all ();
    }

    private void on_tasks_modified (Gee.Collection<ECal.Component> tasks) {
        Widgets.TaskRow task_row = null;
        var row_index = 0;

        do {
            task_row = (Widgets.TaskRow) listbox.get_row_at_index (row_index);

            if (task_row != null) {
                foreach (ECal.Component task in tasks) {
                    if (Util.calcomponent_equal_func (task_row.task, task)) {
                        task_row.task = task;
                        break;
                    }
                }
            }
            row_index++;
        } while (task_row != null);
    }

    private void on_tasks_removed (SList<ECal.ComponentId?> cids) {
        //  unowned Tasks.TaskRow? task_row = null;
        //  var row_index = 0;
        //  do {
        //      task_row = (Tasks.TaskRow) task_list.get_row_at_index (row_index);

        //      if (task_row != null) {
        //          foreach (unowned ECal.ComponentId cid in cids) {
        //              if (cid == null) {
        //                  continue;
        //              } else if (cid.get_uid () == task_row.task.get_icalcomponent ().get_uid ()) {
        //                  task_list.remove (task_row);
        //                  break;
        //              }
        //          }
        //      }
        //      row_index++;
        //  } while (task_row != null);
    }

    public void update_request () {
        name_label.label = source.dup_display_name ();
        name_entry.text = source.dup_display_name ();

        listbox.@foreach ((row) => {
            if (row is Widgets.TaskRow) {
                (row as Widgets.TaskRow).update_request ();
            }
        });
    }
}
