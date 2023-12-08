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

public enum ColorScheme {
	NO_PREFERENCE,
	DARK,
	LIGHT
}

public enum NotificationStyle {
	NORMAL,
	ERROR
}

public enum ProjectViewStyle {
	LIST,
	BOARD;

	public string to_string () {
		switch (this) {
		case LIST:
			return "list";

		case BOARD:
			return "board";

		default:
			assert_not_reached();
		}
	}
}

public enum ProjectIconStyle {
	PROGRESS,
	EMOJI;

	public string to_string () {
		switch (this) {
		case PROGRESS:
			return "progress";

		case EMOJI:
			return "emoji";

		default:
			assert_not_reached();
		}
	}
}

public enum FilterType {
	TODAY = 0,
	INBOX = 1,
	SCHEDULED = 2,
	PINBOARD = 3,
	LABEL = 4,
	FILTER = 5;

	public string to_string () {
		switch (this) {
		case TODAY:
			return "today";

		case INBOX:
			return "inbox";

		case SCHEDULED:
			return "scheduled";

		case PINBOARD:
			return "pinboard";

		case LABEL:
			return "label";

		case FILTER:
			return "filter";

		default:
			assert_not_reached();
		}
	}

	public string get_name () {
		switch (this) {
		case TODAY:
			return _("Today");

		case INBOX:
			return _("Inbox");

		case SCHEDULED:
			return _("Scheduled");

		case PINBOARD:
			return _("Pinboard");

		default:
			assert_not_reached();
		}
	}
}

public enum BackendType {
	ALL,
	NONE,
	LOCAL,
	TODOIST,
	GOOGLE_TASKS,
	CALDAV;

	public string to_string () {
		switch (this) {
		case ALL:
			return "all";

		case NONE:
			return "none";

		case LOCAL:
			return "local";

		case TODOIST:
			return "todoist";

		case GOOGLE_TASKS:
			return "google-tasks";

		case CALDAV:
			return "caldav";

		default:
			assert_not_reached();
		}
	}
}

public enum PaneType {
	FILTER,
	FAVORITE,
	PROJECT,
	LABEL,
	TASKLIST
}

public enum LoadingButtonType {
	LABEL,
	ICON
}

public enum ObjectType {
	PROJECT,
	SECTION,
	ITEM,
	LABEL,
	TASK,
	TASK_LIST,
	FILTER;

	public string get_header () {
		switch (this) {
		case PROJECT:
			return _("Projects");

		case SECTION:
			return _("Sections");

		case ITEM:
			return _("Tasks");

		case LABEL:
			return _("Labels");

		case FILTER:
			return _("Filters");

		case TASK:
			return _("Tasks");

		case TASK_LIST:
			return _("Lists");

		default:
			assert_not_reached();
		}
	}
}

public enum RecurrencyType {
	EVERY_DAY,
	EVERY_WEEK,
	EVERY_MONTH,
	EVERY_YEAR,
	NONE;

	public string to_friendly_string(int? interval = null) {
		switch (this) {
		case NONE:
			return _("Don't Repeat");
		case EVERY_DAY:
			if (interval == null || interval == 0) {
				return _("Every day");
			} else {
				return GLib.ngettext (_("Every day"), _("Every %d days"), interval).printf (interval);
			}
		case EVERY_WEEK:
			if (interval == null || interval == 0) {
				return _("Every week");
			} else {
				return GLib.ngettext (_("Every week"), _("Every %d weeks"), interval).printf (interval);
			}

		case EVERY_MONTH:
			if (interval == null || interval == 0) {
				return _("Every month");
			} else {
				return GLib.ngettext (_("Every month"), _("Every %d months"), interval).printf (interval);
			}

		case EVERY_YEAR:
			if (interval == null || interval == 0) {
				return _("Every year");
			} else {
				return GLib.ngettext (_("Every year"), _("Every %d years"), interval).printf (interval);
			}

		default:
			assert_not_reached();
		}
	}
}

public enum DefaultInboxProject {
	LOCAL = 0,
	TODOIST = 1
}

public enum PickerType {
	PROJECTS,
	SECTIONS;

	public string to_string () {
		switch (this) {
		case PROJECTS:
			return "projects";

		case SECTIONS:
			return "sections";

		default:
			assert_not_reached();
		}
	}
}
