/*
* Copyright 2020 elementary, Inc. (https://elementary.io)
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
*/


errordomain TaskModelError {
    CLIENT_NOT_AVAILABLE
}

public class Services.Tasks.Store : Object {
    public signal void task_list_added (E.Source task_list);
    public signal void task_list_modified (E.Source task_list);
    public signal void task_list_removed (E.Source task_list);

    public delegate void TasksAddedFunc (Gee.Collection<ECal.Component> tasks, E.Source task_list);
    public delegate void TasksModifiedFunc (Gee.Collection<ECal.Component> tasks);
    public delegate void TasksRemovedFunc (SList<weak ECal.ComponentId?> cids);

    private Gee.Future<E.SourceRegistry> registry;
    private HashTable<string, ECal.Client> task_list_client;
    private HashTable<ECal.Client, Gee.Collection<ECal.ClientView>> task_list_client_views;

    public async E.SourceRegistry get_registry () throws Error {
        return yield registry.wait_async ();
    }

    public E.SourceRegistry get_registry_sync () throws Error {
        if (!registry.ready) {
            debug ("Blocking until registry is loaded…");
            registry.wait ();
        }
        return registry.value;
    }

    private ECal.Client get_client (E.Source task_list) throws Error {
        ECal.Client client;
        lock (task_list_client) {
            client = task_list_client.get (task_list.dup_uid ());
        }

        if (client == null) {
            throw new TaskModelError.CLIENT_NOT_AVAILABLE ("No client available for task list '%s'".printf (task_list.dup_display_name ()));  // vala-lint=line-length
        }

        return client;
    }

    private void create_task_list_client (E.Source task_list) {
        try {
            var client = (ECal.Client) ECal.Client.connect_sync (task_list, ECal.ClientSourceType.TASKS, -1, null);
            lock (task_list_client) {
                task_list_client.insert (task_list.dup_uid (), client);
            }

        } catch (Error e) {
            critical (e.message);
        }
    }

    private void destroy_task_list_client (E.Source task_list, ECal.Client client) {
        var views = get_views (client);
        foreach (var view in views) {
            try {
                view.stop ();
            } catch (Error e) {
                warning (e.message);
            }
        }

        lock (task_list_client_views) {
            task_list_client_views.remove (client);
        }

        lock (task_list_client) {
            task_list_client.remove (task_list.dup_uid ());
        }
    }

    private Gee.Collection<ECal.ClientView> get_views (ECal.Client client) {
        Gee.Collection<ECal.ClientView> views;
        lock (task_list_client_views) {
            views = task_list_client_views.get (client);
        }
        if (views == null) {
            views = new Gee.ArrayList<ECal.ClientView> ((Gee.EqualDataFunc<ECal.ClientView>?) direct_equal);
        }
        return views.read_only_view;
    }

    construct {
        var promise = new Gee.Promise<E.SourceRegistry> ();
        registry = promise.future;
        init_registry.begin (promise);

        task_list_client = new HashTable<string, ECal.Client> (str_hash, str_equal);
        task_list_client_views = new HashTable<ECal.Client, Gee.Collection<ECal.ClientView>> (direct_hash, direct_equal);  // vala-lint=line-length
    }

    private async void init_registry (Gee.Promise<E.SourceRegistry> promise) {
        try {
            var registry = yield new E.SourceRegistry (null);

            registry.source_added.connect ((task_list) => {
                add_task_list (task_list);
                task_list_added (task_list);
            });

            registry.source_changed.connect ((task_list) => {
                task_list_modified (task_list);
            });

            registry.source_removed.connect ((task_list) => {
                remove_task_list (task_list);
                task_list_removed (task_list);
            });

            registry.list_sources (E.SOURCE_EXTENSION_TASK_LIST).foreach ((task_list) => {
                E.SourceTaskList task_list_extension = (E.SourceTaskList)task_list.get_extension (E.SOURCE_EXTENSION_TASK_LIST);  // vala-lint=line-length
                if (task_list_extension.selected == true && task_list.enabled == true) {
                    add_task_list (task_list);
                }
            });

            promise.set_value (registry);

        } catch (Error e) {
            critical (e.message);
            promise.set_exception (e);
        }
    }

    private void add_task_list (E.Source task_list) {
        debug ("Adding task list '%s'", task_list.dup_display_name ());
        create_task_list_client (task_list);
    }

