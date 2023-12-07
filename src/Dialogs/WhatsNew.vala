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

public class Dialogs.WhatsNew : Adw.Window {
	private Adw.PreferencesGroup feature_group;
	private Gtk.TextView textview;
	private Gtk.Revealer group_revealer;

	public WhatsNew () {
		Object (
			transient_for: (Gtk.Window) Planify.instance.main_window,
			deletable: true,
			destroy_with_parent: true,
			modal: true,
			title: _("What's New"),
			height_request: 475,
			width_request: 375
			);
	}

	construct {
		var headerbar = new Adw.HeaderBar () {
			title_widget = new Gtk.Label (null),
			hexpand = true,
			decoration_layout = ":close"
		};
		headerbar.add_css_class (Granite.STYLE_CLASS_FLAT);

		var title_label = new Gtk.Label (_("What's New in Planify")) {
			halign = START
		};
		title_label.add_css_class ("h1");

		var version_label = new Gtk.Label (_("Version 4.1.1")) {
			halign = START
		};
		version_label.add_css_class ("dim-label");

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
			editable = false
		};
		textview.add_css_class ("card");
		textview.add_css_class ("small-label");
		textview.remove_css_class ("view");
		group.add (textview);

		group_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			child = group
		};

		var content_box = new Gtk.Box (VERTICAL, 6) {
			margin_start = 24,
			margin_end = 24
		};

		content_box.append (title_label);
		content_box.append (version_label);
		content_box.append (feature_group);
		content_box.append (group_revealer);

		var main_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		main_grid.append (headerbar);
		main_grid.append (content_box);

		content = main_grid;

		add_feature (_("Todoist"), _("Synchronize with your Todoist Account"), "planner-todoist");
		add_feature (_("Todoist"), _("Synchronize with your Todoist Account"), "planner-todoist");

	}

	public void add_feature (string title, string description, string icon) {
		var row = new Adw.ActionRow ();
        row.add_prefix (new Gtk.Image.from_icon_name (icon));
		row.title = title;
		row.subtitle = description;

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
}
