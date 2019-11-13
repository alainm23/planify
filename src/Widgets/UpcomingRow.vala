public class Widgets.UpcomingRow : Gtk.ListBoxRow {
    public GLib.DateTime date { get; construct; }

    private Gtk.ListBox listbox;
    private Gtk.Revealer motion_revealer;
    private Gee.HashMap<string, bool> items_loaded;

    public UpcomingRow (GLib.DateTime date) {
        Object (
            date: date
        );
    }

    construct {
        can_focus = false;
        get_style_context ().add_class ("area-row");
        
        items_loaded = new Gee.HashMap<string, bool> ();

        string day = date.format ("%A");
        if (Application.utils.is_tomorrow (date)) {
            day = _("Tomorrow");
        }

        var day_label =  new Gtk.Label (day);
        day_label.halign = Gtk.Align.START;
        day_label.get_style_context ().add_class ("header-title");
        day_label.valign = Gtk.Align.CENTER;
        day_label.use_markup = true;

        var date_label = new Gtk.Label ("<small>%s</small>".printf (Application.utils.get_default_date_format_from_date (date)));
        date_label.halign = Gtk.Align.START;
        date_label.valign = Gtk.Align.CENTER;
        date_label.use_markup = true;

        var add_button = new Gtk.Button ();
        add_button.can_focus = false;
        add_button.valign = Gtk.Align.CENTER;
        add_button.tooltip_text = _("Add task");
        add_button.image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        add_button.get_style_context ().remove_class ("button");
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        add_button.get_style_context ().add_class ("hidden-button");

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin_start = 41;
        top_box.margin_end = 32;
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.pack_start (day_label, false, false, 0);
        top_box.pack_start (date_label, false, false, 6);
        //top_box.pack_end (add_button, false, false, 0);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_top = 3;
        separator.margin_start = 41;
        separator.margin_end = 32;
        separator.margin_bottom = 6;

        var motion_grid = new Gtk.Grid ();
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;
            
        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        listbox = new Gtk.ListBox  ();
        listbox.valign = Gtk.Align.START;
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.margin_bottom = 12;
        main_box.hexpand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (motion_revealer, false, false, 0);
        main_box.pack_start (separator, false, false, 0);
        main_box.pack_start (listbox, false, false, 0);

        add (main_box);
        add_all_items ();

        listbox.row_activated.connect ((row) => {
            var item = ((Widgets.ItemRow) row);
            item.reveal_child = true;
        });

        Application.database.add_due_item.connect ((item) => {
            var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
            if (Granite.DateTime.is_same_day (datetime, date)) {
                if (items_loaded.has_key (item.id.to_string ()) == false) {
                    add_item (item);  
                }
            }
        });

        Application.database.remove_due_item.connect ((item) => {
            if (items_loaded.has_key (item.id.to_string ())) {
                items_loaded.unset (item.id.to_string ());
            }
        });

        Application.database.update_due_item.connect ((item) => {
            var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());

            if (Granite.DateTime.is_same_day (datetime, date)) {
                if (items_loaded.has_key (item.id.to_string ()) == false) {
                    var row = new Widgets.ItemRow (item);
            
                    row.upcoming = date;
                    items_loaded.set (item.id.to_string (), true);

                    Timeout.add (1000, () => {
                        listbox.add (row);
                        listbox.show_all ();
            
                        return false;
                    }); 
                }
            } else {
                if (items_loaded.has_key (item.id.to_string ())) {
                    items_loaded.unset (item.id.to_string ());
                }
            }
        });

        Application.database.item_completed.connect ((item) => {
            if (item.checked == 0 && item.due_date != "") {
                var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
                if (Granite.DateTime.is_same_day (datetime, date)) {
                    if (items_loaded.has_key (item.id.to_string ()) == false) {
                        add_item (item);
                    }
                }
            } else {
                if (items_loaded.has_key (item.id.to_string ())) {
                    items_loaded.unset (item.id.to_string ());
                }
            }
        });
    }

    private void add_item (Objects.Item item) {
        var row = new Widgets.ItemRow (item);
            
        row.upcoming = date;
        items_loaded.set (item.id.to_string (), true);

        listbox.add (row);
        listbox.show_all ();
    }

    private void add_all_items () {
        foreach (var item in Application.database.get_items_by_date (date)) {
            var row = new Widgets.ItemRow (item);

            row.upcoming = date;
            items_loaded.set (item.id.to_string (), true);

            listbox.add (row);
            listbox.show_all ();
        }
    }
}