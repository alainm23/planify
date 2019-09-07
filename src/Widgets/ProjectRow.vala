/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Widgets.ProjectRow : Gtk.ListBoxRow { 
    public Objects.Project project { get; construct; }

    private Gtk.Grid grid_color;
    private Gtk.Label name_label;
    private Gtk.Label count_label;

    private Gtk.Menu menu = null;
    public Gtk.Box handle_box;

    private Gtk.Revealer motion_revealer;
    public Gtk.Revealer main_revealer;

    private const Gtk.TargetEntry[] targetEntries = {
        {"PROJECTROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public bool reveal_drag_motion {
        set {   
            motion_revealer.reveal_child = value;
        }
        get {
            return motion_revealer.reveal_child;
        }
    }

    public ProjectRow (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        tooltip_text = project.name;
        get_style_context ().add_class ("project-row");

        grid_color = new Gtk.Grid ();
        grid_color.margin_start = 8;
		grid_color.get_style_context ().add_class ("project-%i".printf ((int32) project.id));
        grid_color.set_size_request (13, 13);
        grid_color.valign = Gtk.Align.CENTER;
        grid_color.halign = Gtk.Align.CENTER;

        name_label = new Gtk.Label (project.name);
        name_label.margin_top = 6;
        name_label.margin_bottom = 6;
        name_label.get_style_context ().add_class ("pane-item");
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        name_label.use_markup = true;

        count_label = new Gtk.Label ("4");
        count_label.get_style_context ().add_class ("dim-label");
        count_label.valign = Gtk.Align.CENTER;
        count_label.halign = Gtk.Align.CENTER;
        count_label.margin_end = 12;

        var source_icon = new Gtk.Image ();
        source_icon.get_style_context ().add_class ("dim-label");
        source_icon.pixel_size = 16;

        if (project.is_todoist == 0) {
            source_icon.icon_name = "network-offline-symbolic";
        } else {
            source_icon.icon_name = "planner-online-symbolic";
        }

        handle_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        //handle_box.margin = 6;
        //handle_box.margin_end = 12;
        //handle_box.margin_start = 8;
        handle_box.hexpand = true;
        handle_box.pack_start (grid_color, false, false, 0);
        handle_box.pack_start (name_label, false, false, 7);
        handle_box.pack_end (count_label, false, false, 0);
        //main_box.pack_end (source_icon, false, false, 0);
        
        var motion_grid = new Gtk.Grid ();
        motion_grid.height_request = 12;
            
        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        motion_revealer.add (motion_grid);

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;

        grid.add (motion_revealer);
        grid.add (handle_box);
    
        var handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.expand = true;
        handle.above_child = false;
        handle.add (grid);

        add (handle);
        apply_styles (Application.utils.get_color (project.color));

        build_drag_and_drop ();

        button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                activate_menu ();
                return true;
            }

            return false;
        });
    }

    private void apply_styles (string color) {
        string COLOR_CSS = """
            .project-%i {
                background-color: %s;
                border-radius: 50%;
                box-shadow:
                    inset 0 1px 0 0 alpha (@inset_dark_color, 0.7),
                    inset 0 0 0 1px alpha (@inset_dark_color, 0.3),
                    0 1px 0 0 alpha (@bg_highlight_color, 0.3);
            }
        """;

        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (
                (int32) project.id,
                color
            );

            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }

    private void build_drag_and_drop () {
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, targetEntries, Gdk.DragAction.MOVE);

        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);
        
        Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION, targetEntries, Gdk.DragAction.MOVE);
        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);

        drag_end.connect (clear_indicator);
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = (ProjectRow) widget;

        Gtk.Allocation alloc;
        row.get_allocation (out alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr = new Cairo.Context (surface);
        cr.set_source_rgba (0, 0, 0, 0.3);
        cr.set_line_width (1);

        cr.move_to (0, 0);
        cr.line_to (alloc.width, 0);
        cr.line_to (alloc.width, alloc.height);
        cr.line_to (0, alloc.height);
        cr.line_to (0, 0);
        cr.stroke ();
  
        cr.set_source_rgba (255, 255, 255, 0.5);
        cr.rectangle (0, 0, alloc.width, alloc.height);
        cr.fill ();

        row.handle_box.draw (cr);

        Gtk.drag_set_icon_surface (context, surface);

        row.visible = false;
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context, Gtk.SelectionData selection_data, uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (ProjectRow))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("PROJECTROW"), 32, data
        );
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        reveal_drag_motion = true;   

        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        reveal_drag_motion = false;
    }

    public void clear_indicator (Gdk.DragContext context) {
        reveal_drag_motion = false;
    }

    private void activate_menu () {
        if (menu == null) {
            build_context_menu (project);
        }

        menu.popup_at_pointer (null);
    }

    private void build_context_menu (Objects.Project project) {
        menu = new Gtk.Menu ();
        menu.get_style_context ().add_class ("view");
        menu.get_style_context ().add_class ("css");

        var edit_menu = new Widgets.MenuItem (_("Edit project"), "edit-symbolic", _("Play"));
        var share_menu = new Widgets.MenuItem (_("Share project"), "emblem-shared-symbolic", _("Play Next"));

        var archive_menu = new Widgets.MenuItem (_("Archive"), "folder-symbolic", _("Play"));
        var delete_menu = new Widgets.MenuItem (_("Delete project"), "edit-delete-symbolic", _("Play Next"));

        menu.add (edit_menu);
        menu.add (share_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (archive_menu);
        menu.add (delete_menu);
        menu.show_all ();
    }
}