    private void remove_task_list (E.Source task_list) {
        debug ("Removing task list '%s'", task_list.dup_display_name ());

        ECal.Client client;
        try {
            client = get_client (task_list);
        } catch (Error e) {
            /* Already out of the model, so do nothing */
            warning (e.message);
            return;
        }

        destroy_task_list_client (task_list, client);
    }

    public void add_task (E.Source list, ECal.Component task, Widgets.NewItem new_task) {
        add_task_async.begin (list, task, new_task);
    }

    private async void add_task_async (E.Source list, ECal.Component task, Widgets.NewItem new_task) {
        ECal.Client client;
        try {
            client = get_client (list);
        } catch (Error e) {
            new_task.loading = false;

            // Send Notification Error
            critical (e.message);
            return;
        }

        unowned ICal.Component comp = task.get_icalcomponent ();
        debug (@"Adding task '$(comp.get_uid())'");

        try {
            string? uid;
#if E_CAL_2_0
            yield client.create_object (comp, ECal.OperationFlags.NONE, null, out uid);
#else
            yield client.create_object (comp, null, out uid);
#endif
            if (uid != null) {
                comp.set_uid (uid);
            }
            
            //  var row = new Widgets.NewItem.for_source (new_task.source, new_task.listbox);
            //  new_task.listbox.add (row);
            //  new_task.listbox.show_all ();

            new_task.hide_destroy ();
        } catch (GLib.Error error) {
            new_task.loading = false;

            // Send Notification Error
            critical (error.message);
        }
    }

    public void complete_task (E.Source list, ECal.Component task) {
        ECal.Client client;
        try {
            client = get_client (list);
        } catch (Error e) {
            critical (e.message);
            return;
        }

        unowned ICal.Component comp = task.get_icalcomponent ();
        var was_completed = comp.get_status () == ICal.PropertyStatus.COMPLETED;

        if (was_completed) {
            debug (@"Reopen $(task.is_instance() ? "instance" : "task") '$(comp.get_uid())'");

            comp.set_status (ICal.PropertyStatus.NONE);
            task.set_percent_complete (0);

#if E_CAL_2_0
            task.set_completed (new ICal.Time.null_time ());
#else
            var null_time = ICal.Time.null_time ();
            task.set_completed (ref null_time);
#endif

            update_icalcomponent (client, comp, ECal.ObjModType.ONLY_THIS);

        } else {
            debug (@"Completing $(task.is_instance() ? "instance" : "task") '$(comp.get_uid())'");

            comp.set_status (ICal.PropertyStatus.COMPLETED);
            task.set_percent_complete (100);

#if E_CAL_2_0
            task.set_completed (new ICal.Time.today ());
#else
            var today_time = ICal.Time.today ();
            task.set_completed (ref today_time);
#endif

            update_icalcomponent (client, comp, ECal.ObjModType.THIS_AND_PRIOR);
        }

//          if (task.has_recurrences () && !was_completed) {
//  #if E_CAL_2_0
//              var duration = new ICal.Duration.null_duration ();
//              duration.set_weeks (520); // roughly 10 years
//              var today = new ICal.Time.today ();
//  #else
//              var duration = ICal.Duration.null_duration ();
//              duration.weeks = 520; // roughly 10 years
//              var today = ICal.Time.today ();
//  #endif

//              var start = comp.get_dtstart ();
//              if (today.compare (start) > 0) {
//                  start = today;
//              }
//              var end = start.add (duration);

//  #if E_CAL_2_0
//              ECal.RecurInstanceCb recur_instance_callback = (instance_comp, instance_start_timet, instance_end_timet, cancellable) => {
//  #else
//              ECal.RecurInstanceFn recur_instance_callback = (instance, instance_start_timet, instance_end_timet) => {
//  #endif

//  #if E_CAL_2_0
//                  var instance = new ECal.Component ();
//                  instance.set_icalcomponent (instance_comp);
//  #else
//                  unowned ICal.Component instance_comp = instance.get_icalcomponent ();
//  #endif

//                  if (!instance_comp.get_due ().is_null_time ()) {
//                      instance_comp.set_due (instance_comp.get_dtstart ());
//                  }

//                  instance_comp.set_status (ICal.PropertyStatus.NONE);
//                  instance.set_percent_complete (0);

//  #if E_CAL_2_0
//                  instance.set_completed (new ICal.Time.null_time ());
//  #else
//                  var null_time = ICal.Time.null_time ();
//                  instance.set_completed (ref null_time);
//  #endif

//                  if (instance.has_alarms ()) {
//                      instance.get_alarm_uids ().@foreach ((alarm_uid) => {
//                          ECal.ComponentAlarmTrigger trigger;
//  #if E_CAL_2_0
//                          trigger = new ECal.ComponentAlarmTrigger.relative (ECal.ComponentAlarmTriggerKind.RELATIVE_START, new ICal.Duration.null_duration ());
//  #else
//                          trigger = ECal.ComponentAlarmTrigger () {
//                              type = ECal.ComponentAlarmTriggerKind.RELATIVE_START,
//                              rel_duration = ICal.Duration.null_duration ()
//                          };
//  #endif
//                          instance.get_alarm (alarm_uid).set_trigger (trigger);
//                      });
//                  }

//                  update_icalcomponent (client, instance_comp, ECal.ObjModType.THIS_AND_FUTURE);
//                  return false; // only generate one instance
//              };

//  #if E_CAL_2_0
//              client.generate_instances_for_object_sync (comp, start.as_timet (), end.as_timet (), null, recur_instance_callback);
//  #else
//              client.generate_instances_for_object_sync (comp, start.as_timet (), end.as_timet (), recur_instance_callback);
//  #endif
//          }
    }

