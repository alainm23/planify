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
    LABEL
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
        int count = (interval == null || interval == 0) ? 1 : interval;

        switch (this) {
            case NONE:
                return _("Don't Repeat");
            case MINUTELY:
                return GLib.ngettext ("Every minute", "Every %d minutes", count).printf (count);
            case HOURLY:
                return GLib.ngettext ("Every hour", "Every %d hours", count).printf (count);
            case EVERY_DAY:
                return GLib.ngettext ("Every day", "Every %d days", count).printf (count);
            case EVERY_WEEK:
                return GLib.ngettext ("Every week", "Every %d weeks", count).printf (count);
            case EVERY_MONTH:
                return GLib.ngettext ("Every month", "Every %d months", count).printf (count);
            case EVERY_YEAR:
                return GLib.ngettext ("Every year", "Every %d years", count).printf (count);
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
    START = 0,
    END = 1,
}

public enum CalDAVType {
    NEXTCLOUD = 0,
    GENERIC = 1;

    public string to_string () {
        switch (this) {
            case NEXTCLOUD:
                return "nextcloud";

            case GENERIC:
                return "generic";

            default:
                assert_not_reached ();
        }
    }

    public string title () {
        switch (this) {
            case NEXTCLOUD:
                return _("Nextcloud");

            case GENERIC:
                return _("CalDAV"); // TODO: Maybe rename Generic to CalDAV?

            default:
                assert_not_reached ();
        }
    }

    public static CalDAVType parse_index (uint value) {
        switch (value) {
            case 0:
                return CalDAVType.NEXTCLOUD;

            case 1:
                return CalDAVType.GENERIC;

            default:
                return CalDAVType.NEXTCLOUD;
        }
    }

    public static CalDAVType parse (string value) {
        switch (value) {
            case "nextcloud":
                return CalDAVType.NEXTCLOUD;

            case "generic":
                return CalDAVType.GENERIC;

            default:
                return CalDAVType.NEXTCLOUD;
        }
    }
}

public enum FilterItemType {
    PRIORITY = 0,
    LABEL = 1,
    DUE_DATE = 2,
    SECTION = 3,
    ASSIGNMENT = 4;

    public string to_string () {
        switch (this) {
            case PRIORITY:
                return "priority";

            case LABEL:
                return "label";

            case DUE_DATE:
                return "due-date";

            case SECTION:
                return "section";

            case ASSIGNMENT:
                return "assignment";

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

            case SECTION:
                return _("Section");

            case ASSIGNMENT:
                return _("Assignment");

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

            case SECTION:
                return "arrow3-right-symbolic";

            case ASSIGNMENT:
                return "avatar-default-symbolic";

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
    PINNED,
    CHECKED,
    PROJECT,
    SECTION;

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

            case "checked":
                return ObjectEventKeyType.CHECKED;

            case "project":
                return ObjectEventKeyType.PROJECT;

            case "section":
                return ObjectEventKeyType.SECTION;

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
    FILTER_AND_CREATE,
    FILTER_ONLY
}

public enum ItemPriority {
    HIGHT = 4,
    MEDIUM = 3,
    LOW = 2,
    NONE = 1;

    public static ItemPriority parse (string value) {
        switch (value) {
            case "p1":
                return ItemPriority.HIGHT;

            case "p2":
                return ItemPriority.MEDIUM;

            case "p3":
                return ItemPriority.LOW;

            case "p4":
                return ItemPriority.NONE;

            default:
                return ItemPriority.NONE;
        }
    }

    public string get_color () {
        switch (this) {
            case HIGHT:
                return "#ff7066";

            case MEDIUM:
                return "#ff9914";

            case LOW:
                return "#5297ff";

            case NONE:
                return Services.Settings.get_default ().settings.get_boolean ("dark-mode") ? "#fafafa" : "#333333";

            default:
                assert_not_reached ();
        }
    }
}

public enum SortOrderType {
    ASC,
    DESC;

    public string to_string () {
        switch (this) {
            case ASC:
                return "asc";

            case DESC:
                return "desc";

            default:
                return "asc";
        }
    }

    public static SortOrderType parse (string value) {
        switch (value) {
            case "asc":
                return SortOrderType.ASC;

            case "desc":
                return SortOrderType.DESC;

            default:
                return SortOrderType.ASC;
        }
    }
}

public enum SortedByType {
    MANUAL,
    NAME,
    DUE_DATE,
    ADDED_DATE,
    PRIORITY;

    public string to_string () {
        switch (this) {
            case MANUAL:
                return "manual";

            case NAME:
                return "name";

            case DUE_DATE:
                return "due-date";

            case ADDED_DATE:
                return "added-date";

            case PRIORITY:
                return "priority";

            default:
                return "manual";
        }
    }

    public static SortedByType parse (string value) {
        switch (value) {
            case "manual":
                return SortedByType.MANUAL;

            case "name":
                return SortedByType.NAME;

            case "due-date":
                return SortedByType.DUE_DATE;

            case "added-date":
                return SortedByType.ADDED_DATE;

            case "priority":
                return SortedByType.PRIORITY;

            default:
                return SortedByType.MANUAL;
        }
    }
}

public enum Appearance {
    LIGHT,
    DARK,
    DARK_BLUE;

    public string to_string () {
        switch (this) {
            case LIGHT:
                return "light";

            case DARK:
                return "dark";

            case DARK_BLUE:
                return "dark-blue";

            default:
                return "light";
        }
    }

    public static Appearance parse (int value) {
        switch (value) {
            case 0:
                return Appearance.LIGHT;

            case 1:
                return Appearance.DARK;

            case 2:
                return Appearance.DARK_BLUE;

            default:
                return Appearance.LIGHT;
        }
    }

    public static Appearance get_default () {
        switch (Services.Settings.get_default ().settings.get_enum ("appearance")) {
            case 0:
                return Appearance.LIGHT;

            case 1:
                return Appearance.DARK;

            case 2:
                return Appearance.DARK_BLUE;

            default:
                return Appearance.LIGHT;
        }
    }
}