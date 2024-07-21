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
    public Gee.HashMap <string, Layouts.LabelRow> labels_hashmap = new Gee.HashMap <string, Layouts.LabelRow> ();

    public LabelSourceRow (Objects.Source source) {
        Object (
            source: source
        );
    }

    construct {
        css_classes = { "no-selectable", "no-padding" };

        group = new Layouts.HeaderItem (source.header_text) {
            reveal = true,
            show_separator = true,
            subheader_title = source.subheader_text
        };
        group.placeholder_message = _("No labels available. Create one by clicking on the '+' button");
        group.margin_top = 12;
        group.show_separator = true;
        group.set_sort_func (sort_func);

        var add_button = new Gtk.Button.from_icon_name ("plus-large-symbolic") {
            valign = Gtk.Align.CENTER,
            css_classes = { "flat", "header-item-button", "dim-label" },
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

        add_button.clicked.connect (() => {
            var dialog = new Dialogs.Label.new (source);
            dialog.present (Planify._instance.main_window);
        });

        group.row_activated.connect ((row) => {
            Services.EventBus.get_default ().pane_selected (PaneType.LABEL, ((Layouts.LabelRow) row).label.id);
        });

        Services.Store.instance ().label_added.connect ((label) => {
            add_label (label);
        });

        Services.Store.instance ().label_deleted.connect ((label) => {
            if (labels_hashmap.has_key (label.id)) {
                labels_hashmap[label.id].hide_destroy ();
                labels_hashmap.unset (label.id);
            }
        });
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
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }
}