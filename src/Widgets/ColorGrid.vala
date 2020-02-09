public class Widgets.ColorGrid : Gtk.Grid {
    public signal void color_selected (int color);
    construct {
        var color_30 = new Gtk.RadioButton (null);
        color_30.valign = Gtk.Align.START;
        color_30.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("30", Planner.utils.get_color (30), color_30);

        var color_31 = new Gtk.RadioButton.from_widget (color_30);
        color_31.valign = Gtk.Align.START;
        color_31.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("31", Planner.utils.get_color (31), color_31);

        var color_32 = new Gtk.RadioButton.from_widget (color_30);
        color_32.valign = Gtk.Align.START;
        color_32.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("32", Planner.utils.get_color (32), color_32);

        var color_33 = new Gtk.RadioButton.from_widget (color_30);
        color_33.valign = Gtk.Align.START;
        color_33.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("33", Planner.utils.get_color (33), color_33);

        var color_34 = new Gtk.RadioButton.from_widget (color_30);
        color_34.valign = Gtk.Align.START;
        color_34.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("34", Planner.utils.get_color (34), color_34);

        var color_35 = new Gtk.RadioButton.from_widget (color_30);
        color_35.valign = Gtk.Align.START;
        color_35.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("35", Planner.utils.get_color (35), color_35);

        var color_36 = new Gtk.RadioButton.from_widget (color_30);
        color_36.valign = Gtk.Align.START;
        color_36.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("36", Planner.utils.get_color (36), color_36);

        var color_37 = new Gtk.RadioButton.from_widget (color_30);
        color_37.valign = Gtk.Align.START;
        color_37.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("37", Planner.utils.get_color (37), color_37);

        var color_38 = new Gtk.RadioButton.from_widget (color_30);
        color_38.valign = Gtk.Align.START;
        color_38.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("38", Planner.utils.get_color (38), color_38);

        var color_39 = new Gtk.RadioButton.from_widget (color_30);
        color_39.valign = Gtk.Align.START;
        color_39.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("39", Planner.utils.get_color (39), color_39);

        var color_40 = new Gtk.RadioButton.from_widget (color_30);
        color_40.valign = Gtk.Align.START;
        color_40.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("40", Planner.utils.get_color (40), color_40);

        var color_41 = new Gtk.RadioButton.from_widget (color_30);
        color_41.valign = Gtk.Align.START;
        color_41.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("41", Planner.utils.get_color (41), color_41);

        var color_42 = new Gtk.RadioButton.from_widget (color_30);
        color_42.valign = Gtk.Align.START;
        color_42.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("42", Planner.utils.get_color (42), color_42);

        var color_43 = new Gtk.RadioButton.from_widget (color_30);
        color_43.valign = Gtk.Align.START;
        color_43.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("43", Planner.utils.get_color (43), color_43);

        var color_44 = new Gtk.RadioButton.from_widget (color_30);
        color_44.valign = Gtk.Align.START;
        color_44.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("44", Planner.utils.get_color (44), color_44);

        var color_45 = new Gtk.RadioButton.from_widget (color_30);
        color_45.valign = Gtk.Align.START;
        color_45.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("45", Planner.utils.get_color (45), color_45);

        var color_46 = new Gtk.RadioButton.from_widget (color_30);
        color_46.valign = Gtk.Align.START;
        color_46.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("46", Planner.utils.get_color (46), color_46);

        var color_47 = new Gtk.RadioButton.from_widget (color_30);
        color_47.valign = Gtk.Align.START;
        color_47.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("47", Planner.utils.get_color (47), color_47);

        var color_48 = new Gtk.RadioButton.from_widget (color_30);
        color_48.valign = Gtk.Align.START;
        color_48.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("48", Planner.utils.get_color (48), color_48);

        var color_49 = new Gtk.RadioButton.from_widget (color_30);
        color_49.valign = Gtk.Align.START;
        color_49.halign = Gtk.Align.START;
        Planner.utils.apply_styles ("49", Planner.utils.get_color (49), color_49);

        halign = Gtk.Align.CENTER;
        margin = 6;
        margin_start = 16;
        margin_end = 12;
        margin_bottom = 12;
        column_homogeneous = true;
        row_homogeneous = true;
        row_spacing = 6;
        column_spacing = 12;

        attach (color_30, 0, 0, 1, 1);
        attach (color_31, 1, 0, 1, 1);
        attach (color_32, 2, 0, 1, 1);
        attach (color_33, 3, 0, 1, 1);
        attach (color_34, 4, 0, 1, 1);
        attach (color_35, 5, 0, 1, 1);
        attach (color_36, 6, 0, 1, 1);
        attach (color_37, 0, 1, 1, 1);
        attach (color_38, 1, 1, 1, 1);
        attach (color_39, 2, 1, 1, 1);
        attach (color_40, 3, 1, 1, 1);
        attach (color_41, 4, 1, 1, 1);
        attach (color_42, 5, 1, 1, 1);
        attach (color_43, 6, 1, 1, 1);
        attach (color_44, 0, 2, 1, 1);
        attach (color_45, 1, 2, 1, 1);
        attach (color_46, 2, 2, 1, 1);
        attach (color_47, 3, 2, 1, 1);
        attach (color_48, 4, 2, 1, 1);
        attach (color_49, 5, 2, 1, 1);

        color_30.toggled.connect (() => {
            color_selected (30);
        });

        color_31.toggled.connect (() => {
            color_selected (31);
        });

        color_32.toggled.connect (() => {
            color_selected (32);
        });

        color_33.toggled.connect (() => {
            color_selected (33);
        });

        color_34.toggled.connect (() => {
            color_selected (34);
        });

        color_35.toggled.connect (() => {
            color_selected (35);
        });

        color_36.toggled.connect (() => {
            color_selected (36);
        });

        color_37.toggled.connect (() => {
            color_selected (37);
        });

        color_38.toggled.connect (() => {
            color_selected (38);
        });

        color_39.toggled.connect (() => {
            color_selected (39);
        });

        color_40.toggled.connect (() => {
            color_selected (40);
        });

        color_41.toggled.connect (() => {
            color_selected (41);
        });

        color_42.toggled.connect (() => {
            color_selected (42);
        });

        color_43.toggled.connect (() => {
            color_selected (43);
        });

        color_44.toggled.connect (() => {
            color_selected (44);
        });

        color_45.toggled.connect (() => {
            color_selected (45);
        });

        color_46.toggled.connect (() => {
            color_selected (46);
        });

        color_47.toggled.connect (() => {
            color_selected (47);
        });

        color_48.toggled.connect (() => {
            color_selected (48);
        });

        color_49.toggled.connect (() => {
            color_selected (49);
        });
    }
}
