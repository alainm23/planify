/*/
*- Copyright © 2020 Alain M. (https://github.com/alainm23/planner)
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

public class Widgets.WhatsNew : Gtk.Dialog {
    private Gtk.Image app_icon;

    /**
     * List of buttons for action items
     */
    protected new GLib.List<Gtk.Button> children = new GLib.List<Gtk.Button> ();

    /**
     * Grid for action items
     */
    protected Gtk.Grid options;

    public string icon {
        set {
            app_icon.gicon = new ThemedIcon (value);
        }
    }

    public WhatsNew (string app_icon) {
        Object (
            icon: app_icon,
            deletable: false,
            resizable: true,
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            modal: true
        );
    }

    construct {
        get_style_context ().add_class ("release-dialog");
        width_request = 525;
        height_request = 600;

        app_icon = new Gtk.Image ();
        app_icon.halign = Gtk.Align.CENTER;
        app_icon.hexpand = true;
        app_icon.pixel_size = 64;

        var title_label = new Gtk.Label (_("What's New"));
        title_label.get_style_context ().add_class ("h3");
        title_label.get_style_context ().add_class ("font-bold");
        title_label.halign = Gtk.Align.CENTER;
        title_label.margin_top = 12;
        title_label.hexpand = true;

        options = new Gtk.Grid ();
        options.orientation = Gtk.Orientation.VERTICAL;
        options.row_spacing = 12;
        options.halign = Gtk.Align.CENTER;
        options.margin_top = 24;

        var content = new Gtk.Grid ();
        content.orientation = Gtk.Orientation.VERTICAL;
        content.add (app_icon);
        content.add (title_label);
        content.add (options);

        get_content_area ().add (content);
    }

    public int append (string icon_name, string option_text, string description_text) {
        var image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG);
        image.use_fallback = true;
        return append_with_image (image, option_text, description_text);
    }

    public int append_with_image (Gtk.Image? image, string option_text, string description_text) {
        // Option label
        var button = new Granite.Widgets.WelcomeButton (image, option_text, description_text);
        children.append (button);
        options.add (button);
        
        return this.children.index (button);
    }
}
