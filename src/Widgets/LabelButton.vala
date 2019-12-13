public class Widgets.LabelButton : Gtk.ToggleButton {
    public int64 item_id { get; construct; }

    private Gtk.Popover popover = null;
    private Gtk.ListBox listbox;

    public LabelButton (int64 item_id) {
        Object (
            item_id: item_id
        );
    }

    construct {
        tooltip_text = _("Labels");

        get_style_context ().add_class ("flat");
        get_style_context ().add_class ("item-action-button");

        var label_icon = new Gtk.Image ();
        label_icon.valign = Gtk.Align.CENTER;
        label_icon.gicon = new ThemedIcon ("tag-new-symbolic");
        label_icon.pixel_size = 16;

        var label = new Gtk.Label (_("labels"));
        label.get_style_context ().add_class ("pane-item");
        label.margin_bottom = 1;
        label.use_markup = true;

        var main_grid = new Gtk.Grid ();
        main_grid.halign = Gtk.Align.CENTER;
        main_grid.valign = Gtk.Align.CENTER;
        main_grid.add (label_icon);
        //main_grid.add (label);

        add (main_grid);

        this.toggled.connect (() => {
            if (this.active) {
                if (popover == null) {
                    create_popover ();

                    Planner.database.label_added.connect ((label) => {
                        if (popover != null) {
                            var row = new Widgets.LabelPopoverRow (label);
                            listbox.add (row);
                        }
                    });
                }

                foreach (Gtk.Widget element in listbox.get_children ()) {
                    listbox.remove (element);
                }

                foreach (Objects.Label l in Planner.database.get_all_labels ()) {
                    var row = new Widgets.LabelPopoverRow (l);
                    listbox.add (row);
                }

                popover.show_all ();
            }
        });
    }

    private void create_popover () {
        popover = new Gtk.Popover (this);
        popover.position = Gtk.PositionType.RIGHT;

        listbox = new Gtk.ListBox ();
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.expand = true;
        listbox.get_style_context ().add_class ("background");

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        listbox_scrolled.expand = true;
        listbox_scrolled.add (listbox);

        var edit_icon = new Gtk.Image ();
        edit_icon.valign = Gtk.Align.CENTER;
        edit_icon.gicon = new ThemedIcon ("edit-symbolic");
        edit_icon.pixel_size = 14;

        var edit_labels = new Gtk.Button ();
        edit_labels.margin_bottom = 6;
        edit_labels.image = edit_icon;
        edit_labels.valign = Gtk.Align.CENTER;
        edit_labels.halign = Gtk.Align.START;
        edit_labels.always_show_image = true;
        edit_labels.can_focus = false;
        edit_labels.label = _("Edit labels");
        edit_labels.get_style_context ().add_class ("flat");
        edit_labels.get_style_context ().add_class ("font-bold");

        var popover_grid = new Gtk.Grid ();
        popover_grid.margin_start = 3;
        popover_grid.margin_end = 3;
        popover_grid.margin_top = 6;
        popover_grid.width_request = 235;
        popover_grid.height_request = 250;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (listbox_scrolled);
        popover_grid.add (edit_labels);

        popover.add (popover_grid);

        popover.closed.connect (() => {
            this.active = false;
        });

        edit_labels.clicked.connect (() => {
            var dialog = new Dialogs.Preferences ("labels");
            dialog.destroy.connect (Gtk.main_quit);
            dialog.show_all ();

            popover.popdown ();
        });

        listbox.row_activated.connect ((row) => {
            var label = ((Widgets.LabelPopoverRow) row).label;
            if (Planner.database.add_item_label (item_id, label)) {
                popover.popdown ();
            }
        });
    }
}

public class Widgets.LabelPopoverRow : Gtk.ListBoxRow {
    public Objects.Label label { get; construct; }

    public LabelPopoverRow (Objects.Label label) {
        Object (
            label: label
        );
    }

    construct {
        get_style_context ().add_class ("label-row");

        var label_image = new Gtk.Button.from_icon_name ("tag-symbolic");
        label_image.valign = Gtk.Align.CENTER;
        label_image.halign = Gtk.Align.CENTER;
        label_image.can_focus = false;
        label_image.get_style_context ().add_class ("label-%s".printf (label.id.to_string ()));

        var name_label = new Gtk.Label (label.name);
        name_label.get_style_context ().add_class ("h3");
        name_label.get_style_context ().add_class ("font-weight-600");
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        name_label.use_markup = true;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.margin = 3;
        box.pack_start (label_image, false, false, 0);
        box.pack_start (name_label, false, true, 0);

        add (box);

        Planner.database.label_updated.connect ((l) => {
            Idle.add (() => {
                if (label.id == l.id) {
                    name_label.label = l.name;
                }

                return false;
            });
        });

        Planner.database.label_deleted.connect ((l) => {
            if (label.id == l.id) {
                destroy ();
            }
        });
    }
}