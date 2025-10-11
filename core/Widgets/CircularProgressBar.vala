/*
 * Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Alain M. <alainmh23@gmail.com>
 */

public class Widgets.CircularProgressBar : Gtk.DrawingArea {
    public int size { get; construct; }

    private int _line_width;
    private double _percentage;
    private double _animated_percentage;
    private string _center_fill_color;
    private string _radius_fill_color;
    private string _progress_fill_color;
    private string _border_color;
    private int _border_width;
    private int _gap;
    private uint animation_timeout_id = 0;
    private double animation_start_value;
    private double animation_target_value;
    private int64 animation_start_time;
    private uint success_animation_id = 0;
    private double success_squeeze = 0.0;
    private int64 success_start_time;

    [Description (nick = "Center Fill", blurb = "Center Fill toggle")]
    public bool center_filled { set; get; default = false; }

    [Description (nick = "Radius Fill", blurb = "Radius Fill toggle")]
    public bool radius_filled { set; get; default = false; }
    
    [Description (nick = "Thick Style", blurb = "Use thick circular style")]
    public bool thick_style { set; get; default = false; }

    [Description (nick = "Line Cap", blurb = "Line Cap for stroke as in Cairo.LineCap")]
    public Cairo.LineCap line_cap { set; get; default = Cairo.LineCap.BUTT; }

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

    [Description (nick = "Gap", blurb = "Gap between border and progress circle")]
    public int gap {
        get {
            return _gap;
        }
        set {
            if (value < 0) {
                _gap = 0;
            } else {
                _gap = value;
            }
            queue_draw ();
        }
    }

    [Description (nick = "Border Width", blurb = "Width of the outer border")]
    public int border_width {
        get {
            return _border_width;
        }
        set {
            if (value < 0) {
                _border_width = 0;
            } else {
                _border_width = value;
            }
            queue_draw ();
        }
    }

    [Description (nick = "Percentage/Value", blurb = "The percentage value [0.0 ... 1.0]")]
    public double percentage {
        get {
            return _percentage;
        }
        set {
            var new_value = value;
            if (new_value > 1.0) {
                new_value = 1.0;
            } else if (new_value < 0.0) {
                new_value = 0.0;
            }
            
            if (_percentage != new_value) {
                animate_to_percentage (new_value);
                _percentage = new_value;
            }
        }
    }

    public string color {
        set {
            var base_color = Util.get_default ().get_color (value);
            _progress_fill_color = base_color;
            _border_color = base_color;
            
            if (thick_style) {
                var rgba = Gdk.RGBA ();
                rgba.parse (base_color);
                rgba.alpha = 0.3f;
                _radius_fill_color = rgba.to_string ();
            }
            
            queue_draw ();
        }
    }

    construct {
        _line_width = 0;
        _percentage = 0;
        _animated_percentage = 0;
        _center_fill_color = "#adadad";
        _radius_fill_color = "#d3d3d3";
        _progress_fill_color = "#4a90d9";
        _border_color = "#4a90d9";
        _border_width = 2;
        _gap = 3;
    }

    public CircularProgressBar (int size = 16) {
        Object (
            size: size,
            height_request: size,
            width_request: size,
            halign: Gtk.Align.CENTER,
            valign: Gtk.Align.CENTER
        );

        set_draw_func (draw);

        notify.connect (() => {
            queue_draw ();
        });
    }

    private int calculate_radius () {
        var base_size = int.min (size, size);
        return (base_size / 2) - _border_width - _gap - 1;
    }
    
    private void animate_to_percentage (double target) {
        if (animation_timeout_id != 0) {
            Source.remove (animation_timeout_id);
        }
        
        animation_start_value = _animated_percentage;
        animation_target_value = target;
        animation_start_time = get_monotonic_time ();
        
        animation_timeout_id = Timeout.add (16, () => {
            var elapsed = (get_monotonic_time () - animation_start_time) / 1000.0;
            var duration = 500.0;
            
            if (elapsed >= duration) {
                _animated_percentage = animation_target_value;
                queue_draw ();
                animation_timeout_id = 0;
                
                if (animation_target_value >= 1.0) {
                    start_success_animation ();
                }
                
                return false;
            }
            
            var progress = elapsed / duration;
            progress = 1.0 - Math.pow (1.0 - progress, 3.0);
            
            _animated_percentage = animation_start_value + (animation_target_value - animation_start_value) * progress;
            queue_draw ();
            return true;
        });
    }
    
