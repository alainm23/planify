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
                _scheduled_count = Services.Database.get_default ().get_items_by_scheduled (false).size;
            }

            return _scheduled_count;
        }

        set {
            _scheduled_count = value;
        }
    }

    public signal void scheduled_count_updated ();

    construct {
        name = _("Scheduled");
        keywords = "%s;%s".printf (_("scheduled"), _("upcoming"));

        Services.Database.get_default ().item_added.connect (() => {
            _scheduled_count = Services.Database.get_default ().get_items_by_scheduled (false).size;
            scheduled_count_updated ();
        });

        Services.Database.get_default ().item_deleted.connect (() => {
            _scheduled_count = Services.Database.get_default ().get_items_by_scheduled (false).size;
            scheduled_count_updated ();
        });

        Services.Database.get_default ().item_updated.connect (() => {
            _scheduled_count = Services.Database.get_default ().get_items_by_scheduled (false).size;
            scheduled_count_updated ();
        });
    }
}