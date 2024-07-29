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
            pixel_size = 38,
            css_classes = { "error" }
        };

        error_label = new Gtk.Label (null) {
            hexpand = true,
            halign = Gtk.Align.CENTER,
            css_classes = { "font-bold", "title-2" },
            margin_top = 12,
            margin_start = 12,
            margin_end = 12,
            wrap = true,
            justify = Gtk.Justification.CENTER
        };
        
        error_code_label = new Gtk.Label (null) {
            hexpand = true,
            halign = Gtk.Align.CENTER,
            css_classes = { "dim-label", "caption" },
            margin_top = 3
        };

        error_textview = new Gtk.TextView () {
			left_margin = 12,
			top_margin = 12,
			bottom_margin = 12,
			right_margin = 12,
			wrap_mode = Gtk.WrapMode.WORD
		};
		error_textview.add_css_class ("monospace");
		error_textview.add_css_class ("error-message");
        error_textview.remove_css_class ("view");

		var textview_scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
			child = error_textview,
			height_request = 275
        };

		var textview_frame = new Gtk.Frame (null) {
			child = textview_scrolled_window,
            margin_top = 24,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12
		};

        issue_button = new Gtk.Button.with_label (_("Report Issue")) {
            hexpand = true,
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12,
            css_classes = { "suggested-action" }
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.append (headerbar);
        content_box.append (error_image);
        content_box.append (error_label);
        content_box.append (error_code_label);
        content_box.append (textview_frame);
        content_box.append (issue_button);

        child = content_box;

        issue_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://github.com/alainm23/planify/issues/new?assignees=&labels=&projects=&template=bug_report.md", null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });
    }

    public string get_http_error (int code) {
        var messages = new Gee.HashMap<int, string> ();

        messages.set (400, _("The request was incorrect."));
        messages.set (401, _("Authentication is required, and has failed, or has not yet been provided."));
        messages.set (403, _("The request was valid, but for something that is forbidden."));
        messages.set (404, _("The requested resource could not be found."));
        messages.set (429, _("The user has sent too many requests in a given amount of time."));
        messages.set (500, _("The request failed due to a server error."));
        messages.set (503, _("The server is currently unable to handle the request."));

        return messages.has_key (code) ? messages.get (code) : _("Unknown error");
    }
}
