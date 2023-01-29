public class Objects.Completed : Objects.BaseObject {
    private static Completed? _instance;
    public static Completed get_default () {
        if (_instance == null) {
            _instance = new Completed ();
        }

        return _instance;
    }

    string _view_id;
    public string view_id {
        get {
            _view_id = "completed-view";
            return _view_id;
        }
    }

    int? _count = null;
    public int count {
        get {
            if (_count == null) {
                _count = Services.Database.get_default ().get_items_completed ().size;
            }

            return _count;
        }

        set {
            _count = value;
        }
    }

    public signal void count_updated ();

    construct {
        name = _("Completed");
        keywords = "%s;%s".printf (_("completed"), _("logbook"));

        Services.Database.get_default ().item_added.connect (() => {
            _count = Services.Database.get_default ().get_items_completed ().size;
            count_updated ();
        });

        Services.Database.get_default ().item_deleted.connect (() => {
            _count = Services.Database.get_default ().get_items_completed ().size;
            count_updated ();
        });

        Services.Database.get_default ().item_updated.connect (() => {
            _count = Services.Database.get_default ().get_items_completed ().size;
            count_updated ();
        });
    }
}