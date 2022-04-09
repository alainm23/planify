public class Objects.Scheduled : Objects.BaseObject {
    private static Scheduled? _instance;
    public static Scheduled get_default () {
        if (_instance == null) {
            _instance = new Scheduled ();
        }

        return _instance;
    }

    int? _scheduled_count = null;
    public int scheduled_count {
        get {
            if (_scheduled_count == null) {
                _scheduled_count = Planner.database.get_items_by_scheduled (false).size;
            }

            return _scheduled_count;
        }

        set {
            _scheduled_count = value;
        }
    }

    public signal void scheduled_count_updated ();

    private Gee.Map<E.Source, ECal.ClientView> views;
    private Gee.HashMap<string, ECal.Component> items_added;

    construct {
        name = _("Scheduled");

        BackendType backend_type = (BackendType) Planner.settings.get_enum ("backend-type");

        if (backend_type == BackendType.LOCAL || backend_type == BackendType.TODOIST) {
            Planner.database.item_added.connect (() => {
                _scheduled_count = Planner.database.get_items_by_scheduled (false).size;
                scheduled_count_updated ();
            });
    
            Planner.database.item_deleted.connect (() => {
                _scheduled_count = Planner.database.get_items_by_scheduled (false).size;
                scheduled_count_updated ();
            });
    
            Planner.database.item_updated.connect (() => {
                _scheduled_count = Planner.database.get_items_by_scheduled (false).size;
                scheduled_count_updated ();
            });
        } else if (backend_type == BackendType.CALDAV) {
            try {
                var registry = Services.CalDAV.get_default ().get_registry_sync ();
                items_added = new Gee.HashMap<string, ECal.Component> ();

                var sources = registry.list_sources (E.SOURCE_EXTENSION_TASK_LIST);
                sources.foreach ((source) => {
                    add_task_list (source);
                });

                Timeout.add (225, () => {
                    _scheduled_count = get_caldav_count ();
                    scheduled_count_updated ();
                    return GLib.Source.REMOVE;
                });
            } catch (Error e) {
                warning (e.message);
            }
        }
    }

    private void add_task_list (E.Source task_list) {
        if (!task_list.has_extension (E.SOURCE_EXTENSION_TASK_LIST)) {
            return;
        }

        E.SourceTaskList list = (E.SourceTaskList) task_list.get_extension (E.SOURCE_EXTENSION_TASK_LIST);

        if (list.selected == true && task_list.enabled == true && !task_list.has_extension (E.SOURCE_EXTENSION_COLLECTION)) {
            add_view (task_list, "AND (NOT is-completed?) (has-start?)");
        }
    }

    private void add_view (E.Source source, string query) {
        try {
            var view = Services.CalDAV.get_default ().create_task_list_view (
                source,
                query,
                on_tasks_added,
                on_tasks_modified,
                on_tasks_removed
            );

            lock (views) {
                views.set (source, view);
            }

        } catch (Error e) {
            critical (e.message);
        }
    }

    private void on_tasks_added (Gee.Collection<ECal.Component> tasks) {
        foreach (ECal.Component task in tasks) {
            items_added[task.get_icalcomponent ().get_uid ()] = task;
        }

        _scheduled_count = get_caldav_count ();
        scheduled_count_updated ();
    }

    private void on_tasks_modified (Gee.Collection<ECal.Component> tasks) {
        foreach (ECal.Component task in tasks) {
            items_added[task.get_icalcomponent ().get_uid ()] = task;
        }
        
        _scheduled_count = get_caldav_count ();
        scheduled_count_updated ();
    }

    private void on_tasks_removed (SList<ECal.ComponentId?> cids) {
        foreach (unowned ECal.ComponentId cid in cids) {
            if (cid == null) {
                continue;
            } else {
                items_added.unset (cid.get_uid ());
            }
        }

        _scheduled_count = get_caldav_count ();
        scheduled_count_updated ();
    }

    private int get_caldav_count () {
        int returned = 0;

        foreach (ECal.Component task in items_added.values) {
            if (!task.get_icalcomponent ().get_due ().is_null_time ()) {
                GLib.DateTime datetime = CalDAVUtil.ical_to_date_time_local (
                    task.get_icalcomponent ().get_due ()
                );
    
                if (task.get_icalcomponent ().get_status () != ICal.PropertyStatus.COMPLETED &&
                    datetime.compare (new GLib.DateTime.now_local ()) > 0) {
                    returned++;
                }
            }
        }

        return returned;
    }
}
