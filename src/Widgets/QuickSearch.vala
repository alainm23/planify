public class Widgets.QuickSearch : Gtk.Revealer {
    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox search_listbox;

    public QuickSearch () {
        transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        margin_top = 75;
        valign = Gtk.Align.START;
        halign = Gtk.Align.CENTER;
        reveal_child = false;
    }

    construct {
        search_entry = new Gtk.SearchEntry ();
        search_entry.margin = 9;
        search_entry.width_request = 350;
        search_entry.placeholder_text = _("Quick search");

        var quick_search_grid = new Gtk.Grid ();
        quick_search_grid.margin = 6;
        quick_search_grid.get_style_context ().add_class ("card");
        quick_search_grid.get_style_context ().add_class ("planner-card-radius");
        quick_search_grid.add (search_entry);

        search_listbox = new Gtk.ListBox ();
        search_listbox.expand = true;

        var search_scroll = new Gtk.ScrolledWindow (null, null);
        search_scroll.margin = 6;
        search_scroll.height_request = 250;
        search_scroll.expand = true;
        search_scroll.add (search_listbox);

        var search_grid = new Gtk.Grid ();
        search_grid.margin = 6;
        search_grid.get_style_context ().add_class ("card");
        search_grid.get_style_context ().add_class ("planner-card-radius");
        search_grid.orientation = Gtk.Orientation.VERTICAL;
        search_grid.add (search_scroll);

        var search_revealer = new Gtk.Revealer ();
        search_revealer.add (search_grid);
        search_revealer.reveal_child = false;

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (quick_search_grid);
        main_grid.add (search_revealer);

        add (main_grid);
        update_items ();

        search_listbox.set_filter_func ((row) => {
            var item = row as Item;

            if (search_entry.text.down () == _("all")) {
                return true;
            } else {
                return search_entry.text.down () in item.title.down ();
            }
        });

        Application.signals.on_signal_show_quick_search.connect (() => {
            reveal_child = true;
            search_entry.grab_focus ();
        });

        search_entry.search_changed.connect (() => {
            if (search_entry.text != "") {
                search_revealer.reveal_child = true;
            } else {
                search_revealer.reveal_child = false;
            }

            search_listbox.invalidate_filter ();
        });

        search_entry.focus_out_event.connect (() => {
            if (search_entry.text == "") {
                reveal_child = false;
            }

            return false;
        });

        search_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                reveal_child = false;
            }

            return false;
        });
    }

    private void update_items () {
        // Tasks
        var all_tasks = new Gee.ArrayList<Objects.Task?> ();
        all_tasks = Application.database.get_all_search_tasks ();

        foreach (var task in all_tasks) {
            var row = new Item (task.content, "emblem-default-symbolic");
            search_listbox.add (row);
        }

        // Projects
        var all_projects = new Gee.ArrayList<Objects.Project?> ();
        all_projects= Application.database.get_all_projects ();

        foreach (var project in all_projects) {
            var row = new Item (project.name, "planner-startup-symbolic");
            search_listbox.add (row);
        }

        var inbox_row = new Item (Application.utils.INBOX_STRING, "mail-mailbox-symbolic");
        search_listbox.add (inbox_row);

        var today_row = new Item (Application.utils.TODAY_STRING, "help-about-symbolic");
        search_listbox.add (today_row);

        var upcoming_row = new Item (Application.utils.UPCOMING_STRING, "x-office-calendar-symbolic");
        search_listbox.add (upcoming_row);

        search_listbox.show_all ();
    }
}

public class Item : Gtk.ListBoxRow {

    public string title {
        get {
            return name_label.label;
        }
        set {
            name_label.label = value;
            tooltip_text = value;
        }
    }

    public string icon_name {
        owned get {
            return image.icon_name ?? "";
        }
        set {
            if (value != null && value != "") {
                image.gicon = new ThemedIcon (value);
                image.pixel_size = 16;
                image.no_show_all = false;
                image.show ();
            } else {
                image.no_show_all = true;
                image.hide ();
            }
        }
    }

    public Gtk.Label name_label;
    public Gtk.Image image;

    public Item (string _name, string _icon_name) {
        Object (
            title: _name,
            icon_name: _icon_name
        );
    }

    construct {
        //can_focus = false;
        get_style_context ().add_class ("search-row");

        name_label = new Gtk.Label (null);
        name_label.get_style_context ().add_class ("h3");
        name_label.ellipsize = Pango.EllipsizeMode.END;
        name_label.use_markup = true;

        image = new Gtk.Image ();
        image.margin_top = 1;

        var main_grid = new Gtk.Grid ();
        main_grid.margin = 6;
        main_grid.column_spacing = 6;
        main_grid.add (image);
        main_grid.add (name_label);

        add (main_grid);
    }
}
