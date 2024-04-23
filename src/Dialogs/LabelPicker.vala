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

public class Dialogs.LabelPicker : Adw.Window {
    private Widgets.LabelsPickerCore picker;

    public Gee.ArrayList<Objects.Label> labels {
        set {
            picker.labels = value;
        }
    }

    public signal void labels_changed (Gee.HashMap<string, Objects.Label> labels);

    public LabelPicker () {
        Object (
            deletable: true,
            resizable: true,
            modal: true,
            title: _("Labels"),
            width_request: 320,
            height_request: 450,
            transient_for: (Gtk.Window) Planify.instance.main_window
        );
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);

        picker = new Widgets.LabelsPickerCore ();

        var button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Filter")) {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            css_classes = { Granite.STYLE_CLASS_SUGGESTED_ACTION }
        };

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (headerbar);
        toolbar_view.add_bottom_bar (button);
		toolbar_view.content = picker;

        content = toolbar_view;

        button.clicked.connect (() => {
            labels_changed (picker.picked);
            hide_destroy ();
        });

        picker.close.connect (() => {
            labels_changed (picker.picked);
            hide_destroy ();
        });
    }

    public void add_labels (BackendType backend_type) {
        picker.backend_type = backend_type;
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}