    private void start_success_animation () {
        if (success_animation_id != 0) {
            Source.remove (success_animation_id);
        }
        
        success_start_time = get_monotonic_time ();
        
        success_animation_id = Timeout.add (16, () => {
            var elapsed = (get_monotonic_time () - success_start_time) / 1000.0;
            var duration = 350.0;
            
            if (elapsed >= duration) {
                success_squeeze = 0.0;
                queue_draw ();
                success_animation_id = 0;
                return false;
            }
            
            var progress = elapsed / duration;
            var t = progress;
            
            if (t < 0.5) {
                success_squeeze = t * 2.0;
            } else {
                var bounce_t = (t - 0.5) * 2.0;
                var bounce = Math.pow (2, -10 * bounce_t) * Math.sin ((bounce_t - 0.075) * (2 * Math.PI) / 0.3) + 1;
                success_squeeze = 1.0 - (bounce_t * bounce);
            }
            
            queue_draw ();
            return true;
        });
    }

    ~CircularProgressBar () {
        debug ("Destroying - Widgets.CircularProgressBar\n");
    }

    public override Gtk.SizeRequestMode get_request_mode () {
        return Gtk.SizeRequestMode.CONSTANT_SIZE;
    }

    public void draw (Gtk.DrawingArea da, Cairo.Context cr, int width, int height) {
        int delta;
        Gdk.RGBA color;

        cr.save ();

        color = Gdk.RGBA ();

        var center_x = get_width () / 2;
        var center_y = get_height () / 2;
        var radius = calculate_radius ();

        if (thick_style) {
            var ring_width = radius * 0.3;
            var ring_radius = radius - ring_width / 2;
            
            if (_animated_percentage >= 1.0 && success_squeeze > 0) {
                ring_radius = ring_radius * (1.0 - success_squeeze * 0.3);
            }
            
            cr.set_line_width (ring_width);
            cr.set_line_cap (Cairo.LineCap.ROUND);
            
            cr.arc (center_x, center_y, ring_radius, 0, 2 * Math.PI);
            color.parse (_radius_fill_color);
            Gdk.cairo_set_source_rgba (cr, color);
            cr.stroke ();
            
            if (_animated_percentage > 0) {
                cr.arc (center_x, center_y, ring_radius, -Math.PI / 2, -Math.PI / 2 + _animated_percentage * 2 * Math.PI);
                color.parse (_progress_fill_color);
                Gdk.cairo_set_source_rgba (cr, color);
                cr.stroke ();
            }
        } else {
            double border_radius = radius + _gap + _border_width / 2;
            if (_animated_percentage >= 1.0 && success_squeeze > 0) {
                border_radius = border_radius * (1.0 - success_squeeze * 0.25);
            }
            
            cr.arc (center_x, center_y, border_radius, 0, 2 * Math.PI);
            color.parse (_border_color);
            Gdk.cairo_set_source_rgba (cr, color);
            cr.set_line_width (_border_width);
            cr.stroke ();

            if (radius - line_width < 0) {
                delta = 0;
                line_width = radius;
            } else {
                delta = radius - (line_width / 2);
            }

            cr.set_line_cap (line_cap);
            cr.set_line_width (line_width);

            if (center_filled == true) {
                cr.arc (center_x, center_y, delta, 0, 2 * Math.PI);
                color.parse (center_fill_color);
                Gdk.cairo_set_source_rgba (cr, color);
                cr.fill ();
            }

            if (radius_filled == true) {
                cr.arc (center_x, center_y, delta, 0, 2 * Math.PI);
                color.parse (radius_fill_color);
                Gdk.cairo_set_source_rgba (cr, color);
                cr.stroke ();
            }

            if (_animated_percentage > 0) {
                color.parse (progress_fill_color);
                Gdk.cairo_set_source_rgba (cr, color);

                if (line_width == 0) {
                    cr.move_to (center_x, center_y);
                    cr.arc (center_x, center_y, delta + 1, 1.5 * Math.PI, (1.5 + _animated_percentage * 2) * Math.PI);
                    cr.fill ();
                } else {
                    cr.arc (center_x, center_y, delta, 1.5 * Math.PI, (1.5 + _animated_percentage * 2) * Math.PI);
                    cr.stroke ();
                }
            }
        }
    }
}