    public void update_task (E.Source list, ECal.Component task, ECal.ObjModType mod_type) {
        ECal.Client client;
        try {
            client = get_client (list);
        } catch (Error e) {
            critical (e.message);
            return;
        }

        unowned ICal.Component comp = task.get_icalcomponent ();
        debug (@"Updating task '$(comp.get_uid())' [mod_type=$(mod_type)]");
        update_icalcomponent (client, comp, mod_type);
    }

    private void update_icalcomponent (ECal.Client client, ICal.Component comp, ECal.ObjModType mod_type) {
        client.modify_object.begin (comp, mod_type, null, (obj, res) => {
            try {
                client.modify_object.end (res);
            } catch (Error e) {
                warning (e.message);
            }
        });
//          try {
//  #if E_CAL_2_0
//              client.modify_object_sync (comp, mod_type, ECal.OperationFlags.NONE, null);
//  #else
//              client.modify_object_sync (comp, mod_type, null);
//  #endif
//          } catch (Error e) {
//              warning (e.message);
//              return;
//          }

//          if (comp.get_uid () == null) {
//              return;
//          }

//          try {
//              SList<ECal.Component> ecal_tasks;
//              client.get_objects_for_uid_sync (comp.get_uid (), out ecal_tasks, null);

//  #if E_CAL_2_0
//              var ical_tasks = new SList<ICal.Component> ();
//  #else
//              var ical_tasks = new SList<unowned ICal.Component> ();
//  #endif
//              foreach (unowned ECal.Component ecal_task in ecal_tasks) {
//                  ical_tasks.append (ecal_task.get_icalcomponent ());
//              }

//          } catch (Error e) {
//              warning (e.message);
//          }
    }

