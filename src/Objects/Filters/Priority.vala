public class Objects.Priority : Objects.BaseObject {
    public int priority { get; construct; }

    private static Priority? _instance;
    public static Priority get_default (int priority) {
        if (_instance == null) {
            _instance = new Priority (priority);
        }

        return _instance;
    }

    string _view_id;
    public string view_id {
        get {
            _view_id = "priority-%d".printf (priority);
            return _view_id;
        }
    }

    public Priority (int priority) {
        Object (
            priority: priority
        );
    }

    int? _count = null;
    public int count {
        get {
            if (_count == null) {
                _count = Services.Database.get_default ().get_items_by_priority (priority, false).size;
            }

            return _count;
        }

        set {
            _count = value;
        }
    }

    public signal void count_updated ();

    construct {
        name = Util.get_default ().get_priority_title (priority);
        keywords = "%s;%s".printf (_("priority"), "p" + priority.to_string ());

        Services.Database.get_default ().item_added.connect (() => {
            _count = Services.Database.get_default ().get_items_by_priority (priority, false).size;
            count_updated ();
        });

        Services.Database.get_default ().item_deleted.connect (() => {
            _count = Services.Database.get_default ().get_items_by_priority (priority, false).size;
            count_updated ();
        });

        Services.Database.get_default ().item_updated.connect (() => {
            _count = Services.Database.get_default ().get_items_by_priority (priority, false).size;
            count_updated ();
        });
    }
}