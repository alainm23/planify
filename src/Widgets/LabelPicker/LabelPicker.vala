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

public class Widgets.LabelPicker.LabelPicker : Gtk.Popover {
    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox listbox;
    
    public Gee.HashMap <string, Objects.Label> labels_map;
    public Gee.HashMap <string, Widgets.LabelPicker.LabelRow> labels_widgets_map;

    public Objects.Item item {
        set {
            foreach (var entry in value.labels.entries) {
                labels_map [entry.key] = entry.value.label;
            }

            foreach (Objects.Label label in Services.Database.get_default ().labels) {
                labels_widgets_map [label.id_string].active = value.labels.has_key (label.id_string);
            }
        }
    }

    public signal void labels_changed (Gee.HashMap <string, Objects.Label> labels_map);

    public LabelPicker () {
        Object (
            has_arrow: false,
            position: Gtk.PositionType.BOTTOM
        );
    }

    construct {
        add_css_class ("popover-contents");

        labels_map = new Gee.HashMap <string, Objects.Label> ();
        labels_widgets_map = new Gee.HashMap <string, Widgets.LabelPicker.LabelRow> ();

        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Search or Create"),
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_top = 8,
            margin_start = 8,
            margin_end = 8,
            margin_bottom = 8
        };

        listbox = new Gtk.ListBox () {
            hexpand = true
        };

        listbox.set_filter_func (filter_func);
        listbox.add_css_class ("listbox-separator-3");
        listbox.add_css_class ("listbox-background");
        
        var listbox_scrolled = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            height_request = 175
        };

        listbox_scrolled.child = listbox;

        var content_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            hexpand = true,
            vexpand = true
        };
        
        content_grid.attach (listbox_scrolled, 0, 0);

        var main_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_grid.append (search_entry);
        main_grid.append (content_grid);

        child = main_grid;
        add_all_labels ();

        //  key_press_event.connect ((event) => {
        //      var key = Gdk.keyval_name (event.keyval).replace ("KP_", "");

        //      if (key == "Up" || key == "Down") {
        //          return false;
        //      } else if (key == "Enter" || key == "Return" || key == "KP_Enter") {
        //          return false;
        //      } else {
        //          if (!search_entry.has_focus) {
        //              search_entry.grab_focus ();
        //              search_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, 0, false);
        //          }

        //          return false;
        //      }

        //      return true;
        //  });

        //  focus_out_event.connect (() => {
        //      labels_changed (labels_map);
        //      hide_destroy ();
        //      return false;
        //  });

        //  key_release_event.connect ((key) => {
        //      if (key.keyval == 65307) {
        //          hide_destroy ();
        //      }

        //      return false;
        //  });

        //  closed.connect (() => {
        //      labels_changed (labels_map);
        //  });

        //  cancel_clear_button.clicked.connect (() => {
        //      labels_map.clear ();
        //      labels_changed (labels_map);
        //      hide_destroy ();
        //  });

        //  search_entry.search_changed.connect (() => {
        //      listbox.invalidate_filter ();
        //  });

        //  search_entry.activate.connect (() => {
        //      if (Util.get_default ().is_input_valid (search_entry)) {
        //          Objects.Label label = Planner.database.get_label_by_name (search_entry.text, true);
        //          if (label != null) {
        //              if (labels_widgets_map.has_key (label.id_string)) {
        //                  labels_widgets_map [label.id_string].update_checked_toggled ();
        //              }
        //          } else {
        //              add_assign_label ();
        //          }
        //      }
        //  });
    }

    private void add_assign_label () {
        //  BackendType backend_type = (BackendType) Planner.settings.get_enum ("backend-type");

        //  var label = new Objects.Label ();
        //  label.color = Util.get_default ().get_random_color ();
        //  label.name = search_entry.text;

        //  if (backend_type == BackendType.TODOIST) {
        //      placeholder_stack.visible_child_name = "spinner";
        //      label.todoist = true;
        //      Planner.todoist.add.begin (label, (obj, res) => {
        //          label.id = Planner.todoist.add.end (res);
        //          Planner.database.insert_label (label);
        //          checked_toggled (label, true);
        //          labels_changed (labels_map);
        //          hide_destroy ();
        //      });
        //  } else if (backend_type == BackendType.LOCAL) {
        //      label.id = Util.get_default ().generate_id ();
        //      Planner.database.insert_label (label);
        //      checked_toggled (label, true);
        //      labels_changed (labels_map);
        //      hide_destroy ();
        //  }
    }

    private void add_all_labels () {
        foreach (Objects.Label label in Services.Database.get_default ().labels) {
            var row = new Widgets.LabelPicker.LabelRow (label);
            row.checked_toggled.connect (checked_toggled);

            labels_widgets_map [label.id_string] = row;
            listbox.append (row);
        }

        //  listbox.show_all ();
    }

    //  private Gtk.Widget get_placeholder () {
    //      var message_label = new Gtk.Label ("Your list of filters will show up here. Create one by entering the name and pressing the Enter key.") {
    //          wrap = true,
    //          justify = Gtk.Justification.CENTER
    //      };
        
    //      unowned Gtk.StyleContext message_label_context = message_label.get_style_context ();
    //      message_label_context.add_class ("dim-label");
    //      message_label_context.add_class (Granite.STYLE_CLASS_SMALL_LABEL);
        
    //      var spinner = new Gtk.Spinner ();
    //      spinner.get_style_context ().add_class ("text-color");
    //      spinner.start ();

    //      placeholder_stack = new Gtk.Stack () {
    //          expand = true,
    //          transition_type = Gtk.StackTransitionType.CROSSFADE,
    //          homogeneous = false
    //      };

    //      placeholder_stack.add_named (message_label, "message");
    //      placeholder_stack.add_named (spinner, "spinner");

    //      var grid = new Gtk.Grid () {
    //          margin = 6,
    //          valign = Gtk.Align.CENTER
    //      };

    //      grid.add (placeholder_stack);
    //      grid.show_all ();

    //      return grid;
    //  }

    private void checked_toggled (Objects.Label label, bool active) {
        if (active) {
            if (!labels_map.has_key (label.id_string)) {
                labels_map [label.id_string] = label;
            }
        } else {
            if (labels_map.has_key (label.id_string)) {
                labels_map.unset (label.id_string);
            }
        }
    }

    private bool filter_func (Gtk.ListBoxRow row) {
        var label = ((Widgets.LabelPicker.LabelRow) row).label;
        return search_entry.text.down () in label.name.down ();
    }
}