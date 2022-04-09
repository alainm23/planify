public class Services.AccountsModel : Object {
    public ListStore accounts_liststore { get; private set; }
    private E.SourceRegistryWatcher collection_extension_watcher;

    private static AccountsModel? _instance;
    public static AccountsModel get_default () {
        if (_instance == null) {
            _instance = new AccountsModel ();
        }

        return _instance;
    }

    public signal void esource_removed (E.Source e_source);
    public signal void esource_added (E.Source e_source);

    construct {
        accounts_liststore = new ListStore (typeof (E.Source));
        init_registry.begin ();
    }

    private async void init_registry () {
        try {
            var registry = yield new E.SourceRegistry (null);

            collection_extension_watcher = new E.SourceRegistryWatcher (registry, E.SOURCE_EXTENSION_COLLECTION);
            collection_extension_watcher.appeared.connect (add_esource);
            collection_extension_watcher.disappeared.connect (remove_esource);
            collection_extension_watcher.reclaim ();
        } catch (Error e) {
            critical (e.message);
        }
    }

    private void add_esource (E.Source e_source) {
        uint position;
        if (accounts_liststore.find (e_source, out position)) {
            return;
        }

        // Ignore children of collection accounts
        if (e_source.parent != null) {
            return;
        }

        // Ignore "Search", "On This Computer" and "local_mbox"
        if (e_source.has_extension (E.SOURCE_EXTENSION_MAIL_ACCOUNT)) {
            unowned var mail_source = (E.SourceMailAccount) e_source.get_extension (E.SOURCE_EXTENSION_MAIL_ACCOUNT);
            if (mail_source.backend_name == "vfolder" || mail_source.backend_name == "maildir" || mail_source.backend_name == "mbox" ) {
                return;
            }
        }

        esource_added (e_source);
        accounts_liststore.append (e_source);
    }

    private void remove_esource (E.Source e_source) {
        uint position;
        if (accounts_liststore.find (e_source, out position)) {
            accounts_liststore.remove (position);
            esource_removed (e_source);
        }
    }
}