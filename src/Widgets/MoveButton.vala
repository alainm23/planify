public class Widgets.MoveButton : Gtk.ToggleButton {
    private Widgets.Popovers.MovePopover move_popover;

    public signal void on_selected_project (bool is_inbox = false, Objects.Project project = null);
    public MoveButton () {
        Object (
            valign: Gtk.Align.CENTER
        );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var move_label = new Gtk.Label (_("Move"));
        var move_icon = new Gtk.Image.from_icon_name ("pan-end-symbolic", Gtk.IconSize.MENU);
        move_icon.yalign = 0.9f;

        move_popover = new Widgets.Popovers.MovePopover (this);

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.pack_start (move_label, false, false, 0);
        main_box.pack_start (move_icon, false, false, 0);

        add (main_box);

        this.toggled.connect (() => {
          if (this.active) {
            move_popover.show_all ();
          }
        });

        move_popover.closed.connect (() => {
            this.active = false;
        });

        move_popover.on_selected_project.connect ((is_inbox, project) => {
            on_selected_project (is_inbox, project);
        });
    }
}
