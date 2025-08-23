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

public class Widgets.AttachmentRow : Gtk.ListBoxRow {
    public Objects.Attachment attachment { get; construct; }

    private Gtk.Revealer main_revealer;
    private Widgets.LoadingButton close_button;

    public AttachmentRow (Objects.Attachment attachment) {
        Object (
            attachment: attachment
        );
    }

    construct {
        add_css_class ("row");
        add_css_class ("transition");
        add_css_class ("no-padding");

        var name_label = new Gtk.Label (attachment.file_name);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

        close_button = new Widgets.LoadingButton.with_icon ("cross-large-circle-filled-symbolic") {
            valign = CENTER,
            halign = END,
            hexpand = true,
            css_classes = { "flat" },
            tooltip_text = _("Delete")
        };

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 3,
            margin_start = 6,
            margin_bottom = 3,
            margin_end = 6
        };

        content_box.append (new Gtk.Image.from_icon_name ("paper-symbolic"));
        content_box.append (name_label);
        content_box.append (close_button);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = content_box
        };

        child = main_revealer;

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        var gesture = new Gtk.GestureClick ();
        add_controller (gesture);
        gesture.pressed.connect (() => {
            open_file ();
        });

        activate.connect (() => {
            open_file ();
        });

        var remove_gesture = new Gtk.GestureClick ();
        close_button.add_controller (remove_gesture);
        remove_gesture.pressed.connect (() => {
            remove_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            attachment.delete ();
        });
    }

    private void open_file () {
        close_button.is_loading = true;

        try {
            if (attachment.file_path == null || attachment.file_path.strip () == "") {
                throw new GLib.IOError.INVALID_ARGUMENT ("File path is empty");
            }

            var file = GLib.File.new_for_uri (attachment.file_path);
            if (!file.query_exists ()) {
                throw new GLib.IOError.NOT_FOUND ("File no longer exists");
            }

            var app_info = GLib.AppInfo.get_default_for_uri_scheme ("file");
            if (app_info == null) {
                var file_info = file.query_info (GLib.FileAttribute.STANDARD_CONTENT_TYPE,
                                                 GLib.FileQueryInfoFlags.NONE);
                var content_type = file_info.get_content_type ();
                app_info = GLib.AppInfo.get_default_for_type (content_type, false);
            }

            if (app_info != null) {
                var file_list = new GLib.List<GLib.File> ();
                file_list.append (file);
                app_info.launch (file_list, null);
            } else {
                GLib.AppInfo.launch_default_for_uri (attachment.file_path, null);
            }

            close_button.is_loading = false;
        } catch (Error e) {
            close_button.is_loading = false;
            Services.EventBus.get_default ().send_toast (
                Util.get_default ().create_toast ("Error opening file: " + e.message)
            );
        }
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }
}