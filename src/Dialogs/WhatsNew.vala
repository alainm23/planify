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

public class Dialogs.WhatsNew : Adw.Window {
	private Adw.NavigationView navigation_view;
	private Adw.PreferencesGroup feature_group;
	private Gtk.TextView textview;
	private Gtk.Revealer group_revealer;

	public WhatsNew () {
		Object (
			transient_for: (Gtk.Window) Planify.instance.main_window,
			deletable: true,
			destroy_with_parent: true,
			modal: true,
			default_width: 500,
			height_request: 500,
			title: null
		);
	}

	construct {
		var headerbar = new Adw.HeaderBar () {
			title_widget = new Gtk.Label (null),
			hexpand = true,
			css_classes = { "flat" }
		};

		var title_label = new Gtk.Label (_("What’s new in Planify")) {
			hexpand = true,
			halign = CENTER,
			css_classes = { "h1" }
		};

		var version_label = new Gtk.Label (Build.VERSION) {
			hexpand = true,
			halign = CENTER,
			css_classes = { "dim-label" }
		};

		feature_group = new Adw.PreferencesGroup () {
			margin_top = 24
		};

		var group = new Adw.PreferencesGroup () {
			margin_top = 12
		};

		textview = new Gtk.TextView () {
			left_margin = 12,
			right_margin = 12,
			top_margin = 12,
			bottom_margin = 12,
			editable = false,
			css_classes = { "card", "small-label" }
		};
		textview.remove_css_class ("view");
		group.add (textview);

		group_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			child = group
		};

		var content_box = new Gtk.Box (VERTICAL, 6);
		content_box.append (title_label);
		content_box.append (version_label);
		content_box.append (feature_group);
		content_box.append (group_revealer);

		var content_clamp = new Adw.Clamp () {
            maximum_size = 600,
			margin_start = 12,
			margin_end = 12,
			margin_bottom = 12
		};

		content_clamp.child = content_box;

		var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (headerbar);
		toolbar_view.content = content_clamp;

		var home_page = new Adw.NavigationPage.with_tag (toolbar_view, "home", "home");

		navigation_view = new Adw.NavigationView ();
		navigation_view.add (home_page);

		content = navigation_view;

		add_feature (
			_("Improved drag-and-drop sorting"),
			_("Added a new animation and a new way of sorting making it cleaner and easier."),
			create_video_page (
				_("Drag and drop has been improved, now it shows you a friendly animation to sort the elements in an easier way."),
				"/io/github/alainm23/planify/dnd-order.webm"
			)
		);

		add_feature (
			_("Support for sub-projects"),
			_("Create a sub-project just by dragging and dropping or by using the magic button and dropping into the parent project."),
			create_video_page (
				_("Creating sub projects is now easier, just drag the child sub project into the parent project, Planify will do the rest.\nIf you want a sub project to no longer be part of a parent project, just drag it out."),
				"/io/github/alainm23/planify/subprojects.webm"
			)
		);

		add_feature (
			_("The Magic Button"),
			_("Just drag and drop to add tasks wherever you want and in the order you want."),
			create_video_page (
				_("Drag the magic button to create your tasks wherever you want. You can also create sub-tasks by dropping the magic button inside a parent task."),
				"/io/github/alainm23/planify/magic-button.webm"
			)
		);

		add_feature (
			_("Board View"),
			_("Have an overview of your tasks without losing sight of the details.")
		);
	}

	public void add_feature (string title, string description, Adw.NavigationPage? page = null) {
		var row = new Adw.ActionRow ();
		row.title = title;
		row.subtitle = description;

		if (page != null) {
			row.add_suffix (generate_icon ("pan-end-symbolic", 16));
			row.activatable = true;
			row.activated.connect (() => {
				navigation_view.push (page);
			});
		}

		feature_group.add (row);
	}

	public void add_description (string description) {
		textview.buffer.text = description;
		group_revealer.reveal_child = true;
	}

	public void hide_destroy () {
		hide ();

		Timeout.add (500, () => {
			destroy ();
			return GLib.Source.REMOVE;
		});
	}

	private Adw.NavigationPage create_video_page (string description, string video_url) {
		var headerbar = new Dialogs.Preferences.SettingsHeader (_("What's New"));

		var description_label = new Gtk.Label (description) {
			justify = Gtk.Justification.FILL,
			use_markup = true,
			wrap = true,
			xalign = 0
		};

		var video = new Gtk.Video.for_resource (video_url) {
			autoplay = true,
			loop = true,
			css_classes = { "video-content" }
		};

		var _video = new Adw.Bin () {
			css_classes = { "card", "video-content" },
			child = video,
			margin_top = 12
		};

		var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
		content_box.append (description_label);
		content_box.append (_video);

		var content_clamp = new Adw.Clamp () {
			maximum_size = 600,
			margin_start = 24,
			margin_end = 24,
			margin_top = 12
		};

		content_clamp.child = content_box;

		var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (headerbar);
		toolbar_view.content = content_clamp;

		var page = new Adw.NavigationPage (toolbar_view, "dnd");

		headerbar.back_activated.connect (() => {
			navigation_view.pop ();
		});

		return page;
	}
	
	private Gtk.Widget generate_icon (string icon_name, int size = 32) {
		var icon = new Widgets.DynamicIcon.from_icon_name (icon_name);
		icon.size = size;
		return icon;
	}
}
