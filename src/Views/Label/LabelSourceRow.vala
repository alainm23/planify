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

public class Views.LabelSourceRow : Gtk.ListBoxRow {
    public Objects.Source source { get; construct; }

    private Layouts.HeaderItem group;
    private Gtk.Revealer main_revealer;

    private Gee.HashMap<string, Layouts.LabelRow> labels_hashmap = new Gee.HashMap<string, Layouts.LabelRow> ();
    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public LabelSourceRow (Objects.Source source) {
        Object (
            source: source
        );
    }

    ~LabelSourceRow () {
        print ("Destroying - Views.LabelSourceRow\n");
    }

    construct {
        css_classes = { "no-selectable", "no-padding" };

        group = new Layouts.HeaderItem (source.display_name) {
            reveal = true,
            subheader_title = source.subheader_text
        };
        group.placeholder_message = _("No labels available. Create one by clicking on the '+' button");
        group.margin_bottom = 12;
        group.set_sort_func (sort_func);

        var add_button = new Gtk.Button.from_icon_name ("plus-large-symbolic") {
            valign = Gtk.Align.CENTER,
            css_classes = { "flat", "header-item-button", "dimmed" },
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Add Project"), "P")
        };

        group.add_widget_end (add_button);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = group
        };

        child = main_revealer;
        add_labels ();

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            group.set_sort_func (null);
            return GLib.Source.REMOVE;
        });

        signal_map[source.updated.connect (() => {
            group.header_title = source.display_name;
        })] = source;

        signal_map[add_button.clicked.connect (() => {
            var dialog = new Dialogs.Label.new (source);
            dialog.present (Planify._instance.main_window);
        })] = add_button;

        signal_map[group.row_activated.connect ((row) => {
            Services.EventBus.get_default ().pane_selected (PaneType.LABEL, ((Layouts.LabelRow) row).label.id);
        })] = group;

        signal_map[Services.Store.instance ().label_added.connect ((label) => {
            add_label (label);
        })] = Services.Store.instance ();

        signal_map[Services.Store.instance ().label_deleted.connect ((label) => {
            if (labels_hashmap.has_key (label.id)) {
                labels_hashmap[label.id].hide_destroy ();
                labels_hashmap.unset (label.id);
            }
        })] = Services.Store.instance ();
    }

    private void add_labels () {
        foreach (Objects.Label label in Services.Store.instance ().get_labels_by_source (source.id)) {
            add_label (label);
        }
    }

    private void add_label (Objects.Label label) {
        if (label.source_id == source.id && !labels_hashmap.has_key (label.id)) {
            labels_hashmap[label.id] = new Layouts.LabelRow (label);
            group.add_child (labels_hashmap[label.id]);
        }
    }

    private int sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
        Objects.Label label1 = ((Layouts.LabelRow) lbrow).label;
        Objects.Label label2 = ((Layouts.LabelRow) lbbefore).label;
        return label1.item_order - label2.item_order;
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        clean_up ();
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }

    public void clean_up () {
        foreach (var row in group.get_children ()) {
            (row as Layouts.LabelRow).clean_up ();
        }

        group.clean_up ();

        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }
}