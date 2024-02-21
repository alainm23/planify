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
 
public class Widgets.CircularProgressBar : Adw.Bin {
    public int size { get; construct; }

    public double percentage {
        get {
            return circularProgressBar.percentage;
        }

        set {
            circularProgressBar.percentage = value;
        }
    }

    public string color {
        set {
            circularProgressBar.progress_fill_color = Util.get_default ().get_color (value);
            Util.get_default ().set_widget_color (Util.get_default ().get_color (value), this);
        }
    }

    private _CircularProgressBar circularProgressBar; // vala-lint=naming-convention

    public CircularProgressBar (int size = 18) {
        Object (
            size: size,
            halign: Gtk.Align.CENTER,
            valign: Gtk.Align.CENTER
        );
    }

    construct {
        if (size <= 10) {
            add_css_class ("circular-progress-bar-min");
        } else {
            add_css_class ("circular-progress-bar");
        }

        circularProgressBar = new _CircularProgressBar (size) {
            margin_start = 2,
            margin_top = 2,
            margin_end = 2,
            margin_bottom = 2  
        };

        child = circularProgressBar;
    }
}

public class _CircularProgressBar : Gtk.DrawingArea { // vala-lint=naming-convention
    public int size { get; construct; }

    private int _line_width;
    private double _percentage;
    private string _center_fill_color; 
    private string _radius_fill_color;
    private string _progress_fill_color; 

    [Description (nick = "Center Fill", blurb = "Center Fill toggle")]
    public bool center_filled {set; get; default = false;}

    [Description (nick = "Radius Fill", blurb = "Radius Fill toggle")]
    public bool radius_filled {set; get; default = false;}

    [Description (nick = "Font", blurb = "Font description without size, just the font name")]
    public string font {set; get; default = "URW Gothic";}

    [Description (nick = "Line Cap", blurb = "Line Cap for stroke as in Cairo.LineCap")]
    public Cairo.LineCap line_cap {set; get; default = Cairo.LineCap.BUTT;}
    
    [Description (nick = "Inside circle fill color", blurb = "Center pad fill color (Check Gdk.RGBA parse method)")]
    public string center_fill_color {
        get {
            return _center_fill_color;
        }
        set {
            var color = Gdk.RGBA ();
            if (color.parse (value)) {
                _center_fill_color = value;
            }
        }
    }

    [Description (nick = "Circular radius fill color", blurb = "The circular pad fill color (Check GdkRGBA parse method)")]
    public string radius_fill_color {
        get {
            return _radius_fill_color;
        }
        set {
            var color = Gdk.RGBA ();
            if (color.parse (value)) {
                _radius_fill_color = value;
            }
        }
    }

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

    [Description (nick = "Circle width", blurb = "The circle radius line width")]
    public int line_width {
        get {
            return _line_width;
        }
        set {
            if (value < 0) {
                _line_width = 0;
            } else if (value > calculate_radius ()) {
                _line_width = calculate_radius ();
            } else {
                _line_width = value;
            }
        }
    }

    [Description (nick = "Percentage/Value", blurb = "The percentage value [0.0 ... 1.0]")]
    public double percentage {
        get { 
            return _percentage; 
        }
        set {
            if (value > 1.0) {
                _percentage = 1.0;
            } else if (value < 0.0) {
                _percentage = 0.0;
            } else {
                _percentage = value;
            }
        }
    }

    construct {
        _line_width = 0;
        _percentage = 0;
        _center_fill_color   = "#adadad"; // vala-lint=double-spaces
        _radius_fill_color   = "#d3d3d3"; // vala-lint=double-spaces
        _progress_fill_color = "#4a90d9";
    }

    public _CircularProgressBar (int size) {
        Object (
            size: size,
            height_request: size,
            width_request: size
        );

        set_draw_func (draw);

        notify.connect (() => {
            queue_draw ();
        });
    }

    private int calculate_radius () {
        return int.min (get_width () / 2, get_height () / 2) - 1;
    }

    public override Gtk.SizeRequestMode get_request_mode () {
        return Gtk.SizeRequestMode.CONSTANT_SIZE;
    }

    public void draw (DrawingArea da, Cairo.Context cr, int width, int height) {
        int delta;
        Gdk.RGBA color;
        
        cr.save ();

        color = Gdk.RGBA ();

        var center_x = get_width () / 2;
        var center_y = get_height () / 2;
        var radius = calculate_radius ();

        if (radius - line_width < 0) {
            delta = 0;
            line_width = radius;
        } else {
            delta = radius - (line_width / 2);
        }
        
        color = Gdk.RGBA ();
        cr.set_line_cap (line_cap);
        cr.set_line_width (line_width);

        // Center Fill
        if (center_filled == true) {
            cr.arc (center_x, center_y, delta, 0, 2 * Math.PI);
            color.parse (center_fill_color);
            Gdk.cairo_set_source_rgba (cr, color);
            cr.fill ();
        }

        // Radius Fill
        if (radius_filled == true) {
            cr.arc (center_x, center_y, delta, 0, 2 * Math.PI);
            color.parse (radius_fill_color);
            Gdk.cairo_set_source_rgba (cr, color);
            cr.stroke ();
        }

        // Progress/Percentage Fill
        if (percentage > 0) {
            color.parse (progress_fill_color);
            Gdk.cairo_set_source_rgba (cr, color);

            if (line_width == 0) {
                cr.move_to (center_x, center_y);
                cr.arc (center_x,
                        center_y,
                        delta + 1,
                        1.5 * Math.PI,
                        (1.5 + percentage * 2 ) * Math.PI);
                cr.fill ();
            } else {
                cr.arc (center_x,
                        center_y,
                        delta,
                        1.5 * Math.PI,
                        (1.5 + percentage * 2 ) * Math.PI);
                cr.stroke ();
            }
        }
    }
}
