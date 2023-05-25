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

public class Dialogs.ProjectDescription : Adw.Window {
    public Objects.Project project { get; construct; }

    public ProjectDescription (Objects.Project project) {
        Object (
            project: project,
            transient_for: (Gtk.Window) Planner.instance.main_window,
            deletable: true,
            resizable: true,
            modal: true,
            width_request: 400,
            height_request: 350,
            title: _("Project Description")
        );
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);

        var description_textview = new Widgets.HyperTextView (_("Add a description")) {
            left_margin = 12,
            right_margin = 12,
            top_margin = 12,
            bottom_margin = 12,
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
            hexpand = true,
            vexpand = true
        };
        description_textview.set_text (project.description);
        description_textview.remove_css_class ("view");

        var description_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_start = 12,
            margin_end = 12
        };
        description_box.append (description_textview);
        description_box.add_css_class ("card");
        description_box.add_css_class ("border-radius-6");

        var done_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Done")) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_top = 12
        };

        done_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            width_request = 225
        };
        
        content_box.append (headerbar);
        content_box.append (description_box);
        content_box.append (done_button);

        content = content_box;

        done_button.clicked.connect (() => {
            project.description = description_textview.get_text ();
            project.update (false);
            destroy ();
        });
    }
}