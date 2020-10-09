public class Widgets.CalDavList : Gtk.EventBox {
    private Gee.HashMap<E.Source, Widgets.SourceRow>? source_rows = null;
    private Gtk.ListBox listbox;

    public signal void tasklist_selected (E.Source source);
    
    construct {
        var area_image = new Gtk.Image ();
        area_image.halign = Gtk.Align.CENTER;
        area_image.valign = Gtk.Align.CENTER;
        area_image.gicon = new ThemedIcon ("folder-outline");
        area_image.pixel_size = 18;
        //  if (area.collapsed == 1) {
        //      area_image.gicon = new ThemedIcon ("folder-open-outline");
        //  }

        var name_label = new Gtk.Label (_("CalDav"));
        name_label.margin_start = 9;
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("pane-area");
        name_label.valign = Gtk.Align.CENTER;
        name_label.set_ellipsize (Pango.EllipsizeMode.END);

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin_start = 5;
        top_box.margin_top = 1;
        top_box.margin_bottom = 1;
        top_box.pack_start (area_image, false, false, 0);
        top_box.pack_start (name_label, false, true, 0);
        // top_box.pack_end (menu_stack, false, false, 0);

        var top_eventbox = new Gtk.EventBox ();
        top_eventbox.margin_start = 5;
        top_eventbox.margin_end = 5;
        top_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        top_eventbox.add (top_box);
        top_eventbox.get_style_context ().add_class ("toogle-box");

        listbox = new Gtk.ListBox ();
        listbox.get_style_context ().add_class ("pane");
        listbox.activate_on_single_click = true;
        listbox.margin_top = 3;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        var listbox_revealer = new Gtk.Revealer ();
        listbox_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        listbox_revealer.add (listbox);
        listbox_revealer.reveal_child = true;

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (top_eventbox);
        grid.add (listbox_revealer);

        add (grid);

        Planner.task_store.task_list_added.connect (add_source);
        Planner.task_store.task_list_modified.connect (update_source);
        Planner.task_store.task_list_removed.connect (remove_source);
        Planner.task_store.get_registry.begin ((obj, res) => {
            E.SourceRegistry registry;
            try {
                registry = Planner.task_store.get_registry.end (res);
            } catch (Error e) {
                critical (e.message);
                return;
            }

            // listbox.set_header_func (header_update_func);
            
            var task_lists = registry.list_sources (E.SOURCE_EXTENSION_TASK_LIST);
            task_lists.foreach ((source) => {
                E.SourceTaskList list = (E.SourceTaskList)source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);
                if (list.selected == true && source.enabled == true) {
                    add_source (source);
                }
            });
        });

        listbox.row_selected.connect ((row) => {
            if (row != null) {
                var source = ((Widgets.SourceRow) row).source;
                tasklist_selected (source);
            }
        });
    }

    private void add_source (E.Source source) {
        if (source_rows == null) {
            source_rows = new Gee.HashMap<E.Source, Widgets.SourceRow> ();
        }

        debug ("Adding row '%s'", source.dup_display_name ());
        if (!source_rows.has_key (source)) {
            source_rows[source] = new Widgets.SourceRow (source);

            listbox.add (source_rows[source]);
            listbox.show_all ();
        }
    }

    private void update_source (E.Source source) {
        E.SourceTaskList list = (E.SourceTaskList)source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);

        if (list.selected != true || source.enabled != true) {
            remove_source (source);

        } else if (!source_rows.has_key (source)) {
            add_source (source);
        }
    }

    public void unselect_all () {
        listbox.unselect_all ();
    }

    private void remove_source (E.Source source) {
        listbox.unselect_row (source_rows[source]);
        source_rows[source].remove_request ();
        source_rows.unset (source);
    }

    private void header_update_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
        if (!(lbrow is Widgets.SourceRow)) {
            return;
        }
        var row = (Widgets.SourceRow) lbrow;
        if (lbbefore != null && lbbefore is Widgets.SourceRow) {
            var before = (Widgets.SourceRow) lbbefore;
            if (row.source.parent == before.source.parent) {
                return;
            }
        }

        E.SourceRegistry registry;
        try {
            registry = Planner.task_store.get_registry_sync ();
        } catch (Error e) {
            warning (e.message);
            return;
        }
        string display_name;

        var ancestor = registry.find_extension (row.source, E.SOURCE_EXTENSION_COLLECTION);
        if (ancestor != null) {
            display_name = ancestor.display_name;
        } else {
            display_name = ((E.SourceTaskList?) row.source.get_extension (E.SOURCE_EXTENSION_TASK_LIST)).backend_name;
        }

        var header_label = new Granite.HeaderLabel (display_name);
        header_label.ellipsize = Pango.EllipsizeMode.MIDDLE;
        header_label.margin_start = 6;

        row.set_header (header_label);
    }
}
