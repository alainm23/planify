public class Widgets.LabelButton : Gtk.ToggleButton {

    public signal void on_selected_label (Objects.Label label);
    public LabelButton () {
        Object (
            valign: Gtk.Align.CENTER
        );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var label_icon = new Gtk.Image.from_icon_name ("tag-symbolic", Gtk.IconSize.MENU);
        var label_name = new Gtk.Label (_("Labels"));
        label_name.margin_bottom = 1;

        var labels_popover = new Widgets.Popovers.LabelsPopover (this);

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.pack_start (label_icon, false, false, 0);
        main_box.pack_start (label_name, false, false, 0);

        add (main_box);

        this.toggled.connect (() => {
            if (this.active) {
                labels_popover.update_label_list ();
                labels_popover.show_all ();
                labels_popover.labels_listbox.unselect_all ();
            }
        });

        labels_popover.closed.connect (() => {
            this.active = false;
        });

        labels_popover.on_selected_label.connect ((label) => {
            on_selected_label (label);
            labels_popover.popdown ();
        });
    }
}
