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

public class Widgets.BoardView : Gtk.EventBox {
    public Objects.Project project { get; set; }
    private Gtk.Grid grid;
    private Widgets.BoardColumn inbox_board;

    private const Gtk.TargetEntry[] TARGET_ENTRIES_SECTION = {
        {"SECTIONROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    construct {
        grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.HORIZONTAL;
        grid.hexpand = true;
        grid.margin_top = 24;
        grid.margin_start = 31;
        grid.margin_end = 18;
        grid.column_spacing = 24;
        grid.halign = Gtk.Align.START;
        // Gtk.drag_dest_set (grid, Gtk.DestDefaults.ALL, TARGET_ENTRIES_SECTION, Gdk.DragAction.MOVE);
        // grid.drag_data_received.connect (on_drag_section_received);

        var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.expand = true;
        scrolled_window.add (grid);

        add (scrolled_window);

        notify["project"].connect (() => {
            add_boards ();
        });

        Planner.database.section_added.connect ((section) => {
            if (project.id == section.project_id) {
                var board = new Widgets.BoardColumn (section, project);
                grid.add (board);
                grid.show_all ();
            }
        });

        Planner.event_bus.show_new_window_project.connect ((id) => {
            if (project.id == id) {
                add_boards ();
            }
        });
    }

    public void add_boards () {
        foreach (unowned Gtk.Widget child in grid.get_children ()) {
            child.destroy ();
        }

        inbox_board = new Widgets.BoardColumn.for_project (project);
        grid.add (inbox_board);
        foreach (var section in Planner.database.get_all_sections_by_project (project.id)) {
            var board = new Widgets.BoardColumn (section, project);
            grid.add (board);
        }
        
        show_all ();
    }

    public void add_new_item (int index=-1) {
        inbox_board.add_new_item (index);
    }

    //  private void on_drag_section_received (Gdk.DragContext context, int x, int y,
    //      Gtk.SelectionData selection_data, uint target_type, uint time) {
    //      Widgets.BoardColumn target;
    //      Widgets.BoardColumn source;
    //      Gtk.Allocation alloc;

    //      print ("X: %i\n".printf (x));
    //      print ("Y: %i\n".printf (y));

    //      target = (Widgets.BoardColumn) grid.get_child_at (x, y);
    //      target.get_allocation (out alloc);

    //      if (target != null) {
    //          print ("Section: %s\n".printf (target.section.name));
    //      }

    //      var row = ((Gtk.Widget[]) selection_data.get_data ()) [0];
    //      source = (Widgets.BoardColumn) row;

    //      if (target != null) {
    //          source.get_parent ().remove (source);

    //          grid.insert (source, 2);
    //          grid.show_all ();
    //      }
    //  }
}
