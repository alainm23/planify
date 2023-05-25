public class Objects.Filters.Labels : Objects.BaseObject {
    private static Labels? _instance;
    public static Labels get_default () {
        if (_instance == null) {
            _instance = new Labels ();
        }

        return _instance;
    }

    string _view_id;
    public string view_id {
        get {
            _view_id = "labels-view";
            return _view_id;
        }
    }

    int? _count = null;
    public int count {
        get {
            if (_count == null) {
                _count = Services.Database.get_default ().get_labels_collection().size;
            }

            return _count;
        }

        set {
            _count = value;
        }
    }

    public signal void count_updated ();

    construct {
        name = _("Labels");
        keywords = "%s".printf (_("labels"));

        Services.Database.get_default ().label_added.connect (() => {
            _count = Services.Database.get_default ().get_labels_collection().size;
            count_updated ();
        });

        Services.Database.get_default ().label_deleted.connect (() => {
            _count = Services.Database.get_default ().get_labels_collection().size;
            count_updated ();
        });

        Services.Database.get_default ().label_updated.connect (() => {
            _count = Services.Database.get_default ().get_labels_collection().size;
            count_updated ();
        });
    }
}