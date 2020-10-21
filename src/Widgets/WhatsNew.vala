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
    private Gtk.Label description_label;

    /**
     * Grid for action items
     */
    protected Gtk.Grid options;

    public string icon {
        set {
            app_icon.gicon = new ThemedIcon (value);
        }
    }

    public string app_description {
        set {
            description_label.label = value;
        }
    }

    public WhatsNew (string app_icon, string app_description) {
        Object (
            icon: app_icon,
            app_description: app_description,
            deletable: false,
            resizable: false,
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
        title_label.get_style_context ().add_class ("h2");
        title_label.get_style_context ().add_class ("font-bold");
        title_label.halign = Gtk.Align.CENTER;
        title_label.hexpand = true;

        description_label = new Gtk.Label (null);
        description_label.halign = Gtk.Align.CENTER;
        description_label.wrap = true;
        description_label.margin_top = 12;

        options = new Gtk.Grid ();
        options.orientation = Gtk.Orientation.VERTICAL;
        options.row_spacing = 12;
        options.halign = Gtk.Align.CENTER;
        options.margin_top = 24;
        options.expand = true;

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.height_request = 325;
        scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrolled.expand = true;
        scrolled.add (options);

        var continue_button = new Gtk.Button.with_label (_("Continue"));
        continue_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        continue_button.expand = true;
        continue_button.margin_top = 6;
        continue_button.margin_bottom = 24;
        continue_button.valign = Gtk.Align.END;

        var content = new Gtk.Grid ();
        content.orientation = Gtk.Orientation.VERTICAL;
        content.halign = Gtk.Align.CENTER;
        content.margin_end = 32;
        content.margin_start = 32;
        content.add (title_label);
        content.add (description_label);        
        content.add (scrolled);
        content.add (continue_button);

        var main_scrolled = new Gtk.ScrolledWindow (null, null);
        main_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        main_scrolled.vscrollbar_policy = Gtk.PolicyType.NEVER;
        main_scrolled.expand = true;
        main_scrolled.add (content);

        get_content_area ().add (main_scrolled);

        use_header_bar = 1;
        var header_bar = (Gtk.HeaderBar) get_header_bar ();
        header_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        header_bar.get_style_context ().add_class ("oauth-dialog");

        continue_button.clicked.connect (() => {
            destroy ();
        });
    }

    public void append (string icon_name, string option_text, string description_text) {
        var image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG);
        image.use_fallback = true;
        append_with_image (image, option_text, description_text);
    }

    public void append_notes (string title, List<string> list, int margin_start) {
        var title_label = new Gtk.Label (title);
        title_label.get_style_context ().add_class ("font-bold");
        title_label.halign = Gtk.Align.START;
        title_label.valign = Gtk.Align.END;

        var notes_grid = new Gtk.Grid ();
        notes_grid.halign = Gtk.Align.START;
        notes_grid.margin_top = 3;
        notes_grid.orientation = Gtk.Orientation.VERTICAL;
        list.foreach ((item) => {
            notes_grid.add (get_note (item));
        });

        var grid = new Gtk.Grid ();
        grid.margin_start = margin_start;
        grid.halign = Gtk.Align.START;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (title_label);
        grid.add (notes_grid);

        options.add (grid);
    }

    public Gtk.Label get_note (string title) {
        var label = new Gtk.Label ("- %s".printf (title));
        label.wrap = true;
        label.xalign = 0;
        label.halign = Gtk.Align.START;
        label.valign = Gtk.Align.END;

        return label;
    }

    public void append_with_image (Gtk.Image? image, string option_text, string description_text) {
        // Option label
        var button = new Widgets.Feature (image, option_text, description_text);
        options.add (button);
    }
}


public class Widgets.Feature : Gtk.EventBox {

    Gtk.Label button_title;
    Gtk.Label button_description;
    Gtk.Image? _icon;
    Gtk.Grid button_grid;

    /**
     * Title property of the Welcome Button
     *
     * @since 0.3
     */
    public string title {
        get { return button_title.get_text (); }
        set { button_title.set_text (value); }
    }

    /**
     * Description property of the Welcome Button
     *
     * @since 0.3
     */
    public string description {
        get { return button_description.label; }
        set { button_description.label = value; }
    }

    /**
     * Image of the Welcome Button
     *
     * @since 0.3
     */
    public Gtk.Image? icon {
        get { return _icon; }
        set {
            if (_icon != null) {
                _icon.destroy ();
            }
            _icon = value;
            if (_icon != null) {
                _icon.set_pixel_size (48);
                _icon.halign = Gtk.Align.CENTER;
                _icon.valign = Gtk.Align.CENTER;
                button_grid.attach (_icon, 0, 0, 1, 2);
            }
        }
    }

    public Feature (Gtk.Image? image, string option_text, string description_text) {
        Object (title: option_text, description: description_text, icon: image);
    }

    construct {
        // Title label
        button_title = new Gtk.Label (null);
        button_title.get_style_context ().add_class ("font-bold");
        button_title.halign = Gtk.Align.START;
        button_title.valign = Gtk.Align.END;

        // Description label
        button_description = new Gtk.Label (null);
        button_description.halign = Gtk.Align.START;
        button_description.valign = Gtk.Align.START;
        button_description.xalign = 0;
        button_description.set_line_wrap (true);
        button_description.set_line_wrap_mode (Pango.WrapMode.WORD);
        button_description.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        button_description.use_markup = true;

        // Button contents wrapper
        button_grid = new Gtk.Grid ();
        button_grid.column_spacing = 12;

        button_grid.attach (button_title, 1, 0, 1, 1);
        button_grid.attach (button_description, 1, 1, 1, 1);
        this.add (button_grid);
    }
}
