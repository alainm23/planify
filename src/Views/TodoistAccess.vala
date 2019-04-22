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

public class Views.TodoistAccess : Gtk.EventBox {
    private Gtk.Label info_label;
    private Gtk.Spinner spinner;
    private WebKit.WebView webview;

    private const string oauth_open_url = "https://todoist.com/oauth/authorize?client_id=b0dd7d3714314b1dbbdab9ee03b6b432&scope=data:read&state=XE3K-4BBL-4XLG-UDS8"; 
    
    public signal void back ();
    
    public TodoistAccess () {
        
    }

    construct {
        info_label = new Gtk.Label (_("Loading…"));

        spinner = new Gtk.Spinner ();
        spinner.start ();

        var back_button = new Gtk.Button.with_label (_("Back"));
        back_button.halign = Gtk.Align.START;
        back_button.margin = 6;
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var container_grid = new Gtk.Grid ();
        container_grid.column_spacing = 6;
        container_grid.valign = Gtk.Align.CENTER;
        container_grid.add (info_label);
        container_grid.add (spinner);

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        header_box.hexpand = true;
        header_box.add (back_button);
        header_box.set_center_widget (container_grid);

        webview = new WebKit.WebView ();
        webview.expand = true;

        WebKit.WebContext.get_default ().set_preferred_languages (GLib.Intl.get_language_names ());

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (webview);

        var alert_view = new Granite.Widgets.AlertView (
            _("Network Is Not Available"),
            _("Connect to the Internet to connect with Todoist"),
            "network-error"
        );
        
        var spinner_loading = new Gtk.Spinner ();
        spinner_loading.valign = Gtk.Align.CENTER;
        spinner_loading.halign = Gtk.Align.CENTER;
        spinner_loading.width_request = 50;
        spinner_loading.height_request = 50;
        spinner_loading.active = true;
        spinner_loading.start ();

        var stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        stack.add_named (scrolled, "web_view");
        stack.add_named (alert_view, "error_view");
        stack.add_named (spinner_loading, "spinner_loading");

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (header_box);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (stack);
    
        var main_frame = new Gtk.Frame (null);
        main_frame.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_frame.add (main_grid);

        add (main_frame);

        back_button.clicked.connect (() => {
            back ();
        });

        webview.load_changed.connect ((load_event) => {
            var redirect_uri = webview.get_uri ();

            if ("https://github.com/alainm23/planner?state=XE3K-4BBL-4XLG-UDS8&code=" in redirect_uri) {                
                new Thread<void*> ("get_todoist_token", () => {
                    Application.todoist.get_todoist_token (redirect_uri);

                    return null;
                });
                
                stack.visible_child_name = "spinner_loading";
                webview.stop_loading ();
            }
            
            if ("https://github.com/alainm23/planner?error=access_denied" in redirect_uri) {
                back ();
            }

            if (load_event == WebKit.LoadEvent.FINISHED) {
                info_label.label = _("Please enter your credentials…");
                spinner.stop ();
                spinner.hide ();

                return;
            }

            if (load_event == WebKit.LoadEvent.STARTED) {
                info_label.label = _("Loading…");
                spinner.start ();
                spinner.show ();

                return;
            }
            
            return;
        });

        webview.load_failed.connect ((load_event, failing_uri, _error) => {
            var error = (GLib.Error)_error;
            warning ("Loading uri '%s' failed, error : %s", failing_uri, error.message);
            if (GLib.strcmp (failing_uri, oauth_open_url) == 0) {
                info_label.label = _("Network Is Not Available");
                stack.visible_child_name = "error_view";
            }

            return true;
        });
    }

    public void init () {
        webview.load_uri (oauth_open_url);
    }
}