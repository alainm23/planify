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

public class Dialogs.LabelPicker : Adw.Dialog {
    public LabelPickerType picker_type { get; construct; }

    private Widgets.LabelsPickerCore labels_picker_core;
    private Widgets.LoadingButton button;

    public Gee.ArrayList<Objects.Label> labels {
        set {
            labels_picker_core.labels = value;
        }
    }

    public string button_text {
        set {
            button.label = value;
        }
    }

    public signal void labels_changed (Gee.HashMap<string, Objects.Label> labels);
    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();

    public LabelPicker (LabelPickerType picker_type = LabelPickerType.FILTER_ONLY) {
        Object (
            picker_type: picker_type,
            title: _("Labels"),
            content_width: 320,
            content_height: 450
        );
    }

    ~LabelPicker () {
        debug ("Destroying - Dialogs.LabelPicker\n");
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class ("flat");

        labels_picker_core = new Widgets.LabelsPickerCore (picker_type);

        button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Filter")) {
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            css_classes = { "suggested-action" }
        };

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (headerbar);
        toolbar_view.add_bottom_bar (button);
        toolbar_view.content = labels_picker_core;

        child = toolbar_view;
        Services.EventBus.get_default ().disconnect_typing_accel ();

        signal_map[button.clicked.connect (() => {
            labels_changed (labels_picker_core.picked);
            close ();
        })] = button;

        signal_map[labels_picker_core.close.connect (() => {
            labels_changed (labels_picker_core.picked);
            close ();
        })] = labels_picker_core;

        closed.connect (() => {
            clean_up ();
            Services.EventBus.get_default ().connect_typing_accel ();
        });
    }

    public void add_labels (Objects.Source source) {
        labels_picker_core.source = source;
    }

    public void add_labels_list (Gee.ArrayList<Objects.Label> labels_list) {
        labels_picker_core.add_labels_list (labels_list);
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();

        if (labels_picker_core != null) {
            labels_picker_core.clean_up ();
        }
    }
}
