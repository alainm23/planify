[DBus (name = "org.gnome.Shell.SearchProvider2")]
public class Planify.SearchProvider : GLib.Application {

    private SearchRepository repository;

    internal SearchProvider () {
        Object (
            application_id: Build.APPLICATION_ID + ".SearchProvider",
            flags: ApplicationFlags.IS_SERVICE,
            inactivity_timeout: 10000
        );
    }

    construct {
        repository = new SearchRepository ();
    }

    protected override bool dbus_register (DBusConnection connection, string object_path) throws Error {
        base.dbus_register (connection, object_path);

        try {
            connection.register_object (object_path, this);
        } catch (IOError e) {
            warning ("Could not register search provider: %s", e.message);
            quit ();
        }

        return true;
    }

    public string[] get_initial_result_set (string[] terms) throws Error {
        return repository.search (string.joinv (" ", terms));
    }

    public string[] get_subsearch_result_set (string[] previous_results, string[] terms) throws Error {
        return repository.search (string.joinv (" ", terms));
    }

    public HashTable<string, Variant>[] get_result_metas (string[] identifiers) throws Error {
        var results = new GenericArray<HashTable<string, Variant>> ();

        foreach (var id in identifiers) {
            var meta_data = repository.get_meta (id);
            if (meta_data == null) {
                continue;
            }

            var meta = new HashTable<string, Variant> (str_hash, str_equal);
            meta.insert ("id", new Variant.string (id));
            meta.insert ("name", new Variant.string (meta_data.name));
            meta.insert ("description", new Variant.string (meta_data.description));
            results.add (meta);
        }

        return results.data;
    }

    public void activate_result (string identifier, string[] terms, uint32 timestamp) throws Error {
        if (identifier.has_prefix ("project-")) {
            launch_planify ("planify://project/" + identifier.substring (8));
        } else if (identifier.has_prefix ("item-")) {
            launch_planify ("planify://item/" + identifier.substring (5));
        } else {
            launch_planify ("planify://");
        }
    }

    public void launch_search (string[] terms, uint32 timestamp) throws Error {
        launch_planify ("planify://");
    }

    private void launch_planify (string uri = "planify://") {
        try {
            AppInfo.launch_default_for_uri (uri, null);
        } catch (Error e) {
            try {
                Process.spawn_command_line_async ("flatpak run " + Build.APPLICATION_ID);
            } catch (SpawnError se) {
                warning ("Could not launch Planify: %s", se.message);
            }
        }
    }
}
