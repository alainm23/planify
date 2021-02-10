public class Plugins.LabelPaneRow : Gtk.ListBoxRow {
    public Objects.Label label { get; construct; }
    private Gtk.Label count_label;
    private Gtk.Revealer count_revealer;
    private Gtk.EventBox handle;
    private Gtk.Revealer main_revealer;
    private Gtk.Revealer motion_revealer;
    private Gtk.Revealer first_motion_revealer;

    private const Gtk.TargetEntry[] TARGET_ENTRIES = {
        {"LABELROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public LabelPaneRow (Objects.Label label) {
        Object (
            label: label
        );
    }

    construct {
        margin_start = 6;
        margin_top = 2;
        margin_end = 3;
        get_style_context ().add_class ("label-row");
        get_style_context ().add_class ("transparent");

        var color_image = new Gtk.Image.from_icon_name ("tag-symbolic", Gtk.IconSize.MENU);
        color_image.valign = Gtk.Align.CENTER;
        color_image.halign = Gtk.Align.CENTER;
        color_image.can_focus = false;
        color_image.get_style_context ().add_class ("label-%s".printf (label.id.to_string ()));

        var name_label = new Gtk.Label (label.name);
        name_label.halign = Gtk.Align.START;
        name_label.valign = Gtk.Align.CENTER;
        name_label.margin_start = 1;
        name_label.set_ellipsize (Pango.EllipsizeMode.END);

        count_label = new Gtk.Label (null);
        count_label.label = "<small>%i</small>".printf (8);
        count_label.valign = Gtk.Align.CENTER;
        count_label.opacity = 0.7;
        count_label.use_markup = true;
        count_label.width_chars = 3;

        count_revealer = new Gtk.Revealer ();
        count_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        count_revealer.add (count_label);

        var source_icon = new Gtk.Image ();
        source_icon.pixel_size = 14;
        source_icon.gicon = new ThemedIcon ("planner-online-symbolic");
        source_icon.tooltip_text = _("Todoist Label");

        var source_revealer = new Gtk.Revealer ();
        source_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        source_revealer.add (source_icon);

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        main_box.margin_start = 3;
        main_box.margin_end = 3;
        main_box.margin_bottom = 5;
        main_box.margin_top = 5;
        main_box.hexpand = true;
        main_box.pack_start (color_image, false, false, 0);
        main_box.pack_start (name_label, false, true, 0);
        if (label.is_todoist == 1) {
            main_box.pack_start (source_revealer, false, false, 0);   
        }
        main_box.pack_end (count_revealer, false, true, 0);

        var motion_grid = new Gtk.Grid ();
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;
        motion_grid.margin_top = 6;

        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        var first_motion_grid = new Gtk.Grid ();
        first_motion_grid.get_style_context ().add_class ("grid-motion");
        first_motion_grid.height_request = 24;
        first_motion_grid.hexpand = true;
        first_motion_grid.margin_bottom = 6;
        first_motion_grid.margin_top = 6;

        first_motion_revealer = new Gtk.Revealer ();
        first_motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        first_motion_revealer.add (first_motion_grid);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (first_motion_revealer);
        grid.add (main_box);
        grid.add (motion_revealer);

        handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.hexpand = true;
        handle.above_child = false;
        handle.add (grid);

        main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = true;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (handle);

        add (main_revealer);
        update_count ();
        build_drag_and_drop ();

        handle.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                Planner.event_bus.pane_selected (PaneType.LABEL, label.id.to_string ());
                return false;
            }

            return false;
        });

        handle.enter_notify_event.connect ((event) => {
            source_revealer.reveal_child = true;
        });

        handle.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            source_revealer.reveal_child = false;
        });

        Planner.event_bus.pane_selected.connect ((pane_type, id) => {
            if (pane_type == PaneType.LABEL && label.id.to_string () == id) {
                handle.get_style_context ().add_class ("project-selected");
            } else {
                handle.get_style_context ().remove_class ("project-selected");
            }
        });

        Planner.database.label_updated.connect ((l) => {
            Idle.add (() => {
                if (label.id == l.id) {
                    name_label.label = l.name;
                }

                return false;
            });
        });

        Planner.database.label_deleted.connect ((id) => {
            if (label.id == id) {
                main_revealer.reveal_child = false;

                Timeout.add (500, () => {
                    destroy ();
                    return false;
                });
            }
        });

        Planner.database.item_label_added.connect ((id, item_id, l) => {
            if (label.id == l.id) {
                update_count ();
            }
        });

        Planner.database.item_label_deleted.connect ((id, item_id, l) => {
            if (label.id == l.id) {
                update_count ();
            }
        });
    }

    private void update_count () {
        var count = Planner.database.get_items_by_label (label.id).size;
        count_label.label = "<small>%i</small>".printf (count);

        if (count <= 0) {
            count_revealer.reveal_child = false;
        } else {
            count_revealer.reveal_child = true;
        }
    }

    private void build_drag_and_drop () {
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);
        drag_end.connect (clear_indicator);

        Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);
        drag_end.connect (clear_indicator);
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = ((Plugins.LabelPaneRow) widget).handle;

        Gtk.Allocation alloc;
        row.get_allocation (out alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr = new Cairo.Context (surface);
        cr.set_source_rgba (0, 0, 0, 0);
        cr.set_line_width (1);

        cr.move_to (0, 0);
        cr.line_to (alloc.width, 0);
        cr.line_to (alloc.width, alloc.height);
        cr.line_to (0, alloc.height);
        cr.line_to (0, 0);
        cr.stroke ();

        cr.set_source_rgba (255, 255, 255, 0);
        cr.rectangle (0, 0, alloc.width, alloc.height);
        cr.fill ();

        row.get_style_context ().add_class ("drag-begin");
        row.draw (cr);
        row.get_style_context ().remove_class ("drag-begin");

        Gtk.drag_set_icon_surface (context, surface);
        main_revealer.reveal_child = false;
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (Plugins.LabelPaneRow))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("LABELROW"), 32, data
        );
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        Gtk.Allocation alloc;
        handle.get_allocation (out alloc);
        
        if (get_index () == 0) {
            if (y > (alloc.height / 2)) {
                motion_revealer.reveal_child = true;
                first_motion_revealer.reveal_child = false;
            } else {
                first_motion_revealer.reveal_child = true;
                motion_revealer.reveal_child = false;
            }
        } else {
            motion_revealer.reveal_child = true;
        }

        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        motion_revealer.reveal_child = false;
        first_motion_revealer.reveal_child = false;
    }

    public void clear_indicator (Gdk.DragContext context) {
        main_revealer.reveal_child = true;
    }
}
