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

public class Dialogs.MessageDialog : Hdy.Window {
    public Gtk.Label primary_label;
    public Gtk.Label secondary_label;
    private Gtk.Image image;
    private Gtk.Grid action_grid;

    public string image_icon {
        owned get {
            return image.icon_name;
        }

        set {
            image.gicon = new ThemedIcon (value);  
            image.pixel_size = 64;
        }
    }

    public string primary_text {
        get {
            return primary_label.label;
        }

        set {
            primary_label.label = value;
        }
    }

    public string secondary_text {
        get {
            return secondary_label.label;
        }

        set {
            secondary_label.label = value;
        }
    }

    public signal void default_action (Gtk.ResponseType response = Gtk.ResponseType.CANCEL);

    public MessageDialog (string primary_text, string secondary_text, string image_icon_name) {
        Object (
            primary_text: primary_text,
            secondary_text: secondary_text,
            image_icon: image_icon_name,
            deletable: false,
            resizable: false,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT
        );
    }

    construct {
        unowned Gtk.StyleContext dialog_context = get_style_context ();
        dialog_context.add_class (Gtk.STYLE_CLASS_VIEW);
        dialog_context.add_class ("planner-dialog");
        dialog_context.remove_class ("background");
        
        transient_for = Planner.instance.main_window;

        var headerbar = new Hdy.HeaderBar ();
        headerbar.has_subtitle = false;
        headerbar.show_close_button = false;
        headerbar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        image = new Gtk.Image ();
        image.halign = Gtk.Align.CENTER;

        primary_label = new Gtk.Label (null);
        primary_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        primary_label.get_style_context ().add_class ("font-bold");
        primary_label.max_width_chars = 50;
        primary_label.wrap = true;
        primary_label.xalign = 0;
        primary_label.halign = Gtk.Align.CENTER;
        primary_label.justify = Gtk.Justification.CENTER;
        primary_label.margin_top = 12;

        secondary_label = new Gtk.Label (null);
        secondary_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        secondary_label.use_markup = true;
        secondary_label.max_width_chars = 50;
        secondary_label.wrap = true;
        secondary_label.xalign = 0;
        secondary_label.halign = Gtk.Align.CENTER;
        secondary_label.justify = Gtk.Justification.CENTER;

        action_grid = new Gtk.Grid () {
            column_spacing = 6,
            column_homogeneous = true,
            margin_top = 12
        };

        var content_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            expand = true,
            margin = 24,
            margin_top = 0,
            margin_bottom = 12,
            halign = Gtk.Align.CENTER,
            row_spacing = 6
        };

        content_grid.add (image);
        content_grid.add (primary_label);
        content_grid.add (secondary_label);
        content_grid.add (action_grid);

        var message_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            width_request = 280
        };

        message_grid.add (headerbar);
        message_grid.add (content_grid);
        message_grid.show_all ();

        var main_scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        main_scrolled.add (message_grid);

        add (main_scrolled);

        focus_out_event.connect (() => {
            if (!modal) {
                hide_destroy ();
            }
            
            return false;
        });

         key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_destroy ();
            }

            return false;
        });
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }

    public void add_action_widget (Gtk.Button button,
        Gtk.ResponseType response = Gtk.ResponseType.CANCEL) {
        button.clicked.connect (() => {
            default_action (response);
        });
        action_grid.add (button);
        action_grid.show_all ();
    }

    public void add_default_action (
        string label, Gtk.ResponseType response = Gtk.ResponseType.CANCEL,
        string class_name = Gtk.STYLE_CLASS_BUTTON) {
        Gtk.Button button = new Gtk.Button.with_label (label) {
            hexpand = true
        };
        button.get_style_context ().add_class ("border-radius-6");
        button.get_style_context ().add_class (class_name);
        add_action_widget (button, response);
    }
}