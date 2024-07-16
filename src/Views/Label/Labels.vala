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

public class Views.Labels : Adw.Bin {
    private Layouts.HeaderItem labels_local_header;
    private Layouts.HeaderItem labels_todoist_header;
    private Layouts.HeaderItem labels_caldav_header;

    public Gee.HashMap <string, Layouts.LabelRow> labels_local_map;
    public Gee.HashMap <string, Layouts.LabelRow> labels_todoist_map;
    public Gee.HashMap <string, Layouts.LabelRow> labels_caldav_map;

    construct {
        labels_local_map = new Gee.HashMap <string, Layouts.LabelRow> ();
        labels_todoist_map = new Gee.HashMap <string, Layouts.LabelRow> ();
        labels_caldav_map = new Gee.HashMap <string, Layouts.LabelRow> ();

        var headerbar = new Layouts.HeaderBar ();
        headerbar.title = _("Labels");

        labels_local_header = new Layouts.HeaderItem (_("Labels: On This Computer"));
        labels_local_header.reveal = true;
        labels_local_header.show_separator = true;
        labels_local_header.set_sort_func (sort_func);

        labels_todoist_header = new Layouts.HeaderItem (_("Labels: Todoist"));
        labels_todoist_header.reveal = Services.Todoist.get_default ().is_logged_in ();
        labels_todoist_header.show_separator = true;
        labels_todoist_header.set_sort_func (sort_func);

        labels_caldav_header = new Layouts.HeaderItem (_("Labels: Nextcloud"));
        labels_caldav_header.reveal = Services.CalDAV.Core.get_default ().is_logged_in ();
        labels_caldav_header.show_separator = true;
        labels_caldav_header.set_sort_func (sort_func);

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            hexpand = true,
            vexpand = true
        };

        content.append (labels_local_header);
        content.append (labels_todoist_header);
        content.append (labels_caldav_header);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 1024,
            tightening_threshold = 800,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 64,
        };

        content_clamp.child = content;

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        scrolled_window.child = content_clamp;

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (headerbar);
		toolbar_view.content = scrolled_window;

        child = toolbar_view;
        add_labels ();

        Timeout.add (225, () => {
            labels_local_header.set_sort_func (null);
            labels_todoist_header.set_sort_func (null);
            labels_caldav_header.set_sort_func (null);
            return GLib.Source.REMOVE;
        });

        var add_local_button = new Gtk.Button.from_icon_name ("plus-large-symbolic") {
            valign = Gtk.Align.CENTER,
            css_classes = { "flat", "header-item-button" }
        };

        labels_local_header.add_widget_end (add_local_button);
        add_local_button.clicked.connect (() => {
            var dialog = new Dialogs.Label.new (BackendType.LOCAL);
            dialog.present (Planify._instance.main_window);
        });

        var add_todoist_button = new Gtk.Button.from_icon_name ("plus-large-symbolic") {
            valign = Gtk.Align.CENTER,
            css_classes = { "flat", "header-item-button" }
        };

        labels_todoist_header.add_widget_end (add_todoist_button);
        add_todoist_button.clicked.connect (() => {
            var dialog = new Dialogs.Label.new (BackendType.TODOIST);
            dialog.present (Planify._instance.main_window);
        });

        var add_caldav_button = new Gtk.Button.from_icon_name ("plus-large-symbolic") {
            valign = Gtk.Align.CENTER,
            css_classes = { "flat", "header-item-button" }
        };

        labels_caldav_header.add_widget_end (add_caldav_button);
        add_caldav_button.clicked.connect (() => {
            var dialog = new Dialogs.Label.new (BackendType.CALDAV);
            dialog.present (Planify._instance.main_window);
        });

        labels_local_header.row_activated.connect ((row) => {
            Services.EventBus.get_default ().pane_selected (PaneType.LABEL, ((Layouts.LabelRow) row).label.id);
        });

        labels_todoist_header.row_activated.connect ((row) => {
            Services.EventBus.get_default ().pane_selected (PaneType.LABEL, ((Layouts.LabelRow) row).label.id);
        });

        labels_caldav_header.row_activated.connect ((row) => {
            Services.EventBus.get_default ().pane_selected (PaneType.LABEL, ((Layouts.LabelRow) row).label.id);
        });

        Services.Database.get_default ().label_added.connect ((label) => {
            add_label (label);
        });

        Services.Database.get_default ().label_deleted.connect ((label) => {
            if (labels_local_map.has_key (label.id)) {
                labels_local_map[label.id].hide_destroy ();
                labels_local_map.unset (label.id);
            }

            if (labels_todoist_map.has_key (label.id)) {
                labels_todoist_map[label.id].hide_destroy ();
                labels_todoist_map.unset (label.id);
            }

            if (labels_caldav_map.has_key (label.id)) {
                labels_caldav_map[label.id].hide_destroy ();
                labels_caldav_map.unset (label.id);
            }
        });

        //  Services.Todoist.get_default ().log_in.connect (() => {
        //      labels_todoist_header.reveal = Services.Todoist.get_default ().is_logged_in ();
        //  });

        //  Services.Todoist.get_default ().log_out.connect (() => {
        //      labels_todoist_header.reveal = Services.Todoist.get_default ().is_logged_in ();
        //  });

        Services.CalDAV.Core.get_default ().log_in.connect (() => {
            labels_caldav_header.reveal = Services.CalDAV.Core.get_default ().is_logged_in ();
        });

        Services.CalDAV.Core.get_default ().log_out.connect (() => {
            labels_caldav_header.reveal = Services.CalDAV.Core.get_default ().is_logged_in ();
        });
    }

    private void add_labels () {
        foreach (Objects.Label label in Services.Database.get_default ().labels) {
            add_label (label);
        }
    }

    private int sort_func (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow lbbefore) {
        Objects.Label label1 = ((Layouts.LabelRow) lbrow).label;
        Objects.Label label2 = ((Layouts.LabelRow) lbbefore).label;
        return label1.item_order - label2.item_order;
    }

    private void add_label (Objects.Label label) {
        if (label.backend_type == BackendType.LOCAL) {
            if (!labels_local_map.has_key (label.id)) {
                labels_local_map[label.id] = new Layouts.LabelRow (label); 
                labels_local_header.add_child (labels_local_map[label.id]);
            }
        } else if (label.backend_type == BackendType.TODOIST) {
            if (!labels_todoist_map.has_key (label.id)) {
                labels_todoist_map[label.id] = new Layouts.LabelRow (label); 
                labels_todoist_header.add_child (labels_todoist_map[label.id]);
            }
        } else if (label.backend_type == BackendType.CALDAV) {
            if (!labels_caldav_map.has_key (label.id)) {
                labels_caldav_map[label.id] = new Layouts.LabelRow (label); 
                labels_caldav_header.add_child (labels_caldav_map[label.id]);
            }
        }
    }
}
