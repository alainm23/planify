/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab : */
/*
 * Custom Gtk.Widget to provide a circular progress bar.
 * It extends/subclasses Gtk.Bin instead of Gtk.DrawingArea.
 *
 * Based on José Miguel Fonte's Vala Circular Progress Bar
 * https://github.com/phastmike/vala-circular-progress-bar
 */

using Gtk;
using Cairo;

public class Widgets.ProjectProgress : Gtk.Bin {
    public int min_d { get; construct; }
    public int subproject_offset = 2;
    private string _progress_fill_color;
    private double _percentage;
    public double subproject_line_width = 1.1;
    public double line_width = 1.5;
    public bool has_subprojects = false;
    public bool enable_subprojects = false;

    [Description (nick = "Progress fill color", blurb = "Progress line color (Check GdkRGBA parse method)")]
    public string progress_fill_color {
        get {
            return _progress_fill_color;
        }
        set {
            var color = Gdk.RGBA ();
            if (color.parse (value)) {
                _progress_fill_color = value;
            }
        }
    }

    [Description (nick = "Percentage/Value", blurb = "The percentage value [0.0 ... 1.0]")]
    public double percentage {
        get {
            return _percentage;
        }
        set {
            _percentage = double.min (double.max (value, 0), 1);
        }
    }

    construct {
        _percentage = 0;
        _progress_fill_color = "#4a90d9";
    }

    public ProjectProgress (int min_d=18) {
        Object (
            min_d: min_d
        );

        notify.connect (() => {
            queue_draw ();
        });
    }

    private int calculate_radius () {
        return int.min (get_allocated_width () / 2, get_allocated_height () / 2) - 1;
    }

    private int calculate_diameter () {
        return 2 * calculate_radius ();
    }

    public override Gtk.SizeRequestMode get_request_mode () {
        return Gtk.SizeRequestMode.CONSTANT_SIZE;
    }

    public override void get_preferred_width (out int min_w, out int natural_w) {
        min_w = min_d;
        natural_w = int.max (calculate_diameter (), min_d);
    }

    public override void get_preferred_height (out int min_h, out int natural_h) {
        min_h = min_d;
        natural_h = int.max (calculate_diameter (), min_d);
    }

    public override void size_allocate (Gtk.Allocation allocation) {
        base.size_allocate (allocation);
    }

    public override bool draw (Cairo.Context cr) {
        Gdk.RGBA color;

        cr.save ();

        var center_x = get_allocated_width () / 2;
        var center_y = get_allocated_height () / 2;

        var outer_delta = enable_subprojects ? (subproject_offset + subproject_line_width) : line_width;
        var inner_delta = enable_subprojects ? 1 : 2;

        var outer_radius = Math.round (center_x - outer_delta);
        var inner_radius = Math.round (outer_radius - line_width - inner_delta);

        color = Gdk.RGBA ();
        color.parse (progress_fill_color);
        Gdk.cairo_set_source_rgba (cr, color);

        // Progress/Percentage Fill
        if (percentage > 0) {
            cr.move_to (center_x, center_y);
            cr.arc (center_x,
                    center_y,
                    inner_radius,
                    1.5 * Math.PI,
                    (1.5 + percentage * 2) * Math.PI);
            cr.fill ();
        }

        // Outer circle around progress
        cr.set_line_width (line_width);
        cr.arc (center_x,
               center_y,
               outer_radius ,
               0,
               Math.PI * 2);
        cr.stroke ();

        // Extra circle to indicate sub projects
        if (has_subprojects && enable_subprojects) {
            color.alpha = 0.7;
            Gdk.cairo_set_source_rgba (cr, color);
            cr.set_line_width (subproject_line_width);

            cr.arc (center_x + 2,
                   center_y + 2,
                   outer_radius,
                   Math.PI / 90.0,
                   90.0 * Math.PI / 180.0);
            cr.stroke ();
        }

        cr.restore ();

        return base.draw (cr);
    }
}
