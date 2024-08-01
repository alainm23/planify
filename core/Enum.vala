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
			assert_not_reached ();
		}
	}

	public static ProjectViewStyle parse (string value) {
		switch (value) {
			case "list":
				return ProjectViewStyle.LIST;

			case "board":
				return ProjectViewStyle.BOARD;

			default:
				assert_not_reached ();
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
			assert_not_reached ();
		}
	}

	public static ProjectIconStyle parse (string value) {
		switch (value) {
			case "progress":
				return ProjectIconStyle.PROGRESS;

			case "emoji":
				return ProjectIconStyle.EMOJI;

			default:
				assert_not_reached ();
		}
	}
}

public enum FilterType {
	INBOX = 0,
	TODAY = 1,
	SCHEDULED = 2,
	PINBOARD = 3,
	LABELS = 4,
	COMPLETED = 5;

	public string to_string () {
		switch (this) {
			case INBOX:
				return "inbox";

			case TODAY:
				return "today";

			case SCHEDULED:
				return "scheduled";

			case PINBOARD:
				return "pinboard";

			case LABELS:
				return "labels";

			case COMPLETED:
				return "completed";

			default:
				assert_not_reached ();
			}
	}

	public string get_name () {
		switch (this) {
			case INBOX:
				return _("Inbox");

			case TODAY:
				return _("Today");

			case SCHEDULED:
				return _("Scheduled");

			case PINBOARD:
				return _("Pinboard");

			case LABELS:
				return _("Labels");

			case COMPLETED:
				return _("Completed");

			default:
				assert_not_reached ();
		}
	}

	public string get_icon () {
		switch (this) {
			case INBOX:
				return "mailbox-symbolic";

			case TODAY:
				return "star-outline-thick-symbolic";

			case SCHEDULED:
				return "month-symbolic";

			case PINBOARD:
				return "pin-symbolic";

			case LABELS:
				return "tag-outline-symbolic";

			case COMPLETED:
				return "check-round-outline-symbolic";

			default:
				assert_not_reached ();
		}
	}

	public string get_color () {
		switch (this) {
			case INBOX:
				return "#3584e4";

			case TODAY:
				return "#33d17a";

			case SCHEDULED:
				return "#9141ac";

			case PINBOARD:
				return "#ed333b";

			case LABELS:
				return "#986a44";

			case COMPLETED:
				return "#ff7800";

			default:
				assert_not_reached ();
		}
	}
}

public enum SourceType {
	NONE,
	LOCAL,
	TODOIST,
	GOOGLE_TASKS,
	CALDAV;

	public string to_string () {
		switch (this) {
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
				assert_not_reached ();
		}
	}

	public static SourceType parse (string value) {
		switch (value) {
			case "local":
				return SourceType.LOCAL;

			case "todoist":
				return SourceType.TODOIST;

			case "google-tasks":
				return SourceType.GOOGLE_TASKS;
			
			case "caldav":
				return SourceType.CALDAV;

			default:
				return SourceType.NONE;
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
				assert_not_reached ();
		}
	}
}

public enum RecurrencyEndType {
	NEVER,
	ON_DATE,
	AFTER
}

public enum RecurrencyType {
	MINUTELY,
	HOURLY,
	EVERY_DAY,
	EVERY_WEEK,
	EVERY_MONTH,
	EVERY_YEAR,
	NONE;

	public string to_friendly_string (int? interval = null) {
		switch (this) {
			case NONE:
				return _("Don't Repeat");
			case MINUTELY:
				if (interval == null || interval == 0) {
					return _("Every minute");
				} else {
					return GLib.ngettext (_("Every minute"), _("Every %d minutes"), interval).printf (interval);
				}
			case HOURLY:
				if (interval == null || interval == 0) {
					return _("Every hour");
				} else {
					return GLib.ngettext (_("Every hour"), _("Every %d hours"), interval).printf (interval);
				}
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
				assert_not_reached ();
		}
	}
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
				assert_not_reached ();
		}
	}
}

public enum NewTaskPosition {
	TOP = 0,
	BOTTOM = 1,
}

public enum CalDAVType {
	NEXTCLOUD = 0,
	RADICALE = 1;

	public string to_string () {
		switch (this) {
			case NEXTCLOUD:
				return "nextcloud";

			case RADICALE:
				return "radicale";

			default:
				assert_not_reached ();
		}
	}

