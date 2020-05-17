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

public class Widgets.DueProjectButton : Gtk.ToggleButton {
    public Objects.Project project { get; construct; }

    private Gtk.Label due_label;
    private Gtk.Image due_image;
    private Gtk.Revealer label_revealer;
    private Widgets.Calendar.Calendar calendar;
    private Gtk.Switch enable_switch;

    private Gtk.Popover popover = null;

    public DueProjectButton (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        tooltip_text = _("Due Date");
        get_style_context ().add_class ("flat");
        // get_style_context ().add_class ("item-action-button");

        due_image = new Gtk.Image ();
        due_image.valign = Gtk.Align.CENTER;
        due_image.pixel_size = 16;
        due_image.gicon = new ThemedIcon ("planner-calendar-symbolic");

        due_label = new Gtk.Label (null);
        due_label.get_style_context ().add_class ("font-bold");
        due_label.use_markup = true;

        label_revealer = new Gtk.Revealer ();
        label_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        label_revealer.add (due_label);

        var main_grid = new Gtk.Grid ();
        main_grid.margin_end = 3;
        main_grid.halign = Gtk.Align.CENTER;
        main_grid.valign = Gtk.Align.CENTER;
        main_grid.add (due_image);
        main_grid.add (label_revealer);

        add (main_grid);

        this.toggled.connect (() => {
            if (this.active) {
                if (popover == null) {
                    create_popover ();
                }

                if (project.due_date != "") {
                    enable_switch.active = true;
                    calendar.sensitive = false;
                } else {
                    enable_switch.active = false;
                    calendar.sensitive = true;
                }

                popover.popup ();
            }
        });

        update_date_text (project);
    }

    private void create_popover () {
        popover = new Gtk.Popover (this);
        popover.position = Gtk.PositionType.BOTTOM;
        // popover.get_style_context ().add_class ("popover-background");

        calendar = new Widgets.Calendar.Calendar ();
        calendar.hexpand = true;
        calendar.margin_start = 9;
        calendar.margin_end = 9;

        calendar.selection_changed.connect ((date) => {
            set_due (date.to_string ());
        });

        var due_label = new Granite.HeaderLabel (_("Relative date:"));

        enable_switch = new Gtk.Switch ();
        enable_switch.valign = Gtk.Align.CENTER;
        enable_switch.get_style_context ().add_class ("active-switch");

        var due_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        due_box.margin_start = 12;
        due_box.margin_end = 12;
        due_box.hexpand = true;
        due_box.pack_start (due_label, false, false, 0);
        due_box.pack_end (enable_switch, false, false, 0);

        var popover_grid = new Gtk.Grid ();
        popover_grid.margin_top = 6;
        popover_grid.margin_bottom = 12;
        popover_grid.width_request = 235;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (due_box);
        popover_grid.add (calendar);
        popover_grid.show_all ();

        popover.add (popover_grid);

        popover.closed.connect (() => {
            this.active = false;
        });

        enable_switch.notify["active"].connect (() => {
            calendar.sensitive = enable_switch.active;
        });
    }

    public void update_date_text (Objects.Project project) {

    }

    public void set_due (string date) {
        //  if (due_switch.active) {
        //      project.due_date = date;
        //  } else {
        //      project.due_date = "";
        //  }

        //  project.save ();
    //      bool new_date = false;
    //      if (date != "") {
    //          undated_button.visible = true;
    //          undated_button.no_show_all = false;

    //          if (item.due_date == "") {
    //              new_date = true;
    //          }

    //          item.due_date = date;
    //      } else {
    //          undated_button.visible = false;
    //          undated_button.no_show_all = true;
    //          combobox.set_active_iter (e_day_iter);

    //          item.due_date = "";
    //          item.due_is_recurring = 0;
    //          item.due_string = "";
    //          item.due_lang = "";

    //          recurring_switch.active = false;
    //      }

    //      Planner.database.set_due_item (item, new_date);
    //      if (item.is_todoist == 1) {
    //          Planner.todoist.update_item (item);
    //      }
    }
}
