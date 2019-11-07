public class Views.Today : Gtk.EventBox {
    private Gtk.ListBox listbox;
    private Gee.HashMap<string, bool> items_loaded;
    construct {
        items_loaded = new Gee.HashMap<string, bool> ();

        var icon_image = new Gtk.Image ();
        icon_image.valign = Gtk.Align.CENTER;
        icon_image.pixel_size = 21; 

        var hour = new GLib.DateTime.now_local ().get_hour ();
        if (hour >= 18 || hour <= 6) {
            icon_image.gicon = new ThemedIcon ("planner-today-night-symbolic");
            icon_image.get_style_context ().add_class ("today-night-icon");
        } else {
            icon_image.gicon = new ThemedIcon ("planner-today-day-symbolic");
            icon_image.get_style_context ().add_class ("today-day-icon");
        }

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Today")));
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        //title_label.get_style_context ().add_class ("today");
        title_label.use_markup = true;

        var date_label = new Gtk.Label (new GLib.DateTime.now_local ().format (Granite.DateTime.get_default_date_format (false, true, false)));
        date_label.valign = Gtk.Align.CENTER;
        date_label.margin_top = 6;
        date_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_start = 41;
        top_box.margin_end = 24;

        top_box.pack_start (icon_image, false, false, 0);
        top_box.pack_start (title_label, false, false, 6);
        top_box.pack_start (date_label, false, false, 0);

        listbox = new Gtk.ListBox  ();
        listbox.margin_top = 12;
        listbox.valign = Gtk.Align.START;
        listbox.get_style_context ().add_class ("welcome");
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (listbox, false, false, 0);

        var main_scrolled = new Gtk.ScrolledWindow (null, null);
        main_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        main_scrolled.width_request = 246;
        main_scrolled.expand = true;
        main_scrolled.add (main_box);

        add (main_scrolled);
        add_all_items ();

        listbox.row_activated.connect ((row) => {
            var item = ((Widgets.ItemRow) row);
            item.reveal_child = true;
        });

        Application.database.add_due_item.connect ((item) => {
            var datetime = new GLib.DateTime.from_iso8601 (item.due, new GLib.TimeZone.local ());
            if (Application.utils.is_today (datetime)) {
                if (items_loaded.has_key (item.id.to_string ()) == false) {
                    var row = new Widgets.ItemRow (item);
            
                    row.is_today = true;
                    items_loaded.set (item.id.to_string (), true);
        
                    listbox.add (row);
                    listbox.show_all ();
                }
            }
        });

        Application.database.remove_due_item.connect ((item) => {
            if (items_loaded.has_key (item.id.to_string ())) {
                items_loaded.unset (item.id.to_string ());
            }
        });

        Application.database.update_due_item.connect ((item) => {
            var datetime = new GLib.DateTime.from_iso8601 (item.due, new GLib.TimeZone.local ());
            if (items_loaded.has_key (item.id.to_string ()) == false) {
                if (Application.utils.is_today (datetime)) {
                    var row = new Widgets.ItemRow (item);
        
                    row.is_today = true;
                    items_loaded.set (item.id.to_string (), true);
        
                    listbox.add (row);
                    listbox.show_all ();
                }
            } else {
                items_loaded.unset (item.id.to_string ());
            }
        });
    }

    private void add_all_items () {
        foreach (var item in Application.database.get_all_today_items ()) {
            var row = new Widgets.ItemRow (item);
            
            row.is_today = true;
            items_loaded.set (item.id.to_string (), true);

            listbox.add (row);
            listbox.show_all ();
        }
    }
}