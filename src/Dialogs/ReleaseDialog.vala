/*/
*- Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Dialogs.ReleaseDialog : Gtk.Dialog {
    public ReleaseDialog () {
        Object (
            transient_for: Planner.instance.main_window,
            deletable: true,
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

        var app_icon = new Gtk.Image ();
        app_icon.valign = Gtk.Align.END;
        app_icon.gicon = new ThemedIcon ("com.github.alainm23.planner");
        app_icon.pixel_size = 38;

        var header_label = new Gtk.Label (_("What's new"));
        header_label.halign = Gtk.Align.START;
        header_label.get_style_context ().add_class ("h3");
        header_label.get_style_context ().add_class ("font-weight-600");

        var date = new DateTime.local (
            2020,
            7,
            8, 0, 0, 0);
        var date_label = new Gtk.Label (Planner.utils.get_default_date_format_from_date (date));
        date_label.halign = Gtk.Align.START;
        date_label.use_markup = true;
        date_label.get_style_context ().add_class ("dim-label");

        var version_label = new Gtk.Label ("v%s".printf (Constants.VERSION));
        version_label.valign = Gtk.Align.CENTER;
        version_label.get_style_context ().add_class ("pane-due-button");

        var app_grid = new Gtk.Grid ();
        app_grid.column_spacing = 6;
        app_grid.attach (app_icon, 0, 0, 1, 2);
        app_grid.attach (header_label, 1, 0, 1, 1);
        app_grid.attach (date_label, 1, 1, 1, 1);

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        header_box.margin = 6;
        header_box.margin_start = 12;
        header_box.margin_end = 12;
        header_box.pack_start (app_grid, false, true, 0);
        header_box.pack_end (version_label, false, false, 0);

        var separator_01 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator_01.hexpand = true;

        var separator_02 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL); 
        separator_02.hexpand = true;

        var fund_button = new UrlButton (_("Fund"), "https://www.patreon.com/alainm23", "payment-card-symbolic");
        var translate_button = new UrlButton (_("Suggest Translations"), "https://hosted.weblate.org/projects/planner/", "preferences-desktop-locale-symbolic");
        var report_button = new UrlButton (_("Report a Problem"), "https://github.com/alainm23/planner/issues", "bug-symbolic");

        var footer_grid = new Gtk.Grid ();
        footer_grid.column_homogeneous = true;
        footer_grid.halign = Gtk.Align.CENTER;
        footer_grid.valign = Gtk.Align.END;
        footer_grid.vexpand = true;
        footer_grid.add (fund_button);
        footer_grid.add (translate_button);
        footer_grid.add (report_button);

        var release_info = new Widgets.TextView (); 
        release_info.buffer.text = _("""General bug fixes and improvements.
✓ Fixed a critical bug where tasks disappear unexpectedly.""");
        release_info.pixels_below_lines = 3;
        release_info.border_width = 12;
        release_info.wrap_mode = Gtk.WrapMode.WORD;
        release_info.cursor_visible = false;
        release_info.editable = false;

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (separator_01);
        main_grid.add (header_box);
        main_grid.add (separator_02);
        main_grid.add (release_info);
        main_grid.add (footer_grid);

        var main_scrolled = new Gtk.ScrolledWindow (null, null);
        main_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        main_scrolled.expand = true;
        main_scrolled.add (main_grid);

        var content_area = get_content_area ();
        // content_area.border_width = 12;
        content_area.add (main_scrolled);
    }
}


class UrlButton : Gtk.Grid {
    public UrlButton (string label, string? uri, string icon_name) {
        halign = Gtk.Align.CENTER;
        get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        tooltip_text = uri;

        var icon = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.SMALL_TOOLBAR);
        icon.valign = Gtk.Align.CENTER;

        var title = new Gtk.Label (label);
        title.ellipsize = Pango.EllipsizeMode.END;

        var grid = new Gtk.Grid ();
        grid.halign = Gtk.Align.CENTER;
        grid.column_spacing = 6;
        grid.add (icon);
        grid.add (title);

        if (uri != null) {
            var button = new Gtk.Button ();
            button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

            button.add (grid);
            add (button);

            button.clicked.connect (() => {
                try {
                    AppInfo.launch_default_for_uri (uri, null);
                } catch (Error e) {
                    warning ("%s\n", e.message);
                }
            });
        } else {
            add (grid);
        }
    }
}
