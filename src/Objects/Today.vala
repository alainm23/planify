public class Objects.Today : Objects.BaseObject {
    private static Today? _instance;
    public static Today get_default () {
        if (_instance == null) {
            _instance = new Today ();
        }

        return _instance;
    }

    int? _today_count = null;
    public int today_count {
        get {
            if (_today_count == null) {
                BackendType backend_type = (BackendType) Planner.settings.get_enum ("backend-type");
                
                if (backend_type == BackendType.LOCAL || backend_type == BackendType.TODOIST) {
                    _today_count = Planner.database.get_items_by_date (
                        new GLib.DateTime.now_local (), false).size;
                } else {
                    _today_count = get_caldav_today_count ();
                }
            }

            return _today_count;
        }

        set {
            _today_count = value;
        }
    }

    int? _overdeue_count = null;
    public int overdeue_count {
        get {
            if (_overdeue_count == null) {
                BackendType backend_type = (BackendType) Planner.settings.get_enum ("backend-type");
                
                if (backend_type == BackendType.LOCAL || backend_type == BackendType.TODOIST) {
                    _overdeue_count = Planner.database.get_items_by_overdeue_view (false).size;
                } else if (backend_type == BackendType.CALDAV) {
                    _overdeue_count = 0;
                }
            }

            return _overdeue_count;
        }

        set {
            _overdeue_count = value;
        }
    }

    public signal void today_count_updated ();

    private Gee.Map<E.Source, ECal.ClientView> views;
    private Gee.HashMap<string, ECal.Component> items_added;

    construct {
        views = new Gee.HashMap<E.Source, ECal.ClientView> ();
        name = _("Today");

        BackendType backend_type = (BackendType) Planner.settings.get_enum ("backend-type");

        if (backend_type == BackendType.LOCAL || backend_type == BackendType.TODOIST) {
            Planner.database.item_added.connect (() => {
                _today_count = Planner.database.get_items_by_date (
                    new GLib.DateTime.now_local (), false).size;
                _overdeue_count = Planner.database.get_items_by_overdeue_view (false).size;
                today_count_updated ();
            });
    
            Planner.database.item_deleted.connect (() => {
                _today_count = Planner.database.get_items_by_date (
                    new GLib.DateTime.now_local (), false).size;
                _overdeue_count = Planner.database.get_items_by_overdeue_view (false).size;
                today_count_updated ();
            });
    
            Planner.database.item_updated.connect (() => {
                _today_count = Planner.database.get_items_by_date (
                    new GLib.DateTime.now_local (), false).size;
                _overdeue_count = Planner.database.get_items_by_overdeue_view (false).size;
                today_count_updated ();
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
                    _today_count = get_caldav_today_count ();
                    today_count_updated ();
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
            add_view (task_list, "(contains? 'any' '')");
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

        _today_count = get_caldav_today_count ();
        today_count_updated ();
    }

    private void on_tasks_modified (Gee.Collection<ECal.Component> tasks) {
        foreach (ECal.Component task in tasks) {
            items_added[task.get_icalcomponent ().get_uid ()] = task;
        }

        _today_count = get_caldav_today_count ();
        today_count_updated ();
    }

    private void on_tasks_removed (SList<ECal.ComponentId?> cids) {
        foreach (unowned ECal.ComponentId cid in cids) {
            if (cid == null) {
                continue;
            } else {
                items_added.unset (cid.get_uid ());
            }
        }

        _today_count = get_caldav_today_count ();
        today_count_updated ();
    }

    private int get_caldav_today_count () {
        int returned = 0;

        foreach (ECal.Component task in items_added.values) {
            if (!task.get_icalcomponent ().get_due ().is_null_time ()) {
                GLib.DateTime datetime = CalDAVUtil.ical_to_date_time_local (
                    task.get_icalcomponent ().get_due ()
                );
    
                if (task.get_icalcomponent ().get_status () != ICal.PropertyStatus.COMPLETED &&
                    Granite.DateTime.is_same_day (datetime, new GLib.DateTime.now_local ())) {
                    returned++;
                }
            }
        }

        return returned;
    }
}