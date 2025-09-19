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

public class Widgets.LabelPicker.LabelPicker : Gtk.Popover {
    private Widgets.LabelsPickerCore labels_picker_core;

    public Gee.ArrayList<Objects.Label> labels {
        set {
            labels_picker_core.labels = value;
        }
    }

    public Objects.Source source {
        set {
            labels_picker_core.source = value;
        }
    }

    public Gee.HashMap<string, Objects.Label> picked {
        get {
            return labels_picker_core.picked;
        }
    }

    public LabelPicker () {
        Object (
            has_arrow: false,
            position: Gtk.PositionType.TOP,
            width_request: 275,
            height_request: 300
        );
    }

    ~LabelPicker () {
        debug ("Destroying - Widgets.LabelPicker.LabelPicker\n");
    }

    construct {
        css_classes = { "popover-contents" };

        labels_picker_core = new Widgets.LabelsPickerCore (LabelPickerType.FILTER_AND_CREATE) {
            margin_top = 12
        };

        child = labels_picker_core;

        labels_picker_core.close.connect (() => {
            popdown ();
        });

        destroy.connect (() => {
            labels_picker_core.clean_up ();
        });
    }

    public void reset () {
        labels_picker_core.reset ();
    }

    public void clean_up () {
        labels_picker_core.clean_up ();
    }
}
