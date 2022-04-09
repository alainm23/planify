errordomain TaskModelError {
    CLIENT_NOT_AVAILABLE,
    BACKEND_ERROR,
    INVALID_ARGUMENT;
}

public class Services.CalDAV : Object {
    public signal void task_list_added (E.Source task_list);
    public signal void task_list_modified (E.Source task_list);
    public signal void task_list_removed (E.Source task_list);

    public delegate void TasksAddedFunc (Gee.Collection<ECal.Component> tasks, E.Source task_list);
    public delegate void TasksModifiedFunc (Gee.Collection<ECal.Component> tasks);
    public delegate void TasksRemovedFunc (SList<ECal.ComponentId?> cids);
    
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
            throw new TaskModelError.CLIENT_NOT_AVAILABLE ("No client available for task list '%s'", task_list.dup_display_name ());  // vala-lint=line-length
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

    private static CalDAV? _instance;
    public static CalDAV get_default () {
        if (_instance == null) {
            _instance = new CalDAV ();
        }

        return _instance;
    }

    construct {
        task_list_client = new HashTable<string, ECal.Client> (str_hash, str_equal);
        task_list_client_views = new HashTable<ECal.Client, Gee.Collection<ECal.ClientView>> (direct_hash, direct_equal);  // vala-lint=line-length
    }

    public async void start () {
        var promise = new Gee.Promise<E.SourceRegistry> ();
        registry = promise.future;
        yield init_registry (promise);
    }

    private async void init_registry (Gee.Promise<E.SourceRegistry> promise) {
        try {
            var registry = yield new E.SourceRegistry (null);

            registry.source_added.connect ((task_list) => {
                debug ("Adding task list '%s'", task_list.dup_display_name ());
                create_task_list_client (task_list);
                task_list_added (task_list);
            });

            registry.source_changed.connect ((task_list) => {
                task_list_modified (task_list);
            });

            registry.source_removed.connect ((task_list) => {
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
                task_list_removed (task_list);
            });

            registry.list_sources (E.SOURCE_EXTENSION_TASK_LIST).foreach ((task_list) => {
                E.SourceTaskList task_list_extension = (E.SourceTaskList)task_list.get_extension (E.SOURCE_EXTENSION_TASK_LIST);  // vala-lint=line-length
                if (task_list_extension.selected == true && task_list.enabled == true && !task_list.has_extension (E.SOURCE_EXTENSION_COLLECTION)) {
                    registry.source_added (task_list);
                }
            });

            promise.set_value (registry);
        } catch (Error e) {
            critical (e.message);
            promise.set_exception (e);
        }
    }

    public string get_collection_backend_name (E.Source source, E.SourceRegistry registry) {
        string? backend_name = null;

        var collection_source = registry.find_extension (source, E.SOURCE_EXTENSION_COLLECTION);
        if (collection_source != null) {
            var collection_source_extension = (E.SourceCollection) collection_source.get_extension (E.SOURCE_EXTENSION_COLLECTION);
            backend_name = collection_source_extension.backend_name;
        }

        if (backend_name == null && source.has_extension (E.SOURCE_EXTENSION_TASK_LIST)) {
            var source_extension = (E.SourceTaskList) source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);
            backend_name = source_extension.backend_name;
        }

        return backend_name == null ? "" : backend_name;
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

