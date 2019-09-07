public class Widgets.Popovers.ProjectSettings : Gtk.Popover {
    public Objects.Project project { get; set; }

    private Gtk.Entry name_entry;

    construct {
        var name_label = new Granite.HeaderLabel (_("Name:"));

        name_entry = new Gtk.Entry ();

        var color_label = new Granite.HeaderLabel (_("Color:"));

        var color_30 = new Gtk.RadioButton (null);
        color_30.valign = Gtk.Align.START;
        color_30.halign = Gtk.Align.START;
        Application.utils.apply_styles ("30", "#b8255f", color_30);

        var color_31 = new Gtk.RadioButton.from_widget (color_30);
        color_31.valign = Gtk.Align.START;
        color_31.halign = Gtk.Align.START;
        Application.utils.apply_styles ("31", "#db4035", color_31);

        var color_32 = new Gtk.RadioButton.from_widget (color_30);
        color_32.valign = Gtk.Align.START;
        color_32.halign = Gtk.Align.START;
        Application.utils.apply_styles ("32", "#ff9933", color_32);

        var color_33 = new Gtk.RadioButton.from_widget (color_30);
        color_33.valign = Gtk.Align.START;
        color_33.halign = Gtk.Align.START;
        Application.utils.apply_styles ("33", "#fad000", color_33);

        var color_34 = new Gtk.RadioButton.from_widget (color_30);
        color_34.valign = Gtk.Align.START;
        color_34.halign = Gtk.Align.START;
        Application.utils.apply_styles ("34", "#afb83b", color_34);

        var color_35 = new Gtk.RadioButton.from_widget (color_30);
        color_35.valign = Gtk.Align.START;
        color_35.halign = Gtk.Align.START;
        Application.utils.apply_styles ("35", "#7ecc49", color_35);

        var color_36 = new Gtk.RadioButton.from_widget (color_30);
        color_36.valign = Gtk.Align.START;
        color_36.halign = Gtk.Align.START;
        Application.utils.apply_styles ("36", "#299438", color_36);

        var color_37 = new Gtk.RadioButton.from_widget (color_30);
        color_37.valign = Gtk.Align.START;
        color_37.halign = Gtk.Align.START;
        Application.utils.apply_styles ("37", "#6accbc", color_37);

        var color_38 = new Gtk.RadioButton.from_widget (color_30);
        color_38.valign = Gtk.Align.START;
        color_38.halign = Gtk.Align.START;
        Application.utils.apply_styles ("38", "#158fad", color_38);

        var color_39 = new Gtk.RadioButton.from_widget (color_30);
        color_39.valign = Gtk.Align.START;
        color_39.halign = Gtk.Align.START;
        Application.utils.apply_styles ("39", "#14aaf5", color_39);

        var color_40 = new Gtk.RadioButton.from_widget (color_30);
        color_40.valign = Gtk.Align.START;
        color_40.halign = Gtk.Align.START;
        Application.utils.apply_styles ("40", "#96c3eb", color_40);

        var color_41 = new Gtk.RadioButton.from_widget (color_30);
        color_41.valign = Gtk.Align.START;
        color_41.halign = Gtk.Align.START;
        Application.utils.apply_styles ("41", "#4073ff", color_41);

        var color_42 = new Gtk.RadioButton.from_widget (color_30);
        color_42.valign = Gtk.Align.START;
        color_42.halign = Gtk.Align.START;
        Application.utils.apply_styles ("42", "#884dff", color_42);

        var color_43 = new Gtk.RadioButton.from_widget (color_30);
        color_43.valign = Gtk.Align.START;
        color_43.halign = Gtk.Align.START;
        Application.utils.apply_styles ("43", "#af38eb", color_43);

        var color_44 = new Gtk.RadioButton.from_widget (color_30);
        color_44.valign = Gtk.Align.START;
        color_44.halign = Gtk.Align.START;
        Application.utils.apply_styles ("44", "#eb96eb", color_44);

        var color_45 = new Gtk.RadioButton.from_widget (color_30);
        color_45.valign = Gtk.Align.START;
        color_45.halign = Gtk.Align.START;
        Application.utils.apply_styles ("45", "#e05194", color_45);
        
        var color_46 = new Gtk.RadioButton.from_widget (color_30);
        color_46.valign = Gtk.Align.START;
        color_46.halign = Gtk.Align.START;
        Application.utils.apply_styles ("46", "#ff8d85", color_46);

        var color_47 = new Gtk.RadioButton.from_widget (color_30);
        color_47.valign = Gtk.Align.START;
        color_47.halign = Gtk.Align.START;
        Application.utils.apply_styles ("47", "#808080", color_47);

        var color_48 = new Gtk.RadioButton.from_widget (color_30);
        color_48.valign = Gtk.Align.START;
        color_48.halign = Gtk.Align.START;
        Application.utils.apply_styles ("48", "#b8b8b8", color_48);

        var color_49 = new Gtk.RadioButton.from_widget (color_30);
        color_49.valign = Gtk.Align.START;
        color_49.halign = Gtk.Align.START;
        Application.utils.apply_styles ("49", "#ccac93", color_49);

        var color_box = new Gtk.Grid ();
        color_box.column_homogeneous = true;
        color_box.row_homogeneous = true;
        color_box.row_spacing = 9;
        color_box.column_spacing = 12;

        color_box.attach (color_30, 0, 0, 1, 1);
        color_box.attach (color_31, 1, 0, 1, 1);
        color_box.attach (color_32, 2, 0, 1, 1);
        color_box.attach (color_33, 3, 0, 1, 1);
        color_box.attach (color_34, 4, 0, 1, 1);
        color_box.attach (color_35, 5, 0, 1, 1);
        color_box.attach (color_36, 6, 0, 1, 1);
        color_box.attach (color_37, 0, 1, 1, 1);
        color_box.attach (color_38, 1, 1, 1, 1);
        color_box.attach (color_39, 2, 1, 1, 1);
        color_box.attach (color_40, 3, 1, 1, 1);
        color_box.attach (color_41, 4, 1, 1, 1);
        color_box.attach (color_42, 5, 1, 1, 1);
        color_box.attach (color_43, 6, 1, 1, 1);
        color_box.attach (color_44, 0, 2, 1, 1);
        color_box.attach (color_45, 1, 2, 1, 1);
        color_box.attach (color_46, 2, 2, 1, 1);
        color_box.attach (color_47, 3, 2, 1, 1);
        color_box.attach (color_48, 4, 2, 1, 1);
        color_box.attach (color_49, 5, 2, 1, 1);

        var grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        grid.margin = 12;
        grid.margin_top = 0;
        grid.expand = true;
        grid.add (name_label);
        grid.add (name_entry);
        grid.add (color_label);
        grid.add (color_box);
        grid.show_all ();

        add (grid);

        notify["project"].connect (() => {
            name_entry.text = project.name;

            switch (project.color) {
                case 30:
                    color_30.active = true;
                    break;
                case 31:
                    color_31.active = true;
                    break;
                case 32:
                    color_32.active = true;
                    break;
                case 33:
                    color_33.active = true;
                    break;
                case 34:
                    color_34.active = true;
                    break;
                case 35:
                    color_35.active = true;
                    break;
                case 36:
                    color_36.active = true;
                    break;
                case 37:
                    color_37.active = true;
                    break;
                case 38:
                    color_39.active = true;
                    break;
                case 39:
                    color_30.active = true;
                    break;
                case 40:
                    color_40.active = true;
                    break;
                case 41:
                    color_41.active = true;
                    break;
                case 42:
                    color_42.active = true;
                    break;
                case 43:
                    color_43.active = true;
                    break;
                case 44:
                    color_44.active = true;
                    break;
                case 45:
                    color_45.active = true;
                    break;
                case 46:
                    color_46.active = true;
                    break;
                case 47:
                    color_47.active = true;
                    break;
                case 48:
                    color_48.active = true;
                    break;
                case 49:
                    color_49.active = true;
                    break;
                default:
                    break;
            }
        });
    }
}