	public string title () {
		switch (this) {
			case NEXTCLOUD:
				return _("Nextcloud");

			case RADICALE:
				return _("Radicale");

			default:
				assert_not_reached ();
		}
	}

	public static CalDAVType parse_index (uint value) {
		switch (value) {
			case 0:
				return CalDAVType.NEXTCLOUD;

			case 1:
				return CalDAVType.RADICALE;

			default:
				return CalDAVType.NEXTCLOUD;
		}
	}

	public static CalDAVType parse (string value) {
		switch (value) {
			case "nextcloud":
				return CalDAVType.NEXTCLOUD;

			case "radicale":
				return CalDAVType.RADICALE;

			default:
				return CalDAVType.NEXTCLOUD;
		}
	}
}

public enum FilterItemType {
	PRIORITY = 0,
	LABEL = 1,
	DUE_DATE = 2;

	public string to_string () {
		switch (this) {
			case PRIORITY:
				return "priority";

			case LABEL:
				return "label";
			
			case DUE_DATE:
				return "due-date";

			default:
				assert_not_reached ();
		}
	}

	public string get_title () {
		switch (this) {
			case PRIORITY:
				return _("Priority");

			case LABEL:
				return _("Label");

			case DUE_DATE:
				return _("Due Date");

			default:
				assert_not_reached ();
		}
	}

	public string get_icon () {
		switch (this) {
			case PRIORITY:
				return "flag-outline-thick-symbolic";

			case LABEL:
				return "tag-outline-symbolic";

			case DUE_DATE:
				return "month-symbolic";

			default:
				assert_not_reached ();
		}
	} 
}

public enum ReminderType {
	ABSOLUTE,
	RELATIVE;

	public string to_string () {
		switch (this) {
			case ABSOLUTE:
				return "absolute";

			case RELATIVE:
				return "relative";
		
			default:
				assert_not_reached ();
		}
	}
}

public enum ItemType {
	TASK,
	NOTE;

	public string to_string () {
		switch (this) {
			case TASK:
				return "task";

			case NOTE:
				return "note";

			default:
				assert_not_reached ();
		}
	}

	public static ItemType parse (string value) {
		switch (value) {
			case "task":
				return ItemType.TASK;

			case "note":
				return ItemType.NOTE;

			default:
				assert_not_reached ();
		}
	}
}

public enum ObjectEventType {
	INSERT,
	UPDATE;

	public static ObjectEventType parse (string value) {
		switch (value) {
			case "insert":
				return ObjectEventType.INSERT;

			case "update":
				return ObjectEventType.UPDATE;

			default:
				assert_not_reached ();
		}
	}

	public string to_string () {
		switch (this) {
			case INSERT:
				return "insert";

			case UPDATE:
				return "update";

			default:
				assert_not_reached ();
		}
	}

	public string get_label () {
		switch (this) {
			case INSERT:
				return _("Task Created");

			case UPDATE:
				return _("Task Updated");

			default:
				assert_not_reached ();
		}
	}
}

public enum ObjectEventKeyType {
	CONTENT,
	DESCRIPTION,
	DUE,
	PRIORITY,
	LABELS,
	PINNED;

	public static ObjectEventKeyType parse (string value) {
		switch (value) {
			case "content":
				return ObjectEventKeyType.CONTENT;

			case "description":
				return ObjectEventKeyType.DESCRIPTION;
			
			case "due":
				return ObjectEventKeyType.DUE;
			
			case "priority":
				return ObjectEventKeyType.PRIORITY;

			case "labels":
				return ObjectEventKeyType.LABELS;

			case "pinned":
				return ObjectEventKeyType.PINNED;

			default:
				assert_not_reached ();
		}
	}

	public string get_label () {
		switch (this) {
			case ObjectEventKeyType.CONTENT:
				return _("Content");

			case ObjectEventKeyType.DESCRIPTION:
				return _("Description");
			
			case ObjectEventKeyType.DUE:
				return _("Scheduled");
			
			case ObjectEventKeyType.PRIORITY:
				return _("Priority");

			case ObjectEventKeyType.LABELS:
				return _("Labels");

			case ObjectEventKeyType.PINNED:
				return _("Pin");

			default:
				assert_not_reached ();
		}
	}
}

public enum LabelPickerType {
	SELECT,
	FILTER
}