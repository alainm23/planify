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

public class Widgets.ErrorView : Adw.Bin {
    private Gtk.Label error_label;
    private Gtk.Label error_code_label;
    private Gtk.TextView error_textview;
    private Gtk.Button issue_button;
    private Gtk.Button copy_button;

    private static Gee.HashMap<int, string> http_messages;

    ~ErrorView () {
        debug ("Destroying Widgets.ErrorView\n");
    }

    public int error_code {
        set {
            error_label.label = get_http_error (value);
            error_code_label.label = "HTTP %d".printf (value);
        }
    }

    public string error_message {
        set {
            error_textview.buffer.text = value;
        }
    }

    public bool visible_issue_button {
        set {
            issue_button.visible = value;
        }
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class ("flat");

        var error_image = new Gtk.Image.from_icon_name ("cross-large-circle-outline-symbolic") {
            hexpand = true,
            halign = Gtk.Align.CENTER,
            pixel_size = 48,
            css_classes = { "error" },
            margin_top = 12
        };

        error_label = new Gtk.Label (null) {
            hexpand = true,
            halign = Gtk.Align.CENTER,
            css_classes = { "font-bold", "title-2" },
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            wrap = true,
            justify = Gtk.Justification.CENTER,
            selectable = true
        };

        error_code_label = new Gtk.Label (null) {
            hexpand = true,
            halign = Gtk.Align.CENTER,
            css_classes = { "dimmed", "caption" },
            margin_top = 3,
            selectable = true
        };

        error_textview = new Gtk.TextView () {
            left_margin = 12,
            top_margin = 12,
            bottom_margin = 12,
            right_margin = 12,
            wrap_mode = Gtk.WrapMode.WORD,
            editable = false,
            cursor_visible = false
        };
        error_textview.add_css_class ("monospace");
        error_textview.add_css_class ("error-message");
        error_textview.remove_css_class ("view");

        var textview_scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = error_textview,
            height_request = 150
        };

        copy_button = new Gtk.Button.from_icon_name ("edit-copy-symbolic") {
            valign = Gtk.Align.END,
            halign = Gtk.Align.END,
            css_classes = { "flat", "circular" },
            tooltip_text = _("Copy error message"),
            margin_bottom = 6,
            margin_end = 6
        };

        var textview_overlay = new Gtk.Overlay () {
            child = textview_scrolled_window
        };
        textview_overlay.add_overlay (copy_button);

        var textview_frame = new Gtk.Frame (null) {
            child = textview_overlay,
            margin_top = 18,
            margin_start = 12,
            margin_end = 12
        };

        var log_label = new Gtk.Label (
            _("For more details, share your log file: %s").printf (
                Services.LogService.get_default ().get_log_path ()
            )
        ) {
            css_classes = { "dimmed", "caption" },
            wrap = true,
            justify = Gtk.Justification.CENTER,
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            selectable = true
        };

        var buttons_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8) {
            halign = Gtk.Align.CENTER,
            margin_top = 16,
            margin_bottom = 24
        };

        issue_button = new Gtk.Button.with_label (_("Report Issue")) {
            css_classes = { "suggested-action", "pill" }
        };

        buttons_box.append (issue_button);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.append (headerbar);
        content_box.append (error_image);
        content_box.append (error_label);
        content_box.append (error_code_label);
        content_box.append (textview_frame);
        content_box.append (log_label);
        content_box.append (buttons_box);

        child = content_box;

        copy_button.clicked.connect (() => {
            var clipboard = Gdk.Display.get_default ().get_clipboard ();
            clipboard.set_text (error_textview.buffer.text);
            copy_button.icon_name = "object-select-symbolic";
            Timeout.add (1500, () => {
                copy_button.icon_name = "edit-copy-symbolic";
                return GLib.Source.REMOVE;
            });
        });

        issue_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri (Constants.NEW_ISSUE_URL, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });
    }

    public static string get_http_error (int code) {
        if (http_messages == null) {
            http_messages = new Gee.HashMap<int, string> ();
            http_messages.set (400, _("The request was incorrect."));
            http_messages.set (401, _("Authentication is required, and has failed, or has not yet been provided."));
            http_messages.set (403, _("The request was valid, but for something that is forbidden."));
            http_messages.set (404, _("The requested resource could not be found."));
            http_messages.set (410, _("Account migration required."));
            http_messages.set (429, _("The user has sent too many requests in a given amount of time."));
            http_messages.set (500, _("The request failed due to a server error."));
            http_messages.set (503, _("The server is currently unable to handle the request."));
        }

        return http_messages.has_key (code) ? http_messages.get (code) : _("Unknown error");
    }
}
