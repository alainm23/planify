public class Widgets.ProjectPicker.ProjectPickerButton : Adw.Bin {
    public Objects.Project project { get; set; }

    private Widgets.IconColorProject icon_project;
    private Gtk.Label name_label;
    
    public signal void selected (Objects.Project project);

    construct {
        icon_project = new Widgets.IconColorProject (19);

        name_label = new Gtk.Label (null);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

        var project_box = new Gtk.Box (HORIZONTAL, 6) {
            valign = CENTER
        };
        project_box.append (icon_project);
        project_box.append (name_label);

        var project_picker_popover = new Widgets.ProjectPicker.ProjectPickerPopover ();

        var project_button = new Gtk.MenuButton () {
            popover = project_picker_popover,
            child = project_box,
            css_classes = { Granite.STYLE_CLASS_FLAT }
        };

        child = project_button;

        notify["project"].connect (() => {
            if (project != null) {
                update_project_request ();
            }
        });

        project_picker_popover.selected.connect ((_project) => {
            project = _project;
            update_project_request ();
            selected (_project);
        });
    }

    public void update_project_request () {
        name_label.label = project.is_inbox_project ? _("Inbox") : project.name;
        icon_project.project = project;
        icon_project.update_request ();
    }
}