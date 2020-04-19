/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Widgets.ModelButton : Gtk.Button {
    public bool arrow { get; construct; }
    private Gtk.Label item_label;
    public Gtk.Image item_image;

    public string icon {
        set {
            item_image.gicon = new ThemedIcon (value);
        }
    }
    public string tooltip {
        set {
            tooltip_text = value;
        }
    }
    public string text {
        set {
            item_label.label = value;
        }
    }

    public int color {
        set {
            if (value == 0) {
                item_image.get_style_context ().add_class ("today-icon");
                //  var hour = new GLib.DateTime.now_local ().get_hour ();
                //  if (hour >= 18 || hour <= 6) {
                //      item_image.get_style_context ().add_class ("today-night-icon");
                //  } else {
                //      item_image.get_style_context ().add_class ("today-icon");
                //  }
            } else if (value == 1) {
                item_image.get_style_context ().add_class ("upcoming-icon");
            } else {
                item_image.get_style_context ().add_class ("due-clear");
            }
        }
    }

    public bool due_label {
        set {
            if (value) {
                item_label.get_style_context ().add_class ("due-label");
            }
        }
    }

    public ModelButton (string text, string icon, string tooltip = "", bool arrow = false) {
        Object (
            icon: icon,
            text: text,
            tooltip: tooltip,
            arrow: arrow,
            expand: true
        );
    }

    construct {
        get_style_context ().remove_class ("button");
        get_style_context ().add_class ("flat");
        get_style_context ().add_class ("menuitem");
        get_style_context ().add_class ("no-border");
        can_focus = false;

        item_image = new Gtk.Image ();
        item_image.valign = Gtk.Align.CENTER;
        item_image.halign = Gtk.Align.CENTER;
        item_image.pixel_size = 16;

        item_label = new Gtk.Label (null);

        var arrow_image = new Gtk.Image ();
        arrow_image.gicon = new ThemedIcon ("pan-end-symbolic");
        arrow_image.valign = Gtk.Align.CENTER;
        arrow_image.halign = Gtk.Align.CENTER;
        arrow_image.get_style_context ().add_class ("dim-label");
        arrow_image.pixel_size = 16;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        box.margin_start = 3;
        box.pack_start (item_image, false, false, 0);
        box.pack_start (item_label, false, true, 0);
        if (arrow) {
            box.pack_end (arrow_image, false, false, 0);
        }

        add (box);
    }
}

public class Widgets.ImageMenuItem : Gtk.MenuItem {
    private Gtk.Label item_label;
    public Gtk.Image item_image;

    public string icon {
        set {
            item_image.gicon = new ThemedIcon (value);
        }
    }
    public string tooltip {
        set {
            tooltip_text = value;
        }
    }
    public string text {
        set {
            item_label.label = value;
        }
    }

    public int color {
        set {
            if (value == 0) {
                var hour = new GLib.DateTime.now_local ().get_hour ();
                if (hour >= 18 || hour <= 6) {
                    item_image.get_style_context ().add_class ("today-night-icon");
                } else {
                    item_image.get_style_context ().add_class ("today-day-icon");
                }
            } else if (value == 1) {
                item_image.get_style_context ().add_class ("upcoming-icon");
            } else {
                item_image.get_style_context ().add_class ("due-clear");
            }
        }
    }

    public bool due_label {
        set {
            if (value) {
                item_label.get_style_context ().add_class ("due-label");
            }
        }
    }

    public ImageMenuItem (string text, string icon, string tooltip = "") {
        Object (
            icon: icon,
            text: text,
            tooltip: tooltip,
            expand: true
        );
    }

    construct {
        get_style_context ().remove_class ("button");
        get_style_context ().add_class ("flat");
        get_style_context ().add_class ("menuitem");
        can_focus = false;

        item_image = new Gtk.Image ();
        item_image.valign = Gtk.Align.CENTER;
        item_image.halign = Gtk.Align.CENTER;
        item_image.pixel_size = 16;
        item_image.get_style_context ().add_class ("dim-label");

        item_label = new Gtk.Label (null);

        var grid = new Gtk.Grid ();
        grid.margin_start = 3;
        grid.column_spacing = 6;
        grid.add (item_image);
        grid.add (item_label);

        add (grid);
    }
}

public class Widgets.PopoverButton : Gtk.Button {
    public PopoverButton (string text, string? icon, string[]? accels = null) {
        get_style_context ().add_class (Gtk.STYLE_CLASS_MENUITEM);

        var label = new Gtk.Label (text);
        label.halign = Gtk.Align.START;
        label.hexpand = true;

        var grid = new Gtk.Grid ();
        grid.margin_start = 6;

        if (icon != null) {
            grid.add (new Gtk.Image.from_icon_name (icon, Gtk.IconSize.MENU));
        }

        grid.add (label);

        if (accels != null) {
            var accel_label = new Gtk.Label (Granite.markup_accel_tooltip (accels));
            accel_label.halign = Gtk.Align.END;
            accel_label.margin_end = 6;
            accel_label.use_markup = true;

            grid.add (accel_label);
        }

        add (grid);
    }
}
