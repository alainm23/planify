public class Views.Project : Gtk.EventBox {
    public Objects.Project project { get; set; }

    private const Gtk.TargetEntry[] targetEntries = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private Gtk.ListBox listbox;
    construct {
        var grid_color = new Gtk.Grid ();
        grid_color.set_size_request (16, 16);
        grid_color.valign = Gtk.Align.CENTER;
        grid_color.halign = Gtk.Align.CENTER;

        var name_label = new Gtk.Label (null);//"<b>%s</b>".printf (_("Inbox")));
        name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        name_label.get_style_context ().add_class ("font-bold");
        name_label.use_markup = true;

        var settings_button = new Gtk.MenuButton ();
        settings_button.valign = Gtk.Align.CENTER;
        //settings_button.tooltip_text = _("Edit Name and Appearance");
        //settings_button.popover = list_settings_popover;
        settings_button.image = new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.MENU);
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_start = 36;
        top_box.margin_end = 24;

        top_box.pack_start (grid_color, false, false, 0);
        top_box.pack_start (name_label, false, false, 0);
        top_box.pack_end (settings_button, false, false, 0);

        listbox = new Gtk.ListBox  ();
        listbox.valign = Gtk.Align.START;
        listbox.margin_top = 12;
        listbox.get_style_context ().add_class ("welcome");
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        var new_item_widget = new Widgets.NewItem (project.id);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (listbox, false, false, 3);
        main_box.pack_start (new_item_widget, false, false, 0);
        
        var main_scrolled = new Gtk.ScrolledWindow (null, null);
        main_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        main_scrolled.width_request = 246;
        main_scrolled.expand = true;
        main_scrolled.add (main_box);

        add (main_scrolled);

        build_drag_and_drop ();

        notify["project"].connect (() => {
            if (project != null) {
                name_label.label = project.name;

                bool is_todoist = false;

                if (project.is_todoist == 1) {
                    is_todoist = true;
                }

                new_item_widget.project_id = project.id;
                new_item_widget.is_todoist = is_todoist;

                grid_color.get_style_context ().list_classes ().foreach ((c) => {
                    if (c != "horizontal") {
                        grid_color.get_style_context ().remove_class (c);
                    }
                });

                grid_color.get_style_context ().add_class ("project-%s".printf (project.id.to_string ()));

                apply_styles (Application.utils.get_color (project.color));

                add_all_items (project.id);
            } else {
                name_label.label = "";
                new_item_widget.project_id = 0;
            }

            show_all ();
        });

        listbox.row_activated.connect ((row) => {
            var item = ((Widgets.ItemRow) row);
            item.reveal_child = true;
        });

        Application.database.item_added.connect (item => {
            if (item.project_id == project.id && item.header_id == 0) {
                var row = new Widgets.ItemRow (item);
                listbox.add (row);
                listbox.show_all ();
            }
        });

        Application.database.project_updated.connect ((p) => {
            if (project != null && p.id == project.id) {
                project = p;
            }
        });
    }

    private void apply_styles (string color) {
        string COLOR_CSS = """
            .project-color-%s {
                color: %s
            }
        """;

        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (
                project.id.to_string (),
                color
            );

            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }

    private void add_all_items (int64 project_id) {
        listbox.foreach ((widget) => {
            widget.destroy (); 
        });

        var all_items = Application.database.get_all_items_by_project (project_id);

        foreach (var item in all_items) {
            var row = new Widgets.ItemRow (item);
            listbox.add (row);
            listbox.show_all ();
        }
    }

    private void build_drag_and_drop () {
        Gtk.drag_dest_set (listbox, Gtk.DestDefaults.ALL, targetEntries, Gdk.DragAction.MOVE);
        listbox.drag_data_received.connect (on_drag_data_received);
    }

    private void on_drag_data_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.ItemRow target;
        Widgets.ItemRow source;
        Gtk.Allocation alloc;

        target = (Widgets.ItemRow) listbox.get_row_at_y (y);
        target.get_allocation (out alloc);
        
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        if (target != null) {        
            if (target.get_index () != source.get_index ()) {
                source.get_parent ().remove (source); 
                listbox.insert (source, target.get_index ());
                listbox.show_all ();

                update_item_order ();
            }   
        } else {
            source.get_parent ().remove (source); 
            listbox.insert (source, (int) listbox.get_children ().length);
            listbox.show_all ();
    
            update_item_order ();
        }
    }

    private void update_item_order () {
        listbox.foreach ((widget) => {
            var row = (Gtk.ListBoxRow) widget;
            int index = row.get_index ();

            var item = ((Widgets.ItemRow) row).item;

            new Thread<void*> ("update_item_order", () => {
                Application.database.update_item_order (item.id, index);

                return null;
            });
        });
    }
}