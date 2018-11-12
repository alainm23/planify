public class Views.Project : Gtk.EventBox {
    public MainWindow window { get; construct; }
    public Objects.Project project;

    private Gtk.Label project_name;

    private Widgets.TaskNew task_new_revealer;
    private Gtk.ListBox tasks_list;
    private Gtk.Button add_task_button;
    private Gtk.Revealer add_task_revealer;
    private Gtk.InfoBar infobar;
    private Gtk.Label infobar_label;
    private Gtk.FlowBox labels_flowbox;

    private Widgets.Popovers.LabelsPopover labels_popover;
    private Granite.Widgets.Toast notification_toast;
    public Project () {
        Object (
            expand: true
        );
    }

    construct {
        get_style_context ().add_class (Granite.STYLE_CLASS_WELCOME);

        project_name = new Gtk.Label (null);
        project_name.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        project_name.use_markup = true;

        var paste_button = new Gtk.Button.from_icon_name ("planner-paste-symbolic", Gtk.IconSize.MENU);
        paste_button.get_style_context ().add_class ("planner-paste-menu");
        paste_button.tooltip_text = _("Paste");
        paste_button.valign = Gtk.Align.CENTER;
        paste_button.halign = Gtk.Align.CENTER;

        var labels_button = new Gtk.Button.from_icon_name ("planner-label-symbolic", Gtk.IconSize.MENU);
        labels_button.get_style_context ().add_class ("planner-label-menu");
        labels_button.tooltip_text = _("Filter by Label");
        labels_button.valign = Gtk.Align.CENTER;
        labels_button.halign = Gtk.Align.CENTER;

        labels_popover = new Widgets.Popovers.LabelsPopover (labels_button);
        labels_popover.position = Gtk.PositionType.BOTTOM;

        var share_button = new Gtk.Button.from_icon_name ("planner-share-symbolic", Gtk.IconSize.MENU);
        share_button.get_style_context ().add_class ("planner-share-menu");
        share_button.tooltip_text = _("Share");
        share_button.valign = Gtk.Align.CENTER;
        share_button.halign = Gtk.Align.CENTER;

        var action_grid = new Gtk.Grid ();
        action_grid.column_spacing = 12;

        action_grid.add (labels_button);
        action_grid.add (paste_button);
        action_grid.add (share_button);

        var action_revealer = new Gtk.Revealer ();
        action_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        action_revealer.add (action_grid);

        var settings_button = new Gtk.ToggleButton ();
		settings_button.active = true;
        settings_button.valign = Gtk.Align.START;
		settings_button.get_style_context ().add_class ("show-settings-button");
        settings_button.get_style_context ().add_class ("button-circular");
        settings_button.get_style_context ().remove_class ("button");
		settings_button.add (new Gtk.Image.from_icon_name ("pan-start-symbolic", Gtk.IconSize.MENU));

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.valign = Gtk.Align.START;
        top_box.hexpand = true;
        top_box.margin_start = 24;
        top_box.margin_end = 16;
        top_box.margin_top = 24;

        top_box.pack_start (project_name, false, false, 12);
        top_box.pack_end (settings_button, false, false, 12);
        top_box.pack_end (action_revealer, false, false, 0);

        add (top_box);

        // Signals
        settings_button.toggled.connect (() => {
            if (action_revealer.reveal_child) {
                settings_button.get_style_context ().remove_class ("closed");
                action_revealer.reveal_child = false;
            } else {
                action_revealer.reveal_child = true;
                settings_button.get_style_context ().add_class ("closed");
            }
        });
    }

    public void set_project (Objects.Project _project) {
        project = _project;

        project_name.label = "<b>%s</b>".printf (project.name);

        show_all ();
    }
}
