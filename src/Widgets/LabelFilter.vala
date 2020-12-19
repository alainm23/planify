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

public class Widgets.LabelFilter : Gtk.ToggleButton {
    public Objects.Project project { get; set; }
    private Gtk.Label filter_label;
    private Gtk.Popover popover = null;
    private Gtk.ListBox listbox;
    public Gee.HashMap <string, Objects.Label> labels_loaded;
    public Gee.HashMap <string, Objects.Label> labels_selected;

    //  public LabelFilter (Objects.Project project) {
    //      Object (
    //          project: project
    //      );
    //  }

    construct {
        margin_bottom = 3;
        can_focus = false;
        valign = Gtk.Align.END;
        tooltip_text = _("Filter by Label");
        get_style_context ().add_class ("flat");
        get_style_context ().add_class ("no-padding");

        labels_loaded = new Gee.HashMap <string, Objects.Label> ();
        labels_selected = new Gee.HashMap <string, Objects.Label> ();

        filter_label = new Gtk.Label (_("Label"));
        filter_label.get_style_context ().add_class ("font-bold");

        var down_icon = new Gtk.Image ();
        down_icon.gicon = new ThemedIcon ("pan-down-symbolic");
        down_icon.pixel_size = 16;

        var main_grid = new Gtk.Grid ();
        main_grid.halign = Gtk.Align.CENTER;
        main_grid.valign = Gtk.Align.CENTER;
        main_grid.add (filter_label);
        main_grid.add (down_icon);

        var main_revealer = new Gtk.Revealer ();
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        main_revealer.add (main_grid);
        main_revealer.reveal_child = Planner.database.get_labels_by_project (project.id).size > 0;

        add (main_revealer);

        notify["project"].connect (() => {
            main_revealer.reveal_child = Planner.database.get_labels_by_project (project.id).size > 0;
        });

        toggled.connect (() => {
            if (active) {
                if (popover == null) {
                    create_popover ();
                }

                labels_loaded.clear ();
                foreach (unowned Gtk.Widget child in listbox.get_children ()) {
                    child.destroy ();
                }

                foreach (var label in Planner.database.get_labels_by_project (project.id)) {
                    if (!labels_loaded.has_key (label.id.to_string ())) {
                        var row = new Widgets.LabelFilterRow (label);
                        row.update_checked (labels_selected.has_key (label.id.to_string ()));
                        row.toggled.connect ((label) => {
                            if (labels_selected.has_key (label.id.to_string ())) {
                                labels_selected.unset (label.id.to_string ());
                            } else {
                                labels_selected.set (label.id.to_string (), label);
                            }

                            Planner.event_bus.filter_label_activated (project.id, labels_selected.values);
                        });

                        listbox.add (row);
                        labels_loaded.set (label.id.to_string (), label);
                    }
                }

                listbox.show_all ();
                popover.popup ();
            }
        });

        Planner.database.item_label_added.connect ((id, item_id, label) => {
            if (project.id == Planner.database.get_item_by_id (item_id).project_id) {
                main_revealer.reveal_child = true;
            }
        });

        Planner.database.item_label_deleted.connect ((id, item_id, label) => {
            if (project.id == Planner.database.get_item_by_id (item_id).project_id) {
                main_revealer.reveal_child = Planner.database.get_labels_by_project (project.id).size > 0;
            }
        });
    }

    private void create_popover () {
        popover = new Gtk.Popover (this);
        popover.position = Gtk.PositionType.BOTTOM;
        popover.get_style_context ().add_class ("popover-background");

        listbox = new Gtk.ListBox ();
        listbox.margin_bottom = 3;
        listbox.margin_top = 3;

        var popover_grid = new Gtk.Grid ();
        popover_grid.width_request = 150;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (listbox);
        popover_grid.show_all ();

        popover.add (popover_grid);

        popover.closed.connect (() => {
            this.active = false;
        });
    }
}

public class Widgets.LabelFilterRow : Gtk.ListBoxRow {
    public Objects.Label label { get; construct; }
    public signal void toggled (Objects.Label label);
    
    private Gtk.Label label_name;
    private Gtk.CheckButton checked_button;

    public LabelFilterRow (Objects.Label label) {
        Object (
            label: label
        );
    }

    construct {
        get_style_context ().add_class ("row-transparent");

        checked_button = new Gtk.CheckButton ();
        checked_button.valign = Gtk.Align.CENTER;
        checked_button.get_style_context ().add_class ("check-border");
        
        var color_image = new Gtk.Image.from_icon_name ("tag-symbolic", Gtk.IconSize.MENU);
        color_image.valign = Gtk.Align.CENTER;
        color_image.halign = Gtk.Align.CENTER;
        color_image.can_focus = false;
        color_image.get_style_context ().add_class ("label-%s".printf (label.id.to_string ()));

        label_name = new Gtk.Label (label.name);
        label_name.get_style_context ().add_class ("font-weight-600");

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.hexpand = true;
        grid.add (checked_button);
        grid.add (color_image);
        grid.add (label_name);
        grid.show_all ();

        var button = new Gtk.ModelButton ();
        button.get_child ().destroy ();
        button.add (grid);

        add (button);

        button.button_release_event.connect (() => {
            checked_button.active = !checked_button.active;  
            toggled (label);      
            return Gdk.EVENT_STOP;
        });
    }

    public void update_checked (bool active) {
        checked_button.active = active;
    }
}
