public class Widgets.QuickFind : Gtk.Revealer {
    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox listbox;

    public bool reveal {
        set {
            if (value) {
                reveal_child = true;
                search_entry.grab_focus ();
            } else {
                reveal_child = false;
            }
        }
    }

    public QuickFind () {
        transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        //transition_duration = 125;
        valign = Gtk.Align.START;
        halign = Gtk.Align.CENTER;
    }

    construct {
        search_entry = new Gtk.SearchEntry ();
        search_entry.hexpand = true;

        var cancel_button = new Gtk.Button.with_label (_("Close"));
        cancel_button.margin_start = 6;
        cancel_button.get_style_context ().add_class ("flat");
        cancel_button.get_style_context ().add_class ("font-bold");
        cancel_button.get_style_context ().add_class ("no-padding");

        var cancel_revealer = new Gtk.Revealer ();
        cancel_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        cancel_revealer.add (cancel_button);

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.margin = 6;
        top_box.hexpand = true;
        top_box.pack_start (search_entry, false, true, 0);
        top_box.pack_start (cancel_revealer, false, false, 0);

        listbox = new Gtk.ListBox ();
        listbox.get_style_context ().add_class ("background");
        listbox.hexpand = true;

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        listbox_scrolled.margin_bottom = 6;
        listbox_scrolled.height_request = 250;
        listbox_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        listbox_scrolled.expand = true;
        listbox_scrolled.add (listbox);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        //box.margin_top = 24;
        box.width_request = 350;
        box.get_style_context ().add_class ("quick-find");
        box.pack_start (top_box, false, false, 0);
        //box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);
        box.pack_start (listbox_scrolled, false, false, 0);
        
        var eventbox = new Gtk.EventBox ();
        eventbox.add (box);

        add (eventbox);

        search_entry.search_changed.connect (() => {
            listbox.foreach ((widget) => {
                widget.destroy ();
            });

            if (search_entry.text != "") {
                cancel_revealer.reveal_child = true;
                foreach (var item in Planner.database.get_items_by_search (search_entry.text)) {
                    var row = new Widgets.SearchItem (
                        item.content,
                        "checkbox-symbolic",
                        "item",
                        item.id,
                        item.project_id
                    );
                    
                    listbox.add (row);
                    listbox.show_all ();
                }

                foreach (var project in Planner.database.get_all_projects_by_search (search_entry.text)) {
                    var row = new Widgets.SearchItem (
                        project.name,
                        "planner-project-symbolic",
                        "project",
                        project.id
                    );
                    
                    listbox.add (row);
                    listbox.show_all ();
                }
            } else {
                cancel_revealer.reveal_child = false;
            }
        });

        search_entry.focus_out_event.connect (() => {
            if (search_entry.text == "") {
                cancel ();
            }

            return false;
        });

        search_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                cancel ();
            }

            return false;
        });

        search_entry.icon_press.connect ((icon_pos, event) => {
            if (icon_pos == Gtk.EntryIconPosition.SECONDARY) {
                search_entry.grab_focus ();
            }
        });

        cancel_button.clicked.connect (() => {
            cancel ();
        });

        eventbox.key_press_event.connect ((event) => {
            var key = Gdk.keyval_name (event.keyval).replace ("KP_", "");

            if (key == "Up" || key == "Down") {
                return false;
            } else if (key == "Enter" || key == "Return" || key == "KP_Enter") {
                var item = (Widgets.SearchItem) listbox.get_selected_row ();

                if (item.element == "item") {
                    Planner.instance.go_view ("item", item.id, item.project_id);
                } else if (item.element == "project") {
                    Planner.instance.go_view ("project", item.id, 0);
                }

                cancel ();
                return false;
            } else {
                if (!search_entry.has_focus) {
                    search_entry.grab_focus ();
                    search_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, 0, false);
                    search_entry.key_press_event (event);
                }

                return false;
            }

            return true;
        });

        listbox.row_activated.connect ((row) => {
            var item = (Widgets.SearchItem) row;

            if (item.element == "item") {
                Planner.instance.go_view ("item", item.id, item.project_id);
            } else if (item.element == "project") {
                Planner.instance.go_view ("project", item.id, 0);
            }

            cancel ();
        });
    }

    public void reveal_toggled () {
        if (reveal_child) {
            cancel ();
        } else {
            reveal_child = true;
            search_entry.grab_focus ();
        }
    }

    public void cancel () {
        search_entry.text = "";

        reveal_child = false;
        listbox.foreach ((widget) => {
            widget.destroy ();
        });
    }
}

public class Widgets.SearchItem : Gtk.ListBoxRow {
    public string title { get; construct; }
    public int64 id { get; construct; }
    public int64 project_id { get; construct; }
    public string icon { get; construct; }
    public string element { get; construct; }

    public SearchItem (string title, string icon, string element, int64 id, int64 project_id=0) {
        Object (
            title: title,
            icon: icon,
            element: element,
            id: id,
            project_id: project_id
        );
    }

    construct {
        margin_start = margin_end = 6;
        get_style_context ().add_class ("pane-row");
        
        var image = new Gtk.Image ();
        image.gicon = new ThemedIcon (icon);
        image.pixel_size = 16;

        var title_label = new Gtk.Label (title);
        //title_label.get_style_context ().add_class ("h3");
        title_label.ellipsize = Pango.EllipsizeMode.END;
        //title_label.use_markup = true;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.hexpand = true;
        box.margin = 6;
        box.pack_start (image, false, false, 0);
        box.pack_start (title_label, false, false, 0);

        add (box);
    }
}