    private void on_objects_added (E.Source task_list, ECal.Client client, SList<ICal.Component> objects, TasksAddedFunc on_tasks_added) {  // vala-lint=line-length
        debug (@"Received $(objects.length()) added task(s) for task list '%s'", task_list.dup_display_name ());
        var added_tasks = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) CalDAVUtil.calcomponent_equal_func);  // vala-lint=line-length
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

    private void on_objects_modified (E.Source task_list, ECal.Client client, SList<ICal.Component> objects, TasksModifiedFunc on_tasks_modified) {  // vala-lint=line-length
        debug (@"Received $(objects.length()) modified task(s) for task list '%s'", task_list.dup_display_name ());
        var updated_tasks = new Gee.ArrayList<ECal.Component> ((Gee.EqualDataFunc<ECal.Component>?) CalDAVUtil.calcomponent_equal_func);  // vala-lint=line-length
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

    private void on_objects_removed (E.Source task_list, ECal.Client client, SList<ECal.ComponentId?> cids, TasksRemovedFunc on_tasks_removed) {  // vala-lint=line-length
        debug (@"Received $(cids.length()) removed task(s) for task list '%s'", task_list.dup_display_name ());
        on_tasks_removed (cids);
    }

    public async void update_task_list_display_name (E.Source task_list, string display_name) throws Error {
        var registry = get_registry_sync ();
        var collection_source = registry.find_extension (task_list, E.SOURCE_EXTENSION_COLLECTION);

        if (collection_source != null && task_list.has_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND)) {
            debug ("WebDAV Rename '%s'", task_list.get_uid ());

            var collection_source_webdav_session = new E.WebDAVSession (collection_source);
            var source_webdav_extension = (E.SourceWebdav) task_list.get_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND);

            var credentials_provider = new E.SourceCredentialsProvider (registry);
            E.NamedParameters credentials;
            credentials_provider.lookup_sync (collection_source, null, out credentials);
            collection_source_webdav_session.credentials = credentials;

            var changes = new GLib.SList<E.WebDAVPropertyChange> ();
            changes.append (new E.WebDAVPropertyChange.set (
                E.WEBDAV_NS_DAV,
                "displayname",
                display_name
            ));

#if HAS_EDS_3_40
            collection_source_webdav_session.update_properties_sync (
#else
            E.webdav_session_update_properties_sync (
                collection_source_webdav_session,
#endif
                source_webdav_extension.soup_uri.to_string (false),
                changes,
                null
            );

            registry.refresh_backend_sync (collection_source.uid, null);

        } else if ("gtasks" == ((E.SourceTaskList) task_list.get_extension (E.SOURCE_EXTENSION_TASK_LIST)).backend_name && E.GDataOAuth2Authorizer.supported ()) {
            debug ("GTasks Rename '%s'", task_list.get_uid ());

            var authorizer = (GData.Authorizer) new E.GDataOAuth2Authorizer (collection_source, typeof (GData.TasksService));
            var gtasks_service = new GData.TasksService (authorizer);
            var uri = "https://www.googleapis.com/tasks/v1/users/@me/lists/%s";
            var task_list_id = ((E.SourceResource) task_list.get_extension (
                E.SOURCE_EXTENSION_RESOURCE
            )).identity.replace ("gtasks::", "");

            var gtasks_tasklist = (GData.TasksTasklist) yield gtasks_service.query_single_entry_async (
                GData.TasksService.get_primary_authorization_domain (),
                uri.printf (task_list_id),
                null,
                typeof (GData.TasksTasklist),
                null
            );

            gtasks_tasklist.title = display_name;
            gtasks_service.update_tasklist (gtasks_tasklist, null);

            yield registry.refresh_backend (collection_source.uid, null);
        } else if (task_list.parent == "local-stub") {
            debug ("Local Rename '%s'", task_list.get_uid ());
            task_list.display_name = display_name;
            registry.commit_source_sync (task_list, null);
        } else {
            throw new TaskModelError.BACKEND_ERROR ("Renaming tasks list is not supported yet for this type of backend.");
        }
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

    public async void update_task (E.Source list, ECal.Component task, ECal.ObjModType mod_type) throws Error {
        ECal.Client client = get_client (list);
        unowned ICal.Component comp = task.get_icalcomponent ();

        debug (@"Updating task '$(comp.get_uid())' [mod_type=$(mod_type)]");
        yield client.modify_object (comp, mod_type, ECal.OperationFlags.NONE, null);
    }

    public async void remove_task (E.Source list, ECal.Component task, ECal.ObjModType mod_type) throws Error {
        ECal.Client client = get_client (list);
        unowned ICal.Component comp = task.get_icalcomponent ();

        string uid = comp.get_uid ();
        string? rid = task.has_recurrences () ? null : task.get_recurid_as_string ();

        debug (@"Removing task '$uid'");
        yield client.remove_object (uid, rid, mod_type, ECal.OperationFlags.NONE, null);
    }

    public async void complete_task (E.Source list, ECal.Component task) throws Error {
        ECal.Client client = get_client (list);

        unowned ICal.Component comp = task.get_icalcomponent ();
        var was_completed = comp.get_status () == ICal.PropertyStatus.COMPLETED;

        if (was_completed) {
            debug (@"Reopen $(task.is_instance() ? "instance" : "task") '$(comp.get_uid())'");

            comp.set_status (ICal.PropertyStatus.NONE);
            task.set_percent_complete (0);

            task.set_completed (new ICal.Time.null_time ());

            yield client.modify_object (comp, ECal.ObjModType.THIS, ECal.OperationFlags.NONE, null);
        } else {
            debug (@"Completing $(task.is_instance() ? "instance" : "task") '$(comp.get_uid())'");

            comp.set_status (ICal.PropertyStatus.COMPLETED);
            task.set_percent_complete (100);
            task.set_completed (new ICal.Time.today ());

            yield client.modify_object (comp, ECal.ObjModType.THIS_AND_PRIOR, ECal.OperationFlags.NONE, null);
        }

        //  if (task.has_recurrences () && !was_completed) {
        //      var duration = new ICal.Duration.null_duration ();
        //      duration.set_weeks (520); // roughly 10 years
        //      var today = new ICal.Time.today ();

        //      var start = comp.get_dtstart ();
        //      if (today.compare (start) > 0) {
        //          start = today;
        //      }
        //      var end = start.add (duration);

        //      ECal.RecurInstanceCb recur_instance_callback = (instance_comp, instance_start_timet, instance_end_timet, cancellable) => {

        //          var instance = new ECal.Component ();
        //          instance.set_icalcomponent (instance_comp);

        //          if (!instance_comp.get_due ().is_null_time ()) {
        //              instance_comp.set_due (instance_comp.get_dtstart ());
        //          }

        //          instance_comp.set_status (ICal.PropertyStatus.NONE);
        //          instance.set_percent_complete (0);

        //          instance.set_completed (new ICal.Time.null_time ());

        //          if (instance.has_alarms ()) {
        //              instance.get_alarm_uids ().@foreach ((alarm_uid) => {
        //                  ECal.ComponentAlarmTrigger trigger;
        //                  trigger = new ECal.ComponentAlarmTrigger.relative (ECal.ComponentAlarmTriggerKind.RELATIVE_START, new ICal.Duration.null_duration ());
        //                  instance.get_alarm (alarm_uid).set_trigger (trigger);
        //              });
        //          }

        //          client.modify_object_sync (instance_comp, ECal.ObjModType.THIS_AND_FUTURE, ECal.OperationFlags.NONE, null);

        //          return false; // only generate one instance
        //      };

        //      client.generate_instances_for_object_sync (comp, start.as_timet (), end.as_timet (), null, recur_instance_callback);
        //  }
    }

    public async string? add_task (E.Source list, ECal.Component task) throws Error {
        ECal.Client client = get_client (list);
        unowned ICal.Component comp = task.get_icalcomponent ();

        debug (@"Adding task '$(comp.get_uid())'");

        string? uid;
        yield client.create_object (comp, ECal.OperationFlags.NONE, null, out uid);
        if (uid != null) {
            comp.set_uid (uid);
        }

        return uid;
    }

    public async void update_task_list_color (E.Source task_list, string color) throws Error {
        if (!task_list.has_extension (E.SOURCE_EXTENSION_TASK_LIST)) {
            throw new TaskModelError.INVALID_ARGUMENT ("Changing the color is not supported by this source.");
        }
        var task_list_extension = (E.SourceTaskList) task_list.get_extension (E.SOURCE_EXTENSION_TASK_LIST);
        var previous_color = task_list_extension.dup_color ();

        var registry = get_registry_sync ();
        var collection_source = registry.find_extension (task_list, E.SOURCE_EXTENSION_COLLECTION);
        var backend_name = "local";
        if (collection_source != null) {
            backend_name = get_collection_backend_name (collection_source, registry);
        }

        // Change color in local EDS first, because remote may take quite some time
        debug ("Update local color for '%s'", task_list.get_uid ());
        task_list_extension.color = color;
        registry.commit_source_sync (task_list, null);

        try {
            switch (backend_name.down ()) {
                case "webdav":
                    if (collection_source == null || !task_list.has_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND)) {
                        throw new TaskModelError.INVALID_ARGUMENT ("Required information is missing to update the color of this source.");
                    }
                    debug ("Update %s color for '%s'", backend_name, task_list.get_uid ());

                    var collection_source_webdav_session = new E.WebDAVSession (collection_source);
                    var source_webdav_extension = (E.SourceWebdav) task_list.get_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND);

                    var credentials_provider = new E.SourceCredentialsProvider (registry);
                    E.NamedParameters credentials;
                    credentials_provider.lookup_sync (collection_source, null, out credentials);
                    collection_source_webdav_session.credentials = credentials;

                    var changes = new GLib.SList<E.WebDAVPropertyChange> ();
                    changes.append (new E.WebDAVPropertyChange.set (
                        E.WEBDAV_NS_ICAL,
                        "calendar-color",
                        color
                    ));

#if HAS_EDS_3_40
                    collection_source_webdav_session.update_properties_sync (
#else
                    E.webdav_session_update_properties_sync (
                        collection_source_webdav_session,
#endif
                        source_webdav_extension.soup_uri.to_string (false),
                        changes,
                        null
                    );

                    registry.refresh_backend_sync (collection_source.uid, null);
                    break;

                case "local":
                    // we updated the local color above, so we are already done here.
                    break;

                default:
                    throw new TaskModelError.BACKEND_ERROR ("Updating the list color is not supported for '%s' backends.", backend_name);
            }

        } catch (Error e) {
            debug ("Reset local color for '%s'", task_list.get_uid ());
            task_list_extension.color = previous_color;
            registry.commit_source_sync (task_list, null);
            throw e;
        }
    }

    public async void add_task_list (E.Source task_list, E.Source collection_or_sibling) throws Error {
        var registry = get_registry_sync ();
        var task_list_extension = (E.SourceTaskList) task_list.get_extension (E.SOURCE_EXTENSION_TASK_LIST);
        var backend_name = get_collection_backend_name (collection_or_sibling, registry);

        switch (backend_name.down ()) {
            case "webdav":
                var collection_source = registry.find_extension (collection_or_sibling, E.SOURCE_EXTENSION_COLLECTION);
                var collection_source_webdav_session = new E.WebDAVSession (collection_source);
                var credentials_provider = new E.SourceCredentialsProvider (registry);

                E.NamedParameters credentials;
                credentials_provider.lookup_sync (collection_source, null, out credentials);
                collection_source_webdav_session.credentials = credentials;

                var webdav_task_list_uri = yield discover_webdav_server_uri (credentials, collection_source);
                webdav_task_list_uri.set_path (webdav_task_list_uri.get_path () + "/" + GLib.Uuid.string_random ().up ());

                collection_source_webdav_session.mkcalendar_sync (
                    webdav_task_list_uri.to_string (false),
                    task_list.display_name,
                    null,
                    task_list_extension.color,
                    E.WebDAVResourceSupports.TASKS,
                    null
                );

                registry.refresh_backend_sync (collection_source.uid, null);
                break;
            case "google":
                var collection_source = registry.find_extension (collection_or_sibling, E.SOURCE_EXTENSION_COLLECTION);
                var authorizer = (GData.Authorizer) new E.GDataOAuth2Authorizer (collection_source, typeof (GData.TasksService));
                var gtasks_service = new GData.TasksService (authorizer);

                var gtasks_tasklist = new GData.TasksTasklist (null) {
                    title = task_list.display_name
                };

                gtasks_service.insert_tasklist (gtasks_tasklist, null);
                yield registry.refresh_backend (collection_source.uid, null);
                break;
            case "local":
                task_list.parent = "local-stub";
                task_list_extension.backend_name = "local";

                registry.commit_source_sync (task_list, null);
                break;
            default:
                throw new TaskModelError.BACKEND_ERROR ("Task list management for '%s' is not supported yet.".printf (backend_name));
        }
    }

    private async Soup.URI discover_webdav_server_uri (E.NamedParameters credentials, E.Source collection_source) throws Error {
        var collection_source_extension = (E.SourceCollection) collection_source.get_extension (E.SOURCE_EXTENSION_COLLECTION);

        Soup.URI? webdav_server_uri = null;
        GLib.Error? webdav_error = null;

#if HAS_EDS_3_40
        collection_source.webdav_discover_sources.begin (
#else
        E.webdav_discover_sources.begin (
            collection_source,
#endif
            collection_source_extension.calendar_url,
            E.WebDAVDiscoverSupports.TASKS,
            credentials,
            null,
            (obj, res) => {
                string webdav_certificate_pem;
                GLib.TlsCertificateFlags? webdav_certificate_errors;
                GLib.SList<E.WebDAVDiscoveredSource?> webdav_discovered_sources;
                GLib.SList<string> webdav_calendar_user_addresses;

                try {

#if HAS_EDS_3_40
                    collection_source.webdav_discover_sources.end (
#else
                    E.webdav_discover_sources_finish (
                        collection_source,
#endif
                        res,
                        out webdav_certificate_pem,
                        out webdav_certificate_errors,
                        out webdav_discovered_sources,
                        out webdav_calendar_user_addresses
                    );

                    if (webdav_discovered_sources.length () > 0) {
                        var webdav_discovered_source = webdav_discovered_sources.nth_data (0);
                        webdav_server_uri = new Soup.URI (webdav_discovered_source.href.dup ());
                    }

#if !HAS_EDS_3_40
                    E.webdav_discover_do_free_discovered_sources ((owned) webdav_discovered_sources);
#endif

                    if (webdav_server_uri == null) {
                        throw new TaskModelError.BACKEND_ERROR ("Unable to resolve the WebDAV uri from backend.");
                    }

                    var uri_dir_path = webdav_server_uri.get_path ();
                    if (uri_dir_path.has_suffix ("/")) {
                        uri_dir_path = uri_dir_path.substring (0, uri_dir_path.length - 1);
                    }
                    uri_dir_path = uri_dir_path.substring (0, uri_dir_path.last_index_of ("/"));
                    webdav_server_uri.set_path (uri_dir_path);

                } catch (Error e) {
                    webdav_error = e;
                }
                discover_webdav_server_uri.callback ();
            }
        );

        yield;

        if (webdav_error != null) {
            throw webdav_error;
        }
        return webdav_server_uri;
    }

    public bool is_remove_task_list_supported (E.Source source) {
        try {
            var registry = get_registry_sync ();
            var backend_name = get_collection_backend_name (source, registry);

            switch (backend_name.down ()) {
                case "webdav": return true;
                case "google": return !is_gtasks_default_task_list (source, registry);
                case "local": return source.removable;
            }

        } catch (Error e) {
            warning (e.message);
        }
        return false;
    }

    private bool is_gtasks_default_task_list (E.Source task_list, E.SourceRegistry registry) throws Error {
        var collection_source = registry.find_extension (task_list, E.SOURCE_EXTENSION_COLLECTION);
        var authorizer = (GData.Authorizer) new E.GDataOAuth2Authorizer (collection_source, typeof (GData.TasksService));
        var service = new GData.TasksService (authorizer);
        var id = ((E.SourceResource) task_list.get_extension (
            E.SOURCE_EXTENSION_RESOURCE
        )).identity.replace ("gtasks::", "");

        var tasklist = (GData.TasksTasklist) service.query_single_entry (
            GData.TasksService.get_primary_authorization_domain (),
            "https://www.googleapis.com/tasks/v1/users/@me/lists/@default",
            null,
            typeof (GData.TasksTasklist),
            null
        );

        return tasklist.id == id;
    }

    public async void remove_task_list (E.Source task_list) throws Error {
        var registry = get_registry_sync ();
        var backend_name = get_collection_backend_name (task_list, registry);

        switch (backend_name.down ()) {
            case "webdav":
                var collection_source = registry.find_extension (task_list, E.SOURCE_EXTENSION_COLLECTION);
                var collection_source_webdav_session = new E.WebDAVSession (collection_source);
                var credentials_provider = new E.SourceCredentialsProvider (registry);

                E.NamedParameters credentials;
                credentials_provider.lookup_sync (collection_source, null, out credentials);
                collection_source_webdav_session.credentials = credentials;

                var task_list_webdav_extension = (E.SourceWebdav) task_list.get_extension (E.SOURCE_EXTENSION_WEBDAV_BACKEND);

                collection_source_webdav_session.delete_sync (
                    task_list_webdav_extension.soup_uri.to_string (false),
                    E.WEBDAV_DEPTH_THIS_AND_CHILDREN,
                    null,
                    null
                );

                registry.refresh_backend_sync (collection_source.uid, null);
                break;
            case "google":
                var collection_source = registry.find_extension (task_list, E.SOURCE_EXTENSION_COLLECTION);
                var authorizer = (GData.Authorizer) new E.GDataOAuth2Authorizer (collection_source, typeof (GData.TasksService));
                var service = new GData.TasksService (authorizer);
                var uri = "https://www.googleapis.com/tasks/v1/users/@me/lists/%s";
                var id = ((E.SourceResource) task_list.get_extension (
                    E.SOURCE_EXTENSION_RESOURCE
                )).identity.replace ("gtasks::", "");

                var tasklist = (GData.TasksTasklist) yield service.query_single_entry_async (
                    GData.TasksService.get_primary_authorization_domain (),
                    uri.printf (id),
                    null,
                    typeof (GData.TasksTasklist),
                    null
                );

                service.delete_tasklist (tasklist, null);
                yield registry.refresh_backend (collection_source.uid, null);
                break;

            case "local":
                task_list.remove_sync (null);
                break;

            default:
                throw new TaskModelError.BACKEND_ERROR ("Task list management for '%s' is not supported yet.".printf (backend_name));
        }
    }
}
