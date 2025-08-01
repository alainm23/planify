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

public class Layouts.ProjectContainerRow : Gtk.ListBoxRow {
	public Objects.Project project { get; construct; }
	public bool show_subprojects { get; construct; }
	public bool drag_n_drop { get; construct; }

	private Gtk.Revealer main_revealer;

	public ProjectContainerRow (Objects.Project project, bool show_subprojects = true, bool drag_n_drop = true) {
		Object (
			project: project,
			show_subprojects: show_subprojects,
			drag_n_drop: drag_n_drop
			);
	}

	~ProjectContainerRow () {
		print ("Destroying Layouts.ProjectContainerRow\n");
	}

	construct {
		css_classes = { "no-selectable", "no-padding" };

		var listbox = new Gtk.ListBox () {
			css_classes = { "listbox-background" }
		};

		listbox.append (new Layouts.ProjectRow (project, drag_n_drop));

		main_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			child = listbox
		};

		child = main_revealer;

		Timeout.add (main_revealer.transition_duration, () => {
			main_revealer.reveal_child = true;
			return GLib.Source.REMOVE;
		});
	}

	public void hide_destroy () {
		main_revealer.reveal_child = false;
		Timeout.add (main_revealer.transition_duration, () => {
			((Gtk.ListBox) parent).remove (this);
			return GLib.Source.REMOVE;
		});
	}
}