    public void remove_task (E.Source list, ECal.Component task, ECal.ObjModType mod_type) {
        ECal.Client client;
        try {
            client = get_client (list);
        } catch (Error e) {
            critical (e.message);
            return;
        }

        unowned ICal.Component comp = task.get_icalcomponent ();
        string uid = comp.get_uid ();
        string? rid = task.has_recurrences () ? null : task.get_recurid_as_string ();
        debug (@"Removing task '$uid'");

#if E_CAL_2_0
        client.remove_object.begin (uid, rid, mod_type, ECal.OperationFlags.NONE, null, (obj, results) => {
#else
        client.remove_object.begin (uid, rid, mod_type, null, (obj, results) => {
#endif
            try {
                client.remove_object.end (results);
            } catch (Error e) {
                warning (e.message);
            }
        });
    }

    private void debug_task (E.Source task_list, ECal.Component task) {
        unowned ICal.Component comp = task.get_icalcomponent ();
        var task_summary = comp.get_summary ();
        var task_uid = comp.get_uid ();
        var task_list_display_name = task_list.dup_display_name ();

        if (task_summary == null)
            task_summary = "";

        if (task_uid == null)
            task_uid = "";

        if (task_list_display_name == null)
            task_list_display_name = "";

        debug (@"Task ['$(task_summary)', $(task_list_display_name), $(task_uid)))]");
    }

    public ECal.ClientView create_task_list_view (E.Source task_list, string query, TasksAddedFunc on_tasks_added, TasksModifiedFunc on_tasks_modified, TasksRemovedFunc on_tasks_removed) throws Error { // vala-lint=line-length
        ECal.Client client = get_client (task_list);
        debug ("Getting view for task list '%s'", task_list.dup_display_name ());

        ECal.ClientView view;
        client.get_view_sync (query, out view, null);

        view.objects_added.connect ((objects) => on_objects_added (task_list, client, objects, on_tasks_added));
        view.objects_removed.connect ((objects) => on_objects_removed (task_list, client, objects, on_tasks_removed));
        view.objects_modified.connect ((objects) => on_objects_modified (task_list, client, objects, on_tasks_modified));  // vala-lint=line-length
        view.start ();

        lock (task_list_client_views) {
            var views = task_list_client_views.get (client);

            if (views == null) {
                views = new Gee.ArrayList<ECal.ClientView> ((Gee.EqualDataFunc<ECal.ClientView>?) direct_equal);
            }
            views.add (view);

            task_list_client_views.set (client, views);
        }

        return view;
    }

    public void destroy_task_list_view (ECal.ClientView view) {
        try {
            view.stop ();
        } catch (Error e) {
            warning (e.message);
        }

        lock (task_list_client_views) {
            unowned Gee.Collection<ECal.ClientView> views = task_list_client_views.get (view.client);

            if (views != null) {
                views.remove (view);
            }
        }
    }

#if E_CAL_2_0
    private void on_objects_added (E.Source task_list, ECal.Client client, SList<ICal.Component> objects, TasksAddedFunc on_tasks_added) {  // vala-lint=line-length
#else
    private void on_objects_added (E.Source task_list, ECal.Client client, SList<weak ICal.Component> objects, TasksAddedFunc on_tasks_added) {  // vala-lint=line-length
#endif
        debug (@"Received $(objects.length()) added task(s) for task list '%s'", task_list.dup_display_name ());
        var added_tasks = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);  // vala-lint=line-length
        objects.foreach ((ical_comp) => {
            try {
                SList<ECal.Component> ecal_tasks;
                client.get_objects_for_uid_sync (ical_comp.get_uid (), out ecal_tasks, null);

                ecal_tasks.foreach ((task) => {
                    debug_task (task_list, task);

                    if (!added_tasks.contains (task)) {
                        added_tasks.add (task);
                    }
                });

            } catch (Error e) {
                warning (e.message);
            }
        });

        on_tasks_added (added_tasks.read_only_view, task_list);
    }

#if E_CAL_2_0
    private void on_objects_modified (E.Source task_list, ECal.Client client, SList<ICal.Component> objects, TasksModifiedFunc on_tasks_modified) {  // vala-lint=line-length
#else
    private void on_objects_modified (E.Source task_list, ECal.Client client, SList<weak ICal.Component> objects, TasksModifiedFunc on_tasks_modified) {  // vala-lint=line-length
#endif
        debug (@"Received $(objects.length()) modified task(s) for task list '%s'", task_list.dup_display_name ());
        var updated_tasks = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) Util.calcomponent_equal_func);  // vala-lint=line-length
        objects.foreach ((comp) => {
            try {
                SList<ECal.Component> ecal_tasks;
                client.get_objects_for_uid_sync (comp.get_uid (), out ecal_tasks, null);

                ecal_tasks.foreach ((task) => {
                    debug_task (task_list, task);
                    if (!updated_tasks.contains (task)) {
                        updated_tasks.add (task);
                    }
                });

            } catch (Error e) {
                warning (e.message);
            }
        });

        on_tasks_modified (updated_tasks.read_only_view);
    }

#if E_CAL_2_0
    private void on_objects_removed (E.Source task_list, ECal.Client client, SList<ECal.ComponentId?> cids, TasksRemovedFunc on_tasks_removed) {  // vala-lint=line-length
#else
    private void on_objects_removed (E.Source task_list, ECal.Client client, SList<weak ECal.ComponentId?> cids, TasksRemovedFunc on_tasks_removed) {  // vala-lint=line-length
#endif
        debug (@"Received $(cids.length()) removed task(s) for task list '%s'", task_list.dup_display_name ());

        on_tasks_removed (cids);
    }
}
