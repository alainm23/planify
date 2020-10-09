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

public class Widgets.SourceRow : Gtk.ListBoxRow {
    public E.Source source { get; construct; }

    public Gtk.Revealer main_revealer;
    private Widgets.ProjectProgress project_progress;
    private Gtk.Label name_label;

    public SourceRow (E.Source source) {
        Object (
            source: source
        );
    }

    construct {
        var task_list = (E.SourceTaskList?) source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);

        margin_start = margin_end = 6;
        margin_top = 2;
        get_style_context ().add_class ("pane-row");
        get_style_context ().add_class ("project-row");

        project_progress = new Widgets.ProjectProgress (10);
        project_progress.margin = 2;
        project_progress.valign = Gtk.Align.CENTER;
        project_progress.halign = Gtk.Align.CENTER;
        project_progress.progress_fill_color = task_list.dup_color ();

        var progress_grid = new Gtk.Grid ();
        progress_grid.get_style_context ().add_class ("project-progress-%s".printf (
            source.uid
        ));
        progress_grid.add (project_progress);
        progress_grid.valign = Gtk.Align.CENTER;
        progress_grid.halign = Gtk.Align.CENTER;

        name_label = new Gtk.Label (source.display_name);
        name_label.tooltip_text = source.display_name;
        name_label.get_style_context ().add_class ("pane-item");
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        name_label.margin_start = 9;

        var handle_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        handle_box.hexpand = true;
        handle_box.margin_start = 5;
        handle_box.margin_end = 3;
        handle_box.margin_top = handle_box.margin_bottom = 3;
        handle_box.pack_start (progress_grid, false, false, 0);
        handle_box.pack_start (name_label, false, false, 0);
        
        main_revealer = new Gtk.Revealer ();
        main_revealer.reveal_child = true;
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        main_revealer.add (handle_box);

        add (main_revealer);
        apply_color (task_list.dup_color ());
    }

    private void apply_color (string color) {
        string _css = """
            .project-progress-%s {
                border-radius: 50%;
                border: 1.5px solid %s;
            }
        """;

        var provider = new Gtk.CssProvider ();

        try {
            var css = _css.printf (
                source.uid,
                color
            );

            provider.load_from_data (css, css.length);
            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (), provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } catch (GLib.Error e) {
            return;
        }
    }

    public void update_request () {
        var task_list = (E.SourceTaskList?) source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);
        name_label.label = source.display_name;
        apply_color (task_list.dup_color ());
        //  if (source.connection_status == E.SourceConnectionStatus.CONNECTING) {
        //      status_stack.visible_child_name = "spinner";
        //  } else {
        //      status_stack.visible_child_name = "image";

        //      switch (source.connection_status) {
        //          case E.SourceConnectionStatus.AWAITING_CREDENTIALS:
        //              status_image.icon_name = "dialog-password-symbolic";
        //              status_image.tooltip_text = _("Waiting for login credentials");
        //              break;
        //          case E.SourceConnectionStatus.DISCONNECTED:
        //              status_image.icon_name = "network-offline-symbolic";
        //              status_image.tooltip_text = _("Currently disconnected from the (possibly remote) data store");
        //              break;
        //          case E.SourceConnectionStatus.SSL_FAILED:
        //              status_image.icon_name = "security-low-symbolic";
        //              status_image.tooltip_text = _("SSL certificate trust was rejected for the connection");
        //              break;
        //          default:
        //              status_image.gicon = null;
        //              status_image.tooltip_text = null;
        //              break;
        //      }
        //  }
    }

    public void remove_request () {
        main_revealer.reveal_child = false;
        GLib.Timeout.add (main_revealer.transition_duration, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}
