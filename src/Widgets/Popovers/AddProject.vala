public class Widgets.Popovers.AddProject : Gtk.Popover {
    private Gtk.Entry name_entry;
    private Gtk.Button add_button;
    private Gtk.Entry color_hex_entry;

    private Granite.Widgets.DatePicker duedate_datepicker;
    private Gtk.Switch duedate_switch;

    private Gtk.Revealer datepicker_revealer;
    private Gtk.Revealer color_hex_revealer;

    public signal void on_add_project_signal ();
    public AddProject (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.TOP
        );
    }

    construct {
        var title_label = new Gtk.Label ("<small>%s</small>".printf (_("New Project")));
        title_label.use_markup = true;
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        name_entry = new Gtk.Entry ();
        name_entry.hexpand = true;
        name_entry.max_length = 50;
        name_entry.margin_bottom = 12;
        name_entry.placeholder_text = _("Personal");

        var color_1 = new Gtk.Button ();
        color_1.valign = Gtk.Align.CENTER;
        color_1.halign = Gtk.Align.CENTER;
        color_1.height_request = 24;
        color_1.width_request = 24;
        color_1.get_style_context ().add_class ("color-button");
        color_1.get_style_context ().add_class ("color-1");

        var color_2 = new Gtk.Button ();
        color_2.valign = Gtk.Align.CENTER;
        color_2.halign = Gtk.Align.CENTER;
        color_2.height_request = 24;
        color_2.width_request = 24;
        color_2.get_style_context ().add_class ("color-button");
        color_2.get_style_context ().add_class ("color-2");

        var color_3 = new Gtk.Button ();
        color_3.valign = Gtk.Align.CENTER;
        color_3.halign = Gtk.Align.CENTER;
        color_3.height_request = 24;
        color_3.width_request = 24;
        color_3.get_style_context ().add_class ("color-button");
        color_3.get_style_context ().add_class ("color-3");

        var color_4 = new Gtk.Button ();
        color_4.valign = Gtk.Align.CENTER;
        color_4.halign = Gtk.Align.CENTER;
        color_4.height_request = 24;
        color_4.width_request = 24;
        color_4.get_style_context ().add_class ("color-button");
        color_4.get_style_context ().add_class ("color-4");

        var color_5 = new Gtk.Button ();
        color_5.valign = Gtk.Align.CENTER;
        color_5.halign = Gtk.Align.CENTER;
        color_5.height_request = 24;
        color_5.width_request = 24;
        color_5.get_style_context ().add_class ("color-button");
        color_5.get_style_context ().add_class ("color-5");

        var color_6 = new Gtk.Button ();
        color_6.valign = Gtk.Align.CENTER;
        color_6.halign = Gtk.Align.CENTER;
        color_6.height_request = 24;
        color_6.width_request = 24;
        color_6.get_style_context ().add_class ("color-button");
        color_6.get_style_context ().add_class ("color-6");

        var color_7 = new Gtk.Button ();
        color_7.valign = Gtk.Align.CENTER;
        color_7.halign = Gtk.Align.CENTER;
        color_7.height_request = 24;
        color_7.width_request = 24;
        color_7.get_style_context ().add_class ("color-button");
        color_7.get_style_context ().add_class ("color-7");


        var color_n = new Gtk.ToggleButton ();
        color_n.valign = Gtk.Align.CENTER;
        color_n.halign = Gtk.Align.CENTER;
        color_n.height_request = 24;
        color_n.width_request = 24;

        var hex_label = new Gtk.Label ("<b>#</b>");
        hex_label.use_markup = true;
        color_n.add (hex_label);
        color_n.get_style_context ().add_class ("color-n");

        var color_box = new Gtk.Grid ();
        color_box.column_homogeneous = true;
        color_box.margin_bottom = 6;
        color_box.column_spacing = 3;

        color_box.add (color_1);
        color_box.add (color_2);
        color_box.add (color_3);
        color_box.add (color_4);
        color_box.add  (color_5);
        color_box.add (color_6);
        color_box.add (color_7);
        color_box.add (color_n);

        color_hex_entry = new Gtk.Entry ();
        color_hex_entry.hexpand = true;
        color_hex_entry.placeholder_text = "#7239b3";
        color_hex_entry.max_length = 7;

        var color_button  = new Gtk.ColorButton ();
        color_button.valign = Gtk.Align.START;


        var color_grid = new Gtk.Grid ();
        color_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        color_grid.add (color_hex_entry);
        color_grid.add (color_button);

        color_hex_revealer = new Gtk.Revealer ();
        color_hex_revealer.margin_top = 6;
        color_hex_revealer.add (color_grid);
        color_hex_revealer.reveal_child = false;

        var duedate_label = new Granite.HeaderLabel (_("Deadline"));
        duedate_label.margin_top = 6;

        duedate_switch = new Gtk.Switch ();
        duedate_switch.get_style_context ().add_class ("active-switch");
        duedate_switch.valign = Gtk.Align.CENTER;

        var duedate_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        duedate_box.pack_start (duedate_label, false, false, 0);
        duedate_box.pack_end (duedate_switch, false, false, 0);

        duedate_datepicker = new Granite.Widgets.DatePicker ();

        datepicker_revealer = new Gtk.Revealer ();
        datepicker_revealer.reveal_child = false;
        datepicker_revealer.add (duedate_datepicker);

        add_button = new Gtk.Button.with_label (_("Create"));
        add_button.tooltip_text = _("Create a new project");
        add_button.margin_top = 12;
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        add_button.sensitive = false;

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.margin = 12;
        main_grid.margin_top = 0;
        main_grid.expand = true;
        main_grid.width_request = 224;

        main_grid.add (title_label);
        main_grid.add (new Granite.HeaderLabel (_("Name")));
        main_grid.add (name_entry);
        main_grid.add (new Granite.HeaderLabel (_("Color")));
        main_grid.add (color_box);
        main_grid.add (color_hex_revealer);
        main_grid.add (duedate_box);
        main_grid.add (datepicker_revealer);
        main_grid.add (add_button);

        add (main_grid);
        name_entry.grab_focus ();

        // Events
        name_entry.changed.connect (() => {
            if (name_entry.text != "") {
                add_button.sensitive = true;
            } else {
                add_button.sensitive = false;
            }
        });

        name_entry.activate.connect (() => {
            if (name_entry.text != "") {
                on_click_add_project ();
            }
        });

        add_button.clicked.connect (on_click_add_project);

        color_n.clicked.connect (() => {
            if (color_hex_revealer.reveal_child) {
                color_hex_revealer.reveal_child = false;
            } else {
                color_hex_revealer.reveal_child = true;
            }
        });

        color_1.clicked.connect (() => {
            color_hex_entry.text = "#c6262e";
        });

        color_2.clicked.connect (() => {
            color_hex_entry.text = "#f37329";
        });

        color_3.clicked.connect (() => {
            color_hex_entry.text = "#f9c440";
        });

        color_4.clicked.connect (() => {
            color_hex_entry.text = "#68b723";
        });

        color_5.clicked.connect (() => {
            color_hex_entry.text = "#3689e6";
        });

        color_6.clicked.connect (() => {
            color_hex_entry.text = "#a56de2";
        });

        color_7.clicked.connect (() => {
            color_hex_entry.text = "#333333";
        });

        duedate_switch.notify["active"].connect(() => {
            if (duedate_switch.active) {
                datepicker_revealer.reveal_child = true;
            } else {
                datepicker_revealer.reveal_child = false;
            }
        });

        color_button.color_set.connect (() => {
            color_hex_entry.text = Planner.utils.rgb_to_hex_string (color_button.rgba);
        });

        color_hex_entry.changed.connect (() => {
            var rgba = Gdk.RGBA ();
            if (rgba.parse (color_hex_entry.text)) {
                color_button.rgba = rgba;
                if (name_entry.text != "") {
                    add_button.sensitive = true;
                }
            } else {
                add_button.sensitive = false;
            }
        });
    }

    private void on_click_add_project () {
        var project = new Objects.Project ();

        if (color_hex_entry.text == "") {
            color_hex_entry.text = "#3689e6";
        }

        if (duedate_switch.active) {
            project.deadline = duedate_datepicker.date.format ("%F");
        } else {
            project.deadline = "";
        }

        project.name = name_entry.text;
        project.color = color_hex_entry.text;

        if (Planner.database.add_project (project) == Sqlite.DONE) {
            on_add_project_signal ();
            popdown ();

            name_entry.text = "";
            color_hex_entry.text = "";
            duedate_switch.active = false;
        }
    }
}
